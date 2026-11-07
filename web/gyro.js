/* Optional motion aim. Sensor samples stay in memory; only sensitivity is saved. */
(function(root){
  'use strict';
  const clamp=(v,a,b)=>Math.min(b,Math.max(a,v)), RAD=Math.PI/180;
  function create({host=root,now=()=>performance.now(),changed=()=>{}}={}){
    let enabled=false,ready=false,pending=false,generation=0,listening=false;
    let context={running:false,landscape:true,visible:true,focused:true};
    let sensitivity=1,last=null,lastSample=null,yaw=0,pitch=0,filtered=[0,0],bias=[0,0,0];
    let permissionGranted=false;
    let calibration=null,probe=0,status=unavailable()||idleStatus();
    try {const saved=Number(host.localStorage?.getItem('no-art-gyro-sensitivity'));if(saved>=.25&&saved<=3)sensitivity=saved;}catch{}
    const snapshot=()=>({enabled,ready,pending,sensitivity,status,calibrating:!!calibration,available:!unavailable(),canRequest:!!permissionAPI()});
    function permissionAPI(){
      if(typeof host.DeviceMotionEvent?.requestPermission==='function')return host.DeviceMotionEvent;
      if(typeof host.DeviceOrientationEvent?.requestPermission==='function')return host.DeviceOrientationEvent;
      return null;
    }
    function idleStatus(){
      return permissionAPI()
        ? '点按「请求权限」，由浏览器处理运动与方向访问。'
        : '点按「启用」后会尝试读取运动传感器。';
    }
    function unavailable(){
      if(!host.isSecureContext)return '体感瞄准需要 HTTPS。请打开正式试玩页面。';
      if(!host.DeviceMotionEvent)return '当前浏览器不提供运动传感器。请用系统浏览器直接打开。';
      const policy=host.document?.permissionsPolicy||host.document?.featurePolicy;
      const features=policy?.features?.()??[];
      if(['accelerometer','gyroscope'].some(feature=>features.includes(feature)&&!policy.allowsFeature(feature)))return '当前页面禁止访问运动传感器。请在浏览器中直接打开试玩页。';
      return '';
    }
    function notify(message){if(message!==undefined)status=message;changed(snapshot());}
    function reset(){last=null;yaw=pitch=0;filtered=[0,0];}
    function active(){return context.visible&&context.focused&&context.landscape;}
    function watchForMotion(){
      host.clearTimeout(probe);probe=0;
      if(!enabled||!active())return;
      function check(){
        const remaining=lastSample===null?0:3000-(now()-lastSample);
        if(remaining>0)probe=host.setTimeout(check,remaining);
        else stop(permissionGranted
          ? '权限已允许，但未检测到体感数据。请保持页面在前台后重试。'
          : '未检测到体感数据。请检查浏览器是否允许此站点访问运动传感器。');
      }
      probe=host.setTimeout(check,3000);
    }
    function stop(message=idleStatus()){
      generation++;enabled=ready=pending=false;calibration=null;reset();
      permissionGranted=false;
      host.clearTimeout(probe);probe=0;
      if(listening)host.removeEventListener('devicemotion',sample);
      listening=false;notify(message);
    }
    function calibrate(){
      if(!enabled)return;
      ready=false;lastSample=null;reset();calibration={start:now(),first:null,count:0,sum:[0,0,0]};
      const instruction=active()?'请保持设备静止，等待校准完成。':'请回到当前页面，横握设备完成校准。';
      notify((permissionGranted?'权限已允许。':'')+instruction);
      watchForMotion();
    }
    async function enable(){
      if(enabled||pending)return;
      const issue=unavailable();
      if(issue){notify(issue);return;}
      const api=permissionAPI();
      const token=++generation;
      try {
        // Called directly from the switch click, before any other awaited work.
        const request=api?.requestPermission();
        if(api){pending=true;notify('已向浏览器请求权限。如有弹窗，请允许访问。');}
        const permission=api?await request:'granted';
        if(token!==generation)return;
        pending=false;
        if(permission!=='granted'){notify('浏览器拒绝了运动传感器权限。如果没有弹窗，浏览器可能沿用了之前的选择。');return;}
        permissionGranted=!!api;
        enabled=true;
        host.addEventListener('devicemotion',sample);listening=true;calibrate();
      }catch(error){
        if(token===generation)stop(error?.name==='NotAllowedError'?'授权未完成。请在当前页面重新点按「请求权限」。':'浏览器无法请求体感权限。请直接打开试玩页后重试。');
      }
    }
    function setContext(next){
      const wasActive=active(),wasRunning=context.running;
      context={...context,...next};
      if(wasActive!==active()){
        reset();lastSample=null;
        if(calibration)calibrate();
        else if(enabled)watchForMotion();
      }else if(wasRunning!==context.running){
        reset();
      }
    }
    function setSensitivity(value){
      const n=Number(value);if(!Number.isFinite(n))return;
      sensitivity=clamp(n,.25,3);reset();
      try{host.localStorage?.setItem('no-art-gyro-sensitivity',String(sensitivity));}catch{}
      notify();
    }
    function sample(event){
      if(!enabled||!active())return;
      const r=event.rotationRate;
      if(!r||![r.beta,r.gamma,r.alpha].every(Number.isFinite)){reset();return;}
      const t=now(),raw=[r.beta,r.gamma,r.alpha];lastSample=t;
      if(calibration){
        if(raw.some(v=>Math.abs(v)>3)){calibration.first=null;calibration.count=0;calibration.sum=[0,0,0];}
        else{
          if(calibration.first===null)calibration.first=t;
          raw.forEach((v,i)=>calibration.sum[i]+=v);calibration.count++;
          if(t-calibration.first>=650&&calibration.count>=15){
            bias=calibration.sum.map(v=>v/calibration.count);calibration=null;ready=true;reset();notify('校准完成，可以用体感瞄准。');return;
          }
        }
        if(t-calibration.start>6000){calibration=null;ready=false;notify('手机移动较多，请重新校准');}
        return;
      }
      if(!ready||!context.running){reset();return;}
      const dt=last===null?0:(t-last)/1000;last=t;
      if(dt<=0||dt>.1){yaw=pitch=0;filtered=[0,0];return;}
      const rates=raw.map((v,i)=>clamp(v-bias[i],-300,300));
      const screenAngle=host.screen?.orientation?.angle ?? host.orientation ?? 0;
      const a=Number(screenAngle)*RAD,c=Math.cos(a),s=Math.sin(a);
      // Screen X is the pitch axis. Screen Y is a fallback when gravity is absent.
      const pitchRate=rates[0]*c-rates[1]*s;
      let yawRate=rates[0]*s+rates[1]*c;
      const g=event.accelerationIncludingGravity;
      if(g&&[g.x,g.y,g.z].every(Number.isFinite)){
        const length=Math.hypot(g.x,g.y,g.z);
        // At rest accelerationIncludingGravity points up (W3C: face-up Z=+9.8).
        if(length>7&&length<12)yawRate=(rates[0]*g.x+rates[1]*g.y+rates[2]*g.z)/length;
      }
      const blend=1-Math.exp(-dt/.025);
      [yawRate,pitchRate].forEach((v,i)=>filtered[i]+=(v-filtered[i])*blend);
      const softDeadzone=v=>Math.sign(v)*Math.max(0,Math.abs(v)-.08);
      yaw=clamp(yaw-softDeadzone(filtered[0])*RAD*dt*sensitivity,-.25,.25);
      pitch=clamp(pitch-softDeadzone(filtered[1])*RAD*dt*sensitivity,-.25,.25);
    }
    function read(){
      if(!enabled||!ready||!active()||!context.running||lastSample===null||now()-lastSample>250)reset();
      const result={gyroYaw:yaw,gyroPitch:pitch};yaw=pitch=0;return result;
    }
    return {enable,disable:()=>stop(),calibrate,setContext,setSensitivity,read,snapshot,reset};
  }
  root.NoArtGyro={create};
})(typeof window!=='undefined'?window:globalThis);
