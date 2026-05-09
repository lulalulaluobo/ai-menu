# ai-menu

一个轻量的终端 AI CLI 菜单工具，用一个统一入口管理 Codex、Gemini、Claude Code、OpenCode、DeepSeek TUI 和 Claude GLM 的环境检测、安装更新、登录登出与启动。

适合不想记一堆 CLI 命令的用户：打开 `ai-menu`，用方向键选择操作即可。

## 特性

- **统一入口**：一个菜单管理 6 个终端 AI CLI
- **跨平台**：支持 Linux/macOS bash 和 Windows PowerShell
- **少依赖**：bash 版不依赖 jq/dialog，PowerShell 版使用系统内置能力
- **状态可见**：主菜单显示各 CLI 是否已安装
- **安装更新**：支持 npm/npx 类 CLI 的安装、更新和卸载
- **登录管理**：支持可自动调用的登录/登出命令，也提供手动引导
- **敏感信息保护**：命令报错输出会过滤常见 API key 格式

## 支持的 CLI

| CLI | 命令 | 安装方式 | 登录 | 登出 | 说明 |
| --- | --- | --- | --- | --- | --- |
| Codex CLI | `codex` | npm | 自动 | 自动 | OpenAI Codex |
| Gemini CLI | `gemini` | npm | 自动 | 手动引导 | Google Gemini |
| Claude Code | `claude` | npm | 自动 | 自动 | Anthropic Claude Code |
| OpenCode | `opencode` | npm | 配置文件 | 配置文件 | OpenCode AI |
| DeepSeek TUI | `deepseek-tui` | npm | - | - | DeepSeek TUI |
| Claude GLM | `claude` | npx | 自动 | 自动 | 智谱 GLM 的 Claude Code 安装脚本 |

## 安装

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/lulalulaluobo/ai-menu/main/install.sh | bash
```

安装完成后，重新打开终端或确认 `~/.local/bin` / `/usr/local/bin` 在 `PATH` 中，然后运行：

```bash
ai-menu
```

也可以直接运行：

```bash
bash ~/.ai-menu/ai-menu.sh
```

### Windows

```powershell
irm https://raw.githubusercontent.com/lulalulaluobo/ai-menu/main/install.ps1 | iex
```

安装完成后，重启终端，然后运行：

```powershell
ai-menu
```

也可以直接运行：

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.ai-menu\ai-menu.ps1"
```

## 本地开发安装

如果你已经 clone 了仓库，可以用本地安装脚本复制当前工作区文件到 `~/.ai-menu`。

### Linux / macOS

```bash
git clone https://github.com/lulalulaluobo/ai-menu.git
cd ai-menu
bash install.sh
```

### Windows

```powershell
git clone https://github.com/lulalulaluobo/ai-menu.git
cd ai-menu
powershell -ExecutionPolicy Bypass -File install-local.ps1
```

## 使用

启动菜单：

```bash
ai-menu
```

使用方向键选择菜单项，按回车确认。

主菜单包含：

```text
=== ai-menu v1.0.0 ===

 1. 环境体检
 2. 安装 / 更新 CLI
 3. 登录 / 登出
 4. 启动 AI
 5. 退出

CLI 状态:
  [OK] Codex CLI
  [OK] Gemini CLI
  [OK] Claude Code
  [--] OpenCode
  [--] DeepSeek TUI
  [OK] Claude GLM (智谱)
```

## 主要功能

### 环境体检

- 检测 OS、Node.js、npm、pnpm、git
- 检测 6 个 CLI 的安装状态和版本
- 检查网络连通性
- 检查 PATH 冲突

### 安装 / 更新 CLI

- 展示每个 CLI 的安装状态
- 一键安装、更新或卸载支持 npm/npx 的 CLI
- 对需要手动处理的工具显示安装引导

### 登录 / 登出

- 自动调用支持的 CLI 登录/登出命令
- 对不支持自动登出的 CLI 显示操作提示
- 不主动采集 CLI 凭证

### 启动 AI

- 列出已配置的 CLI
- 标注未安装项
- 启动后退出 CLI 会返回菜单

## 项目结构

```text
ai-menu/
├── ai-menu.sh              # Linux/macOS bash 主脚本
├── ai-menu.ps1             # Windows PowerShell 主脚本
├── cli-registry.json       # CLI 元数据
├── install.sh              # Linux/macOS 在线安装器
├── install.ps1             # Windows 在线安装器
├── install-local.ps1       # Windows 本地开发安装器
├── tests/
│   ├── test_bash.sh
│   ├── test_powershell.ps1
│   └── integration_test.ps1
└── README.md
```

## 开发与测试

```bash
# bash 语法检查
bash -n ai-menu.sh
bash -n install.sh

# bash 测试
bash tests/test_bash.sh
```

```powershell
# PowerShell 测试
powershell -ExecutionPolicy Bypass -File tests\test_powershell.ps1

# 集成测试
powershell -ExecutionPolicy Bypass -File tests\integration_test.ps1
```

## 安全说明

- 不要把 API key、token、登录态或本机配置提交到 Git
- 命令报错输出会过滤 `sk-`、`key-` 开头的常见敏感字符串
- `.gitignore` 已排除 `.env`、`.ai-menu/`、`profiles/`、`.claude.json` 等本地敏感配置
- 推送前建议执行 `git status --ignored`，确认没有把本地配置文件加入暂存区

## 推送到 GitHub

首次推送可以执行：

```bash
git remote add origin https://github.com/lulalulaluobo/ai-menu.git
git branch -M main
git push -u origin main
```

如果已经存在 `origin`，请先检查：

```bash
git remote -v
```

## License

MIT
