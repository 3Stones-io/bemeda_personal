#!/bin/bash

echo "📊 Adding all S/U/T issues to Bemeda Platform project"
echo "===================================================="

PROJECT_ID="PVT_kwDOCSexDM4ArxmP"

# Add all technical components (T1-T13)
for issue_num in 373 401 402 403 404 405 406 407 408 409 410; do
    echo "Adding issue #$issue_num to project..."
    gh project item-add 12 --owner 3Stones-io --url "https://github.com/3Stones-io/bemeda_personal/issues/$issue_num" || echo "Issue #$issue_num may already be in project"
done

# Add all scenario steps (S1-S19)
for issue_num in 371 377 378 376 383 384 385 386 387 388 389 390 391 392 393 394 398 399 400; do
    echo "Adding issue #$issue_num to project..."
    gh project item-add 12 --owner 3Stones-io --url "https://github.com/3Stones-io/bemeda_personal/issues/$issue_num" || echo "Issue #$issue_num may already be in project"
done

echo ""
echo "✅ All issues added to project!"
echo "📊 View at: https://github.com/orgs/3Stones-io/projects/12"