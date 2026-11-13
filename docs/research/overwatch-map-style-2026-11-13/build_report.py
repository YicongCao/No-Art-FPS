"""Build the offline map inspection page; original screenshots remain unchanged."""
from pathlib import Path
import html,json,re
ROOT=Path(__file__).resolve().parent
md=(ROOT/'README.md').read_text()
def inline(s):
 s=html.escape(s)
 s=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'<a href="\2">\1</a>',s)
 s=re.sub(r'`([^`]+)`',r'<code>\1</code>',s)
 return re.sub(r'\*\*([^*]+)\*\*',r'<strong>\1</strong>',s)
# The report uses plain headings, paragraphs, tables and single-level lists.
blocks=[]; table=[]; listing=False
for line in md.splitlines()+['']:
 if line.startswith('|'):
  table.append(line);continue
 if table:
  cells=[[x.strip() for x in row.strip('|').split('|')] for row in table]
  blocks.append('<div class="table-scroll"><table><thead><tr>'+''.join('<th>'+inline(x)+'</th>' for x in cells[0])+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+inline(x)+'</td>' for x in row)+'</tr>' for row in cells[2:])+'</tbody></table></div>');table=[]
 islist=line.startswith('- ') or bool(re.match(r'^\d+\. ',line))
 if listing and not islist:blocks.append('</ul>');listing=False
 if not line:continue
 if line.startswith('#'):
  n=len(line)-len(line.lstrip('#'));blocks.append(f'<h{min(n+1,6)}>'+inline(line.lstrip('#').strip())+f'</h{min(n+1,6)}>')
 elif islist:
  if not listing:blocks.append('<ul>');listing=True
  blocks.append('<li>'+inline(re.sub(r'^(?:- |\d+\. )','',line))+'</li>')
 else:blocks.append('<p>'+inline(line)+'</p>')
ids=['score_attack','sandgate','bb_office','amusement_park','last_ferry','night_studio','hogwarts','rain_market','baggage_below','snowline','palm_house','ginza_station']
rows=[]
for line in md.splitlines():
 if line.startswith('| ') and len(line.split('|'))==6:
  cells=[c.strip() for c in line.strip('|').split('|')]
  if cells[0] in ['堆货场','沙门','办公室','游乐园','渡轮','摄影棚','城堡','香港雨市','行李层','雪线天文台','棕榈屋','银座站']:rows.append(cells)
assert len(rows)==12
annotations={
'score_attack':[[76,25,'前景货柜应区分角件、框架与凹板，远排波纹降低对比。'],[27,49,'涂鸦、叉车与红色箱体都很醒目；明确装卸区的主景。'],[31,76,'混凝土靠材料与有限轮迹形成尺度，不再整体提亮。']],
'sandgate':[[26,40,'厚窗与棚布已有改善；围绕这一组深化结构，不铺满新细缝。'],[78,40,'长墙应有檐底与墙脚的宽缓变化，保留沙色。'],[55,37,'门楼作为视觉重点，周围次要边框降低竞争。']],
'bb_office':[[56,25,'天花重复管线抢眼，合并非必要线条，保留主要系统走向。'],[20,51,'前后排屏风不必同样清楚，保留近景工位的形体。'],[53,46,'交战背景保留较完整色块；紫墙与海报继续保留。']],
'rain_market':[[48,25,'棚架已有明确结构，减少与主灯竞争的次要接缝。'],[34,75,'碎反光偏密；组织灯下湿区与棚下干区。'],[20,53,'鱼池内胆、台面翻边与退脚优先于再加杂物。']],
'palm_house':[[52,25,'主拱肋与次肋分级，保持白色但避免所有细杆同等突出。'],[35,38,'叶片用弯曲成组形体，留出空隙与角色识别背景。'],[80,69,'支柱与地面接触需稳定，新增结构服从原通行边界。']]
}
maps=[]
for key,row in zip(ids,rows):
 maps.append(dict(id=key,name=row[0],issue=row[1],action=row[2],boundary=row[3],secondary=(ROOT/'current'/f'{key}-view.png').exists(),annotations=annotations.get(key,[])))
refs=[
 dict(name='Suravasa：入口与建筑层次',url='https://news.blizzard.com/en-us/article/24215719/weekly-recall-flashpoint-map-reworks',image='https://bnetcmsus-a.akamaihd.net/cms/page_media/x0/X0NN0LIHG4K51751394084399.png',credit='Blizzard 官方重做说明；展示机位',note='观察拱门、平台、树木与远景的尺度差异，以及暖亮面和阴影的分区。'),
 dict(name='Dorado：材质与局部光',url='https://philipklevestav.artstation.com/projects/eayYrG',image='https://cdna.artstation.com/p/assets/images/images/037/381/022/large/philip-klevestav-overwatch-dorado-01.jpg?1620228801',credit='Philip Klevestav / Blizzard；作品展示',note='观察灰泥、石材、屋瓦和植被各自的表面，以及拱廊暖灯对入口的强调。'),
 dict(name='Midtown：先读大形体',url='https://darkrusader.artstation.com/projects/oALwqJ',image='https://cdnb.artstation.com/p/assets/images/images/040/510/793/large/travis-castillo-blizzconline-newyork-02.jpg?1629096347',credit='Travis Castillo / Blizzard；历史预览',note='细节很多，但桥体阴影、街角楼体、店面和街道先组织空间。')]
reference_html=''.join(f'<figure><a href="{r["url"]}" target="_blank" rel="noopener"><img loading="lazy" src="{r["image"]}" alt="{r["name"]}，外部原作者图片"></a><figcaption><strong>{r["name"]}</strong><p>{r["note"]}</p><a href="{r["url"]}">{r["credit"]}</a></figcaption></figure>' for r in refs)
page='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>地图风格研究 · No-Art-FPS</title>
<style>
:root{color-scheme:light;--paper:#f5f3ed;--ink:#222a2e;--muted:#596369;--line:#d0d1c9;--accent:#235e68}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.8 -apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif}header,main,footer{max-width:1280px;margin:auto;padding:28px}header{border-bottom:1px solid var(--line)}h1{font-size:32px;line-height:1.35;margin:12px 0}h2{font-size:26px;line-height:1.4;margin:36px 0 16px}h3{font-size:22px;margin-top:32px}h4{font-size:19px}p{margin:10px 0}a{color:var(--accent);text-underline-offset:4px}.eyebrow,.muted{color:var(--muted);font-size:14px}.lead{max-width:880px;font-size:19px}nav{display:flex;gap:24px;flex-wrap:wrap}button,select{font:inherit;padding:8px 12px;border:1px solid #919e9f;border-radius:4px;background:white;color:var(--ink)}button{cursor:pointer}button[aria-pressed=true]{background:var(--accent);color:white}button:focus-visible,select:focus-visible,a:focus-visible{outline:3px solid #b66a28;outline-offset:3px}.controls{display:flex;flex-wrap:wrap;align-items:center;gap:12px;margin:18px 0}.inspect{display:grid;grid-template-columns:minmax(0,3fr) minmax(260px,1fr);gap:24px}.frame{position:relative;align-self:start;overflow:hidden;background:#19242d}.frame>img{width:100%;display:block;aspect-ratio:16/9}.frame.gray>img{filter:grayscale(1)}.frame.blur>img{filter:blur(5px)}.frame.gray.blur>img{filter:grayscale(1) blur(5px)}.pin{position:absolute;transform:translate(-50%,-50%);background:#fff6d5;color:#242424;border:2px solid #79520c;width:28px;height:28px;border-radius:50%;display:grid;place-items:center;font-weight:700;line-height:1}.annotations-off .pin{display:none}aside h3{margin:0 0 8px}aside p{font-size:15px}aside ol{padding-left:22px;font-size:14px}.tag{font-size:13px;color:var(--accent);letter-spacing:.04em}.references{display:grid;grid-template-columns:repeat(3,1fr);gap:22px}figure{margin:0}figure img{display:block;width:100%;aspect-ratio:16/9;object-fit:contain;background:#23303a}figcaption{font-size:14px;padding-top:12px}.table-scroll{overflow:auto;border:1px solid var(--line);margin:20px 0}table{border-collapse:collapse;width:100%;font-size:14px;min-width:680px}td,th{text-align:left;padding:12px;border-bottom:1px solid var(--line);vertical-align:top}th{background:#e6e7e0}td:first-child{min-width:96px}code{background:#e5e7e2;padding:2px 4px;overflow-wrap:anywhere}article{max-width:1040px}article>h2:first-child{display:none}.notice{border-left:4px solid var(--accent);padding:12px 20px;background:#e8eeeb}.source-note{font-size:13px;color:var(--muted)}footer{border-top:1px solid var(--line)}@media(max-width:850px){.inspect{grid-template-columns:1fr}.references{grid-template-columns:1fr}header,main,footer{padding:20px}h1{font-size:27px}}@media print{button,select,nav{display:none}.inspect{display:block}.references{display:block}.references figure{break-inside:avoid;margin-bottom:20px}body{background:white}article{max-width:none}}
</style>
<header><div class="eyebrow">No-Art-FPS / 环境美术研究 / 2026-11-13</div><h1>从精细的物件，走向有主次的场景</h1><p class="lead">我们的下一步：重新组织空间、形体、材质与光照。保留明快的上漆玩具风格，让地图在战斗视角中更有重量、层次与辨识度。</p><nav><a href="#inspect">12 图逐项检查</a><a href="#reference">一手参考</a><a href="#report">完整研究</a><a href="README.md">Markdown 原文</a></nav></header>
<main><section id="inspect"><h2>当前版本实机与编辑建议</h2><p class="muted">新采集 24 个视角，保留 16 张。两名敌人由脚本摆放，普通模式；这是静态美术检查，不是完整游玩测试。图上标注是待实施建议。</p>
<div class="controls"><label for="map">地图</label><select id="map">OPTIONS</select><button id="view" aria-pressed="false">补充视角</button><button id="gray" aria-pressed="false">灰度检查</button><button id="blur" aria-pressed="false">虚化看大色块</button><button id="pins" aria-pressed="true">编辑标注</button><a id="original" href="current/score_attack-play.png" target="_blank">打开原图</a></div>
<div class="inspect"><div class="frame" id="frame"><img id="shot" alt="当前地图实机"><div id="marks"></div></div><aside aria-live="polite"><span class="tag">观察 / 编辑动作 / 边界</span><h3 id="name"></h3><p id="issue"></p><p><strong>先做：</strong><span id="action"></span></p><p><strong>边界：</strong><span id="boundary"></span></p><ol id="notes"></ol></aside></div><p class="source-note">灰度和虚化仅是网页检查滤镜，不修改原始截图。各图补充机位的 FOV 不同；不要用画面中的物体大小直接比较地图尺度。</p></section>
<section id="reference"><h2>守望先锋的一手视觉参考</h2><p class="muted">以下图片直接来自暴雪及参与制作的环境美术师，需要联网。展示机位、时段和画质不同，比较设计方法，不做像素或性能排名；点击图片可到原文。</p><div class="references">REFERENCES</div></section>
<section id="report"><h2>完整研究与执行方案</h2><div class="notice">先在沙门一个街角、办公室一条过道验证；依次隔离摆放、形体、光照和材质的贡献，再决定扩展。全图套用同一批细节不作为验收目标。</div><article>REPORT</article></section></main><footer>本轮没有修改地图或发布游戏。研究基线 79b1a3c · <a href="evidence.json">采集版本与文件校验</a> · <a href="capture.log">相机记录</a></footer>
<script>
const maps=MAPDATA;const $=id=>document.getElementById(id);let secondary=false;
function draw(){const m=maps.find(m=>m.id===$('map').value);if(!m.secondary)secondary=false;const path='current/'+m.id+(secondary?'-view':'-play')+'.png';$('shot').src=path;$('shot').alt=m.name+'当前版本'+(secondary?'补充':'战斗')+'视角';$('original').href=path;$('view').disabled=!m.secondary;$('view').setAttribute('aria-pressed',String(secondary));for(const k of ['name','issue','action','boundary'])$(k).textContent=m[k];$('marks').replaceChildren();$('notes').replaceChildren();if(!secondary)m.annotations.forEach(([x,y,n],i)=>{const pin=document.createElement('span');pin.className='pin';pin.style.left=x+'%';pin.style.top=y+'%';pin.textContent=i+1;pin.title=n;$('marks').append(pin);const li=document.createElement('li');li.textContent=n;$('notes').append(li)});}
$('map').addEventListener('change',()=>{secondary=false;draw()});$('view').addEventListener('click',()=>{secondary=!secondary;draw()});for(const id of ['gray','blur'])$(id).addEventListener('click',()=>{const on=$('frame').classList.toggle(id);$(id).setAttribute('aria-pressed',String(on))});$('pins').addEventListener('click',()=>{const off=$('frame').classList.toggle('annotations-off');$('pins').setAttribute('aria-pressed',String(!off))});draw();
</script></html>'''
page=page.replace('OPTIONS',''.join(f'<option value="{m["id"]}">{m["name"]}</option>' for m in maps)).replace('REFERENCES',reference_html).replace('REPORT','\n'.join(blocks)).replace('MAPDATA',json.dumps(maps,ensure_ascii=False))
(ROOT/'index.html').write_text(page)
print('Built index.html:',len(maps),'maps;',len(list((ROOT/'current').glob('*.png'))),'local images')
