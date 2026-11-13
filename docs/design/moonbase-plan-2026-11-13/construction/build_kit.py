"""Dimensioned design proxies and orthographic sheets; not production game meshes."""
from pathlib import Path
from math import sin,cos,pi,sqrt
import json,html,hashlib,base64
OUT=Path(__file__).resolve().parent
PARTS=[];ASSEMBLIES=[]
COLORS={'shell':'#d8d6cd','dark':'#334555','orange':'#d85c38','cyan':'#70cfdf','glass':'#193c51','steel':'#8e9aa2','yellow':'#cba35c','soil':'#777a7e'}
def add(a,b):return tuple(x+y for x,y in zip(a,b))
def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def cross(a,b):return(a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def unit(v):
 l=sqrt(dot(v,v));return tuple(x/l for x in v) if l>1e-9 else (0,1,0)
def faces(v,fs,c='shell'):
 # Convex chunks only. Orient face normals away from centroid.
 center=tuple(sum(p[k] for p in v)/len(v) for k in range(3));out=[]
 for f in fs:
  ps=[v[i] for i in f];n=cross(sub(ps[1],ps[0]),sub(ps[2],ps[0]));fc=tuple(sum(p[k] for p in ps)/len(ps) for k in range(3))
  if dot(n,sub(fc,center))<0:ps=list(reversed(ps))
  out.append((ps,c))
 return out
def extrude(poly,d,c='shell'):
 n=len(poly);v=[(x,y,z) for z in [-d/2,d/2] for x,y in poly];return faces(v,[list(range(n)),list(range(n,2*n))]+[[i,(i+1)%n,(i+1)%n+n,i+n] for i in range(n)],c)
def box(w,h,d,c='shell',bevel=0):
 b=min(bevel,w/3,h/3)
 return extrude([(-w/2+b,0),(w/2-b,0),(w/2,b),(w/2,h-b),(w/2-b,h),(-w/2+b,h),(-w/2,h-b),(-w/2,b)],d,c) if b else extrude([(-w/2,0),(w/2,0),(w/2,h),(-w/2,h)],d,c)
def lathe(profile,c='shell',n=16):
 # profile: (height, radius), closed at ends; rings can close as a tube.
 v=[(r*cos(2*pi*j/n),y,r*sin(2*pi*j/n)) for y,r in profile for j in range(n)];fs=[]
 for k in range(len(profile)-1):
  for j in range(n):fs.append([k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j])
 fs.extend([list(range(n-1,-1,-1)),list(range((len(profile)-1)*n,len(profile)*n))]);return faces(v,fs,c)
def shift(mesh,p):return [([add(v,p) for v in f],c) for f,c in mesh]
def rotate(mesh,axis,a):
 ca,sa=cos(a),sin(a)
 def r(p):
  x,y,z=p
  return (x,y*ca-z*sa,y*sa+z*ca) if axis=='x' else ((x*ca+z*sa,y,-x*sa+z*ca) if axis=='y' else (x*ca-y*sa,x*sa+y*ca,z))
 return [([r(v) for v in f],c) for f,c in mesh]
def scale(mesh,s):return [([tuple(v[k]*s[k] for k in range(3)) for v in (reversed(f) if s[0]*s[1]*s[2]<0 else f)],c) for f,c in mesh]
def rod(a,b,r=.05,c='dark',n=10):
 d=sub(b,a);l=sqrt(dot(d,d));axis=unit(d);u=unit(cross(axis,(0,0,1) if abs(axis[2])<.9 else (1,0,0)));v=cross(axis,u)
 pts=[add(p,add(tuple(r*cos(j*2*pi/n)*x for x in u),tuple(r*sin(j*2*pi/n)*x for x in v))) for p in [a,b] for j in range(n)]
 return faces(pts,[list(range(n)),list(range(n,2*n))]+[[j,(j+1)%n,(j+1)%n+n,j+n] for j in range(n)],c)
def ring(ro,ri,h,c='steel',n=16):
 # Four surfaces, preserving a true through hole.
 v=[(r*cos(j*2*pi/n),y,r*sin(j*2*pi/n)) for y,r in [(0,ro),(h,ro),(h,ri),(0,ri)] for j in range(n)];out=[]
 for k in range(4):
  for j in range(n):
   ps=[v[k*n+j],v[k*n+(j+1)%n],v[((k+1)%4)*n+(j+1)%n],v[((k+1)%4)*n+j]]
   if k in (2,3):pass
   out.append((list(reversed(ps)),c))
 return out
def panel(w,h,d=.15):
 m=box(w,h,d,'shell',min(.14,w*.12,h*.12));m+=shift(box(w*.65,h*.15,.025,'orange'),(0,h*.25,-d/2-.025));return m
def bounds(m):
 ps=[v for f,c in m for v in f];return [min(v[k] for v in ps) for k in range(3)],[max(v[k] for v in ps) for k in range(3)]
def part(i,name,group,family,size,mesh,params,ports,detail,collision,variants='长度／色带／seed',lod='保留外轮廓；减小圆周段数与附件'):
 mn,mx=bounds(mesh);actual=[round(mx[k]-mn[k],4) for k in range(3)]
 PARTS.append(dict(id=i,name=name,group=group,family=family,nominal_size=size,bounds_size=actual,params=params,ports=ports,detail=detail,collision=collision,variants=variants,lod=lod,mesh=mesh));return mesh
# Ship components: front is -Z.
stations=[(-7,.18,.08,.25),(-4,1.05,.08,.75),(-1,1.55,0,1.3),(3.5,1.45,0,1.15)]
v=[]
for z,w,lo,hi in stations:v.extend([(-w,lo,z),(w,lo,z),(w,hi*.65,z),(.8*w,hi,z),(-.8*w,hi,z),(-w,hi*.65,z)])
fs=[list(range(6)),list(range(len(v)-6,len(v)))]+[[k*6+j,k*6+(j+1)%6,(k+1)*6+(j+1)%6,(k+1)*6+j] for k in range(len(stations)-1) for j in range(6)]
hull=faces(v,fs,'shell')+shift(box(1.4,.18,6.8,'dark',.07),(0,-.08,.1))
part('S01','楔形机身芯','飞船','profile_loft',[3.1,1.38,10.5],hull,{'length_m':[9,12],'front_width_ratio':[.12,.35],'sections':[3,6]},'前后截面中心；翼根 ±X；腹部落架座','轮廓与装甲退台为几何；浅缝烘焙','3 个凸包；腹部不可穿行','长度／鼻端截面／装甲分区；不随机改变接地高度')
wing=shift(rotate(extrude([(0,-1.9),(4.8,.3),(4.2,1.6),(0,1.15)],.25,'shell'),'x',pi/2),(-2.4,.125,0))
wing+=shift(rotate(extrude([(1.1,-1.0),(3.7,.35),(3.3,.7),(1.1,-.15)],.018,'orange'),'x',pi/2),(-2.4,.267,0))
part('S02','翼面与翼根','飞船','tapered_extrude',[4.8,.25,3.5],wing,{'span_m':[3,5],'thickness_m':[.18,.45],'sweep_deg':[15,35]},'内端翼根面；挂载座位于局部坐标','翼前缘与厚度为几何；铆钉为法线','静态翼碰撞并入机身；不可站上','左右手版本重新检查绕序，不能只保留负缩放')
fin=extrude([(-.8,0),(.8,0),(.4,3.2),(-.15,2.7)],.18);fin+=shift(extrude([(-.45,.35),(.38,.35),(.18,2.7),(-.12,2.4)],.02,'orange'),(0,0,-.105))
fin=rotate(fin,'y',pi/2)
part('S03','斜切尾翼','飞船','tapered_extrude',[.2,3.2,1.6],fin,{'height_m':[2.5,3.4],'cant_deg':[10,22],'edge_m':[.025,.06]},'底部插接舌与机身座','翼缘真实厚度；色带烘进图集','并入飞船静态凸包','倾角与左右版本；色带不改变厚度')
part('S04','座舱罩与舱框','飞船','profile_loft',[1.5,.5,2],shift(box(1.5,.5,2,'dark',.18),(0,0,0))+shift(box(1.22,.32,1.65,'glass',.1),(0,.13,-.06)),{'width_m':[1.2,1.7],'slope_deg':[15,30]},'机背凹槽面','玻璃先用不透明暗面；不建座舱内部','不独立碰撞')
engine=rotate(lathe([(0,.52),(.12,.65),(1.9,.65),(2.1,.52),(2.1,.35)],'dark'), 'x',pi/2);engine+=rotate(ring(.67,.55,.12,'steel'),'x',pi/2);engine+=shift(rotate(ring(.54,.42,.08,'cyan'),'x',pi/2),(0,0,1.85))
part('S05','发动机筒与喷口','飞船','lathe',[1.34,1.34,2.1],engine,{'diameter_m':[.9,1.4],'length_m':[1.8,2.8],'radial_segments':[12,24]},'轴向前后中心；固定法兰','喷口有凹深和环形壁厚；内部叶片烘焙','并入主机身','口径／环数；青环为实体和状态材质')
strut=rod((-.25,0,0),(.2,1.7,0),.13)+rod((-.2,.1,.1),(.1,1.1,.1),.08,'steel')+shift(box(.65,.22,.5,'dark',.04),(0,1.5,0))
part('S06','落架减震腿','飞船','strut',[.65,1.72,.5],strut,{'length_m':[1.4,2],'tilt_deg':[10,25],'piston_ratio':[.3,.55]},'上下铰点，位置由接地解算锁定','轴、套筒、销孔为几何；小刻线为法线','静态简化胶囊，堵住不可通行腹部','长度随落地约束；不随机seed摆歪')
part('S07','落架脚掌与座','飞船','bevel_box',[.9,.26,1.3],panel(.9,.26,1.3)+shift(box(.4,.32,.45,'dark'),(0,.26,0)),{'footprint_m':[.8,1.3],'pad_h_m':[.18,.28]},'底面接地；上部销座','脚缘真实厚度，尘积集中在接触处','单凸包')
part('S08','飞船挂载导轨','飞船','rail_array',[.6,.45,2.4],box(.6,.45,2.4,'dark',.08)+shift(rod((0,.25,-1.2),(0,.25,-2),.07,'steel'),(0,0,0))+shift(box(.48,.22,.6,'orange',.04),(0,.45,.55)),{'length_m':[1.8,2.6],'mount_spacing_m':[.4,.8]},'上部双连接座，附着 S02','先做导轨与炮管大形；小挂钩为法线','不可发射、不独立交互')
# Building modules.
part('B01','外墙实心板','基地','wall_panel',[4,3,.3],panel(4,3,.3),{'width_m':[2,4],'height_m':[3,3],'rib_count':[0,3]},'左右端 X=±W/2；下边 Y=0','大面与角切为几何；浅缝和螺钉入 trim','单盒；背面闭合')
window=box(4,.6,.45)+shift(box(4,.55,.45),(0,2.45,0))+shift(box(.45,1.85,.45),(-1.775,.6,0))+shift(box(.45,1.85,.45),(1.775,.6,0))+shift(box(3.1,1.85,.14,'glass',.08),(0,.6,.05))
part('B02','观察窗墙与暗箱','基地','wall_panel',[4,3,.45],window,{'width_m':[4,4],'recess_m':[.15,.35],'mullions':[1,3]},'与 B01 同端口；窗玻璃为封闭背板','三层窗框和压暗背板；不制作内部桌椅','整墙盒；窗不可通行','窗分格／深度／标号')
part('B03','建筑外转角','基地','corner',[.8,3,.8],shift(box(.3,3,.8),(-.25,0,0))+shift(box(.8,3,.3),(0,0,.25)),{'turn_deg':[90,90],'leg_m':[.8,.8]},'两条正交墙接口；转角共享内外面','内侧封闭，避免拼缝透天','L 形两盒')
# Hollow octagonal frame as bars between two octagonal contours.
def portal(w,h,thick,d,c='shell'):
 poly=[(-w/2+.45,0),(w/2-.45,0),(w/2,.45),(w/2,h-.45),(w/2-.45,h),(-w/2+.45,h),(-w/2,h-.45),(-w/2,.45)]
 out=[]
 for j,a in enumerate(poly):
  b=poly[(j+1)%len(poly)];aa=(a[0]*(1-2*thick/w),(a[1]-h/2)*(1-2*thick/h)+h/2);bb=(b[0]*(1-2*thick/w),(b[1]-h/2)*(1-2*thick/h)+h/2)
  out+=extrude([a,b,bb,aa],d,c)
 return out
part('B04','八角气闸框','基地','ring_extrude',[4.2,4.4,.8],portal(4.2,4.4,.35,.8)+shift(portal(3.65,3.85,.16,.18,'orange'),(0,.275,-.5)),{'width_m':[4,4.5],'height_m':[4.2,4.6],'frame_m':[.25,.4]},'底座中心；内侧门扇平面 Z=+.18','外壳、密封框、门扇三层；必须真洞口','静态框分盒；首版门扇不可穿行','标号／框条；轮廓不随机')
part('B05','封闭气闸门扇','基地','door_panel',[3.1,3.5,.18],box(3.1,3.5,.18,'dark',.35)+shift(box(.06,3.1,.03,'steel'),(0,.2,-.11))+shift(box(.8,.12,.03,'cyan'),(0,2.65,-.11)),{'split':[2,2],'recess_m':[.3,.6]},'门框局部中心；闭合锁定','中缝、密封圈、把手有层次；不预留室内','单盒；关闭门不加入导航')
part('B06','屋顶压顶与斜边','基地','trim_profile',[4,.45,.8],extrude([(-2,0),(2,0),(1.8,.45),(-1.8,.45)],.8),{'length_m':[2,4],'slope_deg':[15,30]},'墙顶 Y=3；端头盖板','边缘折板为几何；细槽用 trim','并入楼体')
part('B07','平台承载板','基地','deck',[4,.25,3],box(4,.25,3,'dark',.08)+shift(box(4,.06,.12,'steel'),(0,.25,-1.44)),{'width_m':[2,4],'depth_m':[2,3],'thickness_m':[.2,.3]},'顶面为通行高程；板底与 B08/B09 相连','防滑纹用法线；边缘和板厚真实','单盒；平台下首版封闭')
part('B08','立柱与柱脚','基地','column',[.65,2.4,.65],box(.65,.18,.65,'dark',.06)+shift(box(.3,2.22,.3,'steel'),(0,.18,0)),{'height_m':[2.4,3],'section_m':[.25,.4],'base_m':[.6,.8]},'脚底 Y=0；柱头顶面接梁底','柱脚与锚栓关系清楚；不能悬空','单盒；脚不侵占路径')
part('B09','承重横梁','基地','beam',[4,.4,.3],box(4,.08,.4,'dark')+shift(box(4,.08,.4,'dark'),(0,.32,0))+shift(box(4,.24,.12,'steel'),(0,.08,0)),{'span_m':[2,4],'beam_h_m':[.3,.5]},'两端中心；上翼板接平台板底','工字截面可读；远景减为单梁','单盒')
ramp=extrude([(-1.5,-.22),(1.5,-.22),(1.5,0),(-1.5,0)],8,'dark');ramp=[([(x,y+(z+4)*.3,z) for x,y,z in f],c) for f,c in ramp]
part('B10','坡道段与侧裙','基地','ramp',[3,2.62,8],ramp,{'rise_m':[2.4,2.4],'run_m':[8,8],'clear_width_m':[3,3.5]},'坡底与坡顶通行表面；终点高差 2.4 m','纵坡 16.7°；踏纹为法线，连续碰撞','单斜面凸体；正式模型需补侧裙与支撑','净宽／踏纹；不随机坡度')
rail=rod((-1.5,0,0),(-1.5,1.1,0),.035,'yellow')+rod((1.5,0,0),(1.5,1.1,0),.035,'yellow')+rod((-1.5,1.1,0),(1.5,1.1,0),.035,'yellow')+rod((-1.5,.55,0),(1.5,.55,0),.025,'yellow')
part('B11','栏杆标准段','基地','rail_array',[3,1.1,.08],rail,{'span_m':[1,3],'height_m':[1.1,1.1],'post_pitch_m':[1,1.5]},'底部柱脚；两端扶手连续','管径真几何；细焊缝入法线','粗代理条；不让细杆卡玩家','平段／坡段按端点生成；不拉伸圆管')
# Industrial modules.
part('I01','压力容器直筒','工业','lathe',[2,4,2],lathe([(0,.9),(.12,1),(3.88,1),(4,.9)]),{'diameter_m':[1.2,2.4],'barrel_length_m':[2,4],'radial_segments':[12,24]},'轴向两端圆口；径向法兰按端口生成','纵向大色块；薄焊缝用法线','单圆柱代理，静态','横竖安装同一局部轴，不改变圆截面')
part('I02','压力容器封头','工业','lathe',[2,.45,2],lathe([(0,1),(.15,.98),(.3,.83),(.42,.5),(.45,.18)]),{'diameter_m':[1.2,2.4],'cap_ratio':[.18,.25]},'端面与 I01 口径相同；中心出气端口','弧顶分段靠轮廓决定；小焊道为法线','并入罐体','拱高／端口；保持密封壁厚')
part('I03','束环与发光状态环','工业','ring',[2.16,.18,2.16],ring(1.08,1,.18,'dark')+shift(ring(1.085,1.07,.055,'cyan'),(0,.06,0)),{'diameter_m':[1.2,2.4],'band_h_m':[.12,.25],'emission_state':[0,1]},'匹配罐体外径；轴向环位','实体箍环承载状态光；不靠 bloom 代替几何','并入静态罐；非交互','普通／过载只变 uniform')
saddle=box(1.9,.25,1.2,'dark',.08)+shift(box(.32,.75,1.2,'steel'),(-.72,.25,0))+shift(box(.32,.75,1.2,'steel'),(.72,.25,0))
part('I04','横罐鞍座','工业','support',[1.9,1,1.2],saddle,{'tank_diameter_m':[1.2,2],'foot_width_m':[1.5,2.2]},'底面接地；上部承托罐底切面','正式版接触弧跟随罐径；不允许罐穿座','单盒代理','鞍弧随罐半径生成')
part('I05','刚性直气管','工业','tube',[.3,2,.3],lathe([(0,.15),(2,.15)],'steel',12),{'outer_diameter_m':[.22,.45],'length_m':[.5,4],'wall_m':[.015,.035]},'P0=(0,0,0) 法线 −Y；P1=(0,L,0) +Y；口径相同','远景实心封口可用；近端需环状壁厚','静态管路分段代理，不单杆卡路','D0.22 / D0.45 两套视觉口径；单位米')
elbow=[]
for j in range(8):
 a=j*pi/16;b=(j+1)*pi/16;elbow+=rod((.6*cos(a),.6*sin(a),0),(.6*cos(b),.6*sin(b),0),.15,'steel',12)
part('I06','九十度气管弯头','工业','curve_tube',[.9,.9,.3],elbow,{'outer_diameter_m':[.22,.45],'bend_radius_m':[.45,.9],'path_segments':[6,10]},'两端切线互相垂直；与 I05 法线对向','连续弧形放样，不能由多段裸接缝拼成','静态合并；弯外净空要测','45° / 90°；弯曲半径至少外径 1.5 倍')
flange=ring(.25,.15,.10,'steel',12)
for j in range(6):flange+=shift(lathe([(0,.025),(.035,.025)],'dark',6),(.205*cos(j*pi/3),.10,.205*sin(j*pi/3)))
part('I07','法兰与连接盘','工业','ring_array',[.5,.135,.5],flange,{'pipe_diameter_m':[.22,.45],'bolt_count':[4,8],'flange_h_m':[.08,.14]},'中心轴与气管同轴，孔径匹配','近端六角螺栓可几何；远端烘焙或删掉','并入管组，非独立碰撞','口径匹配表决定螺栓圈；不随机孔位')
valve=lathe([(0,.15),(.6,.15)],'steel',12)+shift(rotate(ring(.35,.29,.05,'orange',12),'x',pi/2),(0,.3,-.3))+rod((0,.3,0),(0,.3,-.3),.05)
part('I08','阀体与手轮','工业','valve',[.7,.7,.65],valve,{'pipe_diameter_m':[.22,.45],'wheel_d_m':[.45,.7],'wheel_state_deg':[0,90]},'进出管口与手轮轴；状态仅装饰','轮辐近景真实；不暗示新增可操作功能','合并代理，手轮不独立碰撞','手轮方位沿检修侧路，不能朝墙')
cab=box(1.6,2.2,.8,'dark',.12)+shift(panel(1.4,1.8,.08),(0,.2,-.45))+shift(box(.45,.18,.03,'cyan'),(0,1.45,-.51))
part('I09','维修设备柜','工业','cabinet',[1.6,2.2,.94],cab,{'width_m':[.8,1.8],'height_m':[1.2,2.2],'vent_count':[3,9]},'底面；背面管线端口；前方检修净空','柜壳、门盖与内框分层；通风浅槽烘焙','单盒；活动盖单独命中挂点','面板类型／标号／seed；结构不随污渍变形')
exchange=box(1.8,1.8,.35,'dark',.1)
for j in range(10):exchange+=shift(box(.08,1.5,.5,'steel'),(-.75+j/6,.15,-.1))
part('I10','散热器鳍片组','工业','fin_array',[1.8,1.8,.6],exchange,{'width_m':[1.2,2.2],'fin_count':[6,16],'fin_depth_m':[.2,.5]},'机架背面四固定点；侧面管口','近景少量真实鳍片；远景替换法线面板','单盒','鳍片间距有下限；不按纹理分辨率加片')
chassis=box(3,.4,1.8,'dark',.12)+shift(box(3,1.1,1.5,'shell',.25),(0,.4,.15))+shift(box(1.9,.65,.04,'dark',.1),(0,.55,-.62))+shift(rotate(lathe([(0,.38),(1.5,.38)],'steel',12),'z',-pi/2),(-.75,.85,-.8))
part('I11','氧气发生器机架','工业','machine_chassis',[3,1.5,2],chassis,{'width_m':[2.4,3.2],'shell_open_ratio':[.3,.55],'roller_count':[1,2]},'底座；前检修面；侧面氧气与供电口','机壳包芯，开口露出圆筒；不全身黑缝','主机盒；维护盖可独立碎件','壳色／滚筒／检修盖版本')
spool=rotate(lathe([(0,.6),(.08,.6),(.12,.37),(1.0,.37),(1.04,.6),(1.12,.6)],'orange',16),'z',pi/2)+shift(box(1.3,.2,1.3,'dark'),(-.56,-.65,0))
part('I12','软管卷盘','工业','lathe_array',[1.32,1.4,1.3],spool,{'width_m':[.8,1.3],'outer_d_m':[1,1.4],'hose_d_m':[.05,.09]},'卷盘轴；出管口指向维修侧','只做外层 3–5 道软管或法线；不建整盘实管','单盒；软管无小段碰撞','收卷／放出短尾两种；不跨交战路')
# Props, boundary, infrastructure.
crate=box(1.4,1.1,1,'dark',.1)+shift(panel(1.22,.82,.08),(0,.14,-.55))+shift(panel(1.22,.82,.08),(0,.14,.55))+shift(box(1.4,.12,1.05,'shell',.06),(0,1.1,0))
part('P01','储物箱箱体','道具','crate',[1.4,1.22,1.18],crate,{'width_m':[.8,1.8],'height_m':[.6,1.2],'depth_m':[.6,1.2],'rib_count':[0,6],'wear':[0,.12]},'地面 pivot；盖板铰点；堆叠角座','框架真几何；小锁扣与浅划痕图集；月球默认无锈','单盒；完整壳与残架分离','S/M/L 三档、色带、编号、seed；非均匀缩放禁用')
part('P02','检修盖与内框','道具','service_panel',[.8,.8,.1],panel(.8,.8,.1)+shift(box(.12,.3,.06,'dark',.02),(.22,.22,-.08)),{'width_m':[.5,1.2],'height_m':[.5,1.2],'hinge_side':[0,1],'wear':[0,.12]},'铰点在侧边；残架边缘不得变','盖、卡扣与内框；拆下后露芯不变整柜消失','可破坏挂点；小碎片无持久阻挡','左铰／右铰／整块卸下；与母体 ID 绑定')
part('P03','低掩体标准段','边界','barrier',[3,1.1,.8],extrude([(-1.5,0),(1.5,0),(1.5,.7),(1.25,1.1),(-1.25,1.1),(-1.5,.7)],.8)+shift(box(1.2,.15,.03,'orange'),(-.4,.45,-.42)),{'length_m':[2,3],'height_m':[.9,1.2],'depth_m':[.65,.9]},'左右端端盖；底面完整接地','顶部斜切真实；铭牌用图集','单凸包；保持掩体高度不随seed变','直段／短段／端盖；不随破坏减少主遮挡')
part('P04','外围矮墙与端柱','边界','perimeter',[4,1.1,.5],box(4,1,.35,'shell',.08)+shift(box(.4,1.1,.5,'dark',.04),(-1.8,0,0))+shift(box(.4,1.1,.5,'dark',.04),(1.8,0,0)),{'length_m':[2,4],'height_m':[1,1.2],'corner_deg':[45,90]},'端柱中心连接；地面高差用基脚补','短墙不等于地图硬边界；后接岩崖实体封闭','墙盒 + 外圈地形不可通行','直／45°角／90°角；斜条控制频率')
part('P05','道路灯柱','设施','light',[.35,1.3,.35],box(.35,.12,.35,'dark',.03)+shift(box(.16,1.05,.16,'steel'),(0,.12,0))+shift(box(.3,.14,.3,'cyan',.03),(0,1.17,0)),{'height_m':[.6,1.4],'lamp_type':[0,1],'emission':[0,1]},'柱脚；灯朝路侧，不给每盏建 PointLight','灯罩实体+自发光；少数关键灯带实际落光','并入路缘；低碰撞避免卡路','暖白／青；光源另由总装预算管理')
mast=box(.7,.25,.7,'dark',.06)+shift(box(.32,2.4,.32,'shell',.04),(0,.25,0))+rod((0,2.65,0),(0,4,0),.035,'steel')+shift(box(.28,.35,.28,'orange'),(0,2.25,0))
part('P06','天线分节桅杆','设施','mast',[.7,4,.7],mast,{'height_m':[3,6],'sections':[2,4],'rod_d_m':[.05,.09]},'基座中心；侧接控制盒；顶端信标','粗细递减，不能靠发光点撑轮廓','基座代理；屋顶版并入楼体','屋顶／地面台；不制作常态摆动')
dish=[]
profile=[(.0,.06),(.04,.3),(.17,.65),(.43,1),(.5,1.03)]
for offset,back in [(0,False),(-.045,True)]:
 for k in range(len(profile)-1):
  for j in range(24):
   ps=[]
   for kk,jj in [(k,j),(k,j+1),(k+1,j+1),(k+1,j)]:
    yy,rr=profile[kk];aa=jj*2*pi/24;ps.append((rr*cos(aa),yy+offset,rr*sin(aa)))
   dish.append((list(reversed(ps)) if back else ps,'dark' if back else 'shell'))
dish+=shift(ring(1.05,1.015,.06,'steel',24),(0,.455,0))+rod((0,.03,0),(0,1,0),.045,'dark')
part('P07','通信碟与馈源','设施','lathe_dish',[2.06,1,2.06],dish,{'diameter_m':[1.6,2.8],'depth_ratio':[.18,.25],'tilt_deg':[25,55]},'背部支臂轴；馈源沿碟轴','浅碟外表与厚边；背筋可简化；设计代理不作电磁复现','并入天线台','安装倾角／外径；锁定朝向防遮挡')
solar=box(3,.1,1.8,'dark',.03)
for x in range(3):
 for z in range(2):solar+=shift(box(.92,.025,.82,'glass',.02),(-.98+x*.98,.1,-.44+z*.88))
part('P08','太阳能板单元','设施','panel_array',[3,.125,1.8],solar,{'cols':[2,4],'rows':[2,3],'panel_pitch_m':[.8,1],'tilt_deg':[25,40]},'背部双安装轨；支架接地','格分烘焙为主；外框和板厚几何；低闪烁反射','侧景单代理','2×3 / 2×4；调整数量而非拉伸板片')
brace=rod((-.8,0,0),(.8,1.8,0),.065,'yellow')+rod((.8,0,0),(-.8,1.8,0),.065,'yellow')+rod((-.8,0,0),(-.8,1.8,0),.08)+rod((.8,0,0),(.8,1.8,0),.08)
part('P09','工业台架斜撑','设施','brace',[1.8,1.95,.2],brace,{'bay_m':[1.5,3],'height_m':[1.5,3],'tube_d_m':[.1,.18]},'四角节点与平台梁同轴','三角支撑真实；螺栓不每根独立节点','分盒；设备底部封闭','X撑／单斜撑；不得横穿走廊')
pad=box(4,.16,4,'dark',.08)+shift(box(3.6,.02,.16,'orange'),(0,.16,-1.55))
part('P10','停机坪边板','设施','deck',[4,.18,4],pad,{'module_m':[2,4],'edge_band_m':[.1,.2]},'水平顶面；角块按局部轮廓生成','接缝真实但浅；H标与橙环烘焙或共面贴片','单盒；细缝不做碰撞','直边／角块／地标面；不加全地面镜像反射')
rock=lathe([(0,.7),(.15,1),(.6,.85),(1.1,.4)],'soil',7);rock=[([(x*(1+.12*sin(y*7+z)),y,z*(1+.15*cos(x*8))) for x,y,z in f],c) for f,c in rock]
part('P11','月岩与边缘石群','地形','rock_profile',[2,1.1,2],rock,{'radius_m':[.4,2.5],'height_ratio':[.4,1.2],'seed':[0,9999]},'底面嵌地 0.05–0.15 m；不悬浮','轮廓起伏几何；颗粒与色斑烘焙/低成本贴图','外圈简凸包，路内小石无碰撞','固定 seed 石型 4–6 个；不随机堵出生点')
can=lathe([(0,.24),(.08,.3),(1,.3),(1.08,.24)],'shell',12)+shift(ring(.31,.29,.06,'cyan',12),(0,.85,0))+shift(box(.2,.13,.15,'dark',.03),(0,1.08,0))
part('P12','便携补给罐','道具','lathe',[.62,1.21,.62],can,{'diameter_m':[.35,.6],'height_m':[.6,1.2],'cap_type':[0,1]},'地面；阀帽；搬运夹具接口','壳、底环、盖清楚；默认非爆炸氧气罐','单胶囊；普通可拆壳，不赋范围伤害','短／长罐、色环、seed')
# Reusable assembly recipes. Each uses the same meshes as all five-view sheets.
BY={p['id']:p for p in PARTS}
def instance(i,p=(0,0,0),r=None,s=(1,1,1)):
 m=scale(BY[i]['mesh'],s)
 if r:
  for axis,a in r:m=rotate(m,axis,a)
 return shift(m,p)
def assembly(i,name,instances,description,placement,collider):
 mesh=[];bom=[]
 for row in instances:
  pid,p,*rest=row;r=rest[0] if rest else None;ss=rest[1] if len(rest)>1 else (1,1,1)
  mesh+=instance(pid,p,r,ss);bom.append({'part':pid,'position':p,'rotation':r,'design_scale':ss})
 ASSEMBLIES.append(dict(id=i,name=name,description=description,placement=placement,collision=collider,bom=bom,mesh=mesh))
ship=[('S01',(0,1.8,0)),('S04',(0,2.95,-2.2)),('S02',(-3.6,2,.7),None,(-1,1,1)),('S02',(3.6,2,.7)),('S03',(-2,2.4,2),[('z',-.2)]),('S03',(2,2.4,2),[('z',.2)]),('S05',(-1.2,2,2.2)),('S05',(1.2,2,2.2))]
for x,z in [(-2.6,1.8),(2.6,1.8),(0,-2.2)]:ship.extend([('S07',(x,0,z)),('S06',(x,.58,z))])
for x in [-4,4]:ship.append(('S08',(x,2.2,.6)))
assembly('A01','飞船总装',ship,'机身 → 翼根 → 双翼 → 尾翼 → 发动机 → 三点落架 → 挂载。外观代理需按 11×14 m 目标占地在灰盒定稿，不能反向拉伸完成品。',(-12.5,0,-1),'飞船主壳与落架合并代理；腹部不通行，周边路宽 ≥3.5 m。')
base=[('B04',(0,2.4,0),[('y',pi)]),('B05',(0,2.8,-.3),[('y',pi)]),('B02',(0,6.8,-1),[('y',pi)]),('B07',(0,6.55,-1.5)),('B06',(0,9.8,-1)),('P07',(0,10.25,-1),[('x',-.5)]),('P06',(-6,5.85,-3))]
for x in [-10,-6,6,10]:base.extend([('B01',(x,2.4,-.2),[('y',pi)]),('B06',(x,5.4,-.7)),('B07',(x,2.15,1.5)),('B08',(x,0,1.5),None,(1,1.75/2.4,1)),('B09',(x,1.75,1.5))])
for x in [-2,2]:base.extend([('B07',(x,2.15,1.5)),('B08',(x,0,1.5),None,(1,1.75/2.4,1)),('B09',(x,1.75,1.5))])
for x in [-3,3]:base.append(('B01',(x,2.4,-.2),[('y',pi)],(.5,1,1)))
for x in [-10,-6,-2,2,6,10]:base.extend([('B01',(x,2.4,-5)),('B06',(x,5.4,-4.5))])
for x in [-1.5,5]:base.append(('B10',(x,0,7),[('y',pi)]))
for x in [-9,9]:base.append(('B11',(x,2.4,3)))
base.extend([('B03',(-12,2.4,-4.8)),('B03',(12,2.4,-4.8),[('y',pi)])])
assembly('A02','基地外立面与平台',base,'只做外墙、封闭门扇、窗后暗箱、屋顶设备与室外平台；窗后不铺室内、不放室内灯家具。前墙朝世界 +Z；背墙与转角示意闭合方向，正式顶面和侧向封闭体须在样板补齐。',(0,0,-18),'整栋为封闭实体；平台 Y=2.4，板底 Y=2.15、梁底/柱顶 Y=1.75；双坡从 Z=-15 到 -7，平台下不开放。')
oxygen=[]
for x in [-1.8,1.8]:
 oxygen.extend([('I01',(x,2,0)),('I02',(x,6,0)),('I03',(x,2.5,0)),('I03',(x,5.5,0)),('P09',(x,0,0))])
oxygen.extend([('I09',(0,0,1.8)),('I05',(-1.8,6.3,0),[('z',-pi/2)],(1,1.8,1)),('I06',(1.8,6.3,0),[('z',pi)]),('B11',(0,2,-1.4))])
assembly('A03','双塔氧气分离组',oxygen,'两塔共用直筒、封头、束环；管线端口驱动连接；塔架跟随罐脚而非自由撒摆。装配图为构图代理，正式管口需按端口系统求解。',(16,0,-10),'9×20 m 工业带北段；检修面朝西，塔架下封闭不让玩家钻入。')
assembly('A04','横罐储气组',[('I01',(-2,1.9,0),[('z',-pi/2)]),('I02',(2,1.9,0),[('z',-pi/2)]),('I02',(-2,1.9,0),[('z',pi/2)]),('I04',(-1.3,0,0)),('I04',(1.3,0,0)),('I07',(2.4,1.9,0),[('z',-pi/2)]),('I08',(2.7,1.6,0))],'与竖塔共享旋转体内核，改变轴向、筒长、鞍座与法兰预设；不是拉长竖塔整组。',(16,0,2),'工业带中段；罐前侧净宽 ≥3 m，阀轮朝维修面，不做默认爆炸桶。')
assembly('A05','氧气发生器与卷管站',[('I11',(0,0,0)),('I12',(2.2,.65,-.2)),('P12',(-2,0,0)),('P12',(-2.8,0,0)),('P02',(.5,.55,-.7)),('P03',(-2.4,0,-.8),None,(.6,.5,.6))],'主机壳包滚筒，两罐与卷盘组成一个用途组；维护盖有完整/残架/碎片三态。',(10,0,15),'南侧景观岛，避开玩家起点视线；软管只在岛内，不跨路。')
assembly('A06','天线通信台',[('B07',(0,0,0),None,(.6,1,.7)),('B08',(0,.25,0)),('P07',(0,2.65,0),[('x',-.55)]),('P06',(1.2,.25,.5),None,(.8,1,.8)),('I09',(-1.1,.25,.5),None,(.5,.6,.7))],'平台、立柱、碟面、馈源、桅杆和控制盒组成。背侧走线用细软管，不开独立导航层。',(-10,0,-20),'屋顶装在承重梁上；地面版靠外圈，不放中央交战线。')
assembly('A07','太阳能支架组',[('P09',(-.9,0,0)),('P09',(.9,0,0)),('P08',(0,1.8,0),[('x',-.5)]),('I09',(1.8,0,0),None,(.5,.5,.6))],'面板单元按列复制，支腿角度适配倾角；先确认面板朝向不产生战区闪点。',(19,0,-16),'工业区外缘低对比侧景，不提供发电操作；面板不得成为可攀跳捷径。')
assembly('A08','储物箱与补给组',[('P01',(0,0,0)),('P01',(-1.8,0,0),None,(.75,.75,.75)),('P01',(.2,1.22,0),None,(.65,.65,.65)),('P12',(1.3,0,.4)),('P12',(2,0,.4)),('P02',(-1.8,.2,-.47),None,(.6,.6,1))],'箱体通过预设尺寸重建而非正式模型非均匀缩放。图中缩比只表达摆放意图；盖板对接母体、重开恢复。',(-9,0,15),'最多三处小组；堆叠总高 ≤1.8 m，避免把两组拼成全高连续墙。')
assembly('A09','中央错位掩体岛',[('P03',(-2,0,0)),('P03',(2,0,2),[('y',pi/2)]),('P05',(-3.5,0,.5)),('P01',(.5,0,-1.8),None,(.7,.7,.7))],'长短错位留两条出口，物体朝向解释站位；同一掩体不同时布满色条、铭牌和高光。',(0,0,4),'0.9–1.2 m 掩体，中央主路 ≥3.5 m；不因破坏主壳改变掩体高度。')
assembly('A10','外围矮墙与崖边',[('P04',(-4,0,0)),('P04',(0,0,0)),('P04',(4,0,0)),('P05',(-2,1.1,0),None,(.65,.5,.65)),('P11',(5,0,1.5),None,(1.4,1.5,1.4)),('P11',(-5,0,1.5))],'直墙、端柱与斜角段连成边界；墙后用崖体/岩壁堵出界。矮墙本身不能假装玩家跳不过。',(0,0,22),'场地外圈；连续高度或形体阻挡与视觉边界一致，不靠看不见的空气墙。')
assembly('A11','停机坪与灯带',[('P10',(-2,0,-2)),('P10',(2,0,-2)),('P10',(-2,0,2)),('P10',(2,0,2)),('P05',(-4,0,-4)),('P05',(4,0,4))],'模块化板面、角块、灯柱和共面地标构成；轮廓按停机坪边界扩展，图为 8×8 m 片段而非最终全坪。',(-12.5,0,-1),'按船脚位置校准停机坪高程；边缘允许走，不让细电缆阻挡胶囊。')
assembly('A12','工业维修管桥',[('B08',(-2,0,0),None,(1,1.75,1)),('B08',(2,0,0),None,(1,1.75,1)),('B09',(0,3.8,0)),('I05',(-2,4.35,0),[('z',-pi/2)],(1,2,1)),('I06',(2,4.35,0),[('z',pi)]),('I09',(2,0,.8),None,(.65,.7,.8))],'梁、柱与气管分工：梁承重，管夹固定；正式图用支架端口补齐管夹。通行处优先从高处或侧墙绕接。',(16,0,-3),'跨通行路径时净空目标 ≥3.8 m，并按跳跃最高点实测；不能仅以视高 1.65 m 判安全。')
# Projection from shared, dimensioned geometry. No independent AI views.
VIEWS=[('FRONT / -Z',(1,0,0),(0,1,0),(0,0,-1)),('REAR / +Z',(-1,0,0),(0,1,0),(0,0,1)),('LEFT / -X',(0,0,-1),(0,1,0),(-1,0,0)),('RIGHT / +X',(0,0,1),(0,1,0),(1,0,0)),('TOP / +Y',(1,0,0),(0,0,-1),(0,1,0))]
ISO_CAM=unit((1,1.2,1));ISO_U=unit((1,0,-1));ISO=('ASSEMBLY',ISO_U,unit(cross(ISO_CAM,ISO_U)),ISO_CAM)
def project(m,view,x,y,w,h,common_scale=None):
 name,u,v,cam=view;ps=[p for f,c in m for p in f];a=[dot(p,u) for p in ps];b=[dot(p,v) for p in ps];amin,amax,bmin,bmax=min(a),max(a),min(b),max(b)
 ss=min((w-44)/max(.1,amax-amin),(h-60)/max(.1,bmax-bmin)) if common_scale is None else common_scale
 cx=x+w/2-(amin+amax)*ss/2;cy=y+h/2+(bmin+bmax)*ss/2+7
 p2=lambda p:(cx+dot(p,u)*ss,cy-dot(p,v)*ss)
 polys=[]
 for f,c in m:
  n=unit(cross(sub(f[1],f[0]),sub(f[2],f[0])))
  if dot(n,cam)<-1e-7:continue
  depth=sum(dot(p,cam) for p in f)/len(f);light=.72+.28*max(0,dot(n,unit((-.4,1,-.6))));hexv=COLORS[c].lstrip('#');rgb=[int(hexv[i:i+2],16) for i in (0,2,4)];fill='#'+''.join(f'{min(255,round(z*light)):02x}' for z in rgb)
  coords=' '.join(f'{a:.2f},{b:.2f}' for a,b in map(p2,f));polys.append((depth,f'<polygon points="{coords}" fill="{fill}" stroke="#344958" stroke-width=".65" stroke-linejoin="round"/>'))
 body=f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="#f1f4f1" stroke="#c7d2d4"/><text x="{x+16}" y="{y+24}" font-size="13" fill="#334b5c">{name}</text>'
 body+=''.join(q for z,q in sorted(polys,key=lambda z:z[0]))
 if name!='ASSEMBLY':
  yy=y+h-17;xl=x+22;xr=x+w-22
  body+=f'<path d="M{xl} {yy}H{xr}m-5 -4l5 4l-5 4M{xl+5} {yy-4}l-5 4l5 4" fill="none" stroke="#6f8f9a"/><text x="{x+w/2}" y="{yy-6}" text-anchor="middle" font-size="11" fill="#466373">{amax-amin:.2f} m horizontal / {bmax-bmin:.2f} m vertical</text>'
 return body

def sheet(p):
 m=p['mesh'];mn,mx=bounds(m);maxdim=max(mx[k]-mn[k] for k in range(3));ss=min(270,360/maxdim,220/maxdim)
 # Same pixels per metre for all five orthographic panels; ISO uses fit.
 body=f'<rect width="1440" height="1050" fill="#e6ece9"/><text x="36" y="48" font-size="26" fill="#193748">{p["id"]} / {html.escape(p["name"])}</text><text x="36" y="78" font-size="14" fill="#466373">FIVE ORTHOGRAPHIC VIEWS / metres / design proxy v1 / same scale / solid colours are material IDs</text>'
 positions=[(30,110),(500,110),(970,110),(30,430),(500,430)]
 for view,(x,y) in zip(VIEWS,positions):body+=project(m,view,x,y,440,300,ss)
 body+=project(m,ISO,970,430,440,300)
 body+=f'<text x="36" y="782" font-size="18" fill="#193748">X {mx[0]-mn[0]:.2f} m   Y {mx[1]-mn[1]:.2f} m   Z {mx[2]-mn[2]:.2f} m</text><text x="36" y="814" font-size="14" fill="#466373">Origin: shared local coordinates; front = -Z, up = +Y. Top view: -Z toward page top.</text>'
 for j,(label,text) in enumerate([('PORTS',p['ports']),('DETAIL',p['detail']),('COLLISION',p['collision']),('VARIANTS',p['variants'])]):body+=f'<text x="36" y="{858+j*35}" font-size="15" fill="#334b5c">{label}: {html.escape(text)}</text>'
 body+='<text x="36" y="1024" font-size="12" fill="#6b7f89">Planning drawing only. Not a production mesh, construction engineering drawing or measured reconstruction of the AI image.</text>'
 return '<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="1050" viewBox="0 0 1440 1050">'+body+'</svg>'

def asm_sheet(a):
 body='<rect width="1440" height="900" fill="#e6ece9"/>'
 body+=f'<text x="36" y="48" font-size="26" fill="#193748">{a["id"]} / {html.escape(a["name"])}</text><text x="36" y="78" font-size="14" fill="#466373">Assembly hierarchy / design proxy / use component IDs to locate five-view sheets</text>'
 body+=project(a['mesh'],ISO,30,105,920,650)
 counts={}
 for r in a['bom']:counts[r['part']]=counts.get(r['part'],0)+1
 body+='<text x="985" y="140" font-size="20" fill="#193748">BILL OF COMPONENTS</text>'
 for j,(pid,n) in enumerate(counts.items()):body+=f'<text x="985" y="{180+j*33}" font-size="16" fill="#334b5c">{pid} × {n} / {html.escape(BY[pid]["name"])}</text>'
 # Width limited narrative in HTML; drawing remains concise.
 body+='<text x="36" y="810" font-size="14" fill="#466373">Placement diagram. Detail joints and non-overlapping ports must be resolved in the production model.</text><text x="36" y="844" font-size="14" fill="#466373">No base interiors. Closed doors, opaque window backings, exterior supports only.</text>'
 return '<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="900" viewBox="0 0 1440 900">'+body+'</svg>'

if __name__=='__main__':
 for p in PARTS:(OUT/'sheets'/f'{p["id"]}.svg').write_text(sheet(p))
 for a in ASSEMBLIES:(OUT/'assemblies'/f'{a["id"]}.svg').write_text(asm_sheet(a))
 data={'version':'1.1','status':'design_proxies_only','axes':{'front':'-Z','up':'+Y','units':'m'},'view_count':5,'parts':[{k:v for k,v in p.items() if k!='mesh'} for p in PARTS],'assemblies':[{k:v for k,v in a.items() if k!='mesh'} for a in ASSEMBLIES]}
 (OUT/'kit.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({'parts':len(PARTS),'views':len(PARTS)*5,'assemblies':len(ASSEMBLIES),'svg_bytes':sum(p.stat().st_size for p in OUT.rglob('*.svg'))}))
