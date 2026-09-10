# Fallen Aces 参考资料

采集日期：2026-09-09。当前目标：研究 Fallen Aces 风格的 **3D 场景、2D 人物、大量贴图**。本轮收集参考，不预先确定引擎、题材和玩法规模。

## 从这里看

- [截图总览 1](overview-01.jpg)：人物近景、战斗、夜间街巷、室内。
- [截图总览 2](overview-02.jpg)：建筑、人物、墙纸、家具、街道与植被。
- [逐图索引](image-index.md)：24 张官方商店截图的观察重点，点击查看原图。
- [美术与玩法观察](visual-notes.md)：哪些是官方事实，哪些是从截图得到的判断。
- [资料来源与视频](sources.md)：官方商店、SDK、更新公告和预告片。
- [制作工具链研究](toolchain-research.md)：Codex、GPT Image、Godot/Unity CLI 与 Blender MCP 的分工、取舍和验证路线。

## 文件说明

`images/` 保存 24 张从 Steam 官方商店截图清单下载的 JPEG。文件名中的编号是 Steam screenshot ID，保留原始下载内容，编号不连续。总览是供检索用的缩略图拼版。

`sources/image-manifest.json` 记录每张图的来源页面、下载 URL、抓取时间、分辨率、大小和 SHA-256；`sources/steam-appdetails.json` 是官方商店接口快照；`sources/trailers.json` 保留官方预告片元数据。`sources/official-sdk.html` 和 `sources/official-news.html` 是网页快照，离线阅读时其中的远程图片未必可用。

这些图片是研究参考，版权归原权利人；本目录不把它们视为本项目已获授权的游戏资产。截图跨越不同开发时期，单张图的具体构建版本未知。
