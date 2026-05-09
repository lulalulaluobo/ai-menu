#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
source ./ai-menu.sh --source-only
load_cli_registry
echo "CLI count: ${#CLI_NAMES[@]}"
for k in "${!CLI_NAMES[@]}"; do
    echo "  $k: ${CLI_NAMES[$k]}"
done
