# No-Art-FPS

- Godot 4.7.2, GDScript; Blender 5.2.2 LTS for editable original models.
- Target: a bright, low-poly 60-second score-attack FPS. See docs/design/No-Art-FPS-playbox-plan.md.
- Keep the HUD minimal: time, kills, crosshair; contextual ammo. Never display health; use a gradual dark-red edge vignette at low health.
- Avoid unnecessary secondary labels and descriptions. Let the layout do the explaining.（避免不必要的次要标签和描述，让布局本身来传达信息。）
- Model sources live in art_source/; game-ready exports in assets/models/.
- Keep analyses and screenshots in this project as ordinary Markdown/PNG/SVG. No editor-specific canvas runtime.
- Work in verifiable stages and make a Git commit after each completed stage. Immediately push every new commit to `origin` (`git@github.com:YicongCao/No-Art-FPS.git`); the user has authorized ongoing pushes. Never force-push without explicit authorization. If a push fails, report it and preserve the local commit.
- Validate with Godot import/headless checks, rule tests, and actual rendered gameplay. Distinguish automated checks from human playtesting.
- Reference video and extracted reference screenshots remain local and are not committed.

- 不在工程界面、文案、注释或文档中使用 emoji，也不使用 Unicode 图形字符充当图标。需要图形表达时绘制 SVG；保留可访问的文字标签。不要用表情字体、emoji 图片或图片生成来替代 SVG。
