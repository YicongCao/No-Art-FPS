"""Build an offline construction handbook from the shared proxy catalog."""
from pathlib import Path
import base64,json,html,hashlib,re
from build_kit import PARTS,ASSEMBLIES,COLORS
OUT=Path(__file__).resolve().parent;PLAN=OUT.parent;ROOT=PLAN.parents[2]
def h(s):return html.escape(str(s))
def table(head,rows):return '<div class="table-wrap"><table><thead><tr>'+''.join('<th>'+h(x)+'</th>' for x in head)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+str(c)+'</td>' for c in row)+'</tr>' for row in rows)+'</tbody></table></div>'
def image(path):return 'data:image/'+('svg+xml' if path.suffix=='.svg' else 'png')+';base64,'+base64.b64encode(path.read_bytes()).decode()
def note(s):return '<div class="note">'+s+'</div>'
S=[]
def section(i,title,lead,body):S.append({'id':i,'title':title,'lead':lead,'body':body})
concept=ROOT/'docs/art/moonbase-concepts-2026-11-13/02-map-overview.png'
coverage=[
('01','飞船与停机坪','画面左侧大飞船、落架、挂载、橙环停机坪','A01 / A11','S01–S08、P05、P10','角色不能钻进翼根小缝；腹部封闭，保留坪边连续侧路。'),
('02','基地外壳','后排双层主楼、气闸、观察窗、侧楼和屋顶','A02','B01–B09、B04/B05','室外立面完整；窗后仅暗箱，门后封闭，无室内房间。'),
('03','室外平台与双坡','中央入口前高台、两侧平台、黄色栏杆','A02','B07–B11','双坡均可上；平台下封闭；立柱落地，扶手不挤窄通路。'),
('04','天线通信','楼顶碟面、分节天线和控制盒','A06','P06、P07、B08、I09','屋顶主碟偏左，与工业双塔避开主轮廓重叠。'),
('05','氧气工业双塔','右侧两塔、顶端连管、台架和检修栏杆','A03','I01–I03、I05–I09、P09','塔脚有基座，管口有法兰；检修面朝路。'),
('06','横罐与散热供电','双塔前横罐、右后鳍片设备、电柜','A04','I01/I02/I04、I07–I10','大横圆与直塔形成对比；不能遍地发光圈。'),
('07','太阳能阵列','画面右上倾斜蓝色板面、支架','A07','P08、P09、I09','保持侧景与低反射，不变成跳跃捷径。'),
('08','发生器与卷管站','前景中央机壳、机械芯、橙黑卷盘、两只罐','A05','I11/I12、P02/P12','支管局限在设备岛，离开主通路与出生视线。'),
('09','货箱与便携物','左前堆箱、散落小箱、立罐、维护盖','A08','P01/P02/P12','3 档箱体参数而非任意缩放；短罐与高罐共享旋转体。'),
('10','交战掩体','中央前后错位矮障碍、短墙、边缘工具箱','A09','P03、P01、P05','高度 0.9–1.2 m；碎片不改变主遮挡，不串成整堵墙。'),
('11','外围墙与崖边','前后外圈矮墙、端柱灯、山岩围边','A10','P04/P05/P11','可跨越的矮墙后需可见岩崖实体，视觉与通行边界一致。'),
('12','道路与管线细物','路灯、地标、维修气管、电缆、路面磨耗','A11 / A12','P05/P10、I05–I08/I12','共面标识入图集；软管不形成细碎碰撞网。')]
section('scope','01 / 全景物件清点与范围','复杂物体拆成总装配方，基础构件拆到能独立复用、定义接口、生成五视图的粒度。',table(['编号','总装对象','概念图可见内容','总装','构件','地编责任'],coverage)+note('43 类基础构件、12 组总装方案，共 215 幅正投影视图，另附 43 幅轴测辅助图。背面和被遮挡部分是本案补充设计，不是从 AI 图中测量还原。敌人与手持武器沿用原案专章，本册聚焦环境；所有基地室内、室内家具、室内导航与开门探索均不进入首版。'))
section('hierarchy','02 / 两层复用，而不是所有东西拆成小盒子','内核负责形状族，构件负责功能与接口，总装负责用途和摆放。',table(['层级','内容','输入／输出','何时复用'],[
('几何内核','BevelBox、ProfileExtrude、SectionLoft、Lathe、CurveTube、Array、RockProfile','轮廓/截面/路径 → 网格面、局部坐标、法线与材质区域','箱体、墙板共用 BevelBox；罐、喷口、卷盘共用 Lathe。'),
('构件族','43 个设计编号，约 16 个生产生成器家族','尺寸/结构/材质参数 → 网格、端口、碰撞代理、UV 与 LOD','同一家族可产生多种尺寸；保留强约束，不任意全参数笛卡尔积。'),
('总装配方','A01–A12：飞船、外立面、双塔、横罐等','构件 ID + 端口连接 + 局部变换 → 用途完整的模型组','氧气塔和横罐共享罐体但支座不同；不将整座工厂作为一个无法改动的 GLB。'),
('场地布局','44×48 m 灰盒、路线、出生、标识与固定机位','总装落点与碰撞 → 可玩的月球小样','布局由地编明确设计，不用随机种子重新随机出生点和掩体高度。')])+note('本轮已实现图纸用几何代理与 SVG 投影脚本；生产级 Blender 生成器、真实 UV/烘焙、GLB、碰撞与 Godot 接入仍待实施。图册中的参数范围是生产合同，不代表预览脚本已支持这些参数的全部组合。'))
# Embeddable annotated overview, without touching source image.
pins=[(1,24,43),(2,50,24),(3,53,36),(4,45,8),(5,78,31),(6,86,48),(7,88,23),(8,58,76),(9,28,77),(10,51,50),(11,25,91),(12,40,66)]
fig='<div class="overview"><img src="'+image(concept)+'" alt="月球基地全景概念图：覆盖十二个环境物件区域">'+''.join(f'<a href="#coverage-{n}" style="left:{x}%;top:{y}%" aria-label="查看第{n}区">{n:02}</a>' for n,x,y in pins)+'</div><p class="caption">图上编号对应物件清点；不是碰撞或施工图。</p>'
fig+=''.join(f'<article class="coverage" id="coverage-{int(row[0])}"><b>{row[0]} / {row[1]}</b><p>{row[2]}；{row[3]}，构件 {row[4]}。{row[5]}</p></article>' for row in coverage)
section('overview','03 / 概念图与总装覆盖','先核对画面里有什么，再安排它们服务哪条路、哪个观察距离。',fig)
# Asset assembly gallery.
asbody='<div class="assembly-grid">'
for a in ASSEMBLIES:
 counts={}
 for r in a['bom']:counts[r['part']]=counts.get(r['part'],0)+1
 asbody+=f'<article id="{a["id"]}" class="assembly"><h3>{a["id"]} / {a["name"]}</h3><img loading="lazy" src="{image(OUT/"assemblies"/(a["id"]+".svg"))}" alt="{a["name"]}总装与构件编号图"><p>{a["description"]}</p><p><b>布局：</b>世界落点起点 {a["placement"]} m。{a["collision"]}</p><p class="bom">'+', '.join(f'<a href="#part-{pid}">{pid} × {n}</a>' for pid,n in counts.items())+'</p></article>'
asbody+='</div>'+note('总装图表达拆件与空间关系，局部缩比只用于构图代理；生产版应以参数重建，不能用非均匀缩放破坏倒角宽度、管径和纹理密度。端口、密封面、支撑接触必须在样板中逐一闭合，图中未画出的背墙和端盖不代表最终可省。')
section('assemblies','04 / 十二组总装与构件清单','每个总装有可追溯的基础构件；点构件编号即可进入其五视图。',asbody)
section('level','05 / 地编落位、净空与装配顺序','世界原点为交战区中心，X 向东、Z 向南；所有坐标是待灰盒验证的起点。',table(['区域','落位与包络起点','必须保留的空间','装配与检查'],[
('西侧停机坪','中心约 (-12.5,0,-1)；飞船目标宽 X≈11 m、长 Z≈14 m；落架决定实际高度。','停机坪外沿主路 ≥3.5 m；翼尖与地面不形成可误入小缝。','先落架脚接坪面 → 机身腹部封闭体 → 翼根/尾翼 → 挂载；重算包围盒再落位。'),
('北侧基地','约 X[-14,14]、Z[-23,-15]；平台 Y=2.4 m；门前两条 3 m 净宽坡道，坡长约 8 m，中心 X=-1.5 / 5 m。','坡底不面对窄墙；坡顶有 ≥2 m 缓冲；气闸门关闭，平台下封闭。','实心楼体代理 → 坡道/平台碰撞 → 柱梁 → 墙/转角/压顶 → 门框/窗暗箱 → 栏杆。'),
('东侧工业','约 X[11,20]、Z[-17,3]；A03 双塔在北，A04 横罐靠南；屋顶阵列只占外缘。','检修路 ≥3 m；中央到设备带通路 ≥3.5 m；跨路管桥净空目标 ≥3.8 m。','基座/鞍座 → 罐/封头 → 支撑 → 法兰/管/阀 → 柜/鳍片；净空还须覆盖原跳跃高度与枪口。'),
('南侧维修岛','A05 中心起点 (10,0,15)，A08 起点 (-9,0,15)。','玩家起点约 (0,1.65,18)；第一目标可见，不将主机摆在准星正前。','设备摆在岛内；软管/补给罐靠检修面；道具组各留至少两个离开方向。'),
('中央掩体','A09 以 (0,0,4) 为起点，拆成 3–4 组错位岛而非整组重复。','高度 0.9–1.2 m；主路 3.5–5 m、短穿插 ≥3 m；交战距离优先 8–20 m。','先冻结碰撞 → 加壳 → 加可拆盖；碎片无导航阻挡。不得把可拆主壳当唯一掩体。'),
('外圈边界','场地约 X[-22,22]、Z[-24,24]；A10 是边界片段，不是自动围满的最终路线。','出入口仍保留遮挡与补敌公平性；矮墙后有岩崖/高岩体接住视觉边界。','角点 → 端柱 → 墙段 → 岩体补闭 → 地灯；从玩家视高沿圈实走，查穿帮与可翻越点。')])+table(['地编 pass','执行动作','通过标准'],[
('L0 尺度与玩法','沿用原玩家与敌人，在灰盒测一整局；先确认双坡、主环和短路。','三局无卡住、近脸刷新、长空跑；标记首目标时间和实测路线长度。'),
('L1 结构替换','替换代理时逐项锁定碰撞高度、通路边缘；先壳、梁、柱、接口，不先撒物件。','每组替换后按原路线再走；柱脚、落架和管架无悬空。'),
('L2 工业用途','标明空气流向/维修面/电缆入口；从设备到管桥逐端口连接。','管不插门、阀不朝墙、线束不跨脚边；结构能解释其支撑与用途。'),
('L3 叙事与小物','少量货箱、工具、便携罐围绕操作位置成组。','可破坏物在路上可见，非所有物体均可爆；不超过原案 6–9 组起点。'),
('L4 阅读与画面','固定 C0/C1/C2、63° FOV，检查全彩/灰度与普通/狂暴。','主地标互不重叠；20 m 角色头肩清楚；敌后背景不密铺高对比管线。'),
('L5 收口与状态','检查端盖、背面、边界、LOD、破坏残架和复位。','没有穿帮/漂浮/空气墙；普通/爆头/手雷/暂停/重开/结尾状态完整。')]))
section('interfaces','06 / 统一接口与五视图读法','同一构件的五个方向来自同一份几何与同一米制比例，不能独立改一张侧视图。',table(['规范','约定','约束与验证'],[
('五视图','正视 FRONT(-Z)、后视 REAR(+Z)、左视 LEFT(-X)、右视 RIGHT(+X)、顶视 TOP(+Y)；不含仰视。','每张构件图五个正投影共用 px/m；右下第六格为轴测辅助，不计入五视图。不同构件图纸独立缩放。'),
('尺寸','清单列名义尺寸；图内 X/Y/Z 为包含附件的实际几何包围尺寸，单位 m。','名义板宽与含外凸锁扣的包络不同。正式资产须另外登记端口、净空与碰撞，而不能只读美术包围盒。'),
('位置与旋转','构件局部前为 -Z，上为 +Y；完整端口包含 position、normal、up、profile 与尺寸。','父子矩阵对齐：T_child = T_parent · T_socket_parent · R_mate · inverse(T_socket_child)。R_mate 绕 up 转 180° 使法线对向；up 对齐，不靠目测推拉。'),
('墙/梁/板','主模数 1 m，半格 0.5 m，细修 0.1 m；结构起始主宽 4 m。','长度可在模板合法值内改，墙边厚度固定；端头/内角/外角分别出件，少量收口件解决余量。'),
('管路','视觉管径族外径 0.22 / 0.45 m；标号是本项目视觉规格，不宣称工业标准 DN。','直管按端点距离生成；弯头按相切路径；法兰按口径映射。r_bend ≥1.5×外径作为建模起点，正式碰撞需留足外弯空间。'),
('栏杆/坡道','栏杆顶高 1.1 m；坡段端点决定倾斜扶手，立柱仍竖直。','不要直接旋转整段栏杆使立柱斜插地面；按坡道沿线重新生成柱脚与横杆。'),
('盖板/破坏','母体 ID、固定口、铰点、完整壳/残架/碎片、恢复初值一并登记。','可破坏盖从静态壳批次分离；不把运行时重置依赖于对象的偶然生成顺序。'),
('材质和标签','白壳、深结构、橙色、青光为统一材质 ID；文字区独立 UV。','图纸色块是材料身份，不是 PBR 最终质感。端口与尺寸优先于图中细小线缝。')])+note('背面设计补充：箱背有结构肋与锁扣对应；墙背封闭；机身腹部有落架座；罐背保留管口与支腿；天线碟背有轴座。可见面与背面都须成立，不能复制正面贴花假装五面一致。'))
# Five-view gallery, all embedded, filtering only controls visibility.
gallery='<div class="controls"><label>分组<select id="part-group"><option value="all">全部构件</option>'+''.join('<option>'+g+'</option>' for g in dict.fromkeys(p['group'] for p in PARTS))+'</select></label><label>检索<input type="search" id="part-search" placeholder="编号、名称、生成器或接口"></label><button id="expand-all">展开全部图纸</button><button id="collapse-all">收起全部图纸</button></div><p id="part-count" role="status"></p><div class="part-index">'+''.join(f'<a href="#part-{p["id"]}">{p["id"]} {p["name"]}</a>' for p in PARTS)+'</div>'
for p in PARTS:
 clean={k:v for k,v in p.items() if k!='mesh'}
 gallery+=f'<details class="part" id="part-{p["id"]}" data-group="{p["group"]}" data-search="{h(json.dumps(clean,ensure_ascii=False))}"><summary><span>{p["id"]}</span> {p["name"]}<small>{p["group"]} / {p["family"]}</small></summary><button class="zoom-control" data-zoom="{p["id"]}" aria-pressed="false">放大图纸</button><div class="drawing"><img loading="lazy" src="{image(OUT/"sheets"/(p["id"]+".svg"))}" alt="{p["id"]} {p["name"]}：正后左右顶五视图与轴测辅助图"></div><div class="spec">'
 gallery+=table(['条目','制作要求'],[('名义尺寸 X/Y/Z',str(p['nominal_size'])+' m；含附件实际包络见图头。'),('生成参数',h(json.dumps(p['params'],ensure_ascii=False))),('接口',p['ports']),('细节职责',p['detail']),('碰撞',p['collision']),('变体',p['variants']),('LOD',p['lod'])])+'</div></details>'
section('five-views','07 / 四十三类基础构件五视图','展开构件查看五视图与生成合同；图纸可通过浏览器保存为 SVG，配套 sheets/ 目录也保留原件。',gallery)
families=[
('G01 / bevel_box','B01、B06、P01–P04','W,H,D,corner_cut,edge_bevel,frame_t,face_id,seed','W/H/D 正值；倒角 < 最薄边的 1/3；框厚和锁扣不随整体缩放。'),
('G02 / profile_extrude','S02、S03、B04、P03','profile2d,depth,lip_t,mirror_side','闭合轮廓无自交；翼和门框真厚度；镜像应用变换后纠正绕序。'),
('G03 / section_loft','S01、S04','stations[z,width,height,offset],seam_regions','截面数量受限；鼻端不出现反折；翼根/落架座固定在可解释承重位。'),
('G04 / lathe','S05、I01/I02、I12、P12','radius_profile,axis,radial_steps,endcap,wall_t','内外表面按壁厚分离；近口真孔；不用单面板伪装罐和喷口。'),
('G05 / ring_array','I03、I07','r_inner,r_outer,axial_h,bolt_count,bolt_circle','r_outer>r_inner；螺栓圈不得落到孔内；法兰与管外径匹配。'),
('G06 / curve_tube','I05/I06、软气管','path_tangent,radius,bend_radius,radial_steps,path_steps','平行移动标架避免扭转；路径相切、自交与最小半径校验；留独立端口。'),
('G07 / rail_array','B11、S08','path,post_pitch,rail_h,rail_radius,style','端柱去重；坡柱保持竖直；非均匀缩放不用于圆杆。'),
('G08 / support','B08/B09、I04、P09','span,height,section,baseplate,brace_mode','梁柱节点对齐；鞍座弧匹配罐径；支撑强制接地，不由噪声扰动。'),
('G09 / deck_ramp','B07/B10、P10','outline,thickness,rise,run,edge_profile','通行面与碰撞面一致；坡顶缓冲、边裙和支撑一并生成。'),
('G10 / wall_window','B02/B03/B05','grid,opening,recess,mullion,backing','室内关闭；窗后暗板、端头与墙背封闭；门扇贴合气闸内口。'),
('G11 / cabinet','I09、P02','size,frame_t,door_split,vent_count,hinge','盖板与母体共用孔位；残架接口不随 seed 漂移。'),
('G12 / fin_array','I10','bounds,fin_pitch,fin_depth,side_caps','上限由观看距离决定；远景切换实心法线面，而不是无限加片。'),
('G13 / machine_chassis','I11','bounds,shell_open,roller_count,port_layout','手工冻结英雄轮廓；只有机械组与维护面变体，不能随机所有壳面。'),
('G14 / mast_dish','P06/P07','segments,height,dish_profile,tilt,feed_offset','轴心、背支臂和馈源一致；天线避开主地标轮廓。'),
('G15 / panel_array_light','P05/P08','rows,cols,frame_t,tilt,emission_state','面板和灯罩实体；发光件与实时灯预算分开。'),
('G16 / rock_profile','P11','radius,height,facets,macro_noise,seed','种子只改形体细节；落地包络和路线净空先裁定；4–6 个定稿石型复用。')]
section('generators','08 / 生产生成器合同与变体控制','先做少数高复用生成器；飞船机身、气闸和发生器仍需人工审美冻结剪影。',table(['生成器族','覆盖构件','参数','边界'],families)+'''<h3>通用输入 / 输出合同</h3><pre>input = {
  schema_version, generator_version, family, preset_id,
  dimensions_m, structural_params, material_recipe_id,
  shape_seed, surface_seed, instance_id, lod_profile
}
output = {
  editable_source, meshes_by_lod, material_regions, uv0, uv2_if_static,
  sockets[{name, position_m, normal, up, profile, diameter_m}],
  collision_proxies, destruction_parts, bounds, stats, provenance
}
cache_key = hash(generator_version + canonical_json(structural_params)
                 + shape_seed + lod_profile)
material_key = hash(recipe_version + surface_seed + resolution + channels)</pre>'''+table(['参数类型','可变','不可随 seed 改变'],[
('结构 seed','月岩宏观形体、非关键装甲分区、箱侧肋预设。','门洞净空、掩体高、枪线、出生点、落架接地面、法兰口径、可破坏挂点。'),
('表面 seed','尘积与轻微磨损，材质图集中少量稳定变体。','不能每实例生成一套独立大贴图或材质对象；不能让锈斑随机控制凹凸、颜色、金属度各一套。'),
('预设','箱 S/M/L、管两口径、墙 2/4 m、平台 2/4 m、鳍片近/远。','不允许任意尺寸组合；先测 12 个边界样例再开放连续参数。'),
('缓存与复现','相同输入导出相同几何与图像内容；记录版本与哈希。','不要依赖当前时间作为默认 seed；不要每次重开/45 秒切换重建。')])+note('制作开销也包括生成器调试和接缝返工。首个试点只做储物箱与压力容器两家族：各三种变体，记录手工修改耗时、生成耗时、返工数量与实机效果；若变体很少且参数复杂，允许保留一次性手工主模型，不强行程序化一切。'))
section('detail','09 / 几何与材质细节的距离分工','用正常 FOV 和实战距离决定细节，不以 Blender 极近景为唯一标准。',table(['细节','近景 0.3–3 m','中景 3–12 m','远景 >12 m'],[
('轮廓与大凹凸','真实几何：壳厚、门洞、喷口、手柄、翼缘、支架。','保留主截面与承重连接；合并内构。','保留剪影、色块与少量高光边，删看不见背面附件。'),
('小倒角','影响读形的边保留低段 Bevel；高模细边烘法线。','关键边一段/两段起点；其余法线。','不继续加细分；用正确顶点法线和粗糙度控制闪点。'),
('螺丝与铆钉','少量近处原型实例化，导出时合并静态网格或按区批量；不每颗 Node3D。','大连接点可保留；密集小螺栓入法线。','移除或烘焙，别产生亚像素亮点。'),
('划痕/接缝/颗粒','Normal + Roughness，同一 mask 对应表面变化；微弱强度。','降低高频幅度，mip 与法线过滤；不是加大纹理对比。','只留下低频 roughness/color；距离淡出细节强度而非突然透明整个物件。'),
('污渍与月尘','制作端程序化生成，地脚/踩踏/检修部位有原因。','共享 atlas/trim；顶点色或实例参数做低频差异。','压低对比，不让脏层把白壳和橙色一起洗灰。'),
('格栅和鳍片','最近两组真实浅腔或少量片组。','低模片 + 法线面板。','实心暗面 + 法线，无密集透明网。')])+note('距离是本案试点划分，正式阈值须按视口像素覆盖测定；枪与手沿用原案独立高优先级。小划痕不增加几何。实例化小模型节约制作与存储，只有正确合并/批量并控制材质槽时才可能减少绘制成本。'))
section('materials','10 / 程序化 PBR：共享蒙版驱动所有通道','程序化放在制作端；运行端优先少量已烘焙材质与轻量状态参数。',table(['材料配方','底色/金属度/粗糙度','蒙版逻辑与生成位置'],[
('白色涂层装甲','基础略暖白；漆面 Metallic=0；Roughness 起点 .42–.62。','wear_mask 仅出现在把手/边缘/碰撞区，露底部分才切到金属；反射、normal 与颜色共同响应。'),
('深色机械芯','深蓝灰；裸金属 Metallic .8–1，Roughness .28–.55。','有反射环境才像金属；磨擦接触区局部更光滑，不把所有黑色都设为金属。'),
('软管与密封胶','近黑非金属，Roughness .75–.95。','截面与接头真几何，表面微粒弱法线；不把橡胶变成发亮金属管。'),
('月尘覆盖','非金属、高粗糙；低幅色差。','deposition_mask 由朝向、地面距离、凹隙、检修使用区、固定 seed 控制；同时减金属、增粗糙、柔化原法线。'),
('月壤与岩石','Metallic=0；Roughness .85–1；低频颜色与粗法线。','Height/Voronoi/低阶 FBM 在制作端烘焙；运行时近景一层 detail，远景衰减；不全场迭代 domain warp。'),
('旧锈材质备用','锈层自身非金属，粗糙度通常提高；露金属与锈斑由同一个 mask 混合。','月球外表默认 corrosion=0；不是地球雨港。若后续有地球制造旧件叙事，再按局部预设启用，不默认下雨流锈。'),
('设备青光','实体环+小面积 Emissive；其余通道保持材料身份。','状态 uniform 驱动颜色/强度，45 秒前已加载；真实落光由少数关键灯承担。')])+'''<h3>蒙版配方起点</h3><pre>macro = fbm(position * low_frequency, octaves=2..3, seed=surface_seed)
edge = authored_edge_mask                 # 制作端曲率/人工边区，不在每像素实时求曲率
contact = base_contact_mask * authored_usage_mask
dust = saturate(macro * orientation_mask * contact + recess_mask)
wear = saturate(edge * usage_mask * thresholded_noise)
base_color = mix(paint_color, exposed_metal_color, wear)
metallic = mix(0.0, metal_value, wear) * (1.0 - dust)
roughness = mix(paint_roughness, metal_roughness, wear)
roughness = mix(roughness, dust_roughness, dust)
normal = blend_normals(substrate_normal, wear_normal, wear)
normal = soften_normal(normal, dust)
# 同一 dust/wear 同步作用；RGB 与数据图按各自颜色空间导入。</pre>'''+table(['资源','制作与分发','验收'],[
('三套共享图集','建筑 trim、工业设备 atlas、道具 atlas；英雄飞船可独立；BaseColor、Normal、ORM 同源生成。','UV/色带/文字位置固定；ORM=R AO、G Roughness、B Metallic；AO 不做大范围脏层。'),
('可编辑配方','保存 Python/Blender 节点或等价生成脚本、参数 JSON、seed、版本；最终图进 assets。','生成工具可重建；缓存按内容 hash 去重，不每变体独立复制纹理。'),
('运行时计算','状态发光、少量顶点色混合、单层低频变化；完整多阶噪声先烘焙。','启动、暖机、45 秒切换分别测；包小不等于显存小，生成一次也会占纹理内存。'),
('法线正确性','UV0 切线空间法线；Triplanar 法线必须变换到同一坐标并按轴符号混合后归一化。','旋转模型与侧面测试，不能直接将三张切线 normal RGB 线性平均。')]))
tech=[
('1 程序化建模','制作端优先采用','Blender Python / 参数 JSON 生成 + .blend/GLB 缓存；原图纸脚本仅证明拆件结构。','不把生成器放每帧，不以一份源函数保证少 draw calls。'),
('2 模块化建模','全面采用','墙、角、端盖、平台、栏杆、坡、管、支架、箱、灯有稳定接口与预设。','封闭背面、管径、接缝与承重关系先过样板。'),
('3 几何/材质分工','全面采用','真实轮廓与大凹凸；小倒角看距离；划痕/颗粒入图。','近中远固定机位同时检查，不只看源模型细节。'),
('4 低模+好材质','全面采用','主轮廓、厚度和主光先成立，少量共享高质量图集跟进。','材质不能挽救纸片翼、悬空柱和没有凹深的门框。'),
('5 程序化 PBR','采用共享配方','结构 mask 对应 Albedo/Metallic/Roughness/Normal/AO；发光独立状态。','默认干燥月球，不启用全局湿层与流锈。'),
('6 程序化纹理','制作端烘焙为主','选择 Perlin 或 Simplex 作为噪声基底，2–3 阶 FBM、Voronoi、Height Mask 与少量 Domain Warp 按需烘焙缓存。','复杂高频函数不满屏常驻；比较启动与 GPU 代价。'),
('7 Shader','按材料选择','PBR 自带角度反射；Triplanar 优先岩石；Vertex Color 做尘/材质区；按距离减细节。','建筑标识/方向性 trim 用 UV；视差仅少量近景样板，先不开；避免额外 Fresnel 把边刷白。'),
('8 平面反射','月球小样默认不采用','干燥地面无水；金属和窗用环境与少量 ReflectionProbe；真实镜面另立收益测试。','镜像相机还要再渲染可见集；不承诺半分辨率就只有 25% 成本，也不假定动态敌人能被静态探针映到。'),
('9 Bloom / Glow','克制采用并可关闭','小面积灯环、门灯、枪口有局部辉光；开关普通/过载 A/B。','Compatibility 的实际响应与高动态平台不同；光晕不替代落光，避免泛白。'),
('10 色调与后期','曝光/颜色基线先稳定','选一条经过 Web 验证的 tonemapping 路径，再固定曝光；低血量 vignette 沿用。','不直接复制 Three.js ACES 常数；不叠加两次色调映射。Film grain、常驻色差、额外电影暗角不进入基线。')]
section('tech','11 / 十项技术的落地取舍','目标是把重复制作变成参数与缓存，把复杂运算留在制作阶段，把运行时成本花在能看见的地方。',table(['技术','决定','本项目实施方向','检查点'],tech)+note('Triplanar 省 UV 工作，但通常增加纹理采样：同一通道可能取三个轴向；BaseColor/Normal/ORM 都启用时成本进一步叠加。先在 P11 岩石样板用，对带字、装甲条和设备面板用 UV。移动/旋转物体优先物体空间锚定，世界空间噪声用于固定环境；避免模型走动时污渍“游泳”。')+note('本次核查用户提供的原始 HTML：Gg 中按需生成并缓存 Albedo/ORM/Normal，记录纹理字节和生成耗时；SL_TRIPLANAR 具有三轴采样与法线处理；源文件暴露 reflectionTarget/reflectionCamera。这里借鉴可复现配方与缓存，不照搬雨夜湿面。原文件只在本地保留，不随仓库提交。'))
section('production','12 / 低开销生产流程与阶段验收','先验证两个家族能否高质量复用，再扩大到全场；每阶段保留固定机位与资产统计。',table(['阶段','具体交付','通过条件'],[
('K0 接口样板','箱 P01/P02 三尺寸；罐 I01/I02/I03 横竖两总装；参数 schema 与缓存 manifest。','五视图比例、端口尺寸、法线方向、接地与 seed 复现正确。所有生成变体 UV/LOD/碰撞一致可用。'),
('K1 外立面角落','B01–B11 的一角：墙/窗暗箱/封闭门框/平台/柱梁/坡/栏杆。','1 m/0.5 m 接口成立；通路不缩水；坡柱仍竖；屋顶与背面封闭。'),
('K2 工业站','A03/A04/A05：双塔、横罐、发生器与一组盖板破坏。','管口、法兰、密封端、支架接触和维修路成立；喷散不长驻遮敌。'),
('K3 飞船与外围','人工冻结 S01/S02/S03 大形，再用 S05–S08 程序组装；完成围墙、灯、岩石。','C0/C1 主轮廓、落架接地、侧路、外圈视觉边界与碰撞一致。'),
('K4 地编整合','把总装落在已验证灰盒，6–9 组互动、3 个机位、完整普通/狂暴回合。','角色在 8/15/20 m 各背景清楚；碎片/盖板/重开正确；无新增室内。'),
('K5 运行与交付','Blender 源、GLB/纹理、manifest、自动检查、Web 实机和帧时间。','记录生成器制作与返工时间、PCK/显存/绘制规模、P50/P95/P99 与45秒切换；预算仍按主案，超标如实标记。')])+'''<h3>导出与资产组织提案</h3><pre>art_source/moonbase/generators/       # 生产 Blender 生成器，待实施
art_source/moonbase/recipes/          # 几何与材质预设、seed、版本
art_source/moonbase/hero/             # 人工冻结的英雄截面与源 .blend
assets/models/moonbase/               # 已导出的 GLB、LOD 与碰撞场景
assets/materials/moonbase/            # 共享图集/trim 与运行材质
# 当前图册在 docs/design/.../construction/；不当作生产资产目录。</pre>'''+note('静态壳体按材质/空间块合并，重复道具在适当区域考虑 MultiMesh；大批次不能逐实例剔除，不能把全图装饰塞进一个总批次。可破坏盖板与独立命中对象保留逻辑 ID，和静态外壳分开。生成器版本变更后回归全部尺寸边界与连接面。'))
section('acceptance','13 / 图纸与生产资产各自的验收','图册完成不等于生产模型完成；每项证据对应它实际证明的内容。',table(['检查','图纸阶段','生产阶段'],[
('覆盖','12 个总装全部有构件列表；43 个基础构件各有正后左右顶，编号对应概念图可见物。','端头、转角、支撑、背板、管夹、拼缝与活动挂点在实际模型完整补齐。'),
('投影','共享几何、同米制比例；顶视 -Z 在页面上方；五视图之外附轴测，不以透视图代替正视。','三轴尺寸、pivot、socket 实际导入匹配；负缩放/绕序/法线无错误。'),
('材料','色板仅为材料区，所有材质范围标为提案。','原始图 vs Godot 同机位对照，白壳有面差、金属有反射、橙条不退灰。'),
('可玩','布局标注路径宽、掩体高、坡度、边界。','实走和敌人补敌三局；跳跃/枪口净空按原玩法测，非仅静态相机。'),
('成本','生成器族/参数/缓存/批次策略可追踪。','同时比较制作耗时与画面收益；不能以代码短、PNG小或一个drawcall证明总体性能。')])+note('图纸是原创的尺寸化设计代理。没有承诺 AI 概念图中的所有细节可以自动生成，也未把示意总装当成可直接上线的模型。本文暂不实施或发布游戏。'))
section('sources','14 / 核查依据与技术边界','2026-11-13 核查；布局、尺寸与流程为本案设计，技术能力依据官方文档。',table(['依据','本案用途'],[
('<a href="https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html">Godot 4.7 渲染器比较</a>','Web 以 Compatibility 为基线；可用 Glow/SSAO 与已烘焙光照不等于已证明项目性能；SSR/原生体积雾不作依赖。'),
('<a href="https://docs.godotengine.org/en/4.7/tutorials/3d/standard_material_3d.html">Godot 标准材质与 ORM</a>','ORM、透明、UV/Triplanar 等参数边界；材质制作建议由项目样板验证。'),
('<a href="https://docs.godotengine.org/en/4.7/tutorials/performance/using_multimesh.html">Godot MultiMesh</a>','批量绘制与整体剔除限制；页面标有尚待更新说明，具体接入按运行版本测试。'),
('本地用户提供 HTML；SHA-256 9e55b5200b088adaf8e1152da04efc0d3b25e236e6baf2dee96f81e23e084966','核查程序纹理缓存/三轴映射/反射相机标识。未在本轮执行该第三方游戏，也未把同名网络项目当权威来源。'),
('本项目 02-map-overview.png 与原制作策划案','场景内容、玩法约束、字体与性能基线；AI 图只是视觉参考。'),
('construction/build_kit.py、kit.json、sheets/、assemblies/','图纸原创几何与投影可重建；参数是设计提案，生产模型仍待实施。')])+'''<details><summary>内嵌字体与许可</summary><p>沿用主案 Noto Sans CJK SC Medium（Adobe 2014–2021）子集与 Oxanium 700（The Oxanium Project Authors 2019），均为 SIL OFL 1.1；本册补充字符，原版权字段保留。</p><pre>@@LICENSES@@</pre></details>''')
CSS=r'''
:root{--ink:#243d4a;--muted:#657983;--paper:#f0f2ec;--line:#c4d0cf;--orange:#bd5637}*{box-sizing:border-box}html{scroll-padding-top:22px}body{margin:0;background:var(--paper);color:var(--ink);font:15px/1.85 NotoKit,"PingFang SC",sans-serif;font-synthesis:none}a{color:#a74425;text-underline-offset:3px}button,input,select{font:inherit;color:inherit;border:1px solid #a3b8bc;border-radius:4px;padding:7px 10px;background:#fff}button{cursor:pointer}a:focus-visible,button:focus-visible,input:focus-visible,select:focus-visible,summary:focus-visible{outline:3px solid #d85c38;outline-offset:3px}.sidebar{position:fixed;left:0;top:0;bottom:0;width:235px;background:#112633;color:#e5ece7;padding:25px 20px;overflow:auto}.brand{font:700 27px/1.1 Oxanium,sans-serif}.brand small{font:500 11px/2 NotoKit,sans-serif;display:block;color:#b5c6c7;margin-top:10px}.sidebar nav{margin:25px 0;display:grid;gap:8px}.sidebar nav a{font-size:12px;color:#d0dfdf;text-decoration:none;border-left:2px solid transparent;padding:5px 9px}.sidebar nav a.active{border-color:#df8055;background:#203e4e}.sidebar p{font-size:11px;color:#b2c6c9}.sidebar>a{color:#eeb58c;font-size:12px}main{margin-left:235px;padding:40px clamp(24px,4vw,64px) 70px;max-width:1680px}.eyebrow{font:700 12px Oxanium,sans-serif;letter-spacing:.14em;color:#bd5637}h1{font-size:clamp(29px,3.2vw,48px);line-height:1.4;margin:18px 0}h2{font-size:25px;line-height:1.5}h3{font-size:18px;margin:22px 0 12px}.lead{color:#536e77;font-size:17px;max-width:950px}.meta,.actions{display:flex;flex-wrap:wrap;gap:10px;margin:20px 0}.meta span{font-size:12px;border:1px solid #adbec0;padding:3px 9px}.actions button:first-child{background:#183e50;color:white}.hero,.overview{margin:26px 0}.hero img,.overview img{width:100%;height:auto;display:block;border-radius:5px}.caption{font-size:12px;color:var(--muted)}section{margin-top:20px;padding:35px 0;border-top:1px solid var(--line);scroll-margin-top:20px}.table-wrap{overflow:auto;border:1px solid var(--line);border-radius:5px;margin:22px 0;background:#f9faf5}table{border-collapse:collapse;width:100%;min-width:780px;font-size:13px;line-height:1.8}th,td{padding:13px 16px;text-align:left;vertical-align:top;border-bottom:1px solid #d7dfda;min-width:130px}th{background:#dce6e2;font-size:12px}td:first-child{font-weight:600}tr:last-child td{border:0}.note{border-left:4px solid #577e85;background:#e2ebe6;padding:15px 20px;font-size:13px;margin:22px 0}.overview{position:relative}.overview a{position:absolute;transform:translate(-50%,-50%);font:700 13px Oxanium,sans-serif;background:#d85c38;border:2px solid #fff;color:#fff;text-decoration:none;min-width:30px;height:30px;border-radius:50%;display:grid;place-items:center;box-shadow:0 2px 4px #0006}.coverage{padding:10px 0}.coverage p{margin:7px 0;font-size:13px}.assembly-grid{display:grid;grid-template-columns:1fr;gap:20px}.assembly{border:1px solid var(--line);border-radius:6px;padding:15px 20px;background:#f8f9f3;scroll-margin-top:20px}.assembly h3{margin-top:3px}.assembly img{width:100%;height:auto;display:block}.assembly p{font-size:13px}.bom{display:flex;flex-wrap:wrap;gap:12px}.part-index{display:flex;gap:7px;flex-wrap:wrap;margin:20px 0}.part-index a{font-size:11px;padding:3px 6px;background:#e1e9e3;border-radius:3px}.controls{display:flex;gap:15px;flex-wrap:wrap;align-items:end}.controls label{display:flex;flex-direction:column;font-size:12px;gap:5px}.controls input{min-width:260px}#part-count{font-size:13px;color:#527482}.part{margin:12px 0;border:1px solid var(--line);background:#f8f9f4;border-radius:5px;scroll-margin-top:22px}.part summary{cursor:pointer;padding:16px 19px;font-size:16px}.part summary span{font-family:Oxanium,sans-serif;color:#ad4c30;margin-right:9px}.part summary small{display:block;font-size:11px;color:#67818a;margin-left:28px}.part img{display:block;width:100%;height:auto}.drawing{overflow:auto}.drawing.zoomed img{width:1440px;max-width:none}.zoom-control{margin:0 16px 12px;font-size:12px}.spec{padding:0 16px 12px}.spec table{min-width:600px}.hidden{display:none!important}pre{background:#132d3b;color:#d7e4dc;white-space:pre-wrap;overflow-wrap:anywhere;padding:22px;border-radius:5px;font:12px/1.9 ui-monospace,monospace}details:not(.part){margin:20px 0}footer{font-size:12px;color:#6b8087;border-top:1px solid var(--line);padding-top:25px}.download-notice{font-size:12px;min-height:1.8em;color:#557581}@media(max-width:1050px){.sidebar{width:200px;padding:22px 14px}main{margin-left:200px;padding:28px 24px}}@media(max-width:720px){.sidebar{position:relative;width:100%;padding:20px}.sidebar nav{display:flex;overflow:auto;gap:12px;margin:17px 0 0}.sidebar nav a{flex-shrink:0;max-width:175px;font-size:11px;border:1px solid #325563}.sidebar p{display:none}main{margin:0;padding:24px 16px}.lead{font-size:15px}h2{font-size:22px}.controls{gap:10px}.controls label,.controls select,.controls input{width:100%;min-width:0}.overview a{font-size:9px;min-width:22px;height:22px}.assembly{padding:12px}.part summary{font-size:14px;padding:13px}.part-index a{font-size:10px}}@media print{.sidebar,.actions,.controls,.part-index,.download-notice{display:none!important}main{margin:0;padding:0}body{background:white;font-size:10pt}section{padding-top:20px}.zoom-control{display:none!important}.drawing.zoomed img{width:100%}.part{break-before:page}.part img{max-height:175mm;object-fit:contain}.assembly{break-inside:avoid}table{min-width:0;font-size:8pt}th,td{min-width:0;padding:8px}pre{background:#eee;color:#111}.table-wrap{overflow:visible}.overview a{-webkit-print-color-adjust:exact;print-color-adjust:exact}}
'''
JS=r'''
const $=id=>document.getElementById(id),parts=[...document.querySelectorAll('.part')];
function filter(){const g=$('part-group').value,q=$('part-search').value.trim().toLowerCase();let n=0;for(const p of parts){const show=(g==='all'||p.dataset.group===g)&&p.dataset.search.toLowerCase().includes(q);p.classList.toggle('hidden',!show);if(show)n++;}$('part-count').textContent=`显示 ${n} / ${parts.length} 类构件；每类包含 5 个正投影与 1 个轴测。`;}
$('part-group').addEventListener('change',filter);$('part-search').addEventListener('input',filter);
$('expand-all').addEventListener('click',()=>parts.filter(p=>!p.classList.contains('hidden')).forEach(p=>p.open=true));$('collapse-all').addEventListener('click',()=>parts.forEach(p=>p.open=false));
function openHash(){const id=location.hash.slice(1),p=document.getElementById(id);if(p&&p.classList.contains('part')){if(p.classList.contains('hidden')){$('part-group').value='all';$('part-search').value='';filter();}p.open=true;p.scrollIntoView({block:'start'});}}
window.addEventListener('hashchange',openHash);filter();openHash();
for(const b of document.querySelectorAll('[data-zoom]'))b.addEventListener('click',()=>{const d=document.querySelector('#part-'+b.dataset.zoom+' .drawing'),on=d.classList.toggle('zoomed');b.setAttribute('aria-pressed',String(on));b.textContent=on?'适配宽度':'放大图纸';});
const kit=@@KIT@@;
$('export-kit').addEventListener('click',()=>{const a=document.createElement('a'),url=URL.createObjectURL(new Blob([JSON.stringify(kit,null,2)],{type:'application/json;charset=utf-8'}));a.href=url;a.download='moonbase-construction-kit-v1.1.json';document.body.append(a);a.click();a.remove();$('download-state').textContent='已请求下载完整构件清单；也可使用目录中的 kit.json。';setTimeout(()=>URL.revokeObjectURL(url),1500);});
$('print').addEventListener('click',()=>window.print());let saved=[];window.addEventListener('beforeprint',()=>{saved=parts.map(p=>[p,p.open,p.classList.contains('hidden')]);for(const p of parts){p.open=true;p.classList.remove('hidden');}});window.addEventListener('afterprint',()=>{for(const [p,o,h]of saved){p.open=o;p.classList.toggle('hidden',h);}});
if('IntersectionObserver'in window){const io=new IntersectionObserver(es=>{for(const e of es)if(e.isIntersecting)for(const a of document.querySelectorAll('.sidebar nav a'))a.classList.toggle('active',a.hash==='#'+e.target.id);},{rootMargin:'-5% 0px -80% 0px'});for(const s of document.querySelectorAll('section'))io.observe(s);}
'''
for item in S:
 if item['id']=='level':item['body']='<figure><img style="width:100%;height:auto" src="'+image(OUT/'layout-v1.1.svg')+'" alt="月球基地室外地编总平面，标注坐标、落位与路线净宽"><figcaption class="caption">补充地编总平面 v1.1：西侧飞船中心调整至 X=-12.5 m，给 12 m 宽代理保留 3.5 m 外侧通路。路线和出生均待实际灰盒验证。</figcaption></figure>'+item['body']
# Embed report-specific CJK subset, preserving source copyright/name fields.
from fontTools.ttLib import TTFont
from fontTools import subset
source=ROOT/'artifacts/local/moonbase-plan/NotoSansCJKsc-Medium.otf'
text=Path(__file__).read_text()+json.dumps([{k:v for k,v in p.items() if k!='mesh'} for p in PARTS],ensure_ascii=False)+json.dumps([{k:v for k,v in a.items() if k!='mesh'} for a in ASSEMBLIES],ensure_ascii=False)
font=TTFont(source);opt=subset.Options();opt.name_IDs=['*'];sub=subset.Subsetter(options=opt);sub.populate(unicodes={ord(c) for c in text}|set(range(32,127)));sub.subset(font);font.flavor='woff2';font.save(OUT/'NotoKit.woff2')
fc=''
for family,path,weight in [('NotoKit',OUT/'NotoKit.woff2',500),('Oxanium',PLAN/'fonts/Oxanium.woff2',700)]:fc+=f'@font-face{{font-family:{family};src:url(data:font/woff2;base64,{base64.b64encode(path.read_bytes()).decode()}) format("woff2");font-weight:{weight};font-display:swap;}}'
licenses='\n\n'.join((PLAN/'fonts'/n).read_text() for n in ['NotoSansCJK-OFL.txt','Oxanium-OFL.txt'])
nav=''.join(f'<a href="#{s["id"]}">{s["title"]}</a>' for s in S)
body=''.join(f'<section id="{s["id"]}"><h2>{s["title"]}</h2><p class="lead">{s["lead"]}</p>{s["body"]}</section>' for s in S)
kit=(OUT/'kit.json').read_text()
page='''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>月球基地 · 地编与程序化构件手册 v1.1</title><style>@@FONTS@@@@CSS@@</style></head><body><aside class="sidebar"><div class="brand">MOONBASE / KIT<small>地编、建模与技术美术 · V1.1</small></div><a href="../index.html">返回完整制作策划案</a><nav aria-label="构件手册目录">@@NAV@@</nav><p>43 类构件 / 215 个正投影<br>12 组总装 / 不含基地室内<br>尺寸化设计代理，尚非生产资产</p></aside><main><header><div class="eyebrow">CONSTRUCTION KIT / PROCEDURAL ART / EXTERIOR ONLY</div><h1>从一张概念图<br>拆到可重复制造的月球基地</h1><p class="lead">用统一接口连接飞船、基地外壳与工业设施；用参数化生成和共享材质减少重复劳动。每个基础构件有五视图，每个复杂物体有可追溯的装配配方。</p><div class="meta"><span>43 类构件</span><span>215 个正投影</span><span>12 组总装</span><span>16 个生成器家族提案</span><span>只做室外</span></div><div class="actions"><button id="export-kit">导出构件清单 JSON</button><button id="print">打印 / 保存 PDF</button><a href="#five-views">进入五视图图册</a></div><div class="download-notice" id="download-state" role="status"></div><figure class="hero"><img src="@@CONCEPT@@" alt="月球基地全景 AI 概念图"><figcaption class="caption">视觉目标参考；不是游戏实机。下文背面、接口和尺寸均为新设计起点，待灰盒与样板验收。</figcaption></figure></header>@@BODY@@<footer>本册是 v1.0 制作策划案的环境生产附册；全部图片、字体、样式与脚本内嵌。来源链接和返回主案链接不是运行资源。© 字体作者版权见文末；图纸与投影脚本随项目保存。</footer></main><script>@@JS@@</script></body></html>'''
for key,val in [('@@FONTS@@',fc),('@@CSS@@',CSS),('@@NAV@@',nav),('@@CONCEPT@@',image(concept)),('@@BODY@@',body),('@@LICENSES@@',h(licenses)),('@@JS@@',JS.replace('@@KIT@@',kit))]:page=page.replace(key,val)
page='\n'.join(x.rstrip() for x in page.splitlines())
assert not re.search(r'@@\w+@@',page)
(OUT/'index.html').write_text(page)
(OUT/'build-info.json').write_text(json.dumps({'sections':len(S),'parts':len(PARTS),'orthographic_views':len(PARTS)*5,'assembly_recipes':len(ASSEMBLIES),'html_bytes':len(page.encode()),'html_sha256':hashlib.sha256(page.encode()).hexdigest(),'status':'planning','font_source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'embedded_svg':len(PARTS)+len(ASSEMBLIES)+1},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'sections':len(S),'parts':len(PARTS),'views':len(PARTS)*5,'bytes':len(page.encode())}))
