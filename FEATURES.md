# ai-menu 功能详解

## 主菜单

主菜单是 ai-menu 的核心界面，提供 5 个主要功能和实时 CLI 状态显示。

### 界面布局

```
┌─────────────────────────────────────────┐
│     === ai-menu v1.0.0 ===             │
│                                         │
│  1. 环境体检                            │
│  2. 安装 / 更新 CLI                     │
│  3. 登录 / 登出                         │
│  4. 启动 AI                             │
│  5. 退出                                │
│                                         │
│  使用 ↑↓ 选择，回车确认                 │
│                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  CLI 状态:                              │
│    [OK] Codex CLI                       │
│    [OK] Gemini CLI                      │
│    [OK] Claude Code                     │
│    [--] OpenCode                        │
│    [--] DeepSeek TUI                    │
│    [OK] Claude GLM (智谱)               │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
└─────────────────────────────────────────┘
```

### 状态指示器

- `[OK]` + 绿色：CLI 已安装且可用
- `[--]` + 灰色：CLI 未安装

## 功能 1：环境体检

全面检测系统环境和 CLI 状态。

### 检测项目

1. **操作系统**
   - OS 类型和版本
   - 平台信息

2. **开发工具**
   - Node.js 版本
   - npm 版本
   - pnpm 版本（可选）
   - git 版本

3. **CLI 状态**
   - 6 个 AI CLI 的安装状态
   - 版本号显示
   - 未安装项的获取方式

4. **网络连通性**
   - Anthropic API (api.anthropic.com)
   - Google Gemini API (generativelanguage.googleapis.com)
   - OpenAI API (api.openai.com)

5. **PATH 冲突检测**
   - 检查是否有多个同名 CLI
   - 显示所有路径

### 输出示例

```
【操作系统】
  Windows 10.0.19045

【Node.js】
  ✓ 已安装: v20.11.0

【npm】
  ✓ 已安装: 10.2.4

【Target CLI 状态】
  ✓ Codex CLI: 已安装 (v1.2.3)
  ✓ Claude Code: 已安装 (v2.1.137)
  ⚠ OpenCode: 未安装

【网络连通性】
  ✓ Anthropic API: 可访问
  ✓ Google Gemini API: 可访问
  ✓ OpenAI API: 可访问
```

## 功能 2：安装 / 更新 CLI

统一管理所有 CLI 的安装和更新。

### 子菜单

1. **安装 CLI**
   - 列出所有 CLI 及安装状态
   - 选择后自动执行安装命令
   - 自动处理权限（sudo/管理员）

2. **更新 CLI**
   - 只显示已安装的 CLI
   - 一键更新到最新版本

### 支持的安装方式

| CLI | 安装命令 | 权限要求 |
|-----|---------|---------|
| Codex CLI | `npm i -g @openai/codex` | 管理员 |
| Gemini CLI | `npm i -g @anthropic-ai/gemini-cli` | 管理员 |
| Claude Code | `npm i -g @anthropic-ai/claude-code` | 管理员 |
| OpenCode | `npm i -g opencode-ai` | 管理员 |
| DeepSeek TUI | 手动安装 | - |
| Claude GLM | `npx @z_ai/coding-helper` | 无需管理员 |

### 特殊处理

- **DeepSeek TUI**：显示官方安装指南
- **Claude GLM**：使用 `npx` 无需全局安装
- **权限检测**：自动检测并提示所需权限

## 功能 3：登录 / 登出

统一管理 CLI 的认证。

### 子菜单

1. **登录**
   - 列出支持自动登录的 CLI
   - 执行 `<cli> login` 命令
   - 不抓取或保存凭证

2. **登出**
   - 自动登出：直接执行 `<cli> logout`
   - 手动登出：显示操作指南

### 登录/登出支持

| CLI | 登录 | 登出 |
|-----|------|------|
| Codex CLI | ✅ 自动 | ✅ 自动 |
| Gemini CLI | ✅ 自动 | 📖 手动指南 |
| Claude Code | ✅ 自动 | ✅ 自动 |
| OpenCode | 📖 配置文件 | 📖 配置文件 |
| DeepSeek TUI | - | - |
| Claude GLM | ✅ 自动 | ✅ 自动 |

## 功能 4：启动 AI

快速启动已安装的 CLI。

### 特点

- 列出所有 CLI，标注未安装
- 选择后直接启动
- CLI 退出后返回主菜单
- 无需记命令

### 使用流程

```
1. 选择"启动 AI"
2. 从列表中选择 CLI
3. CLI 启动（如 claude）
4. 使用 CLI
5. 退出 CLI（Ctrl+D 或 /exit）
6. 自动返回 ai-menu 主菜单
```

## 功能 5：退出

安全退出 ai-menu。

## 技术特性

### 零依赖

- **bash 版**：纯 bash + sed/awk，不依赖 jq/dialog
- **PowerShell 版**：原生 cmdlet，不依赖额外模块

### 跨平台一致

- 菜单文案完全一致
- 功能行为对等
- 快捷键统一（↑↓ + 回车）

### 安全设计

- 敏感信息自动过滤（API Key 只显示后 4 位）
- 权限检查（sudo/管理员）
- 不抓取或保存用户凭证

### 用户友好

- 箭头键导航，无需记命令
- 中文界面，清晰提示
- 实时状态显示
- 错误信息中文化

## 使用技巧

### 快速检查环境

```
ai-menu → 1 (环境体检) → 查看所有状态
```

### 批量安装 CLI

```
ai-menu → 2 (安装/更新) → 1 (安装) → 逐个选择安装
```

### 快速启动

```
ai-menu → 4 (启动 AI) → 选择 CLI → 开始使用
```

### 查看状态

主菜单底部实时显示，无需进入子菜单。

## 常见问题

### Q: 如何更新 ai-menu 本身？

A: 重新运行安装脚本即可。

### Q: 如何添加自定义 CLI？

A: 编辑 `~/.ai-menu/cli-registry.json`，添加新的 CLI 配置。

### Q: 为什么需要管理员权限？

A: npm 全局安装（`-g`）需要管理员权限。可以使用 npm 的用户级安装避免。

### Q: Claude GLM 和 Claude Code 有什么区别？

A: Claude GLM 使用智谱 GLM 模型，Claude Code 使用 Anthropic 官方模型。两者界面相同。

## 快捷键

- `↑` / `↓`：上下移动选择
- `Enter`：确认选择
- `Ctrl+C`：退出（任何界面）

## 配置文件

- `~/.ai-menu/cli-registry.json`：CLI 元数据
- `~/.ai-menu/ai-menu.sh`：bash 主脚本
- `~/.ai-menu/ai-menu.ps1`：PowerShell 主脚本
- `~/.ai-menu/ai-menu.cmd`：Windows 启动器

## 日志

ai-menu 不生成日志文件，所有输出直接显示在终端。
