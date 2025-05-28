set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <feature-name>"
    echo "Example: $0 dashboard-redesign"
    exit 1
fi

check_playwright_status() {
    echo "🎭 Checking Playwright MCP server status..."

    if lsof -i :8931 >/dev/null 2>&1; then
        echo "   ✅ Playwright MCP server is running on port 8931"
        return 0
    else
        echo "   ❌ Playwright MCP server is not running on port 8931"

        cd "$SCRIPT_DIR"
        make playwright
        return $?
    fi
}

FEATURE_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_NAME="${FEATURE_NAME}"
WORKSPACE_PATH="${REPO_ROOT}/codegen/workspaces/${WORKSPACE_NAME}"
BRANCH_NAME="feature/${FEATURE_NAME}"

echo "🌳 Creating feature workspace for: $FEATURE_NAME"

check_playwright_status

mkdir -p "$REPO_ROOT/codegen/workspaces"

if [ -d "$WORKSPACE_PATH" ]; then
    echo "💡 Feature workspace '$FEATURE_NAME' already exists!"
    echo "   Use 'make resume $FEATURE_NAME' to reopen it in Cursor"
    echo "   Or use 'make rm $FEATURE_NAME' to remove and recreate it"
    exit 0
fi

get_next_port() {
    local base_port=4001
    local current_port=$base_port

    while true; do
        local port_in_use=false

        for workspace_dir in "$REPO_ROOT"/codegen/workspaces/*; do
            if [ -d "$workspace_dir" ] && [ -f "$workspace_dir/.env" ]; then
                if grep -q "^PORT=$current_port" "$workspace_dir/.env" 2>/dev/null; then
                    port_in_use=true
                    break
                fi
            fi
        done

        if ! $port_in_use && lsof -i :$current_port >/dev/null 2>&1; then
            port_in_use=true
        fi

        if ! $port_in_use; then
            echo $current_port
            return
        fi

        ((current_port++))

        if [ $current_port -gt 4100 ]; then
            echo "❌ Error: Could not find available port (checked up to 4100)"
            exit 1
        fi
    done
}

echo "📁 Creating feature workspace at: $WORKSPACE_PATH"
cd "$REPO_ROOT"

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    git worktree add "$WORKSPACE_PATH" "$BRANCH_NAME" >/dev/null 2>&1
else
    git worktree add "$WORKSPACE_PATH" -b "$BRANCH_NAME" >/dev/null 2>&1
fi

cd "$WORKSPACE_PATH"

echo "📦 Workspace created - setup will happen in the new workspace"
echo ""

if [ -f "$REPO_ROOT/.env" ]; then
    cp "$REPO_ROOT/.env" "$WORKSPACE_PATH/.env"

    NEXT_PORT=$(get_next_port)
    PARTITION=$((NEXT_PORT - 4000))

    echo "" >>"$WORKSPACE_PATH/.env"
    echo "
    echo "PORT=$NEXT_PORT" >>"$WORKSPACE_PATH/.env"
    echo "MIX_DEV_PARTITION=$PARTITION" >>"$WORKSPACE_PATH/.env"
    echo "MIX_TEST_PARTITION=$PARTITION" >>"$WORKSPACE_PATH/.env"
else
    
    NEXT_PORT=$(get_next_port)
    PARTITION=$((NEXT_PORT - 4000))
    echo "
    echo "PORT=$NEXT_PORT" >>"$WORKSPACE_PATH/.env"
    echo "MIX_DEV_PARTITION=$PARTITION" >>"$WORKSPACE_PATH/.env"
    echo "MIX_TEST_PARTITION=$PARTITION" >>"$WORKSPACE_PATH/.env"
fi

echo "⚙️  Setting up workspace (port: $NEXT_PORT, partition: $PARTITION)..."

if [ -f "$WORKSPACE_PATH/.cursor/mcp.json" ]; then

    if [[ "$OSTYPE" == "darwin"* ]]; then

        sed -i '' "s/localhost:4000/localhost:$NEXT_PORT/g" "$WORKSPACE_PATH/.cursor/mcp.json"
    else

        sed -i "s/localhost:4000/localhost:$NEXT_PORT/g" "$WORKSPACE_PATH/.cursor/mcp.json"
    fi
fi

mkdir -p "$WORKSPACE_PATH/.vscode"

if [ -f "$SCRIPT_DIR/templates/.vscode/settings.json" ]; then
    cp "$SCRIPT_DIR/templates/.vscode/settings.json" "$WORKSPACE_PATH/.vscode/"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/4000/$NEXT_PORT/g" "$WORKSPACE_PATH/.vscode/settings.json"
    else
        sed -i "s/4000/$NEXT_PORT/g" "$WORKSPACE_PATH/.vscode/settings.json"
    fi
fi

if [ -f "$SCRIPT_DIR/templates/.vscode/tasks.json" ]; then
    cp "$SCRIPT_DIR/templates/.vscode/tasks.json" "$WORKSPACE_PATH/.vscode/"
fi

if [ -f "$SCRIPT_DIR/templates/feature-workspace.code-workspace" ]; then
    cp "$SCRIPT_DIR/templates/feature-workspace.code-workspace" "$WORKSPACE_PATH/${FEATURE_NAME}.code-workspace"
fi

if [ -f "$SCRIPT_DIR/templates/startup.sh" ]; then
    cp "$SCRIPT_DIR/templates/startup.sh" "$WORKSPACE_PATH/"
    chmod +x "$WORKSPACE_PATH/startup.sh"
fi

if [ -f "$SCRIPT_DIR/plans/${FEATURE_NAME}.md" ]; then
    cp "$SCRIPT_DIR/plans/${FEATURE_NAME}.md" "$WORKSPACE_PATH/PLAN.md"
fi

if command -v cursor >/dev/null 2>&1; then

    if [ -f "$WORKSPACE_PATH/${FEATURE_NAME}.code-workspace" ]; then
        cursor "$WORKSPACE_PATH/${FEATURE_NAME}.code-workspace" &
    else
        cursor "$WORKSPACE_PATH" &
    fi

    echo "✅ Workspace created successfully!"
else
    echo "❌ Cursor command not found. Please install Cursor or open the workspace manually:"
    echo "   📁 $WORKSPACE_PATH"
fi

echo ""
echo "🎉 Workspace ready: $FEATURE_NAME"
echo "🔌 Port: $NEXT_PORT | 🗄️ Partition: $PARTITION | 🌿 Branch: $BRANCH_NAME"
echo "🗄️  Database (dev): bemeda_personal_dev$PARTITION | Database (test): bemeda_personal_test$PARTITION"
echo ""
echo "🌐 Server will be available at: http://localhost:$NEXT_PORT"
echo "📁 $WORKSPACE_PATH"
if [ -f "$WORKSPACE_PATH/PLAN.md" ]; then
    echo "📋 Plan: PLAN.md"
fi
echo ""
echo "🚀 Further setup will continue in the new Cursor window"
echo ""
echo "To remove: make rm $FEATURE_NAME"
