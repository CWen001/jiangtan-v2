# 灯下旧埠：首轮场景主方案

已按用户授权推进设计与小样。主方案是本轮制作决定；既有三张美术参考不直接充当统一空间。

[SceneDesign](scene-design.json) · [VisualProductionPlan](visual-production-plan.json)

步道 → 仓门进出 → 石阶上下。仓库在西、江面在东；可自由观察、推门、接近二维人物。首轮不含航行和战斗。

执行：Godot 复用已有玩家控制器，Blender 制作三维形体，ImageGen 制作人物和纹理。主视点1280×800，目标帧率至少30 FPS；截图不含文字界面。通过主目标对比及两个补充视点检查，不为主截图改变空间连接。正式选定产物保存于 art/harbor 和 docs/harbor，.dream-loop 只保存工作上下文。

## 当前结果

已实现独立可试玩码头入口 `启动码头小样.command`，详见[实际截图、检查结果与美术差距](../../../docs/harbor/verification.md)。行走和互动检查通过；视觉评审最高6.3/10，第二轮退步后恢复较好版本，尚未达到目标图标准。生成目标与运行结果分别保存。
