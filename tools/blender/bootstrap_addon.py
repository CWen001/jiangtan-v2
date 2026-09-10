"""Load the pinned upstream addon in a dedicated GUI Blender instance."""
import os
import sys
import importlib.util
from pathlib import Path
import bpy

os.environ['DISABLE_TELEMETRY'] = 'true'
root = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('fallen_blender_mcp', root / 'vendor/blender-mcp/addon.py')
addon = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = addon
spec.loader.exec_module(addon)
addon.register()
# Addon preferences are deliberately not persisted globally. Upstream's
# get_telemetry_consent fails closed when no preference registration exists.
assert addon._telemetry_consent_enabled() is False
for name in ('polyhaven', 'hyper3d', 'hunyuan3d', 'sketchfab', 'polypizza'):
    setattr(bpy.context.scene, 'blendermcp_use_' + name, False)
bpy.context.scene.blendermcp_auto_start_server = False
print('FALLEN_MCP_READY telemetry=false external_asset_services=false port=9876', flush=True)
