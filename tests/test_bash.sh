#!/usr/bin/env bash
# Test suite for ai-menu.sh
# Run: bash tests/test_bash.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { ((PASS++)); echo "  ✅ $1"; }
fail() { ((FAIL++)); echo "  ❌ $1: $2"; }

echo "=== ai-menu.sh Test Suite ==="
echo ""

# --- Test: Script syntax check ---
echo "[T1] Syntax check"
if bash -n "$SCRIPT_DIR/ai-menu.sh"; then
    pass "ai-menu.sh has valid syntax"
else
    fail "ai-menu.sh syntax" "bash -n failed"
fi

# --- Test: Script sources without error in non-interactive mode ---
echo "[T2] Source check (non-interactive)"
if bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only"; then
    pass "ai-menu.sh sources cleanly"
else
    fail "ai-menu.sh source" "source failed"
fi

# --- Test: select_menu function exists ---
echo "[T3] select_menu function defined"
if bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; type select_menu" &>/dev/null; then
    pass "select_menu function exists"
else
    fail "select_menu" "function not found"
fi

# --- Test: Main menu options defined ---
echo "[T4] Main menu options"
if bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; [[ \${#MAIN_MENU_OPTIONS[@]} -eq 5 ]]" 2>/dev/null; then
    pass "5 main menu options defined"
else
    fail "main menu options" "expected 5 options"
fi

# --- Test: CLI registry loading ---
echo "[T5] CLI registry loading"
if bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; load_cli_registry; [[ \${#CLI_NAMES[@]} -gt 0 ]]" 2>/dev/null; then
    pass "CLI registry loads successfully"
else
    fail "CLI registry" "failed to load"
fi

# --- Test: CLI registry loading through symlinked command ---
echo "[T5b] Symlinked command path"
TMP_BIN="$(mktemp -d)"
ln -s "$SCRIPT_DIR/ai-menu.sh" "$TMP_BIN/ai-menu"
if bash -c "source '$TMP_BIN/ai-menu' --source-only; load_cli_registry; [[ \$CLI_REGISTRY_FILE = '$SCRIPT_DIR/cli-registry.json' ]]" 2>/dev/null; then
    pass "CLI registry resolves from symlink target"
else
    fail "symlinked command path" "registry resolved relative to symlink directory"
fi
rm -rf "$TMP_BIN"

# --- Test: Core utility functions exist ---
echo "[T6] Core utility functions"
CORE_FUNCS="mask_api_key filter_sensitive load_cli_registry is_cli_installed normalize_key"
ALL_FOUND=true
for fn in $CORE_FUNCS; do
    if ! bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; type $fn" &>/dev/null; then
        ALL_FOUND=false
        fail "$fn" "function not found"
    fi
done
if [ "$ALL_FOUND" = true ]; then
    pass "All core utility functions exist"
fi

# --- Test: Key sequence normalization ---
echo "[T6b] Key sequence normalization"
if bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; [[ \$(normalize_key \$'\\e[A') = up ]] && [[ \$(normalize_key \$'\\eOA') = up ]] && [[ \$(normalize_key \$'\\e[B') = down ]] && [[ \$(normalize_key \$'\\eOB') = down ]] && [[ \$(normalize_key \$'\\eOM') = enter ]] && [[ \$(normalize_key \$'\\n') = enter ]] && [[ \$(normalize_key 3) = 3 ]]" 2>/dev/null; then
    pass "normalize_key supports macOS and xterm arrow sequences"
else
    fail "normalize_key" "expected arrow, enter, and number keys to normalize"
fi

# --- Test: select_menu only returns choice on stdout ---
echo "[T6c] Submenu output channel"
CHOICE=$(printf '\n' | bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; select_menu 'Test Menu' 'One' 'Two'" 2>/dev/null)
if [[ "$CHOICE" == "0" ]]; then
    pass "select_menu returns only the selected index on stdout"
else
    fail "select_menu stdout" "expected '0', got '$CHOICE'"
fi

# --- Test: Registry field extraction does not bleed across CLI entries ---
echo "[T6d] Registry field extraction"
REGISTRY_VALUES=$(bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; load_cli_registry; for i in \"\${!CLI_KEYS[@]}\"; do key=\${CLI_KEYS[\$i]}; auto=\$(get_registry_value \"\$key\" auto_logout); logout=\$(get_registry_value \"\$key\" logout); guide=\$(get_registry_value \"\$key\" logout_guide); if [ \"\$auto\" = true ] && [ -n \"\$logout\" ] && [ \"\$logout\" != null ]; then label=\"\${CLI_NAMES[\$i]}\"; elif [ -n \"\$guide\" ]; then label=\"\${CLI_NAMES[\$i]} [需手动]\"; else continue; fi; printf '%s|' \"\$label\"; done" 2>/dev/null)
EXPECTED_REGISTRY_VALUES="Codex CLI|Gemini CLI [需手动]|Claude Code|OpenCode [需手动]|Claude GLM (智谱)|"
if [[ "$REGISTRY_VALUES" == "$EXPECTED_REGISTRY_VALUES" ]]; then
    pass "Logout labels match registry metadata"
else
    fail "logout labels" "expected '$EXPECTED_REGISTRY_VALUES', got '$REGISTRY_VALUES'"
fi

# --- Test: mask_api_key function ---
echo "[T7] mask_api_key output"
MASKED=$(bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; mask_api_key 'sk-1234567890abcdef'" 2>/dev/null)
if [[ "$MASKED" == "****cdef" ]]; then
    pass "mask_api_key correctly masks key"
else
    fail "mask_api_key" "expected '****cdef', got '$MASKED'"
fi

# --- Test: Error handler function ---
echo "[T8] Error handler"
if bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; type run_cmd" &>/dev/null; then
    pass "run_cmd error handler exists"
else
    fail "run_cmd" "function not found"
fi

# --- Test: Sensitive info filter ---
echo "[T9] Sensitive info filter"
FILTERED=$(bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; filter_sensitive 'error with sk-abcdefghijklmnop'" 2>/dev/null)
if echo "$FILTERED" | grep -q 'sk-' 2>/dev/null; then
    fail "filter_sensitive" "API key not filtered"
else
    pass "filter_sensitive removes sensitive data"
fi

# --- Test: Environment check function ---
echo "[T10] Environment check function"
if bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; type do_health_check" &>/dev/null; then
    pass "do_health_check function exists"
else
    fail "do_health_check" "function not found"
fi

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
