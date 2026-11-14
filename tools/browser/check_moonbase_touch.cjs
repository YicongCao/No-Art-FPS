const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
(async()=>{
 const [url,out]=process.argv.slice(2);fs.mkdirSync(out,{recursive:true});
 const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
 try{
  const context=await browser.newContext({viewport:{width:844,height:390},hasTouch:true,isMobile:true,deviceScaleFactor:1});
  const page=await context.newPage(),errors=[];
  page.on('pageerror',e=>errors.push(String(e)));
  page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
  await page.goto(url+'?touch=1');await page.locator('#loading').waitFor({state:'hidden',timeout:120000});
  if(await page.locator('#gyro-panel').isVisible())await page.locator('[data-gyro-touch]:visible').first().tap();
  if(await page.locator('#toolbar-tip').isVisible())await page.locator('#toolbar-tip-ignore').tap();
  assert.equal(await page.locator('#comedy-mode').isVisible(),false);
  await page.touchscreen.tap(128,321);
  await page.waitForFunction(()=>document.body.dataset.game==='RUNNING',null,{timeout:45000});
  await page.waitForTimeout(1000);await page.screenshot({path:path.join(out,'opening.png')});
  await page.evaluate(()=>{const read=window.noArtReadTouch;window.touchEvidence={};window.noArtReadTouch=(...args)=>{const raw=read(...args),v=JSON.parse(raw);if((Math.abs(v.x)+Math.abs(v.y))>.1&&v.fire)window.touchEvidence.moveAndFire=true;for(const k of ['reload','grenade'])if(v[k])window.touchEvidence[k]=true;return raw;}});
  const stick=await page.locator('#stick').boundingBox(),fire=await page.locator('#fire').boundingBox();
  const cdp=await context.newCDPSession(page);
  const points=[{id:1,x:stick.x+stick.width/2,y:stick.y+stick.height/2},{id:2,x:fire.x+fire.width/2,y:fire.y+fire.height/2}];
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:points});
  points[0].y-=stick.height*.3;
  await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:points});
  await page.waitForTimeout(1600);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await page.locator('#reload').tap();await page.waitForTimeout(1100);
  await page.locator('#aim').tap();await page.waitForTimeout(300);
  assert.equal(await page.locator('#aim').getAttribute('aria-pressed'),'true');
  await page.screenshot({path:path.join(out,'ads.png')});
  await page.locator('#aim').tap();await page.locator('#grenade').tap();await page.waitForTimeout(1500);
  await page.locator('#pause').tap();await page.waitForFunction(()=>document.body.dataset.game==='PAUSED');
  await page.screenshot({path:path.join(out,'pause.png')});
  // Space/Enter are not used to stand in for touch controls; the resume tile is tapped below.
  await page.touchscreen.tap(306,340);
  await page.waitForTimeout(400);
  await page.waitForFunction(()=>document.body.dataset.game==='RUNNING');
  const state=await page.evaluate(()=>document.body.dataset.game);
  const evidence=await page.evaluate(()=>window.touchEvidence);
  assert.deepEqual(evidence,{moveAndFire:true,reload:true,grenade:true});
  fs.writeFileSync(path.join(out,'touch.json'),JSON.stringify({viewport:[844,390],state,errors,evidence,checks:['start','simultaneous joystick and fire gestures','reload','ADS state','grenade gesture','pause','touch resume'],note:'Desktop Chrome touch emulation; not a physical iOS/Android performance result.'},null,2));
  assert.deepEqual(errors,[]);console.log('MOONBASE_TOUCH_PASS',state);
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exit(1)});
