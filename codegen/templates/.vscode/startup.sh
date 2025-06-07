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
    echo "🔧 MCP servers configured"
    echo "   💡 Use Ctrl+Cmd+Shift+Option+M to open MCP settings and toggle servers when ready"
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

# Function to copy resume context to clipboard
copy_resume_context() {
    if [ ! -f "RESUME_CONTEXT.md" ]; then
        return 1
    fi

    # Get git status
    local git_status=$(git status --porcelain 2>/dev/null || echo "# Unable to get git status")
    if [ -z "$git_status" ]; then
        git_status="# Working directory clean"
    fi

    # Get commit log (difference between main and current branch)
    local commit_log=""
    if git rev-parse --verify main >/dev/null 2>&1; then
        local commit_count=$(git rev-list --count main..HEAD 2>/dev/null || echo "0")
        if [ "$commit_count" -gt 0 ]; then
            commit_log="Commits ahead of main: $commit_count"$'\n\n'
            commit_log+=$(git log --oneline main..HEAD 2>/dev/null || echo "# Unable to get commit log")
        else
            commit_log="# No commits ahead of main branch"
        fi
    else
        commit_log="# Main branch not found"
    fi

    # Fill placeholders in the resume context file
    local context=$(cat "RESUME_CONTEXT.md")
    context="${context//\{\{GIT_STATUS\}\}/$git_status}"
    context="${context//\{\{COMMIT_LOG\}\}/$commit_log}"

    echo "$context" | pbcopy
    rm "RESUME_CONTEXT.md"
}

# Function to copy CONTEXT.md to clipboard
copy_feature_context() {
    if [ -f "CONTEXT.md" ]; then
        cat "CONTEXT.md" | pbcopy
        rm "CONTEXT.md"
    else
        return 1
    fi
}

open_cursor_chat() {
    local context_type="$1"

    # Check if Cursor is running
    if ! pgrep -f "Cursor" >/dev/null 2>&1; then
        return 1
    fi

    # AppleScript to open chat and paste
    osascript <<'EOF' >/dev/null 2>&1
tell application "Cursor"
    activate
    delay 1
    
    tell application "System Events"
        -- Open Cursor chat with Cmd+L
        keystroke "l" using {command down}
        delay 1
        
        -- Clear any existing content in chat
        keystroke "a" using {command down}
        delay 0.5
        
        -- Paste the content using Cmd+V
        keystroke "v" using {command down}
        delay 0.5
        
        -- Don't auto-submit, let user review and press Enter manually
    end tell
end tell
EOF
}

open_mcp_settings() {
    # AppleScript to open MCP settings using keyboard shortcut
    osascript <<'EOF' >/dev/null 2>&1
tell application "Cursor"
    activate
    delay 1
    
    -- Ensure Cursor window is frontmost and focused
    tell application "System Events"
        tell process "Cursor"
            set frontmost to true
            delay 0.5
        end tell
        
        -- Open MCP settings with Ctrl+Cmd+Shift+Option+M
        keystroke "m" using {control down, command down, shift down, option down}
        delay 0.5
    end tell
end tell
EOF
}

show_workspace_summary() {
    local mode="$1"
    sleep 3 # Wait for server to start and settle

    echo ""
    echo "🎯 Feature workspace '$FEATURE_NAME' is ready!"
    echo "=================================="
    echo "🔌 Port: ${PORT:-4000}"
    echo "🎭 Playwright MCP Port: ${PLAYWRIGHT_MCP_PORT:-9222}"
    echo "🗄️  Database: bemeda_personal_dev${MIX_DEV_PARTITION:-0}"
    echo "🌐 Server: http://localhost:${PORT:-4000}"
    echo "=================================="
    echo "Next steps:"
    echo "✅ MCP settings opened for server configuration"
    echo "👉 Toggle server switches to restart MCP servers if needed"

    if [ "$mode" = "resume" ]; then
        echo "✅ Cursor chat opened with resume context!"
    else
        echo "✅ Cursor chat opened with feature context!"
    fi

    echo "👉 Review the content and press Enter when ready to submit"
}

# Detect if this is a resume operation and handle accordingly
if [ -f ".ocg_resume" ]; then
    echo "🔄 Resume mode detected - loading resume context..."
    rm ".ocg_resume" # Clean up flag file

    copy_resume_context

    if [ $? -eq 0 ]; then
        echo "🤖 Setting up Cursor automation..."
        open_cursor_chat "resume context" &

        if [ -f ".cursor/mcp.json" ]; then
            open_mcp_settings &
        fi

        show_workspace_summary "resume" &
    fi
else
    echo "🆕 New workspace mode - using feature context..."

    if [ -f ".cursor/mcp.json" ]; then
        echo "🤖 Setting up Cursor automation..."

        copy_feature_context
        if [ $? -eq 0 ]; then
            open_cursor_chat "feature context" &
            open_mcp_settings &
            show_workspace_summary "new" &
        fi
    fi
fi

echo ""
echo "🚀 Starting Phoenix server..."
echo "📝 Press Ctrl+C to stop the server"
echo ""

mix phx.server
