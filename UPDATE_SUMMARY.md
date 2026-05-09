# ai-menu v1.1.0 更新总结

## 🎉 新功能

### 1. 主菜单底部显示 CLI 状态

主菜单现在会实时显示所有 CLI 的安装状态：

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
  [OK] Codex CLI          ← 已安装
  [OK] Gemini CLI         ← 已安装
  [OK] Claude Code        ← 已安装
  [--] OpenCode           ← 未安装
  [--] DeepSeek TUI       ← 未安装
  [OK] Claude GLM (智谱)  ← 已安装
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**优势**：
- 一目了然：无需进入子菜单即可查看所有 CLI 状态
- 实时更新：每次返回主菜单都会刷新状态
- 颜色区分：已安装（绿色）/ 未安装（灰色）

### 2. 新增 Claude GLM CLI

添加了第 6 个 CLI：**Claude GLM（智谱）**

**特点**：
- 使用智谱 GLM 的 Claude Code 安装脚本
- 安装命令：`npx @z_ai/coding-helper`
- 与官方 Claude Code 使用相同的 `claude` 命令
- 支持登录/登出

**使用场景**：
- 想使用智谱 GLM 模型但喜欢 Claude Code 界面
- 需要在国内网络环境下使用 Claude Code
- 想体验智谱 GLM 的 AI 编程助手

**安装方式**：
1. 进入 ai-menu
2. 选择"安装 / 更新 CLI"
3. 选择"Claude GLM (智谱)"
4. 自动执行 `npx @z_ai/coding-helper`

## 🔧 技术改进

### 主菜单重构
- 从使用 `Select-Menu` 函数改为自定义渲染
- 支持在菜单中嵌入动态内容（CLI 状态）
- 保持箭头键导航和高亮显示

### CLI Registry 扩展
- 支持 6 个 CLI（原 5 个）
- 新增 `description` 字段用于说明
- 兼容 `npx` 安装方式

## 📝 文档更新

- ✅ README.md - 更新特性说明和 CLI 列表
- ✅ CHANGELOG.md - 新增版本历史
- ✅ cli-registry.json - 添加 claude-glm 配置

## 🧪 测试状态

```
PowerShell 单元测试: 10/10 ✅
bash 语法检查: PASS ✅
实际运行测试: PASS ✅
```

## 📦 升级方法

### 已安装用户

```powershell
# Windows
cd d:\code\ai-menu
powershell -ExecutionPolicy Bypass -File install-local.ps1
```

```bash
# Linux/macOS
cd /path/to/ai-menu
bash install.sh
```

### 新用户

按照 README.md 中的安装说明操作。

## 🎯 下一步计划

- [ ] 支持自定义 CLI Registry
- [ ] 添加 CLI 卸载功能
- [ ] 支持多语言（英文）
- [ ] 添加自动更新检查

## 💡 反馈

如有问题或建议，欢迎提交 Issue！
