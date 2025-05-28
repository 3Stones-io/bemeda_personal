set -e

echo "🚀 Initializing feature workspace..."

WORKSPACE_ROOT="$(pwd)"
FEATURE_NAME="$(basename "$WORKSPACE_ROOT")"

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
echo "🗄️  Database: bemeda_personal_dev${MIX_DEV_PARTITION:-0}"

echo "📦 Copying build artifacts from main branch..."

REPO_ROOT="$(cd ../../../ && pwd)"

if [ -d "$REPO_ROOT/deps" ]; then
    cp -r "$REPO_ROOT/deps" .
fi

if [ -d "$REPO_ROOT/_build" ]; then
    cp -r "$REPO_ROOT/_build" .
fi

if [ -d "$REPO_ROOT/assets/node_modules" ]; then
    mkdir -p assets
    cp -r "$REPO_ROOT/assets/node_modules" assets/
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

echo ""
echo "🎯 Feature workspace '$FEATURE_NAME' is ready!"
echo "🌐 Starting Phoenix server on port ${PORT:-4000}..."
echo "📝 Press Ctrl+C to stop the server"
echo ""

mix phx.server
