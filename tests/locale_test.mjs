import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';
import assert from 'node:assert/strict';

const source=readFileSync(new URL('../web/locale.js',import.meta.url),'utf8');
function launch(locale,storage=new Map()){
  const heading={textContent:'灵敏度'};
  const button={label:'关闭体感设置',getAttribute(){return this.label;},setAttribute(_,label){this.label=label;}};
  const document={
    documentElement:{},
    querySelectorAll:selector=>selector==='[data-i18n]'?[heading]:selector==='[data-i18n-aria-label]'?[button]:[]
  };
  const window={};
  runInNewContext(source,{window,document,navigator:{language:locale},
    localStorage:{getItem:key=>storage.get(key),setItem:(key,value)=>storage.set(key,value)}});
  return {window,document,heading,button,storage};
}

for(const [locale,expected] of [['','zh'],['zh','zh'],['zh-Hans-CN','zh'],['zh-Hant-HK','zh'],
  ['en-US','en'],['ja-JP','en'],['zh-SG','en'],['und','zh']]){
  const {window}=launch(locale);
  assert.equal(window.noArtLanguage(),expected,locale);
}
const app=launch('en-US');
assert.equal(app.heading.textContent,'Sensitivity');
assert.equal(app.button.label,'Close gyro settings');
assert.equal(app.window.noArtText('权限已允许。让抖动保持在刻度线以内。'),'Permission granted. Keep motion below the threshold.');
for(const mark of ['NO ART FPS','FIRE'])assert.equal(app.window.noArtText(mark),mark);
app.window.noArtSetLanguage('zh');
assert.equal(app.document.documentElement.lang,'zh-CN');
assert.equal(app.heading.textContent,'灵敏度');
assert.equal(app.button.label,'关闭体感设置');
assert.equal(launch('en-US',app.storage).window.noArtLanguage(),'zh');
app.window.noArtSetLanguage('en');
assert.equal(launch('zh-CN',app.storage).window.noArtLanguage(),'en');
assert.equal(app.heading.textContent,'Sensitivity');
console.log('LOCALE_PASS: browser locale, Chinese fallback, preserved title, accessible text and persisted manual switch');
