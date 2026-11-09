# 霍格沃茨地图概念图

内置 imagegen 生成。四张图用同一张初稿作为地形、建筑和画风参考。鸟瞰图作为布局基准，三个地面视角用于看地标和动线。

- [上帝鸟瞰图](overview.png) · 北侧高地是城堡，左下是魁地奇球场，右下是霍格莫德，海格小屋在林坡上。
- [魁地奇球场与观礼台](quidditch.png) · 椭圆草坪两端各三只球环，外圈有木制观众席，东侧观礼台旁是四面学院礼旗。
- [城堡与格兰芬多塔楼](castle.png) · 中央石阶通向露台和大礼堂。红旗塔楼位于左侧，黑湖石桥从城堡西侧伸出。
- [霍格莫德村与海格小屋](hogsmeade.png) · 村道经过暖窗、商铺和石拱门，支路沿石阶通往林间小屋与南瓜地。

建议白模验证一条主环线：球场 → 城堡前庭 → 海格小屋 → 霍格莫德 → 球场。保留南侧横路和上城堡的侧坡，球场负责开阔交战，村巷负责近战。地面图是气氛与取景参考，距离、高差和建筑遮挡以鸟瞰和后续白模为准。

## 生成提示词

先用内置 imagegen 生成一张低角度航拍初稿，固定城堡、球场、村庄和小屋的相对位置。以下共用提示和对应机位提示以该初稿为参考。

> Create one new 16:9 landscape concept render of the SAME compact Hogwarts arena in the attached visual reference. The attachment is a style, architecture, and site-layout reference. Retain its saturated matte low-poly 3D, cel shading, crisp fine dark comic outlines, violet dusk sky, amber-lit windows, honey stone, navy slate roofs, emerald turf. A clean in-engine level art target for No-Art-FPS, modular and readable. No text, no UI, no watermarks, no characters, no guns, no frame dividers. Keep geography consistent: castle and Gryffindor tower to the north, oval Quidditch pitch to the southwest, Hogsmeade to the southeast, Hagrid's hut between village and castle on the pine slope at the east, Black Lake northwest.

**上帝鸟瞰图**

> New camera only: true high god-view, orthographic axonometric with elevation approximately 72 degrees downward. North top, south bottom, almost a plan view with a small amount of vertical sides. The horizon is OUTSIDE the frame. Pull back until the entire castle footprint, all its tower tips, the entire oval pitch, the whole village and complete lower ring route fit comfortably with margin on all sides. Make the path hierarchy and vertical connections unmistakable. Castle: dominant scarlet-banner Gryffindor tower upper left, Great Hall behind broad southern courtyard, stone bridge extending west over the lake. Pitch: six brass goal rings (three at each end), wood stands around turf and separate roofed ceremonial pavilion on its east side, four separate house flagpoles with scarlet lion, yellow badger, blue eagle, green serpent flags. Southeast village high street. Round hut with pumpkins in the gap above the village. Main routes in warm limestone visibly link all four, with a cross connector at the south and a stair plus a curved walk joining the upper terrace. Full landscape map, no boundary frame.

**魁地奇球场与观礼台**

> Camera at walking height, 1.7 m above the near southwest end of the Quidditch turf, looking diagonally northeast. The oval grass pitch and opposing three brass hoop goals lead the eye into the image. On the right is the prominent tiered timber spectator seating and a clearly separate raised, roofed ceremonial viewing stand with front stairs and a balcony. Beside that pavilion four full flagpoles with large flags, in this order: Gryffindor scarlet and gold lion, Hufflepuff golden yellow and black badger, Ravenclaw blue and bronze eagle, Slytherin emerald green and silver serpent. Leave walking aisles under the bleachers and at the perimeter. Far behind the pitch, the Hogwarts castle including the scarlet-bannner tower rises on the northern ridge. At least one set of three goal hoops very easy to count. Foreground reads like playable FPS space. Wide lens, architectural scene, no weapon or game UI.

**城堡与格兰芬多塔楼**

> Eye-level wide lens from the midpoint of the central castle staircase, coming uphill into the castle's south forecourt. Central stone terrace, warm lanterns, circular winged statue, low ramparts, an archway and a second walkable side ramp. The tall Gryffindor Tower with scarlet-gold hanging lion banners is unmistakable to the left, the vaulted great hall with luminous pointed windows to the right, the stone bridge and Black Lake glimpsed through the western stone opening far left. Show substantial ground, archways and alternate paths for traversal, full height tower silhouette with breathing room near the top. Honey masonry and simple blocky trim, dusk gradient between slate-blue roof silhouettes.

**霍格莫德村与海格小屋**

> Camera at first-person walking height in Hogsmeade's southeast cobbled high street, looking uphill to the northwest. Foreground framing with crooked timber-and-stone storefronts, staggered slate gables, warm glowing bay windows, outdoor barrels and archway with a lane splitting left and right. Make Hagrid's iconic round stone hut with a conical roof, single tall chimney and oversized pumpkins clearly visible uphill beyond the nearest storefronts in a separate fenced clearing at center-left near pines. The curved path and low stone stair leading to the hut must be visible, and the castle and its scarlet-banner tower peek over far rooftops to the upper left. Show a playable cobbled lane in the foreground with believable width. No readable signs; small blank hanging shop sign shapes only.
