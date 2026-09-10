# Codex + GPT Image + 游戏引擎 + Blender：工具链研究

研究日期：2026-09-09。面向本项目的 3D 场景、2D 人物和丰富贴图。本文将用户的 `clil` 暂按 CLI（命令行）理解。结论属于选型建议；本轮没有安装软件、生成游戏资产或运行游戏原型。

## 当前建议

优先验证 **Codex + imagegen + Godot/GDScript + Blender**。Blender MCP 负责交互操作与反馈，Blender Python/CLI 负责可重复的批量生产。若你已有 Unity 工作习惯、需要复用 Unity 资产或团队已有 C# 基础，Unity 也完全可行，而且本机已有编辑器。

推荐 Godot 的依据是它的项目与场景适合文本维护、命令行入口直接、内置 3D sprite 节点，符合当前由 Codex 主导的小型项目需求。这个判断不表示 Godot 的所有渲染或开发能力都优于 Unity，也不是已完成的性能对比。[Godot CLI](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)、[SpriteBase3D](https://docs.godotengine.org/en/stable/classes/class_spritebase3d.html)

## 每个工具具体负责什么

| 工具 | 在本项目中的建议职责 | 交付物 |
| --- | --- | --- |
| Codex | 编写玩法、资产导入规则、Blender 脚本、构建脚本；运行检查，查看截图并修正 | 可读代码、配置、日志与版本记录 |
| imagegen / GPT Image | 确立漫画风格；生成角色设计、墙地纹理候选、招牌海报和静态物件图 | 经过筛选的 PNG/JPEG 与提示词 |
| Blender | 模块化场景、道具、UV、动画和可控相机渲染 | `.blend` 源文件、GLB/FBX 或 PNG 帧序列 |
| Blender MCP | 让 Codex 读写当前 Blender 场景、执行 Python、取得视口反馈 | 对已运行 Blender 的交互控制 |
| Godot 或 Unity | 摄像机、碰撞、人物行为、方向动画、灯光、音效、UI 与发布 | 真正能运行的游戏 |

这是一套制作工具链。游戏运行时消费导出的资产，不需要保持 Codex、GPT Image 或 Blender MCP 在线。

## Godot 与 Unity 的实际取舍

| 项目 | Godot | Unity |
| --- | --- | --- |
| Codex 编辑 | 建议 GDScript + 文本场景；CLI 可导入、运行脚本/场景和导出 | 建议 C# + Editor API 生成场景/材质，避免大量手改对象引用 |
| 命令行自动化 | `--headless`、`--import`、`--script`、`--export-release` 等；导出还需要模板与预设 | `-batchmode`、`-executeMethod`、日志及构建入口；仍需编辑器、可用授权及目标模块 |
| 2D 人物置于 3D | 内置 Sprite3D / AnimatedSprite3D，可配置 billboard、深度和透明裁切 | 可用 SpriteRenderer 或面片配合朝向脚本与材质；需要组合相关组件 |
| 多方向动画 | 需按相机相对人物朝向选择帧组；billboard 不等于完整方向系统 | 同样需要方向选择和动画状态逻辑 |
| Blender 模型交付 | 优先 GLB；直接导入 `.blend` 背后也依赖 Blender 转换 | 优先导出 FBX；直接 `.blend` 导入依赖 Blender，材质仍需核对 |
| 自动化测试 | 可编写运行后退出的测试场景和断言；语法检查不能替代玩法测试 | 官方 Test Framework 有批处理测试入口和结果文件 |
| 本机情况 | 常见安装目录和 PATH 未发现 | 找到 Unity 6000.1.9f1 编辑器可执行文件 |

依据：[Godot CLI](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)、[Godot SpriteBase3D](https://docs.godotengine.org/en/stable/classes/class_spritebase3d.html)、[Godot 模型格式](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)、[Unity CLI](https://docs.unity3d.com/6000.0/Documentation/Manual/EditorCommandLineArguments.html)、[Unity 模型导入](https://docs.unity3d.com/6000.0/Documentation/Manual/HOWTO-ImportObjectsFrom3DApps.html)、[Unity Test Framework](https://docs.unity3d.com/Packages/com.unity.test-framework@1.4/manual/reference-command-line.html)。Unity 链接为 6000.0 系列及指定包版本，实施时需对照本机 6000.1.9f1 与实际安装的包。

CLI 能执行构建和检查，不等于完整实时编辑器控制。Unity 的 `-executeMethod` 需要我们提供 Editor 脚本；若要持续操作打开的 Unity 编辑器，可之后再评估额外桥接工具。本轮未假定任何名为 unity-cli 的第三方工具已安装。

视觉验收必须运行真正的图形渲染。Godot 的无渲染 headless 检查、Unity 的 `-nographics` 成功退出，都不能证明透明边缘、光照或遮挡正确。Unity 同一项目的 GUI 与 batchmode 使用也应串行调度。[Unity CLI](https://docs.unity3d.com/6000.0/Documentation/Manual/EditorCommandLineArguments.html)

## GPT Image 能做哪些资产

本地 imagegen 技能默认使用会话内置工具，无需配置 API key；如明确选择 API/CLI，才走技能附带脚本。当前内置工具的参数没有模型选择字段，因此不能承诺调用某个可固定的 GPT Image 快照。若以后需要固定模型、程序化队列或用量记录，应单独选择并验证 API 路径。

官方图像文档支持生成和编辑，也明确提示跨次生成的角色一致性、精确文字与布局仍可能出错。因此建议将 GPT Image 先用于风格和单张资产，不把一次生成完整 sprite sheet 当成可靠批量流程。[OpenAI Image generation](https://developers.openai.com/api/docs/guides/image-generation/)

以下是面向本项目的生产建议，并非模型能力保证：

- **墙地纹理**：提示正视、无透视、弱方向光；进入引擎前测试重复铺设、接缝和纹理尺度。写了“无缝”不等于边界必然可平铺。
- **海报与招牌**：适合产生丰富视觉内容；需要准确传达的文字应单独核对。
- **静态人物或道具**：统一画布、比例、朝向和脚底锚点；检查真正 alpha，而非画出来的棋盘格。
- **动画角色**：面部、服装、肢体比例、脚底位置和轮廓都需要跨帧检查。复杂连续动作是主要待验证环节。

本地 skill 的 CLI 模型说明和在线 API 文档已有版本差异；执行时按选定模型核对具体参数。本轮不将某条旧模型透明背景限制泛化为所有 GPT Image 的限制。

## 人物生产的两条路线

### A · 直接生成 2D 人物

固定一张角色设定图，继续生成少量方向和动作，用相同锚点与画布整理成帧组。适合先验证一个静态人物或很短的动作。

风险是不同帧出现衣服变化、身体漂移、脚底跳动。建议先做一个小样，合格后再扩展方向和动作数量；不能只检查每张图单独是否好看。

### B · Blender 固定形体，再渲染成 2D

以角色设计为参照，在 Blender 中建立并绑定模型，通过固定相机、光照、动作和多个方向批量渲染 PNG。引擎仍然显示二维帧；制作阶段使用三维模型与最终画面中的二维人物并不冲突。

这条路线使形体和动作更可控，但模型、绑定和漫画线条本身仍要制作。Blender MCP 不能自动保证角色质量。若逐帧再交给图像模型重绘，仍可能重新引入闪烁；建议先用固定材质与渲染风格得到稳定结果。

推荐先用 A 验证风格；若动作数量增多或一致性不过关，再比较 B 的投入。相机和自动化基础见 [Blender 4.5 Camera API](https://docs.blender.org/api/4.5/bpy.types.Camera.html)、[Blender 4.5 LTS CLI](https://docs.blender.org/manual/nl/4.5/advanced/command_line/arguments.html)。这是可行路径分析，尚未制作样片。

## Blender MCP 的定位

暂以用户所说的 blender_mcp 指 [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)。它是第三方项目，架构是 Blender 插件与 MCP 服务进程配合，文档已有 Codex 接入说明。Codex 支持标准 STDIO MCP 服务，因此协议上可以衔接。[Codex MCP](https://developers.openai.com/codex/mcp/)

推荐采用两种互补入口：交互调整和视口查看使用 MCP；稳定的建模、渲染和导出流程保存为 Python 脚本，通过 Blender CLI 重跑。MCP 接入成功后也要核对 `.blend` 是否保存、导出文件是否存在、引擎是否能导入。

上游当前 server 源码提供视口截图和执行 Python 的工具，并明确提示该插件的命令处理需要 GUI Blender，不能将其当成 `blender -b` 的后台控制接口。MCP 操作宜串行，长时间批量渲染另走 CLI。[server.py](https://raw.githubusercontent.com/ahujasid/blender-mcp/main/src/blender_mcp/server.py)

接入时建议固定版本并配置 `DISABLE_TELEMETRY=true`：上游提供这一开关，当前源码含在遥测同意条件下上传视口截图的路径。本轮没有运行该服务。[上游 README](https://github.com/ahujasid/blender-mcp)

Blender 导出的材质也需要单独验收：glTF 支持指定的 PBR/Unlit 等材质，不能把任意 Blender 漫画节点效果原样搬进引擎。需要将外观烘焙进纹理或在引擎中重建对应效果。[Blender glTF 文档](https://docs.blender.org/manual/en/dev/addons/scene_gltf2.html)（开发版资料，实施时核对安装版本。）

不必为了接入 Blender 顺带依赖额外的在线 3D 生成服务。本项目已有 GPT Image 出图路线，Blender 可以先负责几何、UV 和渲染；上游集成的外部资产服务另有配置与使用条件。

## 资产量与验收

关键成本会随着“方向 × 动作 × 帧数”增长。作为计算示例，8 个方向 × 4 种动作 × 每动作 8 帧 = 256 帧；若每帧 512 × 512，RGBA8 未压缩、不计 mipmap 和图集空隙，约为 256 MiB。这是预算示例，既不是 Fallen Aces 的实测数据，也不是本项目已选规格。

因此应先约定尺寸、锚点、世界尺度、材质复用与图集规则，再批量生成。一个角色的最小验收包括：朝向切换、脚底稳定、动作连续、门后遮挡、两个角色相交时的透明排序，以及亮暗区域中的可读性。Godot 官方文档也说明 alpha blending 与 billboard 阴影存在限制。[SpriteBase3D](https://docs.godotengine.org/en/stable/classes/class_spritebase3d.html)

## 建议的第一次实际验证

1. 一个可行走的小房间连一条巷道，先建立比例与遮挡。
2. 两张候选墙地纹理、一张招牌、一个简单人物。
3. Blender 制作一个门框或道具，导出后在引擎中使用。
4. 人物先做四方向和一个短动作，观察移动中的效果。
5. CLI 导入与检查，再用图形模式走动、看图，最后导出本机可执行版本。

验收目标是这条制作链能重复运行，且人物、贴图与空间在游戏中协调。引擎选择和人物生产路线仍待讨论，未据此创建项目或 ADR。

## 本机核查记录

- 当前会话有内置 `image_gen` 工具和 imagegen skill；本轮未出图。
- `/Applications/Unity/Hub/Editor/6000.1.9f1/Unity.app/Contents/MacOS/Unity` 文件存在；未启动，未验证授权、目标平台模块或构建。
- `/Applications`、`~/Applications` 及常见可执行目录未发现 Godot、Blender；这不代表已搜索全部磁盘。
- 当前会话工具目录未发现 Blender MCP 工具；没有修改全局 MCP 配置。
- `uv`、`uvx` 可从 PATH 找到。
