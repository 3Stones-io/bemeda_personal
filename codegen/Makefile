# Optimum Codegen
# Usage: make [command]

new:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make new <feature-name>"; \
		echo "Example: make new dashboard-redesign"; \
		exit 1; \
	fi
	@./create_workspace.sh $(filter-out $@,$(MAKECMDGOALS))

batch:
	@echo "🚀 Creating codegen features from all available plans..."
	@if [ ! -d "plans" ]; then \
		echo "   ❌ No plans directory found"; \
		exit 1; \
	fi
	@plan_count=$$(ls plans/*.md 2>/dev/null | wc -l); \
	if [ $$plan_count -eq 0 ]; then \
		echo "   ❌ No plan files found in plans/ directory"; \
		exit 1; \
	fi
	@echo "   📋 Found $$plan_count plan(s) to process"
	@for plan in plans/*.md; do \
		if [ -f "$$plan" ]; then \
			name=$$(basename "$$plan" .md); \
			echo "   🎨 Creating codegen feature: $$name"; \
			$(MAKE) new "$$name" || echo "   ⚠️  Failed to create workspace for $$name"; \
		fi; \
	done
	@echo "   ✅ Finished processing all plans"

clean:
	@echo "🧹 Removing all feature workspaces..."
	@if ! ./list_workspaces.sh 2>/dev/null | grep "^📁" | grep -v "Main Repository" | head -1 >/dev/null; then \
		echo "   ℹ️  No feature workspaces found to remove"; \
		exit 0; \
	fi
	@echo "   📋 Found workspaces to remove:"
	@./list_workspaces.sh 2>/dev/null | grep "^📁" | grep -v "Main Repository" | sed 's/^📁 //' | sed 's/^/      - /'
	@echo "   ⚠️  This will remove ALL feature workspaces. Continue? [y/N]"; \
	read -r confirm; \
	if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
		echo "   ❌ Operation cancelled"; \
		exit 1; \
	fi
	@for workspace in $$(./list_workspaces.sh 2>/dev/null | grep "^📁" | grep -v "Main Repository" | sed 's/^📁 //'); do \
		echo "   🗑️  Removing workspace: $$workspace"; \
		$(MAKE) rm "$$workspace" || echo "   ⚠️  Failed to remove workspace: $$workspace"; \
	done
	@echo "   ✅ Finished removing all workspaces"

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

help:
	@echo "🚀 Optimum Codegen"
	@echo "================="
	@echo ""
	@echo "⚡ Commands:"
	@echo "  make new <name>                  🎨 Create new feature workspace"
	@echo "  make batch                       🎯 Create feature workspaces from all available plans"
	@echo "  make rm <name>                   🗑️  Remove feature workspace"
	@echo "  make clean                       🧹 Remove ALL feature workspaces (with confirmation)"
	@echo "  make resume <name>               🔄 Resume feature workspace"
	@echo "  make ls                          📋 List all feature workspaces"
	@echo ""
	@echo "📋 Recommended Workflow:"
	@echo "  1. (Optional) Ask Cursor to create a plan in plans/<name>.md"
	@echo "  2. Run: make new <name> (automatically starts Playwright and includes the plan if it exists)"
	@echo "  3. Or run: make batch to create feature workspaces from all available plans"
	@echo "  4. Use: make clean to remove all workspaces when done"
	@echo ""
	@echo "📝 Examples:"
	@echo "  make new dashboard-redesign"
	@echo "  make batch"
	@echo "  make rm dashboard-redesign"
	@echo "  make clean"
	@echo "  make resume dashboard-redesign"
	@echo "  make ls"

# Default target shows help
.DEFAULT_GOAL := help

# Prevent make from treating arguments as targets
%:
	@:
