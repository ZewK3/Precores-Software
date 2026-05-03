#!/bin/bash
################################################################################
# SystemManager - Unified System Management Tool
# 
# Combines system monitoring, updates, and management in one tool
################################################################################

VERSION="1.0.0"

# GitHub Configuration
GITHUB_USER="ZewK3"
GITHUB_REPO="Precores-Software"
GITHUB_BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/refs/heads/${GITHUB_BRANCH}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Config
CONFIG_DIR="$HOME/.precores"
BACKUP_DIR="$CONFIG_DIR/backups"
LOG_DIR="$CONFIG_DIR/logs"
REFRESH_INTERVAL=2

# Logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Initialize
init_config() {
    mkdir -p "$CONFIG_DIR" "$BACKUP_DIR" "$LOG_DIR"
}

# Check internet
check_internet() {
    if ! ping -c 1 github.com &> /dev/null; then
        return 1
    fi
    return 0
}

################################################################################
# MONITORING FUNCTIONS
################################################################################

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'
}

get_ram_usage() {
    free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'
}

get_ram_info() {
    free -h | grep Mem | awk '{print $3 "/" $2}'
}

get_zram_info() {
    if command -v zramctl &> /dev/null; then
        zramctl --output NAME,DISKSIZE,DATA,COMPR,TOTAL --raw --noheadings 2>/dev/null | head -1
    else
        echo "N/A"
    fi
}

get_disk_usage() {
    df -h / | tail -1 | awk '{print $5}' | sed 's/%//'
}

get_disk_info() {
    df -h / | tail -1 | awk '{print $3 "/" $2}'
}

get_network_rx() {
    cat /sys/class/net/$(ip route | grep default | awk '{print $5}' | head -1)/statistics/rx_bytes 2>/dev/null || echo 0
}

get_network_tx() {
    cat /sys/class/net/$(ip route | grep default | awk '{print $5}' | head -1)/statistics/tx_bytes 2>/dev/null || echo 0
}

format_bytes() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(($bytes / 1024))KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$(($bytes / 1048576))MB"
    else
        echo "$(($bytes / 1073741824))GB"
    fi
}

get_top_processes() {
    ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "  %-20s %5s%%  %5s%%\n", substr($11,1,20), $3, $4}'
}

get_uptime() {
    uptime -p | sed 's/up //'
}

get_load_avg() {
    uptime | awk -F'load average:' '{print $2}' | xargs
}

draw_bar() {
    local percent=$1
    local width=30
    local filled=$(printf "%.0f" $(echo "$percent * $width / 100" | bc -l))
    local empty=$((width - filled))
    
    local color=$GREEN
    if (( $(echo "$percent > 80" | bc -l) )); then
        color=$RED
    elif (( $(echo "$percent > 60" | bc -l) )); then
        color=$YELLOW
    fi
    
    printf "${color}"
    printf '█%.0s' $(seq 1 $filled)
    printf "${NC}"
    printf '░%.0s' $(seq 1 $empty)
    printf " %5.1f%%" $percent
}

show_dashboard() {
    clear
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       System Dashboard - $(date '+%Y-%m-%d %H:%M:%S')              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BLUE}┌─ System Information${NC}"
    echo -e "${BLUE}│${NC}  Hostname: $(hostname)"
    echo -e "${BLUE}│${NC}  Kernel:   $(uname -r)"
    echo -e "${BLUE}│${NC}  Uptime:   $(get_uptime)"
    echo -e "${BLUE}│${NC}  Load Avg: $(get_load_avg)"
    echo -e "${BLUE}└${NC}"
    echo ""
    
    local cpu_usage=$(get_cpu_usage)
    echo -e "${MAGENTA}┌─ CPU Usage${NC}"
    echo -e "${MAGENTA}│${NC}  $(draw_bar $cpu_usage)"
    echo -e "${MAGENTA}└${NC}"
    echo ""
    
    local ram_usage=$(get_ram_usage)
    local ram_info=$(get_ram_info)
    echo -e "${GREEN}┌─ Memory Usage${NC}"
    echo -e "${GREEN}│${NC}  RAM:  $(draw_bar $ram_usage)  ($ram_info)"
    
    local zram_info=$(get_zram_info)
    if [ "$zram_info" != "N/A" ]; then
        echo -e "${GREEN}│${NC}  zram: $zram_info"
    fi
    echo -e "${GREEN}└${NC}"
    echo ""
    
    local disk_usage=$(get_disk_usage)
    local disk_info=$(get_disk_info)
    echo -e "${YELLOW}┌─ Disk Usage${NC}"
    echo -e "${YELLOW}│${NC}  Root: $(draw_bar $disk_usage)  ($disk_info)"
    echo -e "${YELLOW}└${NC}"
    echo ""
    
    local rx_bytes=$(get_network_rx)
    local tx_bytes=$(get_network_tx)
    echo -e "${CYAN}┌─ Network Traffic${NC}"
    echo -e "${CYAN}│${NC}  RX: $(format_bytes $rx_bytes)"
    echo -e "${CYAN}│${NC}  TX: $(format_bytes $tx_bytes)"
    echo -e "${CYAN}└${NC}"
    echo ""
    
    echo -e "${RED}┌─ Top Processes (CPU)${NC}"
    echo -e "${RED}│${NC}  Process              CPU    RAM"
    echo -e "${RED}│${NC}  ────────────────────────────────"
    get_top_processes
    echo -e "${RED}└${NC}"
    echo ""
    
    echo -e "${CYAN}Press Ctrl+C to exit | Refresh: ${REFRESH_INTERVAL}s${NC}"
}

monitor_system() {
    # Check if bc is installed
    if ! command -v bc &> /dev/null; then
        log_info "Installing bc (required for calculations)..."
        sudo pacman -S --noconfirm bc
    fi
    
    trap 'return' INT
    
    while true; do
        show_dashboard
        sleep $REFRESH_INTERVAL
    done
}

################################################################################
# UPDATE FUNCTIONS
################################################################################

get_remote_version() {
    local script=$1
    curl -s "${BASE_URL}/${script}" | grep -oP '(?<=VERSION=")[^"]+' | head -1
}

get_local_version() {
    local script=$1
    if [ -f "$HOME/$script" ]; then
        grep -oP '(?<=VERSION=")[^"]+' "$HOME/$script" | head -1
    else
        echo "not installed"
    fi
}

update_script() {
    local script=$1
    local display_name=$2
    
    log_info "Checking $display_name..."
    
    local remote_version=$(get_remote_version "$script")
    local local_version=$(get_local_version "$script")
    
    if [ "$local_version" == "not installed" ]; then
        log_warn "$display_name not found, installing..."
    elif [ "$remote_version" == "$local_version" ]; then
        log_info "✓ $display_name is up to date (v$local_version)"
        return 0
    else
        log_info "Update available: v$local_version → v$remote_version"
    fi
    
    if [ -f "$HOME/$script" ]; then
        cp "$HOME/$script" "$BACKUP_DIR/${script}.bak"
    fi
    
    if curl -f -s -o "$HOME/$script" "${BASE_URL}/${script}"; then
        chmod +x "$HOME/$script"
        log_info "✓ $display_name updated to v$remote_version"
        return 0
    else
        log_error "Failed to update $display_name"
        if [ -f "$BACKUP_DIR/${script}.bak" ]; then
            mv "$BACKUP_DIR/${script}.bak" "$HOME/$script"
            log_info "Restored from backup"
        fi
        return 1
    fi
}

update_all_scripts() {
    log_step "Updating All Scripts"
    
    if ! check_internet; then
        log_error "No internet connection"
        return 1
    fi
    
    update_script "QuickInstall.sh" "QuickInstall"
    update_script "QuiclFix.sh" "QuickFix (remote)"
    update_script "SystemManager.sh" "SystemManager"
    
    log_info "✓ All scripts checked"
}

update_system() {
    log_step "Updating System"
    
    log_info "Syncing package database..."
    sudo pacman -Sy
    
    log_info "Updating packages..."
    sudo pacman -Syu --noconfirm
    
    log_info "✓ System updated"
}

update_aur() {
    log_step "Updating AUR Packages"
    
    if ! command -v yay &> /dev/null; then
        log_warn "yay not installed, skipping AUR update"
        return 0
    fi
    
    log_info "Updating AUR packages..."
    yay -Syu --noconfirm
    
    log_info "✓ AUR packages updated"
}

check_updates() {
    log_step "Checking for Updates"
    
    if ! check_internet; then
        log_error "No internet connection"
        return 1
    fi
    
    local updates_available=0
    
    local scripts=("QuickInstall.sh" "QuiclFix.sh" "SystemManager.sh")
    for script in "${scripts[@]}"; do
        local remote=$(get_remote_version "$script")
        local local=$(get_local_version "$script")
        
        if [ "$local" != "not installed" ] && [ "$remote" != "$local" ]; then
            echo -e "${YELLOW}  • $script: v$local → v$remote${NC}"
            updates_available=1
        fi
    done
    
    if [ $updates_available -eq 0 ]; then
        log_info "✓ All scripts are up to date"
    else
        echo ""
        log_info "Updates available! Run option 2 to update"
    fi
}

show_versions() {
    log_step "Installed Versions"
    
    echo -e "${CYAN}Scripts:${NC}"
    echo "  QuickInstall:   v$(get_local_version 'QuickInstall.sh')"
    echo "  QuickFix:       v$(get_local_version 'QuiclFix.sh')"
    echo "  SystemManager:  v$(get_local_version 'SystemManager.sh')"
    echo ""
    
    echo -e "${CYAN}System:${NC}"
    echo "  Kernel: $(uname -r)"
    echo "  Pacman: $(pacman --version | head -1 | awk '{print $3}')"
    if command -v yay &> /dev/null; then
        echo "  yay:    $(yay --version | head -1 | awk '{print $2}')"
    fi
}

rollback_script() {
    local script=$1
    
    if [ -f "$BACKUP_DIR/${script}.bak" ]; then
        log_info "Rolling back $script..."
        cp "$BACKUP_DIR/${script}.bak" "$HOME/$script"
        chmod +x "$HOME/$script"
        log_info "✓ Rollback complete"
    else
        log_error "No backup found for $script"
    fi
}

clean_backups() {
    log_step "Cleaning Backups"
    
    local count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
    
    if [ $count -eq 0 ]; then
        log_info "No backups to clean"
        return
    fi
    
    log_info "Found $count backup(s)"
    read -p "Delete all backups? (y/n): " confirm
    
    if [ "$confirm" == "y" ]; then
        rm -f "$BACKUP_DIR"/*
        log_info "✓ Backups cleaned"
    else
        log_info "Cancelled"
    fi
}

################################################################################
# MENU
################################################################################

show_menu() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         SystemManager v${VERSION}                          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Monitoring:${NC}"
    echo "  1) System Dashboard (Real-time)"
    echo ""
    echo -e "${YELLOW}Updates:${NC}"
    echo "  2) Update All Scripts"
    echo "  3) Update System (pacman)"
    echo "  4) Update AUR Packages (yay)"
    echo "  5) Update Everything"
    echo ""
    echo -e "${YELLOW}Information:${NC}"
    echo "  6) Check for Updates"
    echo "  7) Show Installed Versions"
    echo ""
    echo -e "${YELLOW}Maintenance:${NC}"
    echo "  8) Rollback Script"
    echo "  9) Clean Backups"
    echo ""
    echo "  0) Exit"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
}

################################################################################
# MAIN
################################################################################

main() {
    init_config
    
    while true; do
        show_menu
        read -p "Enter your choice: " choice
        
        case $choice in
            1) monitor_system ;;
            2) update_all_scripts ;;
            3) update_system ;;
            4) update_aur ;;
            5)
                update_all_scripts
                update_system
                update_aur
                ;;
            6) check_updates ;;
            7) show_versions ;;
            8)
                read -p "Enter script name to rollback: " script
                rollback_script "$script"
                ;;
            9) clean_backups ;;
            0)
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option: $choice"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run
main "$@"
