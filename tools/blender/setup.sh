#!/bin/sh
set -eu
cd "$(dirname "$0")"
commit=5f8ddaf6e987c4aa0c3467fcc548838b28f64477
if [ ! -d vendor/blender-mcp/.git ]; then
    git clone https://github.com/ahujasid/blender-mcp.git vendor/blender-mcp
fi
git -C vendor/blender-mcp checkout --detach "$commit"
test "$(git -C vendor/blender-mcp rev-parse HEAD)" = "$commit"
if [ ! -x .venv/bin/python ]; then uv venv --python 3.13 .venv; fi
uv pip install --python .venv/bin/python -r requirements.lock
uv pip install --python .venv/bin/python --no-deps -e vendor/blender-mcp
