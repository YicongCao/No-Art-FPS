# 成就徽章 Review

[打开 HTML 审阅版](achievement-badges.html)

共 15 枚，按标题页摆放顺序排列。中英文说明沿用游戏原文，文末补充实际计数口径。

1. <img src="../../assets/ui/achievements/first.svg" width="24" height="24" alt="第一滴血徽章"> **第一滴血 · FIRST BLOOD**
   - 完成首次战斗击杀
   - First combat kill
2. <img src="../../assets/ui/achievements/headshot.svg" width="24" height="24" alt="爆头专家徽章"> **爆头专家 · PINPOINT**
   - 累计完成 12 次爆头击杀
   - 12 headshots across rounds
3. <img src="../../assets/ui/achievements/triple.svg" width="24" height="24" alt="三连击徽章"> **三连击 · TRIPLE TAP**
   - 在 1.25 秒内完成 3 次击杀
   - 3 kills within 1.25 seconds
4. <img src="../../assets/ui/achievements/barrel.svg" width="24" height="24" alt="一桶搞定徽章"> **一桶搞定 · BARREL DEAL**
   - 用油桶爆炸击杀 1 名敌人
   - Kill an enemy with an oil barrel explosion
5. <img src="../../assets/ui/achievements/yard.svg" width="24" height="24" alt="货场值班徽章"> **货场值班 · YARD SHIFT**
   - 在一局货场中完成 12 次战斗击杀
   - 12 combat kills in one yard round
6. <img src="../../assets/ui/achievements/park.svg" width="24" height="24" alt="末班游乐徽章"> **末班游乐 · LAST RIDE**
   - 在游乐园的一次狂暴模式中完成 5 次击杀
   - 5 kills in one park DESTROY ALL phase
7. <img src="../../assets/ui/achievements/ferry.svg" width="24" height="24" alt="涨潮时刻徽章"> **涨潮时刻 · HIGH TIDE**
   - 在一局渡轮地图中从高处完成 3 次击杀
   - 3 kills from high ground on the ferry in one round
8. <img src="../../assets/ui/achievements/studio.svg" width="24" height="24" alt="节目停播徽章"> **节目停播 · OFF AIR**
   - 摧毁深夜摄影棚的一块背景板
   - Destroy a Night Studio backdrop
9. <img src="../../assets/ui/achievements/wreck.svg" width="24" height="24" alt="拆迁小队徽章"> **拆迁小队 · WRECKING CREW**
   - 累计摧毁 8 件道具或建筑
   - Destroy 8 props or structures across rounds
10. <img src="../../assets/ui/achievements/clean.svg" width="24" height="24" alt="屹立不倒徽章"> **屹立不倒 · STILL STANDING**
    - 撑过 60 秒且零死亡并完成 8 次战斗击杀
    - Finish 60 seconds with no deaths and 8 combat kills
11. <img src="../../assets/ui/achievements/water.svg" width="24" height="24" alt="水花四溅徽章"> **水花四溅 · SPLASH ZONE**
    - 用滋水枪累计完成 10 次战斗击杀
    - 10 combat kills in water blaster mode
12. <img src="../../assets/ui/achievements/slipper.svg" width="24" height="24" alt="拖鞋正义徽章"> **拖鞋正义 · SOLE JUSTICE**
    - 用拖鞋发射器累计完成 10 次战斗击杀
    - 10 combat kills in slipper launcher mode

13. <img src="../../assets/ui/achievements/poop.svg" width="24" height="24" alt="便便巡逻队徽章"> **便便巡逻队 · POOP PATROL**
    - 在大便模式下累计击杀 15 名敌人
    - 15 combat kills in Poop Mode
14. <img src="../../assets/ui/achievements/grenade.svg" width="24" height="24" alt="拔针高手徽章"> **拔针高手 · PIN PULLER**
    - 累计用手雷击杀 15 名敌人
    - 15 kills with grenades across rounds
15. <img src="../../assets/ui/achievements/no_art.svg" width="24" height="24" alt="NO ART徽章"> **NO ART**
    - 解锁其他所有徽章
    - Unlock every other badge

## 实际计数口径

- **战斗击杀**包括回合内的爆炸击杀。倒计时归零后的全场爆炸只计入成绩。拆弹模式无这组徽章进度。
- **三连击**的 1.25 秒从这一组的第一杀开始计时。**一桶搞定**在油桶爆炸击杀一名敌人时解锁，连锁引爆的油桶也算。
- **涨潮时刻**用击杀发生时的玩家高度判定，门槛为关卡坐标 Y ≥ 2.55 米。
- **节目停播**和**拆迁小队**都在狂暴模式期间计数。节目停播需要打掉演播厅中带背景板标记的物件。
- **屹立不倒**在结算时判定。**水花四溅**和**拖鞋正义**按启用的模式累计，油桶或厕所爆炸造成的战斗击杀也算。
- 便便巡逻队沿用水花四溅已保存的大便模式击杀进度。旧版本最多保存 10 次，之后的击杀从本版本开始累计。
- 拔针高手只统计手雷直接造成的击杀。油桶、厕所或景物的连锁爆炸各自计数。
- NO ART 在其他 14 枚徽章全部解锁后自动获得。

[成就定义](../../scripts/achievements.gd) · [中文文案](../../data/ui_text.csv) · [游戏内计数](../../scripts/game.gd)
