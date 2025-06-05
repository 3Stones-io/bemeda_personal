#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PARENT_DIR="$(dirname "$REPO_ROOT")"

ACTION="${1:-status}"
ENVIRONMENT="${2:-both}"

case "$ACTION" in
"create" | "migrate" | "drop" | "status") ;;
*)
    echo "Usage: $0 [create|migrate|drop|status] [dev|test|both]"
    echo ""
    echo "Actions:"
    echo "  create  - Create databases for all feature workspaces"
    echo "  migrate - Run migrations for all feature workspaces"
    echo "  drop    - Drop databases for all feature workspaces"
    echo "  status  - Show database status for all feature workspaces"
    echo ""
    echo "Environments:"
    echo "  dev     - Development databases only"
    echo "  test    - Test databases only"
    echo "  both    - Both dev and test databases (default)"
    exit 1
    ;;
esac

case "$ENVIRONMENT" in
"dev" | "test" | "both") ;;
*)
    echo "❌ Invalid environment: $ENVIRONMENT"
    echo "Valid options: dev, test, both"
    exit 1
    ;;
esac

echo "🗄️  Database Management for All Worktrees"
echo "=========================================="
echo ""

WORKTREE_DIRS=()

if [ -f "$REPO_ROOT/.env" ]; then
    WORKTREE_DIRS+=("$REPO_ROOT")
fi

if [ -d "$REPO_ROOT/codegen/features" ]; then
    for worktree_dir in "$REPO_ROOT/codegen/features"/*; do
        if [ -d "$worktree_dir" ] && [ -f "$worktree_dir/.env" ]; then
            WORKTREE_DIRS+=("$worktree_dir")
        fi
    done
fi

if [ ${#WORKTREE_DIRS[@]} -eq 0 ]; then
    echo "No feature workspaces with .env files found."
    exit 0
fi

for worktree_dir in "${WORKTREE_DIRS[@]}"; do
    WORKTREE_NAME=$(basename "$worktree_dir")
    DEV_PARTITION=$(grep "^MIX_DEV_PARTITION=" "$worktree_dir/.env" 2>/dev/null | cut -d'=' -f2 || echo "")
    TEST_PARTITION=$(grep "^MIX_TEST_PARTITION=" "$worktree_dir/.env" 2>/dev/null | cut -d'=' -f2 || echo "")

    echo "📁 $WORKTREE_NAME"

    cd "$worktree_dir"

    if [ "$ENVIRONMENT" = "dev" ] || [ "$ENVIRONMENT" = "both" ]; then
        if [ -n "$DEV_PARTITION" ]; then
            DEV_DB_NAME="bemeda_personal_dev$DEV_PARTITION"
            DEV_ENV_VAR="MIX_DEV_PARTITION=$DEV_PARTITION"
        else
            DEV_DB_NAME="bemeda_personal_dev"
            DEV_ENV_VAR=""
        fi

        echo "   🗄️  Dev Database: $DEV_DB_NAME"

        case "$ACTION" in
        "create")
            echo "   🔨 Creating dev database..."
            if [ -n "$DEV_ENV_VAR" ]; then
                env $DEV_ENV_VAR mix ecto.create 2>/dev/null && echo "   ✅ Dev created" || echo "   ⚠️  Dev already exists or failed"
            else
                mix ecto.create 2>/dev/null && echo "   ✅ Dev created" || echo "   ⚠️  Dev already exists or failed"
            fi
            ;;
        "migrate")
            echo "   🔄 Running dev migrations..."
            if [ -n "$DEV_ENV_VAR" ]; then
                env $DEV_ENV_VAR mix ecto.migrate && echo "   ✅ Dev migrated" || echo "   ❌ Dev failed"
            else
                mix ecto.migrate && echo "   ✅ Dev migrated" || echo "   ❌ Dev failed"
            fi
            ;;
        "drop")
            echo "   🗑️  Dropping dev database..."
            if [ -n "$DEV_ENV_VAR" ]; then
                env $DEV_ENV_VAR mix ecto.drop && echo "   ✅ Dev dropped" || echo "   ⚠️  Dev not found or failed"
            else
                mix ecto.drop && echo "   ✅ Dev dropped" || echo "   ⚠️  Dev not found or failed"
            fi
            ;;
        "status")

            if [ -n "$DEV_ENV_VAR" ]; then
                if env $DEV_ENV_VAR mix ecto.migrate --dry-run >/dev/null 2>&1; then
                    echo "   ✅ Dev database exists and is accessible"
                else
                    echo "   ❌ Dev database does not exist or is not accessible"
                fi
            else
                if mix ecto.migrate --dry-run >/dev/null 2>&1; then
                    echo "   ✅ Dev database exists and is accessible"
                else
                    echo "   ❌ Dev database does not exist or is not accessible"
                fi
            fi
            ;;
        esac
    fi

    if [ "$ENVIRONMENT" = "test" ] || [ "$ENVIRONMENT" = "both" ]; then
        if [ -n "$TEST_PARTITION" ]; then
            TEST_DB_NAME="bemeda_personal_test$TEST_PARTITION"
            TEST_ENV_VAR="MIX_ENV=test MIX_TEST_PARTITION=$TEST_PARTITION"
        else
            TEST_DB_NAME="bemeda_personal_test"
            TEST_ENV_VAR="MIX_ENV=test"
        fi

        echo "   🗄️  Test Database: $TEST_DB_NAME"

        case "$ACTION" in
        "create")
            echo "   🔨 Creating test database..."
            env $TEST_ENV_VAR mix ecto.create 2>/dev/null && echo "   ✅ Test created" || echo "   ⚠️  Test already exists or failed"
            ;;
        "migrate")
            echo "   🔄 Running test migrations..."
            env $TEST_ENV_VAR mix ecto.migrate && echo "   ✅ Test migrated" || echo "   ❌ Test failed"
            ;;
        "drop")
            echo "   🗑️  Dropping test database..."
            env $TEST_ENV_VAR mix ecto.drop && echo "   ✅ Test dropped" || echo "   ⚠️  Test not found or failed"
            ;;
        "status")

            if env $TEST_ENV_VAR mix ecto.migrate --dry-run >/dev/null 2>&1; then
                echo "   ✅ Test database exists and is accessible"
            else
                echo "   ❌ Test database does not exist or is not accessible"
            fi
            ;;
        esac
    fi

    echo ""
done

cd "$REPO_ROOT"

case "$ACTION" in
"create")
    echo "🎉 Database creation complete!"
    echo "💡 Run 'make db-migrate $ENVIRONMENT' to run migrations"
    ;;
"migrate")
    echo "🎉 Migration complete!"
    ;;
"drop")
    echo "🎉 Database cleanup complete!"
    ;;
"status")
    echo "💡 Tips:"
    echo "   • Create all databases: make db-create [env]"
    echo "   • Run all migrations: make db-migrate [env]"
    echo "   • Drop all databases: make db-drop [env]"
    echo "   • Check status: make db-status [env]"
    ;;
esac
