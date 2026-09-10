"""Real MCP stdio client: inspect, then send the reproducible model script."""
import asyncio
import base64
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
PROMPT = '好，暂定使用Godot加上Blender MCP， 还有CodeX内的GenImage来执行。现在先做一个小样。'

async def main():
    env = dict(os.environ, DISABLE_TELEMETRY='true', BLENDER_HOST='127.0.0.1', BLENDER_PORT='9876')
    params = StdioServerParameters(command=str(HERE / '.venv/bin/blender-mcp'), env=env)
    log = {'timestamp': datetime.now(timezone.utc).isoformat(), 'transport': 'MCP stdio -> upstream server -> localhost:9876 -> upstream Blender addon', 'calls': []}
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            init = await session.initialize()
            log['initialize'] = init.model_dump(mode='json')
            available = await session.list_tools()
            log['tools'] = [t.name for t in available.tools]
            # Upstream Git source omits blender_mcp.config, so get_addon_status
            # fails in its telemetry helper. Inspect addon state through bpy
            # instead; keep the unmodified pinned upstream server and addon.
            for name, args in [('get_scene_info', {'user_prompt': PROMPT}), ('execute_blender_code', {'code': "import bpy, sys, json; a=sys.modules['fallen_blender_mcp']; print(json.dumps({'blender':bpy.app.version_string,'telemetry_consent':a._telemetry_consent_enabled(),'addon_server_running':bpy.types.blendermcp_server.running,'services':{n:getattr(bpy.context.scene,'blendermcp_use_'+n) for n in ('polyhaven','hyper3d','hunyuan3d','sketchfab','polypizza')}}))", 'user_prompt': PROMPT})]:
                result = await session.call_tool(name, args)
                log['calls'].append({'tool': name, 'result': result.model_dump(mode='json')})
                print(name, result, flush=True)
            if '--inspect-only' not in sys.argv:
                source = Path(sys.argv[sys.argv.index('--source') + 1]).resolve() if '--source' in sys.argv else HERE / 'make_street_props.py'
                script = source.read_text().replace('__PROJECT_ROOT__', str(ROOT))
                result = await session.call_tool('execute_blender_code', {'code': script, 'user_prompt': PROMPT})
                log['calls'].append({'tool': 'execute_blender_code', 'source': str(source), 'result': result.model_dump(mode='json')})
                print('execute_blender_code', result, flush=True)
                if any(getattr(block, 'text', '').startswith('Error executing code') for block in result.content):
                    raise RuntimeError('Blender execution failed; see the preceding MCP response')
                result = await session.call_tool('get_scene_info', {'user_prompt': PROMPT})
                log['calls'].append({'tool': 'get_scene_info', 'result': result.model_dump(mode='json')})
            if '--screenshot' in sys.argv:
                result = await session.call_tool('get_viewport_screenshot', {'max_size':1200,'user_prompt':PROMPT})
                for block in result.content:
                    if block.type == 'image':
                        (ROOT / 'art/blender/street_props_viewport.png').write_bytes(base64.b64decode(block.data))
                log['viewport_screenshot'] = {'isError':result.isError,'content_types':[b.type for b in result.content]}
    (HERE / 'logs').mkdir(exist_ok=True)
    name = 'inspect.json' if '--inspect-only' in sys.argv else 'model-build.json'
    if '--source' in sys.argv:
        name = Path(sys.argv[sys.argv.index('--source') + 1]).stem + '.json'
    (HERE / 'logs' / name).write_text(json.dumps(log, ensure_ascii=False, indent=2))

asyncio.run(main())
