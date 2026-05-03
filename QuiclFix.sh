#!/bin/bash
################################################################################
# QuickFix - System Fix & Update Tool (Remote Script)
# 
# This is the actual fix/update logic that runs from GitHub
# Update this file to add new fixes or features
################################################################################

# Version (update this when making changes)
VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
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

# Fix functions
fix_autologin() {
    log_step "Fixing Auto-Login"
    
    log_info "Checking LightDM configuration..."
    
    # Backup current config
    sudo cp /etc/lightdm/lightdm.conf.d/50-autologin.conf /etc/lightdm/lightdm.conf.d/50-autologin.conf.bak 2>/dev/null
    
    # Recreate auto-login config
    sudo mkdir -p /etc/lightdm/lightdm.conf.d
    sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf > /dev/null <<EOF
[Seat:*]
autologin-user=$USER
autologin-user-timeout=0
autologin-session=xfce
EOF
    
    # Check PAM config
    if [ ! -f /etc/pam.d/lightdm-autologin ]; then
        log_info "Creating PAM autologin config..."
        sudo tee /etc/pam.d/lightdm-autologin > /dev/null <<EOF
#%PAM-1.0
auth        sufficient  pam_succeed_if.so user ingroup autologin
auth        required    pam_permit.so
account     include     system-local-login
password    include     system-local-login
session     include     system-local-login
EOF
    fi
    
    # Add user to autologin group
    sudo groupadd -r autologin 2>/dev/null || true
    sudo gpasswd -a $USER autologin
    
    log_info "✓ Auto-login fixed"
    log_warn "Please reboot for changes to take effect"
}

fix_zram() {
    log_step "Fixing zram Configuration"
    
    log_info "Checking zram setup..."
    
    if [ ! -f /etc/systemd/zram-generator.conf ]; then
        log_info "Creating zram configuration..."
        sudo tee /etc/systemd/zram-generator.conf > /dev/null <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF
        log_info "✓ zram configured"
        log_warn "Please reboot for changes to take effect"
    else
        log_info "✓ zram already configured"
    fi
}

fix_firewall() {
    log_step "Fixing Firewall"
    
    log_info "Checking UFW status..."
    
    if ! command -v ufw &> /dev/null; then
        log_info "Installing UFW..."
        sudo pacman -S --noconfirm ufw
    fi
    
    log_info "Configuring firewall rules..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw --force enable
    sudo systemctl enable ufw
    
    log_info "✓ Firewall fixed"
}

fix_network() {
    log_step "Fixing Network"
    
    log_info "Restarting NetworkManager..."
    sudo systemctl restart NetworkManager
    
    log_info "Checking DNS..."
    if ! ping -c 1 archlinux.org &> /dev/null; then
        log_warn "Network connectivity issue detected"
        log_info "Trying to fix DNS..."
        echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
        echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf > /dev/null
    fi
    
    log_info "✓ Network checked"
}

update_system() {
    log_step "Updating System"
    
    log_info "Syncing package database..."
    sudo pacman -Sy
    
    log_info "Updating packages..."
    sudo pacman -Syu --noconfirm
    
    log_info "✓ System updated"
}

update_scripts() {
    log_step "Updating Helper Scripts"
    
    GITHUB_USER="ZewK3"
    GITHUB_REPO="Precores-Software"
    GITHUB_BRANCH="main"
    
    log_info "Updating QuickInstall.sh..."
    curl -f -s -o ~/QuickInstall.sh "https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/refs/heads/${GITHUB_BRANCH}/QuickInstall.sh" 2>/dev/null
    if [ $? -eq 0 ]; then
        chmod +x ~/QuickInstall.sh
        log_info "✓ QuickInstall.sh updated"
    else
        log_warn "Failed to update QuickInstall.sh"
    fi
    
    log_info "✓ Scripts updated"
}

clean_system() {
    log_step "Cleaning System"
    
    log_info "Removing orphaned packages..."
    sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || log_info "No orphaned packages"
    
    log_info "Cleaning package cache..."
    sudo pacman -Sc --noconfirm
    
    log_info "Cleaning journal logs..."
    sudo journalctl --vacuum-time=7d
    
    log_info "✓ System cleaned"
}

check_system() {
    log_step "System Health Check"
    
    echo -e "${CYAN}System Information:${NC}"
    echo "  Hostname: $(hostname)"
    echo "  Kernel: $(uname -r)"
    echo "  Uptime: $(uptime -p)"
    echo ""
    
    echo -e "${CYAN}Memory Usage:${NC}"
    free -h
    echo ""
    
    echo -e "${CYAN}Disk Usage:${NC}"
    df -h / | tail -1
    echo ""
    
    echo -e "${CYAN}zram Status:${NC}"
    if command -v zramctl &> /dev/null; then
        zramctl
    else
        echo "  zram not available"
    fi
    echo ""
    
    echo -e "${CYAN}Network Status:${NC}"
    if ping -c 1 archlinux.org &> /dev/null; then
        echo "  ✓ Internet: Connected"
    else
        echo "  ✗ Internet: Disconnected"
    fi
    echo ""
    
    echo -e "${CYAN}Services Status:${NC}"
    systemctl is-active NetworkManager && echo "  ✓ NetworkManager: Active" || echo "  ✗ NetworkManager: Inactive"
    systemctl is-active lightdm && echo "  ✓ LightDM: Active" || echo "  ✗ LightDM: Inactive"
    systemctl is-active ufw && echo "  ✓ UFW: Active" || echo "  ✗ UFW: Inactive"
}

# Display menu
show_menu() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         QuickFix - System Repair Tool v${VERSION}         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Common Fixes:${NC}"
    echo "  1) Fix Auto-Login (LightDM)"
    echo "  2) Fix zram (Compressed RAM)"
    echo "  3) Fix Firewall (UFW)"
    echo "  4) Fix Network Connection"
    echo ""
    echo -e "${YELLOW}System Maintenance:${NC}"
    echo "  5) Update System"
    echo "  6) Update Helper Scripts"
    echo "  7) Clean System (remove orphans, cache)"
    echo "  8) System Health Check"
    echo ""
    echo -e "${YELLOW}Quick Actions:${NC}"
    echo "  9) Fix All Common Issues"
    echo "  10) Full System Maintenance"
    echo ""
    echo "  0) Exit"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
}

# Main function
main() {
    while true; do
        show_menu
        read -p "Enter your choice: " choice
        
        case $choice in
            1) fix_autologin ;;
            2) fix_zram ;;
            3) fix_firewall ;;
            4) fix_network ;;
            5) update_system ;;
            6) update_scripts ;;
            7) clean_system ;;
            8) check_system ;;
            9)
                fix_autologin
                fix_zram
                fix_firewall
                fix_network
                ;;
            10)
                update_system
                update_scripts
                clean_system
                ;;
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

# Run main function
main "$@"
