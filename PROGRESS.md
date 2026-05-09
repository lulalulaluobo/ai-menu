# ai-menu 开发进度

## ✅ 已完成

### 核心架构
- ✅ 项目结构和配置文件（cli-registry.json）
- ✅ bash 版菜单引擎（箭头键选择）
- ✅ PowerShell 版菜单引擎
- ✅ 主菜单框架和循环（5 个选项）
- ✅ 跨平台一致性（功能对等）

### 核心功能模块
- ✅ **环境体检**（bash + PowerShell）
  - OS/Node.js/npm/pnpm/git 检测
  - 5 个 CLI 安装状态检测
  - 网络连通性检测
  - PATH 冲突检测
  
- ✅ **安装/更新 CLI**（bash + PowerShell）
  - 列出 CLI 及安装状态
  - 执行 npm install/update 命令
  - sudo/管理员权限处理
  - deepseek-tui 手动安装引导
  - 错误处理和版本显示
  
- ✅ **登录/登出**（bash + PowerShell）
  - 自动登录支持（claude login 等）
  - 手动登出引导（Gemini CLI 等）
  - 不抓取用户凭证
  
- ✅ **启动 AI**（bash + PowerShell）
  - 列出 CLI，标注未安装
  - 直接启动已安装 CLI
  - CLI 退出后返回主菜单

### 工具函数
- ✅ API Key 掩码（mask_api_key / Hide-ApiKey）
- ✅ 敏感信息过滤（filter_sensitive / Hide-SensitiveInfo）
- ✅ CLI Registry 加载和解析
- ✅ CLI 安装状态检测
- ✅ CLI 版本获取
- ✅ 错误处理封装（run_cmd / Invoke-SafeCommand）

### 测试框架
- ✅ PowerShell 测试套件 - 10/10 通过
- ✅ bash 语法检查通过
- ✅ 集成测试框架

## 📋 待完成

### Task 14: 安装器
- [ ] install.sh (Linux/macOS)
  - 创建 ~/.ai-menu/
  - 下载文件（ai-menu.sh, cli-registry.json）
  - 创建 symlink 到 /usr/local/bin 或 ~/.local/bin
  - PATH 检查和提示
  
- [ ] install.ps1 (Windows)
  - 创建 %USERPROFILE%\.ai-menu\
  - 下载文件（ai-menu.ps1, cli-registry.json）
  - 添加到用户 PATH
  - 创建 ai-menu.cmd 包装器

### 最终验证
- [ ] 在真实 Linux/macOS 环境测试 bash 版
- [ ] 测试实际 CLI 安装流程
- [ ] 测试登录/登出流程
- [ ] 测试启动 AI 流程
- [ ] 编写 README.md

## 🎯 设计简化

### 已移除（与 cc-switch 功能重复）
- ❌ Profile 管理（新增/编辑/删除/查看）
- ❌ Profile 切换
- ❌ Profile 模板
- ❌ ~/.claude.json 操作
- ❌ profile-templates.json

### 当前主菜单（5 项）
```
1. 环境体检
2. 安装 / 更新 CLI
3. 登录 / 登出
4. 启动 AI
5. 退出
```

## 📊 测试状态

```
PowerShell 单元测试: 10/10 ✅
bash 语法检查: PASS ✅
核心功能: 4/4 完成 ✅
```

## 🚀 架构亮点

- ✅ **零外部依赖**：bash 不用 jq/dialog，PowerShell 不用额外模块
- ✅ **跨平台一致**：菜单文案、功能对等
- ✅ **安全设计**：敏感信息过滤，权限检查
- ✅ **TDD 驱动**：测试先行，持续验证
- ✅ **UTF-8 处理**：PowerShell BOM，bash LF
- ✅ **职责清晰**：ai-menu 管理 CLI，cc-switch 管理 profile

## 📝 下一步

1. 实现安装器（install.sh + install.ps1）
2. 编写 README.md 和使用文档
3. 在真实环境测试
4. 发布 v1.0.0
