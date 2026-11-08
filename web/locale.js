(() => {
  const key = 'no-art-language';
  const english = {
    'No-Art-FPS — 60 秒击杀冲刺。pixelcao 的明亮低多边形 FPS 小品。':'No-Art-FPS — a bright low-poly 60-second FPS by pixelcao.',
    '游戏加载进度':'Game loading progress',
    '正在连接':'Connecting',
    '重新加载':'Reload page',
    'No-Art-FPS 游戏画面':'No-Art-FPS game view',
    'WASD 移动 · Shift 冲刺 · 鼠标瞄准 · 左键开火 · Esc 暂停':'WASD move · Shift sprint · Mouse aim · Click to fire · Esc pause',
    '左侧移动 · 右侧瞄准':'Move on the left · Aim on the right',
    '横过来，准备开火':'Rotate to play',
    '左手移动，右手瞄准':'Move with your left thumb. Aim with your right.',
    '横屏全屏':'Play fullscreen',
    '体感':'Gyro',
    '进入沉浸全屏':'Enter fullscreen',
    '全屏':'Fullscreen',
    '大便模式':'Poop Mode',
    '蟑螂模式':'Cockroach Mode',
    '触控操作':'Touch controls',
    '按住开火':'Hold to fire',
    '跳跃':'Jump',
    '换弹':'Reload',
    '按住拆除 C4':'Hold to defuse C4',
    '拆除':'Defuse',
    '暂停':'Pause',
    '体感瞄准':'Gyro Aim',
    '关闭体感设置':'Close gyro settings',
    '正在检查浏览器支持':'Checking browser support',
    '启用体感':'Enable gyro aim',
    '使用触控':'Use touch',
    '校准进度':'Calibration progress',
    '开始校准':'Calibrate',
    '用体感瞄准亮靶的练习间':'Gyro aim practice room with a lit target',
    '运动传感器':'Motion sensor',
    '启用':'Enable',
    '关闭':'Disable',
    '灵敏度':'Sensitivity',
    '翻转设备轴':'Invert device axes',
    'X 轴':'X axis',
    'Y 轴':'Y axis',
    'Z 轴':'Z axis',
    '准星回正':'Recenter',
    '返回':'Back',
    '重新校准':'Recalibrate',
    '练习瞄准':'Aim practice',
    '进入游戏':'Continue',
    '体感组件加载失败。请刷新页面后重试。':'Gyro aim failed to load. Reload the page and try again.',
    '可在 Safari 页面菜单选择「隐藏工具栏」。':'Choose Hide Toolbar in the Safari page menu.',
    '点按 Safari 地址栏左侧的页面菜单，选择「隐藏工具栏」。':'Tap the Page Menu to the left of Safari’s address bar and choose Hide Toolbar.',
    '忽略':'Dismiss',
    '此浏览器暂不支持全屏':'Fullscreen is unavailable in this browser.',
    '准备就绪':'Ready',
    '加载遇到问题，请重试':'Loading failed. Please try again.',
    '此浏览器不支持运行游戏，请使用新版 Chrome 或 Firefox':'This browser cannot run the game. Try a recent version of Chrome or Firefox.',
    '正在下载资源':'Downloading game files',
    '正在准备场景':'Preparing the arena',
    '场景初始化失败，请重试':'The arena failed to load. Please try again.',
    '游戏已退出':'The game has closed.',
    '游戏加载失败，请检查网络后重试':'The game failed to load. Check your connection and try again.',
    '启用体感瞄准？':'Enable gyro aim?',
    '校准体感':'Calibrate Gyro Aim',
    '体感练习':'Aim Practice',
    '体感已就绪':'Gyro Aim Ready',
    '等待授权':'Waiting for permission',
    '校准中':'Calibrating',
    '请求权限并校准':'Allow motion and calibrate',
    '返回设置':'Back to settings',
    '用转动设备来微调准星。':'Tilt your device to fine-tune your aim.',
    '转动设备，把准星停在亮靶上。':'Tilt your device and hold the crosshair on the lit target.',
    '校准完成，瞄准练习已通过。':'Calibrated. Aim practice passed.',
    '校准完成。':'Calibrated.',
    '点按「请求权限」，由浏览器处理运动与方向访问。':'Tap to request access to motion and orientation.',
    '点按「启用」后会尝试读取运动传感器。':'Tap Enable to read the motion sensor.',
    '体感瞄准需要 HTTPS。请打开正式试玩页面。':'Gyro aim needs HTTPS. Open the official game page.',
    '当前浏览器不提供运动传感器。请用系统浏览器直接打开。':'This browser does not provide motion data. Open the game in your system browser.',
    '当前页面禁止访问运动传感器。请在浏览器中直接打开试玩页。':'This page blocks motion access. Open the game directly in your browser.',
    '权限已允许，但未检测到体感数据。请保持页面在前台后重试。':'Permission granted, but no motion data arrived. Keep this page in the foreground and try again.',
    '未检测到体感数据。请检查浏览器是否允许此站点访问运动传感器。':'No motion data arrived. Check whether your browser allows motion access for this site.',
    '请回到当前页面，横握设备完成校准。':'Return to this page and hold your device sideways to calibrate.',
    '权限已允许。请回到当前页面，横握设备完成校准。':'Permission granted. Return to this page and hold your device sideways to calibrate.',
    '已向浏览器请求权限。如有弹窗，请允许访问。':'Motion access requested. Allow access if your browser prompts you.',
    '浏览器拒绝了运动传感器权限。如果没有弹窗，浏览器可能沿用了之前的选择。':'The browser denied motion access. If no prompt appeared, it may have reused an earlier choice.',
    '授权未完成。请在当前页面重新点按「请求权限」。':'Permission was not granted. Request it again from this page.',
    '浏览器无法请求体感权限。请直接打开试玩页后重试。':'The browser could not request motion access. Open the game directly and try again.',
    '校准完成，可以用体感瞄准。':'Calibrated. Gyro aim is ready.',
    '手机移动较多，请重新校准':'Too much motion. Try calibrating again.'
  };

  function detectLanguage(locale) {
    const parts = (locale || '').toLowerCase().split(/[-_]/);
    if (!parts[0] || ['c', 'posix', 'und'].includes(parts[0])) return 'zh';
    if (parts[0] !== 'zh') return 'en';
    const region = parts.slice(1).find(part => /^[a-z]{2}$/.test(part));
    return !region || ['cn', 'hk', 'mo'].includes(region) ? 'zh' : 'en';
  }

  const preferred = navigator.language || navigator.languages?.[0];
  let language = detectLanguage(preferred);
  try {
    const saved = localStorage.getItem(key);
    if (saved === 'zh' || saved === 'en') language = saved;
  } catch {}

  const text = (source) => language === 'en' && Object.hasOwn(english, source) ? english[source] : source;
  const staticText = [...document.querySelectorAll('[data-i18n]')].map(node => [node, node.textContent]);
  const attributes = ['aria-label', 'content'];
  const staticAttributes = attributes.flatMap(attribute => [...document.querySelectorAll(`[data-i18n-${attribute}]`)]
    .map(node => [node, attribute, node.getAttribute(attribute)]));

  function render() {
    document.documentElement.lang = language === 'zh' ? 'zh-CN' : 'en';
    for (const [node, source] of staticText) node.textContent = text(source);
    for (const [node, attribute, source] of staticAttributes) node.setAttribute(attribute, text(source));
  }

  window.noArtLanguage = () => language;
  window.noArtText = text;
  window.noArtSetLanguage = (value) => {
    if (value !== 'zh' && value !== 'en') return;
    language = value;
    try { localStorage.setItem(key, value); } catch {}
    render();
  };
  render();
})();
