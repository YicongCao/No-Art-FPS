"""Review B: evidence-backed native/Web gallery, with deferred performance work."""
from pathlib import Path
import json,re
H=Path(__file__).resolve().parent
load=lambda p:json.loads(p.read_text())
a=load(H.parent/'review-a/corner-clean-performance.json');b=load(H/'heroes-clean-performance.json')
wa=load(H.parent/'review-a/web-corner/web.json')['performance'];wb=load(H/'web/web.json')['performance']
pack=load(H/'package-audit.json');assets=load(H/'asset-build.json')
css=re.search(r'<style>(.*?)</style>',(H.parent/'review-a/index.html').read_text(),re.S)[1]
rows=''
for label,x,y in [('原生 P95',a['warm']['p95_ms'],b['warm']['p95_ms']),('原生 P99',a['warm']['p99_ms'],b['warm']['p99_ms']),('原生最长帧',a['warm']['max_ms'],b['warm']['max_ms']),('Web P95',wa['p95Ms'],wb['p95Ms']),('Web P99',wa['p99Ms'],wb['p99Ms']),('Web 最长帧',wa['maxMs'],wb['maxMs'])]:
 rows+=f'<tr><td>{label}</td><td>{x:.2f} ms</td><td>{y:.2f} ms</td></tr>'
assetrows=''.join(f'<tr><td>{name}</td><td>{v["triangles"]:,}</td><td>{v["meshes"]}</td><td>{v["materials"]}</td></tr>' for name,v in assets.items())
fig=lambda image,caption:f'<figure><a href="{image}"><img loading="lazy" src="{image}" alt="{caption}"></a><figcaption>{caption}</figcaption></figure>'
t=b['transition_43_to_48'];draws=[d[1] for d in b['draw_samples'] if 3<d[0]<59]
# Web sampling starts after loading and 1.5 seconds of play, unlike native game time.
web_stalls=sorted([f for f in wb['frameTrace'] if f[1]>33.3],key=lambda f:f[1],reverse=True)
issues={'native':{'warm':b['warm'],'transition_43_to_48':t,'draw_range':[min(draws),max(draws)]},'web':{k:wb[k] for k in ['p50Ms','p95Ms','p99Ms','maxMs']},'web_stalls_gt_33_3ms':web_stalls,'pck_bytes':pack['pck_bytes'],'status':'Recorded, not optimized or performance-approved','method':'Native uncapped monotonic frame intervals; Web 60 Hz RAF. Single rounds with different AI paths; not GPU timings. No screenshots in either measured round.'}
(H/'performance-issues.json').write_text(json.dumps(issues,indent=2)+'\n')
html=f'''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>月球样片 · 评审 B</title><style>{css}</style><main>
<div class="eyebrow">SPACE / REVIEW B / 2026-11-14</div><h1>飞船到位，机甲上场。</h1>
<p>飞船、两类机甲与第一人称离子步枪已接入同一个 60 秒月球射击样片。以下主画面均为游戏实际渲染，生成参考图放在末尾单独展示。</p>
<a class="button" href="http://localhost:8766" target="_blank">打开本地 Web 试玩</a><a href="README.md">运行与验证说明</a> · <a href="../review-a/index.html">回看评审 A</a>
<div class="notice"><strong>本轮到评审 B，等待美术方向确认。</strong><p>保持原战斗规则、地图通路和基地室外范围。按要求先做效果，长帧和包体增长已记录，尚未集中优化。远山、服务站、部分道具、HUD 和音效仍待后续阶段；不是整张概念图已经完成。</p></div>
<section>{fig('gameplay.png','原生实机：开局机位，1280 × 720，Compatibility。')}</section>
<h2>评审 A → B</h2><div class="grid">{fig('../review-a/corner-opening.png','评审 A：旧角色、旧枪械和飞船体块。')}{fig('comparison.png','评审 B：相同起点与朝向。敌人快照时间不同，不能逐像素比较。')}</div>
<h2>飞船：云模型主轮廓，程序化精确附件</h2>{fig('ship.png','尖机头、后掠翼和双尾翼保留；三点落架、翼炮、导弹挂载单独装配。')}
<p>主壳归一化到最大平面尺寸 11 米，位于原停机坪范围。主壳碰撞在制作端生成，停机坪有独立可行走碰撞；细小挂载不添加复杂碰撞。起落架接地，室外路线重新烘焙并验证。</p>
<h2>两类机甲：保留玩法，替换外形和活动结构</h2><div class="grid">{fig('mech-pair.png','暖白重装步枪兵与橙色轻型突击兵；沿用原有生命、速度和射击/近战行为。')}{fig('mechs-moving.png','活动部件在游戏中运动；机甲装甲不是一块整体静态网格。')}{fig('melee-windup.png','突击兵举刀蓄力：刀刃闪亮提示，保留原来的攻击节奏。')}{fig('headshot.png','实际子弹爆头：头壳隐藏、露出核心、碎片与命中确认继续生效。')}</div>
<p>保留头、头壳、躯干、肩、肘、髋、膝、脚和武器插槽。采用刚性分件动画，没有宣称完成复杂蒙皮或专业动作捕捉。近景关节切口、握持和极限姿势仍属于后续动作打磨项。</p>
<h2>第一人称枪械</h2><div class="grid">{fig('ads.png','开放式瞄具与射线中心对齐，原生投影误差小于 0.001 像素。')}{fig('reload.png','换弹时弹匣与支撑手参与运动，继续沿用原来的换弹时间。')}</div>
<p>枪身、装甲板、能量腔、护罩、导轨、枪托、空心枪口、瞄具及手臂由 Blender Python 生成。第一/第三人称共用设计，第三人称导出不含玩家手臂。枪口与瞄准轴通过视觉配置独立标定。当前枪身比云模型更干净，微磨损、换弹动作和瞄具屏幕占比仍可在本轮评审后精修。</p>
<h2>Web 实机与狂暴</h2><div class="grid">{fig('web/gameplay.png','Chrome 1280 × 720：实际加载导出包后的游戏画面。')}{fig('frenzy.png','原生狂暴状态：继承原有节奏和反馈，本图不参与性能采样。')}{fig('web-touch/ads.png','Chrome 844 × 390 触控模拟：开镜、摇杆与射击交互。')}{fig('web/end.png','完整 Web 回合结束后的结算画面。')}</div>
<h2>验证结论</h2><ul><li>原生 60 秒完整回合、45 秒狂暴、结算重开、暂停冻结、独立分数与旧图切换阻止通过。</li><li>地图标记导航可达；真实角色沿坡道走上服务平台。</li><li>两类机甲原始/受伤状态的真实子弹爆头、单次计分、反馈清理、暂停、减弱动态效果及效果预算检查通过。月球入口禁用的搞怪模式不纳入月球测试，保留主线独立测试。</li><li>新武器 ADS 对位、弹匣移动、突击兵蓄力/挥刀/恢复状态检查通过；原主线武器桌面与触控瞄准回归通过。</li><li>Web 连续射击、换弹、完整回合、结算、重开和暂停通过；触控模拟的移动与开火并行、换弹、ADS、手雷及暂停恢复通过。浏览器未记录脚本错误。</li></ul>
<p>这些是自动化实际渲染与交互检查，不等同于人工试玩。没有物理手机或持续温度测试结论。</p>
<h2>长帧记录：留待集中优化</h2><table><thead><tr><th>指标</th><th>评审 A</th><th>评审 B</th></tr></thead><tbody>{rows}</tbody></table>
<p>同机 Apple M5、1280 × 720；原生关闭帧率上限与 VSync，使用单调时钟帧间隔；Web 使用 Chrome RAF 间隔。两种口径都不是 GPU 时间，不能互相混比。每阶段只有单轮样本且 AI 路径不同，小幅差异不证明性能改善。正式采样期间不读回截图，也不并行执行资产生成或其他渲染测试。</p>
<div class="notice"><p>原生 43–48 秒区间：P95 {t['p95_ms']:.2f} ms，最长 {t['max_ms']:.2f} ms。绘制调用抽样范围 {int(min(draws))}–{int(max(draws))}。Web 大于 33.3 ms 的帧共 {len(web_stalls)} 个；完整时间列表已存档。仍需区分首次材质/特效使用、角色数量、阴影、主线程和调度影响，当前没有归因结论。</p></div>
<p>最终 PCK {pack['pck_bytes']/1024**2:.2f} MiB（评审 A 21.20 MiB）；保留共享旧角色/特效依赖，尚未做资源裁剪。原 15 MB 内容预算及绘制预算没有通过，不能把本轮作为性能验收。</p>
<p><a href="performance-issues.json">长帧问题与时间列表</a> · <a href="heroes-clean-performance.json">原生完整帧数据</a> · <a href="web/web.json">Web 完整帧数据</a> · <a href="web-touch/touch.json">触控验证</a> · <a href="interaction-check.json">新资产交互验证</a> · <a href="package-audit.json">包体审计</a></p>
<h2>游戏导出物的独立检查</h2><p>以下直接加载游戏中的 GLB，由 Godot Compatibility 渲染；采用独立检查灯光与纯色背景，供看轮廓、附件和背面结构，不替代上方的地图内效果。</p><div class="grid">{fig('asset-views/interceptor-front.png','飞船前侧：主壳、翼炮与落架')}{fig('asset-views/interceptor-rear.png','飞船后侧：双尾翼与推进器')}{fig('asset-views/rifle-mech-front.png','步枪机甲的持枪结构')}{fig('asset-views/assault-mech-front.png','突击机甲的装甲与关节')}{fig('asset-views/ion-rifle-front.png','离子步枪结构；检查视图隐藏玩家手臂')}{fig('asset-views/ion-rifle-rear.png','枪械另一侧与枪托结构')}</div>
<h2>制作投入与可编辑源</h2><table><thead><tr><th>资产</th><th>三角形</th><th>网格</th><th>材质</th></tr></thead><tbody>{assetrows}</tbody></table>
<p>三个 Tripo 任务各 110 credits，共 330；枪械和精确附件没有新增云生成费用。任务清单见 <a href="generation-manifest.json">生成记录</a>。以上为当前导出结构统计，不是最终性能目标。源文件在 <code>art_source/space/heroes</code>，包含内嵌贴图的归一化输入、装配后的 Blender 文件及可重复运行脚本。</p>
<h2>单件生成参考图</h2><p>下列为 AI 设计输入，不是游戏实机；上方截图才是评审 B 的实现结果。</p><div class="grid">{fig('references/interceptor.png','飞船生成参考')}{fig('references/rifle-mech.png','重装机甲生成参考')}{fig('references/assault-mech.png','突击机甲生成参考')}</div>
<h2>本次请重点看</h2><p>飞船轮廓与停机坪尺度、两类机甲辨识度、第一人称枪械屏幕占比与色彩搭配。确认后再扩大场景替换、统一磨损、补全 HUD/音效与可破坏物；性能问题按你的要求留到后续集中处理。本地预览只在 space 分支，不覆盖主线和生产站。</p>
</main></html>'''
(H/'index.html').write_text(html)
print('REVIEW_B_READY')
