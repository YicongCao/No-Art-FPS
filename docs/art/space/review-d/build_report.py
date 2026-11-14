"""Build the self-contained review index from retained test evidence."""
from pathlib import Path
import json,html,hashlib
H=Path(__file__).resolve().parent;ROOT=H.parents[3]
def read(name):return json.loads((H/name).read_text())
def fig(name,caption):return f'<figure><img loading="lazy" src="{name}" alt="{html.escape(caption)}"><figcaption>{html.escape(caption)}</figcaption></figure>'
notes={
'SYS-01':('通过','独立 session、成绩与重开；完整回合自动检查。'),
'SYS-02':('通过','60 秒规则、45 秒过载；rules_test 截止与重复计分回归。'),
'LVL-01':('通过','44×48 米可玩区；导航标记、服务坡道角色实走通过。新增岩石避开 Spawn4。'),
'LVL-02':('待人工验收','导航检查通过；尚未进行要求的三局人工出生公平性走查。'),
'LVL-03':('通过','沿用 C 的 gameplay / industrial / landing 同机位；相机定义在 world_check。'),
'ART-01':('部分','保留暖白、石墨、橙、青色板；增加成套表面响应。尚非概念图级材质与六球正式评审。'),
'ART-02':('部分','气闸、栏杆、坡道垂直切片已接入；本轮未另做三种照明条件人工评审。'),
'MOD-01':('已接入','已批准飞船与落架保留；Godot 导入生成网格 LOD，尚未针对性能调档。'),
'MOD-02':('已接入','基地外壳、封闭气闸、服务站、围墙、坡道与栏杆；室内明确排除。'),
'MOD-03':('已接入','氧气塔、横置储罐、支撑、气管、阀组；本轮补氧气设备表面层次。'),
'MOD-04':('通过','货箱、控制台与近景掩体可编辑源齐全，残件和复位功能通过。'),
'MOD-05':('部分','太阳能、天线、连续远山、近景岩石及行星已接入；尚未满足早期性能预算。'),
'CHR-01':('部分','8/15/20 米截图已补；头部判定通过。远距离辨识仍需人工确认。'),
'CHR-02':('通过','独立轻装轮廓与刀刃，不只换色；挥刀状态与命中逻辑回归通过。'),
'CHR-03':('部分','关节、持枪、蓄力/挥砍/恢复、爆头拆壳已检查；刚性关节动画和脚部贴地仍可精修。'),
'WPN-01':('部分','缩小瞄具、打开能量腔、补表面纹理；ADS 对线通过。握持与近景细节仍不等同概念图。'),
'WPN-02':('通过','弹匣位移及新手雷单次释放、暂停、取消与重开检查通过。'),
'INT-01':('通过','四类 8 组 20 个目标，真实命中、残件、连锁、暂停和复位通过。'),
'INT-02':('通过','屏幕、阀门、供电与货箱局部损坏；保留静态掩体，不运行时重烘焙导航。'),
'LGT-01':('部分','增加静态建筑/停机坪接触阴影，隔离持枪灯，降低持枪白漆与补光；细腻阴影仍有距离。'),
'LGT-02':('部分','补三块深色外窗与金属粗糙度；沿用单次更新探针，未启用平面反射。窗口响应不是概念图的室内透视。'),
'LGT-03':('部分','三盏预建局部橙灯与枪械线圈过载，不洗红全图；长帧目标未验收。'),
'FX-01':('通过','身体、爆头、拆壳、设备碎片与电火花沿用已验证反馈。'),
'FX-02':('部分','沿用碎片与效果上限；集中破坏回合已采样，尚未完成专项性能优化。'),
'AUD-01':('部分','原创枪声、装填、预警、脚步、金属、爆炸与 60 秒音乐；45 秒音乐加强。自动路径检查不代替耳机听感定位验收。'),
'UI-01':('通过','Oxanium 等宽数字、Noto Sans SC 中文，独立字体 fallback；保留许可。'),
'UI-02':('通过','子集来自项目界面文本；字体覆盖检查与等宽数字检查，Web 随包附许可。'),
'UI-03':('通过','时间/击杀/准星/弹药/手雷，无生命条；999 击杀截图、横屏触控截图。'),
'UI-04':('部分','Chrome 触控模拟移动、射击、ADS、换弹、投掷与暂停通过；物理设备和减少动态设置完整人工验收待做。'),
'TECH-01':('通过','实际 PCK 依赖审计，无原九图场景与模型；仍保留公共旧资源依赖，未宣称完全裁剪。'),
'TECH-02':('部分','Compatibility Web 实际运行；局部灯预建、线圈材质初始化时复制。切换长帧仍待优化。'),
'TECH-03':('通过','保留普通、集中破坏、Web 帧序列及 P50/P95/P99/最大值；预算超标明确记录。'),
'QA-01':('通过','规则、导航、破坏、弹匣、投掷、暂停与重开自动回归。'),
'QA-02':('部分','多机位实机图、概念差距与一次出生点阻塞修复已记录；不是三轮人工美术走查。'),
'QA-03':('部分','真实 Chrome Web 导出和触控模拟完成；未做物理手机性能测试。'),
'REL-01':('待主线整合','space 开发预览，本轮不合并 main 或覆盖两处生产站；生产不可变发布与回滚须随主线版本执行。')}
requirements=json.loads((ROOT/'docs/design/moonbase-plan-2026-11-13/requirements.json').read_text())['requirements']
audit=[dict(id=r['id'],title=r['title'],acceptance=r['acceptance'],status=notes[r['id']][0],evidence_or_gap=notes[r['id']][1]) for r in requirements]
(H/'requirements-audit.json').write_text(json.dumps({'source':'docs/design/moonbase-plan-2026-11-13/requirements.json','scope':'Exterior trial on space. Implementation and full acceptance are distinct.','requirements':audit},ensure_ascii=False,indent=2)+'\n')
normal=read('finish-clean-performance.json');stress=read('finish-props-clean-performance.json');web=read('web/web.json')['performance'];pack=read('package-audit.json');old=json.loads((H.parent/'review-c/world-clean-performance.json').read_text())
rows=''.join(f'<tr><td>{label}</td>'+''.join(f'<td>{d[key]:.2f}</td>' for d in [old['warm'],normal['warm'],stress['warm']])+'</tr>' for label,key in [('P50 / ms','p50_ms'),('P95 / ms','p95_ms'),('P99 / ms','p99_ms'),('最大 / ms','max_ms')])
auditrows=''.join(f'<tr><td>{r["id"]}<br>{r["title"]}</td><td>{r["status"]}</td><td>{r["evidence_or_gap"]}</td></tr>' for r in audit)
issues={'native_normal_over_33ms':[f for f in normal['frames'] if f[1]>33.33],'native_stress_over_33ms':[f for f in stress['frames'] if f[1]>33.33],'web_over_33ms':[f for f in web.get('frameTrace',[]) if f[1]>33.33],'transition_normal':normal['transition_43_to_48'],'transition_stress':stress['transition_43_to_48'],'note':'Intervals, not GPU timing. Single runs do not prove optimization. Native seconds and Web elapsed milliseconds have different origins.'}
(H/'performance-issues.json').write_text(json.dumps(issues,indent=2)+'\n')
page=f'''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>月球基地 · 概念缺项补齐</title><style>
*{{box-sizing:border-box}}body{{margin:0;background:#10171d;color:#e1e6e9;font:16px/1.7 system-ui,sans-serif}}main{{max-width:1240px;margin:auto;padding:32px 22px}}h1,h2{{line-height:1.25}}h1{{font-size:clamp(28px,5vw,50px)}}h2{{margin-top:48px;color:#f3a165}}a{{color:#8ad8df}}p{{max-width:100ch}}figure{{margin:0 0 20px}}img{{display:block;width:100%;height:auto}}figcaption,.muted{{font-size:14px;color:#afbec7}}.grid{{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}}.compare{{position:relative;aspect-ratio:16/9;overflow:hidden}}.compare img{{position:absolute;inset:0;width:100%;height:100%}}#before{{clip-path:inset(0 50% 0 0)}}input{{width:100%;accent-color:#e68b4b}}.scroll{{overflow:auto}}table{{border-collapse:collapse;width:100%;min-width:620px}}td,th{{padding:12px;border-bottom:1px solid #34414a;text-align:left;vertical-align:top}}.notice{{padding:16px 22px;background:#1d2a33;border-left:3px solid #f3a165}}@media(max-width:700px){{.grid{{grid-template-columns:1fr}}main{{padding:20px 14px}}}}
</style><main><p class="muted">SPACE / REVIEW D / 2026-11-14 · 原生与 Web 实机证据</p><h1>补齐概念图缺项，统一近景观感</h1>
<p>本轮重点补上 C 阶段缺少的地表细节、设施表面层次、外窗、接触阴影、近景岩石、第一人称装备、字体和音色。保留已批准的飞船与机甲、现有路线和一分钟规则；基地室内继续关闭。没有新增 Tripo 付费任务。</p>
<div class="notice">主要物件与视觉系统已接入，不等于概念图写实程度或整份策划案验收全部完成。下方逐项区分实装、自动检查、人工验收和延期事项；性能优化与生产发布仍未在本轮执行。</div>
<h2>同机位：左 C，右 D</h2><div class="compare"><img src="gameplay.png" alt="D 当前实机"><img id="before" src="../review-c/gameplay.png" alt="C 修改前实机"></div><label for="slider">拖动比较边界</label><input id="slider" aria-label="修改前后对比边界" type="range" value="50" min="0" max="100">
<h2>本轮补齐的内容</h2><ul><li>月壤细颗粒与法线、平滑远山法线、4 种近景岩石和 20 处岩块布置；近处碰撞经导航检查。</li><li>设施、货箱、枪械的磨损/粗糙度/法线共享分布，离线烘焙为纹理；保持原有主色，不加全屏灰雾。</li><li>三块深色镀膜外窗，4 处静态接触阴影；不制作基地室内，不新增平面反射渲染。</li><li>缩小瞄具、打开能量线圈、降低持枪白漆和补光强度；新增装甲手雷与投掷手套，物理和库存规则不变。</li><li>三盏预建局部过载灯与线圈橙色状态，退出后恢复青色；不全图洗红。</li><li>Oxanium + Noto Sans SC 子集与许可、简化数字 HUD、数字弹量和 SVG 手雷图标；独立开始界面与 Web 加载字样。</li><li>原创离子射击、装填、预警、脚步、金属、爆炸和 60 秒音乐，45 秒提高音乐密度；无下载音频素材。</li></ul>
<div class="grid">{fig('industrial.png','工业区：粗糙度变化、外窗与保留的封闭气闸。')}{fig('service.png','服务站与外围模块：统一表面密度。')}{fig('terrain.png','月壤与远山：连续轮廓、平滑法线及近景岩石。')}{fig('landing.png','飞船和停机坪：保留已批准模型，加静态接触层。')}{fig('ads.png','紧凑瞄具：实际 ADS 对线误差小于 0.001 像素。')}{fig('grenade-hand.png','新手雷与手套：实际投掷前持握帧。')}{fig('frenzy.png','过载：局部橙光与线圈变化。')}{fig('hud-999.png','999 击杀极值与新的弹药、手雷显示。')}</div>
<h2>辨识与交互</h2><div class="grid">{fig('readability-8m.png','8 米：两类机甲轮廓。')}{fig('readability-20m.png','20 米：远距离机甲；仍需人工游玩确认辨识体验。')}</div>
<p>Godot 导入、导航和实际坡道行走、规则回归、机甲状态与爆头、ADS、弹匣动作、新手雷单次释放/暂停/重开均已自动检查；8 组 20 个破坏目标保留真实射线命中证据。新增岩块曾占用 Spawn4，已移位后重新通过导航。手雷 SVG 首次绘制的临时纹理生命周期导致白块，改为持久缓存并截图复验。</p>
<div class="grid">{fig('web/gameplay.png','实际 Web 导出运行。')}{fig('web-touch/ads.png','844×390 Chrome 触控模拟；不是物理手机。')}</div>
<h2>帧时间与长帧记录</h2><div class="scroll"><table><tr><th>帧间隔</th><th>C 普通</th><th>D 普通</th><th>D 集中破坏</th></tr>{rows}</table></div>
<p>同机 Apple M5、1280×720 原生完整回合，关闭 VSync/上限，采样时无截图读回；集中破坏在 12 / 30 / 44.4 秒破坏、复原、再次破坏。普通与压力回合不是相同工作量。Web Chrome RAF：P95 {web['p95Ms']:.2f} ms，P99 {web['p99Ms']:.2f} ms，最大 {web['maxMs']:.2f} ms。实际 PCK {pack['pck_bytes']/1024**2:.2f} MiB。</p>
<p>以上均为帧间隔而非 GPU 时间，单轮变化不说明优化成功。仍需针对绘制调用、机甲网格、纹理复用、阴影和 Web 加载做集中优化。<a href="performance-issues.json">长帧清单</a> · <a href="finish-clean-performance.json">普通原始帧</a> · <a href="finish-props-clean-performance.json">集中破坏原始帧</a> · <a href="web/web.json">Web 日志</a> · <a href="package-audit.json">包体审计</a></p>
<h2>策划案逐项核对</h2><p>保留原始需求及其验收标准；“已接入”不替代所有验收项通过。<a href="requirements-audit.json">完整机器可读清单</a></p><div class="scroll"><table><tr><th>需求</th><th>状态</th><th>证据与剩余差距</th></tr>{auditrows}</table></div>
<h2>与概念图仍然不同的部分</h2>{fig('../../moonbase-concepts-2026-11-13/01-gameplay.png','原概念图，仅为目标方向，非本轮实机。')}
<p>实机仍是偏低模的 Web 样片：岩层造型、设施接缝/软管密度、机甲脚部贴地、手部握持、枪械近景细节和玻璃反射层次尚不等同写实概念图。当前玻璃是封闭外窗；行星是程序化风格化背景，不是真实地球地理纹理。没有通过水面、浓雾、过量 Bloom 掩盖这些差距，也未把它们标成已经完成。</p>
<p>下一轮优先保留当前效果做性能优化；随后可针对近景材质、动作与人工游玩反馈收敛。本轮不追加室内、不改变 60 秒玩法、不合并主线或覆盖生产站。<a href="README.md">复现与来源</a> · <a href="validation.json">检查摘要</a> · <a href="finish-check.json">新装备状态检查</a></p></main>
<script>document.querySelector('#slider').addEventListener('input',e=>document.querySelector('#before').style.clipPath=`inset(0 ${{100-e.target.value}}% 0 0)`)</script></html>'''
(H/'index.html').write_text(page);print('REVIEW_D_READY',len(audit))
