# 小样验证记录

日期：2026-09-09。平台：macOS Apple Silicon；实际图形日志报告 Apple M4 Pro、OpenGL 4.1 Metal Compatibility。引擎：Godot 4.7.2 stable。

## 实际运行结果

| 验证 | 结果 | 证据 |
| --- | --- | --- |
| 资源加载 | 六张生成图片与 Blender GLB 全部载入 | [smoke-test.log](logs/smoke-test.log) |
| 门与碰撞 | 关闭阻挡角色、打开后可以穿过 | [smoke-test.log](logs/smoke-test.log) |
| 人物与任务 | 射线选中接头人、获得信封、限制提前离开、任务完成 | [smoke-test.log](logs/smoke-test.log) |
| 完整输入流程 | 实际移动输入与 E 事件驱动，走向门、进入、拿信、返回、离开；PASS，退出码 0 | [playtest.log](logs/playtest.log) |
| 游戏画面 | Godot 图形模式保存截图并目视检查：中文可读、透明人物轮廓正确、道具/纹理可见 | [接头人](screenshots/playtest/02-contact.png)、[拿到信封](screenshots/playtest/03-envelope.png)、[完成](screenshots/playtest/04-completed.png) |
| Blender MCP | 上游 MCP server 经标准 Python MCP 客户端实际建模、导出和视口截图 | [模型构建记录](../../tools/blender/logs/model-build.json)、[Blender 视口](../../art/blender/street_props_viewport.png) |

图形模式的完整流程测试使用正常 CharacterBody3D 物理移动和交互事件；转身由脚本控制相机方向，没有将传送或直接修改任务状态当作通关。测试覆盖这条小样路线，并非完整键鼠人工试玩或跨平台测试。

## 已处理问题

贴近门边时原有指向门中心的角度判定会导致 E 提示丢失，已改为门面最近点判定，并通过完整输入流程复验。

## 当前限制

- 人物使用单帧正面 billboard 与轻微起伏，未实现多方向动画。
- 尚无战斗、声音、存档和独立分发安装包。
- Blender MCP 由项目内客户端调用，尚未作为 Codex 原生工具注册。上游 `get_addon_status` 的缺模块问题及可用替代读取方式见 [说明](../../tools/blender/README.md)。
- Blender 本轮产出街角道具，主体房间与巷道由 Godot 脚本搭建。

## 生成资产

六张图片均由 Codex 内置 imagegen 实际生成；项目中的最终资产与原始返回文件一致，未调用 API fallback。完整提示词见 [art/imagegen](../../art/imagegen/)，像素尺寸和 SHA-256 见 [manifest.json](../../art/imagegen/manifest.json)。
