"""Build the full-map review from actual screenshots and measured traces."""
from pathlib import Path
import json,re,math
H=Path(__file__).resolve().parent
load=lambda p:json.loads(p.read_text())
b=load(H.parent/'review-b/heroes-clean-performance.json');c=load(H/'world-clean-performance.json');stress=load(H/'world-props-clean-performance.json')
web=load(H/'web/web.json')['performance'];pack=load(H/'package-audit.json');props=load(H/'interaction-check.json')
css=re.search(r'<style>(.*?)</style>',(H.parent/'review-b/index.html').read_text(),re.S)[1]
fig=lambda p,t:f'<figure><a href="{p}"><img loading="lazy" src="{p}" alt="{t}"></a><figcaption>{t}</figcaption></figure>'
rows=''
for label,key in [('原生 P50','p50_ms'),('原生 P95','p95_ms'),('原生 P99','p99_ms'),('原生最长帧','max_ms')]:
 rows+=f'<tr><td>{label}</td><td>{b["warm"][key]:.2f} ms</td><td>{c["warm"][key]:.2f} ms</td><td>{stress["warm"][key]:.2f} ms</td></tr>'
draws=[x[1] for x in c['draw_samples'] if 3<x[0]<59]
stalls=[x for x in web['frameTrace'] if x[1]>33.3]
issues={'ordinary_native':c['warm'],'ordinary_transition_43_to_48':c['transition_43_to_48'],'destruction_native':stress['warm'],'destruction_transition_43_to_48':stress['transition_43_to_48'],'destruction_events':stress['prop_events'],'draw_range':[min(draws),max(draws)],'web':{k:web[k] for k in ['p50Ms','p95Ms','p99Ms','maxMs']},'web_stalls_over_33_3ms':stalls,'pck_bytes':pack['pck_bytes'],'status':'Recorded; optimization deferred by user','method':'Single rounds. Native monotonic uncapped wall-clock intervals; Web RAF at 60 Hz. No screenshot readbacks during sampling. Different AI trajectories; not GPU timing or mobile-device certification.'}
(H/'performance-issues.json').write_text(json.dumps(issues,indent=2)+'\n')
def chart(frames):
 bins={}
 for t,ms,*_ in frames:
  key=int(t*5);bins[key]=max(bins.get(key,0),ms)
 ceiling=max(40,math.ceil(max(bins.values())/20)*20)
 points=' '.join(f'{40+k/300*1000:.1f},{200-min(v/ceiling,1)*170:.1f}' for k,v in sorted(bins.items()))
 return f'<svg viewBox="0 0 1080 240" role="img" aria-label="集中破坏回合帧间隔峰值，横轴零至六十秒"><rect x="756" y="20" width="84" height="180" fill="#513a29"/><path d="M40 20 V200 H1040" fill="none" stroke="#8597a5"/><polyline points="{points}" fill="none" stroke="#67d2e0" stroke-width="1.5"/><g fill="#b7c4cf" font-size="14"><text x="4" y="28">{ceiling}</text><text x="10" y="200">0</text><text x="40" y="225">0 s</text><text x="760" y="225">43–48 s</text><text x="1000" y="225">60 s</text></g></svg>'
html=f'''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>月球基地 · 全地图美术</title><style>{css}svg{{width:100%}}.scroll{{overflow-x:auto}}</style><main>
<div class="eyebrow">SPACE / FULL MAP / 2026-11-14</div><h1>从基地角落，到整片月面。</h1>
<p>评审 B 通过后的全图美术推进：连续山脊、服务站、工业管路、围墙、太阳能、货箱与灯带已替换主要占位，加入 8 组、20 个可破坏目标。保留 60 秒玩法、通路、两类机甲和既有武器。</p>
<a class="button" href="http://localhost:8766" target="_blank">打开本地 Web 试玩</a><a href="README.md">验证与制作记录</a> · <a href="../review-b/index.html">回看评审 B</a>
<section>{fig('gameplay.png','当前原生实机，1280 × 720，Compatibility。没有用生成图代替实机结果。')}</section>
<h2>同起点：评审 B 与全图版本</h2><div class="compare"><img src="gameplay.png" alt="当前全图"><img class="before" id="before" src="../review-b/gameplay.png" alt="评审 B"></div><label for="slider">左侧评审 B，右侧当前版本</label><input id="slider" type="range" min="0" max="100" value="50">
<p>起点、朝向和分辨率一致；动态敌人帧可能不同。主基地和英雄资产沿用已批准方向。本轮新资产全部程序化制作，没有新增 Tripo 消费。</p>
<h2>地编与主要替换</h2><div class="grid">{fig('terrain.png','球状远山占位改为连续月面山脊，制作端烘焙矿物纹理。')}{fig('service.png','服务站保持原 5 × 4 米包络；补封闭气闸、控制窗、散热百叶、屋顶设备和天线。')}{fig('industrial.png','氧气区增加横罐、箍带、法兰、支撑与圆形管线。')}{fig('landing.png','停机坪补分段标线和暖色灯具，新增局部真实落光。')}{fig('overview.png','全场俯视：围墙、太阳能与设备依照原路线边缘布置。')}{fig('frenzy.png','狂暴状态继续使用原玩法与反馈。')}</div>
<p>货箱新增护角、锁扣、嵌板、搬运孔和标识；平台与坡道增加板缝、防滑条。地面增加细碎岩石。远景天体使用球面程序纹理，只作风格化视觉，不是准确的地球地理图。山体在边界外，室内继续关闭。</p>
<h2>可破坏物：四种反馈，八组布置</h2><table><thead><tr><th>类型</th><th>组 / 目标</th><th>行为</th></tr></thead><tbody><tr><td>电池架</td><td>2 / 6</td><td>单发击破，剩余电池延迟连锁放电；留下残件。</td></tr><tr><td>压力阀门</td><td>2 / 6</td><td>单发击破，短促喷泄与金属碎屑。</td></tr><tr><td>控制台</td><td>2 / 4</td><td>普通弹两发、狂暴弹一发；屏幕熄灭，产生电火花。</td></tr><tr><td>补给箱</td><td>2 / 4</td><td>普通弹两发破坏独立舱板，显示暗色残腔。</td></tr></tbody></table>
<div class="grid">{fig('space_battery-before.png','电池架：完整状态')}{fig('space_battery-after.png','电池架：实际子弹击破')}{fig('space_valves-before.png','阀门组：完整状态')}{fig('space_valves-after.png','阀门组：击破与喷泄')}{fig('space_console-before.png','控制台：完整状态')}{fig('space_console-after.png','控制台：屏幕破损与火花')}{fig('space_supply-before.png','补给箱：完整状态')}{fig('space_supply-after.png','补给箱：舱板破损')}</div>
<p>破坏不增加击杀分数、不额外修改敌人伤害，也没有把工业设施都设为伤害爆炸桶。静态掩体和主要通路保留，小道具沿用原有射击目标层。目标破坏后关闭命中碰撞，重开复原；电池连锁在暂停时冻结。</p>
<h2>验证结果</h2><ul><li>8 组 20 目标的射线命中、两发耐久、残件显示、碰撞关闭、电池连锁、暂停冻结、范围破坏和重开复原通过。</li><li>导航标记可达，真实角色可以走上原服务坡道；完整 60 秒、45 秒狂暴、结算重开与会话隔离通过。</li><li>原九张地图的交互物回归通过：普通/狂暴命中、手雷遮挡、复原和导航保持不变。</li><li>Chrome 完整回合持续射击、换弹、结算、重开、暂停通过；844 × 390 触控模拟通过，未记录脚本错误。</li></ul>
<div class="grid">{fig('web/gameplay.png','Web 导出实际运行画面。')}{fig('web-touch/ads.png','触控模拟：移动、开火、换弹、ADS、手雷和暂停恢复。')}</div>
<h2>性能记录，集中优化留到后续</h2><div class="scroll"><table><thead><tr><th>指标</th><th>评审 B</th><th>全图普通回合</th><th>全图集中破坏</th></tr></thead><tbody>{rows}</tbody></table></div>
<p>同机 Apple M5、1280 × 720，原生关闭帧率上限和 VSync，采用单调时钟帧间隔；没有在采样期间读取截图。普通回合维持原测试路径；压力回合额外在 12 秒击破全部目标、30 秒复原、44.4 秒再次击破。因此压力回合是额外负载，不能与普通回合当作相同工作量比较。</p>
{chart(stress['frames'])}<p class="muted">压力回合：每 0.2 秒保留最大帧间隔；高亮为 43–48 秒狂暴切换区间。原始逐帧数据保留。</p>
<div class="notice"><p>普通回合 43–48 秒 P95 {c['transition_43_to_48']['p95_ms']:.2f} ms，最大 {c['transition_43_to_48']['max_ms']:.2f} ms；压力回合该区间最大 {stress['transition_43_to_48']['max_ms']:.2f} ms。绘制调用抽样范围 {int(min(draws))}–{int(max(draws))}。Web P95 {web['p95Ms']:.2f} ms、P99 {web['p99Ms']:.2f} ms、最大 {web['maxMs']:.2f} ms。</p></div>
<p>Web 是 Chrome RAF 帧间隔，原生和 Web 均不是 GPU 时间。每组仅单轮、AI 路径不同，不能用微小差异宣称优化。PCK {pack['pck_bytes']/1024**2:.2f} MiB，依然超出早期预算；本轮没有做统一 LOD、资源裁剪或渲染调用优化。真实手机性能仍未验证。灯光层修正前的中间 Web 回合曾出现 250 ms 长帧，已另存 <a href="interim-long-frame-observation.json">中间观察记录</a>；不能用最终单轮较低的最大值宣称长帧已解决。</p>
<p><a href="optimization-backlog.md">后续定位入口</a> · <a href="performance-issues.json">长帧问题清单</a> · <a href="world-clean-performance.json">普通完整帧数据</a> · <a href="world-props-clean-performance.json">集中破坏数据</a> · <a href="web/web.json">Web 数据</a> · <a href="interaction-check.json">交互验证</a> · <a href="validation.json">验证摘要</a> · <a href="package-audit.json">包体审计</a></p>
<h2>与概念图仍有的距离</h2>{fig('../../moonbase-concepts-2026-11-13/01-gameplay.png','原设计概念图，仅作为方向对照，不是实机。')}
<p>本轮补齐了主要场景组成、整体轮廓与交互层；概念图里的高密度微磨损、写实月壤、近景岩石细节和细腻接触阴影还没有达到同等水平。新程序化设施仍比基地云模型干净，材质密度需要继续统一。HUD、字体、音效和手雷造型没有在本轮改动，也没有制作基地室内。</p>
<p>代码、可编辑 Blender 源和证据保存在 space 分支。当前为开发预览，未覆盖主线与生产站。</p>
</main><script>document.querySelector('#slider').addEventListener('input',e=>document.querySelector('#before').style.clipPath=`inset(0 ${{100-e.target.value}}% 0 0)`);</script></html>'''
(H/'index.html').write_text(html);print('REVIEW_C_READY')
