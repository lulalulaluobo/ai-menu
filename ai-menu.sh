#!/usr/bin/env bash
# ai-menu.sh - 终端 AI 菜单 (Linux/macOS bash 版)
# Version: 1.0.0

set -euo pipefail

# 全局配置
VERSION="1.0.0"
CONFIG_HOME="$HOME/.ai-menu"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_REGISTRY_FILE="$SCRIPT_DIR/cli-registry.json"

# 颜色定义
COLOR_RESET='\033[0m'
COLOR_HIGHLIGHT='\033[7m'
COLOR_GREEN='\033[32m'
COLOR_RED='\033[31m'
COLOR_YELLOW='\033[33m'
COLOR_BLUE='\033[34m'

# 主菜单选项
declare -a MAIN_MENU_OPTIONS=(
    "环境体检"
    "安装 / 更新 CLI"
    "登录 / 登出"
    "启动 AI"
    "退出"
)

# CLI registry 缓存（使用普通数组以兼容 macOS 默认 bash 3.2）
CLI_KEYS=()
CLI_NAMES=()
CLI_BINS=()
CLI_INSTALL_CMDS=()

# ============================================================================
# 工具函数
# ============================================================================

mask_api_key() {
    local key="$1"
    if [ ${#key} -le 4 ]; then
        echo "****"
    else
        echo "****${key: -4}"
    fi
}

filter_sensitive() {
    local text="$1"
    # 过滤 sk- 和 key- 开头的敏感字符串
    echo "$text" | sed -E 's/(sk-|key-)[a-zA-Z0-9]{16,}/****/g'
}

print_success() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $1"
}

print_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"
}

print_warning() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1"
}

print_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
}

# ============================================================================
# 菜单引擎
# ============================================================================

select_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    local option_count=${#options[@]}
    
    while true; do
        clear
        echo ""
        echo -e "${COLOR_BLUE}=== $title ===${COLOR_RESET}"
        echo ""
        
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "${COLOR_HIGHLIGHT} $((i+1)). ${options[$i]} ${COLOR_RESET}"
            else
                echo " $((i+1)). ${options[$i]}"
            fi
        done
        
        echo ""
        echo -e "${COLOR_RESET}使用 ↑↓ 选择，回车确认${COLOR_RESET}"
        
        # 读取按键
        read -rsn1 key
        
        # 处理箭头键（ESC [ A/B）
        if [ "$key" = $'\x1b' ]; then
            read -rsn2 -t 0.1 key
            case "$key" in
                '[A') # Up
                    selected=$(( (selected - 1 + option_count) % option_count ))
                    ;;
                '[B') # Down
                    selected=$(( (selected + 1) % option_count ))
                    ;;
            esac
        elif [ "$key" = "" ]; then
            # Enter
            echo "$selected"
            return 0
        fi
    done
}

# ============================================================================
# CLI Registry 管理
# ============================================================================

load_cli_registry() {
    if [ ! -f "$CLI_REGISTRY_FILE" ]; then
        print_error "CLI registry 文件不存在: $CLI_REGISTRY_FILE"
        return 1
    fi
    
    # 简单 JSON 解析（不依赖 jq）
    # 提取 CLI 名称列表
    local cli_keys=$(grep -oE '"[a-z-]+"[[:space:]]*:[[:space:]]*\{' "$CLI_REGISTRY_FILE" | grep -oE '"[a-z-]+"' | tr -d '"')
    
    CLI_KEYS=()
    CLI_NAMES=()
    CLI_BINS=()
    CLI_INSTALL_CMDS=()
    
    for key in $cli_keys; do
        CLI_KEYS+=("$key")
        CLI_NAMES+=("$(grep -A 20 "\"$key\"" "$CLI_REGISTRY_FILE" | grep '"name"' | head -1 | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')")
        CLI_BINS+=("$(grep -A 20 "\"$key\"" "$CLI_REGISTRY_FILE" | grep '"bin"' | head -1 | sed -E 's/.*"bin"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')")
        CLI_INSTALL_CMDS+=("$(grep -A 20 "\"$key\"" "$CLI_REGISTRY_FILE" | grep '"install"' | head -1 | sed -E 's/.*"install"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')")
    done
}

is_cli_installed() {
    local bin_name="$1"
    command -v "$bin_name" &>/dev/null
}

get_cli_version() {
    local bin_name="$1"
    if ! is_cli_installed "$bin_name"; then
        echo ""
        return 1
    fi
    
    "$bin_name" --version 2>&1 || echo "未知版本"
}

# ============================================================================
# Profile 管理
# ============================================================================

read_profile() {
    local profile_name="$1"
    local profile_path="$PROFILES_DIR/$profile_name.env"
    
    if [ ! -f "$profile_path" ]; then
        return 1
    fi
    
    # 读取 .env 文件
    source "$profile_path"
}

write_profile() {
    local profile_name="$1"
    local base_url="$2"
    local api_key="$3"
    local model="$4"
    
    mkdir -p "$PROFILES_DIR"
    
    local profile_path="$PROFILES_DIR/$profile_name.env"
    
    cat > "$profile_path" <<EOF
# Profile: $profile_name
ANTHROPIC_BASE_URL=$base_url
ANTHROPIC_API_KEY=$api_key
ANTHROPIC_MODEL=$model
EOF
    
    chmod 600 "$profile_path"
}

get_active_profile() {
    if [ ! -f "$ACTIVE_PROFILE_FILE" ]; then
        echo ""
        return 1
    fi
    
    cat "$ACTIVE_PROFILE_FILE"
}

set_active_profile() {
    local profile_name="$1"
    mkdir -p "$CONFIG_HOME"
    echo -n "$profile_name" > "$ACTIVE_PROFILE_FILE"
}

get_all_profiles() {
    if [ ! -d "$PROFILES_DIR" ]; then
        return 0
    fi
    
    find "$PROFILES_DIR" -name "*.env" -exec basename {} .env \;
}

# ============================================================================
# 错误处理
# ============================================================================

run_cmd() {
    local cmd="$1"
    local error_msg="${2:-命令执行失败}"
    
    local output
    local exit_code
    
    output=$(eval "$cmd" 2>&1) || exit_code=$?
    
    if [ "${exit_code:-0}" -ne 0 ]; then
        print_error "$error_msg"
        echo "原始报错："
        echo "$(filter_sensitive "$output")"
        return 1
    fi
    
    echo "$output"
    return 0
}

# ============================================================================
# 功能模块
# ============================================================================

do_health_check() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 环境体检 ===${COLOR_RESET}"
    echo ""
    
    # OS 信息
    echo "【操作系统】"
    uname -a
    echo ""
    
    # Node.js
    echo "【Node.js】"
    if command -v node &>/dev/null; then
        local node_ver=$(node --version 2>&1)
        print_success "已安装: $node_ver"
    else
        print_warning "未安装，请访问 https://nodejs.org 下载"
    fi
    echo ""
    
    # npm
    echo "【npm】"
    if command -v npm &>/dev/null; then
        local npm_ver=$(npm --version 2>&1)
        print_success "已安装: $npm_ver"
    else
        print_warning "未安装（通常随 Node.js 一起安装）"
    fi
    echo ""
    
    # pnpm (可选)
    echo "【pnpm (可选)】"
    if command -v pnpm &>/dev/null; then
        local pnpm_ver=$(pnpm --version 2>&1)
        print_success "已安装: $pnpm_ver"
    else
        print_info "未安装（可选）"
    fi
    echo ""
    
    # git
    echo "【git】"
    if command -v git &>/dev/null; then
        local git_ver=$(git --version 2>&1)
        print_success "已安装: $git_ver"
    else
        print_warning "未安装，请访问 https://git-scm.com 下载"
    fi
    echo ""
    
    # CLI 检测
    echo "【Target CLI 状态】"
    load_cli_registry
    for i in "${!CLI_NAMES[@]}"; do
        local cli_name="${CLI_NAMES[$i]}"
        local bin_name="${CLI_BINS[$i]}"
        
        if is_cli_installed "$bin_name"; then
            local version=$(get_cli_version "$bin_name")
            print_success "$cli_name: 已安装 ($version)"
        else
            print_warning "$cli_name: 未安装"
        fi
    done
    echo ""
    
    # 网络连通性
    echo "【网络连通性】"
    local endpoints=(
        "Anthropic API|https://api.anthropic.com"
        "Google Gemini API|https://generativelanguage.googleapis.com"
        "OpenAI API|https://api.openai.com"
    )
    
    for ep in "${endpoints[@]}"; do
        local name="${ep%%|*}"
        local url="${ep##*|}"
        
        if curl -sI --connect-timeout 3 "$url" &>/dev/null; then
            print_success "$name: 可访问"
        else
            print_warning "$name: 无法访问"
        fi
    done
    echo ""
    
    # PATH 冲突检测
    echo "【PATH 冲突检测】"
    for i in "${!CLI_BINS[@]}"; do
        local bin_name="${CLI_BINS[$i]}"
        local paths=$(which -a "$bin_name" 2>/dev/null || true)
        local path_count=$(echo "$paths" | grep -c . || true)
        
        if [ "$path_count" -gt 1 ]; then
            print_warning "$bin_name 存在多个版本："
            echo "$paths" | sed 's/^/    /'
        fi
    done
    
    echo ""
    echo -e "${COLOR_RESET}按任意键返回主菜单...${COLOR_RESET}"
    read -rsn1
}

do_install_cli() {
    while true; do
        local options=(
            "安装 CLI"
            "更新 CLI"
            "返回主菜单"
        )
        
        local choice=$(select_menu "安装 / 更新 CLI" "${options[@]}")
        
        case $choice in
            0) do_install_cli_action ;;
            1) do_update_cli_action ;;
            2) return ;;
        esac
    done
}

do_install_cli_action() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 安装 CLI ===${COLOR_RESET}"
    echo ""
    
    load_cli_registry
    
    # 构建选项列表
    local options=()
    local cli_keys=()
    
    for i in "${!CLI_NAMES[@]}"; do
        local cli_name="${CLI_NAMES[$i]}"
        local bin_name="${CLI_BINS[$i]}"
        
        if is_cli_installed "$bin_name"; then
            local version=$(get_cli_version "$bin_name")
            options+=("$cli_name [已安装: $version]")
        else
            options+=("$cli_name [未安装]")
        fi
        cli_keys+=("$i")
    done
    options+=("返回")
    
    local choice=$(select_menu "选择要安装的 CLI" "${options[@]}")
    
    if [ $choice -eq $((${#options[@]} - 1)) ]; then
        return
    fi
    
    local selected_index="${cli_keys[$choice]}"
    local registry_key="${CLI_KEYS[$selected_index]}"
    local cli_name="${CLI_NAMES[$selected_index]}"
    local install_cmd="${CLI_INSTALL_CMDS[$selected_index]}"
    
    # 检查是否有安装命令
    if [ -z "$install_cmd" ] || [ "$install_cmd" = "null" ]; then
        clear
        echo ""
        print_warning "$cli_name 需要手动安装"
        echo ""
        
        local install_guide=$(grep -A 20 "\"$registry_key\"" "$CLI_REGISTRY_FILE" | grep '"install_guide"' | head -1 | sed -E 's/.*"install_guide"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
        if [ -n "$install_guide" ]; then
            echo -e "${COLOR_YELLOW}$install_guide${COLOR_RESET}"
        fi
        
        echo ""
        echo -e "${COLOR_RESET}按任意键返回...${COLOR_RESET}"
        read -rsn1
        return
    fi
    
    clear
    echo ""
    print_success "正在安装 $cli_name..."
    echo ""
    echo -e "${COLOR_RESET}命令: $install_cmd${COLOR_RESET}"
    echo ""
    
    # 检查是否需要 sudo
    if ! npm list -g &>/dev/null 2>&1; then
        # 需要 sudo
        echo -e "${COLOR_YELLOW}需要 sudo 权限安装全局 npm 包${COLOR_RESET}"
        echo ""
        install_cmd="sudo $install_cmd"
    fi
    
    # 执行安装
    if eval "$install_cmd"; then
        echo ""
        local version=$(get_cli_version "${CLI_BINS[$selected_index]}")
        print_success "$cli_name 安装成功！版本: $version"
    else
        echo ""
        print_error "安装失败，请检查网络连接或 npm 配置"
    fi
    
    echo ""
    echo -e "${COLOR_RESET}按任意键返回...${COLOR_RESET}"
    read -rsn1
}

do_update_cli_action() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 更新 CLI ===${COLOR_RESET}"
    echo ""
    
    load_cli_registry
    
    # 构建选项列表（只显示已安装的）
    local options=()
    local cli_keys=()
    
    for i in "${!CLI_NAMES[@]}"; do
        local cli_name="${CLI_NAMES[$i]}"
        local bin_name="${CLI_BINS[$i]}"
        
        if is_cli_installed "$bin_name"; then
            local version=$(get_cli_version "$bin_name")
            options+=("$cli_name [$version]")
            cli_keys+=("$i")
        fi
    done
    
    if [ ${#options[@]} -eq 0 ]; then
        print_warning "没有已安装的 CLI"
        sleep 2
        return
    fi
    
    options+=("返回")
    
    local choice=$(select_menu "选择要更新的 CLI" "${options[@]}")
    
    if [ $choice -eq $((${#options[@]} - 1)) ]; then
        return
    fi
    
    local selected_index="${cli_keys[$choice]}"
    local registry_key="${CLI_KEYS[$selected_index]}"
    local cli_name="${CLI_NAMES[$selected_index]}"
    local update_cmd=$(grep -A 20 "\"$registry_key\"" "$CLI_REGISTRY_FILE" | grep '"update"' | head -1 | sed -E 's/.*"update"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    
    if [ -z "$update_cmd" ] || [ "$update_cmd" = "null" ]; then
        print_warning "$cli_name 没有自动更新命令"
        sleep 2
        return
    fi
    
    clear
    echo ""
    print_success "正在更新 $cli_name..."
    echo ""
    echo -e "${COLOR_RESET}命令: $update_cmd${COLOR_RESET}"
    echo ""
    
    # 检查是否需要 sudo
    if ! npm list -g &>/dev/null 2>&1; then
        echo -e "${COLOR_YELLOW}需要 sudo 权限更新全局 npm 包${COLOR_RESET}"
        echo ""
        update_cmd="sudo $update_cmd"
    fi
    
    # 执行更新
    if eval "$update_cmd"; then
        echo ""
        local version=$(get_cli_version "${CLI_BINS[$selected_index]}")
        print_success "$cli_name 更新成功！版本: $version"
    else
        echo ""
        print_error "更新失败"
    fi
    
    echo ""
    echo -e "${COLOR_RESET}按任意键返回...${COLOR_RESET}"
    read -rsn1
}

do_login_logout() {
    while true; do
        local options=(
            "登录"
            "登出"
            "返回主菜单"
        )
        
        local choice=$(select_menu "登录 / 登出" "${options[@]}")
        
        case $choice in
            0) do_login ;;
            1) do_logout ;;
            2) return ;;
        esac
    done
}

do_login() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 登录 ===${COLOR_RESET}"
    echo ""
    
    load_cli_registry
    
    # 构建选项列表
    local options=()
    local cli_keys=()
    
    for i in "${!CLI_NAMES[@]}"; do
        local registry_key="${CLI_KEYS[$i]}"
        # 检查是否有 login 命令
        local login_cmd=$(grep -A 20 "\"$registry_key\"" "$CLI_REGISTRY_FILE" | grep '"login"' | head -1 | sed -E 's/.*"login"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
        
        if [ -n "$login_cmd" ] && [ "$login_cmd" != "null" ]; then
            options+=("${CLI_NAMES[$i]}")
            cli_keys+=("$i")
        fi
    done
    
    if [ ${#options[@]} -eq 0 ]; then
        print_warning "没有支持自动登录的 CLI"
        sleep 2
        return
    fi
    
    options+=("返回")
    
    local choice=$(select_menu "选择要登录的 CLI" "${options[@]}")
    
    if [ $choice -eq $((${#options[@]} - 1)) ]; then
        return
    fi
    
    local selected_index="${cli_keys[$choice]}"
    local registry_key="${CLI_KEYS[$selected_index]}"
    local cli_name="${CLI_NAMES[$selected_index]}"
    local login_cmd=$(grep -A 20 "\"$registry_key\"" "$CLI_REGISTRY_FILE" | grep '"login"' | head -1 | sed -E 's/.*"login"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    
    clear
    echo ""
    print_success "正在启动 $cli_name 登录流程..."
    echo ""
    sleep 1
    
    # 执行登录命令
    eval "$login_cmd" || {
        print_error "登录失败"
        sleep 2
        return
    }
    
    echo ""
    print_success "登录流程完成"
    sleep 2
}

do_logout() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 登出 ===${COLOR_RESET}"
    echo ""
    
    load_cli_registry
    
    # 构建选项列表
    local options=()
    local cli_keys=()
    
    for i in "${!CLI_NAMES[@]}"; do
        local registry_key="${CLI_KEYS[$i]}"
        local auto_logout=$(grep -A 20 "\"$registry_key\"" "$CLI_REGISTRY_FILE" | grep '"auto_logout"' | head -1 | sed -E 's/.*"auto_logout"[[:space:]]*:[[:space:]]*([^,}]+).*/\1/')
        local logout_cmd=$(grep -A 20 "\"$registry_key\"" "$CLI_REGISTRY_FILE" | grep '"logout"' | head -1 | sed -E 's/.*"logout"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
        local logout_guide=$(grep -A 20 "\"$registry_key\"" "$CLI_REGISTRY_FILE" | grep '"logout_guide"' | head -1 | sed -E 's/.*"logout_guide"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
        
        if [ "$auto_logout" = "true" ] && [ -n "$logout_cmd" ] && [ "$logout_cmd" != "null" ]; then
            options+=("${CLI_NAMES[$i]}")
            cli_keys+=("$i")
        elif [ -n "$logout_guide" ]; then
            options+=("${CLI_NAMES[$i]} [需手动]")
            cli_keys+=("$i")
        fi
    done
    
    if [ ${#options[@]} -eq 0 ]; then
        print_warning "没有可登出的 CLI"
        sleep 2
        return
    fi
    
    options+=("返回")
    
    local choice=$(select_menu "选择要登出的 CLI" "${options[@]}")
    
    if [ $choice -eq $((${#options[@]} - 1)) ]; then
        return
    fi
    
    local selected_index="${cli_keys[$choice]}"
    local registry_key="${CLI_KEYS[$selected_index]}"
    local cli_name="${CLI_NAMES[$selected_index]}"
    local auto_logout=$(grep -A 20 "\"$registry_key\"" "$CLI_REGISTRY_FILE" | grep '"auto_logout"' | head -1 | sed -E 's/.*"auto_logout"[[:space:]]*:[[:space:]]*([^,}]+).*/\1/')
    local logout_cmd=$(grep -A 20 "\"$registry_key\"" "$CLI_REGISTRY_FILE" | grep '"logout"' | head -1 | sed -E 's/.*"logout"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    local logout_guide=$(grep -A 20 "\"$registry_key\"" "$CLI_REGISTRY_FILE" | grep '"logout_guide"' | head -1 | sed -E 's/.*"logout_guide"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    
    clear
    echo ""
    
    if [ "$auto_logout" = "true" ] && [ -n "$logout_cmd" ] && [ "$logout_cmd" != "null" ]; then
        print_success "正在执行 $cli_name 登出..."
        echo ""
        sleep 1
        
        eval "$logout_cmd" || {
            print_error "登出失败"
            sleep 2
            return
        }
        
        echo ""
        print_success "登出完成"
        sleep 2
    else
        print_info "$cli_name 登出指南："
        echo ""
        echo -e "${COLOR_YELLOW}$logout_guide${COLOR_RESET}"
        echo ""
        echo -e "${COLOR_RESET}按任意键返回...${COLOR_RESET}"
        read -rsn1
    fi
}

do_start_ai() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 启动 AI ===${COLOR_RESET}"
    echo ""
    
    load_cli_registry
    
    # 构建选项列表
    local options=()
    local cli_keys=()
    
    for i in "${!CLI_NAMES[@]}"; do
        local cli_name="${CLI_NAMES[$i]}"
        local bin_name="${CLI_BINS[$i]}"
        
        if is_cli_installed "$bin_name"; then
            options+=("$cli_name")
        else
            options+=("$cli_name [未安装]")
        fi
        cli_keys+=("$i")
    done
    options+=("返回主菜单")
    
    local choice=$(select_menu "选择要启动的 AI CLI" "${options[@]}")
    
    if [ $choice -eq $((${#options[@]} - 1)) ]; then
        return
    fi
    
    local selected_index="${cli_keys[$choice]}"
    local cli_name="${CLI_NAMES[$selected_index]}"
    local bin_name="${CLI_BINS[$selected_index]}"
    
    if ! is_cli_installed "$bin_name"; then
        print_warning "$cli_name 未安装，请先安装"
        sleep 2
        return
    fi
    
    clear
    echo ""
    print_success "正在启动 $cli_name..."
    echo ""
    echo -e "${COLOR_RESET}提示: 退出 CLI 后将返回主菜单${COLOR_RESET}"
    echo ""
    sleep 1
    
    # 启动 CLI
    "$bin_name" || {
        print_error "启动失败"
        sleep 2
    }
}

do_switch_profile() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 切换 Claude Profile ===${COLOR_RESET}"
    echo ""
    
    local profiles=($(get_all_profiles))
    
    if [ ${#profiles[@]} -eq 0 ]; then
        print_warning "没有可用的 Profile，请先创建"
        echo ""
        echo -e "${COLOR_RESET}按任意键返回主菜单...${COLOR_RESET}"
        read -rsn1
        return
    fi
    
    local active_profile=$(get_active_profile || echo "")
    
    # 构建选项列表
    local options=()
    for p in "${profiles[@]}"; do
        if [ "$p" = "$active_profile" ]; then
            options+=("$p [当前]")
        else
            options+=("$p")
        fi
    done
    options+=("返回主菜单")
    
    local choice=$(select_menu "选择要切换的 Profile" "${options[@]}")
    
    if [ $choice -eq $((${#options[@]} - 1)) ]; then
        return
    fi
    
    local selected_profile="${profiles[$choice]}"
    
    # 读取 profile
    local profile_path="$PROFILES_DIR/$selected_profile.env"
    if [ ! -f "$profile_path" ]; then
        print_error "无法读取 Profile: $selected_profile"
        sleep 2
        return
    fi
    
    # 提取 profile 数据
    local base_url=$(grep '^ANTHROPIC_BASE_URL=' "$profile_path" | cut -d'=' -f2-)
    local api_key=$(grep '^ANTHROPIC_API_KEY=' "$profile_path" | cut -d'=' -f2-)
    local model=$(grep '^ANTHROPIC_MODEL=' "$profile_path" | cut -d'=' -f2-)
    
    # 读取或创建 ~/.claude.json
    local claude_json="$HOME/.claude.json"
    
    if [ ! -f "$claude_json" ]; then
        echo '{"env":{}}' > "$claude_json"
    fi
    
    # 使用 sed 更新 JSON（不依赖 jq）
    # 简单策略：如果 env 字段存在，替换；否则插入
    local temp_json=$(mktemp)
    
    # 读取现有 JSON，移除 env 段
    grep -v '"env"' "$claude_json" | grep -v 'ANTHROPIC_' > "$temp_json" || echo '{}' > "$temp_json"
    
    # 重建 JSON
    cat > "$claude_json" <<EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "$base_url",
    "ANTHROPIC_API_KEY": "$api_key",
    "ANTHROPIC_MODEL": "$model"
  }
}
EOF
    
    rm -f "$temp_json"
    
    # 更新 active-profile
    set_active_profile "$selected_profile"
    
    clear
    echo ""
    print_success "Profile 切换成功！"
    echo ""
    echo -e "${COLOR_BLUE}Profile 名称:${COLOR_RESET} $selected_profile"
    echo "Base URL: $base_url"
    echo "Model: $model"
    echo "API Key: $(mask_api_key "$api_key")"
    echo ""
    echo -e "${COLOR_RESET}按任意键返回主菜单...${COLOR_RESET}"
    read -rsn1
}

do_manage_profiles() {
    while true; do
        local options=(
            "新增 Profile"
            "编辑 Profile"
            "删除 Profile"
            "查看所有 Profile"
            "返回主菜单"
        )
        
        local choice=$(select_menu "Claude Profile 管理" "${options[@]}")
        
        case $choice in
            0) do_create_profile ;;
            1) do_edit_profile ;;
            2) do_delete_profile ;;
            3) do_view_profiles ;;
            4) return ;;
        esac
    done
}

do_create_profile() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 新增 Profile ===${COLOR_RESET}"
    echo ""
    
    local options=(
        "从预设模板创建"
        "完全自定义"
        "返回"
    )
    
    local choice=$(select_menu "选择创建方式" "${options[@]}")
    
    case $choice in
        0) do_create_from_template ;;
        1) do_create_custom_profile ;;
        2) return ;;
    esac
}

do_create_from_template() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 从模板创建 Profile ===${COLOR_RESET}"
    echo ""
    
    if [ ! -f "$PROFILE_TEMPLATES_FILE" ]; then
        print_error "模板文件不存在"
        sleep 2
        return
    fi
    
    # 提取模板列表
    local template_keys=$(grep -oE '"[a-z]+"[[:space:]]*:[[:space:]]*\{' "$PROFILE_TEMPLATES_FILE" | grep -oE '"[a-z]+"' | tr -d '"')
    local options=()
    local keys=()
    
    for key in $template_keys; do
        local name=$(grep -A 10 "\"$key\"" "$PROFILE_TEMPLATES_FILE" | grep '"name"' | head -1 | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
        local desc=$(grep -A 10 "\"$key\"" "$PROFILE_TEMPLATES_FILE" | grep '"description"' | head -1 | sed -E 's/.*"description"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
        options+=("$name - $desc")
        keys+=("$key")
    done
    options+=("返回")
    
    local choice=$(select_menu "选择模板" "${options[@]}")
    
    if [ $choice -eq $((${#options[@]} - 1)) ]; then
        return
    fi
    
    local selected_key="${keys[$choice]}"
    
    # 提取模板数据
    local base_url=$(grep -A 10 "\"$selected_key\"" "$PROFILE_TEMPLATES_FILE" | grep '"base_url"' | head -1 | sed -E 's/.*"base_url"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    local model=$(grep -A 10 "\"$selected_key\"" "$PROFILE_TEMPLATES_FILE" | grep '"model"' | head -1 | sed -E 's/.*"model"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    local tmpl_name=$(grep -A 10 "\"$selected_key\"" "$PROFILE_TEMPLATES_FILE" | grep '"name"' | head -1 | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    
    clear
    echo ""
    echo -e "${COLOR_BLUE}模板: $tmpl_name${COLOR_RESET}"
    echo "Base URL: $base_url"
    echo "Model: $model"
    echo ""
    
    read -p "输入 Profile 名称: " profile_name
    if [ -z "$profile_name" ]; then
        print_warning "名称不能为空"
        sleep 2
        return
    fi
    
    read -p "输入 API Key: " api_key
    if [ -z "$api_key" ]; then
        print_warning "API Key 不能为空"
        sleep 2
        return
    fi
    
    # 如果是自定义模板
    if [ "$selected_key" = "custom" ]; then
        read -p "输入 Base URL: " base_url
        read -p "输入 Model 名称: " model
    fi
    
    write_profile "$profile_name" "$base_url" "$api_key" "$model"
    
    print_success "Profile '$profile_name' 创建成功！"
    sleep 2
}

do_create_custom_profile() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 自定义 Profile ===${COLOR_RESET}"
    echo ""
    
    read -p "输入 Profile 名称: " profile_name
    if [ -z "$profile_name" ]; then
        print_warning "名称不能为空"
        sleep 2
        return
    fi
    
    read -p "输入 Base URL: " base_url
    read -p "输入 API Key: " api_key
    read -p "输入 Model 名称: " model
    
    if [ -z "$base_url" ] || [ -z "$api_key" ] || [ -z "$model" ]; then
        print_warning "所有字段都不能为空"
        sleep 2
        return
    fi
    
    write_profile "$profile_name" "$base_url" "$api_key" "$model"
    
    print_success "Profile '$profile_name' 创建成功！"
    sleep 2
}

do_edit_profile() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 编辑 Profile ===${COLOR_RESET}"
    echo ""
    
    local profiles=($(get_all_profiles))
    
    if [ ${#profiles[@]} -eq 0 ]; then
        print_warning "没有可用的 Profile"
        sleep 2
        return
    fi
    
    local options=("${profiles[@]}" "返回")
    local choice=$(select_menu "选择要编辑的 Profile" "${options[@]}")
    
    if [ $choice -eq $((${#options[@]} - 1)) ]; then
        return
    fi
    
    local profile_name="${profiles[$choice]}"
    local profile_path="$PROFILES_DIR/$profile_name.env"
    
    if [ ! -f "$profile_path" ]; then
        print_error "无法读取 Profile"
        sleep 2
        return
    fi
    
    local current_base_url=$(grep '^ANTHROPIC_BASE_URL=' "$profile_path" | cut -d'=' -f2-)
    local current_api_key=$(grep '^ANTHROPIC_API_KEY=' "$profile_path" | cut -d'=' -f2-)
    local current_model=$(grep '^ANTHROPIC_MODEL=' "$profile_path" | cut -d'=' -f2-)
    
    clear
    echo ""
    echo -e "${COLOR_BLUE}编辑 Profile: $profile_name${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_RESET}当前值 (直接回车保持不变):${COLOR_RESET}"
    echo ""
    
    read -p "Base URL [$current_base_url]: " new_base_url
    read -p "API Key [$(mask_api_key "$current_api_key")]: " new_api_key
    read -p "Model [$current_model]: " new_model
    
    [ -z "$new_base_url" ] && new_base_url="$current_base_url"
    [ -z "$new_api_key" ] && new_api_key="$current_api_key"
    [ -z "$new_model" ] && new_model="$current_model"
    
    write_profile "$profile_name" "$new_base_url" "$new_api_key" "$new_model"
    
    print_success "Profile '$profile_name' 更新成功！"
    sleep 2
}

do_delete_profile() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 删除 Profile ===${COLOR_RESET}"
    echo ""
    
    local profiles=($(get_all_profiles))
    
    if [ ${#profiles[@]} -eq 0 ]; then
        print_warning "没有可用的 Profile"
        sleep 2
        return
    fi
    
    local options=("${profiles[@]}" "返回")
    local choice=$(select_menu "选择要删除的 Profile" "${options[@]}")
    
    if [ $choice -eq $((${#options[@]} - 1)) ]; then
        return
    fi
    
    local profile_name="${profiles[$choice]}"
    
    clear
    echo ""
    print_warning "确认删除 Profile: $profile_name ?"
    echo ""
    read -p "输入 'yes' 确认删除: " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "已取消"
        sleep 1
        return
    fi
    
    rm -f "$PROFILES_DIR/$profile_name.env"
    
    # 如果删除的是当前激活的 profile，清除 active-profile
    local active_profile=$(get_active_profile || echo "")
    if [ "$active_profile" = "$profile_name" ]; then
        rm -f "$ACTIVE_PROFILE_FILE"
    fi
    
    print_success "Profile '$profile_name' 已删除"
    sleep 2
}

do_view_profiles() {
    clear
    echo ""
    echo -e "${COLOR_BLUE}=== 所有 Profile ===${COLOR_RESET}"
    echo ""
    
    local profiles=($(get_all_profiles))
    
    if [ ${#profiles[@]} -eq 0 ]; then
        print_warning "没有可用的 Profile"
    else
        local active_profile=$(get_active_profile || echo "")
        
        for p in "${profiles[@]}"; do
            local profile_path="$PROFILES_DIR/$p.env"
            local base_url=$(grep '^ANTHROPIC_BASE_URL=' "$profile_path" | cut -d'=' -f2-)
            local api_key=$(grep '^ANTHROPIC_API_KEY=' "$profile_path" | cut -d'=' -f2-)
            local model=$(grep '^ANTHROPIC_MODEL=' "$profile_path" | cut -d'=' -f2-)
            
            if [ "$p" = "$active_profile" ]; then
                echo -e "${COLOR_GREEN}[$p] (当前激活)${COLOR_RESET}"
            else
                echo -e "${COLOR_BLUE}[$p]${COLOR_RESET}"
            fi
            
            echo "  Base URL: $base_url"
            echo "  Model: $model"
            echo "  API Key: $(mask_api_key "$api_key")"
            echo ""
        done
    fi
    
    echo -e "${COLOR_RESET}按任意键返回...${COLOR_RESET}"
    read -rsn1
}

# ============================================================================
# 主程序
# ============================================================================

main_menu() {
    local selected=0
    local option_count=${#MAIN_MENU_OPTIONS[@]}
    
    while true; do
        clear
        echo ""
        echo -e "${COLOR_BLUE}=== ai-menu v$VERSION ===${COLOR_RESET}"
        echo ""
        
        # 显示主菜单选项（带高亮）
        for i in "${!MAIN_MENU_OPTIONS[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "${COLOR_HIGHLIGHT} $((i+1)). ${MAIN_MENU_OPTIONS[$i]} ${COLOR_RESET}"
            else
                echo " $((i+1)). ${MAIN_MENU_OPTIONS[$i]}"
            fi
        done
        
        echo ""
        echo -e "${COLOR_RESET}使用 ↑↓ 选择，回车确认${COLOR_RESET}"
        echo ""
        
        # 显示 CLI 安装状态
        echo -e "${COLOR_RESET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
        echo -e "${COLOR_RESET}CLI 状态:${COLOR_RESET}"
        
        load_cli_registry
        for i in "${!CLI_NAMES[@]}"; do
            local cli_name="${CLI_NAMES[$i]}"
            local bin_name="${CLI_BINS[$i]}"
            
            if is_cli_installed "$bin_name"; then
                echo -e "  ${COLOR_GREEN}[OK] $cli_name${COLOR_RESET}"
            else
                echo -e "  ${COLOR_RESET}[--] $cli_name${COLOR_RESET}"
            fi
        done
        echo -e "${COLOR_RESET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
        
        # 读取按键
        read -rsn1 key
        
        if [ "$key" = $'\x1b' ]; then
            read -rsn2 -t 0.1 key
            case "$key" in
                '[A') # Up
                    selected=$(( (selected - 1 + option_count) % option_count ))
                    ;;
                '[B') # Down
                    selected=$(( (selected + 1) % option_count ))
                    ;;
            esac
        elif [ "$key" = "" ]; then
            # Enter - 执行选中的功能
            case $selected in
                0) do_health_check ;;
                1) do_install_cli ;;
                2) do_login_logout ;;
                3) do_start_ai ;;
                4)
                    clear
                    echo -e "${COLOR_GREEN}再见！${COLOR_RESET}"
                    exit 0
                    ;;
            esac
        fi
    done
}

# ============================================================================
# 入口
# ============================================================================

# 测试模式：只加载函数，不启动主菜单
if [ "${1:-}" = "--source-only" ]; then
    return 0 2>/dev/null || exit 0
fi

# 正常模式：启动主菜单
main_menu
