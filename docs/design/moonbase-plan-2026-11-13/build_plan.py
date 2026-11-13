"""Build a portable, offline HTML production plan. No game runtime changes."""
from pathlib import Path
import base64,html,json,re,hashlib
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
S=[]
def h(s):return html.escape(str(s))
def table(head,rows):return '<div class="table-wrap"><table><thead><tr>'+''.join('<th>'+h(c)+'</th>' for c in head)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+str(c)+'</td>' for c in row)+'</tr>' for row in rows)+'</tbody></table></div>'
def sec(id,n,title,lead,body):S.append(dict(id=id,n=n,title=title,lead=lead,body=body))
def note(s):return '<div class="note">'+s+'</div>'
def cards(rows):return '<div class="cards">'+''.join('<div class="card"><h3>'+a+'</h3><p>'+b+'</p></div>' for a,b in rows)+'</div>'
sec('brief','01','产品定位与制作边界','把已经成立的一分钟射击体验，放进一个具有统一制造语言的月球工业基地。',cards([
('核心体验','进入场地，识别机甲，快速瞄准，击杀与转移；顺手打碎设备外壳与维护物件。60 秒结束即可再来一局。'),
('第一版交付','一张紧凑月球基地地图、一把可开镜与换弹的卡宾枪、两种机甲敌人、一个普通到狂暴的完整回合、桌面与 Web 可运行版本。'),
('艺术定位','具有工程结构感的风格化硬表面：大块米白装甲包覆深色机械骨架，橙红识别带与少量青色状态光；保留轮廓和面材，克制微小噪声。'),
('范围控制','首版不引入飞船驾驶、氧气管理、低重力数值、机甲技能树、武器商店或复杂室内探索。参考月球环境的视觉，不额外改变走位与击杀规则。')])+note('文档状态：<b>需求与美术制作提案 v1.0</b>。概念图为 AI 生成的视觉参考；当前没有月球地图、三维资产或性能实测。所有预算、尺寸和材质数值均为起始目标，须经样板验证。'))
sec('baseline','02','现有系统：继承、替换与隔离','代码基线 73f0968；以下“已实现”指原项目，不代表月球小样已经实现。',table(['系统','当前核查','小样要求'],[
('回合与结算','scripts/run_rules.gd：60 秒，连续补敌；击杀 +1，爆头计入同一击杀；最后 15 秒狂暴，结束后约 1 秒收尾。','直接继承计时与记分，视觉将狂暴解释为基地过载；过载不增加计分时长。'),
('移动与相机','player.gd：步行 7 m/s、冲刺 10.5 m/s、视高 1.65 m、腰射 FOV 63°、已有开镜。','保留移动、跳跃与控制响应。机甲外形与月球背景不触发低重力改动。'),
('枪械','game.gd：20 发弹匣、3 枚手雷；已有换弹、后坐力、射击／开镜和投掷。','换模型、音色、枪口与命中表现；射速、伤害、换弹时长首先读取现有逻辑，不从概念图推导。'),
('敌人','普通／快速两种行为，独立头部判定；已有死亡、重生与警告。','宽肩步枪机甲与轻型突击机甲映射到两种行为；新外形必须适配现有命中盒、动作和爆头反馈。'),
('破坏','interactive_props：独立部件、普通／狂暴命中、手雷遮挡、重开恢复、结尾清场与碎片上限。','复用事件与恢复框架，重做太空道具；拆壳、散落、喷散各有区别，装饰破坏不自动变范围伤害。'),
('HUD 与辅助','时间、击杀、准星、情境弹药；不显示生命值，低血量边缘暗红；已有触控、减少动态效果、语言与暂停。','保留信息结构。概念图“24/120”仅是图像生成文字，不新增有限备弹或生命／氧气仪表。'),
('工程与发布','Godot 4.7.2 Compatibility；Blender 5.2.2；现有项目有九图与自动 Web 发布。','规划专用小样入口、地图 ID moonbase_trial、独立成绩键；是否合入默认菜单与公开发布，进入实施阶段再按发布范围办理。')])+note('单图小样导出须审计依赖：当前 all_resources 导出和全图目录引用可能把旧地图一起打包。建立专用导出预设与轻量入口，不能只在菜单隐藏旧地图就声称包体已减小。'))
sec('reference','03','概念图拆解：哪些东西决定“就是这个感觉”','先抓住大形、材料与光照，再填螺栓、贴花和磨损。', '''<figure class="annotated"><img src="@@IMG1@@" alt="月球基地第一人称 AI 概念图，带八个美术观察点" loading="lazy"><div class="pins">'''+''.join(f'<a class="pin" href="#ref-{i}" style="left:{x}%;top:{y}%" aria-label="查看美术观察点 {i}">{i}</a>' for i,x,y in [(1,20,38),(2,81,30),(3,61,23),(4,43,49),(5,60,48),(6,76,76),(7,22,83),(8,87,48)])+'''</div></figure>'''+table(['观察点','保留特征','制作指令'],[
('<span id="ref-1">01 飞船</span>','低矮机身、长楔形座舱、斜立尾翼、落地支撑与外挂机械组。','保留比例逻辑，另画原创剪影；近景要见到起落架与承重连接，远景炮口等细节可合并。'),
('<span id="ref-2">02 基地</span>','厚重八角气闸、面板退台、深色窗洞、上层服务平台。','门洞至少三层深度：外壳、密封框、门扇；有可踩斜坡、真实支柱和设备维修通路。'),
('<span id="ref-3">03 氧气设施</span>','竖塔与横罐组合、腰部束环、管线有入口出口。','用圆形压力容器对比建筑的斜切块面；先做管径、支架与接口，再补标识。'),
('<span id="ref-4">04 步枪机甲</span>','胸肩宽、头部独立、足部落地、枪与手有明确连接。','头肩在 8–20 m 保持可识别；胸甲遮住机械核心但关节露出，不能做成全身一样粗的盒子。'),
('<span id="ref-5">05 突击机甲</span>','更窄的躯干、前倾姿态、橙色肢体段。','用比例与运动区分，不依赖改色；保留可命中的头，腿再细也不能改变已有判定公平性。'),
('<span id="ref-6">06 枪械</span>','白壳／黑芯／青色环，橙色可拆弹匣，明确瞄准线。','第一人称关键件优先：握持、机匣、枪口、瞄具、弹匣；只在看得见的区域做高密度几何。'),
('<span id="ref-7">07 月面</span>','低饱和地面托住亮装甲，宽缓起伏与局部石块。','近处有尺度，交战区保持安静；不能把每个像素都覆盖高对比碎石与脚印。'),
('<span id="ref-8">08 明暗</span>','清楚的主光方向、装甲面间差异、深色洞口和小面积暖灯。','白壳亮但有灰阶；阴影保留结构。黑天空不等于把敌人压黑，补光有艺术导向且保持一致。')])+note('验收先看 640×360 缩略图能否读出飞船、基地门洞和两类机甲。这个检查方法是本案提出的门槛，不是“概念图已经通过实机验证”。'))
sec('art','04','画面风格与色彩语言','风格化工业硬表面；强轮廓、少色系、有限做旧、清楚的使用关系。','''<div class="swatches">'''+''.join('<div style="--sw:'+color+'"><span></span><b>'+name+'</b><code>'+color+'</code><p>'+use+'</p></div>' for name,color,use in [('装甲白','#D8D6CD','大面积外壳；留出受光变化'),('机械蓝灰','#263445','内构、底盘、关节、凹槽'),('工业橙红','#D85C38','识别带、可拆接口、突击兵装甲'),('能量青','#70CFDF','状态窗、线圈环，小面积使用'),('月壤灰','#777A7E','地面与远景；避免均匀纯灰'),('暖灯色','#E8B571','门内照明与维修灯')])+'''</div>'''+cards([
('大／中／小三层形体','大层：机身、楼体、罐体；中层：装甲分区、门框、进排气组、支架；小层：螺栓、划痕、标识。正常战斗距离必须先读出前两层。'),
('形状语法','外壳采用宽斜切、少量折面；承重骨架用直梁与节点；压力系统多用圆筒与束环。每类物体的形状来自用途，避免全图同一种倒角盒。'),
('控制信息密度','近景英雄资产保留局部细节，交战目标身后的墙板与地面保留完整色块。相邻物件不要同时用粗黑缝、橙条、发光圈抢眼。'),
('做旧有原因','脚边、检修门把手、落架、货箱转角和机枪口附近可磨损；装甲大面保持干净。月尘来自行走、落地和作业，不全场用随机灰噪声。')])+table(['对象','建议面积关系（制作起点）','颜色的功能'],[
('基地／飞船','约 55–65% 白壳，25–35% 深结构，5–10% 橙色；青光只在少数接口。','这些比例是造型检查参考，不要求整张截图满足固定直方图。'),
('步枪机甲','白胸甲与深色核心为主，肩部橙红大块。','红色头部传感器提示敌人身份，体积仍须在无发光时成立。'),
('突击机甲','橙色肢体段更大、白胸甲更小、关节留空。','远距离先读到窄与快，近处才读到部件；不能仅靠橙色区分。'),
('互动道具','可拆缝、卡扣和局部标识可重复。','青色不是统一“可打爆”标识。危险能量组件另用一致的警示形状和声音；氧气罐不默认是爆炸桶。')]))
sec('modeling','05','建模规范：轮廓、厚度、支撑与尺度','模型必须能在玩家视角里成立，也必须能继续编辑、替换和分级。',table(['规范','起始值／约束','检查方式'],[
('单位与方向','Blender 以米为单位，应用缩放；导出为 Godot Y-up。静态件 pivot 在接地／拼接点，活动件 pivot 在实际铰链。','导入 1 m 标尺与 1.8 m 人形；检查负缩放、法线、转轴和部件命名。'),
('模数','建筑主网格 1 m，半格 0.5 m，精修吸附 0.1 m；门洞与平台用统一接口高度。','搭两段墙、一处转角、一扇门验证无缝拼接，再批量做套件。'),
('几何层级','外壳／内构／机械附件独立组织；只有需要破坏或动画的部件才独立成节点。','一个门框不拆出几十个运行时节点；高频螺栓可烘入法线。'),
('倒角','手持件可从 3–10 mm、设备 1–3 cm、建筑厚边 3–8 cm 起试；非统一全局参数。','63° FOV、正常距离下能见到高光而不显充气；高模倒角可烘焙，低模只留影响轮廓的边。'),
('薄片','盖板、翼面、灯罩和护栏必须有可读的厚度或折边。','从 45°、背面与近景查看；不出现纸片侧面、悬空支柱或无支撑的管道。'),
('机械连接','管子接法兰，法兰接设备壳；承重件落在基座，活动轴留回转空间。','检查起落架、塔架束环、栏杆柱脚和机甲膝踝，不用小细节遮掩接合问题。'),
('细节分工','几何做剪影、洞口和厚度；法线做浅缝、压纹；粗糙度做磨擦变化；底色做识别区。','关闭颜色与贴花后仍能认出物体类型；关闭法线后主体不垮。'),
('UV／拓扑','UV0 用于材质；拟烘焙静态光的结构另有无重叠 UV2；活动件分开。','检查接缝、镜像文本、UV 拉伸、三角化后的阴影与法线；不要依赖 Blender 视口效果。'),
('贴图密度','起点：近景枪 512–1024 px/m；主设备 256–512；远景 64–128。可平铺材质不据此扩成巨图。','同距离的相邻物件清晰度接近；资源预算优先覆盖画面占比大的部分。'),
('交付结构','art_source/moonbase/ 存 .blend、烘焙与贴图来源；assets/models/moonbase/ 存 GLB；绑定、碰撞与逻辑放 Godot 场景。','每件有来源、版本、LOD、材质槽、三角形、纹理和碰撞说明；导出后重新导入验证。')])+note('不要把全部零件加大倒角段数当作质量提升。先做一个气闸角落、一只机甲肩关节和一段枪机匣，冻结观察机位，验证轮廓与高光再扩产。'))
sec('materials','06','材质与贴图：让白装甲、金属与月壤真正不同','下列 roughness / metallic 均为 0–1 的起始范围，不是跨渲染器可直接复制的校准值。',table(['材料','roughness / metallic','表面与制作方法'],[
('涂漆金属／陶瓷装甲','0.38–0.62 / 0','略暖的灰白底色，宽而克制的高光；露底金属仅出现在实际剥漆区。不要因底下是金属就把整个漆面 metallic 拉高。'),
('裸露机械金属','0.28–0.55 / 0.75–1','中低明度，反射有环境内容；磨损只强调连接与手持区域，不能变一片镜面铬。'),
('橡胶、密封圈、软管','0.72–0.95 / 0','近黑但留层次，靠截面与接触阴影读形；软管有合理弯曲半径，避免细密全长螺纹。'),
('月壤与碎石','0.80–1 / 0','低频高程变化叠低幅细噪声；主交战区减弱法线强度，脚印集中在入口和维修路。'),
('氧气罐与管线','罐体同涂装，法兰按金属','白壳、深色支座、少量规格色环；O₂ 标识与维护盖清楚，铭牌不承担路线识别。'),
('舷窗／观察窗','0.12–0.28 / 0','近景玻璃小面积使用；先用不透明深色窗配受控反射、内框与暗箱，只有必须看穿处使用透明。'),
('青色能量环','底材按实体材质，局部 emissive','先有可读实体，再做小范围发光。发光贴图不等于真实落光，需要时单独用一盏受限补光验证。'),
('橙色识别条','0.45–0.70 / 0','跟随面板与部件方向，不平均横贴每个物体；几何描边不再重描这条色差。')])+cards([
('三套共享材质图集','建筑 trim sheet 管门框与结构边；设备 atlas 管维护盖、通风和接头；道具 atlas 管货箱与小容器。英雄资产可独立图集，先按可见收益分配。'),
('通道与颜色空间','Base Color 与 Emission 按颜色贴图导入；Normal、Roughness、Metallic、AO 按数据处理。可打包 ORM，但须核对 Godot 通道与导入设置，先用球样和灰卡检验。'),
('AO 的边界','轻量顶点 AO 适合接触关系，不把整块底色烤黑。可破坏物、门、机甲与动态部件不能留下固定在空中的烘焙阴影。'),
('防止重复踩坑','禁用大面积灰色脏层洗掉主色；禁用整图统一强高光；禁用随机面板缝覆盖每个平面。白色退灰、塑料变石头和金属像黑洞均要返工。')]))
sec('terrain','07','月面、天空与空间氛围','月球的识别来自黑天空、灰地形、强方向光和人工设施的对比。',cards([
('地形分三层','可走平面用简洁地形与稳定碰撞；场内边缘用少量可绕石群；远处环形山是低细节背景。陡坡、坑缘与视觉边界必须对应碰撞边界。'),
('近景地表','入口附近压实路径、脚印、着陆痕迹与轮迹形成用途关系；外圈更粗糙。石块不均匀撒满战区，更不在敌人头肩后制造高对比花纹。'),
('天空与地球','黑或极深蓝天空；地球作为远景方向锚点而非会追着镜头移动的 UI。大小与位置以视觉构图为准，不宣称科学观测复现。'),
('尘与蒸气','无大气环境不放常态飘雾与风吹尘云。枪击、脚步、着陆残留可用短时、受控的抛射尘粒；设备泄压只作为艺术化局部效果，不能持续挡住目标。')])+note('月尘纹理先在 8–20 m 战斗距离评估。对整体画面有帮助的地表大尺度变化优先于远处成千上万颗小石子。'))
sec('light','08','光照、阴影与后处理','目标是白色装甲有面间差异，深色机甲仍有胸腹与头部体积。',table(['层次','实现方向','验收与禁区'],[
('主光','一盏有阴影的太阳光；建议从玩家观察方向的侧上方约 30–55° 入射，先固定方向再摆场景。','飞船压住地面的接触清楚，机甲胸肩面有差异；不让主要交战区长期正逆光。'),
('环境与间接光','中性偏冷的低强度环境补光；静态建筑试验 LightmapGI 或有节制的顶点接触烘焙。','黑天空下也要读到阴影内的结构；不能用全局环境光把所有面照成同一种灰白。'),
('人工照明','气闸内暖光、设备青色灯、少量维修灯分区。','灯的来源、灯池与受光面对应；多数发光指示件无需创建真实光源。'),
('反射','优先静态环境反射或少量局部 ReflectionProbe；金属与玻璃依赖它们的合理环境内容。','无水地面不加湿地倒影；不为每台机器建立实时反射视口。'),
('接触与 AO','先靠几何遮蔽、阴影和烘焙；SSAO 作为可关闭的样板试验。','不出现黑边贴纸和大圈脏晕；关闭 AO 后形体仍成立，启用后对照 Web 开销。'),
('后处理','先稳定曝光与色调，再考虑小幅 Glow；用固定机位白壳灰阶样本校准。','亮面保留纹理与色阶，青光不糊成大光团；禁止靠重色差、景深、镜头污渍遮住不足。'),
('狂暴阶段','45 秒后局部警示灯、枪械线圈、音色与少量能量碎物增强。','不把整个天空和所有白壳染红；移动敌人头部持续可辨；不集中新建大量灯或编译材质变体。')])+note('Godot 4.7 官方列出 Compatibility 可显示已烘焙 LightmapGI、可用 SSAO 与 Glow；SSR、原生体积雾及 SDFGI 不可作为 Web 基线。支持某功能不代表本项目启用后足够快，必须 A/B 测试。<a href="https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html">渲染器能力表</a>。LightmapGI 的烘焙需要支持 RenderingDevice 的设备；见 <a href="https://docs.godotengine.org/en/4.7/classes/class_lightmapgi.html">官方说明</a>。'))
# Schematic map, authored in metres. Coordinates are a proposed greybox, not a baked level.
def xy(x,z):return (404+x*12,405+z*12)
def rect(x,z,w,d,cls,label):
 px,py=xy(x,z)
 return f'<g class="zone {cls}" tabindex="0" role="button" data-zone="{cls}" aria-label="查看{label}设计"><rect x="{px}" y="{py}" width="{w*12}" height="{d*12}" rx="8"/><text x="{px+w*6}" y="{py+d*6}">{label}</text></g>'
MAP='''<svg class="map-svg" viewBox="0 0 820 780" role="group" aria-labelledby="map-title map-desc"><title id="map-title">月球基地灰盒布局提案</title><desc id="map-desc">44 米乘 48 米场地，北侧基地与高台，西侧飞船，东侧氧气设施，中间低掩体与南侧玩家入口。路线、出生点和净空均为待验证设计。</desc><defs><pattern id="grid" width="24" height="24" patternUnits="userSpaceOnUse"><path d="M24 0H0V24" fill="none" stroke="#273c4d" stroke-width=".5"/></pattern><marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0L10 5L0 10Z" fill="#e7ad65"/></marker></defs><rect width="820" height="780" fill="#101c29"/><rect x="140" y="117" width="528" height="576" fill="url(#grid)" stroke="#8d9aa8" stroke-dasharray="6 5"/><text x="404" y="81" class="dim">44 m</text><text x="102" y="405" class="dim" transform="rotate(-90 102 405)">48 m</text><text x="155" y="101" class="dim">北 / −Z</text>'''
MAP+=rect(-8,-22,28,8,'base','基地气闸 / 高台 2.4 m')+rect(-21,-7,14,12,'pad','飞船停机坪')+rect(12,-10,9,20,'oxygen','氧气 / 工业区')
MAP+='''<g class="map-layer" data-layer="cover">'''
for x,z,w,d in [(-4,-5,5,2),(3,3,5,2),(-8,10,3,2),(10,15,4,2)]:
 px,py=xy(x,z);MAP+=f'<rect x="{px}" y="{py}" width="{w*12}" height="{d*12}" rx="3" fill="#5b6d7a" stroke="#b7c4cd"/>'
for x in [-6,15]:
 px,py=xy(x,-14);MAP+=f'<path d="M{px} {py}h48v96h-48Z" fill="#394c5b" stroke="#b7c4cd"/><path d="M{px+12} {py+75}v-48" stroke="#e7ad65" marker-end="url(#arrow)"/>'
MAP+='''<text x="404" y="401" class="dim">中央交战区</text><text x="404" y="426" class="dim">8–20 m 优先交战距离</text></g><g class="map-layer" data-layer="routes"><path d="M386 635L230 600L192 505L222 300L340 282L560 282L605 500L550 623Z" fill="none" stroke="#e7ad65" stroke-width="5" stroke-dasharray="12 7" marker-end="url(#arrow)"/><path d="M280 536L508 345" fill="none" stroke="#70cfdf" stroke-width="4" stroke-dasharray="7 7" marker-end="url(#arrow)"/></g><g class="map-layer" data-layer="spawns">'''
for name,x,z in [('P',-2,20),('E1',-17,-15),('E2',6,-21),('E3',19,-8),('E4',16,19)]:
 px,py=xy(x,z);MAP+=f'<circle cx="{px}" cy="{py}" r="19" fill="{"#264f57" if name=="P" else "#6b3930"}" stroke="#e8d0ae"/><text x="{px}" y="{py+1}">{name}</text>'
MAP+='''</g><text x="404" y="740" class="dim">原点在场地中心；X 向东，Z 向南；符号为概念示意</text></svg>'''
sec('layout','09','地图结构与尺度：三块主题，一个战斗环','以 44×48 m 为灰盒起点；尺寸是待调参数，概念图不直接充当碰撞图。','''<div class="map-tools"><label><input type="checkbox" data-toggle="routes" checked>路线</label><label><input type="checkbox" data-toggle="spawns" checked>出生点</label><label><input type="checkbox" data-toggle="cover" checked>掩体与坡道</label></div><div class="map-grid"><figure>'''+MAP+'''<figcaption>点击区域可看设计职责。平面与资产占地为起点，具体净空需灰盒实走。</figcaption></figure><div class="card" id="zone-info" aria-live="polite"><h3>基地气闸 / 高台</h3><p>北侧作为主方向锚点，玩家从南侧进入即可看见橙色气闸。高台仅覆盖部分场地，双坡道让敌人可接近；平台下先封闭，不暗示可穿行空间。</p></div></div>'''+table(['分区／接口','起始规格','设计意图'],[
('西侧飞船','飞船主体约 14×11 m 占地，最高约 6 m；停机坪外沿留连续侧路。','飞船提供方向与遮挡，腹部先封闭为不可穿行；不把腿间小缝做成碰撞陷阱。'),
('北侧基地','主楼约 28×8 m；服务平台高 2.4 m；两条坡道长约 8 m、净宽至少 3 m。','形成中尺度建筑层次；2.4/8 的坡度约 16.7°，楼梯视觉使用连续斜坡碰撞。'),
('东侧氧气区','约 9×20 m 设备带；两座竖塔、一组横罐、维修侧路。','竖向地标与气闸组成轮廓对比；管线跨路时保证头部、跳跃与相机净空。'),
('中央与南侧','错位低掩体，优先 0.9–1.2 m 高；主通道 3.5–5 m，次通道最低 3 m。','中央可穿插，掩体间有断续射线，不形成一路贯穿的长狙击通廊。'),
('路线长度','外环步行目标约 70–90 m，对应 7 m/s 下约 10–13 秒；实长在灰盒测量。','一局能多次走完关键路线；出生点到第一目标不应长时间空跑。'),
('边界','围墙、地形和不通行设备给出明确视觉封闭；危险坑不作为必经路线。','避免画面看似可走但撞空气墙，也避免穿出场地后掉落。')]))
sec('level-edit','10','地编：从灰盒到可验证的战斗空间','美术物件必须解释既有玩法空间，不能依靠后期镜头掩饰布局问题。',table(['步骤','编辑师具体动作','通过条件'],[
('01 标尺与碰撞','放置玩家胶囊、两类敌人、1 m 标尺；以 0.5–1 m 模数搭地面、围边、基地实体、飞船代理。','从玩家视高走通整个环路；枪口、相机、跳跃与坡顶不穿模。'),
('02 敌人与节奏','沿四个候选入口做视线遮挡；保留原有补敌和并发攻击限制，继承现有避脸刷新检查，再按灰盒调候选点。','开局目标尽快可见；敌人不在玩家脸前弹出，也不能藏在远处一直不接战。'),
('03 射线与覆盖','标记 8、15、20 m 观察点；测试中央到平台、氧气区到停机坪的枪线。','高台不能安全覆盖全图；相邻区域可互相压迫又有短绕行机会。'),
('04 三个主机位','C0：(-3,1.65,16) 朝中央与气闸；C1：(-17,1.65,9) 朝飞船；C2：(10,1.65,7) 朝氧气塔。坐标仅为起点。','固定 FOV、分辨率与普通／狂暴状态对照；相机若被物件挡住，应先检查布局而非只移机位。'),
('05 替换结构','先地形、楼体、飞船，再罐体和近景掩体；每换一组都验证碰撞和导航。','灰盒的通路、掩体高度与刷怪条件仍成立；装饰厚度不能把通道挤窄。'),
('06 整理层次','压低后排接缝、栏杆和窗格的对比；让机甲常出现的背景有完整色块。','缩略图仍读到地标与角色；关闭描边也不丢失主要掩体边缘。'),
('07 互动摆放','先放 6–9 组太空小物，靠墙、维护台和设备接口组成用途组合；避开出生与转弯位置。','玩家能在行进中看到并射击；碎片不挡路，重开后状态完整恢复。'),
('08 完整走查','按环路、短穿插、坡道、高台、边界、各入口分别实走；连续打三局并重开。','无卡住、悬空、意外捷径、穿帮碰撞、掉出地图或最后几秒找不到敌人的情况。')])+note('不得在终版镜头之外保留不可玩的区域。环境美术检查与实际游玩分别留证：固定机位负责视觉对照，移动实走负责玩法与碰撞。'))
sec('ship','11','英雄资产：飞船如何做出重量感','飞船是场景主地标，不提供驾驶玩法；主轮廓与落地关系占制作优先级。','''<figure><img src="@@IMG2@@" alt="AI 生成的月球基地全景参考" loading="lazy"><figcaption>全景提供场景关系，不是已测量的关卡蓝图。</figcaption></figure>'''+cards([
('一级体块','楔形前舱、后部动力舱、左右机翼和两片倾斜尾翼。先输出三套简化剪影，在 C0 与 C1 看大小和遮挡，再选定一套原创比例。'),
('二级结构','机翼根部有承重过渡；尾翼插入稳定座；发动机与进气组有壳厚、内腔和连接；外挂武器不是悬空贴在翼面。'),
('起落架','接地脚、减震段与收纳舱关系明确。脚掌与停机坪接触阴影可见，关节结构无需复杂运动，但必须看起来能支撑机身。'),
('制作取舍','近处座舱框、机头截面和最近的落架优先；远侧武器、后部喷口内部可减面。停机坪边灯与电缆不比机身轮廓更抢眼。')])+note('用户提供的飞船仅作为形态语言参考。最终资产须保留自制来源，重新设计面板分区、比例与挂载关系，不能把参考图直接当成有授权的模型或贴图。'))
sec('base-oxygen','12','基地与氧气工业设施：中等尺度的制作清单','一个气闸角落做精，再用模块扩展整座基地。',table(['组件','必须体现的结构','地编与材质要求'],[
('气闸','外壳压顶、八角密封框、凹入门扇、滑轨／铰链、踏步平台。','橙色集中在开口，门洞深处留暗；不可通行门与真正入口在尺度和照明上有区别。'),
('墙体套件','直墙、转角、窗墙、设备墙、地脚、压顶、端头。','统一模数与接口；窗洞有内框或暗箱；不要整面平板加一圈粗黑描边。'),
('平台与坡道','承重梁、立柱脚、边缘折板、防滑面、扶手连接。','扶手高度和杆距可辨，不让装饰立柱落在主通道；底面未开放时用结构闭合。'),
('氧气分离塔','厚罐体、束环、接口法兰、检修口、支腿与基座。','塔与设备柜有功能连接；大白罐通过面材、方向光与支撑建立层次，不用全身污渍。'),
('横罐与管线','底鞍座、管径变化、阀门、护罩、弯头与补偿段。','管子不能插进门或越过玩家头部净空；先管径和接头再细小刻度。'),
('热交换／供电','散热片组、检修盖、绝缘端头、电缆槽、固定件。','密集鳍片远处可用法线或简化片组；机器上的小灯多为 emissive。'),
('太阳能阵列','支架、铰接与基础，面板有厚度与可辨格分。','作为低对比侧景，不用镜面反光照满战区；不新增供电管理玩法。'),
('维修台与标识','工具、补给箱、备件与规格铭牌。','物件围绕使用场景成组；O₂ 标签说明设备用途，不承担玩家生命值信息。')]))
sec('enemies','13','敌人机甲：模型、动作与爆头可读性','两种行为沿用原版，通过比例、装甲分布和动作节奏形成区别。','''<figure><img src="@@IMG3@@" alt="两类机甲与玩家卡宾枪的 AI 设定参考" loading="lazy"></figure>'''+table(['项目','步枪机甲','突击机甲'],[
('比例','视觉身高约 1.9–2.1 m，肩宽约 0.85–1.0 m；厚胸甲与可靠的足部支撑。','约 1.75–1.9 m，肩窄约 0.65–0.8 m，前倾姿态与细长腿部。'),
('轮廓','胸、肩、前臂形成稳重块面；头不埋在肩甲里。','腰与肘部留空，橙色装甲集中在肢体段；不使用巨大翼片或细长不可读的头。'),
('头部目标','独立传感器壳与颈部机械段，红色小传感器；头部外观需与当前 head hit area 对齐。','头部同样明确，跑动时不能长期被武器或胸甲遮住；细头不缩小现有判定。'),
('动作','承重转移清楚，抬枪与瞄准前摇可读；脚不持续滑动。','保持原快速单位的冲近／规避规则；以姿态和步幅区别，不先改移动速度。'),
('死亡与爆头','头壳／传感器局部断裂，短促亮芯与机械碎片；躯体动作继承现有反馈。','统一爆头反馈语言，碎件数量受限；不用覆盖角色的大火球取代头部反馈。')])+cards([
('绑定与命名','当前敌人依赖按名称查找 Torso、Vest、Helmet、Head、Visor 与四肢等节点。先做视觉适配层或保留这些逻辑挂点，禁止只换 GLB 后让命中、爆头或动作静默失效。'),
('首版动作方案','先沿用现有分件转轴驱动，正确设置肩、肘、髋、膝、踝 pivot。若改骨骼，先验证导入与事件映射，再补步行、抬枪、命中、倒地与重生；不默认已有完整重定向工具。'),
('最低可读检查','在 8、15、20 m 分别拍亮背景、暗门洞、复杂设备背景、逆光四种状态。全彩与灰度下都要读到头肩；红色眼灯只能辅助，不能成为唯一识别来源。'),
('包围与碰撞','模型尺寸与动作不得改变原命中盒公平性。检查枪口方向、双手握持、脚掌接地，以及冲近玩家后头部不会被夸大肩甲完全遮掉。')]))
sec('weapon','14','玩家枪械与第一人称表现','机械细节集中在看得见的地方，瞄准与握持必须先成立。',table(['部位／状态','制作要求','验收'],[
('机匣与枪口','白色外壳包住深色导轨和线圈；枪口有真实内腔和护套，不只是贴一张黑圆。','正常腰射能读出枪口方向与主体，细节不抢过准星附近的敌人。'),
('握把与双手','握把、扳机护圈、托腮／枪托和护木连接合理；手套与袖口属于同一制造语言。','手指数量与握持正确，开镜、冲刺、换弹和投掷时不穿过机匣。'),
('弹匣','橙色可拆弹匣作为操作焦点；20 发逻辑不要求外壳画满 20 格刻度。','退匣、入匣、锁定、恢复射击的状态与原有音效／计时一致；暂停与取消不留下缺匣模型。'),
('开镜','保留当前 FOV 与倍率起点，枪身位置按新瞄具重新校准。','将现有硬编码瞄具坐标迁移或映射到前后瞄准挂点；射线、准星与视觉瞄准线一致。'),
('画面占比','概念图枪较大；小样建议从画面面积约 18–25% 起试，优先保留右下角空间。','在 16:9 与较宽手机横屏上，武器与手臂不遮住近距离敌人头部或关键落脚位置。'),
('光与材质','沿用独立 viewmodel 层和受控补光，环境阴影不把枪变黑。','枪与场景同色系但不漂浮发亮；青色线圈有实体与面材，发光变化不影响判定。'),
('投掷物','工业电容／破片罐的原创外形，功能沿用现有手雷。','模型握持、抛物与库存提示一致；不额外引入弹药属性、元素克制或技能冷却。')]))
sec('destruction','15','可破坏物：工业设施也要有“打起来有反应”的小尺度','首版优先 6–9 组、每组 2–4 个独立目标；不是把基地承重结构全部开放。',table(['物件','普通命中／狂暴命中','实现边界'],[
('货箱维护盖','先松动，再脱落；狂暴一次打脱，留下内框。','露出内部线束与设备色块；不让整台机器凭空消失。'),
('空容器／工具箱','盖板、工具分件弹开；不同材料音色。','复用现有小物框架，最多少量短寿命碎件。'),
('冷却接头','短时喷散并停止；装置保留。','作为局部艺术化效果，不产生全屏雾，不默认造成玩家减速或敌人伤害。'),
('设备显示屏','裂纹／变暗、局部火花；机座仍在。','可以模型或材质状态切换实现，不能永久熄灭整个交战区主照明。'),
('太阳能小样板／备用面板','小块破口或折板，背架保持。','放近景维护区；大型阵列先作静态侧景。'),
('危险能量组件','使用与普通容器不同的警示壳与充能声，可映射原爆炸桶。','半径、预警与伤害沿用已验证机制。氧气装置和每个青色灯圈不自动等于爆炸目标。')])+note('任何改变遮挡、可走通路或敌人伤害的破坏，都升级为玩法资产处理。需要完整／受损／破坏三个状态与复位说明；静态光烘焙不能把活动盖板的阴影留在空中。'))
sec('vfx-audio','16','特效、音效与一分钟情绪曲线','反馈服务于击杀节奏；前 45 秒克制，最后 15 秒增强，截止后立即停止计分。',cards([
('射击与命中','枪口短促亮点配少量壳屑／能量轨迹；金属火花、陶瓷壳片与月尘分开。保留身体命中、击杀与爆头的不同反馈，不重复叠加多层文字。'),
('狂暴过载','线圈加亮、设备小范围警示节奏和音色变化；沿用原破坏能力。不要通过改变所有材质、批量实例化新灯或临时载入模型来制造高潮。'),
('结尾清场','复用回合收尾状态，场景、可破坏物与机甲同时纳入清理与恢复。结算后不新增击杀；重开必须恢复碰撞、灯、部件与延迟连锁。'),
('音频风格','枪声保留冲击与节奏，叠加短促机械电磁音；机甲脚步、抬枪预警和命中声承担定位。采用头盔传导／通信式艺术表达，环境设定不要求把战斗全部静音。'),
('音量层级','敌人预警、命中与击杀高于设备环境声；氧气站、门内与停机坪分别使用克制循环声。不要给每个发光部件都配置持续蜂鸣。'),
('可访问设置','减少动态效果应降低碎片、闪烁与镜头振动；低血量沿用渐进暗红边缘，不显示生命条，不用频繁全屏闪白。手机触控区域继续避让准星与敌人。')]))
sec('type','17','字体、HUD 与工业标识规范','字体既要像同一套设备上的信息，也要在移动与闪光中看得清楚。',table(['用途','主方案','规格与原因'],[
('倒计时／击杀数字','Oxanium 600–700；首版试排使用 700。','本次实际检查：0–9 默认 advance 均为 578 units。保留默认等宽数字，关闭比例数字 pnum；不能只写 tnum 就假定所有字体有效。'),
('短英文标题／菜单','Oxanium 600；短标签可用 500。','宽度比当前 Rajdhani 更舒展、切角有机械感；仅用于短字串，不将长说明全设大写。'),
('中文界面','Noto Sans CJK SC Medium 500；必要强调使用真实 Bold 700 的独立裁剪。','中文有稳定字形与中等笔画；本 HTML 嵌入 Medium 子集。正文与错误提示不使用斜切装饰字体或虚拟加粗。'),
('低成本备选','保留 Rajdhani Bold + 现有 Glow Sans SC。','两者已随项目分发；若继续用 Rajdhani，计时器各数字位用固定宽容器或固定总宽，避免数字切换带动布局。'),
('设备文字','Oxanium 500 的 O2 / AIRLOCK / SERVICE 等短标；中文使用同一中文家族。','设备标识服务于场景用途，细铭牌不当 HUD；出口、可走入口与维修盖有层级，不到处重复长文案。')])+'''<div class="type-lab"><div class="controls"><label>数字字体<select id="font-choice"><option value="Oxanium">Oxanium 700（主方案）</option><option value="Rajdhani">Rajdhani Bold（现用）</option></select></label><label>字号 <input id="font-size" type="range" min="28" max="80" value="52"><output id="font-size-value">52 px</output></label><label><input id="slash-zero" type="checkbox">启用斜线零（Oxanium）</label><label>背景<select id="font-bg"><option value="dark">气闸暗面</option><option value="light">月面亮区</option></select></label></div><div class="hud-preview" id="hud-preview"><div class="hud-top"><span id="clock-preview">00:42</span><i></i><span>08</span><small>击杀</small></div><div class="preview-cross" aria-label="准星示意"><svg viewBox="0 0 32 32" aria-hidden="true"><path d="M16 3v6m0 14v6M3 16h6m14 0h6"/></svg></div><div class="preview-bottom"><span>月球基地 / 氧气设备就绪</span><span class="preview-ammo">20</span></div></div><p class="caption">离线实字体试排；不是游戏运行界面。背景只用于读字检查，不模拟真实曝光。中文与数字字体分别加载，不依赖联网字体服务。</p><div class="glyphs"><span class="ox">00:11　00:48　0123456789　O₂ / O2　I1l / 0O / 5S / 8B</span><span>月球基地　击杀　重开　氧气设备就绪　暂停　准备　返回首页</span></div></div>'''+table(['层级','1440×810 设计基准起点','排版／行为'],[
('计时与击杀','数字约 48–56 px；中文标签 18–22 px。','顶中一组；冒号不跳、分隔线由 SVG／绘制完成；最大三位击杀不挤压计时。'),
('准星','约 12–18 px 总宽，按 DPI 检查。','简单绘制，明暗背景均有对比；反馈短促，不用复杂锁定框。'),
('情境弹药','数字约 22–28 px 或现有弹匣视觉。','沿用现有显示节奏与触控避让；不同时叠放三套弹药仪表；满弹时可低存在感。'),
('菜单／设置','主按钮 24–30 px，中文 20–24 px，次要说明至少 16 px。','避免细长字重与高密度英文；真实触控热区按设备独立校核。'),
('场景标识','主要门号约 0.25–0.45 m 字高；检修标签按观察距离另定。','沿用模块表面方向，别用大块高亮文字替代建筑地标；远距离无需读到所有铭牌。'),
('字距与数字','数字字距从 0–0.03 em 起；短全大写标签约 0.04–0.08 em。','中文不拉成稀疏字阵；同一 HUD 行基线对齐。倒计时、百分号、连字符与省略号逐项检查。')])+cards([
('为何选 Oxanium','它的方折与开放字腔对应装甲切面，默认等宽数字更容易锁定计数布局。实际字形优先，不把“科幻感”交给难读的缺笔字和重描边。<a href="https://github.com/sevmeyer/oxanium">字体上游</a>。'),
('中文与回退','Noto Sans CJK SC 是明确的简体字形版本。游戏发布前按翻译目录、所有菜单和设备文字裁剪，并逐字检查；不把 macOS 系统回退当成 Web 已覆盖。现有 Glow Sans 也可保留，但新字需要重建子集。'),
('分发与版本','Oxanium、Noto Sans CJK SC 与现有 Rajdhani 的核查版本均附 OFL 1.1；保留作者、许可、来源与版本哈希。裁剪文件作为字体衍生文件管理，不宣称重新拥有原字体。许可全文随本 HTML 附在文末。'),
('跨端验收','测试 00:00、00:11、00:48、999、O2、中文菜单和最窄横屏。若关闭 pnum 后计时仍抖动，检查实际加载字体和回退，而不是继续调字距掩盖问题。')]))
ASSETS=[
('ENV-01','飞船主体 + 起落架','1 套 / 1','30–50k / 10–18k / 3–5k','2 个主要材质槽，2k 图集起步','M','C0/C1 剪影与落地关系'),
('ENV-02','气闸英雄模块','1 套 / 1','8–12k / 3–5k','共享建筑 trim + 局部标识','S','内框、门扇、平台三层深度'),
('ENV-03','直墙／窗墙／设备墙','3 类 / 约 12–18','每块 0.4–2k / 0.2–0.6k','建筑 trim，共享纹理','S','模数、UV 与接缝'),
('ENV-04','转角／端头／墙裙／压顶','4 类 / 按拼接','每块 0.2–1k','共享建筑材质','S','接口一致、背面封闭'),
('ENV-05','平台／坡道／扶手','3 类 / 两处坡道','每类 1–4k / 0.3–1k','共享结构材质','M','通行净空与承重支撑'),
('ENV-06','氧气分离塔','1 类 / 2','6–10k / 2–4k / 0.8k','设备 atlas + 标识','S','罐体、束环与基座'),
('ENV-07','横罐／热交换器','2 类 / 各 1–2','每类 3–6k / 1–2k','共享设备图集','M','管线接入与散热结构'),
('ENV-08','直管／弯管／法兰／阀组','4 类 / 按连接','每类 0.2–1.5k','共用管线材质','S','管径统一、连接不穿帮'),
('ENV-09','供电柜／维修柜／小泵','3 类 / 约 4–6','每类 0.8–3k / 0.3–1k','共享设备图集','S','中尺度面板与合理厚度'),
('ENV-10','太阳能阵列','1 类 / 1–2','3–6k / 1–2k','一套可重复面板纹理','S','支架与低反射侧景'),
('ENV-11','低掩体／货箱','2 类 / 约 6–8','每类 0.5–2k / 0.2–0.6k','道具 atlas','S','掩体高度与判定一致'),
('ENV-12','地形／石群／围边','3 类 / 组合','可见总量起点 20–40k','平铺地表与少量石材图集','M','地面安静、边界可读'),
('CHR-01','步枪机甲','1 套 / 共享实例','10–16k / 4–7k / 1.5–3k','2 个主要槽，2k 图集','L','命中、动作、头部可读'),
('CHR-02','突击机甲','1 套 / 共享实例','8–13k / 3–6k / 1.5–2.5k','与步枪机甲共享部分图集','L','比例区别与快速动作'),
('WPN-01','第一人称卡宾枪','1 套','15–25k；第三人称 3–6k','最多 2 个主要槽，2k 图集','L','瞄准线、握持、换弹挂点'),
('WPN-02','手套／袖口／投掷物','2 类 / 一套','手 5–8k；投掷物 0.8–1.5k','共用玩家材质','M','开镜／换弹／投掷不穿模'),
('INT-01','维护盖／空罐／工具箱','3 类 / 6–9 组候选','每类完整 + 残架约 0.4–1.5k','共享道具 atlas','M','独立命中、无伤害爆炸'),
('INT-02','接头／屏幕／危险组件','3 类 / 小量','每类约 0.3–1.5k','共用材质 + 状态','M','遮挡、过载与重开恢复'),
('FX-01','枪口／火花／壳片／月尘','4 类 / 共享池','短寿命批次，按可见量限制','小图集或原生几何','M','命中清晰、数量上限'),
('UI-01','HUD／字体／触控适配','1 套','不适用','Oxanium + 中文裁剪；SVG 图形','M','字形覆盖、横屏与减少动态效果')]
sec('assets','18','资产台账与工作拆分','三角形预算按导出、三角化后的结果统计；下表为起点，不能据此承诺 60 FPS。',table(['ID','资产组','种类／摆放量','LOD0 / LOD1 / LOD2（三角形）','材质／贴图','相对工作量','验收重点'],ASSETS)+note('S：已有规范下可重复制作；M：需要新结构或状态；L：涉及角色、武器或复杂绑定。它们不是承诺工期。先完成样板，再按实际耗时估算剩余工作。实例复用的数量不等于需要制作同数量的独立模型。'))
sec('budget','19','技术路径与性能预算','继续以 Godot 4.7.2 Compatibility / Web 为基线，视觉方案不能依赖桌面专用渲染。',table(['项目','初始约束／目标','如何验证'],[
('帧时间','目标 60 FPS；指定桌面场景暖机后 P95 ≤16.7 ms、P99 ≤33.3 ms 为初始门槛。','固定设备、分辨率、路线与敌人数，普通／45 秒切换／破坏密集区分别采样；首启和缓存热启分别报告，不隐藏首帧代价。'),
('绘制与几何','先控制代表性战斗机位可见三角形约 200–300k、draw calls 尽量 ≤300；超出先定位再决定调整。','引擎与 Web 统计口径一致；不能只加总去重资产面数。相机、敌人与阴影会改变实际开销。'),
('动态光源','1 盏主阴影光；重要局部无阴影光起点 ≤4 个，指示灯优先 emissive。','普通／狂暴不突增灯数；检查角色在灯池和阴影间的过渡。'),
('反射／透明','静态或一次更新探针起点 1–2 个；透明窗、喷散和能量层只在必要位置。','记录透明覆盖与 overdraw；不做全场 SSR、实时多视口镜面或原生体积雾依赖。'),
('纹理与显存','以共享 1k/2k 图集为主；单图新增 GPU 纹理预算起点 128–160 MiB，实际随格式与设备修订。','一张 2048² RGBA8 带完整 mip 约 21.3 MiB；PNG 文件小不代表 GPU 占用小。测实际压缩格式、mip 与驻留。'),
('模型与材质','重要静态件与两类机甲做 LOD；运行时碰撞保持简单、少量材质槽。','检查烘焙细分与应用 modifier 后的规模；不要把源模型面数当最终数。'),
('新小样下载','单图新增内容压缩后先以 ≤15 MB 为预算试点，需单独清点。','引擎 WASM 与现有九图资源另计；单图导出必须查依赖表。不得拿约 1.4 MB 的其他 HTML 游戏作为本工程保证值。'),
('状态切换','预载模型与共享效果；减少每帧节点创建，复用碎片批次。','记录 45 秒切换前后 P50/P95/P99、最大长帧与调用来源；不以平均 FPS 掩盖卡顿。'),
('手机与浏览器','桌面基准先用 Apple M5、1440×810；手机设备型号和横屏分辨率在样板验收时登记。','不得用桌面触控模式证明物理手机性能。记录浏览器、缩放、热状态、实际设备与画质档位。')])+note('这是预算草案，尚无月球小样实测。若画面不达标，先检查构图、形体和材料；若性能超标，优先查绘制、透明、阴影、重复材质和热路径，而非立即牺牲所有颜色与明暗层次。'))
REQ=[]
def req(id,p,role,title,deliver,accept,deps='—',section='brief'):
 REQ.append(dict(id=id,priority=p,role=role,title=title,deliverable=deliver,acceptance=accept,dependencies=deps,section=section,status='待实施'))
for row in [
('SYS-01','P0','玩法','小样入口与独立成绩','专用 session、入口与 score_moonbase_trial_v1。','新局可进入／重开；现有九图与成绩不被误覆盖。','—','baseline'),
('SYS-02','P0','玩法','保持一分钟规则','沿用计时、击杀、45 秒狂暴和截止结算。','自动测试覆盖重复死亡、截止后击杀、暂停、重开。','SYS-01','baseline'),
('LVL-01','P0','地编','完整灰盒环路','44×48 m 起始灰盒，含基地、飞船代理、氧气设备带和双坡道。','玩家实走、敌人导航、坡顶与边界无卡住；记录调整后的实际尺寸。','SYS-01','layout'),
('LVL-02','P0','地编','出生与补敌公平性','入口、遮挡与候选点数据；继承原并发攻击限制。','三局路线检查：近脸刷怪、长时间空跑、卡在入口均不可出现。','LVL-01','level-edit'),
('LVL-03','P0','地编','固定视觉对照点','C0/C1/C2 相机、统一 FOV 与普通／狂暴截图脚本。','改动可在同机位比较，截图保留版本与参数。','LVL-01','level-edit'),
('ART-01','P0','美术','色板与六种材料球','白壳、裸金属、橡胶、月壤、窗、能量环样板。','亮部有层次，暗部可读；对照概念图，关闭噪声和发光也成立。','LVL-03','materials'),
('ART-02','P0','美术','气闸角落垂直切片','门洞、墙角、地面、接头、灯与一组小物的完整样板。','C0、逆光、阴影三个状态可读；不用后期雾掩盖接缝和厚度。','ART-01','base-oxygen'),
('MOD-01','P0','建模','飞船原创剪影与落架','三套低模剪影评审后完成一套 GLB 与 .blend。','C0/C1 可辨飞船；落架接地；共享材质与 LOD 可导入。','ART-01','ship'),
('MOD-02','P0','建模','建筑模块套件','门、墙、角、端头、窗、压顶、平台与扶手。','对齐模数，进退台正确；替换灰盒后通路净宽不缩水。','ART-02','base-oxygen'),
('MOD-03','P0','建模','氧气工业套件','竖塔、横罐、交换器与管阀连接。','有支撑与真实接口；不穿门、不占跳跃净空；O2 不作为伤害标签。','ART-01','base-oxygen'),
('MOD-04','P0','建模','近景掩体与道具','共享货箱、盖板、工具箱和备用容器。','材质身份可辨；轮廓厚度正确；资产源与统计完整。','ART-01','assets'),
('MOD-05','P1','建模','太阳能与远景补充','阵列、远岩、维修侧景和低对比标识。','不抢主地标，不引入高反射闪点；预算内。','MOD-02','terrain'),
('CHR-01','P0','角色','步枪机甲模型与适配','命名、转轴或骨骼、材质、命中映射与 LOD。','8/15/20 m 头肩可读，现有头部判定和死亡逻辑有效。','ART-01','enemies'),
('CHR-02','P0','角色','突击机甲模型与适配','窄躯干、前倾轮廓与快速动作映射。','不只改色；冲近／规避行为与命中公平性沿用。','CHR-01','enemies'),
('CHR-03','P0','角色','完整敌人动作状态','移动、抬枪、射击、受击、死亡、爆头与重生。','无滑步与脱手枪；死亡后碰撞、头壳和重生状态正确恢复。','CHR-01, CHR-02','enemies'),
('WPN-01','P0','武器','第一人称卡宾枪与手套','GLB、挂点、瞄具坐标、双手与材质。','开镜对线；宽屏／横屏不遮目标；枪与手不穿模。','ART-01','weapon'),
('WPN-02','P0','武器','换弹与投掷状态','弹匣、20 发视觉状态、投掷物和音效挂点。','暂停、重开、取消与切换时不丢弹匣、不产生重复道具。','WPN-01','weapon'),
('INT-01','P0','互动','三类小物的完整状态','盖板、容器、接头；6–9 组候选摆放。','普通／狂暴、手雷遮挡、残架、复位和清场均通过。','MOD-04','destruction'),
('INT-02','P1','互动','额外设备局部损坏','显示屏、备用板、局部灯罩。','不会把主交战区照黑；无导航重烘焙与重复记分。','INT-01','destruction'),
('LGT-01','P0','光照','主光与静态接触方案','确定主光、环境补光、静态烘焙或 AO 样板。','白装甲不泛白，阴影机甲可读；动态门／盖板无残留固定阴影。','ART-02, LVL-03','light'),
('LGT-02','P0','光照','金属与窗的环境反射','受控环境与少量静态探针。','金属不成黑洞，玻璃不靠大雾；记录探针与透明成本。','LGT-01','light'),
('LGT-03','P0','光照','狂暴过载视觉','预载状态，局部警示灯、线圈与配套音色。','45 秒切换可读且无明显长帧；不把整场主色洗红。','LGT-01, WPN-01','vfx-audio'),
('FX-01','P0','特效','材质命中与击杀反馈','枪口、火花、壳片、尘粒与爆头机械反馈。','爆头、身体命中、普通物件、敌人死亡互相可区分。','CHR-03, INT-01','vfx-audio'),
('FX-02','P0','特效','效果上限与复用','共享小图集／MultiMesh 批次与数量限制。','持续扫射与手雷不会无限增长节点、透明覆盖和碎片。','FX-01','budget'),
('AUD-01','P0','音频','射击与敌人定位音','原型新音色、脚步、抬枪预警、材质撞击与回合音乐映射。','预警高于环境声；普通／狂暴层级清楚；暂停恢复不叠播放。','WPN-02, CHR-03','vfx-audio'),
('UI-01','P0','字体','确定数字与中文字族','Oxanium + Noto SC 样张、替代方案与字体许可。','十数字位宽、中文覆盖、O2 与低分辨率样张验收。','—','type'),
('UI-02','P0','字体','字体子集与字形清单','Godot 与 Web 对应裁剪、来源与哈希。','所有翻译、提示与标识无缺字；不依赖系统字体补漏。','UI-01','type'),
('UI-03','P0','界面','HUD 与菜单适配','时间／击杀／准星／情境弹药、暂停与设置。','无生命条、无无关常驻标签；999 击杀与最窄横屏不溢出。','UI-02, WPN-01','type'),
('UI-04','P0','界面','触控与减少动态效果','沿用输入桥与陀螺仪选项，重新检查手套和枪的占屏。','按钮可触达；触控区、准星、弹药与敌人不互挡。','UI-03','vfx-audio'),
('TECH-01','P0','技术','单图资源依赖审计','专用导出预设、资源目录与发布 manifest。','PCK 不夹带未使用的九图资源；来源与许可文件随包。','SYS-01, MOD-02','baseline'),
('TECH-02','P0','技术','渲染路径与热切换检查','Compatibility 可用功能清单，预载、材质与效果状态。','Web 无桌面专用效果依赖；45 秒切换无临时大批创建。','LGT-03, FX-02','budget'),
('TECH-03','P0','技术','预算采样与资源统计','CPU/GPU 或浏览器帧时间、draw calls、三角形、纹理、下载统计。','固定设备路线报告普通／狂暴／破坏密集区 P50/P95/P99 与长帧，未达目标明确列出。','TECH-02','budget'),
('QA-01','P0','验收','规则与重开回归','时间、击杀、爆头、手雷、暂停、重生与结算自动检查。','截止、重复命中、迟到事件与重开恢复通过；已有测试失败不能隐去。','SYS-02, INT-01','acceptance'),
('QA-02','P0','验收','美术与地编走查','三机位、四光照背景、三局移动实走与物件接触检查。','无悬空／嵌入、无假通路，机甲头肩可读；概念对照差异有记录。','LVL-02, CHR-03, LGT-03','acceptance'),
('QA-03','P0','验收','Web 真实交互验收','浏览器加载、FIRE、移动、射击、开镜、换弹、暂停、重开。','截图与日志证明实际运行；桌面触控与物理手机分别标注。','QA-01, QA-02, TECH-03','acceptance'),
('REL-01','P0','发布','不可变版本与回滚','经确认的发布范围、源提交、双站版本与旧版保留。','资源哈希、health、浏览器启动和直接链接齐全；能切回上一版。','QA-03','acceptance')]:req(*row)
sec('requirements','20','需求拆解：可筛选、可导出的工作清单','所有条目当前均为待实施；勾选仅代表本地评审标记，不改变工程状态。','''<div class="controls"><label>优先级<select id="priority"><option value="all">全部</option><option>P0</option><option>P1</option></select></label><label>工作域<select id="role"><option value="all">全部</option>'''+''.join('<option>'+h(r)+'</option>' for r in dict.fromkeys(x['role'] for x in REQ))+'''</select></label><label>检索<input id="req-search" type="search" placeholder="例如：气闸、字体、重开"></label><button id="export-json">导出需求 JSON</button><button id="reset-review">清除本地评审标记</button></div><p id="req-count" role="status"></p><div id="req-list"></div><p class="caption">P0 为可运行完整小样必需，P1 为核心通过后的补充。编号用于交接与验收；依赖链可以按实际实现拆分，但不能跳过先有灰盒、再验证样板的门禁。</p>''')
sec('milestones','21','制作阶段与门禁：先把一张关键画面做成立','用完成条件控制扩产，不按“全地图都铺上了新材质”判定进度。',table(['阶段','产物','前置／通过门槛','未通过时怎么处理'],[
('G0 需求与灰盒','SYS-01/02、LVL-01/02：一局可完成的灰盒。','60 秒、两类敌人、双坡道、完整环路与重开通过；记录实际交战距离。','先调路线与补敌，不用精美模型掩盖空跑和死角。'),
('G1 视觉样板','一个气闸角落 + 材料球 + C0 主光；六项关键代理：飞船、基地角、氧气单元、两类机甲、枪。','缩略图主次清楚、白壳有层次、暗部角色可见；所有关键资产能在 Godot 而非仅 Blender 视口显示。','返工形体、灯光或材料；先冻结一个成立的版本再扩展。'),
('G2 英雄资产与动作','近景枪、手、两类机甲、飞船与氧气塔的可交付资产。','瞄准、换弹、头部判定、动作和接地验证；LOD 与资源表齐全。','不要同时批量生成全场道具。先把难以复用的问题解决。'),
('G3 地图替换与互动','模块替换完整灰盒，加入 6–9 组小物与过载状态。','通路与射线仍成立；普通／狂暴／破坏／结尾／重开状态闭环。','按固定机位回退单个改动，区分布局问题与材质问题。'),
('G4 Web 性能与验收','单图导出、资源预算、浏览器和设备报告。','关键玩法、字体覆盖、错误日志和帧时间证据齐全；预算超出有明确取舍记录。','先处理绘制、透明、状态切换与资源依赖，避免全局去色或全图压暗。'),
('G5 发布与回滚','源提交、不可变版本、双站校验与可打开链接。','发布范围确定后执行；上一版保留、实际浏览器可进入并射击。','发布失败保持上一版可用，报告当前状态，不把构建成功当发布成功。')])+note('建议先完成 G0 与 G1 后重新估时。当前仅有概念图与原项目运行系统，缺少月球样板的制作耗时与实测设备数据，本案不承诺固定天数或“生成模型即可还原概念图”。'))
sec('acceptance','22','验收矩阵与风险处理','视觉、玩法和性能分别留证；任何单项通过都不能替代其余项。',table(['维度','必须看到的证据','返工触发'],[
('画面风格','C0/C1/C2 普通／狂暴原始截图；白壳、金属、月壤与设备发光可区分。','泛白、全局退灰、过度黑边、满场随机脏纹或所有材质同一种光泽。'),
('场景结构','正视、侧视、近景接触与实际走动；门洞、支柱、管道、落架有合理连接。','悬空支撑、物件嵌入、薄片穿帮、看似可走却撞空气墙。'),
('角色与武器','8/15/20 m 多背景目标图；开镜、换弹、命中与爆头片段。','头被肩甲埋住、只有眼灯可见、武器遮关键目标、枪线与瞄具不一致。'),
('字体与 HUD','内嵌样张与游戏导出样张，中文和数字覆盖记录；最窄横屏与 999 计数。','缺字、系统回退造成字形混杂、数字抖动、过细文字或无关常驻说明。'),
('互动','普通／狂暴／手雷／隔墙／重复命中／暂停／重开／结尾清场。','小杯子都爆炸、碎片无限增长、暂停继续倒、重开后缺部件或保留失效碰撞。'),
('完整回合','至少三局人工游玩与自动规则检查；输入、重生、截止、结算与再次开始。','卡路、缺敌、近脸刷怪、计时越界记分或新资产破坏旧逻辑。'),
('Web 与性能','版本 manifest、浏览器错误、实际交互、设备与分辨率、帧时间分布。','只有编辑器截图；用桌面代替手机结论；只报告平均 FPS 或隐去切换长帧。')])+cards([
('风险：概念图细节超预算','优先保留剪影、厚度、主光和材料身份。高频螺栓、裂痕和远侧机械简化；不先削掉主要颜色与白壳面间关系。'),
('风险：机械模型漂亮但不能动','先验转轴、命名、命中与挂点再细化。首版有可靠分件动画即可，不强行同时引入新骨骼系统。'),
('风险：月面灰导致整体沉闷','用低饱和地面托住白壳与橙色；靠光区和地标组织层次。不要给地面全面加湿反射、霓虹或漂雾。'),
('风险：新项目范围膨胀','维持单图、一枪、两类敌人、一局。飞船是地标，氧气是环境设施；驾驶与生存系统不进入本轮。')])+'''<p>立项前仍需确定：首批物理手机验收设备；是否要求独立下载的单图演示；主标题与中文命名；样板完成后可接受的美术工作量。以上未定项不妨碍先按本案完成灰盒与视觉样板。</p>''')
sec('sources','23','依据、许可与文档使用','资料核查日期：2026-11-13；引用的技术能力不等于项目实测结果。',table(['来源','用途／边界'],[
('<a href="https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html">Godot 4.7：渲染器比较</a>','核对 Web Compatibility 与效果边界；本文只摘取小样相关功能。'),
('<a href="https://docs.godotengine.org/en/4.7/classes/class_lightmapgi.html">Godot 4.7：LightmapGI</a>','烘焙、静态几何、UV2 与设备要求。样板仍需验证实际光照与动态部件。'),
('<a href="https://github.com/sevmeyer/oxanium">Oxanium 上游</a> / <a href="https://raw.githubusercontent.com/google/fonts/main/ofl/oxanium/OFL.txt">OFL 许可</a>','数字与短英文主方案；本次检查字体实际度量并提供试排子集。'),
('<a href="https://github.com/notofonts/noto-cjk/blob/main/Sans/README.md">Noto Sans CJK 格式说明</a> / <a href="https://github.com/notofonts/noto-cjk/blob/main/Sans/LICENSE">许可</a>','简体中文字族方案；内嵌的是本报告需要的 SC Medium 字符子集。'),
('本项目 scripts/run_rules.gd / game.gd / player.gd / enemy.gd','核对回合、弹匣、移动、命中与视觉适配入口，基线 73f0968。'),
('本项目 assets/fonts/README.md 与字体文件','核对现有 Rajdhani 与 Glow Sans、许可与裁剪流程。Rajdhani 数字宽度与 Oxanium 的对照来自本次字体表检查。'),
('docs/art/moonbase-concepts-2026-11-13/ 三张图','由 imagegen 基于用户风格参考生成。不是实机截图、生产模型或授权可复用三维资源。'),
('本案所有布局、预算与生产规范','属于设计提案；没有把经验范围表述为引擎官方要求，也没有将未实施条目标记为完成。')])+'''<details class="licenses"><summary>查看内嵌字体许可全文</summary>@@LICENSES@@</details><p class="caption">本 HTML 内嵌三张概念图、字体、样式、示意图与脚本，可离线打开；来源链接仅在点击时需要联网。图中美术观察点与路线图均为文档注释，不修改原图。评审标记只在当前浏览器本地保存。</p>''')
CSS=r'''
:root{--ink:#202e3c;--muted:#586776;--paper:#f6f4ee;--line:#d8ddd9;--orange:#c24f2f;--cyan:#9bd6dd;--nav:#122130;--font-ui:NotoPlan,"PingFang SC","Microsoft YaHei",sans-serif}*{box-sizing:border-box}html{scroll-behavior:auto;scroll-padding-top:24px}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.85 var(--font-ui);font-synthesis:none}a{color:#9b3e25;text-underline-offset:4px}button,input,select{font:inherit}button,select,input[type=search]{background:#fff;color:var(--ink);border:1px solid #a4b1b8;border-radius:5px;padding:8px 12px}button{cursor:pointer}button:hover{border-color:var(--orange)}button:focus-visible,input:focus-visible,select:focus-visible,a:focus-visible,.zone:focus-visible{outline:3px solid #d57332;outline-offset:4px}input[type=checkbox]{accent-color:var(--orange);width:17px;height:17px;vertical-align:middle}input[type=range]{width:130px;accent-color:var(--orange)}aside.nav{position:fixed;inset:0 auto 0 0;width:240px;background:var(--nav);color:#d8e0e4;padding:27px 22px;overflow:auto;z-index:5}.brand{font:700 29px/1.1 Oxanium,sans-serif;letter-spacing:.03em;color:#fff}.brand small{display:block;font:500 11px/2 var(--font-ui);color:#9aadb9;letter-spacing:.16em}.nav-rule{height:3px;width:42px;background:#e57743;margin:24px 0}.nav-title{font-size:12px;color:#95adb7}.nav nav{display:flex;flex-direction:column;margin:12px 0 24px;gap:4px}.nav nav a{display:flex;gap:11px;align-items:baseline;color:#cfdae0;text-decoration:none;font-size:12px;line-height:1.7;padding:5px 8px;border-left:2px solid transparent}.nav nav a span{font-family:Oxanium,sans-serif;color:#7f9aa8;font-size:11px}.nav nav a.active{border-color:#e57743;background:#22384a;color:#fff}.nav-bottom{font-size:11px;color:#a2b4be;border-top:1px solid #385062;padding-top:14px}.nav-bottom p{margin:5px 0}.nav-bottom progress{display:block;width:100%;height:5px;accent-color:#e9824d;margin:9px 0}main{margin-left:240px;padding:40px clamp(24px,4vw,72px) 60px;max-width:1600px}.page-header{border-bottom:1px solid #bdc8ca;padding-bottom:24px}.eyebrow{font:600 13px/1.4 Oxanium,sans-serif;letter-spacing:.12em;color:var(--orange)}h1{font-size:clamp(31px,3.4vw,50px);line-height:1.35;letter-spacing:-.03em;margin:16px 0;color:#192b3a}.subhead{max-width:840px;font-size:18px;color:#4b5c66;line-height:1.8}.meta{display:flex;gap:10px;flex-wrap:wrap;margin:20px 0}.meta span{font-size:12px;border:1px solid #bdc8ca;padding:4px 10px;border-radius:3px}.actions{display:flex;gap:10px;flex-wrap:wrap;margin-top:20px}.actions button.primary{background:#21394b;color:#fff;border-color:#21394b}.hero{margin:28px 0 0}.hero img,figure img{display:block;width:100%;height:auto;border-radius:5px}figure{margin:22px 0}figcaption,.caption{font-size:12px;line-height:1.8;color:var(--muted);margin-top:10px}section{padding-top:52px;margin-top:8px;border-bottom:1px solid var(--line);padding-bottom:36px;scroll-margin-top:20px}.section-head{display:flex;gap:16px;align-items:baseline}.sec-no{font:500 25px Oxanium,sans-serif;color:#c56b48}.section-head h2{font-size:27px;line-height:1.55;margin:0;color:#223748}p.lead{color:var(--muted);margin:10px 0 23px;font-size:16px}h3{font-size:17px;line-height:1.65;margin:0 0 9px}p{margin:12px 0}b,strong{color:#243747}.cards{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}.card{border:1px solid #cbd4d3;border-radius:5px;padding:22px;background:#fdfbf7}.card p{font-size:14px;color:#4f606b;margin:0}.card a{display:inline}.note{background:#e8efed;border-left:4px solid #487581;padding:17px 21px;font-size:14px;line-height:1.9;margin:24px 0}.table-wrap{max-width:100%;overflow:auto;border:1px solid #c8d2d2;border-radius:5px;margin:22px 0}table{border-collapse:collapse;width:100%;font-size:13px;line-height:1.9;min-width:750px}th{text-align:left;vertical-align:top;background:#e0e7e5;color:#213b48;font-size:12px;letter-spacing:.02em}td,th{padding:13px 15px;border-bottom:1px solid #d7dfdd;min-width:120px}td{vertical-align:top}tbody tr:last-child td{border-bottom:0}td:first-child{font-weight:500;min-width:130px}tr:hover td{background:#f0f2eb}code{font-size:12px;background:#e6ebe9;border-radius:3px;padding:2px 5px;overflow-wrap:anywhere}.swatches{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:13px}.swatches>div{background:white;border:1px solid #d0d8d5;border-radius:4px;overflow:hidden}.swatches span{display:block;height:55px;background:var(--sw);border-bottom:1px solid #e6e6e2}.swatches b,.swatches code,.swatches p{display:block;margin:8px 13px}.swatches b{font-size:14px}.swatches code{font-family:Oxanium,sans-serif;background:none;padding:0}.swatches p{font-size:12px;color:var(--muted)}.annotated{position:relative}.pins{position:absolute;inset:0}.pin{position:absolute;transform:translate(-50%,-50%);display:grid;place-items:center;width:29px;height:29px;background:#edc295;color:#1b2b35;border:2px solid #172f42;border-radius:50%;font:700 14px Oxanium,sans-serif;text-decoration:none;box-shadow:0 1px 5px #0006}.map-tools,.controls{display:flex;gap:14px;align-items:center;flex-wrap:wrap;margin:16px 0}.controls label{display:flex;gap:8px;align-items:center;font-size:13px;flex-wrap:wrap}.controls input[type=search]{min-width:180px}.map-tools label{font-size:14px}.map-grid{display:grid;grid-template-columns:minmax(0,1.6fr) minmax(240px,1fr);gap:20px;align-items:start}.map-grid figure{margin:0}.map-svg{display:block;width:100%;height:auto;border-radius:5px}.map-svg text{font-family:var(--font-ui);font-size:13px;fill:#f5ede1;text-anchor:middle;dominant-baseline:middle;pointer-events:none}.map-svg .dim{font-size:12px;fill:#b2c1cc}.zone{cursor:pointer}.zone rect{stroke:#94abbc;stroke-width:1.5;transition:stroke-width .15s}.zone:hover rect,.zone:focus rect{stroke:#edb77f;stroke-width:3}.zone.base rect{fill:#5a6875}.zone.pad rect{fill:#294654}.zone.oxygen rect{fill:#405a57}.map-layer.hidden{display:none}.type-lab{padding:20px;border:1px solid #cbd4d3;border-radius:5px;background:#eef1ed}.hud-preview{height:275px;position:relative;background:linear-gradient(115deg,#152633,#2b3c4c);color:#f7f4ed;border-radius:4px;overflow:hidden;font-family:Oxanium,var(--font-ui);font-weight:700;--number-size:52px;font-feature-settings:"pnum" 0}.hud-preview.light{background:linear-gradient(115deg,#c8c7bd,#9a9e9c);color:#172c3b}.hud-top{display:flex;gap:20px;align-items:center;justify-content:center;padding-top:20px;line-height:1.3;font-size:var(--number-size);white-space:nowrap}.hud-top small{font:500 18px var(--font-ui);align-self:center}.hud-top i{width:2px;height:.75em;background:#e5794a}.preview-cross{width:28px;height:28px;position:absolute;left:calc(50% - 14px);top:calc(55% - 14px)}.preview-cross svg{width:100%;height:100%;stroke:currentColor;stroke-width:1.5;fill:none}.preview-bottom{position:absolute;left:20px;right:20px;bottom:17px;display:flex;justify-content:space-between;align-items:center;font:500 13px var(--font-ui)}.preview-ammo{font:600 26px Oxanium,sans-serif}.glyphs{display:flex;flex-direction:column;gap:13px;padding:18px 2px;font-size:16px;overflow-wrap:anywhere}.glyphs .ox{font:600 21px/1.8 Oxanium,sans-serif}.glyphs .raj{font:700 24px/1.8 Rajdhani,sans-serif}.req-card{border:1px solid #ccd7d4;border-left:4px solid #497078;background:#fcfbf6;padding:16px 18px;margin:12px 0;border-radius:4px}.req-card[data-priority=P1]{border-left-color:#b29876}.req-top{display:flex;gap:10px;align-items:center;flex-wrap:wrap}.req-top h3{flex:1;min-width:160px;font-size:16px;margin:0}.req-top label{font-size:12px;color:#546671;white-space:nowrap}.req-id{font:600 13px Oxanium,sans-serif;color:#9b4a2f}.tag{font-size:11px;border:1px solid #cad3d2;padding:1px 6px;border-radius:3px;color:#556772}.req-body{font-size:13px;color:#50616b;line-height:1.9}.req-body p{margin:7px 0}.req-foot{display:flex;gap:12px;flex-wrap:wrap;font-size:11px;color:#697982}#req-count{font-size:13px;color:#4c6870}details{border:1px solid #cbd4d3;background:#fcfbf7;border-radius:4px;padding:15px 18px;margin:16px 0}summary{cursor:pointer;font-size:14px;color:#294956}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:11px;line-height:1.65;max-height:360px;overflow:auto;padding:16px;background:#edf0eb}.footer{font-size:12px;color:#667781;margin:28px 0 0}.status-toast{position:fixed;right:20px;bottom:20px;background:#173849;color:#fff;padding:12px 18px;border-radius:4px;z-index:10;font-size:13px}.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}@media(max-width:1100px){aside.nav{width:205px;padding:24px 15px}main{margin-left:205px;padding:28px 25px}.map-grid{grid-template-columns:1fr}.map-grid .card{min-height:0}}@media(max-width:760px){aside.nav{position:relative;width:100%;padding:20px}.nav-rule,.nav-title,.nav-bottom{display:none}.brand{font-size:23px}.nav nav{flex-direction:row;overflow:auto;gap:8px;margin:18px 0 0;padding-bottom:3px}.nav nav a{flex-shrink:0;max-width:150px;font-size:11px;line-height:1.5;border:1px solid #365064;padding:7px}.nav nav a span{display:none}main{margin:0;padding:24px 18px}.cards{grid-template-columns:1fr}.swatches{grid-template-columns:repeat(2,minmax(0,1fr))}.section-head{gap:12px}.section-head h2{font-size:23px}.sec-no{font-size:20px}h1{font-size:32px}.subhead{font-size:16px}.hud-top{gap:13px;font-size:min(var(--number-size),48px)}.hud-top small{font-size:14px}.type-lab{padding:12px}.controls{gap:10px}.controls label{width:100%}.req-top label{width:100%;margin-top:5px}.pin{width:23px;height:23px;font-size:11px}.table-wrap{margin-left:0}.actions button{font-size:13px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}.zone rect{transition:none}}@media print{aside.nav,.actions,.controls,.map-tools,.pins,.status-toast{display:none!important}main{margin:0;padding:0;max-width:none}body{background:white;font-size:10pt;color:#111}section{padding-top:18px;margin-top:10px;break-inside:auto}.section-head h2{font-size:18pt}.cards{grid-template-columns:1fr 1fr}figure{break-inside:avoid}table{min-width:0;font-size:8pt}td,th{min-width:0;padding:7px}.table-wrap{overflow:visible}details pre{max-height:none;overflow:visible}.req-card{break-inside:avoid}.hero{break-before:avoid}a{color:#222}.map-grid{grid-template-columns:1fr}.caption{font-size:8pt}.hud-preview{-webkit-print-color-adjust:exact;print-color-adjust:exact}}
'''
JS=r'''
const requirements=@@REQ@@;
const $=id=>document.getElementById(id);
const escapeHtml=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const reviewKey='moonbase-production-plan-review-v1';let reviewed={};
try{reviewed=JSON.parse(localStorage.getItem(reviewKey)||'{}');if(!reviewed||typeof reviewed!=='object')reviewed={};}catch{reviewed={};}
function updateProgress(){const count=requirements.filter(r=>reviewed[r.id]===true).length;$('review-progress').value=count;$('review-progress').max=requirements.length;$('review-count').textContent=`${count} / ${requirements.length} 项已标记评审`;}
function renderRequirements(){const p=$('priority').value,role=$('role').value,q=$('req-search').value.trim().toLowerCase();const rows=requirements.filter(r=>(p==='all'||r.priority===p)&&(role==='all'||r.role===role)&&Object.values(r).join(' ').toLowerCase().includes(q));$('req-count').textContent=`显示 ${rows.length} / ${requirements.length} 项；全部处于待实施状态。`;const fragment=document.createDocumentFragment();for(const r of rows){const el=document.createElement('article');el.className='req-card';el.dataset.priority=r.priority;el.innerHTML=`<div class="req-top"><span class="req-id">${escapeHtml(r.id)}</span><h3>${escapeHtml(r.title)}</h3><span class="tag">${escapeHtml(r.priority)}</span><span class="tag">${escapeHtml(r.role)}</span><label><input type="checkbox" data-review="${escapeHtml(r.id)}" ${reviewed[r.id]===true?'checked':''}>评审标记</label></div><div class="req-body"><p><b>交付：</b>${escapeHtml(r.deliverable)}</p><p><b>验收：</b>${escapeHtml(r.acceptance)}</p></div><div class="req-foot"><span>依赖：${escapeHtml(r.dependencies)}</span><span>状态：待实施</span><a href="#${escapeHtml(r.section)}">查看规范</a></div>`;fragment.append(el);}$('req-list').replaceChildren(fragment);updateProgress();}
for(const id of ['priority','role'])$(id).addEventListener('change',renderRequirements);$('req-search').addEventListener('input',renderRequirements);
$('req-list').addEventListener('change',e=>{const id=e.target.dataset.review;if(!id)return;reviewed[id]=e.target.checked;try{localStorage.setItem(reviewKey,JSON.stringify(reviewed));}catch{}updateProgress();});
$('reset-review').addEventListener('click',()=>{reviewed={};try{localStorage.removeItem(reviewKey);}catch{}renderRequirements();});
function download(name,data,type){const a=document.createElement('a'),url=URL.createObjectURL(new Blob([data],{type}));a.href=url;a.download=name;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);}
$('export-json').addEventListener('click',()=>download('moonbase-requirements-v1.json',JSON.stringify({title:'月球基地一分钟射击制作策划案',version:'1.0',date:'2026-11-13',sourceCommit:'73f0968',status:'proposal',requirements:requirements.map(r=>({...r,reviewed:reviewed[r.id]===true}))},null,2),'application/json;charset=utf-8'));
$('export-top').addEventListener('click',()=>$('export-json').click());$('print-plan').addEventListener('click',()=>window.print());
let previousDetails=[];window.addEventListener('beforeprint',()=>{previousDetails=[...document.querySelectorAll('details')].map(d=>[d,d.open]);for(const [d]of previousDetails)d.open=true;});window.addEventListener('afterprint',()=>{for(const [d,open]of previousDetails)d.open=open;});
const zoneText={base:['基地气闸 / 高台','北侧作为主方向锚点，南侧进入即可看见橙色气闸。高台只覆盖部分场地，两条坡道允许敌人接近；平台下先封闭，不暗示可穿行。'],pad:['飞船停机坪','西侧提供大轮廓和侧向遮挡。沿停机坪边缘保留通路，起落架与电缆不变成玩家胶囊难以判断的小缝；飞船不提供驾驶或上机翼捷径。'],oxygen:['氧气 / 工业区','东侧用竖塔、横罐和管阀形成辨识。设备带与中央之间留清楚的维修侧路，保留通行净空；氧气设施不自动赋予氧气管理或爆炸玩法。']};
for(const el of document.querySelectorAll('[data-zone]')){const show=()=>{const t=zoneText[el.dataset.zone];$('zone-info').replaceChildren();const title=document.createElement('h3'),p=document.createElement('p');title.textContent=t[0];p.textContent=t[1];$('zone-info').append(title,p);};el.addEventListener('click',show);el.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();show();}});}
for(const input of document.querySelectorAll('[data-toggle]'))input.addEventListener('change',()=>document.querySelector(`[data-layer="${input.dataset.toggle}"]`).classList.toggle('hidden',!input.checked));
function typePreview(){const font=$('font-choice').value;$('hud-preview').style.fontFamily=`${font},NotoPlan,sans-serif`;$('hud-preview').style.fontFeatureSettings=`"pnum" 0, "zero" ${$('slash-zero').checked?1:0}`;$('hud-preview').style.setProperty('--number-size',$('font-size').value+'px');$('font-size-value').value=$('font-size').value+' px';$('hud-preview').classList.toggle('light',$('font-bg').value==='light');}
for(const id of ['font-choice','font-size','slash-zero','font-bg'])$(id).addEventListener('input',typePreview);
if('IntersectionObserver'in window){const observer=new IntersectionObserver(entries=>{for(const e of entries)if(e.isIntersecting){for(const a of document.querySelectorAll('.nav nav a'))a.classList.toggle('active',a.hash==='#'+e.target.id);}},{rootMargin:'-10% 0px -68% 0px'});for(const s of document.querySelectorAll('section'))observer.observe(s);}
renderRequirements();typePreview();
'''

# Inline only the glyphs needed by this document. Source fonts stay in ignored local artifacts.
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
text=Path(__file__).read_text()+json.dumps(REQ,ensure_ascii=False)
codepoints={ord(c) for c in text}|set(range(32,127))
fontstats=[]
for name,source,weight in [('Oxanium',ROOT/'artifacts/local/moonbase-plan/Oxanium.ttf',700),('NotoPlan',ROOT/'artifacts/local/moonbase-plan/NotoSansCJKsc-Medium.otf',None)]:
 font=TTFont(source)
 if weight is not None:font=instantiateVariableFont(font,{'wght':weight},inplace=False)
 cmap=font.getBestCmap();options=subset.Options();options.name_IDs=['*'];options.flavor='woff2'
 sub=subset.Subsetter(options=options);sub.populate(unicodes=codepoints&set(cmap));sub.subset(font);font.flavor='woff2';font.save(OUT/'fonts'/f'{name}.woff2')
 fontstats.append({'family':name,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'glyphs':len(font.getBestCmap()),'woff2_bytes':(OUT/'fonts'/f'{name}.woff2').stat().st_size})
 if name=='NotoPlan':
  missing=[c for c in codepoints if 0x4e00<=c<=0x9fff and c not in cmap]
  assert not missing,missing
fontcss=''
for family,path,weight in [('Oxanium',OUT/'fonts/Oxanium.woff2',700),('NotoPlan',OUT/'fonts/NotoPlan.woff2',500),('Rajdhani',ROOT/'web/Rajdhani-Bold.woff2',700)]:
 fontcss+=f'@font-face{{font-family:{family};src:url(data:font/woff2;base64,{base64.b64encode(path.read_bytes()).decode()}) format("woff2");font-weight:{weight};font-display:swap;}}\n'
licenses=''
for title,path in [('Oxanium',OUT/'fonts/Oxanium-OFL.txt'),('Noto Sans CJK SC',OUT/'fonts/NotoSansCJK-OFL.txt'),('Rajdhani',ROOT/'assets/fonts/OFL.txt')]:licenses+='<h3>'+h(title)+'</h3><pre>'+h('\n'.join(line.rstrip() for line in path.read_text().splitlines()))+'</pre>'
nav=''.join(f'<a href="#{s["id"]}"><span>{s["n"]}</span>{h(s["title"].split("：")[0])}</a>' for s in S)
sections=''.join(f'<section id="{s["id"]}" aria-labelledby="heading-{s["id"]}"><div class="section-head"><span class="sec-no">{s["n"]}</span><h2 id="heading-{s["id"]}">{h(s["title"])}</h2></div><p class="lead">{h(s["lead"])}</p>{s["body"]}</section>' for s in S)
page='''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="description" content="月球基地一分钟射击小样的完整制作策划案：需求拆解、美术、建模、地编、字体、技术预算与验收。"><title>月球基地一分钟射击 · 制作策划案</title><style>@@FONTS@@\n@@CSS@@</style></head><body><aside class="nav"><div class="brand">MOONBASE / 60<small>视觉与制作规划 · V1.0</small></div><div class="nav-rule"></div><div class="nav-title">23 个章节 / 从概念到可玩小样</div><nav aria-label="策划案目录">@@NAV@@</nav><div class="nav-bottom"><p>评审标记，仅保存在本地</p><progress id="review-progress" value="0" max="36" aria-label="本地评审标记进度"></progress><p id="review-count">0 项已标记</p><p>全部需求：待实施</p><p>2026-11-13 / 基线 73f0968</p></div></aside><main><header class="page-header"><div class="eyebrow">ART DIRECTION / LEVEL DESIGN / PRODUCTION PLAN</div><h1>月球基地<br>一分钟射击制作策划案</h1><p class="subhead">保留已经成立的射击节奏，用飞船、基地与工业机甲建立一个完整的小世界。把参考图里的材质、重量和光照，拆成可制作、可检查、可交接的具体要求。</p><div class="meta"><span>一张地图</span><span>60 秒回合</span><span>两类敌人</span><span>Godot 4.7.2 / Web</span><span>视觉提案，尚未实施</span></div><div class="actions"><button class="primary" id="export-top">导出需求 JSON</button><button id="print-plan">打印 / 保存 PDF</button><a href="#requirements">查看需求清单</a></div><figure class="hero"><img src="@@IMG1@@" alt="月球基地第一人称 AI 概念图：左侧飞船、右侧基地、氧气塔、两类机甲与玩家枪械"><figcaption>视觉目标参考 / AI 生成概念图；不是游戏截图。本文尺寸、预算与参数均为制作起点，须经灰盒、样板与 Web 实测确认。</figcaption></figure></header>@@SECTIONS@@<footer class="footer">单文件离线版 / 需求与美术制作提案 v1.0 / 本文未修改游戏运行时代码。原始概念图、生成器、字体许可与需求数据随项目保存。</footer></main><script>@@JS@@</script></body></html>'''
for token,value in [('@@FONTS@@',fontcss),('@@CSS@@',CSS),('@@NAV@@',nav),('@@SECTIONS@@',sections),('@@LICENSES@@',licenses),('@@JS@@',JS.replace('@@REQ@@',json.dumps(REQ,ensure_ascii=False)))]:page=page.replace(token,value)
images=[]
for i,filename in enumerate(['01-gameplay.png','02-map-overview.png','03-mechs-and-weapons.png'],1):
 source=ROOT/'docs/art/moonbase-concepts-2026-11-13'/filename;blob=source.read_bytes();page=page.replace(f'@@IMG{i}@@','data:image/png;base64,'+base64.b64encode(blob).decode());images.append({'name':filename,'sha256':hashlib.sha256(blob).hexdigest(),'bytes':len(blob)})
assert not re.findall(r'@@\w+@@',page)
(OUT/'index.html').write_text(page)
(OUT/'requirements.json').write_text(json.dumps({'version':'1.0','date':'2026-11-13','baseline':'73f0968','status':'proposal','requirements':REQ},ensure_ascii=False,indent=2)+'\n')
(OUT/'build-info.json').write_text(json.dumps({'sections':len(S),'requirements':len(REQ),'fonts':fontstats,'images':images,'html_bytes':len(page.encode()),'self_contained':True},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'sections':len(S),'requirements':len(REQ),'html_bytes':len(page.encode()),'fonts':fontstats},ensure_ascii=False))
