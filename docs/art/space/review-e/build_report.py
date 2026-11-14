from pathlib import Path
import json,html
H=Path(__file__).resolve().parent

def image(path,caption):return f'<figure><a href="{path}"><img src="{path}" loading="lazy" alt="{html.escape(caption)}"></a><figcaption>{caption}</figcaption></figure>'
def compare(key,title):
 return f'<h2>{title}</h2><div class="compare"><img src="after/{key}.png" alt="改造后"><img class="before" src="before/{key}.png" alt="改造前"></div><label>左侧改造前，右侧改造后<input aria-label="{title}比较边界" type="range" min="0" max="100" value="50"></label>'
native=json.loads((H/'presentation-clean-performance.json').read_text());web=json.loads((H/'web/web.json').read_text())['performance'];pack=json.loads((H/'package-audit.json').read_text())
issues={'native_over_33ms':[f for f in native['frames'] if f[1]>33.33],'web_over_33ms':[f for f in web.get('frameTrace',[]) if f[1]>33.33],'native_transition_43_48':native['transition_43_to_48'],'note':'Native seconds and Web elapsed milliseconds use different origins. Single runs, frame intervals rather than GPU time. No claim that stutters are solved.'}
(H/'performance-issues.json').write_text(json.dumps(issues,indent=2)+'\n')
page=f'''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>枪械、HUD 与地球 · 实机对比</title><style>
*{{box-sizing:border-box}}body{{margin:0;background:#0c141c;color:#e7ecef;font:16px/1.75 system-ui,sans-serif}}main{{max-width:1280px;margin:auto;padding:30px 22px 70px}}h1{{font-size:clamp(28px,4vw,48px);line-height:1.25}}h2{{font-size:26px;color:#f0a374;margin-top:42px}}a{{color:#83dae2}}p{{max-width:105ch}}.muted,figcaption{{color:#a6b8c6;font-size:14px}}figure{{margin:0 0 20px}}img{{width:100%;display:block}}.grid{{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}}.compare{{position:relative;aspect-ratio:16/9;overflow:hidden;border:1px solid #33404c}}.compare img{{position:absolute;inset:0;width:100%;height:100%}}.before{{clip-path:inset(0 50% 0 0)}}input{{display:block;width:100%;accent-color:#e98244}}label{{font-size:14px;color:#afbdc8}}.notice{{border-left:3px solid #e98244;background:#192631;padding:14px 18px}}table{{border-collapse:collapse;width:100%;min-width:600px}}td,th{{text-align:left;vertical-align:top;border-bottom:1px solid #34434e;padding:12px}}.scroll{{overflow:auto}}@media(max-width:700px){{.grid{{grid-template-columns:1fr}}main{{padding:20px 14px}}}}
</style><main><p class="muted">SPACE / REVIEW E / 2026-11-14 · Godot 实际渲染</p><h1>枪械、HUD 与地球</h1><p>改造前基线为 a820da7。主视角、场景布局、相机视野及分辨率一致；只改变本轮三项及持枪姿态。截图用测试状态固定为 00:42 / 08，便于对照，不是生成图。枪械的持握位置属于本轮调整内容。</p>
{compare('gameplay','主视角：改造前后')}
<p>枪身从长顶轨和大块外壳，改为分离装甲、短瞄具座、侧置三组能量线圈、短护木、独立弹匣与更明确的机械连接。白漆、石墨、金属和橙色标记分开处理。敌人仍使用已批准的四红点头部与原有武器。</p>
{compare('ads','开镜：比例与遮挡')}
<p>持枪姿态向右下收拢，开镜时回到精确瞄准轴；游戏枪口标定不变。检查同时覆盖资源声明的轴线和实际模型 Reticle 的投影，均小于 0.001 像素；保留实际射击爆头与弹匣运动回归。</p>
<div class="grid">{image('after/reload.png','实际换弹中间帧：弹匣和支撑手继续使用原有动作接口。')}{image('after/overload.png','过载状态：线圈变橙，场景不整体洗红。')}</div>
<h2>HUD：按概念图组织，按实际规则显示</h2><p>顶部时间、橙色分隔和击杀数字重新调整比例、边距与暗色描边。右下改成五枚矢量弹头、准确发数与后备弹药符号。每枚弹头表示四发容量，部分填充表示剩余比例；数字提供精确读数。后备弹药无限，因此显示绘制的无限符号，没有伪造 24/120，也没有改变 20 发弹匣规则。手雷库存和触控功能继续保留。</p>
<div class="grid">{image('after/ammo-0.png','0 发：弹头轮廓变暗，数字强调空弹。')}{image('after/ammo-1.png','1 发：第一枚弹头部分填充，数字显示准确余量。')}{image('after/hud-999.png','999 击杀极值：顶部根据实际字宽居中。')}{image('web-touch/ads.png','844×390 实际 Web 触控模拟：保留摇杆、开镜与射击空间。')}</div>
{compare('earth-detail','地球：固定 12° 视野的实机检查')}
<p>改造前的地球来自基线地图中的原始噪声球；改造后使用 NASA Blue Marble 全球地表与云层合成图。两者均由实际场景渲染，12° 视野只用于放大检查；正常游戏仍使用原视野。可以辨认非洲、欧洲、海洋、云带和昼夜边界。</p>
<p>地球使用一个不透明球体、两张带 mipmap 的贴图，薄蓝色边缘在同一着色器中近似表现；没有新增实时灯、透明云球、实时气象或额外场景渲染。太阳方向来自地图主光，观察朝向为艺术构图选择，不对应真实日期的天象。</p>
<p>素材：<a href="https://svs.gsfc.nasa.gov/2915">NASA SVS Blue Marble</a>、<a href="https://science.nasa.gov/earth/earth-observatory/the-blue-marble-true-color-global-imagery-at-1km-resolution/">NASA Blue Marble 地表与云层说明</a>。图像来源致谢 NASA Goddard Space Flight Center、Reto Stöckli、Robert Simmon 及相关科学团队。完整来源与<a href="../../../../assets/models/space/earth/SOURCE.txt">使用说明</a>随 Web 包附带；不使用 NASA 标志或暗示背书。</p>
<h2>功能与开销记录</h2><p>原生导入、导航、实际坡道、规则、主视角状态、ADS/实际 Reticle、换弹与真实爆头通过；原入口瞄准回归通过。Chrome 实际 Web 完整回合与触控模拟通过。物理手机与人工手感评审尚未进行。</p>
<div class="scroll"><table><tr><th>本轮单轮样本</th><th>P50</th><th>P95</th><th>P99</th><th>最大帧间隔</th></tr><tr><td>原生，预热后 ms</td><td>{native['warm']['p50_ms']:.2f}</td><td>{native['warm']['p95_ms']:.2f}</td><td>{native['warm']['p99_ms']:.2f}</td><td>{native['warm']['max_ms']:.2f}</td></tr><tr><td>Chrome RAF，ms</td><td>{web['p50Ms']:.2f}</td><td>{web['p95Ms']:.2f}</td><td>{web['p99Ms']:.2f}</td><td>{web['maxMs']:.2f}</td></tr></table></div>
<p>PCK 为 {pack['pck_bytes']/1048576:.2f} MiB。采样时没有截图读回，数据为帧间隔而非 GPU 时间。原生表格使用预热后样本；起始阶段另有 146.73 ms、69.84 ms 长帧，已在长帧记录中保留。没有完成三轮固定种子的系统性优化，不能据单轮结果宣称卡顿已解决。<a href="performance-issues.json">长帧记录</a> · <a href="validation.json">验证摘要</a> · <a href="package-audit.json">包体审计</a> · <a href="web/web.json">Web 原始数据</a></p>
<h2>与原概念图对照</h2>{image('../../moonbase-concepts-2026-11-13/01-gameplay.png','原概念图，仅供美术方向比较，不是实机。')}
<div class="notice">本轮交付的是三项专项实装与对比，视觉是否达到你的预期仍待评审。实机枪械仍偏低模，手部动作和磨损密度可以继续精修；全图构图、月面、工业装配细节和性能专项没有在这一轮全部完成。基地室内、敌人行为和射击数值未变。</div>
<p><a href="README.md">制作源与复现方式</a> · <a href="http://localhost:8766">本机 Web 预览（需本地服务）</a></p></main><script>document.querySelectorAll('input').forEach(input=>input.addEventListener('input',()=>input.parentElement.previousElementSibling.querySelector('.before').style.clipPath=`inset(0 ${{100-input.value}}% 0 0)`));</script></html>'''
(H/'index.html').write_text(page);print('REVIEW_E_READY')
