#!/bin/bash
# PreToolUse hook: verify very_good_cli is installed before
# allowing Very Good CLI MCP tool calls.

if ! command -v jq &>/dev/null; then
  echo "jq is required for check-vgv-cli hook but not found" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vgv-cli-common.sh"

cli_status=$(check_vgv_cli)
case "$cli_status" in
  not_installed)
    deny "Very Good CLI is not installed. This tool requires Very Good CLI >= ${MIN_VERSION}. Install with: dart pub global activate very_good_cli"
    ;;
  outdated:*)
    version="${cli_status#outdated:}"
    deny "Very Good CLI ${version} is too old. This tool requires Very Good CLI >= ${MIN_VERSION}. Update with: dart pub global activate very_good_cli"
    ;;
esac

# Version OK
exit 0
