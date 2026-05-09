# ai-menu - 终端 AI 菜单

一个轻量的终端 AI 控制台脚本，统一管理 5 个终端 AI CLI 的安装、登录、启动。面向不想记命令的普通用户，用箭头键菜单代替命令行。

## 特性

- 🎯 **零记忆负担**：所有操作通过箭头键菜单完成，无需记命令
- 🔧 **统一管理**：一个工具管理 6 个 AI CLI（Codex、Gemini、Claude Code、OpenCode、DeepSeek TUI、Claude GLM）
- 📊 **实时状态**：主菜单底部实时显示所有 CLI 的安装状态
- 🌍 **跨平台**：Linux/macOS（bash）+ Windows（PowerShell），功能完全对等
- 📦 **零依赖**：bash 版不用 jq/dialog，PowerShell 版不用额外模块
- 🔒 **安全设计**：敏感信息自动过滤，权限检查

## 功能

### 1. 环境体检
- 检测 OS、Node.js、npm、pnpm、git 版本
- 检测 6 个 CLI 安装状态
- 网络连通性测试（Anthropic、Google、OpenAI API）
- PATH 冲突检测

### 2. 安装 / 更新 CLI
- 列出 CLI 及安装状态
- 一键安装/更新（自动处理 sudo/管理员权限）
- deepseek-tui 手动安装引导

### 3. 登录 / 登出
- 支持自动登录（claude login 等）
- 手动登出引导（Gemini CLI 等）
- 不抓取或保存用户凭证

### 4. 启动 AI
- 列出所有 CLI，标注未安装
- 一键启动已安装 CLI
- CLI 退出后返回主菜单

## 安装

### 方式 1: 本地安装（推荐用于开发测试）

```powershell
# Windows
cd d:\code\ai-menu
powershell -ExecutionPolicy Bypass -File install-local.ps1

# 重启终端后使用
ai-menu
```

### 方式 2: 在线安装（发布后）

#### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/your-repo/ai-menu/main/install.sh | bash
```

#### Windows

```powershell
irm https://raw.githubusercontent.com/your-repo/ai-menu/main/install.ps1 | iex
```

安装后，在任意终端输入 `ai-menu` 即可启动。

## 使用

```bash
ai-menu
```

使用箭头键 ↑↓ 选择菜单项，回车确认。

### 主菜单

```
=== ai-menu v1.0.0 ===

 1. 环境体检
 2. 安装 / 更新 CLI
 3. 登录 / 登出
 4. 启动 AI
 5. 退出

使用 ↑↓ 选择，回车确认

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CLI 状态:
  [OK] Codex CLI
  [OK] Gemini CLI
  [OK] Claude Code
  [--] OpenCode
  [--] DeepSeek TUI
  [OK] Claude GLM (智谱)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 支持的 CLI

| CLI | 安装方式 | 登录 | 登出 | 说明 |
|-----|---------|------|------|------|
| **Codex CLI** | npm | ✅ | ✅ | OpenAI Codex |
| **Gemini CLI** | npm | ✅ | 手动 | Google Gemini |
| **Claude Code** | npm | ✅ | ✅ | Anthropic Claude |
| **OpenCode** | npm | 配置文件 | 配置文件 | OpenCode AI |
| **DeepSeek TUI** | 手动 | - | - | DeepSeek TUI |
| **Claude GLM** | npx | ✅ | ✅ | 智谱 GLM 的 Claude 安装脚本 |

## 与 cc-switch 的关系

- **ai-menu**：管理 CLI 的安装、登录、启动
- **cc-switch**：管理 Claude Code 的 profile 切换

两者职责清晰，互不重复。

## 技术架构

### bash 版（Linux/macOS）
- 纯 bash 实现，兼容 bash 3.2+（macOS 默认）
- 箭头键菜单：`read -rsn1` + ANSI escape
- JSON 解析：sed/awk（不依赖 jq）
- 权限：自动检测 sudo 需求

### PowerShell 版（Windows）
- PowerShell 5.1+（Windows 10 自带）
- 箭头键菜单：`[Console]::ReadKey()` + ANSI/VT100
- JSON 解析：`ConvertFrom-Json`（原生）
- UTF-8：`chcp 65001` + BOM
- 权限：自动检测管理员权限

## 配置文件

### cli-registry.json
定义 5 个 CLI 的元数据：

```json
{
  "claude": {
    "name": "Claude Code",
    "bin": "claude",
    "npm_package": "@anthropic-ai/claude-code",
    "install": "npm i -g @anthropic-ai/claude-code",
    "update": "npm i -g @anthropic-ai/claude-code@latest",
    "start": "claude",
    "login": "claude login",
    "logout": "claude logout",
    "auto_logout": true
  }
}
```

## 开发

### 测试

```bash
# PowerShell 版测试
powershell -ExecutionPolicy Bypass -File tests\test_powershell.ps1

# bash 版语法检查
bash -n ai-menu.sh

# 集成测试
powershell -ExecutionPolicy Bypass -File tests\integration_test.ps1
```

### 项目结构

```
ai-menu/
├── ai-menu.sh              # bash 主脚本
├── ai-menu.ps1             # PowerShell 主脚本
├── cli-registry.json       # CLI 元数据
├── install.sh              # bash 安装器
├── install.ps1             # PowerShell 安装器
├── tests/                  # 测试套件
│   ├── test_bash.sh
│   ├── test_powershell.ps1
│   └── integration_test.ps1
├── README.md
├── PROGRESS.md             # 开发进度
└── SIMPLIFICATION.md       # 设计简化说明
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可

MIT License

## 致谢

- 感谢 Anthropic、Google、OpenAI 等提供的终端 AI CLI
- 感谢 cc-switch 工具提供的 profile 管理方案
