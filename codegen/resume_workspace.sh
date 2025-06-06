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

echo "📁 Workspace: $WORKSPACE_PATH"
echo "🌿 Branch: $CURRENT_BRANCH"
echo "📝 HEAD: $COMMIT_HASH"
if [ -n "$PORT" ] && [ "$PORT" != "not configured" ]; then
    echo "🔌 Port: $PORT"
fi
if [ -n "$PARTITION" ] && [ "$PARTITION" != "not configured" ]; then
    echo "🗄️ Partition: $PARTITION"
fi

if command -v cursor >/dev/null 2>&1; then
    echo ""
    echo "🚀 Opening workspace in Cursor..."

    if [ -f "$WORKSPACE_PATH/${FEATURE_NAME}.code-workspace" ]; then
        cursor "$WORKSPACE_PATH/${FEATURE_NAME}.code-workspace" &
    else
        cursor "$WORKSPACE_PATH" &
    fi

    echo "✅ Workspace resumed successfully!"

    if [ -n "$PORT" ] && [ "$PORT" != "not configured" ]; then
        echo "🌐 Server will be available at: http://localhost:$PORT"
    fi
else
    echo "❌ Cursor command not found. Please install Cursor or open the workspace manually:"
    echo "   📁 $WORKSPACE_PATH"
fi
