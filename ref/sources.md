# 资料来源

核查日期：2026-09-09。

## S1 · 官方商店及截图

[Fallen Aces — Steam](https://store.steampowered.com/app/1411910/Fallen_Aces/)

开发者为 Trey Powell、Jason Bond，发行商为 New Blood Interactive。官方定位是犯罪黑色电影风格的第一人称游戏，强调漫画美术、手绘艺术与动画、非线性关卡，以及潜行或正面战斗的选择。

本地的 24 张截图来自该商店的截图清单；逐张来源见 [manifest](sources/image-manifest.json)。当前接口返回 48 张截图，本轮按列表隔张采集 24 张，不代表完整美术资产库。

[商店数据接口](https://store.steampowered.com/api/appdetails?appids=1411910&l=english) · [本地快照](sources/steam-appdetails.json)

## S2 · 官方关卡编辑器文档

[Fallen Aces SDK and Workshop Documentation](https://steamcommunity.com/sharedfiles/filedetails/?id=3486794926)

作者含 Aces Dev。文档标注 AceEd V.0.8.7，页面显示 2025-06-02 更新，不能假定与现版本所有细节一致。它说明了关卡空间、灯光、贴花、门、巡逻，以及自定义 sprite 和贴图导入。Sprite 可设置锚点、比例和碰撞信息，再打包为图集；表面贴图使用单独的打包流程。海报、落叶、报纸等可由贴花补充。镂空门材质涉及 Cutout 与透明排序的取舍。

重点阅读：Sectors、Creating a Basic Map、Adding Custom Sprites and Textures。

[本地网页快照](sources/official-sdk.html)

## S3 · 官方更新公告

[Fallen Aces — 官方新闻](https://steamcommunity.com/app/1411910/allnews/)

重点查找：

- **New and Improved Weapons，2026-06-27**：说明采用新的建模与动画制作流程更新武器、敌人等资产，未披露完整技术流程。不能从“手绘风格”推断全部资产始终采用纯手工逐帧制作。
- **The Immersive Sip Update，2025-08-30**：涉及消耗品动作、弹药的第一人称 sprites，以及游泳和死亡动画，适合研究交互表现。
- **Episode 2 OUT NOW，2026-07-26**：可作为第二章资料入口。

[本地网页快照](sources/official-news.html)。聚合页会变化，以上用标题和日期定位。

## S4 · 官方视频

以下视频已核查标题和官方公告引用关系，本轮未逐帧分析，也未下载视频。

| 视频 | 之后观看时的研究重点 |
| --- | --- |
| [Fallen Aces — Episode 2: Shadow of Death — OUT NOW](https://www.youtube.com/watch?v=Kte2sKAUZps) | 移动中的空间感、人物朝向变化、场景与武器的视觉关系 |
| [Fallen Aces — The Immersive Sip Update](https://www.youtube.com/watch?v=GtwKMf3iWxY) | 消耗品、手部及第一人称交互动作 |

Steam 当前商店接口还提供 **Fallen Aces Episode 1 OUT NOW** 和 **Fallen Aces Episode 2 OUT NOW** 两部预告片的元数据，见 [trailers.json](sources/trailers.json)，可在商店页观看。
