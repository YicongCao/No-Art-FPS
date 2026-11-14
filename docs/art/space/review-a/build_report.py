"""Rebuild the review from checked-in measurements; no external dependencies."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent
load=lambda n:json.loads((HERE/n).read_text())
grey=load('grey-clean-performance.json');corner=load('corner-clean-performance.json');web=load('web-corner/web.json');oldweb=load('web-grey/web.json');pack=load('package-audit.json')
rows=''
for label,before,after in [('原生 P50',grey['warm']['p50_ms'],corner['warm']['p50_ms']),('原生 P95',grey['warm']['p95_ms'],corner['warm']['p95_ms']),('原生 P99',grey['warm']['p99_ms'],corner['warm']['p99_ms']),('Web P95',oldweb['performance']['p95Ms'],web['performance']['p95Ms'])]:
 rows+=f'<tr><td>{label}</td><td>{before:.2f} ms</td><td>{after:.2f} ms</td></tr>'
transition=corner['transition_43_to_48']
draws=[v[1] for v in corner['draw_samples'] if 3<v[0]<59]
html='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>月球样片 · 评审 A</title>
<style>
:root{color-scheme:dark;font-family:Arial,"PingFang SC",sans-serif;background:#0b111a;color:#e3e1da}*{box-sizing:border-box}body{margin:0}main{max-width:1240px;margin:auto;padding:48px 24px 80px}h1{font-size:clamp(32px,5vw,62px);margin:12px 0}h2{font-size:26px;margin-top:48px}p,li{line-height:1.8;color:#bcc5cc}a{color:#7bd5e2}small,.eyebrow{color:#d97750;letter-spacing:.1em}img{max-width:100%;display:block;border-radius:8px}button,.button{font:inherit;background:#d85c38;color:white;padding:12px 20px;border:0;border-radius:4px;display:inline-block;text-decoration:none;margin:10px 10px 10px 0}section{margin:32px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:20px}.card{background:#141f2b;padding:24px;border:1px solid #283544;border-radius:8px}table{width:100%;border-collapse:collapse}td,th{text-align:left;padding:14px;border-bottom:1px solid #35414d}th{color:#81d4df}.compare{position:relative;aspect-ratio:16/9;background:#15202b;overflow:hidden;border-radius:8px}.compare img{position:absolute;width:100%;height:100%;object-fit:cover}.compare .before{clip-path:inset(0 50% 0 0)}input{width:100%;accent-color:#d85c38}figcaption{margin:10px 0;color:#adb9c4;font-size:14px}figure{margin:0}.notice{border-left:4px solid #d85c38;padding:12px 24px;background:#17212b}.metrics{font-size:32px;color:#fff}.muted{font-size:14px;color:#99a7b5}@media(max-width:750px){.grid{grid-template-columns:1fr}main{padding:24px 16px}}
</style><main>
<div class="eyebrow">SPACE / REVIEW A / 2026-11-14</div><h1>月球基地，进入实机。</h1>
<p>独立的 60 秒射击样片，先验收基地门口的材质、光照与可玩尺度，再扩展飞船、机甲和全场。</p>
<a class="button" href="http://localhost:8766" target="_blank">打开本地 Web 试玩</a><a href="README.md">运行与验证说明</a>
<div class="notice"><strong>这是评审 A，不是全地图美术完成版。</strong><p>基地外壳、气闸、栏杆、入口坡道、箱体、氧气设备和月壤已接入。飞船、服务站、边界山体仍为占位；敌人、武器、HUD 与音效复用原游戏。室内未制作。本轮没有调用 Tripo，也没有覆盖生产站点。</p></div>
<section><img src="corner-corner.png" alt="基地角落原生实机画面"><p class="muted">实机截图，原生 Compatibility，1280 × 720。近处设备为程序化模型，基地保留已验证的 Tripo 主壳。</p></section>
<h2>同机位：灰盒与基地角落</h2>
<div class="compare"><img src="corner-corner.png" alt="基地角落美术版"><img class="before" id="before" src="grey-corner.png" alt="灰盒基线"></div>
<label for="slider">拖动分界：左侧灰盒，右侧当前实机</label><input id="slider" type="range" min="0" max="100" value="50">
<div class="grid"><figure><img src="corner-opening.png" alt="完整地图开局"><figcaption>开局机位：只完成北侧基地角落，其余部分保留体量占位。</figcaption></figure><figure><img src="web-corner/gameplay.png" alt="浏览器实机"><figcaption>Chrome Web 实机，复用原有射击与狂暴玩法。</figcaption></figure></div>
<h2>混合资产真正节省了什么</h2><div class="grid"><div class="card"><div class="metrics">57 → 16</div><p>基地单资产正面实验的绘制调用，包含地面和阴影。第一人称近景从 64 → 17，细节机位从 72 → 18。太阳、相机、MSAA 与原实验一致。</p></div><div class="card"><div class="metrics">18,757 tris / 3 meshes</div><p>几何没有减面。非发光程序化部件使用 8 × 8 色板图集和 PBR 参数图集，原云模型贴图与发光件分别保留。可编辑源仍保留部件结构。</p></div></div>
<div class="grid"><figure><img src="../base-hybrid/godot-front.png" alt="原混合模型"><figcaption>原混合模型：17 个网格，57 次绘制。</figcaption></figure><figure><img src="base-production/godot-front.png" alt="图集合并后模型"><figcaption>游戏导出：3 个网格，16 次绘制。颜色与几何保持原设计。</figcaption></figure></div>
<h2>性能实测与尚未解决的部分</h2><table><thead><tr><th>指标</th><th>灰盒</th><th>当前角落</th></tr></thead><tbody>ROWS</tbody></table>
<p>原生为同一台 Apple M5、1280 × 720、关闭帧率上限与 VSync 的完整回合，使用单调时钟测帧间隔，采样中不读回截图。Web 为同机 Chrome、1280 × 720、60 Hz RAF 间隔；两种口径不能直接比较，也不是 GPU 时间。两次回合未做统计显著性测试，不能从小幅差异推断性能提升。</p>
<div class="notice"><p>狂暴切换区间（43–48 秒）原生 P95：TRANSITION95 ms，最大：TRANSITIONMAX ms。原生整轮仍有 HOSTMAX ms 的孤立长帧；Web 最长 WEBMAX ms，采样约 43–44 秒附近还有 100–117 ms 长帧，尚未定位原因。场景绘制调用范围 DRAWRANGE，尚未达到全场 300 次目标；当前旧敌人、阴影和特效仍占用预算。1440 × 810、真实手机与长期温度压力测试留待后续阶段。</p></div>
<p>单图 PCK：PACK MiB。最终包内只有 <code>moonbase_trial</code> 地图与会话；仍保留共享的旧角色、UI、特效资源，后续替换时再裁剪。</p>
<h2>验证范围</h2><ul><li>60 秒计时、45 秒狂暴、结算和重开；独立计分；禁止切换到旧图或搞怪模式。</li><li>8 个开局点、12 个补充点、6 个复活候选点及平台路线可达；角色实际沿服务坡道走上 2.4 米平台。</li><li>原生暂停冻结与规则测试通过；原九图默认入口仍能渲染。</li><li>Chrome 完整回合持续射击、换弹、结算、重开、暂停通过，未记录脚本错误。844 × 390 触控模拟的移动与开火并行、换弹、开镜、手雷、暂停和触摸恢复通过；自动化不等同于人工试玩。</li></ul>
<h2>本轮踩坑及生产约束</h2><ol><li>选定资源导出没有完整收集 GDScript 的 preload。导出工具现在显式递归收集，再审计实际 PCK，最后用浏览器启动验证。</li><li>Compatibility 下不能靠顶点色 sRGB 开关修复颜色。当前色板直接编码为 sRGB 贴图，PBR 参数保持线性；不为批处理牺牲颜色。<a href="https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html#class-basematerial3d-property-vertex-color-is-srgb">Godot 官方说明</a></li><li>月壤噪声在制作端生成，降低 Albedo 对比、补 mipmap；山体与近地面不用同一高频 UV 纹理。</li><li>可玩碰撞与外观独立制作；导航检查之外，还用角色真实攀登坡道。箱体内外壳需检查包络，避免遮住外板。</li><li>截图与性能分开跑，避免 PNG 读回污染切换时的帧时间。图集批处理同时保留原始可编辑文件。</li></ol>
<h2>评审 A 需要确认</h2><p>主要看暖白外壳、橙色气闸、黄色栏杆、青色灯环和深灰月壤的搭配，以及基地入口的尺度。新道具目前比云模型更干净，尚未统一微磨损；山体、飞船和旧枪械不作为本次定稿依据。</p>
<p>确认方向后进入飞船、两类机甲和第一人称枪械的评审 B，再扩展全图、可破坏组、字体与音效。不会把这次角落试验当作整场完成。</p>
<p><a href="corner-clean-performance.json">原生数据</a> · <a href="web-corner/web.json">Web 数据</a> · <a href="base-production/render-stats.json">基地绘制统计</a> · <a href="package-audit.json">包体审计</a></p>
</main><script>document.querySelector('#slider').addEventListener('input',e=>document.querySelector('#before').style.clipPath=`inset(0 ${100-e.target.value}% 0 0)`);</script></html>'''
html=html.replace('ROWS',rows).replace('TRANSITION95',f"{transition['p95_ms']:.2f}").replace('TRANSITIONMAX',f"{transition['max_ms']:.2f}").replace('HOSTMAX',f"{corner['warm']['max_ms']:.2f}").replace('WEBMAX',f"{web['performance']['maxMs']:.1f}").replace('DRAWRANGE',f'{int(min(draws))}–{int(max(draws))}').replace('PACK',f"{pack['pck_bytes']/1024**2:.2f}")
(HERE/'index.html').write_text(html)
print('REVIEW_REPORT_READY')
