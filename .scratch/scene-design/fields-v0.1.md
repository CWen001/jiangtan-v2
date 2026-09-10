# 场景美术契约：字段设计 v0.1

日期：2026-09-10。状态：可讨论、可填写的字段草案；不是已冻结的 JSON Schema 或 Pydantic 实现。

后续：[v0.2](fields-v0.2.md) 以本稿为基础增加按需的路线、移动、体验推进和镜头参照。本文与唱片店样例保留，便于对照静态默认行为；字段不绑定该样例的物件和地点。

沿用 [spec.md](spec.md) 中已确认的三组当前契约和一组后续制作契约。本稿将其展开成嵌套字段，并以 [examples/README.md](examples/README.md) 中的原创场景提案检查交接。样例设计与新字段均待讨论，不代表已制作或已选用。

## 阅读约定

- `text` 是有具体设计内容的短段落；`[]` 表示列表；`Ref` 是 `{id, revision}`。
- “核心”表示建议每份设计主动回答；“按需”表示场景需要时填写，数组可为空。它们是设计责任建议，不是机器校验规则。
- 为会被其他内容引用的对象分配 ID。普通材质描述、形容词、段落不逐句编号。
- 同一文档的 ID 在该文档内唯一；引用跨文档时先锁定文档及其 revision。revision 表示设计内容修订，不是批准状态。
- 设计中的尺寸是意向尺度；当前不输出网格、UV、材质节点、碰撞或精确施工坐标。
- 将“感受”与“可见手段”写在一起，保留丰富美术内容；不为每句话增设评分、理由或审核字段。

## 1. ProjectArtDirection

一份是项目共享的美术语言。输入：创作目标、参考与已知约束。输出内容如下。

| 字段 | 类型 | 设计责任 | 深度示例 |
| --- | --- | --- | --- |
| `id`, `revision`, `title` | text | 核心：识别这套约定 | `noir_comic`, `draft-01` |
| `intent` | `{promise, form_language}` | 核心：画面的共同气质、形体概括方式 | 硬朗漫画形体，局部不规则，结构仍清楚 |
| `linework` | `{contours, inner_marks, distance_behavior}` | 核心：轮廓、内部线条、远近细节 | 近处有磨损墨线，远处归并为块面 |
| `values` | `{massing, edges, light_response}` | 核心：明暗分组、边缘、光照表现 | 阴影保留大块形状，重点区域可有局部柔光 |
| `surfaces` | `{material_readability, detail_hierarchy, wear_logic}` | 核心：材质差异、密度层次、表面变化 | 金属折边、砖缝、木纹各有不同线条方向 |
| `hybrid` | `{geometry, flat_images, characters, integration}` | 核心：形体、图像、人物与环境的共同表现要求 | 轮廓与视差需要的厚度由模型承担；人物接触地面 |
| `scene_freedom` | text[] | 核心：每个场景可以自由决定什么 | 色彩、光源、材质比例、标志形象 |
| `avoid` | text[] | 按需：具体防止的风格偏移 | 不是泛泛“不要低质量”，而是避免每面墙同密度噪点 |
| `references` | Reference[] | 按需：来源及学习范围 | `{id, source, learn, do_not_copy}` |

`Reference.source` 指向实际可取得的图像或资料。`learn` 写视觉特征，`do_not_copy` 写不纳入本项目的具体内容。参考不是宣称本项目已具备其效果。

这里只约定表现语言，不预设每处空间的主色、灯光、建筑布局或逐件造型。

## 2. SceneDesign

一份是一个完整主方案，可以包含需要共同设计的室内、室外及过渡空间。

| 字段 | 类型 | 设计责任 |
| --- | --- | --- |
| `id`, `revision`, `title` | text | 核心：识别主方案 |
| `art_direction` | Ref | 核心：引用项目美术约定 |
| `intent` | `{signature, feeling, invitation}` | 核心：记忆点、感受、吸引人走近的可见线索 |
| `scope` | `{included, edges, starting_position}` | 核心：包含哪些空间，外部衔接在哪里，从哪里开始体验 |
| `art` | SceneArt | 核心：整体美术设计，见下表 |
| `space` | SpatialDesign | 核心：相对布局、体量与连接 |
| `elements` | VisualElement[] | 核心：主要视觉物件逐件设计 |
| `dressing` | DressingGroup[] | 按需：普通陈设按组设计 |
| `initial_state` | text[] | 核心：基准画面的门、人物、灯光等状态 |
| `experience` | ExperienceMoment[] | 核心：空间如何吸引探索，以及动作后的视觉回报 |

### SceneArt：先建立整个空间的画面秩序

| 字段 | 类型 | 设计责任 |
| --- | --- | --- |
| `composition` | `{massing, silhouette, depth, detail_distribution}` | 大体块、识别轮廓、纵深关系、哪里繁复与安静；描述空间而非绑定单一镜头 |
| `palette` | `{id, color, role, placement}[]` | 色彩及其作用和分布，不只是色值表 |
| `lighting` | `{id, source, placement, reach, visual_effect}[]` | 光源在哪里、影响哪些位置、形成什么可见效果 |
| `materials` | `{id, name, appearance, graphic_treatment, variation}[]` | 本场景材料的外观、漫画绘制方式与变化规律 |
| `atmosphere` | `{medium, placement, behavior, purpose}[]` | 按需的雨、蒸汽、微动或声音；说明位置与作用，不要求全都有 |

材料在这里定义一次。区域或物件用 `surface_uses: [{material_id, placement, local_treatment}]` 指定材料分布和局部处理，避免同一木材在几份物件描述中变成不同画风。

### SpatialDesign：共享一个真实可理解的场所

| 字段 | 类型 | 设计责任 |
| --- | --- | --- |
| `orientation` | text | 统一方向约定，如北为店面；镜头转向不改变空间方位 |
| `zones` | Zone[] | 区域及其局部构成 |
| `connections` | Connection[] | 区域如何相接，穿越时看到什么变化 |
| `relations` | text[] | 补充对多视角一致性重要的相对关系；不可与具体物件的位置矛盾 |

`Zone` 的核心字段：

- `id`, `name`, `setting`：区域身份；室内、室外或有顶过渡等用自然语言表达。
- `extent`, `spatial_character`：大致范围、体量比例与围合感。
- `visual_anchor`：最容易辨认的形象，可提及主要物件。
- `surface_uses`：主要围合表面的材质分布。

`Connection` 的核心字段：

- `id`, `from_zone`, `to_zone`：连接的是哪些区域。
- `placement`, `form`, `traversal`：连接位置、几何形态与通过方式。
- `reveal: {before, after}`：通过前后隐藏与显露的内容。
- `sensory_shift`：尺度、光色、表面、声场如何变化。

外部相接而本包未设计的地方写在 `scope.edges`，不伪造不存在的内部 Zone。一个转角可以是 Connection；有独立活动空间的平台可以是 Zone。

### VisualElement：单独设计值得被记住的物件

| 字段 | 类型 | 设计责任 |
| --- | --- | --- |
| `id`, `name` | text | 身份 |
| `zone_ids` | text[] | 物件实际位于或跨接的区域，不是“所有能看见它的区域” |
| `placement` | text | 相对位置、朝向；不随取景变化 |
| `visual_role` | text | 它给场景贡献什么识别性、层次或局部吸引力 |
| `form` | `{silhouette, proportions, parts}` | 外轮廓、比例、主要组成；避免只有名词或风格词 |
| `surface_uses` | SurfaceUse[] | 材质在物件上的具体分布 |
| `representation` | `{geometry, surface_images, flat_elements}` | 模型厚度、表面绘制、独立二维元素各承担什么 |
| `integration` | `{contact, lighting, occlusion_and_angles}` | 接触、受光、遮挡，以及侧看/近看时如何成立 |

同一个橱窗即使从院内与店内都能看到，也只定义一次。若整体店面和重点橱窗分别成为 Element，店面描述引用橱窗，不再重新定义它的形状。这里不建立泛化的资产父子系统。

`DressingGroup = {id, zone_id, contents, arrangement, visual_role, surface_uses}`。用种类、数量级、分布与疏密描述组内物件，不逐个复制主要物件的字段。

`ExperienceMoment = {id, zone_ids, cue, action, visual_payoff, capability_note}`。`capability_note` 说明对步行、推门、蹲下或登高等动作的依赖；是设计要求，不证明已实现。探索不必附加任务奖励。

### 状态与设计的区别

`initial_state` 为门、人物等提供一套基准画面状态。推开门、人物转头属于视角中的状态变化；移动门的位置、改变人物造型属于设计变化。二者不能混为一个“修改场景”字段。

## 3. VisualProductionPlan

一份对应一个 SceneDesign 版本的一轮视觉探索。它可以按需只做近看图，不要求每轮三类图都齐全。

| 字段 | 类型 | 设计责任 |
| --- | --- | --- |
| `id`, `revision`, `title` | text | 本轮计划身份 |
| `scene_design` | Ref | 指向本轮依据的场景版本；其项目美术约定沿引用链取得，不另设可能冲突的风格版本 |
| `exploration` | `{focus, preserve, may_vary}` | 探索问题、保留内容、可变内容 |
| `views` | View[] | 这一轮实际使用的取景设计，可供场景图、近看图和分镜共用 |
| `variants` | Variant[] | 按需的局部备选，不修改主方案 |
| `scene_views` | SceneViewDeliverable[] | 场景视角图的交付要求 |
| `object_studies` | ObjectStudyDeliverable[] | 主要物件近看图的交付要求 |
| `storyboards` | StoryboardDeliverable[] | 体验分镜的交付要求 |

### View：一个可复用的画面设计

`View = {id, camera, subjects, composition, emphasis, state_changes}`。

- `camera = {zone_id, position, eye_level, look_toward, framing}`：相对站位、高度、朝向与取景范围。人物研究图也应说明是在场景中观察，还是另做独立设定图；样例采用场景内观察。
- `subjects = {zone_ids, connection_ids, element_ids}`：该画面需表现哪些已定义空间、过渡和物件；未出现的类型写空数组。
- `composition`：前景如何切入、中景如何展开、视觉焦点落在哪里。
- `emphasis`：希望这张图帮助判断的美术问题。
- `state_changes`：相对于 SceneDesign.initial_state 的画面状态差异；每个 View 独立解释，不默认继承前一个分镜的状态。无变化写空数组。

取景定义只写一次。同一个 View 可以用于场景图，也可以作为分镜的一帧。复用描述不保证生成像素一致；需要延续已选画面时，应把实际图像作为参考传给后续生成。

### 图像交付：三类用途，一套取景

共同字段：`id`, `variant_id`, `presentation`, `reference_deliverable_ids`。

- `presentation` 是该图怎么排版、展示到什么程度的要求；不承担空间造型的重新定义。
- `variant_id` 为空表示主方案；有值时整张图或整组分镜应用同一个局部备选，避免同一组画面混用不同设计。
- `reference_deliverable_ids` 是本轮应先取得的其他图像交付 ID，不是尚未生成的文件路径。首次执行按依赖顺序生成；引用不存在的实际图片时不可声称已经使用参考。

三类结构：

- `SceneViewDeliverable = {共同字段, view_id}`。
- `ObjectStudyDeliverable = {共同字段, element_id, view_id}`。
- `StoryboardDeliverable = {共同字段, frames[]}`；`Frame = {id, view_id, player_action, visual_change}`。空间与构图从 View 取得；动作描述帧所示的动作，visual_change 说明与上一帧相比的体验变化。第一帧可写起始状态。

数量由设计需要决定。样例中的数量只是本轮选择，不是 Schema 的配额。

### Variant：局部探索的明确差异

`Variant = {id, changes[], expected_gain, preserve}`；`Change = {target_kind, target_id, change}`。

`target_kind` 暂取 element、material、zone、connection、light，定位场景中已有的对象。它继承主方案，只说明本轮允许范围内的差异；相关对象的变化可以在同一个备选中一起描述，不引入多备选组合或通用 JSON Patch 系统。新增整片空间或整体布局重构仍应另建场景方案。

仅负责提出。图片里的偶然漂移不是 Variant，选用 Variant 后仍需更新 SceneDesign 才成为后续共同设计。

## 4. 交接与实际结果

前三份是大模型的设计交付；图像文件、执行状态及选用记录由实际执行产生，不增加为第四份当前美术设计 Schema。第四份仍指未来资产制作契约。

生成一张图需要的内容组合：项目美术约定 → 本版场景整体美术 → 相关区域/连接/物件及其材料 → View 与状态 → 如有 Variant 则应用其局部差异 → 交付版式与实际参考图。引用信息由调用流程展开，不能只把 ID 当成提示词。

生成后的修改建议保持简单：指向已有物件或区域，说明变化、美术收益和实际参考图。选用后修订主方案，对受影响的视角补图；图像结果不能静默更改场景设计。

## 5. 本稿通过实例要回答的问题

1. 一件物体被多个区域看见时，是否仍然只定义一次？
2. 表面材料能否指导出图，而不仅是资产名称？
3. 转角、穿门和回望能否组成连续的体验？
4. 同一画面能否被场景图与分镜引用，而不重复维护构图？
5. 局部备选是否保留明确的主方案，且不凭空出现已经生成的图片？

这些是设计走读问题，不是本轮自动化验收门槛。下一步需实际出图检视美术效果；JSON 可解析不能证明画面有吸引力。
