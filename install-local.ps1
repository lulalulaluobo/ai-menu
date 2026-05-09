# ai-menu 本地安装脚本
$INSTALL_DIR = Join-Path $env:USERPROFILE ".ai-menu"
$SOURCE_DIR = $PSScriptRoot

Write-Host "`n=== ai-menu 本地安装 ===`n" -ForegroundColor Cyan

# 创建目录
if (-not (Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
}

# 复制文件
Copy-Item (Join-Path $SOURCE_DIR "ai-menu.ps1") $INSTALL_DIR -Force
Copy-Item (Join-Path $SOURCE_DIR "cli-registry.json") $INSTALL_DIR -Force

# 创建 CMD 包装器
$wrapperPath = Join-Path $INSTALL_DIR "ai-menu.cmd"
@"
@echo off
powershell -ExecutionPolicy Bypass -NoProfile -File "%USERPROFILE%\.ai-menu\ai-menu.ps1" %*
"@ | Out-File -FilePath $wrapperPath -Encoding ASCII -Force

# 添加到 PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$INSTALL_DIR*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$INSTALL_DIR", "User")
    Write-Host "已添加到 PATH，请重启终端`n" -ForegroundColor Green
} else {
    Write-Host "PATH 已配置`n" -ForegroundColor Green
}

Write-Host "安装完成！输入 ai-menu 启动（需重启终端）`n" -ForegroundColor Cyan
