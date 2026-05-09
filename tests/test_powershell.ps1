# Test suite for ai-menu.ps1
# Run: powershell -ExecutionPolicy Bypass -File tests\test_powershell.ps1

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ScriptPath = Join-Path $ScriptDir "ai-menu.ps1"
$Pass = 0
$Fail = 0

function Test-Pass($msg) { $script:Pass++; Write-Host "  ✅ $msg" }
function Test-Fail($msg, $detail) { $script:Fail++; Write-Host "  ❌ ${msg}: $detail" }

Write-Host "=== ai-menu.ps1 Test Suite ==="
Write-Host ""

# --- T1: Script parses without error ---
Write-Host "[T1] Syntax check"
try {
    $null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)
    $tokens = $null
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)
    if ($errors.Count -eq 0) {
        Test-Pass "ai-menu.ps1 has valid syntax"
    } else {
        Test-Fail "ai-menu.ps1 syntax" "$($errors.Count) parse errors"
    }
} catch {
    Test-Fail "ai-menu.ps1 syntax" $_.Exception.Message
}

# --- T2: Source script in test mode ---
Write-Host "[T2] Source check (test mode)"
try {
    $env:AI_MENU_TEST_MODE = "1"
    . $ScriptPath
    Test-Pass "ai-menu.ps1 sources cleanly in test mode"
} catch {
    Test-Fail "ai-menu.ps1 source" $_.Exception.Message
} finally {
    $env:AI_MENU_TEST_MODE = $null
}

# --- T3: Select-Menu function exists ---
Write-Host "[T3] Select-Menu function defined"
if (Get-Command Select-Menu -ErrorAction SilentlyContinue) {
    Test-Pass "Select-Menu function exists"
} else {
    Test-Fail "Select-Menu" "function not found"
}

# --- T4: Main menu options ---
Write-Host "[T4] Main menu options"
if ($null -ne (Get-Variable -Name MAIN_MENU_OPTIONS -ErrorAction SilentlyContinue)) {
    if ($MAIN_MENU_OPTIONS.Count -eq 5) {
        Test-Pass "5 main menu options defined"
    } else {
        Test-Fail "main menu options" "expected 5, got $($MAIN_MENU_OPTIONS.Count)"
    }
} else {
    Test-Fail "main menu options" "variable not defined"
}

# --- T5: CLI registry loading ---
Write-Host "[T5] CLI registry loading"
if (Get-Command Load-CliRegistry -ErrorAction SilentlyContinue) {
    try {
        $registry = Load-CliRegistry
        if ($registry.PSObject.Properties.Name.Count -ge 5) {
            Test-Pass "CLI registry loads with 5+ entries"
        } else {
            Test-Fail "CLI registry" "less than 5 entries"
        }
    } catch {
        Test-Fail "CLI registry" $_.Exception.Message
    }
} else {
    Test-Fail "CLI registry" "Load-CliRegistry not found"
}

# --- T6: Profile utility functions ---
Write-Host "[T6] Core utility functions"
$coreFuncs = @("Hide-ApiKey", "Hide-SensitiveInfo", "Load-CliRegistry", "Get-RegistryItem", "Get-CliInstalled")
$allFound = $true
foreach ($fn in $coreFuncs) {
    if (-not (Get-Command $fn -ErrorAction SilentlyContinue)) {
        $allFound = $false
        Test-Fail $fn "function not found"
    }
}
if ($allFound) {
    Test-Pass "All core utility functions exist"
}

# --- T6b: Registry-backed login/logout options ---
Write-Host "[T6b] Login/logout registry options"
if (Get-Command Get-RegistryItem -ErrorAction SilentlyContinue) {
    try {
        $registry = Load-CliRegistry
        $loginOptions = @()
        $logoutOptions = @()
        
        foreach ($key in $registry.PSObject.Properties.Name) {
            $cli = Get-RegistryItem -Registry $registry -Key $key
            if ($cli.login) {
                $loginOptions += "$($cli.name)"
            }
            if ($cli.auto_logout -and $cli.logout) {
                $logoutOptions += "$($cli.name)"
            } elseif ($cli.logout_guide) {
                $logoutOptions += "$($cli.name) [需手动]"
            }
        }
        
        $expectedLogin = @("Codex CLI", "Gemini CLI", "Claude Code", "Claude GLM (智谱)")
        $expectedLogout = @("Codex CLI", "Gemini CLI [需手动]", "Claude Code", "OpenCode [需手动]", "Claude GLM (智谱)")
        
        if (($loginOptions -join "|") -eq ($expectedLogin -join "|") -and
            ($logoutOptions -join "|") -eq ($expectedLogout -join "|")) {
            Test-Pass "Login/logout options match registry metadata"
        } else {
            Test-Fail "login/logout options" "login=[$($loginOptions -join ', ')] logout=[$($logoutOptions -join ', ')]"
        }
    } catch {
        Test-Fail "login/logout options" $_.Exception.Message
    }
} else {
    Test-Fail "login/logout options" "Get-RegistryItem not found"
}

# --- T6c: No raw ANSI escape sequences in PowerShell UI ---
Write-Host "[T6c] PowerShell UI selection rendering"
$scriptContent = Get-Content $ScriptPath -Raw -Encoding UTF8
if ($scriptContent -notmatch '`e\[' -and
    $scriptContent -notmatch 'COLOR_' -and
    $scriptContent -notmatch 'BackgroundColor' -and
    $scriptContent -match '\*\* \$\(\$i \+ 1\)\.') {
    Test-Pass "PowerShell UI uses plain text selection markers"
} else {
    Test-Fail "PowerShell UI selection" "raw ANSI/background colors are present or plain text marker is missing"
}

# --- T7: Hide-ApiKey function ---
Write-Host "[T7] Hide-ApiKey output"
if (Get-Command Hide-ApiKey -ErrorAction SilentlyContinue) {
    $masked = Hide-ApiKey "sk-1234567890abcdef"
    if ($masked -eq "****cdef") {
        Test-Pass "Hide-ApiKey correctly masks key"
    } else {
        Test-Fail "Hide-ApiKey" "expected '****cdef', got '$masked'"
    }
} else {
    Test-Fail "Hide-ApiKey" "function not found"
}

# --- T8: Error handler function ---
Write-Host "[T8] Error handler"
if (Get-Command Invoke-SafeCommand -ErrorAction SilentlyContinue) {
    Test-Pass "Invoke-SafeCommand error handler exists"
} else {
    Test-Fail "Invoke-SafeCommand" "function not found"
}

# --- T9: Sensitive info filter ---
Write-Host "[T9] Sensitive info filter"
if (Get-Command Hide-SensitiveInfo -ErrorAction SilentlyContinue) {
    $filtered = Hide-SensitiveInfo "error with sk-abcdefghijklmnop"
    if ($filtered -notmatch "sk-abcdefghijklmnop") {
        Test-Pass "Hide-SensitiveInfo removes sensitive data"
    } else {
        Test-Fail "Hide-SensitiveInfo" "API key not filtered"
    }
} else {
    Test-Fail "Hide-SensitiveInfo" "function not found"
}

# --- T10: Environment check function ---
Write-Host "[T10] Environment check function"
if (Get-Command Invoke-HealthCheck -ErrorAction SilentlyContinue) {
    Test-Pass "Invoke-HealthCheck function exists"
} else {
    Test-Fail "Invoke-HealthCheck" "function not found"
}

# --- Summary ---
Write-Host ""
Write-Host "=== Results: $Pass passed, $Fail failed ==="
if ($Fail -gt 0) { exit 1 }
