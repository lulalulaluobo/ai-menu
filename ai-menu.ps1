#!/usr/bin/env pwsh
# ai-menu.ps1 - 终端 AI 菜单 (Windows PowerShell 版)
# Version: 1.0.0

#Requires -Version 5.1

# UTF-8 设置
chcp 65001 | Out-Null
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 全局配置
$script:VERSION = "1.0.0"
$script:CONFIG_HOME = Join-Path $env:USERPROFILE ".ai-menu"
$script:SCRIPT_DIR = $PSScriptRoot
$script:CLI_REGISTRY_FILE = Join-Path $script:SCRIPT_DIR "cli-registry.json"

# 颜色定义
$script:COLOR_RESET = "`e[0m"
$script:COLOR_HIGHLIGHT = "`e[7m"
$script:COLOR_GREEN = "`e[32m"
$script:COLOR_RED = "`e[31m"
$script:COLOR_YELLOW = "`e[33m"
$script:COLOR_BLUE = "`e[34m"

# 主菜单选项
$script:MAIN_MENU_OPTIONS = @(
    "环境体检",
    "安装 / 更新 CLI",
    "登录 / 登出",
    "启动 AI",
    "退出"
)

# ============================================================================
# 工具函数
# ============================================================================

function Hide-ApiKey {
    param([string]$Key)
    if ($Key.Length -le 4) { return '****' }
    return '****' + $Key.Substring($Key.Length - 4)
}

function Hide-SensitiveInfo {
    param([string]$Text)
    # 过滤 sk- 和 key- 开头的敏感字符串
    $result = $Text -replace '(sk-|key-)[a-zA-Z0-9]{16,}', '****'
    return $result
}

function Write-Success {
    param([string]$Message)
    Write-Host ($script:COLOR_GREEN + '[OK] ' + $Message + $script:COLOR_RESET)
}

function Write-Error-Message {
    param([string]$Message)
    Write-Host ($script:COLOR_RED + '[ERROR] ' + $Message + $script:COLOR_RESET)
}

function Write-Warning-Message {
    param([string]$Message)
    Write-Host ($script:COLOR_YELLOW + '[WARN] ' + $Message + $script:COLOR_RESET)
}

function Write-Info {
    param([string]$Message)
    Write-Host ($script:COLOR_BLUE + '[INFO] ' + $Message + $script:COLOR_RESET)
}

# ============================================================================
# 菜单引擎
# ============================================================================

function Select-Menu {
    param(
        [string]$Title,
        [string[]]$Options
    )
    
    $selected = 0
    $optionCount = $Options.Count
    
    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "=== $Title ===" -ForegroundColor Cyan
        Write-Host ""
        
        for ($i = 0; $i -lt $optionCount; $i++) {
            if ($i -eq $selected) {
                Write-Host "$script:COLOR_HIGHLIGHT $($i + 1). $($Options[$i]) $script:COLOR_RESET"
            } else {
                Write-Host " $($i + 1). $($Options[$i])"
            }
        }
        
        Write-Host ""
        Write-Host "使用 ↑↓ 选择，回车确认" -ForegroundColor DarkGray
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                $selected = ($selected - 1 + $optionCount) % $optionCount
            }
            40 { # Down arrow
                $selected = ($selected + 1) % $optionCount
            }
            13 { # Enter
                return $selected
            }
        }
    }
}

# ============================================================================
# CLI Registry 管理
# ============================================================================

function Load-CliRegistry {
    if (-not (Test-Path $script:CLI_REGISTRY_FILE)) {
        Write-Error-Message "CLI registry 文件不存在: $script:CLI_REGISTRY_FILE"
        return $null
    }
    
    try {
        $content = Get-Content $script:CLI_REGISTRY_FILE -Raw -Encoding UTF8
        return $content | ConvertFrom-Json
    } catch {
        Write-Error-Message "无法加载 CLI registry: $($_.Exception.Message)"
        return $null
    }
}

function Get-CliInstalled {
    param([string]$BinName)
    
    $cmd = Get-Command $BinName -ErrorAction SilentlyContinue
    return $null -ne $cmd
}

function Get-CliVersion {
    param([string]$BinName)
    
    if (-not (Get-CliInstalled $BinName)) {
        return $null
    }
    
    try {
        $output = & $BinName --version 2>&1
        return $output
    } catch {
        return "未知版本"
    }
}

# ============================================================================
# Profile 管理
# ============================================================================

function Read-Profile {
    param([string]$ProfileName)
    
    $profilePath = Join-Path $script:PROFILES_DIR "$ProfileName.env"
    if (-not (Test-Path $profilePath)) {
        return $null
    }
    
    $profile = @{}
    Get-Content $profilePath -Encoding UTF8 | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $profile[$matches[1]] = $matches[2]
        }
    }
    
    return $profile
}

function Write-Profile {
    param(
        [string]$ProfileName,
        [hashtable]$Data
    )
    
    if (-not (Test-Path $script:PROFILES_DIR)) {
        New-Item -ItemType Directory -Path $script:PROFILES_DIR -Force | Out-Null
    }
    
    $profilePath = Join-Path $script:PROFILES_DIR "$ProfileName.env"
    $lines = @("# Profile: $ProfileName")
    
    foreach ($key in $Data.Keys) {
        $lines += "$key=$($Data[$key])"
    }
    
    $lines | Out-File -FilePath $profilePath -Encoding UTF8 -Force
    
    # 设置文件权限为当前用户独占
    $acl = Get-Acl $profilePath
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
        "FullControl",
        "Allow"
    )
    $acl.SetAccessRule($rule)
    Set-Acl $profilePath $acl
}

function Get-ActiveProfile {
    if (-not (Test-Path $script:ACTIVE_PROFILE_FILE)) {
        return $null
    }
    
    return (Get-Content $script:ACTIVE_PROFILE_FILE -Raw -Encoding UTF8).Trim()
}

function Set-ActiveProfile {
    param([string]$ProfileName)
    
    if (-not (Test-Path $script:CONFIG_HOME)) {
        New-Item -ItemType Directory -Path $script:CONFIG_HOME -Force | Out-Null
    }
    
    $ProfileName | Out-File -FilePath $script:ACTIVE_PROFILE_FILE -Encoding UTF8 -NoNewline -Force
}

function Get-AllProfiles {
    if (-not (Test-Path $script:PROFILES_DIR)) {
        return @()
    }
    
    $profiles = Get-ChildItem -Path $script:PROFILES_DIR -Filter "*.env" | ForEach-Object {
        $_.BaseName
    }
    
    return $profiles
}

# ============================================================================
# 错误处理
# ============================================================================

function Invoke-SafeCommand {
    param(
        [string]$Command,
        [string]$ErrorMessage = "命令执行失败"
    )
    
    try {
        $output = Invoke-Expression $Command 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -ne 0) {
            Write-Error-Message "$ErrorMessage"
            Write-Host "原始报错："
            Write-Host (Hide-SensitiveInfo ($output | Out-String))
            return $false
        }
        
        return $true
    } catch {
        Write-Error-Message "$ErrorMessage"
        Write-Host "原始报错："
        Write-Host (Hide-SensitiveInfo $_.Exception.Message)
        return $false
    }
}

# ============================================================================
# 功能模块
# ============================================================================

function Invoke-HealthCheck {
    Clear-Host
    Write-Host ""
    Write-Host "=== 环境体检 ===" -ForegroundColor Cyan
    Write-Host ""
    
    # OS 信息
    Write-Host "【操作系统】"
    $os = [System.Environment]::OSVersion
    Write-Host "  $($os.VersionString)"
    Write-Host ""
    
    # Node.js
    Write-Host "【Node.js】"
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeVer = node --version 2>&1
        Write-Success "已安装: $nodeVer"
    } else {
        Write-Warning-Message "未安装，请访问 https://nodejs.org 下载"
    }
    Write-Host ""
    
    # npm
    Write-Host "【npm】"
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $npmVer = npm --version 2>&1
        Write-Success "已安装: $npmVer"
    } else {
        Write-Warning-Message "未安装（通常随 Node.js 一起安装）"
    }
    Write-Host ""
    
    # pnpm (可选)
    Write-Host "【pnpm (可选)】"
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        $pnpmVer = pnpm --version 2>&1
        Write-Success "已安装: $pnpmVer"
    } else {
        Write-Info "未安装（可选）"
    }
    Write-Host ""
    
    # git
    Write-Host "【git】"
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitVer = git --version 2>&1
        Write-Success "已安装: $gitVer"
    } else {
        Write-Warning-Message "未安装，请访问 https://git-scm.com 下载"
    }
    Write-Host ""
    
    # CLI 检测
    Write-Host "【Target CLI 状态】"
    $registry = Load-CliRegistry
    if ($registry) {
        foreach ($cliKey in $registry.PSObject.Properties.Name) {
            $cli = $registry.$cliKey
            $binName = $cli.bin
            
            if (Get-CliInstalled $binName) {
                $version = Get-CliVersion $binName
                Write-Success "$($cli.name): 已安装 ($version)"
            } else {
                Write-Warning-Message "$($cli.name): 未安装"
            }
        }
    }
    Write-Host ""
    
    # 网络连通性
    Write-Host "【网络连通性】"
    $endpoints = @(
        @{Name="Anthropic API"; Url="https://api.anthropic.com"},
        @{Name="Google Gemini API"; Url="https://generativelanguage.googleapis.com"},
        @{Name="OpenAI API"; Url="https://api.openai.com"}
    )
    
    foreach ($ep in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $ep.Url -Method Head -TimeoutSec 3 -ErrorAction Stop
            Write-Success "$($ep.Name): 可访问"
        } catch {
            Write-Warning-Message "$($ep.Name): 无法访问"
        }
    }
    Write-Host ""
    
    # PATH 冲突检测
    Write-Host "【PATH 冲突检测】"
    $registry = Load-CliRegistry
    if ($registry) {
        foreach ($cliKey in $registry.PSObject.Properties.Name) {
            $binName = $registry.$cliKey.bin
            $paths = @(where.exe $binName 2>$null)
            
            if ($paths.Count -gt 1) {
                Write-Warning-Message "$binName 存在多个版本："
                $paths | ForEach-Object { Write-Host "    $_" }
            }
        }
    }
    
    Write-Host ""
    Write-Host "按任意键返回主菜单..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-InstallCli {
    while ($true) {
        $options = @(
            "安装 CLI",
            "更新 CLI",
            "返回主菜单"
        )
        
        $choice = Select-Menu -Title "安装 / 更新 CLI" -Options $options
        
        switch ($choice) {
            0 { Invoke-InstallCliAction }
            1 { Invoke-UpdateCliAction }
            2 { return }
        }
    }
}

function Invoke-InstallCliAction {
    Clear-Host
    Write-Host ""
    Write-Host "=== 安装 CLI ===" -ForegroundColor Cyan
    Write-Host ""
    
    $registry = Load-CliRegistry
    if (-not $registry) {
        Write-Error-Message "无法加载 CLI registry"
        Start-Sleep -Seconds 2
        return
    }
    
    # 构建选项列表
    $options = @()
    $cliKeys = @()
    
    foreach ($key in $registry.PSObject.Properties.Name) {
        $cli = $registry.$key
        $binName = $cli.bin
        
        if (Get-CliInstalled $binName) {
            $version = Get-CliVersion $binName
            $options += "$($cli.name) [已安装: $version]"
        } else {
            $options += "$($cli.name) [未安装]"
        }
        $cliKeys += $key
    }
    $options += "返回"
    
    $choice = Select-Menu -Title "选择要安装的 CLI" -Options $options
    
    if ($choice -eq $options.Count - 1) {
        return
    }
    
    $selectedKey = $cliKeys[$choice]
    $cli = $registry.$selectedKey
    
    # 检查是否有安装命令
    if (-not $cli.install) {
        Clear-Host
        Write-Host ""
        Write-Warning-Message "$($cli.name) 需要手动安装"
        Write-Host ""
        if ($cli.install_guide) {
            Write-Host $cli.install_guide -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "按任意键返回..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    Clear-Host
    Write-Host ""
    Write-Success "正在安装 $($cli.name)..."
    Write-Host ""
    Write-Host "命令: $($cli.install)" -ForegroundColor DarkGray
    Write-Host ""
    
    # 检查管理员权限
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Warning-Message "需要管理员权限安装全局 npm 包"
        Write-Host "请以管理员身份运行 PowerShell，或使用 npm 的用户级安装" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "按任意键返回..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    try {
        $installCmd = $cli.install
        Invoke-Expression $installCmd
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            $version = Get-CliVersion $cli.bin
            Write-Success "$($cli.name) 安装成功！版本: $version"
        } else {
            Write-Host ""
            Write-Error-Message "安装失败，请检查网络连接或 npm 配置"
        }
    } catch {
        Write-Host ""
        Write-Error-Message "安装失败: $($_.Exception.Message)"
    }
    
    Write-Host ""
    Write-Host "按任意键返回..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-UpdateCliAction {
    Clear-Host
    Write-Host ""
    Write-Host "=== 更新 CLI ===" -ForegroundColor Cyan
    Write-Host ""
    
    $registry = Load-CliRegistry
    if (-not $registry) {
        Write-Error-Message "无法加载 CLI registry"
        Start-Sleep -Seconds 2
        return
    }
    
    # 构建选项列表（只显示已安装的）
    $options = @()
    $cliKeys = @()
    
    foreach ($key in $registry.PSObject.Properties.Name) {
        $cli = $registry.$key
        $binName = $cli.bin
        
        if (Get-CliInstalled $binName) {
            $version = Get-CliVersion $binName
            $options += "$($cli.name) [$version]"
            $cliKeys += $key
        }
    }
    
    if ($options.Count -eq 0) {
        Write-Warning-Message "没有已安装的 CLI"
        Start-Sleep -Seconds 2
        return
    }
    
    $options += "返回"
    
    $choice = Select-Menu -Title "选择要更新的 CLI" -Options $options
    
    if ($choice -eq $options.Count - 1) {
        return
    }
    
    $selectedKey = $cliKeys[$choice]
    $cli = $registry.$selectedKey
    
    if (-not $cli.update) {
        Write-Warning-Message "$($cli.name) 没有自动更新命令"
        Start-Sleep -Seconds 2
        return
    }
    
    Clear-Host
    Write-Host ""
    Write-Success "正在更新 $($cli.name)..."
    Write-Host ""
    Write-Host "命令: $($cli.update)" -ForegroundColor DarkGray
    Write-Host ""
    
    # 检查管理员权限
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Warning-Message "需要管理员权限更新全局 npm 包"
        Write-Host ""
        Write-Host "按任意键返回..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    try {
        $updateCmd = $cli.update
        Invoke-Expression $updateCmd
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            $version = Get-CliVersion $cli.bin
            Write-Success "$($cli.name) 更新成功！版本: $version"
        } else {
            Write-Host ""
            Write-Error-Message "更新失败"
        }
    } catch {
        Write-Host ""
        Write-Error-Message "更新失败: $($_.Exception.Message)"
    }
    
    Write-Host ""
    Write-Host "按任意键返回..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-LoginLogout {
    while ($true) {
        $options = @(
            "登录",
            "登出",
            "返回主菜单"
        )
        
        $choice = Select-Menu -Title "登录 / 登出" -Options $options
        
        switch ($choice) {
            0 { Invoke-Login }
            1 { Invoke-Logout }
            2 { return }
        }
    }
}

function Invoke-Login {
    Clear-Host
    Write-Host ""
    Write-Host "=== 登录 ===" -ForegroundColor Cyan
    Write-Host ""
    
    $registry = Load-CliRegistry
    if (-not $registry) {
        Write-Error-Message "无法加载 CLI registry"
        Start-Sleep -Seconds 2
        return
    }
    
    # 构建选项列表
    $options = @()
    $cliKeys = @()
    
    foreach ($key in $registry.PSObject.Properties.Name) {
        $cli = $registry.$key
        
        if ($cli.login) {
            $options += "$($cli.name)"
            $cliKeys += $key
        }
    }
    
    if ($options.Count -eq 0) {
        Write-Warning-Message "没有支持自动登录的 CLI"
        Start-Sleep -Seconds 2
        return
    }
    
    $options += "返回"
    
    $choice = Select-Menu -Title "选择要登录的 CLI" -Options $options
    
    if ($choice -eq $options.Count - 1) {
        return
    }
    
    $selectedKey = $cliKeys[$choice]
    $cli = $registry.$selectedKey
    
    Clear-Host
    Write-Host ""
    Write-Success "正在启动 $($cli.name) 登录流程..."
    Write-Host ""
    Start-Sleep -Seconds 1
    
    # 执行登录命令
    try {
        $loginCmd = $cli.login
        Invoke-Expression $loginCmd
        
        Write-Host ""
        Write-Success "登录流程完成"
        Start-Sleep -Seconds 2
    } catch {
        Write-Error-Message "登录失败: $($_.Exception.Message)"
        Start-Sleep -Seconds 2
    }
}

function Invoke-Logout {
    Clear-Host
    Write-Host ""
    Write-Host "=== 登出 ===" -ForegroundColor Cyan
    Write-Host ""
    
    $registry = Load-CliRegistry
    if (-not $registry) {
        Write-Error-Message "无法加载 CLI registry"
        Start-Sleep -Seconds 2
        return
    }
    
    # 构建选项列表
    $options = @()
    $cliKeys = @()
    
    foreach ($key in $registry.PSObject.Properties.Name) {
        $cli = $registry.$key
        
        if ($cli.auto_logout -and $cli.logout) {
            $options += "$($cli.name)"
            $cliKeys += $key
        } elseif ($cli.logout_guide) {
            $options += "$($cli.name) [需手动]"
            $cliKeys += $key
        }
    }
    
    if ($options.Count -eq 0) {
        Write-Warning-Message "没有可登出的 CLI"
        Start-Sleep -Seconds 2
        return
    }
    
    $options += "返回"
    
    $choice = Select-Menu -Title "选择要登出的 CLI" -Options $options
    
    if ($choice -eq $options.Count - 1) {
        return
    }
    
    $selectedKey = $cliKeys[$choice]
    $cli = $registry.$selectedKey
    
    Clear-Host
    Write-Host ""
    
    if ($cli.auto_logout -and $cli.logout) {
        Write-Success "正在执行 $($cli.name) 登出..."
        Write-Host ""
        Start-Sleep -Seconds 1
        
        try {
            $logoutCmd = $cli.logout
            Invoke-Expression $logoutCmd
            
            Write-Host ""
            Write-Success "登出完成"
            Start-Sleep -Seconds 2
        } catch {
            Write-Error-Message "登出失败: $($_.Exception.Message)"
            Start-Sleep -Seconds 2
        }
    } else {
        Write-Info "$($cli.name) 登出指南："
        Write-Host ""
        Write-Host $cli.logout_guide -ForegroundColor Yellow
        Write-Host ""
        Write-Host "按任意键返回..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Invoke-StartAi {
    Clear-Host
    Write-Host ""
    Write-Host "=== 启动 AI ===" -ForegroundColor Cyan
    Write-Host ""
    
    $registry = Load-CliRegistry
    if (-not $registry) {
        Write-Error-Message "无法加载 CLI registry"
        Start-Sleep -Seconds 2
        return
    }
    
    # 构建选项列表
    $options = @()
    $cliKeys = @()
    
    foreach ($key in $registry.PSObject.Properties.Name) {
        $cli = $registry.$key
        $binName = $cli.bin
        
        if (Get-CliInstalled $binName) {
            $options += "$($cli.name)"
            $cliKeys += $key
        } else {
            $options += "$($cli.name) [未安装]"
            $cliKeys += $key
        }
    }
    $options += "返回主菜单"
    
    $choice = Select-Menu -Title "选择要启动的 AI CLI" -Options $options
    
    if ($choice -eq $options.Count - 1) {
        return
    }
    
    $selectedKey = $cliKeys[$choice]
    $cli = $registry.$selectedKey
    $binName = $cli.bin
    
    if (-not (Get-CliInstalled $binName)) {
        Write-Warning-Message "$($cli.name) 未安装，请先安装"
        Start-Sleep -Seconds 2
        return
    }
    
    Clear-Host
    Write-Host ""
    Write-Success "正在启动 $($cli.name)..."
    Write-Host ""
    Write-Host "提示: 退出 CLI 后将返回主菜单" -ForegroundColor DarkGray
    Write-Host ""
    Start-Sleep -Seconds 1
    
    # 启动 CLI
    try {
        & $binName
    } catch {
        Write-Error-Message "启动失败: $($_.Exception.Message)"
        Start-Sleep -Seconds 2
    }
}

function Invoke-SwitchProfile {
    Clear-Host
    Write-Host ""
    Write-Host "=== 切换 Claude Profile ===" -ForegroundColor Cyan
    Write-Host ""
    
    $profiles = Get-AllProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Warning-Message "没有可用的 Profile，请先创建"
        Write-Host ""
        Write-Host "按任意键返回主菜单..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    $activeProfile = Get-ActiveProfile
    
    # 构建选项列表
    $options = @()
    foreach ($p in $profiles) {
        if ($p -eq $activeProfile) {
            $options += "$p [当前]"
        } else {
            $options += $p
        }
    }
    $options += "返回主菜单"
    
    $choice = Select-Menu -Title "选择要切换的 Profile" -Options $options
    
    if ($choice -eq $options.Count - 1) {
        return
    }
    
    $selectedProfile = $profiles[$choice]
    
    # 读取 profile
    $profileData = Read-Profile $selectedProfile
    if (-not $profileData) {
        Write-Error-Message "无法读取 Profile: $selectedProfile"
        Start-Sleep -Seconds 2
        return
    }
    
    # 读取或创建 ~/.claude.json
    $claudeJsonPath = Join-Path $env:USERPROFILE ".claude.json"
    $claudeConfig = @{}
    
    if (Test-Path $claudeJsonPath) {
        try {
            $claudeConfig = Get-Content $claudeJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
        } catch {
            Write-Warning-Message "~/.claude.json 格式错误，将创建新文件"
            $claudeConfig = @{}
        }
    }
    
    # 确保 env 字段存在
    if (-not $claudeConfig.ContainsKey("env")) {
        $claudeConfig["env"] = @{}
    }
    
    # 更新 env 字段
    $claudeConfig["env"]["ANTHROPIC_BASE_URL"] = $profileData["ANTHROPIC_BASE_URL"]
    $claudeConfig["env"]["ANTHROPIC_API_KEY"] = $profileData["ANTHROPIC_API_KEY"]
    $claudeConfig["env"]["ANTHROPIC_MODEL"] = $profileData["ANTHROPIC_MODEL"]
    
    # 写回 ~/.claude.json
    try {
        $claudeConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $claudeJsonPath -Encoding UTF8 -Force
        
        # 更新 active-profile
        Set-ActiveProfile $selectedProfile
        
        Clear-Host
        Write-Host ""
        Write-Success "Profile 切换成功！"
        Write-Host ""
        Write-Host "Profile 名称: $selectedProfile" -ForegroundColor Cyan
        Write-Host "Base URL: $($profileData['ANTHROPIC_BASE_URL'])"
        Write-Host "Model: $($profileData['ANTHROPIC_MODEL'])"
        Write-Host "API Key: $(Hide-ApiKey $profileData['ANTHROPIC_API_KEY'])"
        Write-Host ""
        Write-Host "按任意键返回主菜单..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        Write-Error-Message "写入 ~/.claude.json 失败: $($_.Exception.Message)"
        Start-Sleep -Seconds 2
    }
}

function Invoke-ManageProfiles {
    while ($true) {
        $options = @(
            "新增 Profile",
            "编辑 Profile",
            "删除 Profile",
            "查看所有 Profile",
            "返回主菜单"
        )
        
        $choice = Select-Menu -Title "Claude Profile 管理" -Options $options
        
        switch ($choice) {
            0 { Invoke-CreateProfile }
            1 { Invoke-EditProfile }
            2 { Invoke-DeleteProfile }
            3 { Invoke-ViewProfiles }
            4 { return }
        }
    }
}

function Invoke-CreateProfile {
    Clear-Host
    Write-Host ""
    Write-Host "=== 新增 Profile ===" -ForegroundColor Cyan
    Write-Host ""
    
    # 选择创建方式
    $options = @(
        "从预设模板创建",
        "完全自定义",
        "返回"
    )
    
    $choice = Select-Menu -Title "选择创建方式" -Options $options
    
    if ($choice -eq 2) { return }
    
    if ($choice -eq 0) {
        # 从模板创建
        Invoke-CreateFromTemplate
    } else {
        # 完全自定义
        Invoke-CreateCustomProfile
    }
}

function Invoke-CreateFromTemplate {
    Clear-Host
    Write-Host ""
    Write-Host "=== 从模板创建 Profile ===" -ForegroundColor Cyan
    Write-Host ""
    
    # 加载模板
    if (-not (Test-Path $script:PROFILE_TEMPLATES_FILE)) {
        Write-Error-Message "模板文件不存在"
        Start-Sleep -Seconds 2
        return
    }
    
    $templates = Get-Content $script:PROFILE_TEMPLATES_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
    
    # 构建选项
    $options = @()
    $templateKeys = @()
    foreach ($key in $templates.PSObject.Properties.Name) {
        $tmpl = $templates.$key
        $options += "$($tmpl.name) - $($tmpl.description)"
        $templateKeys += $key
    }
    $options += "返回"
    
    $choice = Select-Menu -Title "选择模板" -Options $options
    
    if ($choice -eq $options.Count - 1) { return }
    
    $selectedKey = $templateKeys[$choice]
    $template = $templates.$selectedKey
    
    Clear-Host
    Write-Host ""
    Write-Host "模板: $($template.name)" -ForegroundColor Cyan
    Write-Host "Base URL: $($template.base_url)"
    Write-Host "Model: $($template.model)"
    Write-Host ""
    
    # 输入 Profile 名称
    $profileName = Read-Host "输入 Profile 名称"
    if ([string]::IsNullOrWhiteSpace($profileName)) {
        Write-Warning-Message "名称不能为空"
        Start-Sleep -Seconds 2
        return
    }
    
    # 输入 API Key
    $apiKey = Read-Host "输入 API Key"
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Warning-Message "API Key 不能为空"
        Start-Sleep -Seconds 2
        return
    }
    
    # 如果是自定义模板，需要输入 base_url 和 model
    $baseUrl = $template.base_url
    $model = $template.model
    
    if ($selectedKey -eq "custom") {
        $baseUrl = Read-Host "输入 Base URL"
        $model = Read-Host "输入 Model 名称"
    }
    
    # 写入 Profile
    $profileData = @{
        "ANTHROPIC_BASE_URL" = $baseUrl
        "ANTHROPIC_API_KEY" = $apiKey
        "ANTHROPIC_MODEL" = $model
    }
    
    Write-Profile -ProfileName $profileName -Data $profileData
    
    Write-Success "Profile '$profileName' 创建成功！"
    Start-Sleep -Seconds 2
}

function Invoke-CreateCustomProfile {
    Clear-Host
    Write-Host ""
    Write-Host "=== 自定义 Profile ===" -ForegroundColor Cyan
    Write-Host ""
    
    $profileName = Read-Host "输入 Profile 名称"
    if ([string]::IsNullOrWhiteSpace($profileName)) {
        Write-Warning-Message "名称不能为空"
        Start-Sleep -Seconds 2
        return
    }
    
    $baseUrl = Read-Host "输入 Base URL"
    $apiKey = Read-Host "输入 API Key"
    $model = Read-Host "输入 Model 名称"
    
    if ([string]::IsNullOrWhiteSpace($baseUrl) -or [string]::IsNullOrWhiteSpace($apiKey) -or [string]::IsNullOrWhiteSpace($model)) {
        Write-Warning-Message "所有字段都不能为空"
        Start-Sleep -Seconds 2
        return
    }
    
    $profileData = @{
        "ANTHROPIC_BASE_URL" = $baseUrl
        "ANTHROPIC_API_KEY" = $apiKey
        "ANTHROPIC_MODEL" = $model
    }
    
    Write-Profile -ProfileName $profileName -Data $profileData
    
    Write-Success "Profile '$profileName' 创建成功！"
    Start-Sleep -Seconds 2
}

function Invoke-EditProfile {
    Clear-Host
    Write-Host ""
    Write-Host "=== 编辑 Profile ===" -ForegroundColor Cyan
    Write-Host ""
    
    $profiles = Get-AllProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Warning-Message "没有可用的 Profile"
        Start-Sleep -Seconds 2
        return
    }
    
    $options = $profiles + @("返回")
    $choice = Select-Menu -Title "选择要编辑的 Profile" -Options $options
    
    if ($choice -eq $options.Count - 1) { return }
    
    $profileName = $profiles[$choice]
    $profileData = Read-Profile $profileName
    
    if (-not $profileData) {
        Write-Error-Message "无法读取 Profile"
        Start-Sleep -Seconds 2
        return
    }
    
    Clear-Host
    Write-Host ""
    Write-Host "编辑 Profile: $profileName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "当前值 (直接回车保持不变):" -ForegroundColor DarkGray
    Write-Host ""
    
    $newBaseUrl = Read-Host "Base URL [$($profileData['ANTHROPIC_BASE_URL'])]"
    $newApiKey = Read-Host "API Key [$(Hide-ApiKey $profileData['ANTHROPIC_API_KEY'])]"
    $newModel = Read-Host "Model [$($profileData['ANTHROPIC_MODEL'])]"
    
    if (-not [string]::IsNullOrWhiteSpace($newBaseUrl)) {
        $profileData['ANTHROPIC_BASE_URL'] = $newBaseUrl
    }
    if (-not [string]::IsNullOrWhiteSpace($newApiKey)) {
        $profileData['ANTHROPIC_API_KEY'] = $newApiKey
    }
    if (-not [string]::IsNullOrWhiteSpace($newModel)) {
        $profileData['ANTHROPIC_MODEL'] = $newModel
    }
    
    Write-Profile -ProfileName $profileName -Data $profileData
    
    Write-Success "Profile '$profileName' 更新成功！"
    Start-Sleep -Seconds 2
}

function Invoke-DeleteProfile {
    Clear-Host
    Write-Host ""
    Write-Host "=== 删除 Profile ===" -ForegroundColor Cyan
    Write-Host ""
    
    $profiles = Get-AllProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Warning-Message "没有可用的 Profile"
        Start-Sleep -Seconds 2
        return
    }
    
    $options = $profiles + @("返回")
    $choice = Select-Menu -Title "选择要删除的 Profile" -Options $options
    
    if ($choice -eq $options.Count - 1) { return }
    
    $profileName = $profiles[$choice]
    
    Clear-Host
    Write-Host ""
    Write-Warning-Message "确认删除 Profile: $profileName ?"
    Write-Host ""
    $confirm = Read-Host "输入 'yes' 确认删除"
    
    if ($confirm -ne "yes") {
        Write-Info "已取消"
        Start-Sleep -Seconds 1
        return
    }
    
    $profilePath = Join-Path $script:PROFILES_DIR "$profileName.env"
    Remove-Item $profilePath -Force
    
    # 如果删除的是当前激活的 profile，清除 active-profile
    $activeProfile = Get-ActiveProfile
    if ($activeProfile -eq $profileName) {
        if (Test-Path $script:ACTIVE_PROFILE_FILE) {
            Remove-Item $script:ACTIVE_PROFILE_FILE -Force
        }
    }
    
    Write-Success "Profile '$profileName' 已删除"
    Start-Sleep -Seconds 2
}

function Invoke-ViewProfiles {
    Clear-Host
    Write-Host ""
    Write-Host "=== 所有 Profile ===" -ForegroundColor Cyan
    Write-Host ""
    
    $profiles = Get-AllProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Warning-Message "没有可用的 Profile"
    } else {
        $activeProfile = Get-ActiveProfile
        
        foreach ($p in $profiles) {
            $profileData = Read-Profile $p
            
            if ($p -eq $activeProfile) {
                Write-Host "[$p] (当前激活)" -ForegroundColor Green
            } else {
                Write-Host "[$p]" -ForegroundColor Cyan
            }
            
            Write-Host "  Base URL: $($profileData['ANTHROPIC_BASE_URL'])"
            Write-Host "  Model: $($profileData['ANTHROPIC_MODEL'])"
            Write-Host "  API Key: $(Hide-ApiKey $profileData['ANTHROPIC_API_KEY'])"
            Write-Host ""
        }
    }
    
    Write-Host "按任意键返回..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ============================================================================
# 主程序
# ============================================================================

function Start-MainMenu {
    $selected = 0
    $optionCount = $script:MAIN_MENU_OPTIONS.Count
    
    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "=== ai-menu v$script:VERSION ===" -ForegroundColor Cyan
        Write-Host ""
        
        # 显示主菜单选项（带高亮）
        for ($i = 0; $i -lt $optionCount; $i++) {
            if ($i -eq $selected) {
                Write-Host "$script:COLOR_HIGHLIGHT $($i + 1). $($script:MAIN_MENU_OPTIONS[$i]) $script:COLOR_RESET"
            } else {
                Write-Host " $($i + 1). $($script:MAIN_MENU_OPTIONS[$i])"
            }
        }
        
        Write-Host ""
        Write-Host "使用 ↑↓ 选择，回车确认" -ForegroundColor DarkGray
        Write-Host ""
        
        # 显示 CLI 安装状态
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host "CLI 状态:" -ForegroundColor DarkGray
        
        $registry = Load-CliRegistry
        if ($registry) {
            foreach ($key in $registry.PSObject.Properties.Name) {
                $cli = $registry.$key
                $binName = $cli.bin
                
                if (Get-CliInstalled $binName) {
                    Write-Host ("  [OK] " + $cli.name) -ForegroundColor Green
                } else {
                    Write-Host ("  [--] " + $cli.name) -ForegroundColor DarkGray
                }
            }
        }
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        
        # 读取按键
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                $selected = ($selected - 1 + $optionCount) % $optionCount
            }
            40 { # Down arrow
                $selected = ($selected + 1) % $optionCount
            }
            13 { # Enter
                switch ($selected) {
                    0 { Invoke-HealthCheck }
                    1 { Invoke-InstallCli }
                    2 { Invoke-LoginLogout }
                    3 { Invoke-StartAi }
                    4 { 
                        Clear-Host
                        Write-Host "再见！" -ForegroundColor Green
                        exit 0
                    }
                }
            }
        }
    }
}

# ============================================================================
# 入口
# ============================================================================

# 测试模式：只加载函数，不启动主菜单
if ($env:AI_MENU_TEST_MODE -eq "1") {
    return
}

# 正常模式：启动主菜单
Start-MainMenu
