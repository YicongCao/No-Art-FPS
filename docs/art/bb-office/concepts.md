# BB 公司写字楼概念图

内置 imagegen 概念稿。以俯视总览统一空间位置，地面图用于确认机位、材质和道具。公司标志墙设在南侧入口玻璃门对面。

- [俯视总览](overview.png)
- [开放工位](workstations.png)
- [会议室、电话间与经理室](rooms.png)
- [茶水与零食区](pantry.png)
- [入口与 BB 公司标志墙](entrance.png)
- [受击特效](impact-fx.png)

主厅由六组低隔断工位组成。两条贴玻璃幕墙的路线通过工位之间的横向通道连通。入口一侧是前台和茶水区，另一端是两间经理室、电话间和默认开门的会议室。行军床放在工位侧面的凹位，留出走道。

工位靠设备辨识。程序员用三块代码屏，PM 用显示瀑布模型的笔记本，经理室的老板桌上只放显示上涨图表的平板。QQ 企鹅、林克手办和跑车模型分散摆放。

受击图从左到右、从上到下依次是纸张和便签、键帽和屏幕故障、薯片和包装碎片、咖啡和杯片、木门和把手、遮光叶碎片。制作时每次只让少量碎片在命中点附近短暂飞散。

## 生成提示词

参考图使用[演播厅实机截图](../../../artifacts/readme/studio-frenzy.png)和演播厅纸张受击截图。每张图使用共用提示加对应机位提示。

> Use case: stylized-concept. Make one wide 16:9 concept image for a new indoor arena in the game No-Art-FPS, inside one floor of a city tech office called BB 公司. Image 1 is a reference for the game's actual low-poly, strong color blocks, thin dark outlines and readable shapes. Image 2 is the game's actual paper-hit VFX reference. Do not reproduce either image's TV stage, archive or HUD. All views are the same office: daylight through full-height glass curtain walls on the left and right long façades, with a blue-gray blocky city skyline outside; ivory laminate desks, teal acoustic cubicle partitions, navy columns and frames, pale gray carpet tiles, muted plum meeting-room wall, small orange accents, and warm-white linear ceiling light sticks. One open-plan single floor, two walkable window-side routes linked by central cross aisles between cubicle pods, reception and entry glass doors at the south end, an L-shaped snack pantry nearby, and along the north end exactly two individual manager rooms with closed timber doors, two small phone booths and a large shared meeting room with an open door. Plausible walkable FPS scale and clear paths. Render like a game that can actually run in Godot: bold silhouettes, low polygon count, flat shading, angular highlights, restrained transparency, little texture noise. Keep the office colorful and bright with strong readability. No people, gun, HUD, caption, watermark or arbitrary brand signage. The only requested architectural lettering, where visible, is “BB 公司”.

**俯视总览**

> Bird's-eye three-quarter cutaway of the whole floor like a low-poly playable architectural model. Camera above the south entry looking north, roof removed and ceiling lights indicated only over a small strip so the layout stays readable. South bottom-center: shallow lobby with “BB 公司” logo wall facing the framed glass entry doors, pantry in the south-west corner. Center: six clusters of low cubicles with broad straight aisles and two obvious cross aisles. East and west sides: blue glass façades and uninterrupted loop lanes, daylight and the skyline. North: open meeting room centered with long table and chairs, visible projector and television on separate surfaces; a pair of small colored phone booths beside it and one shut timber-door manager office to each outer side, each with a desk and tablet. Show a few green leaf light shades and two tucked-away fold-out camping cots, no floor plan symbols or room labels. Emphasize actual connections and cover heights.

**开放工位**

> First-person eye-level view from a central cross aisle, framed to compare desks at walking distance. Foreground left is a recognizable programmer station with THREE monitors (dark screens, cyan and mint syntax-highlighted code with visible indentation and braces), a QQ penguin figurine in red scarf, and a small green-clad Link action figure. Foreground right is a PM station with ONE open laptop showing a clearly stepped five-stage waterfall process diagram, blue blocks and connector arrows sloping downward; a palm-sized red sports-car model sits beside it. Beyond a few cubicle pods, show ONE deployed folding camping cot tucked into a side bay, with a large black-and-white penguin pillow. Two broad IKEA-style green leaf canopies shade individual desks from suspended warm white light sticks, and a few cots and leaves in the distance are enough. Keep the main aisle clear and reveal both glass façades behind the desk islands. Use natural short sightlines and let objects tell the jobs without text labels.

**会议室、电话间与经理室**

> Human eye-level view at the north cross aisle, looking through a visibly OPEN meeting-room door. Composition must also show one closed manager office timber door to the left and another closed timber door on the right along the same circulation spine, plus two recognizable narrow glass-sided acoustic phone booths near the right foreground. Show meeting room clearly: long table, chairs, distinct ceiling-mounted physical projector, a projection screen on a side wall and a separate large flat-panel television on the end wall. Through a glass sidelight next to the nearest closed manager door, make its tidy executive desk legible: a SINGLE tablet on a stand, bright green bars and an upward line across its screen; no desktop monitors in manager rooms. Same teal cubicle edge in foreground and softly shaded navy accents. Door handles and panels should read clearly as physical breakable wood, intact in this view.

**茶水与零食区**

> Human eye-level wide view of the south-west office pantry, the same office and daylight. L-shaped cream and teal counter with a recognizable espresso machine with two spouts, coffee cups, a recessed stainless-steel sink and faucet. To the left a waist-height open snack shelf displays individually visible colorful potato-chip bags with simple flat chip illustrations and no invented text or brands. A small snack table and stools hug the wall. A nearby window-side aisle remains clearly passable. At the back, see teal partitions, linear light sticks and blue city glazing through the open side of this alcove. Make the pantry compact and everyday, not a restaurant. The coffee machine, sink and chips each get their own clear silhouette.

**入口与 BB 公司标志墙**

> Human eye-level view from just inside the south end of the work area, looking OUT through the framed transparent glass entry double doors toward the small reception lobby opposite them. The lobby has one broad muted plum logo wall with the large, crisp, EXACT lettering “BB 公司” (uppercase B B, then Chinese 公 司), centered and unobstructed, and one simple small geometric emblem if needed. No other text anywhere. Glass edges and handles catch cyan highlights, one leaf slightly ajar so the entry reads clearly. Cubicle edge and one ceiling light stick are visible at the near edges, with angular city buildings through a side glass façade and a glimpse of the pantry to the left. Clean composition suitable as a map thumbnail; walkable corridor and logo are the focus.

**受击特效**

> One 16:9 contact sheet of exactly six equally sized game VFX study frames in two rows of three, thin dark gutters, no labels, no text or HUD. Each is a tight three-quarter freeze frame of the same low-poly office and one short readable bullet impact. Top left: a programmer desk hit sends ivory printouts, square sticky notes and one pen briefly spiraling in a tight cone. Top middle: a keyboard and code screen hit ejects several square keycaps and a few cyan pixel sparks with a quick horizontal glitch strip on the screen. Top right: a snack bag punctures and sends a small fan of angular golden potato-chip fragments and a flap of colored wrapper. Bottom left: impact to a porcelain mug beside the espresso machine sends small cream ceramic chips and two stylized coffee arcs. Bottom middle: one manager timber door breaks inward during the destructive phase, short angular wood splinters and a loose metal handle, with the opening briefly visible. Bottom right: a large green leaf shade at a cubicle is clipped, sending two or three sharp leaf fragments that catch the strip light. Match the reference paper hit with a low count of chunky outlined particles, each burst local to its target, different material silhouettes and colors. No fireballs, blood or explosions that fill the room.
