# Implementation Plan: ai-menu 终端 AI 菜单

## Overview

将 ai-menu 的设计拆解为可执行的编码任务。实现分为两条并行线：bash 版（Linux/macOS）和 PowerShell 版（Windows），共享 JSON 配置文件。任务按模块递进，先搭建基础设施（菜单引擎、配置文件），再逐步实现各功能模块，最后集成联调。

## Tasks

- [ ] 1. 创建项目结构和配置文件
  - [ ] 1.1 创建 cli-registry.json
    - 按设计文档定义 5 个 Target CLI 的元数据
    - 包含 name、bin、npm_package、install、update、start、login、logout 等字段
    - _Requirements: R5.1, R5.5, R6.1, R7.1_

  - [ ] 1.2 创建 profile-templates.json
    - 定义 6 个预设模板：官方 Anthropic、GLM、MiniMax、DeepSeek、Kimi、自定义网关
    - 每个模板包含 name、base_url、model、needs_key、key_field、description
    - _Requirements: R9.3_

- [ ] 2. 实现 bash 版菜单引擎（ai-menu.sh 核心）
  - [ ] 2.1 实现 select_menu 箭头键选择函数
    - 使用 `read -rsn1` 捕获按键输入
    - ANSI escape 渲染高亮当前选中项
    - 支持上下箭头移动、回车确认
    - 兼容 bash 3.2+（macOS 默认版本）
    - _Requirements: R3.1_

  - [ ] 2.2 实现主菜单框架和循环逻辑
    - 定义主菜单 7 个选项
    - 实现主循环：选择 → 执行子功能 → 返回主菜单
    - 退出选项终止脚本
    - _Requirements: R3.2, R3.3_

- [ ] 3. 实现 PowerShell 版菜单引擎（ai-menu.ps1 核心）
  - [ ] 3.1 实现 Select-Menu 箭头键选择函数
    - 使用 `[Console]::ReadKey()` 捕获按键
    - `Write-Host` + ANSI/VT100 渲染高亮行
    - 支持上下箭头移动、回车确认
    - _Requirements: R3.1_

  - [ ] 3.2 实现主菜单框架和循环逻辑
    - 脚本入口执行 `chcp 65001 | Out-Null` 和 `$OutputEncoding = [System.Text.Encoding]::UTF8`
    - 定义主菜单 7 个选项（与 bash 版文案一致）
    - 实现主循环：选择 → 执行子功能 → 返回主菜单
    - _Requirements: R2.1, R2.3, R3.2, R3.3_

- [ ] 4. Checkpoint - 菜单引擎验证
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. 实现环境体检模块
  - [ ] 5.1 bash 版环境体检函数
    - 检测 OS 类型/版本（`uname -a`）
    - 检测 Node.js、npm、pnpm、git 版本（`command -v` + `--version`）
    - 读取 cli-registry.json，检测 5 个 CLI 是否已安装及版本号
    - 网络连通性检测：`curl -sI --connect-timeout 3` 测试 3 个 API 端点
    - PATH 冲突检测：`which -a` 检查同名 CLI 是否有多个
    - 未安装项给出中文提示和获取方式
    - 汇总输出格式化表格
    - _Requirements: R4.1, R4.2, R4.3, R4.4, R4.5_

  - [ ] 5.2 PowerShell 版环境体检函数
    - 检测 OS 类型/版本（`[System.Environment]::OSVersion`）
    - 检测 Node.js、npm、pnpm、git 版本（`Get-Command` + `--version`）
    - 读取 cli-registry.json，检测 5 个 CLI 是否已安装
    - 网络连通性检测：`Test-NetConnection` 或 `Invoke-WebRequest`
    - PATH 冲突检测：`where.exe` 检查同名 CLI
    - 未安装项给出中文提示
    - _Requirements: R4.1, R4.2, R4.3, R4.4, R4.5_

- [ ] 6. 实现安装/更新 CLI 模块
  - [ ] 6.1 bash 版安装/更新函数
    - 读取 cli-registry.json 列出 5 个 CLI 及当前安装状态
    - 选中后执行对应 install/update 命令
    - 需要 sudo 时使用 `sudo npm i -g xxx`
    - deepseek-tui 显示引导文本
    - 成功显示版本号，失败显示中文原因 + 原始报错
    - _Requirements: R5.1, R5.2, R5.3, R5.5, R5.6_

  - [ ] 6.2 PowerShell 版安装/更新函数
    - 读取 cli-registry.json 列出 5 个 CLI 及当前安装状态
    - 选中后执行对应 install/update 命令
    - 检测管理员权限，需要时提示用户
    - deepseek-tui 显示引导文本
    - 成功显示版本号，失败显示中文原因 + 原始报错
    - _Requirements: R5.1, R5.2, R5.4, R5.5, R5.6_

- [ ] 7. 实现登录/登出模块
  - [ ] 7.1 bash 版登录/登出函数
    - 读取 cli-registry.json 列出各 CLI 登录/登出选项
    - 支持自动执行的直接调用（如 `claude login`）
    - 不支持脚本登出的显示中文引导
    - 不抓取或保存用户凭证
    - _Requirements: R6.1, R6.2, R6.3, R6.4_

  - [ ] 7.2 PowerShell 版登录/登出函数
    - 功能与 bash 版一致
    - 使用 `Start-Process` 或直接调用 CLI 命令
    - _Requirements: R6.1, R6.2, R6.3, R6.4_

- [ ] 8. 实现启动 AI 模块
  - [ ] 8.1 bash 版启动 AI 函数
    - 列出 5 个 CLI，未安装的标注"未安装"
    - 选中已安装 CLI 后直接启动（`exec` 或前台运行）
    - 启动 Claude Code 时加载激活 profile 的环境变量
    - CLI 退出后返回主菜单
    - _Requirements: R7.1, R7.2, R7.3, R7.4_

  - [ ] 8.2 PowerShell 版启动 AI 函数
    - 功能与 bash 版一致
    - 启动 Claude Code 时设置 `$env:` 环境变量
    - _Requirements: R7.1, R7.2, R7.3, R7.4_

- [ ] 9. Checkpoint - 基础功能模块验证
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. 实现 Profile 管理模块
  - [ ] 10.1 bash 版 Profile 存储与读写工具函数
    - 实现 .env 文件读写（`source` 读取，`echo` 写入）
    - 实现 active-profile 文件读写
    - Profile 文件权限设为 0600
    - API Key 显示时只保留后 4 位（`****abcd`）
    - _Requirements: R9.7, R9.8, R9.6_

  - [ ] 10.2 bash 版 Profile CRUD 子菜单
    - 新增：从预设模板创建（只需填 API Key）或完全自定义
    - 编辑：逐字段修改已有 profile
    - 删除：确认后删除 profile 文件
    - 查看：列出所有 profile 摘要
    - _Requirements: R9.1, R9.2, R9.3, R9.4, R9.5, R9.6_

  - [ ] 10.3 PowerShell 版 Profile 存储与读写工具函数
    - 实现 .env 文件读写（`Get-Content` + 解析，`Set-Content` 写入）
    - 实现 active-profile 文件读写
    - 使用 `icacls` 设置当前用户独占 ACL
    - API Key 显示时只保留后 4 位
    - _Requirements: R9.7, R9.8, R9.6_

  - [ ] 10.4 PowerShell 版 Profile CRUD 子菜单
    - 功能与 bash 版一致
    - _Requirements: R9.1, R9.2, R9.3, R9.4, R9.5, R9.6_

- [ ] 11. 实现 Profile 切换模块
  - [ ] 11.1 bash 版 Profile 切换函数
    - 列出所有 profile，标注当前激活的
    - 选中后读取 profile .env 文件
    - 读取 `~/.claude.json`（不存在则创建 `{"env":{}}`）
    - 用 sed/awk 修改 JSON 中 env 段的 ANTHROPIC_BASE_URL、ANTHROPIC_API_KEY、ANTHROPIC_MODEL
    - 更新 `~/.ai-menu/active-profile`
    - 显示切换成功摘要（名称、base_url、model、key 后 4 位）
    - _Requirements: R8.1, R8.2, R8.3, R8.4_

  - [ ] 11.2 PowerShell 版 Profile 切换函数
    - 功能与 bash 版一致
    - 使用 `ConvertFrom-Json` / `ConvertTo-Json` 操作 `~/.claude.json`
    - _Requirements: R8.1, R8.2, R8.3, R8.4_

- [ ] 12. 实现错误处理与敏感信息过滤
  - [ ] 12.1 bash 版错误处理封装
    - 封装通用命令执行函数，捕获 stdout/stderr 和退出码
    - 失败时显示中文摘要 + 原始报错
    - 输出前用 sed 过滤 `sk-`/`key-` 开头的敏感字符串（替换为 `****` + 后 4 位）
    - _Requirements: R10.1, R10.2, R10.3_

  - [ ] 12.2 PowerShell 版错误处理封装
    - 封装通用命令执行函数（try/catch + `$LASTEXITCODE`）
    - 失败时显示中文摘要 + 原始报错
    - 输出前用正则过滤敏感字符串
    - _Requirements: R10.1, R10.2, R10.3_

- [ ] 13. Checkpoint - 全功能验证
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 14. 实现安装器
  - [ ] 14.1 创建 install.sh（Linux/macOS 安装器）
    - 创建 `~/.ai-menu/` 目录
    - 下载 ai-menu.sh、cli-registry.json、profile-templates.json
    - `chmod +x ~/.ai-menu/ai-menu.sh`
    - 创建 symlink：优先 `/usr/local/bin/ai-menu`（需 sudo），备选 `~/.local/bin/ai-menu`
    - 检查 `~/.local/bin` 是否在 PATH，不在则提示用户添加
    - 打印安装成功提示
    - _Requirements: R1.1, R1.3_

  - [ ] 14.2 创建 install.ps1（Windows 安装器）
    - 创建 `$env:USERPROFILE\.ai-menu\` 目录
    - 下载 ai-menu.ps1、cli-registry.json、profile-templates.json
    - 将目录加入用户 PATH（如果不在的话）
    - 创建 `ai-menu.cmd` 包装器
    - 打印安装成功提示
    - _Requirements: R1.2, R1.3_

- [ ] 15. 集成联调与主菜单状态显示
  - [ ] 15.1 主菜单动态显示当前 Profile
    - 主菜单"切换 Claude Profile"项动态显示 `[当前: xxx]`
    - 读取 `~/.ai-menu/active-profile` 获取当前 profile 名
    - 两个版本实现一致
    - _Requirements: R3.2, R8.1_

  - [ ] 15.2 集成所有模块到主菜单入口
    - 确保 bash 版所有子功能正确挂载到主菜单选项
    - 确保 PowerShell 版所有子功能正确挂载到主菜单选项
    - 验证两个版本菜单项文案、层级结构完全一致
    - _Requirements: R2.1, R2.2, R3.2_

- [ ] 16. Final checkpoint - 全部完成
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- bash 版和 PowerShell 版功能对等，但实现方式各自遵循平台惯例
- 不引入任何外部依赖：bash 版不用 jq/dialog，PowerShell 版不用额外模块
- Profile 文件格式（.env）跨平台通用
- 所有用户可见文案使用中文
- 每个 Checkpoint 是验证前面模块正确性的节点

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["2.1", "3.1"] },
    { "id": 2, "tasks": ["2.2", "3.2"] },
    { "id": 3, "tasks": ["5.1", "5.2", "6.1", "6.2", "7.1", "7.2", "8.1", "8.2", "12.1", "12.2"] },
    { "id": 4, "tasks": ["10.1", "10.3"] },
    { "id": 5, "tasks": ["10.2", "10.4", "11.1", "11.2"] },
    { "id": 6, "tasks": ["14.1", "14.2", "15.1"] },
    { "id": 7, "tasks": ["15.2"] }
  ]
}
```
