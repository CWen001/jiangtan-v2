# DEAD LETTER · 港口来信

一段可玩的原创黑色漫画街区小样：沿夜巷找到 NIGHTJAR 唱片店，推门进入，与接头人交谈，带着信封原路离开。

## 运行

在本机双击 **`启动小样.command`**，或用 Godot 导入 `game/project.godot`。

```sh
godot --path game
```

当前使用 Godot 4.7.2 Compatibility 渲染器，已安装到 `/Applications/Godot.app`。启动脚本依赖此安装位置；这是本机可运行的工程小样，尚未制作独立分发安装包。

## 操作

| 按键 | 操作 |
| --- | --- |
| WASD | 移动 |
| 鼠标 | 转动视角 |
| Shift | 快走 |
| E | 面向门、接头人或港口出口进行互动 |
| Esc | 释放鼠标，再按或点击返回 |
| R | 重开小样 |

走到巷道尽头推门进入，与红色夹克的接头人交谈。拿到信封后原路返回，面向出生点后方的港口出口按 E 完成。

## 工程与资产

- `game/`：Godot 工程、玩法脚本、场景和运行资产。
- `game/assets/generated/`：六张 Codex 内置 ImageGen 图片，人物、砖墙、铺地、海报、木纹、唱片封面。
- `art/imagegen/`：每张图的完整提示词、原始生成路径与校验信息。
- `art/blender/street_props.blend`：可编辑的街角道具源文件。
- `game/assets/models/street_props.glb`：经 Blender MCP 制作并导出的道具。
- [Blender MCP 流程](tools/blender/README.md)：接入与复现说明。当前通过项目内 Python MCP 客户端真实调用上游服务，未注册成 Codex 原生工具。
- [小样范围](docs/prototype/scope.md)、[参考资料](ref/README.md)、[工具链研究](ref/toolchain-research.md)。

人物目前是单张正面 billboard，带轻微站立起伏。尚无多方向行走动画、战斗、存档或声音。二维人物的制作方式可以在这个可运行基础上继续迭代。

## 检查与截图

从项目根目录运行：

```sh
godot --headless --path game --editor --import
godot --headless --path game -- --smoke-test
godot --path game -- --playtest --capture-dir=/tmp/dead-letter-playtest
```

`--smoke-test` 检查角色、门碰撞、互动与任务状态。`--playtest` 经实际移动输入和 E 按键完成进门、接头、返回出口的路线；图形模式同时保存四个阶段的截图并退出。完整记录在 [验证报告](docs/prototype/verification.md)。

普通固定机位截图：

```sh
godot --path game -- --capture=/tmp/dead-letter-alley.png
godot --path game -- --view=interior --capture=/tmp/dead-letter-interior.png
```
