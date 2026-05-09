#!/usr/bin/env bash
# ai-menu Linux/macOS 安装器
# 使用方法: curl -fsSL <url>/install.sh | bash

set -euo pipefail

# 配置
INSTALL_DIR="$HOME/.ai-menu"
REPO_BASE="https://raw.githubusercontent.com/lulalulaluobo/ai-menu/main"
FILES_TO_DOWNLOAD=(
    "ai-menu.sh"
    "cli-registry.json"
)

# 颜色
COLOR_RESET='\033[0m'
COLOR_GREEN='\033[32m'
COLOR_YELLOW='\033[33m'
COLOR_CYAN='\033[36m'
COLOR_RED='\033[31m'
COLOR_GRAY='\033[90m'

echo ""
echo -e "${COLOR_CYAN}=== ai-menu 安装器 ===${COLOR_RESET}"
echo ""

# 1. 创建安装目录
echo -e "${COLOR_YELLOW}[1/5] 创建安装目录...${COLOR_RESET}"
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    echo -e "  ${COLOR_GREEN}✓ 已创建: $INSTALL_DIR${COLOR_RESET}"
else
    echo -e "  ${COLOR_GREEN}✓ 目录已存在: $INSTALL_DIR${COLOR_RESET}"
fi

# 2. 下载文件
echo ""
echo -e "${COLOR_YELLOW}[2/5] 下载文件...${COLOR_RESET}"
for file in "${FILES_TO_DOWNLOAD[@]}"; do
    url="$REPO_BASE/$file"
    dest="$INSTALL_DIR/$file"
    
    echo -e "  ${COLOR_GRAY}下载: $file${COLOR_RESET}"
    if curl -fsSL "$url" -o "$dest"; then
        echo -e "  ${COLOR_GREEN}✓ 完成: $file${COLOR_RESET}"
    else
        echo -e "  ${COLOR_RED}✗ 失败: $file${COLOR_RESET}"
        echo ""
        echo -e "${COLOR_YELLOW}提示: 如果是本地开发，请手动复制文件到 $INSTALL_DIR${COLOR_RESET}"
        exit 1
    fi
done

# 3. 设置执行权限
echo ""
echo -e "${COLOR_YELLOW}[3/5] 设置权限...${COLOR_RESET}"
chmod +x "$INSTALL_DIR/ai-menu.sh"
echo -e "  ${COLOR_GREEN}✓ ai-menu.sh 已设为可执行${COLOR_RESET}"

# 4. 创建 symlink
echo ""
echo -e "${COLOR_YELLOW}[4/5] 创建命令链接...${COLOR_RESET}"

# 尝试 /usr/local/bin（需要 sudo）
if [ -w "/usr/local/bin" ]; then
    ln -sf "$INSTALL_DIR/ai-menu.sh" "/usr/local/bin/ai-menu"
    echo -e "  ${COLOR_GREEN}✓ 已创建链接: /usr/local/bin/ai-menu${COLOR_RESET}"
elif sudo -n true 2>/dev/null; then
    sudo ln -sf "$INSTALL_DIR/ai-menu.sh" "/usr/local/bin/ai-menu"
    echo -e "  ${COLOR_GREEN}✓ 已创建链接: /usr/local/bin/ai-menu (sudo)${COLOR_RESET}"
else
    # 备选：~/.local/bin
    LOCAL_BIN="$HOME/.local/bin"
    mkdir -p "$LOCAL_BIN"
    ln -sf "$INSTALL_DIR/ai-menu.sh" "$LOCAL_BIN/ai-menu"
    echo -e "  ${COLOR_GREEN}✓ 已创建链接: $LOCAL_BIN/ai-menu${COLOR_RESET}"
    
    # 检查 PATH
    if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
        echo -e "  ${COLOR_YELLOW}⚠ $LOCAL_BIN 不在 PATH 中${COLOR_RESET}"
        echo ""
        echo -e "${COLOR_CYAN}请将以下内容添加到 ~/.bashrc 或 ~/.zshrc:${COLOR_RESET}"
        echo -e "${COLOR_GRAY}export PATH=\"\$HOME/.local/bin:\$PATH\"${COLOR_RESET}"
        echo ""
    fi
fi

# 5. 验证安装
echo ""
echo -e "${COLOR_YELLOW}[5/5] 验证安装...${COLOR_RESET}"
if [ -f "$INSTALL_DIR/ai-menu.sh" ]; then
    echo -e "  ${COLOR_GREEN}✓ ai-menu.sh 已就绪${COLOR_RESET}"
else
    echo -e "  ${COLOR_RED}✗ ai-menu.sh 未找到${COLOR_RESET}"
fi

if command -v ai-menu &>/dev/null; then
    echo -e "  ${COLOR_GREEN}✓ ai-menu 命令可用${COLOR_RESET}"
else
    echo -e "  ${COLOR_YELLOW}⚠ ai-menu 命令未在 PATH 中${COLOR_RESET}"
fi

# 完成
echo ""
echo -e "${COLOR_GREEN}=== 安装完成！===${COLOR_RESET}"
echo ""
echo -e "${COLOR_CYAN}使用方法:${COLOR_RESET}"
echo -e "  ${COLOR_RESET}输入命令: ${COLOR_GREEN}ai-menu${COLOR_RESET}"
echo ""
echo -e "${COLOR_CYAN}或者直接运行:${COLOR_RESET}"
echo -e "  ${COLOR_GRAY}bash $INSTALL_DIR/ai-menu.sh${COLOR_RESET}"
echo ""
