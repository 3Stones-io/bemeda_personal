#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <feature-name>"
    echo "Example: $0 dashboard-redesign"
    exit 1
fi

FEATURE_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_PATH="${REPO_ROOT}/codegen/workspaces/${FEATURE_NAME}"

source "$SCRIPT_DIR/utils.sh"

echo "🔄 Resuming feature workspace: $FEATURE_NAME"

if [ ! -d "$WORKSPACE_PATH" ]; then
    echo "❌ Feature workspace '$FEATURE_NAME' does not exist!"
    echo "   Use '$OCG_CMD new $FEATURE_NAME' to create it"
    echo "   Or use '$OCG_CMD ls' to see available workspaces"
    exit 1
fi

cd "$WORKSPACE_PATH"

git submodule update --init --recursive >/dev/null 2>&1

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null | cut -c1-8 || echo "unknown")

if [ -f "$WORKSPACE_PATH/.env" ]; then
    PORT=$(grep "^PORT=" "$WORKSPACE_PATH/.env" 2>/dev/null | cut -d'=' -f2)
    PARTITION=$(grep "^MIX_DEV_PARTITION=" "$WORKSPACE_PATH/.env" 2>/dev/null | cut -d'=' -f2)
else
    PORT="not configured"
    PARTITION="not configured"
fi

# Create resume flag file for startup.sh to detect
touch "$WORKSPACE_PATH/.ocg_resume"

if [ -f "$SCRIPT_DIR/templates/RESUME_CONTEXT.md" ]; then
    cp "$SCRIPT_DIR/templates/RESUME_CONTEXT.md" "$WORKSPACE_PATH/RESUME_CONTEXT.md"
    sed -i '' "s|{{FEATURE_NAME}}|$FEATURE_NAME|g" "$WORKSPACE_PATH/RESUME_CONTEXT.md"
    sed -i '' "s|{{CURRENT_BRANCH}}|$CURRENT_BRANCH|g" "$WORKSPACE_PATH/RESUME_CONTEXT.md"
    sed -i '' "s|{{COMMIT_HASH}}|$COMMIT_HASH|g" "$WORKSPACE_PATH/RESUME_CONTEXT.md"
    sed -i '' "s|{{PORT}}|${PORT:-4000}|g" "$WORKSPACE_PATH/RESUME_CONTEXT.md"
    sed -i '' "s|{{PARTITION}}|${PARTITION:-0}|g" "$WORKSPACE_PATH/RESUME_CONTEXT.md"
fi

open_cursor_workspace "$WORKSPACE_PATH" "$FEATURE_NAME" "✅ Workspace resumed successfully!"

PLAYWRIGHT_PORT=$(grep "^PLAYWRIGHT_MCP_PORT=" "$WORKSPACE_PATH/.env" 2>/dev/null | cut -d'=' -f2)

echo ""
echo "🎯 Workspace resumed: $FEATURE_NAME"
if [ -n "$PORT" ] && [ "$PORT" != "not configured" ] && [ -n "$PLAYWRIGHT_PORT" ] && [ -n "$PARTITION" ]; then
    echo "🔌 Port: $PORT | 🎭 Playwright: $PLAYWRIGHT_PORT | 🗄️ Partition: $PARTITION | 🌿 Branch: $CURRENT_BRANCH"
fi
if [ -n "$PORT" ] && [ "$PORT" != "not configured" ]; then
    echo "🌐 Server will be available at: http://localhost:$PORT"
fi
echo "📁 $WORKSPACE_PATH"
if [ -f "$WORKSPACE_PATH/PLAN.md" ]; then
    echo "📋 Plan: PLAN.md"
fi
echo ""
echo "To remove: $OCG_CMD rm $FEATURE_NAME"
