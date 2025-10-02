#!/bin/bash

# BDD test runner with proper cleanup
# Uses PORT_TEST environment variable (same as feature tests)

export FEATURE_TESTS=true  # Enables test server
export PW_TIMEOUT=2000

# Store our own PID to avoid killing ourselves
SCRIPT_PID=$$

# Get test port from environment (no hardcoded fallback - workspace must set it)
TEST_PORT=${PORT_TEST:?PORT_TEST environment variable must be set}

# Function to kill ONLY the test server, not the test runner
cleanup_on_exit() {
    echo -e "\n🧹 Cleaning up test server..."

    # Only kill processes on test port (the test server)
    if lsof -ti tcp:${TEST_PORT} > /dev/null 2>&1; then
        echo "  Stopping test server on port ${TEST_PORT}..."
        lsof -ti tcp:${TEST_PORT} | xargs kill -9 2>/dev/null || true
    fi

    echo "  Cleanup complete ✓"
}

# Function for interrupt cleanup (Ctrl+C) - more aggressive
cleanup_on_interrupt() {
    echo -e "\n⚠️  Interrupted! Cleaning up..."

    # Kill test server
    lsof -ti tcp:${TEST_PORT} | xargs kill -9 2>/dev/null || true

    # Kill any child processes of this script
    pkill -P $SCRIPT_PID 2>/dev/null || true

    echo "  Cleanup complete ✓"
    exit 130
}

# Set up different handlers for different situations
trap cleanup_on_interrupt INT  # Ctrl+C
trap cleanup_on_exit EXIT      # Normal exit

# Kill any existing test server before starting
if lsof -ti tcp:${TEST_PORT} > /dev/null 2>&1; then
    echo "🧹 Cleaning up existing test server on port ${TEST_PORT}..."
    lsof -ti tcp:${TEST_PORT} | xargs kill -9 2>/dev/null || true
fi

# Run mix test with BDD inclusion
echo "🚀 Starting BDD tests..."
mix test --color --include bdd "$@"
TEST_EXIT_CODE=$?

# Exit with the test's exit code (cleanup happens via EXIT trap)
exit $TEST_EXIT_CODE