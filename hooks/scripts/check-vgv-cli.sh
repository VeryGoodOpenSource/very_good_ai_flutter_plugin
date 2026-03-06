#!/bin/bash
# PreToolUse hook: verify very_good_cli >= 1.0.0 is installed before
# allowing VeryGoodCLI MCP tool calls.

if ! command -v jq &>/dev/null; then
  echo "jq is required for check-vgv-cli hook but not found" >&2
  exit 1
fi

MIN_VERSION="1.1.0"
MIN_MAJOR=1
MIN_MINOR=1
MIN_PATCH=0

deny() {
  jq -n \
    --arg reason "$1" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
  exit 0
}

# CLI not installed
if ! command -v very_good &>/dev/null; then
  deny "VeryGoodCLI is not installed. This tool requires VeryGoodCLI >= ${MIN_VERSION}. Install with: dart pub global activate very_good_cli"
fi

# Parse version (first semver from first line)
RAW=$(very_good --version 2>/dev/null)
VERSION=$(echo "$RAW" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [ -z "$VERSION" ]; then
  deny "Could not determine VeryGoodCLI version. This tool requires VeryGoodCLI >= ${MIN_VERSION}. Check with: very_good --version"
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# Version too old
if [ "$MAJOR" -lt "$MIN_MAJOR" ] 2>/dev/null ||
   { [ "$MAJOR" -eq "$MIN_MAJOR" ] && [ "$MINOR" -lt "$MIN_MINOR" ]; } 2>/dev/null ||
   { [ "$MAJOR" -eq "$MIN_MAJOR" ] && [ "$MINOR" -eq "$MIN_MINOR" ] && [ "$PATCH" -lt "$MIN_PATCH" ]; } 2>/dev/null; then
  deny "VeryGoodCLI ${VERSION} is too old. This tool requires VeryGoodCLI >= ${MIN_VERSION}. Update with: dart pub global activate very_good_cli"
fi

# Version OK
exit 0
