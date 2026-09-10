# 场景美术契约 v0.2：通用字段与移动场景

2026-09-10。字段草案；不包含运行实现或可执行 JSON Schema。三组当前核心契约及一组后续资产制作契约的分工不变。

## Schema 与实例分开阅读

当前项目选用的美术内容见 [ProjectArtDirection v0.2](project-art-direction-v0.2.md)，引用 `jiangcheng_retro_electric_noir@v0.2`。本文件的通用字段版本与美术预设内容版本分别管理；下方历史示例继续保留原始美术引用。

- Schema 规定 AI 要作出哪些设计决定，以及这些决定怎样关联。
- 唱片店、驳船、湿地、桥和敌人是实例中的内容，不是固定字段或固定关卡。
- 本稿以 [v0.1](fields-v0.1.md) 的美术核心为基础，增加下述按需字段并明确覆盖的语义。未列出的字段沿用 v0.1。
- [唱片店实例](examples/README.md) 保持原样，按静态默认值解释即可；[驳船实例](examples/wetland-barge/README.md) 使用移动与遭遇字段。两例共用同一份项目美术约定，不为湿地再建立一套不同的画风 Schema。
- 当前按“场景本身需要什么”选择字段；不提供固定的 shop、barge、combat 等场景类型开关。

## 通用骨架

```text
ProjectArtDirection                         项目共享
  intent / linework / values / surfaces / hybrid / scene_freedom / references

SceneDesign                                 一个完整主方案
  art_direction                             引用项目美术约定
  intent / art                              主形象、造型、材质、光色、氛围
  scope                                     内容范围与外部衔接
    handoffs[]                              按需：到另一场景的交接
  space
    zones[] / connections[] / relations[]    空间构成
    routes[]                                按需：穿越空间的连续路线
  elements[]                                主要视觉物件
    form / surface_uses / representation / integration
    motion                                  按需：固定、依附、沿路移动或局部机动
  dressing[]                                成组陈设，按需依附移动物件
  initial_state                             基准状态
  experience[]                              体验时刻的具体设计
    cue / action / visual_payoff / capability_note
    at / observer / situation               按需：进度、观察者位置、当时状态
    encounters[]                            按需：有威胁的显露与空间关系
  progression                               按需：体验时刻的顺序与推进条件

VisualProductionPlan                        一轮视觉探索
  scene_design / exploration / variants
  views[]
    moment_id                               按需：这是什么体验时刻
    camera.anchor_element_id                按需：视点依附哪个移动物件
    camera.position / look_toward / framing  相对于锚定对象的取景
  scene_views[] / object_studies[] / storyboards[]
```

主形象、材质、线条与场景表现仍为核心。新增字段使移动过程能被设计，不把输出重心改为敌人逻辑或事件配置。

## 1. 路线：space.routes

`Route = {id, name, segments[]}`。

`RouteSegment = {id, zone_ids, connection_ids, course, visual_rhythm}`。

- segments 的顺序描述路线的空间经过顺序，不是镜头剪辑顺序。
- `course` 描述走向、弯曲、接近方向；暂不要求样条控制点或精确距离。
- `visual_rhythm` 描述视野怎样压缩/展开，地标何时显露与接近。
- zones 定义地方本身，connections 定义地方之间怎样相接，routes 定义一次怎样经过这些地方。它们各自承担不同信息。
- 同一个地方可被多次经过；有折返需求时允许不同路线分段引用相同区域，不复制那个区域。

普通房间不必填写路线。驳船、车行、步行巡游都可以使用这一字段。

## 2. 移动关系：elements[].motion

使用按 mode 区分的结构，不要求所有对象填满所有选项：

| mode | 其他字段 | 意义 |
| --- | --- | --- |
| fixed | 无 | 默认固定，整个 motion 可省略 |
| route | `route_id`, `behavior` | 沿已定义路线移动；behavior 描述速度感、转向与姿态 |
| attached | `anchor_element_id`, `offset`, `behavior` | 依附另一个物件，例如驾驶者站在追击船尾 |
| local | `region_ids`, `behavior` | 在若干区域内局部运动，如敌船从侧后方接近，不必单建第二条完整路线 |

不引入 barge 专属的移动类型。

位置语义：固定物件沿用 v0.1；移动物件的 `zone_ids` 和 `placement` 表达初始位置，之后的位置由 motion 与体验时刻共同决定，不能把所有可能经过的区域当成它同时占据的区域。依附对象的 region 和朝向随锚定对象解释。

成组陈设 `dressing[].anchor_element_id` 可省略；有值时 arrangement 是相对于锚定物件的分布，zone_id 表示初始区域。例如甲板上的绳圈随船移动。

光源 `art.lighting[].anchor_element_id` 可省略；有值时 placement 和 reach 相对于这个物件解释。例如船灯跟随船头，桥上的灯固定在桥上。不能让船离岸后把属于船的灯留在码头。

## 3. 体验推进：扩展已有 experience，不重复建立一份分镜剧情

沿用 `ExperienceMoment` 的美术体验字段，并按需增加：

| 字段 | 结构 | 作用 |
| --- | --- | --- |
| `at` | `{route_id, segment_id, position}` | 此时位于哪条路线的哪段，靠近、穿越或刚驶离哪个位置 |
| `observer` | `{zone_id, anchor_element_id, position}` | 此时玩家在哪个区域，是否在移动物件上；anchor 可为 null |
| `situation` | `{element_id, zone_id, location, visibility, action}[]` | 该时刻相关物件的位置、显露与行动，支持独立画出这个时刻 |
| `encounters` | Encounter[] | 有需要时描述威胁的显露、攻击方向与空间读法 |

`situation` 表达相对 initial_state 的自足快照，不默认累计前一时刻的差异；对画面相关的移动物件要说明当时位置。未列出的物件沿用初始状态或 motion 的明确依附关系。依附对象的位置以锚定对象更新后的状态解释，不保留在初始区域。

`progression = {moment_ids, transitions[]}`；`Transition = {from_moment, to_moment, when}`。

- experience 存内容，progression 只引用顺序和推进条件，不另写一套不同的事件。
- 条件可用自然语言，如“玩家登船后”“船头接近第一座桥”；不在这里编写触发器代码。
- 目前这个结构表达一条意向体验顺序。多分支、回环与可重复事件的运行语义尚未设计，不声称它是完整的游戏状态机。
- 无需强制先后时，可不填写 progression。原唱片店实例仍可表达自由观察，不被迫改成七段流程。

`Encounter = {actor_ids, warning, action, spatial_pressure, readability, transition}`。

- 描述敌人从哪里显露、做什么、对哪些方向施加压力，以及玩家怎样看清。
- `transition` 描述该段威胁怎样结束或转移，如岸上敌人被桥体遮住、追击船减速退出。
- 不定义伤害、命中率、寻路或完整 AI 行为。敌人是可选内容；同一套字段允许不含敌人的航行。
- 敌人和船的造型仍在 elements 中设计，不能只存在于遭遇文字里。

## 4. 视角跟随：View.moment_id 与 camera.anchor_element_id

- `moment_id` 可省略；有值时先读取对应体验时刻的进度、观察者位置与 situation。
- `camera.anchor_element_id` 为 null 或省略时，position 使用世界中的区域参照；有值时 position、eye_level、look_toward 必须写明相对于该物件的站位和方向，例如“船首左侧，朝航行前方”。
- 无锚定物件但 moment 有 observer 时，不能自动猜测跟随关系，View 应明确声明。
- `camera.zone_id` 指当前画面所在区域，不把它当成船永远固定的区域；应与 moment 的观察者位置相符。
- v0.2 的状态组合顺序是 initial_state → moment 的快照及移动/依附关系 → View.state_changes 的镜头内差异。没有 moment 时，仍按 v0.1 相对于 initial_state 解释。
- View.state_changes 只处理镜头内瞬间姿态等变化。若改变这段遭遇或整段体验，应修订 SceneDesign 中的时刻，避免分镜另编一套流程。
- Frame 继续引用 View，不重复维护 moment_id。镜头“在船上”本身不意味着第一人称；样例显式采用玩家视角。

场景图、分镜与船体近看可以共享体验时刻，但不必共享视点：例如靠岸后从岸上研究船体，应为独立 View 指定岸上站位，而不是假装玩家仍站在船头。

## 5. 衔接下一场景：scope.handoffs

`Handoff = {id, zone_id, next_scene_ref, arrival_state, continuity}`。

- `next_scene_ref` 未建立时可为空，不伪造下一份 SceneDesign。
- `arrival_state` 描述交接时玩家、交通工具或关键物件的状态。
- `continuity` 描述要保持的出口位置、朝向、地标、天气和光色关系。
- 当前末段和下一场景入口共同遵循选定的交接设计，不要求两边重复建造完整水路。
- 数据只表达设计交接，不决定 Godot 场景加载方式。

## 两个实例使用同一套结构

| 表达能力 | 唱片店 | 驳船 |
| --- | --- | --- |
| 项目美术约定 | noir_comic@draft-01 | 直接复用同一份 |
| 场景美术与空间 | 木店面、砖墙、巷口、小院 | 水面、湿地、两座桥、码头 |
| 主要视觉物件 | 橱窗、雨棚、人物 | 驳船、两座桥、敌船与人物 |
| routes | 可省略 | 一条分段水路 |
| motion | 可省略，固定默认 | 沿路、依附、局部机动 |
| experience / progression | 观察时刻，顺序不强制 | 登船到上岸的一条意向经历 |
| encounters | 可省略 | 草丛显露攻击、敌船接近 |
| 镜头锚定 | 世界位置 | 船上观察与上岸观察 |
| handoffs | 当前未展开 | 终点码头向未设计陆地场景交接 |

## 新字段仍是提案

用户已同意用第二个移动场景检视通用性，但这不等于选择了驳船样例中的具体路线、桥形、敌人造型和节奏。v0.2 旨在使这些决定可以表达；美术效果、航行舒适度和交战节奏仍需后续图像与可行走样片。
