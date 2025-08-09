#!/bin/bash

# Feature test retry script
# Runs feature tests up to 3 times (initial + 2 retries) before marking as failed

MAX_RETRIES=2
ATTEMPT=0

echo "🚀 Running feature tests with retry capability..."

while [ $ATTEMPT -le $MAX_RETRIES ]; do
    if [ $ATTEMPT -eq 0 ]; then
        echo "📋 Initial attempt: Running feature tests"
    else
        echo "🔄 Retry attempt $ATTEMPT of $MAX_RETRIES: Running failed feature tests"
    fi
    
    # Run feature tests
    if [ $ATTEMPT -eq 0 ]; then
        # First run: run all feature tests
        env FEATURE_TESTS=true PW_TIMEOUT=2000 mix test --only feature --color
        exit_code=$?
    else
        # Retry runs: only run failed tests from previous run
        env FEATURE_TESTS=true PW_TIMEOUT=2000 mix test --failed --only feature --color
        exit_code=$?
    fi
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ Feature tests passed!"
        exit 0
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    
    if [ $ATTEMPT -le $MAX_RETRIES ]; then
        echo "⚠️  Feature tests failed, preparing retry $ATTEMPT of $MAX_RETRIES..."
        sleep 1
    fi
done

echo "❌ Feature tests failed after $((MAX_RETRIES + 1)) attempts"
exit 1