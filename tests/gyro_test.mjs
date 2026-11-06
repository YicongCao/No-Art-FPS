import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';
import assert from 'node:assert/strict';
const source=readFileSync(new URL('../web/gyro.js',import.meta.url),'utf8');
function fixture(permission){
  let time=0;const listeners=new Map(),timers=new Map(),storage=new Map(),states=[];
  const host={isSecureContext:true,DeviceMotionEvent:permission?{requestPermission:permission}:{},screen:{orientation:{angle:90}},localStorage:{getItem:k=>storage.get(k),setItem:(k,v)=>storage.set(k,v)},addEventListener:(k,v)=>listeners.set(k,v),removeEventListener:k=>listeners.delete(k),setTimeout:(fn,ms)=>{timers.set(fn,ms);return fn;},clearTimeout:fn=>timers.delete(fn)};
  runInNewContext(source,{window:host,performance:{now:()=>time}});
  const gyro=host.NoArtGyro.create({host,now:()=>time,changed:s=>states.push(s)});
  const sample=(beta=0,gamma=0,alpha=0,dt=16,g=null)=>{time+=dt;listeners.get('devicemotion')?.({rotationRate:{beta,gamma,alpha},accelerationIncludingGravity:g});};
  async function start(bias=[0,0,0]){await gyro.enable();for(let n=0;n<50;n++)sample(...bias);assert.equal(gyro.snapshot().ready,true);gyro.setContext({running:true});}
  return {gyro,host,listeners,timers,storage,states,sample,start,advance:ms=>{time+=ms;}};
}
let f=fixture();assert.equal(f.gyro.snapshot().enabled,false);assert.equal(f.listeners.size,0);
await f.start([.2,-.1,.15]);
for(let n=0;n<40;n++)f.sample(.2,-.1,.15);
assert.equal(f.gyro.read().gyroYaw,0);assert.equal(f.gyro.read().gyroPitch,0);
// 90 degrees landscape: beta is screen Y; -gamma is screen X.
for(let n=0;n<5;n++)f.sample(30.2,-.1,.15);
let packet=f.gyro.read();assert.ok(packet.gyroYaw>0);assert.ok(Math.abs(packet.gyroPitch)<1e-9);
assert.equal(f.gyro.read().gyroYaw,0,'Consume deltas once');
f.gyro.reset();for(let n=0;n<5;n++)f.sample(.2,-30.1,.15);
assert.ok(f.gyro.read().gyroPitch>0);
f.host.screen.orientation.angle=270;f.gyro.reset();for(let n=0;n<5;n++)f.sample(30.2,-.1,.15);
assert.ok(f.gyro.read().gyroYaw<0,'Opposite landscape reverses device X');
// Gravity projection supports aiming when the phone is tilted nearly flat.
f.gyro.reset();for(let n=0;n<5;n++)f.sample(.2,-.1,30.15,16,{x:0,y:0,z:9.81});
assert.ok(f.gyro.read().gyroYaw>0);
// Sensitivity is independent of pixel movement and persisted; enabling is not persisted.
const measure=()=>{for(let n=0;n<5;n++)f.sample(30.2,-.1,.15);return Math.abs(f.gyro.read().gyroYaw);};
f.gyro.setSensitivity(1);const base=measure();f.gyro.setSensitivity(2);assert.ok(Math.abs(measure()/base-2)<1e-8);
assert.equal(f.storage.get('no-art-gyro-sensitivity'),'2');f.gyro.setSensitivity(99);assert.equal(f.gyro.snapshot().sensitivity,3);
f.gyro.setSensitivity(NaN);assert.equal(f.gyro.snapshot().sensitivity,3);
for(const context of [{running:false},{visible:false},{focused:false},{landscape:false}]){
  f.gyro.setContext({running:true,visible:true,focused:true,landscape:true});measure();
  f.gyro.setContext(context);for(let n=0;n<4;n++)f.sample(30,20,10);assert.equal(f.gyro.read().gyroYaw,0);assert.equal(f.gyro.read().gyroPitch,0);
}
f.gyro.setContext({running:true,visible:true,focused:true,landscape:true});
f.sample(30,20,10,2000);assert.equal(f.gyro.read().gyroYaw,0,'No integration across long gap');
f.sample(30,20,10);f.advance(300);assert.equal(f.gyro.read().gyroYaw,0,'Stale buffered sample discarded');
f.sample(null,null,null);assert.equal(f.gyro.read().gyroPitch,0);
f.gyro.disable();assert.equal(f.listeners.size,0);assert.equal(f.gyro.read().gyroYaw,0);
// Explicit permission, denial, no hardware, insecure context and revoked pending enable.
f=fixture(async()=>'denied');await f.gyro.enable();assert.equal(f.gyro.snapshot().enabled,false);assert.equal(f.listeners.size,0);
f=fixture();await f.gyro.enable();f.sample(null,null,null);for(const timer of [...f.timers.keys()])timer();assert.equal(f.gyro.snapshot().enabled,false);assert.match(f.gyro.snapshot().status,/未检测到/);
f=fixture();f.host.isSecureContext=false;await f.gyro.enable();assert.equal(f.listeners.size,0);
let resolvePermission;f=fixture(()=>new Promise(resolve=>{resolvePermission=resolve;}));const enabling=f.gyro.enable();f.gyro.disable();resolvePermission('granted');await enabling;assert.equal(f.listeners.size,0);
f=fixture(async()=>{throw Error('permission');});await f.gyro.enable();assert.equal(f.gyro.snapshot().enabled,false);
f=fixture();await f.gyro.enable();for(let n=0;n<400;n++)f.sample(10,0,0);assert.equal(f.gyro.snapshot().ready,false);assert.match(f.gyro.snapshot().status,/重新校准/);f.gyro.calibrate();for(let n=0;n<50;n++)f.sample();assert.equal(f.gyro.snapshot().ready,true);
// Rate integration should be stable across sensor event frequencies.
async function integrate(dt){const test=fixture();await test.start();test.sample(30,0,0,dt);let total=0;for(let n=0;n<1000/dt;n++){test.sample(30,0,0,dt);total+=test.gyro.read().gyroYaw;}return total;}
const fast=await integrate(10),slow=await integrate(20);assert.ok(Math.abs(fast-slow)<.01);
const shell=readFileSync(new URL('../web/shell.html',import.meta.url),'utf8');
assert.ok(!shell.includes('href="https://cv.yicong.me'));
assert.ok(shell.includes('...gyro.read()'));assert.ok(shell.includes('syncGyro(alive)'));
console.log('GYRO_PASS: opt-in permission, calibration, coordinate mapping, gravity, sensitivity, consume-once, lifecycle, null data, timeout, cancellation, event rates');
