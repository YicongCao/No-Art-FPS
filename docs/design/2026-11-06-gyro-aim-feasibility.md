# 陀螺仪辅助瞄准可行性

调研日期：2026-11-06。结论：可以作为手机端可选的微调瞄准方式，保留现有双拇指操作。本轮只调研，不把未经过真机验证的传感器控制直接发布。

## 已确认的接口与前提

- `devicemotion` 的 `rotationRate` 提供角速度，单位为度／秒；设备可能不提供数据，返回值可能为 null。不能仅因构造器存在就判断可用，也不能将合法的零角速度误判为不可用。[MDN rotationRate](https://developer.mozilla.org/en-US/docs/Web/API/DeviceMotionEvent/rotationRate)
- 优先使用 DeviceMotionEvent；Generic Sensor 的 `Gyroscope` 接口仍为有限兼容，不宜作为跨浏览器唯一入口。[MDN Gyroscope](https://developer.mozilla.org/en-US/docs/Web/API/Gyroscope)
- 需要安全上下文。当前 `https://fps.yicong.me/` 已满足 HTTPS；本次只读检查未发现响应头显式禁用传感器，但这不证明每台设备都能访问硬件。
- 若存在 `DeviceMotionEvent.requestPermission()`，必须在用户明确点击开关时调用，并处理 granted、denied 和异常。WebKit 的相关说明明确要求用户交互。接口不存在时可以尝试监听，仍要检查能否收到有效读数，不可把缺少此方法等同于不支持。[MDN 权限请求](https://developer.mozilla.org/en-US/docs/Web/API/DeviceMotionEvent/requestPermission_static)、[WebKit 说明](https://bugs.webkit.org/show_bug.cgi?id=201676)
- 保持游戏在顶层页面访问；内嵌 WebView、跨域 iframe 可能还有权限限制。不要将一次桌面模拟测试当作 iPhone、Android 或内嵌浏览器的支持证明。

## 建议交互（设计建议）

暂停菜单增加“体感微调”开关，默认关闭；开启后出现独立灵敏度和“重新校准”。默认不开权限弹窗，不自动弹提示，也不依赖安装到主屏幕。拒绝授权后继续正常触屏游戏。

左手仍负责移动，右手滑动负责大幅转向；轻轻转动手机负责准星最后一段微调，开火手势不变。初版优先只在横屏、RUNNING、玩家存活且开启时生效。暂停、重生、旋转、后台和失焦都停止积累角度，恢复时重新建立采样时间基准。

授权入口与全屏入口分开：不要在等待全屏 Promise 完成后才请求传感器权限，否则用户激活可能已消耗或过期。[MDN User activation](https://developer.mozilla.org/en-US/docs/Web/Security/Defenses/User_activation)

## 接入现有工程（设计建议）

1. Web 外壳监听 `devicemotion`，把角速度变成每次读取的增量；按事件实际时间差积分，超长间隔丢弃，短间隔限定合理上限。滤波与小死区仅用于减少噪声，参数需要真机调整。
2. 按 `screen.orientation.angle` 处理左、右横屏的坐标转换。标准中的 beta 对应设备 X 轴、gamma 对应 Y 轴、alpha 对应 Z 轴；先把向量转换到屏幕坐标，再映射俯仰和水平瞄准，不直接把 alpha 当作水平视角。正负号和不同握持角度需实机验证。[W3C 坐标及旋转定义](https://www.w3.org/TR/orientation-event/)、[MDN 屏幕方向角](https://developer.mozilla.org/en-US/docs/Web/API/ScreenOrientation/angle)
3. 在现有 `noArtReadTouch()` 包中增加 `gyroYaw`、`gyroPitch`，使用弧度而非 CSS 像素。Godot 每个物理帧消费后清零，与触屏增量相加，保留现有俯仰角限制；体感灵敏度和触屏灵敏度分别控制。
4. 首次稳定持握时估算零偏；重新校准只校准噪声和零偏，不强制把当前游戏视角跳回中央。避免长时间积分漂移，提供随时关闭的开关。
5. 传感器读数只在当前页面内存中消费，不上传、不记录轨迹。无数据、权限被拒或接口报错时安静回退到触控。

## 真机验收门槛

- iPhone Safari、Android Chrome 各一台；横屏两个方向都验证，另行记录设备和浏览器版本。
- 权限允许／拒绝／无硬件／无读数均不影响触屏开局。
- 静止时准星不持续漂移；小幅摆动方向自然；手指滑动、按住开火与体感同时使用不冲突。
- 手机转回竖屏、切后台、暂停、重生或重开后不跳视角，也不应用过期增量。
- 帧率、事件间隔、延迟和眩晕感在真实对战中评估；桌面合成事件只能验证数学和状态机，不能替代实际手感。

建议下一步做可关闭的真机体验版。先解决权限、横屏映射和漂移，再决定是否增加“仅开火时体感”等模式。
