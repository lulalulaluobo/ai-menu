# Integration test for both bash and PowerShell versions
# Run: powershell -ExecutionPolicy Bypass -File tests\integration_test.ps1

$Pass = 0
$Fail = 0

function Test-Pass($msg) { $script:Pass++; Write-Host "  ✓ $msg" -ForegroundColor Green }
function Test-Fail($msg) { $script:Fail++; Write-Host "  ✗ $msg" -ForegroundColor Red }

Write-Host "`n=== ai-menu Integration Tests ===`n" -ForegroundColor Cyan

# Test 1: JSON config files exist and are valid
Write-Host "[Test 1] Configuration files"
if (Test-Path "cli-registry.json") {
    try {
        $registry = Get-Content "cli-registry.json" -Raw | ConvertFrom-Json
        if ($registry.PSObject.Properties.Name.Count -eq 5) {
            Test-Pass "cli-registry.json: 5 CLIs defined"
        } else {
            Test-Fail "cli-registry.json: expected 5 CLIs, got $($registry.PSObject.Properties.Name.Count)"
        }
    } catch {
        Test-Fail "cli-registry.json: invalid JSON"
    }
} else {
    Test-Fail "cli-registry.json: file not found"
}

if (Test-Path "profile-templates.json") {
    try {
        $templates = Get-Content "profile-templates.json" -Raw | ConvertFrom-Json
        if ($templates.PSObject.Properties.Name.Count -eq 6) {
            Test-Pass "profile-templates.json: 6 templates defined"
        } else {
            Test-Fail "profile-templates.json: expected 6 templates"
        }
    } catch {
        Test-Fail "profile-templates.json: invalid JSON"
    }
} else {
    Test-Fail "profile-templates.json: file not found"
}

# Test 2: PowerShell version
Write-Host "`n[Test 2] PowerShell version (ai-menu.ps1)"
if (Test-Path "ai-menu.ps1") {
    try {
        $env:AI_MENU_TEST_MODE = "1"
        . .\ai-menu.ps1
        
        if (Get-Command Select-Menu -ErrorAction SilentlyContinue) {
            Test-Pass "Select-Menu function exists"
        } else {
            Test-Fail "Select-Menu function not found"
        }
        
        if (Get-Command Hide-ApiKey -ErrorAction SilentlyContinue) {
            $masked = Hide-ApiKey "sk-test1234"
            if ($masked -eq "****1234") {
                Test-Pass "Hide-ApiKey works correctly"
            } else {
                Test-Fail "Hide-ApiKey output incorrect: $masked"
            }
        } else {
            Test-Fail "Hide-ApiKey function not found"
        }
        
        if (Get-Command Load-CliRegistry -ErrorAction SilentlyContinue) {
            $reg = Load-CliRegistry
            if ($reg.PSObject.Properties.Name.Count -ge 5) {
                Test-Pass "Load-CliRegistry loads 5+ CLIs"
            } else {
                Test-Fail "Load-CliRegistry loaded less than 5 CLIs"
            }
        } else {
            Test-Fail "Load-CliRegistry function not found"
        }
        
        $env:AI_MENU_TEST_MODE = $null
    } catch {
        Test-Fail "PowerShell version failed to load: $($_.Exception.Message)"
    }
} else {
    Test-Fail "ai-menu.ps1 not found"
}

# Test 3: Bash version
Write-Host "`n[Test 3] Bash version (ai-menu.sh)"
$bashPath = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path $bashPath) {
    if (Test-Path "ai-menu.sh") {
        # Syntax check
        $result = & $bashPath -n "ai-menu.sh" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Test-Pass "Bash syntax check passed"
        } else {
            Test-Fail "Bash syntax check failed"
        }
        
        # Function existence
        $result = & $bashPath -c "source ./ai-menu.sh --source-only && type select_menu" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Test-Pass "select_menu function exists"
        } else {
            Test-Fail "select_menu function not found"
        }
        
        # mask_api_key test
        $result = & $bashPath -c "source ./ai-menu.sh --source-only && mask_api_key 'sk-test1234'" 2>&1
        if ($result -match '\*\*\*\*1234') {
            Test-Pass "mask_api_key works correctly"
        } else {
            Test-Fail "mask_api_key output incorrect: $result"
        }
        
        # CLI registry loading
        & $bashPath "test_quick.sh" | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Test-Pass "load_cli_registry loads 5 CLIs"
        } else {
            Test-Fail "load_cli_registry failed"
        }
    } else {
        Test-Fail "ai-menu.sh not found"
    }
} else {
    Write-Host "  ⊘ Bash not available, skipping bash tests" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=== Results: $Pass passed, $Fail failed ===`n" -ForegroundColor Cyan
if ($Fail -gt 0) { exit 1 }
