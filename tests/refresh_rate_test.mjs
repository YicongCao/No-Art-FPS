import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';
import assert from 'node:assert/strict';
const source=readFileSync(new URL('../web/performance.js',import.meta.url),'utf8');
function probe(hz){
 const callbacks=[];
 const window={};const document={hidden:false};
 runInNewContext(source,{window,document,location:{search:'',hostname:'127.0.0.1'},URLSearchParams,requestAnimationFrame:fn=>callbacks.push(fn),devicePixelRatio:3,innerWidth:844,innerHeight:390});
 for(let i=1;i<180;i++)callbacks.shift()(i*1000/hz);
 return {window,document,callbacks};
}
assert.equal(probe(60).window.noArtTargetFPS(),60);
assert.equal(probe(120).window.noArtTargetFPS(),120);
assert.equal(probe(90).window.noArtTargetFPS(),60);
const p=probe(120);
for(let i=180;i<480;i++)p.callbacks.shift()(1500+(i-180)*1000/30);
assert.equal(p.window.noArtTargetFPS(),120,'Slow game frames must not reclassify a measured high-refresh display');
p.document.hidden=true;
for(let i=0;i<30;i++)p.callbacks.shift()(20000+i*1000);
assert.equal(p.window.noArtTargetFPS(),120);
const config={canvas:{width:10,height:10}};p.window.noArtConfigurePerformance(config);assert.equal(config.canvasResizePolicy,undefined);
console.log('REFRESH_RATE_PASS: 60/90/120 Hz, hidden tabs, no default canvas override');
