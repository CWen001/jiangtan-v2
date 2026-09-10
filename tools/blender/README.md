# Blender MCP 小样资产流程

已验证 **Blender 4.5.13 LTS arm64 → upstream addon → upstream MCP server → Python MCP SDK stdio client**。Codex 从终端调用项目内客户端；本会话没有动态注册成 Codex 原生 MCP 工具。没有修改全局 Codex 设置或 Blender 用户配置。

上游为 [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)，固定 commit `5f8ddaf6e987c4aa0c3467fcc548838b28f64477`（package 1.9.1），元数据见 `upstream.json`。Blender 官方下载已校验 SHA256；应用在 `/Applications/Blender.app`。项目依赖使用 `uv` 和 Python 3.13，本地 vendor 与虚拟环境忽略版本管理。

## 复现

在项目根目录运行：

```sh
sh tools/blender/setup.sh
sh tools/blender/start.sh
```

`start.sh` 打开专用 Blender GUI 并加载 addon，需保持窗口运行。在另一个终端中执行：

```sh
tools/blender/.venv/bin/python tools/blender/mcp_client.py --screenshot
```

只验证连接、不重建模型：

```sh
tools/blender/.venv/bin/python tools/blender/mcp_client.py --inspect-only
```

MCP 客户端使用 `initialize`、`list_tools`、`get_scene_info`、`execute_blender_code`；传入的模型源脚本是 `make_street_props.py`。重建会覆盖本小样专用资产，修改模型之前先另存个人版本。`--screenshot` 通过真实 MCP 的 `get_viewport_screenshot` 保存 Blender 视口截图。

## 输出

- `art/blender/street_props.blend`：94 个可独立编辑的原始网格。
- `game/assets/models/street_props.glb`：合并后的一个网格、7 个材质面组，167196 bytes；Godot 导入自动转换为 Y-up。
- `art/blender/street_props_viewport.png`：从 MCP 捕获的视口证据。
- `tools/blender/logs/model-build.json`：MCP 初始化、工具调用结果及真实模型尺寸记录。

组合包含原创漫画比例垃圾桶、木箱、水管和纸屑。Blender Z-up 范围为 X `[-0.805, 0.822]`、Y `[-0.466, 0.332]`、Z `[0, 1.545]`；Godot 的 Y 轴高度为 `0..1.545`，宽 1.627m、深 0.799m，原点在地面。不含碰撞体，由游戏脚本按组合占地添加。

## 已知上游限制

该 Git commit 的源码树未提供 `blender_mcp.config`，`get_addon_status` 在调用其 telemetry helper 时会报缺少模块。未补造或修改 upstream 文件。可用的 `get_scene_info` 与 `execute_blender_code` 已实际调用成功；客户端通过后者读取 Blender 版本、addon server 状态和 telemetry 状态，详见 JSON 日志。此限制不影响已验证的建模、GLB 导出和视口截图路径。

`DISABLE_TELEMETRY=true` 同时作用于 Blender 和 server；addon 未安装持久化偏好，upstream 的无偏好策略为 consent=false。执行日志另验证 `telemetry_consent=false`，PolyHaven、Hyper3D、Hunyuan3D、Sketchfab、PolyPizza 均关闭。未调用任何外部资产生成或下载服务。关闭该专用 Blender 窗口即可停用本地 addon socket；stdio server 在每次客户端结束时退出。
