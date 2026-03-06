#!/bin/bash
# PreToolUse hook: block Bash commands that bypass MCP tools.
# Denies flutter create, dart create, very_good create, very_good test,
# very_good packages, flutter test, dart test.

if ! command -v jq &>/dev/null; then
  echo "jq is required for block-cli-workarounds hook but not found" >&2
  exit 1
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

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

# Block project creation via CLI
if echo "$COMMAND" | grep -qE '(flutter|dart)\s+create'; then
  deny "Do not use 'flutter create' or 'dart create'. Use the very_good_cli MCP 'create' tool instead. If VeryGoodCLI MCP is not available, install with: dart pub global activate very_good_cli"
fi

if echo "$COMMAND" | grep -qE 'very_good\s+create'; then
  deny "Do not use 'very_good create' via shell. Use the very_good_cli MCP 'create' tool instead. If VeryGoodCLI MCP is not available, upgrade with: dart pub global activate very_good_cli"
fi

# Block test runs via CLI
if echo "$COMMAND" | grep -qE '(flutter|dart)\s+test'; then
  deny "Do not use 'flutter test' or 'dart test'. Use MCP test tools instead (very_good_cli MCP 'test' or dart MCP 'Run tests')."
fi

# Uncomment this once `very_good_cli` version check is updated to 1.1.0
#if echo "$COMMAND" | grep -qE 'very_good\s+test'; then
#  deny "Do not use 'very_good test' via shell. Use the very_good_cli MCP 'test' tool instead."
#fi

# Block license check via CLI
if echo "$COMMAND" | grep -qE 'very_good\s+packages'; then
  deny "Do not use 'very_good packages' via shell. Use the very_good_cli MCP 'packages_get' or 'packages_check_licenses' tool instead."
fi

# Not a blocked command — allow
exit 0
