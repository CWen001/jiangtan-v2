# SceneDesign 与 dream-loop 的联动边界

2026-09-10。基于本机实际安装的 dream-loop SKILL.md、Pro workflow 和 assets-3d.md 分析。本文是联动建议，尚未执行构建，也未修改全局 skill。安装版本与上游是否一致、Blender 的运行状态不在本次复核范围内。

## 定位

ProjectArtDirection 决定跨场景美术约定；SceneDesign 决定具体场景的空间、美术、物件、表示方式和体验；VisualProductionPlan 决定一轮用哪些视点和分镜呈现或检视它。dream-loop 是消费这些设计与目标图、反复实现和比较运行画面的执行流程。

dream-loop 接受已有目标图，不要求重新发明画面。但本机 skill 没有原生 SceneDesign 解析器、Godot 导入器或 Blender MCP 绑定；联动目前由代理读取完整设计、引用图像和执行要求后完成，不等于安装即打通。

## 上游实际行为

- 目标图保存在 `.dream-loop/target.png`，工作目录加入 gitignore；已有目标图可直接使用。需要生成目标时强调实际产品截图式取景；已有产品应读取当前截图作为基线。
- Pro 流程反复实现、测试、截取运行画面，并交给独立新上下文评审代理与目标图比较。
- 评分包含构图、光照、材质、细节；视觉评分至少 8 且帧率可接受时完成当前轮，停滞时先大幅调整，仍无改善则请求用户判断。
- 资产流程依次考虑获准下载的外部资产、图生三维、Blender、程序化构建；Blender 可通过 Python 使用，并非必须通过 MCP。ImageGen 用于资产图和贴图。

## 需要约束的交接

1. **选定取景。** 从 VisualProductionPlan 的 View 选当前目标，明确场景版本、视点、朝向、视场角、画幅与体验时刻。后两项相机制作参数可先写在执行说明，不必立刻扩展通用 Schema。
2. **分清图的职责。** 全景、人物近景、材质近景分别是氛围、人物画法和材质密度依据；不是三个已经空间对齐的运行目标。精确对图前先依据 SceneDesign 建立共同空间。已有小样应截取实际相机画面，再在设计允许范围内构成新目标。
3. **遵守表示方式。** elements.representation 指定二维或三维职责。二维人物由 ImageGen 和 Godot 的二维表现手段实现；三维建筑、设备可用 Blender；不因上游通用资产建议把人物送去图生三维。具体资产途径按项目已选技术和授权范围约束。
4. **保持多视角空间。** 上游核心围绕一个 target.png，不能直接声称支持整组分镜的一致性。项目可为同一 SceneDesign 选若干检查视点，每轮主攻一个，修改后复看其他关键视点，并实际走过连接处。视点数量由场景需要确定。
5. **对齐美术目标。** 原评分强调逐像素一致，但本项目更看重轮廓、色块、材质区别、细节层次和二维三维融合。若采用项目版评审要求，应在调用说明中明确修改点；不把有意的漫画简化当作瑕疵，也不为复制偶然碎斑改变已选材质规则。
6. **限制设计漂移。** UV、贴图密度、材质设置、局部网格修整属于执行；改变主要建筑比例、区域连接、设备造型或体验显露顺序要回写 SceneDesign，并刷新受影响目标图；改共享美术规则按 ProjectArtDirection 的修订约定处理。评审代理提出的重做建议本身不是设计变更授权。
7. **明确本轮交付。** 包含可运行 Godot 场景、依赖的模型与贴图、实际截图、走动与交互检查结果及尚未实现的部分。视觉分数用于对图反馈，不能代替空间体验和实际运行检查。选定的正式交付从被忽略的 `.dream-loop` 工作目录转存到项目可保留的位置。

## 最小接法

暂不新增 DreamLoopSchema，也不重写全局 skill。调用时用一份项目任务说明交接：

- SceneDesign 的完整内容和固定版本，以及它引用的 ProjectArtDirection。
- 当前 View、实际目标图、辅助参考图及各自学习范围。
- 本轮需实现的走动或交互、允许变化的设计范围。
- Godot、Blender 与 ImageGen 的职责；禁止把二维人物改成三维角色。
- 运行截图方法、其他必看视点、帧率目标与结束条件。

资产规格可以在执行中形成，将稳定且需要重用的部分再沉淀到后续资产制作契约；不要求先完成整套资产 Schema 才能做小样。

当前可先完成一个小范围 SceneDesign，再形成一张可执行目标图和少量补充视点，试跑这套交接。现阶段已选的三张美术参考尚不等于完整 SceneDesign。

## 本机依据

- [dream-loop SKILL.md](/Users/cwen/.codex/skills/dream-loop/SKILL.md)
- [Pro workflow](/Users/cwen/.codex/skills/dream-loop/references/pro-mode/workflow.md)
- [3D assets](/Users/cwen/.codex/skills/dream-loop/references/pro-mode/assets-3d.md)
- [当前通用字段](fields-v0.2.md)
- [当前项目美术预设](project-art-direction-v0.2.md)
