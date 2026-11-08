const CENTER_X = 280;
const CENTER_Y = 110;
const FOCAL_LENGTH = 310;
const TARGET_ANGLES = [[-.16,.02],[.14,.11],[-.025,-.11]];
const HOLD_MS = 280;
const GIMBAL_ANGLES = [-38,32,86];

// Room coordinates are in the same axes as Godot's first-person camera.
const WALLS = {
  back: [[-4,2.6,-8],[4,2.6,-8],[4,-2,-8],[-4,-2,-8]],
  left: [[-4,2.6,-2],[-4,2.6,-8],[-4,-2,-8],[-4,-2,-2]],
  right: [[4,2.6,-8],[4,2.6,-2],[4,-2,-2],[4,-2,-8]],
  floor: [[-4,-2,-8],[4,-2,-8],[4,-2,-2],[-4,-2,-2]]
};

function project([x,y,z], yaw, pitch) {
  const cy = Math.cos(yaw), sy = Math.sin(yaw);
  const cp = Math.cos(pitch), sp = Math.sin(pitch);
  const side = cy*x-sy*z;
  const ahead = sy*x+cy*z;
  const height = cp*y+sp*ahead;
  const depth = Math.max(.25,sp*y-cp*ahead);
  return [CENTER_X+FOCAL_LENGTH*side/depth,CENTER_Y-FOCAL_LENGTH*height/depth];
}

function makeTarget(yaw,pitch) {
  const distance = 7.9;
  return [-Math.sin(yaw)*Math.cos(pitch)*distance,Math.sin(pitch)*distance,-Math.cos(yaw)*Math.cos(pitch)*distance];
}

const TARGETS = TARGET_ANGLES.map(([yaw,pitch])=>makeTarget(yaw,pitch));

export function setupGyroPanel({makeGyro, sync, isActive, isLandscape}) {
  const get = id=>document.getElementById(id);
  const t = text=>window.noArtText?.(text)??text;
  const panel = get('gyro-panel');
  const canvas = get('canvas');
  const heading = get('gyro-title');
  const status = get('gyro-status');
  const closeButton = get('gyro-close');
  const startButton = get('gyro-start');
  const toggle = get('gyro-toggle');
  const slider = get('gyro-sensitivity');
  const calibrate = get('gyro-calibrate');
  const practiceButton = get('gyro-practice-again');
  const practiceBack = get('gyro-practice-back');
  const calibrationView = get('gyro-calibration');
  const calibrationRing = get('gyro-calibration-ring');
  const gimbalRings = [...calibrationView.querySelectorAll('[data-gyro-ring]')];
  const reticleTarget = get('gyro-target');
  const holdRing = get('gyro-hold');
  const axes = [...panel.querySelectorAll('[data-gyro-axis]')];
  const steps = [...panel.querySelectorAll('[data-gyro-step]')];
  const wallShapes = [...panel.querySelectorAll('[data-gyro-wall]')];
  let step = '';
  let entering = false;
  let started = false;
  let frame = 0;
  let previousTime = 0;
  let yaw = 0, pitch = 0, held = 0, index = 0;
  let returnFocus = null;
  let displayedRates;
  let displayedProgress = -1;
  const gyro = makeGyro(update);

  function stopFrame() {
    cancelAnimationFrame(frame);
    frame=0;
  }

  function show(next) {
    stopFrame();
    if(panel.hidden)returnFocus=document.activeElement;
    step=next;
    panel.hidden=false;
    canvas.inert=true;
    for(const item of steps)item.hidden=!item.dataset.gyroStep.split(' ').includes(step);
    panel.dataset.step=step;
    closeButton.hidden=step!=='settings';
    const titles={choice:'启用体感瞄准？',setup:'校准体感',practice:'体感练习',ready:'体感已就绪',settings:'体感瞄准'};
    heading.textContent=t(titles[step]);
    if(step==='setup'){
      displayedRates=undefined;
      displayedProgress=-1;
    }
    heading.focus({preventScroll:true});
    sync();
    update(gyro.snapshot());
  }

  function close(restore=true) {
    if(panel.hidden)return;
    stopFrame();
    step='';
    panel.hidden=true;
    canvas.inert=false;
    sync();
    if(restore)(returnFocus?.offsetWidth?returnFocus:canvas).focus({preventScroll:true});
  }

  function chooseTouch() {
    gyro.choose(false);
    gyro.disable();
    if(entering)close();
    else show('settings');
  }

  function beginSetup() {
    started=false;
    show('setup');
  }

  function drawCalibration() {
    const {rates,limit,progress}=gyro.calibrationFeedback();
    const fill=started?progress:0;
    if(rates===displayedRates&&fill===displayedProgress)return;
    displayedRates=rates;
    displayedProgress=fill;
    calibrationView.dataset.signal=rates?(rates.some(rate=>Math.abs(rate)>limit)?'shaky':'steady'):'waiting';
    calibrationRing.setAttribute('stroke-dashoffset',String(1-fill));
    calibrationView.setAttribute('aria-valuenow',String(Math.floor(fill*100)));
    gimbalRings.forEach((ring,i)=>{
      const turn=rates?Math.max(-2.5,Math.min(2.5,rates[i]/limit))*22:0;
      ring.setAttribute('transform',`rotate(${GIMBAL_ANGLES[i]+turn})`);
    });
  }

  function calibrationFrame() {
    drawCalibration();
    frame=requestAnimationFrame(calibrationFrame);
  }

  function recenter() {
    gyro.reset();
    yaw=0;
    pitch=0;
    held=0;
    drawRoom();
  }

  function drawRoom() {
    for(const wall of wallShapes){
      const points=WALLS[wall.dataset.gyroWall].map(point=>project(point,yaw,pitch).join(','));
      wall.setAttribute('points',points.join(' '));
    }
    const [x,y]=project(TARGETS[index],yaw,pitch);
    reticleTarget.setAttribute('transform',`translate(${x} ${y})`);
    return Math.hypot(x-CENTER_X,y-CENTER_Y)<16;
  }

  function practiceFrame(time) {
    const delta=previousTime?Math.min(50,time-previousTime):0;
    previousTime=time;
    const packet=gyro.read();
    yaw=Math.max(-.67,Math.min(.67,yaw+packet.gyroYaw));
    pitch=Math.max(-.42,Math.min(.42,pitch+packet.gyroPitch));
    const aligned=drawRoom();
    held=aligned&&isActive()?held+delta:0;
    holdRing.setAttribute('stroke-dasharray',`${Math.min(100,100*held/HOLD_MS)} 100`);
    if(held>=HOLD_MS){
      index++;
      held=0;
      if(index===TARGETS.length){
        gyro.finishPractice();
        show('ready');
        return;
      }
      update(gyro.snapshot());
    }
    frame=requestAnimationFrame(practiceFrame);
  }

  function beginPractice() {
    index=0;
    previousTime=0;
    show('practice');
    recenter();
    frame=requestAnimationFrame(practiceFrame);
  }

  function update(state) {
    if(step==='setup'&&started&&state.ready){
      stopFrame();
      drawCalibration();
      // Paint the closed ring before replacing the calibration view.
      frame=requestAnimationFrame(()=>{
        frame=requestAnimationFrame(()=>{
          frame=0;
          if(!isLandscape())gyro.calibrate();
          else if(!state.practicePassed)beginPractice();
          else show(entering?'ready':'settings');
        });
      });
      return;
    }
    if(step==='practice'&&!state.ready){
      started=true;
      show('setup');
      return;
    }
    get('gyro-yes').disabled=!state.available;
    startButton.disabled=!state.available||state.pending||state.calibrating;
    if(state.pending)startButton.textContent=t('等待授权');
    else if(state.calibrating)startButton.textContent=t('校准中');
    else startButton.textContent=t(state.canRequest&&!state.enabled?'请求权限并校准':'开始校准');
    toggle.textContent=t(state.enabled?'关闭':'启用');
    toggle.disabled=!state.available;
    toggle.setAttribute('aria-checked',String(state.enabled));
    slider.value=String(state.sensitivity);
    get('gyro-value').textContent=state.sensitivity.toFixed(2)+'x';
    for(const axis of axes)axis.checked=state.flipped[axis.dataset.gyroAxis];
    calibrate.disabled=!state.enabled;
    practiceButton.disabled=!state.ready;
    practiceBack.hidden=!state.practicePassed;
    get('gyro-practice-touch').hidden=state.practicePassed;
    get('gyro-continue').textContent=t(entering?'进入游戏':'返回设置');
    if(step==='setup'){
      heading.textContent=t(state.calibrating?'保持稳定':'校准体感');
      drawCalibration();
      const animating=state.calibrating&&isLandscape();
      if(animating&&!frame)frame=requestAnimationFrame(calibrationFrame);
      else if(!animating&&frame)stopFrame();
    }
    if(step==='choice')status.textContent=t(state.available?'用转动设备来微调准星。':state.status);
    else if(step==='setup'){
      const showStatus=!state.available||state.pending||(state.calibrating?!isActive():started);
      status.textContent=showStatus?t(state.status):'';
    }
    else if(step==='practice')status.textContent=`${t('转动设备，把准星停在亮靶上。')} ${index}/${TARGETS.length}`;
    else if(step==='ready')status.textContent=t(state.practicePassed?'校准完成，瞄准练习已通过。':'校准完成。');
    else status.textContent=t(state.status);
  }

  get('gyro-yes').onclick=()=>{gyro.choose(true);beginSetup();};
  for(const button of panel.querySelectorAll('[data-gyro-touch]'))button.onclick=chooseTouch;
  startButton.onclick=()=>{
    if(!isLandscape())return;
    started=true;
    if(gyro.snapshot().enabled)gyro.calibrate();
    else gyro.enable();
  };
  toggle.onclick=()=>{
    if(gyro.snapshot().enabled)chooseTouch();
    else{gyro.choose(true);beginSetup();}
  };
  slider.oninput=()=>gyro.setSensitivity(slider.value);
  for(const axis of axes)axis.onchange=()=>gyro.setAxisFlip(axis.dataset.gyroAxis,axis.checked);
  calibrate.onclick=beginSetup;
  practiceButton.onclick=beginPractice;
  get('gyro-practice-optional').onclick=beginPractice;
  practiceBack.onclick=()=>show(entering?'ready':'settings');
  get('gyro-recenter').onclick=recenter;
  get('gyro-continue').onclick=()=>entering?close():show('settings');
  closeButton.onclick=()=>close();
  panel.onclick=event=>{if(event.target===panel&&step==='settings')close();};
  panel.onkeydown=event=>{
    event.stopPropagation();
    if(event.key==='Escape'&&step==='settings'){event.preventDefault();close();}
    if(event.key==='Escape'&&step==='practice'&&!practiceBack.hidden){event.preventDefault();practiceBack.onclick();}
    if(event.key==='Tab'){
      const items=[...panel.querySelectorAll('button:not(:disabled),input:not(:disabled)')].filter(item=>item.offsetWidth);
      if(!items.length)return;
      const current=items.indexOf(document.activeElement);
      const next=current<0?(event.shiftKey?items.length-1:0):(current+(event.shiftKey?-1:1)+items.length)%items.length;
      event.preventDefault();
      items[next].focus();
    }
  };

  return {
    gyro,
    get practicing(){return step==='practice';},
    openEntry(){
      const state=gyro.snapshot();
      if(state.preference===false)return;
      entering=true;
      if(state.preference)beginSetup();
      else show('choice');
    },
    openSettings(){entering=false;show('settings');},
    close
  };
}
