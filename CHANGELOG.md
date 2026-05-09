# Changelog

## [1.1.0] - 2026-05-09

### Added
- ✨ **主菜单底部显示 CLI 状态**：实时显示所有 CLI 的安装状态（[OK] 已安装 / [--] 未安装）
- ✨ **新增 Claude GLM CLI**：智谱 GLM 的 Claude Code 安装脚本
  - 安装命令：`npx @z_ai/coding-helper`
  - 支持登录/登出
  - 与官方 Claude Code 使用相同的 `claude` 命令

### Changed
- 🎨 主菜单改为自定义渲染，支持实时状态显示
- 📝 更新文档，反映 6 个 CLI 的支持

### Technical
- CLI Registry 现在支持 6 个 CLI
- 主菜单循环逻辑优化，减少重复渲染

---

## [1.0.0] - 2026-05-09

### Added
- 🎉 首次发布
- ✅ 核心功能：环境体检、安装/更新、登录/登出、启动 AI
- ✅ 跨平台支持：bash（Linux/macOS）+ PowerShell（Windows）
- ✅ 零依赖架构
- ✅ 完整测试覆盖
- ✅ 安装器（在线 + 本地）

### Supported CLIs
- Codex CLI
- Gemini CLI
- Claude Code
- OpenCode
- DeepSeek TUI
