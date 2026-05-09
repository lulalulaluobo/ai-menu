#!/usr/bin/env pwsh
# ai-menu Windows 安装器
# 使用方法: irm <url>/install.ps1 | iex

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# 配置
$INSTALL_DIR = Join-Path $env:USERPROFILE ".ai-menu"
$REPO_BASE = "https://raw.githubusercontent.com/your-repo/ai-menu/main"
$FILES_TO_DOWNLOAD = @(
    "ai-menu.ps1",
    "cli-registry.json"
)

Write-Host ""
Write-Host "=== ai-menu 安装器 ===" -ForegroundColor Cyan
Write-Host ""

# 1. 创建安装目录
Write-Host "[1/5] 创建安装目录..." -ForegroundColor Yellow
if (-not (Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
    Write-Host "  ✓ 已创建: $INSTALL_DIR" -ForegroundColor Green
} else {
    Write-Host "  ✓ 目录已存在: $INSTALL_DIR" -ForegroundColor Green
}

# 2. 下载文件
Write-Host ""
Write-Host "[2/5] 下载文件..." -ForegroundColor Yellow
foreach ($file in $FILES_TO_DOWNLOAD) {
    $url = "$REPO_BASE/$file"
    $dest = Join-Path $INSTALL_DIR $file
    
    try {
        Write-Host "  下载: $file" -ForegroundColor Gray
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        Write-Host "  ✓ 完成: $file" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ 失败: $file - $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "提示: 如果是本地开发，请手动复制文件到 $INSTALL_DIR" -ForegroundColor Yellow
        exit 1
    }
}

# 3. 创建 CMD 包装器
Write-Host ""
Write-Host "[3/5] 创建启动器..." -ForegroundColor Yellow
$wrapperPath = Join-Path $INSTALL_DIR "ai-menu.cmd"
$wrapperContent = @"
@echo off
powershell -ExecutionPolicy Bypass -NoProfile -File "%USERPROFILE%\.ai-menu\ai-menu.ps1" %*
"@
$wrapperContent | Out-File -FilePath $wrapperPath -Encoding ASCII -Force
Write-Host "  ✓ 已创建: ai-menu.cmd" -ForegroundColor Green

# 4. 添加到 PATH
Write-Host ""
Write-Host "[4/5] 配置 PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$INSTALL_DIR*") {
    $newPath = "$currentPath;$INSTALL_DIR"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "  ✓ 已添加到用户 PATH" -ForegroundColor Green
    Write-Host "  提示: 需要重启终端才能生效" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ PATH 已包含安装目录" -ForegroundColor Green
}

# 5. 验证安装
Write-Host ""
Write-Host "[5/5] 验证安装..." -ForegroundColor Yellow
$psScript = Join-Path $INSTALL_DIR "ai-menu.ps1"
if (Test-Path $psScript) {
    Write-Host "  ✓ ai-menu.ps1 已就绪" -ForegroundColor Green
} else {
    Write-Host "  ✗ ai-menu.ps1 未找到" -ForegroundColor Red
}

$cmdWrapper = Join-Path $INSTALL_DIR "ai-menu.cmd"
if (Test-Path $cmdWrapper) {
    Write-Host "  ✓ ai-menu.cmd 已就绪" -ForegroundColor Green
} else {
    Write-Host "  ✗ ai-menu.cmd 未找到" -ForegroundColor Red
}

# 完成
Write-Host ""
Write-Host "=== 安装完成！===" -ForegroundColor Green
Write-Host ""
Write-Host "使用方法:" -ForegroundColor Cyan
Write-Host "  1. 重启终端（让 PATH 生效）" -ForegroundColor White
Write-Host "  2. 输入命令: ai-menu" -ForegroundColor White
Write-Host ""
Write-Host "或者直接运行:" -ForegroundColor Cyan
Write-Host "  powershell -ExecutionPolicy Bypass -File `"$psScript`"" -ForegroundColor White
Write-Host ""
