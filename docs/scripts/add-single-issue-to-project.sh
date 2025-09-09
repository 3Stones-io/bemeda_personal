#!/bin/bash

# Safe script to add issues one by one to project

if [ -z "$1" ]; then
    echo "Usage: ./add-single-issue-to-project.sh <issue_number>"
    echo "Example: ./add-single-issue-to-project.sh 410"
    exit 1
fi

ISSUE_NUM=$1
PROJECT_NUM=12
OWNER="3Stones-io"
REPO="bemeda_personal"

echo "Adding issue #$ISSUE_NUM to Bemeda Platform project..."
gh project item-add $PROJECT_NUM --owner $OWNER --url "https://github.com/$OWNER/$REPO/issues/$ISSUE_NUM"

if [ $? -eq 0 ]; then
    echo "✅ Successfully added issue #$ISSUE_NUM to project"
else
    echo "❌ Failed to add issue #$ISSUE_NUM (may already be in project)"
fi