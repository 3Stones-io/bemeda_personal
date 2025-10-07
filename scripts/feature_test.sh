#!/bin/bash

# Feature test runner with proper cleanup
# Only cleans up orphaned processes, not the current test

export FEATURE_TESTS=true
export PW_TIMEOUT=2000

# Use PORT_TEST from environment or default to 4205
PORT_TEST=${PORT_TEST:-4205}

# Store our own PID to avoid killing ourselves
SCRIPT_PID=$$

# Function to kill ONLY the test server, not the test runner
cleanup_on_exit() {
    echo -e "\n🧹 Cleaning up test server..."

    # Only kill processes on PORT_TEST (the test server)
    # This won't kill the test runner itself
    if lsof -ti tcp:$PORT_TEST > /dev/null 2>&1; then
        echo "  Stopping test server on port $PORT_TEST..."
        lsof -ti tcp:$PORT_TEST | xargs kill -9 2>/dev/null || true
    fi

    echo "  Cleanup complete ✓"
}

# Function for interrupt cleanup (Ctrl+C) - more aggressive
cleanup_on_interrupt() {
    echo -e "\n⚠️  Interrupted! Cleaning up..."

    # Kill test server
    lsof -ti tcp:$PORT_TEST | xargs kill -9 2>/dev/null || true

    # Kill any child processes of this script
    pkill -P $SCRIPT_PID 2>/dev/null || true

    echo "  Cleanup complete ✓"
    exit 130
}

# Set up different handlers for different situations
trap cleanup_on_interrupt INT  # Ctrl+C
trap cleanup_on_exit EXIT      # Normal exit

# Kill any existing test server before starting (but don't kill running tests)
if lsof -ti tcp:$PORT_TEST > /dev/null 2>&1; then
    echo "🧹 Cleaning up existing test server on port $PORT_TEST..."
    lsof -ti tcp:$PORT_TEST | xargs kill -9 2>/dev/null || true
fi

# Run mix test
echo "🚀 Starting feature tests..."
mix test --color --only feature "$@"
TEST_EXIT_CODE=$?

# Exit with the test's exit code (cleanup happens via EXIT trap)
exit $TEST_EXIT_CODE
