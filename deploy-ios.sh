#!/usr/bin/env bash
set -euo pipefail

# GutMD iOS Deploy Script
# Triggers a Codemagic build that builds, signs, and uploads to TestFlight.
#
# Usage:
#   ./deploy-ios.sh                    # uses CODEMAGIC_TOKEN env var
#   CM_TOKEN=xxx ./deploy-ios.sh       # pass token inline
#   ./deploy-ios.sh --status BUILD_ID  # check an existing build

APP_ID="REPLACE_WITH_CODEMAGIC_APP_ID"
WORKFLOW="ios-release"
BRANCH="main"
API="https://api.codemagic.io"

# Token from env
TOKEN="${CM_TOKEN:-${CODEMAGIC_TOKEN:-}}"

if [ -z "$TOKEN" ]; then
  echo "Error: Set CM_TOKEN or CODEMAGIC_TOKEN environment variable"
  echo "  Find it at: Codemagic > Settings > Integrations > API token"
  exit 1
fi

# Check status of existing build
if [ "${1:-}" = "--status" ]; then
  BUILD_ID="${2:?Usage: $0 --status BUILD_ID}"
  curl -s -H "x-auth-token: $TOKEN" "$API/builds/$BUILD_ID" | python3 -c "
import json,sys
d=json.load(sys.stdin)
b=d.get('build',d)
print(f\"Status: {b.get('status')}\")
print(f\"Message: {b.get('message','')}\")
for s in b.get('buildActions',[]):
    print(f\"  {s.get('name','')}: {s.get('status','')}\")
for a in b.get('artefacts', b.get('artifacts', [])):
    print(f\"Artifact: {a.get('name','')} ({a.get('size',0)//1024//1024}MB)\")
"
  exit 0
fi

# Ensure we're on main and up to date
echo "Checking git status..."
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
  echo "Warning: on branch '$CURRENT_BRANCH', not '$BRANCH'"
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

# Check for uncommitted changes
if ! git diff --quiet HEAD 2>/dev/null; then
  echo "Warning: you have uncommitted changes"
  git status --short
  read -p "Deploy anyway? (y/N) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

# Trigger build
echo "Triggering Codemagic build..."
RESPONSE=$(curl -s -X POST \
  -H "x-auth-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"appId\":\"$APP_ID\",\"workflowId\":\"$WORKFLOW\",\"branch\":\"$BRANCH\"}" \
  "$API/builds")

BUILD_ID=$(echo "$RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('buildId',''))" 2>/dev/null)

if [ -z "$BUILD_ID" ]; then
  echo "Error triggering build:"
  echo "$RESPONSE"
  exit 1
fi

echo "Build triggered: $BUILD_ID"
echo ""
echo "Track progress:"
echo "  $0 --status $BUILD_ID"
echo "  https://codemagic.io/app/$APP_ID/build/$BUILD_ID"
echo ""

# Poll for completion
echo "Waiting for build to complete..."
while true; do
  sleep 30
  STATUS=$(curl -s -H "x-auth-token: $TOKEN" "$API/builds/$BUILD_ID" | \
    python3 -c "import json,sys; print(json.load(sys.stdin).get('build',{}).get('status','unknown'))" 2>/dev/null)

  case "$STATUS" in
    finished)
      echo "BUILD SUCCEEDED"
      $0 --status "$BUILD_ID"
      exit 0
      ;;
    failed|canceled|timed_out)
      echo "BUILD FAILED (status: $STATUS)"
      $0 --status "$BUILD_ID"
      exit 1
      ;;
    *)
      printf "."
      ;;
  esac
done
