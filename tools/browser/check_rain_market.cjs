// Run against the same viewport and machine for before/after comparisons.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs=require('node:fs');const path=require('node:path');const assert=require('node:assert/strict');
(async()=>{
 const [url,out,mode='desktop']=process.argv.slice(2);fs.mkdirSync(out,{recursive:true});
 const mobile=mode==='touch';const duration=Number(process.env.SAMPLE_SECONDS||60);
 const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
 try{
 const context=await browser.newContext({viewport:mobile?{width:844,height:390}:{width:1280,height:720},deviceScaleFactor:1,hasTouch:mobile,isMobile:mobile});
 await context.addInitScript(id=>{localStorage.setItem('no-art-fps.title.v1',JSON.stringify({id}));},process.env.MAP_ID||'rain_market');
 const page=await context.newPage();const errors=[];const logs=[];
 page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{const t=m.text();if(m.type()==='error'||/SCRIPT ERROR|Shader.*error|ERROR:|GL_INVALID_|WebGL.*CONTEXT_LOST/.test(t))errors.push(t);if(/Godot Engine|WebGL/.test(t))logs.push(t)});
 const start=Date.now();await page.goto(url,{waitUntil:'domcontentloaded',timeout:90000});await page.locator('#loading').waitFor({state:'hidden',timeout:120000});
 const loadMs=Date.now()-start;
 if(mobile && await page.locator('#gyro-panel').isVisible())await page.locator('[data-gyro-touch]:visible').first().tap();
 if(await page.locator('#toolbar-tip').isVisible())await page.locator('#toolbar-tip-ignore').click();
 await page.screenshot({path:path.join(out,'title.png')});
 const press=async(x,y)=>mobile?page.touchscreen.tap(x,y):page.mouse.click(x,y);
 await press(mobile?128:169,mobile?321:615);
 await page.waitForFunction(()=>['RUNNING','CAPTURING'].includes(document.body.dataset.game),null,{timeout:45000});
 if(await page.evaluate(()=>document.body.dataset.game==='CAPTURING'))await press(mobile?422:640,mobile?195:360);
 await page.waitForFunction(()=>document.body.dataset.game==='RUNNING');
 await page.waitForTimeout(250);await page.screenshot({path:path.join(out,'gameplay.png')});await page.waitForTimeout(1250);
 // A real running round with a stationary viewpoint, firing and reloading.
 if(!mobile)await page.mouse.down();
 const samplePromise=page.evaluate(seconds=>new Promise(resolve=>{const a=[];let last=performance.now();const begin=last;function tick(t){a.push(t-last);last=t;if(t-begin<seconds*1000)requestAnimationFrame(tick);else{a.shift();a.sort((x,y)=>x-y);const c=document.querySelector('#canvas');resolve({seconds:(t-begin)/1000,frames:a.length,meanMs:a.reduce((s,v)=>s+v,0)/a.length,p50Ms:a[a.length>>1],p95Ms:a[Math.floor(a.length*.95)],p99Ms:a[Math.floor(a.length*.99)],maxMs:a.at(-1),canvas:[c.width,c.height],state:document.body.dataset.game,heapBytes:performance.memory?.usedJSHeapSize})}}requestAnimationFrame(tick)}),duration);
 for(let t=0;t<duration;t+=4){await page.waitForTimeout(Math.min(4,duration-t)*1000);if(!mobile)await page.keyboard.press('r');if(t===44)await page.screenshot({path:path.join(out,'frenzy.png')});}
 const performanceData=await samplePromise;if(!mobile)await page.mouse.up();
 await page.screenshot({path:path.join(out,'end.png')});
 const data={url,mode,loadMs,performance:performanceData,errors,logs,note:'Hardware Chrome RAF intervals, not GPU timer queries. Fresh browser cache; localhost loading is not an internet download benchmark.'};
 fs.writeFileSync(path.join(out,'web.json'),JSON.stringify(data,null,2));console.log(JSON.stringify(data));assert.deepEqual(errors,[]);await context.close();
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
