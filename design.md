# Design: ai-menu 终端 AI 菜单

## 架构概览

```
ai-menu/
├── ai-menu.sh              # bash 主脚本（Linux/macOS）
├── ai-menu.ps1             # PowerShell 主脚本（Windows）
├── install.sh              # bash 安装器
├── install.ps1             # PowerShell 安装器
├── cli-registry.json       # 5 个 Target CLI 的元数据
└── profile-templates.json  # 预设 profile 模板（6 个）
```

安装后用户本地目录结构：

```
~/.ai-menu/
├── ai-menu.sh (或 .ps1)   # 主脚本
├── cli-registry.json       # CLI 定义
├── profile-templates.json  # 预设模板
└── profiles/               # 用户创建的 profile
    ├── official.env
    ├── glm.env
    └── deepseek.env
```

## 技术选型

### bash 版（ai-menu.sh）

- **最低要求**：bash 4.0+（macOS 默认 3.2，需兼容或提示升级）
- **TUI 菜单**：纯 bash 实现箭头键选择器（`read -rsn1` 读取按键，ANSI escape 渲染高亮）。不依赖 `dialog`/`whiptail`，零外部依赖
- **网络检测**：`curl -sI --connect-timeout 3` 或 `ping -c1 -W3`
- **JSON 读写**：用 `sed`/`awk` 处理简单 JSON（`~/.claude.json` 的 env 段）。不引入 `jq` 依赖
- **权限**：`chmod 600` / `chmod 700`

### PowerShell 版（ai-menu.ps1）

- **最低要求**：PowerShell 5.1（Windows 10 自带）
- **TUI 菜单**：`[Console]::ReadKey()` 读取箭头键，`Write-Host` + ANSI/VT100 渲染高亮行
- **UTF-8**：脚本入口执行 `chcp 65001 | Out-Null`，设置 `$OutputEncoding = [System.Text.Encoding]::UTF8`
- **JSON 读写**：`ConvertFrom-Json` / `ConvertTo-Json`（PowerShell 原生）
- **权限**：`icacls` 设置当前用户独占 ACL
- **管理员检测**：`[Security.Principal.WindowsPrincipal]` 检查，需要时提示用户

## 模块设计

### 1. 菜单引擎（Menu Engine）

两个版本各自实现一个通用的箭头键菜单函数：

**bash:**
```bash
# 返回用户选中的索引（0-based）
select_menu() {
    local title="$1"
    shift
    local options=("$@")
    # 用 ANSI escape 渲染，read -rsn1 捕获箭头键
    # 返回选中索引
}
```

**PowerShell:**
```powershell
function Select-Menu {
    param([string]$Title, [string[]]$Options)
    # [Console]::ReadKey() 捕获箭头键
    # Write-Host 渲染高亮
    # 返回选中索引
}
```

### 2. CLI Registry（cli-registry.json）

```json
{
  "codex": {
    "name": "Codex CLI",
    "bin": "codex",
    "npm_package": "@openai/codex",
    "install": "npm i -g @openai/codex",
    "update": "npm i -g @openai/codex@latest",
    "uninstall": "npm uninstall -g @openai/codex",
    "start": "codex",
    "login": "codex login",
    "logout": "codex logout",
    "auto_logout": true
  },
  "gemini": {
    "name": "Gemini CLI",
    "bin": "gemini",
    "npm_package": "@anthropic-ai/gemini-cli",
    "install": "npm i -g @anthropic-ai/gemini-cli",
    "update": "npm i -g @anthropic-ai/gemini-cli@latest",
    "uninstall": "npm uninstall -g @anthropic-ai/gemini-cli",
    "start": "gemini",
    "login": "gemini login",
    "logout": null,
    "auto_logout": false,
    "logout_guide": "请在 Gemini CLI 中输入 /auth 切换账号"
  },
  "claude": {
    "name": "Claude Code",
    "bin": "claude",
    "npm_package": "@anthropic-ai/claude-code",
    "install": "npm i -g @anthropic-ai/claude-code",
    "update": "npm i -g @anthropic-ai/claude-code@latest",
    "uninstall": "npm uninstall -g @anthropic-ai/claude-code",
    "start": "claude",
    "login": "claude login",
    "logout": "claude logout",
    "auto_logout": true
  },
  "opencode": {
    "name": "OpenCode",
    "bin": "opencode",
    "npm_package": "opencode-ai",
    "install": "npm i -g opencode-ai",
    "update": "npm i -g opencode-ai@latest",
    "uninstall": "npm uninstall -g opencode-ai",
    "start": "opencode",
    "login": null,
    "logout": null,
    "auto_logout": false,
    "logout_guide": "OpenCode 通过配置文件管理认证，请参考官方文档"
  },
  "deepseek-tui": {
    "name": "DeepSeek TUI",
    "bin": "deepseek-tui",
    "npm_package": null,
    "install": null,
    "status": "pending-research",
    "install_guide": "请按 DeepSeek TUI 官方文档安装：https://github.com/deepseek-ai/deepseek-tui",
    "start": "deepseek-tui",
    "login": null,
    "logout": null,
    "auto_logout": false
  }
}
```

### 3. Profile Templates（profile-templates.json）

```json
{
  "official": {
    "name": "官方 Anthropic",
    "base_url": "https://api.anthropic.com",
    "model": "claude-sonnet-4-20250514",
    "needs_key": true,
    "key_field": "ANTHROPIC_API_KEY",
    "description": "Anthropic 官方 API，需要官方 API Key"
  },
  "glm": {
    "name": "GLM 智谱",
    "base_url": "https://open.bigmodel.cn/api/paas/v4",
    "model": "glm-4-plus",
    "needs_key": true,
    "key_field": "ANTHROPIC_API_KEY",
    "description": "智谱 GLM，兼容 OpenAI 接口"
  },
  "minimax": {
    "name": "MiniMax",
    "base_url": "https://api.minimax.chat/v1",
    "model": "abab6.5s-chat",
    "needs_key": true,
    "key_field": "ANTHROPIC_API_KEY",
    "description": "MiniMax，兼容 OpenAI 接口"
  },
  "deepseek": {
    "name": "DeepSeek",
    "base_url": "https://api.deepseek.com",
    "model": "deepseek-chat",
    "needs_key": true,
    "key_field": "ANTHROPIC_API_KEY",
    "description": "DeepSeek，兼容 OpenAI 接口"
  },
  "kimi": {
    "name": "月之暗面 Kimi",
    "base_url": "https://api.moonshot.cn/v1",
    "model": "moonshot-v1-128k",
    "needs_key": true,
    "key_field": "ANTHROPIC_API_KEY",
    "description": "月之暗面 Kimi，兼容 OpenAI 接口"
  },
  "custom": {
    "name": "自定义 OpenAI 兼容网关",
    "base_url": "",
    "model": "",
    "needs_key": true,
    "key_field": "ANTHROPIC_API_KEY",
    "description": "任意兼容 OpenAI 接口的网关，需自行填写 Base URL 和模型名"
  }
}
```

### 4. Profile 存储格式

每个 profile 是一个 `.env` 文件，存在 `~/.ai-menu/profiles/{name}.env`：

```env
# Profile: glm
ANTHROPIC_BASE_URL=https://open.bigmodel.cn/api/paas/v4
ANTHROPIC_API_KEY=sk-xxxxxxxxxxxx
ANTHROPIC_MODEL=glm-4-plus
```

当前激活的 profile 记录在 `~/.ai-menu/active-profile` 文件中（纯文本，内容为 profile 名）。

### 5. Profile 切换流程

```
用户选择 profile
    ↓
读取 ~/.ai-menu/profiles/{name}.env
    ↓
读取 ~/.claude.json（如不存在则创建空 JSON）
    ↓
修改 JSON 中的 env 字段：
  - env.ANTHROPIC_BASE_URL = profile 中的值
  - env.ANTHROPIC_API_KEY = profile 中的值
  - env.ANTHROPIC_MODEL = profile 中的值
    ↓
写回 ~/.claude.json
    ↓
更新 ~/.ai-menu/active-profile 为当前 profile 名
    ↓
显示切换成功摘要
```

### 6. 环境体检流程

```
检测 OS 类型和版本
    ↓
检测 Node.js: command -v node && node --version
    ↓
检测 npm: command -v npm && npm --version
    ↓
检测 pnpm: command -v pnpm && pnpm --version（可选）
    ↓
检测 git: command -v git && git --version
    ↓
检测 5 个 Target_CLI 是否在 PATH 中
    ↓
网络连通性：curl -sI --connect-timeout 3 各端点
    ↓
PATH 冲突检测：which -a claude / where.exe claude 看是否有多个
    ↓
汇总输出表格
```

### 7. 安装器设计（install.sh / install.ps1）

**install.sh 流程：**
1. 创建 `~/.ai-menu/` 目录
2. 下载 `ai-menu.sh`、`cli-registry.json`、`profile-templates.json` 到该目录
3. `chmod +x ~/.ai-menu/ai-menu.sh`
4. 创建 symlink：`ln -sf ~/.ai-menu/ai-menu.sh /usr/local/bin/ai-menu`（需 sudo）或 `~/.local/bin/ai-menu`（无需 sudo，检查是否在 PATH）
5. 打印安装成功提示

**install.ps1 流程：**
1. 创建 `$env:USERPROFILE\.ai-menu\` 目录
2. 下载 `ai-menu.ps1`、`cli-registry.json`、`profile-templates.json` 到该目录
3. 将 `$env:USERPROFILE\.ai-menu\` 加入用户 PATH（如果不在的话）
4. 创建 `ai-menu.cmd` 包装器（内容：`@powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\.ai-menu\ai-menu.ps1" %*`）
5. 打印安装成功提示

### 8. JSON 操作策略（bash 版）

`~/.claude.json` 的结构相对简单，bash 版用以下策略处理：

- **读取**：`grep` + `sed` 提取 env 段中的特定 key
- **写入**：如果 env 段已存在，用 `sed` 替换对应行；如果不存在，在 JSON 末尾 `}` 前插入 env 块
- **不引入 jq 依赖**：保持零外部依赖原则
- **边界处理**：如果 `~/.claude.json` 不存在，创建最小结构 `{"env":{}}`

### 9. 错误处理策略

所有外部命令执行后检查退出码：

```bash
if ! npm i -g @anthropic-ai/claude-code 2>&1; then
    echo "❌ 安装失败：请检查网络连接或 npm 权限"
    echo "原始报错："
    # 显示捕获的 stderr
fi
```

敏感信息过滤：在输出报错前，用 `sed` 将匹配 `sk-` 或 `key-` 开头的长字符串替换为 `****` + 后 4 位。

## 不做的事（设计边界）

- 不引入任何外部依赖（bash 版不用 jq/dialog/python，PowerShell 版不用额外模块）
- 不做配置备份/回滚（用户可以手动备份 `~/.ai-menu/profiles/`）
- 不做自动更新（用户重新跑 install 命令即可更新）
- 不做 OAuth 代理
- 不做遥测
