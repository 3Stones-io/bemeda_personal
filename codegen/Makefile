# Optimum Codegen
# Usage: make [command]

new:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make new <feature-name>"; \
		echo "Example: make new dashboard-redesign"; \
		exit 1; \
	fi
	@./create_workspace.sh $(filter-out $@,$(MAKECMDGOALS))

rm:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make rm <feature-name>"; \
		echo "Example: make rm dashboard-redesign"; \
		exit 1; \
	fi
	@./remove_workspace.sh $(filter-out $@,$(MAKECMDGOALS))

resume:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make resume <feature-name>"; \
		echo "Example: make resume dashboard-redesign"; \
		exit 1; \
	fi
	@./resume_workspace.sh $(filter-out $@,$(MAKECMDGOALS))

ls:
	@./list_workspaces.sh

playwright:
	@echo "🎭 Starting Playwright MCP server..."
	@if lsof -i :8931 >/dev/null 2>&1; then \
		echo "   ✅ Playwright MCP server is already running on port 8931"; \
	else \
		npx @playwright/mcp@latest --port 8931 >/dev/null 2>&1 & \
		echo "   🚀 Playwright MCP server started in background"; \
		echo "   ⏳ Waiting for server to be ready..."; \
		max_attempts=30; \
		attempt=0; \
		while [ $$attempt -lt $$max_attempts ]; do \
			if lsof -i :8931 >/dev/null 2>&1; then \
				echo "   ✅ Playwright MCP server is ready on port 8931"; \
				echo "   📊 Process ID: $$(lsof -ti tcp:8931 | head -1)"; \
				break; \
			fi; \
			sleep 1; \
			attempt=$$((attempt + 1)); \
		done; \
		if [ $$attempt -eq $$max_attempts ]; then \
			echo "   ❌ Failed to start Playwright MCP server within 30 seconds"; \
			exit 1; \
		fi; \
	fi

kill-playwright:
	@echo "⛔ Stopping Playwright MCP server..."
	@if lsof -i :8931 >/dev/null 2>&1; then \
		lsof -ti tcp:8931 | xargs kill -9 2>/dev/null; \
		echo "   ✅ Playwright MCP server stopped"; \
	else \
		echo "   ℹ️  Playwright MCP server was not running"; \
	fi

status:
	@./list_workspaces.sh
	@echo ""
	@echo "🎭 Playwright MCP Server Status:"
	@if lsof -i :8931 >/dev/null 2>&1; then \
		echo "   ✅ Running on port 8931"; \
		echo "   📊 Process: $$(lsof -ti tcp:8931 | head -1)"; \
	else \
		echo "   ❌ Not running"; \
		echo "   💡 Start with: make playwright"; \
	fi

help:
	@echo "🚀 Optimum Codegen"
	@echo "================="
	@echo ""
	@echo "⚡ Commands:"
	@echo "  make new <name>                  🎨 Create new feature workspace"
	@echo "  make rm <name>                   🗑️  Remove feature workspace"
	@echo "  make resume <name>               🔄 Resume feature workspace"
	@echo "  make ls                          📋 List all feature workspaces"
	@echo "  make playwright                  🎭 Start playwright MCP server on port 8931 (background)"
	@echo "  make kill-playwright             ⛔ Stop playwright MCP server"
	@echo "  make status                      📊 List workspaces and check playwright MCP server status"
	@echo ""
	@echo "📋 Recommended Workflow:"
	@echo "  1. (Optional) Ask Cursor to create a plan in plans/<name>.md"
	@echo "  2. Run: make new <name> (automatically starts Playwright and includes the plan if it exists)"
	@echo ""
	@echo "📝 Examples:"
	@echo "  make new dashboard-redesign"
	@echo "  make rm dashboard-redesign"
	@echo "  make resume dashboard-redesign"
	@echo "  make ls"
	@echo "  make status"
	@echo "  make playwright"
	@echo "  make kill-playwright"

# Default target shows help
.DEFAULT_GOAL := help

# Prevent make from treating arguments as targets
%:
	@:
