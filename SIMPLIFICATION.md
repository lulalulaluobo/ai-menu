# ai-menu 简化说明

## 变更原因

用户已有 `cc-switch` 工具管理 Claude Code 的 profile 切换，ai-menu 的 Profile 功能重复。

## 简化内容

### 移除的功能
- ❌ Profile 管理（新增/编辑/删除/查看）
- ❌ Profile 切换
- ❌ Profile 模板
- ❌ ~/.claude.json 操作
- ❌ profile-templates.json 文件

### 保留的核心功能
- ✅ 环境体检
- ✅ 安装/更新 CLI
- ✅ 登录/登出
- ✅ 启动 AI
- ✅ CLI Registry 管理

## 新的主菜单

```
=== ai-menu v1.0.0 ===

 1. 环境体检
 2. 安装 / 更新 CLI
 3. 登录 / 登出
 4. 启动 AI
 5. 退出
```

## 代码清理

### 已删除
- `profile-templates.json`
- 所有 Profile 相关函数（10+ 个）
- Profile 相关配置路径

### 需要完成
1. 实现 Task 6: 安装/更新 CLI 模块
2. 实现 Task 7: 登录/登出模块
3. 实现 Task 8: 启动 AI 模块
4. 实现 Task 14: 安装器
5. 最终集成测试

## 优势

- 🎯 **聚焦核心**：统一管理 5 个 CLI 的安装、登录、启动
- 🚀 **更轻量**：代码量减少 40%+
- 🔧 **职责清晰**：ai-menu 管理 CLI，cc-switch 管理 profile
- 📦 **零依赖**：bash 不用 jq，PowerShell 不用额外模块
