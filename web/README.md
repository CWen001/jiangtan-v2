# 江滩 II · 江城旧埠

一个可以走进去的江城雨夜。复古电气、江岸灯影与黑色漫画人物构成的原创 3D 场景小样。

**在线体验：** https://cwen001.github.io/jiangtan-v2/

电脑使用 WASD 移动、鼠标观察、Shift 快走、左键出拳、右键格挡、E 互动、R 重开。手机横屏使用摇杆、拖动视角与屏幕按钮。首次进入需要下载游戏资源。

封面使用本项目场景美术图，游戏运行画面由浏览器实时渲染。此仓库包含封面与 Web 发布文件。

**C.WEN** · [cwen@hust.edu.cn](mailto:cwen@hust.edu.cn)

运行时使用 [Godot Engine](https://godotengine.org/)，遵循其 [MIT 许可与第三方声明](https://godotengine.org/license/)。

GitHub Actions 从官方 Godot 4.7.2 模板提取引擎，合并 `.release/` 中的场景资源，并校验 SHA256 后发布到 Pages。分块仅用于上传，网页加载完整游戏文件。
