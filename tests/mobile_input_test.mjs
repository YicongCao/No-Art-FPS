// Contract test for the actual Web shell bridge, without a browser or Godot.
import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';
import assert from 'node:assert/strict';
const shell=readFileSync(new URL('../web/shell.html',import.meta.url),'utf8');
const source=shell.match(/<script>\s*(window.noArtMobile=[\s\S]*?)<\/script>/)[1];
class Element {
  handlers={}; style={}; dataset={}; hidden=true; classes=new Set();
  classList={add:c=>this.classes.add(c),remove:c=>this.classes.delete(c),toggle:(c,v)=>v?this.classes.add(c):this.classes.delete(c)};
  addEventListener(type,fn){(this.handlers[type]??=[]).push(fn);}
  setPointerCapture(){}
  setAttribute(name,value){this[name]=value;}
  focus(){}
  closest(){return this.id?this:null;}
  emit(type,event={}){for(const fn of this.handlers[type]??[])fn({preventDefault(){},...event});}
}
const elements=new Map();
const get=s=>{if(!elements.has(s))elements.set(s,new Element());return elements.get(s);};
for(const id of ['fire','interact','jump','reload','pause'])get('#'+id).id=id;
const document=new Element();
document.body=new Element();document.documentElement=new Element();document.hidden=false;
document.querySelector=get;document.getElementById=id=>get('#'+id);
document.querySelectorAll=()=>[...elements.values()].filter(e=>e.classes.has('held'));
const window=new Element();
const timers=new Map();let nextTimer=0;
const context={window,document,location:{search:'?touch=1'},matchMedia:()=>({matches:false}),URLSearchParams,innerWidth:844,innerHeight:390,screen:{},setTimeout:(fn,ms)=>{timers.set(++nextTimer,{fn,ms});return nextTimer;},clearTimeout:id=>timers.delete(id),console};
let sensorTime=0;
Object.assign(window,{isSecureContext:true,DeviceMotionEvent:{},screen:{orientation:{angle:90}},setTimeout:context.setTimeout,clearTimeout:context.clearTimeout,removeEventListener(type,fn){this.handlers[type]=(this.handlers[type]??[]).filter(item=>item!==fn);}});
context.performance={now:()=>sensorTime};
runInNewContext(readFileSync(new URL('../web/gyro.js',import.meta.url),'utf8'),context);
runInNewContext(source,context);
const ui=get('#touch-ui');
const read=()=>JSON.parse(window.noArtReadTouch());
const pointer=(type,id,x,y,target=ui)=>ui.emit(type,{pointerId:id,clientX:x,clientY:y,target});
window.noArtState('RUNNING');
pointer('pointerdown',1,100,300);pointer('pointermove',1,130,260);
pointer('pointerdown',2,500,180);pointer('pointermove',2,520,170);
pointer('pointerdown',3,780,300,get('#fire'));
let p=read();assert.equal(p.x,.6);assert.equal(p.y,-.8);assert.equal(p.dx,20);assert.equal(p.dy,-10);assert.equal(p.fire,true);
p=read();assert.equal(p.dx,0);assert.equal(p.dy,0);assert.equal(p.fire,true);
// Two thumbs can move and aim while firing: dragging the fire button also aims.
pointer('pointermove',3,795,280);p=read();assert.equal(p.dx,15);assert.equal(p.dy,-20);assert.equal(p.fire,true);
// A second fire finger must not own/release the first finger's action.
pointer('pointerdown',4,780,300,get('#fire'));pointer('pointerup',4,780,300);assert.equal(read().fire,true);
pointer('pointercancel',3,780,300);assert.equal(read().fire,false);
pointer('lostpointercapture',1,130,260);assert.equal(read().x,0);
for(const action of ['jump','reload','pause']){pointer('pointerdown',5,700,200,get('#'+action));assert.equal(read()[action],true);assert.equal(read()[action],false);pointer('pointerup',5,700,200);}
pointer('pointerdown',6,100,300);pointer('pointermove',6,300,500);p=read();assert.ok(Math.hypot(p.x,p.y)<=1.000001);
context.innerWidth=390;context.innerHeight=844;window.emit('resize');p=read();assert.equal(p.blocked,true);assert.equal(p.x,0);assert.equal(document.body.classes.has('portrait'),true);
context.innerWidth=844;context.innerHeight=390;window.emit('resize');assert.equal(read().blocked,false);
window.emit('blur');assert.equal(read().pause,true);assert.equal(read().pause,false);
document.hidden=true;document.emit('visibilitychange');assert.equal(read().blocked,true);
document.hidden=false;document.emit('visibilitychange');assert.equal(read().blocked,false);
// Background and foreground may both happen before Godot gets another tick.
document.hidden=true;document.emit('visibilitychange');document.hidden=false;document.emit('visibilitychange');assert.equal(read().pause,true);
window.emit('blur');window.emit('resize');assert.equal(read().pause,true);
document.emit('fullscreenchange');assert.equal(read().pause,true);
pointer('pointerdown',7,780,300,get('#fire'));window.noArtState('PAUSED');p=read();assert.equal(p.fire,false);assert.equal(p.x,0);
console.log('MOBILE_INPUT_PASS: simultaneous move/look/fire, ownership, one-shot actions, cancellation, orientation, blur, visibility, fullscreen exit, state reset');

// Fullscreen failure must not create an automatic in-game banner.
const note=get('#immersive-note'),full=get('#immersive');
window.noArtState('TITLE');get('#canvas').emit('pointerdown');
await Promise.resolve();assert.equal(note.hidden,true);
await full.onclick();assert.equal(note.hidden,false);
assert.equal(note.textContent,'此浏览器暂不支持全屏');
assert.equal([...timers.values()][0].ms,2400);
[...timers.values()][0].fn();assert.equal(note.hidden,true);
await full.onclick();assert.equal(note.hidden,false);
window.noArtState('LOADING');assert.equal(note.hidden,true);assert.equal(timers.size,0);
window.noArtState('RUNNING');await full.onclick();assert.equal(note.hidden,true);
// A request can reject after a menu transitions into gameplay.
window.noArtState('PAUSED');let rejectFullscreen;
document.documentElement.requestFullscreen=()=>new Promise((_,reject)=>{rejectFullscreen=reject;});
const request=full.onclick();window.noArtState('RUNNING');rejectFullscreen(Error('denied'));
await request;assert.equal(note.hidden,true);assert.equal(timers.size,0);
// Success must also clear an earlier manual hint.
window.noArtState('PAUSED');delete document.documentElement.requestFullscreen;
await full.onclick();assert.equal(note.hidden,false);
document.documentElement.requestFullscreen=async()=>{document.fullscreenElement=document.documentElement;};
await full.onclick();assert.equal(note.hidden,true);assert.equal(timers.size,0);
// SVG child targets resolve to their button, including held feedback.
window.noArtState('RUNNING');const svgChild={closest:()=>get('#fire')};
pointer('pointerdown',9,780,300,svgChild);assert.equal(get('#fire').classes.has('held'),true);
pointer('pointerup',9,780,300,svgChild);assert.equal(get('#fire').classes.has('held'),false);
assert.ok(!/\p{Extended_Pictographic}/u.test(shell),'No emoji graphics in the Web shell');
assert.ok(!/[\u26f6\u2197\u25ce\u2191\u21bb\u2161]/u.test(shell),'Use SVG instead of icon glyphs');
for(const id of ['immersive','fire','jump','reload','pause'])assert.match(shell,new RegExp('id="'+id+'"[^>]*><svg'));
assert.ok(!shell.includes('添加到主屏幕'));
console.log('MOBILE_UI_PASS: SVG controls, silent automatic failure, 2.4s manual hint, state cleanup, late rejection, successful retry');

// Verify the real gyro module feeds the same packet as touch, and death clears it.
window.emit('focus');window.noArtState('PAUSED');await get('#gyro-toggle').onclick();
const motion=(beta=0)=>{sensorTime+=16;window.emit('devicemotion',{rotationRate:{alpha:0,beta,gamma:0}});};
for(let i=0;i<50;i++)motion();
window.noArtState('RUNNING');for(let i=0;i<5;i++)motion(30);
p=read();assert.ok(p.gyroYaw>0);assert.equal(read().gyroYaw,0);
for(let i=0;i<5;i++)motion(30);
p=JSON.parse(window.noArtReadTouch(false));assert.equal(p.gyroYaw,0);
window.noArtState('PAUSED');for(let i=0;i<5;i++)motion(30);assert.equal(read().gyroYaw,0);
await get('#gyro-toggle').onclick();
console.log('GYRO_BRIDGE_PASS: real sensor module, packet consumption, respawn and pause gating');

window.noArtMode('defuse');window.noArtState('RUNNING');
pointer('pointerdown',90,690,230,get('#interact'));
assert.equal(read().interact,true);assert.equal(read().interact,true);
pointer('pointercancel',90,690,230);assert.equal(read().interact,false);
pointer('pointerdown',91,690,230,get('#interact'));
window.emit('blur');assert.equal(read().interact,false);
console.log('DEFUSE_TOUCH_PASS: held interaction, cancel and background release');
