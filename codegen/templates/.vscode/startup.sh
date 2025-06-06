#!/bin/bash
set -e

echo "🚀 Initializing feature workspace..."

WORKSPACE_ROOT="$(pwd)"
FEATURE_NAME="$(basename "$WORKSPACE_ROOT")"

WINDOW_POSITION="{{WINDOW_POSITION}}"
TOTAL_WINDOWS="{{TOTAL_WINDOWS}}"
LAYOUT_STRATEGY="{{LAYOUT_STRATEGY}}"

echo "🖥️  Positioning Cursor window ($WINDOW_POSITION of $TOTAL_WINDOWS)..."
./.vscode/position-window.sh

echo "🔧 Activating mise and loading environment..."
if command -v mise >/dev/null 2>&1; then
    mise trust 2>/dev/null || true
    eval "$(mise activate bash)"
    eval "$(mise env)"
else
    echo "⚠️  mise not found, environment variables may not be loaded"
fi

echo "✅ Environment variables loaded"
echo "🔌 Port: ${PORT:-4000}"
echo "🎭 Playwright MCP Port: ${PLAYWRIGHT_MCP_PORT:-9222}"
echo "🗄️  Database: bemeda_personal_dev${MIX_DEV_PARTITION:-0}"

echo "📦 Copying build artifacts from main branch..."

REPO_ROOT="$(cd ../../../ && pwd)"

if [ -d "$REPO_ROOT/.elixir_ls" ] && [ ! -d ".elixir_ls" ]; then
    cp -r "$REPO_ROOT/.elixir_ls" .
fi

if [ -d "$REPO_ROOT/deps" ] && [ ! -d "deps" ]; then
    cp -r "$REPO_ROOT/deps" .
fi

if [ -d "$REPO_ROOT/_build" ] && [ ! -d "_build" ]; then
    cp -r "$REPO_ROOT/_build" .
fi

if [ -d "$REPO_ROOT/assets/node_modules" ] && [ ! -d "assets/node_modules" ]; then
    mkdir -p assets
    cp -r "$REPO_ROOT/assets/node_modules" assets/
fi

if [ -d "$REPO_ROOT/priv/plts" ] && [ ! -d "priv/plts" ]; then
    mkdir -p priv
    cp -r "$REPO_ROOT/priv/plts" priv/
fi

echo "📦 Running mix setup..."
echo "   This will install dependencies, setup database, and build assets..."
mix setup
echo "✅ Setup complete - dependencies, database, and assets ready"

if [ -f ".cursor/mcp.json" ]; then
    echo "🔧 MCP servers configured and should start automatically"
    echo "   If MCP servers show 'No tools available', manually restart them in:"
    echo "   Cursor Settings (Cmd+Shift+J) → MCP → Click the restart button for each server"
fi

echo "🎭 Starting Playwright MCP server..."
npx @playwright/mcp@latest --port $PLAYWRIGHT_MCP_PORT --headless 2>&1 &
echo "   🚀 Playwright MCP server started in background"
echo "   ⏳ Waiting for server to be ready..."

max_attempts=10
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if lsof -i :$PLAYWRIGHT_MCP_PORT >/dev/null 2>&1; then
        echo "   ✅ Playwright MCP server is ready on port $PLAYWRIGHT_MCP_PORT"
        echo "   📊 Process ID: $(lsof -ti tcp:$PLAYWRIGHT_MCP_PORT | head -1)"
        break
    fi
    sleep 1
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "   ❌ Failed to start Playwright MCP server within 10 seconds"
    exit 1
fi

echo ""
echo "🎯 Feature workspace '$FEATURE_NAME' is ready!"
echo "🌐 Starting Phoenix server on port ${PORT:-4000}..."
echo "📝 Press Ctrl+C to stop the server"
echo ""

mix phx.server
