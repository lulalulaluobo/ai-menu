# Requirements: ai-menu 终端 AI 菜单

## 概述

ai-menu 是一个轻量的终端 AI 控制台脚本，面向不想记命令的普通用户。它把 5 个终端 AI CLI 的安装、登录、启动、配置切换等操作收进一个箭头键菜单，用户不需要记任何命令。

- **形态**：bash 脚本（Linux/macOS）+ PowerShell 脚本（Windows），功能对等
- **目标用户**：完全不懂终端的人
- **覆盖 CLI**：Codex CLI、Gemini CLI、Claude Code、OpenCode、deepseek-tui
- **核心特色**：Claude Code 的 profile 管理（预设国内模型模板，一键切换）

## 术语

- **ai-menu**：本工具，通过 `curl | bash` 或 `irm | iex` 安装后，敲 `ai-menu` 进入主菜单
- **Target_CLI**：5 个被管理的终端 AI CLI
- **Profile**：一组 Claude Code 的环境配置（base_url + api_key + model），存为 `.env` 文件
- **Profile_Template**：预设的模型配置模板，用户只需填 API Key 即可创建 profile
- **Config_Home**：ai-menu 的配置目录，`~/.ai-menu/`

## 需求列表

### R1：安装与分发

**User Story:** 作为普通用户，我想一条命令装好 ai-menu，以后敲 `ai-menu` 就能用。

**验收标准：**
1. Linux/macOS：`curl -fsSL <url> | bash` 完成安装，脚本放入 `~/.ai-menu/`，创建 symlink 使 `ai-menu` 命令可用
2. Windows：`irm <url> | iex` 完成安装，脚本放入 `%USERPROFILE%\.ai-menu\`，将目录加入用户 PATH
3. 安装后在任意新终端窗口中输入 `ai-menu` 即可启动主菜单

### R2：跨平台一致性

**User Story:** 作为用户，我希望在 Windows、macOS、Linux 上看到相同的菜单结构和操作流程。

**验收标准：**
1. bash 版和 PowerShell 版的菜单项文案、层级结构、操作流程完全一致
2. Profile 文件格式（`.env`）跨平台通用，可以直接复制到另一个系统使用
3. Windows 版启动时强制 `chcp 65001` 切换 UTF-8，确保中文不乱码

### R3：主菜单结构

**User Story:** 作为用户，我打开 ai-menu 就能看到所有能做的事，用箭头键选择。

**验收标准：**
1. 主菜单使用箭头键上下选择 + 回车确认（非数字输入）
2. 主菜单项如下：
   - 环境体检
   - 安装 / 更新 CLI
   - 登录 / 登出
   - 启动 AI
   - 切换 Claude Profile [当前: xxx]
   - Claude Profile 管理
   - 退出
3. 每个子功能完成后返回主菜单，不退出进程

### R4：环境体检

**User Story:** 作为普通用户，我想一键检查本机环境是否就绪。

**验收标准：**
1. 检测并显示：OS 类型/版本、Node.js 版本、npm 版本、pnpm（可选）、git 版本
2. 检测 5 个 Target_CLI 是否已安装及版本号
3. 检测网络连通性：api.anthropic.com、generativelanguage.googleapis.com、api.openai.com
4. 检测 PATH 中是否有冲突的同名 CLI（多个 `claude` 等）
5. 未安装的项给出中文提示和获取方式

### R5：安装 / 更新 CLI

**User Story:** 作为用户，我想通过菜单选一个 CLI 就能装好或更新。

**验收标准：**
1. 子菜单列出 5 个 Target_CLI，显示当前安装状态
2. 选中后执行对应的官方安装/更新命令（如 `npm i -g @anthropic-ai/claude-code`）
3. 需要 sudo 时直接 `sudo npm i -g xxx`，让系统弹密码提示
4. Windows 需要管理员权限时提示"请以管理员身份运行 PowerShell"
5. deepseek-tui 如安装方式未确定，显示"请按官方文档安装"引导文本
6. 成功显示版本号，失败显示一行中文原因 + 原始报错

### R6：登录 / 登出

**User Story:** 作为用户，我想通过菜单完成各 CLI 的登录登出。

**验收标准：**
1. 子菜单列出各 CLI 的登录/登出选项
2. 支持自动执行的（如 `claude login`）直接执行
3. 不支持脚本登出的（如 Gemini CLI），显示中文引导（"请在 Gemini CLI 中输入 /auth"）
4. 不抓取或保存用户在 CLI 中输入的凭证

### R7：启动 AI

**User Story:** 作为用户，我想从菜单直接启动某个 AI CLI。

**验收标准：**
1. 子菜单列出 5 个 CLI，未安装的标注"未安装"
2. 选中已安装的 CLI 后直接启动
3. 启动 Claude Code 时，如果有激活的 profile，按该 profile 的配置启动
4. CLI 退出后返回主菜单

### R8：切换 Claude Profile

**User Story:** 作为用户，我想在主菜单一步切换 Claude 的模型/网关配置。

**验收标准：**
1. 列出所有已创建的 profile，标注当前激活的
2. 用户选中后，直接改写 `~/.claude.json` 的 env 段（`ANTHROPIC_BASE_URL`、`ANTHROPIC_API_KEY`、`ANTHROPIC_MODEL`）
3. 切换后显示当前 profile 摘要（名称、base_url、model、key 后 4 位）
4. 切换立即生效，不需要重启终端

### R9：Claude Profile 管理

**User Story:** 作为用户，我想新增、编辑、删除、查看 profile。

**验收标准：**
1. 子菜单：新增 / 编辑 / 删除 / 查看所有 / 返回
2. **新增**：可从预设模板创建（只需填 API Key），也可完全自定义（填 base_url + key + model）
3. **预设模板**包含：官方 Anthropic、GLM（智谱）、MiniMax、DeepSeek、月之暗面（Kimi）、通用 OpenAI 兼容网关
4. **编辑**：逐字段修改已有 profile
5. **删除**：确认后删除 profile 文件
6. **查看**：列出所有 profile 摘要，API Key 只显示后 4 位（`****abcd`）
7. Profile 文件存储在 `~/.ai-menu/profiles/{name}.env`，格式为 `KEY=VALUE`
8. Profile 文件权限：Unix 设为 0600，Windows 设为当前用户独占

### R10：错误处理

**User Story:** 作为普通用户，操作失败时我想看到中文说明而不是英文堆栈。

**验收标准：**
1. 失败时显示一行中文摘要（"安装失败：网络超时，请检查网络后重试"）
2. 紧跟原始报错信息供高级用户参考
3. API Key 等敏感信息在报错中不完整显示

### R11：功能边界（不做的事）

1. 不提供 GUI，只有终端菜单
2. 不代替 CLI 完成 OAuth 浏览器跳转
3. 不收集遥测、不联网上报
4. 不提供云端同步
5. 不以守护进程驻留，退出即结束
6. 不提供回滚/备份（保持简单）
