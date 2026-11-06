/* Optional motion aim. Sensor samples stay in memory; only sensitivity is saved. */
(function(root){
  'use strict';
  const clamp=(v,a,b)=>Math.min(b,Math.max(a,v)), RAD=Math.PI/180;
  function create({host=root,now=()=>performance.now(),changed=()=>{}}={}){
    let enabled=false,ready=false,pending=false,generation=0,listening=false;
    let context={running:false,landscape:true,visible:true,focused:true};
    let sensitivity=1,last=null,lastSample=null,yaw=0,pitch=0,filtered=[0,0],bias=[0,0,0];
    let calibration=null,probe=0,status='关闭';
    try {const saved=Number(host.localStorage?.getItem('no-art-gyro-sensitivity'));if(saved>=.25&&saved<=3)sensitivity=saved;}catch{}
    const snapshot=()=>({enabled,ready,pending,sensitivity,status,calibrating:!!calibration});
    function notify(message){if(message!==undefined)status=message;changed(snapshot());}
    function reset(){last=null;yaw=pitch=0;filtered=[0,0];}
    function active(){return context.visible&&context.focused&&context.landscape;}
    function stop(message='关闭'){
      generation++;enabled=ready=pending=false;calibration=null;reset();
      host.clearTimeout(probe);probe=0;
      if(listening)host.removeEventListener('devicemotion',sample);
      listening=false;notify(message);
    }
    function calibrate(){
      if(!enabled)return;
      ready=false;reset();calibration={start:now(),first:null,count:0,sum:[0,0,0]};
      notify('保持手机静止，正在校准');
    }
    async function enable(){
      if(enabled||pending)return;
      const Motion=host.DeviceMotionEvent;
      if(!host.isSecureContext||!Motion){notify('当前浏览器不支持体感');return;}
      const token=++generation;pending=true;notify('等待体感授权');
      try {
        // Called directly from the switch click, before any other awaited work.
        const permission=typeof Motion.requestPermission==='function'?await Motion.requestPermission():'granted';
        if(token!==generation)return;
        pending=false;
        if(permission!=='granted'){notify('未获得体感权限，可继续触屏操作');return;}
        enabled=true;lastSample=null;
        host.addEventListener('devicemotion',sample);listening=true;calibrate();
        probe=host.setTimeout(()=>{if(enabled&&lastSample===null)stop('未检测到体感数据，可继续触屏操作');},3000);
      }catch{if(token===generation)stop('无法开启体感，可继续触屏操作');}
    }
    function setContext(next){
      const merged={...context,...next};
      if(Object.keys(merged).some(k=>merged[k]!==context[k])){
        reset();
        if(calibration)calibration={start:now(),first:null,count:0,sum:[0,0,0]};
      }
      context=merged;
    }
    function setSensitivity(value){
      const n=Number(value);if(!Number.isFinite(n))return;
      sensitivity=clamp(n,.25,3);reset();
      try{host.localStorage?.setItem('no-art-gyro-sensitivity',String(sensitivity));}catch{}
      notify();
    }
    function sample(event){
      if(!enabled)return;
      const r=event.rotationRate;
      if(!r||![r.beta,r.gamma,r.alpha].every(Number.isFinite)){reset();return;}
      const t=now(),raw=[r.beta,r.gamma,r.alpha];lastSample=t;
      host.clearTimeout(probe);probe=0;
      if(!active()){reset();return;}
      if(calibration){
        if(raw.some(v=>Math.abs(v)>3)){calibration.first=null;calibration.count=0;calibration.sum=[0,0,0];}
        else{
          if(calibration.first===null)calibration.first=t;
          raw.forEach((v,i)=>calibration.sum[i]+=v);calibration.count++;
          if(t-calibration.first>=650&&calibration.count>=15){
            bias=calibration.sum.map(v=>v/calibration.count);calibration=null;ready=true;reset();notify('已开启');return;
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
      yaw=clamp(yaw+softDeadzone(filtered[0])*RAD*dt*sensitivity,-.25,.25);
      pitch=clamp(pitch+softDeadzone(filtered[1])*RAD*dt*sensitivity,-.25,.25);
    }
    function read(){
      if(!enabled||!ready||!active()||!context.running||lastSample===null||now()-lastSample>250)reset();
      const result={gyroYaw:yaw,gyroPitch:pitch};yaw=pitch=0;return result;
    }
    return {enable,disable:()=>stop(),calibrate,setContext,setSensitivity,read,snapshot,reset};
  }
  root.NoArtGyro={create};
})(typeof window!=='undefined'?window:globalThis);
