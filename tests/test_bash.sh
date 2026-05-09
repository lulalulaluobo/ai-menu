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
if bash -n "$SCRIPT_DIR/ai-menu.sh" 2>/dev/null; then
    pass "ai-menu.sh has valid syntax"
else
    fail "ai-menu.sh syntax" "bash -n failed"
fi

# --- Test: Script sources without error in non-interactive mode ---
echo "[T2] Source check (non-interactive)"
if bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only" 2>/dev/null; then
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
if bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; [[ \${#MAIN_MENU_OPTIONS[@]} -eq 7 ]]" 2>/dev/null; then
    pass "7 main menu options defined"
else
    fail "main menu options" "expected 7 options"
fi

# --- Test: CLI registry loading ---
echo "[T5] CLI registry loading"
if bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; load_cli_registry; [[ \${#CLI_NAMES[@]} -gt 0 ]]" 2>/dev/null; then
    pass "CLI registry loads successfully"
else
    fail "CLI registry" "failed to load"
fi

# --- Test: Profile functions exist ---
echo "[T6] Profile utility functions"
PROFILE_FUNCS="read_profile write_profile get_active_profile set_active_profile mask_api_key"
ALL_FOUND=true
for fn in $PROFILE_FUNCS; do
    if ! bash -c "source '$SCRIPT_DIR/ai-menu.sh' --source-only; type $fn" &>/dev/null; then
        ALL_FOUND=false
        fail "$fn" "function not found"
    fi
done
if [ "$ALL_FOUND" = true ]; then
    pass "All profile utility functions exist"
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
