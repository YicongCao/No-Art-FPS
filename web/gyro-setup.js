const CENTER_X = 280;
const CENTER_Y = 110;
const FOCAL_LENGTH = 310;
const TARGET_ANGLES = [[-.16,.02],[.14,.11],[-.025,-.11]];
const HOLD_MS = 280;

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

export function setupGyroPanel({makeGyro, sync, isActive}) {
  const get = id=>document.getElementById(id);
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
  const gyro = makeGyro(update);

  function show(next) {
    cancelAnimationFrame(frame);
    if(panel.hidden)returnFocus=document.activeElement;
    step=next;
    panel.hidden=false;
    canvas.inert=true;
    for(const item of steps)item.hidden=!item.dataset.gyroStep.split(' ').includes(step);
    panel.dataset.step=step;
    closeButton.hidden=step!=='settings';
    const titles={choice:'启用体感瞄准？',setup:'校准体感',practice:'体感练习',ready:'体感已就绪',settings:'体感瞄准'};
    heading.textContent=titles[step];
    heading.focus({preventScroll:true});
    sync();
    update(gyro.snapshot());
  }

  function close(restore=true) {
    if(panel.hidden)return;
    cancelAnimationFrame(frame);
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
      if(!state.practicePassed)beginPractice();
      else if(entering)show('ready');
      else show('settings');
      return;
    }
    if(step==='practice'&&!state.ready){
      started=true;
      show('setup');
      return;
    }
    get('gyro-yes').disabled=!state.available;
    startButton.disabled=!state.available||state.pending||state.calibrating;
    startButton.textContent=state.canRequest&&!state.enabled?'请求权限并校准':'开始校准';
    toggle.textContent=state.enabled?'关闭':'启用';
    toggle.disabled=!state.available;
    toggle.setAttribute('aria-checked',String(state.enabled));
    slider.value=String(state.sensitivity);
    get('gyro-value').textContent=state.sensitivity.toFixed(2)+'x';
    for(const axis of axes)axis.checked=state.flipped[axis.dataset.gyroAxis];
    calibrate.disabled=!state.enabled;
    practiceButton.disabled=!state.ready;
    get('gyro-continue').textContent=entering?'进入游戏':'返回设置';
    if(step==='choice')status.textContent=state.available?'用转动设备来微调准星。':state.status;
    else if(step==='setup')status.textContent=!state.available||started?state.status:'横握设备，调整到舒服的姿势，再保持静止。';
    else if(step==='practice')status.textContent=`转动设备，把准星停在亮靶上。 ${index}/${TARGETS.length}`;
    else if(step==='ready')status.textContent=state.practicePassed?'校准完成，瞄准练习已通过。':'校准完成。';
    else status.textContent=state.status;
  }

  get('gyro-yes').onclick=()=>{gyro.choose(true);beginSetup();};
  for(const button of panel.querySelectorAll('[data-gyro-touch]'))button.onclick=chooseTouch;
  startButton.onclick=()=>{
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
  get('gyro-recenter').onclick=recenter;
  get('gyro-continue').onclick=()=>entering?close():show('settings');
  closeButton.onclick=()=>close();
  panel.onclick=event=>{if(event.target===panel&&step==='settings')close();};
  panel.onkeydown=event=>{
    event.stopPropagation();
    if(event.key==='Escape'&&step==='settings'){event.preventDefault();close();}
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
