#!/bin/bash
################################################################################
# QuickInstall - Fast Application Installer
# 
# This script allows you to quickly install popular applications
# with a simple menu interface
################################################################################

# GitHub Configuration
GITHUB_USER="ZewK3"
GITHUB_REPO="Precores-Software"
GITHUB_BRANCH="main"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should NOT be run as root"
        log_info "Run as normal user: ./QuickInstall.sh"
        exit 1
    fi
}

# Check internet connection
check_internet() {
    log_info "Checking internet connection..."
    if ping -c 1 archlinux.org &> /dev/null; then
        log_info "✓ Internet connection OK"
        return 0
    else
        log_error "No internet connection"
        return 1
    fi
}

# Install yay if not present
install_yay() {
    if command -v yay &> /dev/null; then
        log_info "✓ yay already installed"
        return 0
    fi
    
    log_step "Installing yay (AUR Helper)"
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
    log_info "✓ yay installed"
}

# Application installation functions
install_docker() {
    log_step "Installing Docker"
    sudo pacman -S --noconfirm docker docker-compose
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    log_info "✓ Docker installed"
    log_warn "Please logout and login again to use Docker without sudo"
}

install_vscode() {
    log_step "Installing Visual Studio Code"
    yay -S --noconfirm visual-studio-code-bin
    log_info "✓ VS Code installed"
}

install_chrome() {
    log_step "Installing Google Chrome"
    yay -S --noconfirm google-chrome
    log_info "✓ Google Chrome installed"
}

install_brave() {
    log_step "Installing Brave Browser"
    yay -S --noconfirm brave-bin
    log_info "✓ Brave Browser installed"
}

install_discord() {
    log_step "Installing Discord"
    sudo pacman -S --noconfirm discord
    log_info "✓ Discord installed"
}

install_telegram() {
    log_step "Installing Telegram"
    sudo pacman -S --noconfirm telegram-desktop
    log_info "✓ Telegram installed"
}

install_vlc() {
    log_step "Installing VLC Media Player"
    sudo pacman -S --noconfirm vlc
    log_info "✓ VLC installed"
}

install_gimp() {
    log_step "Installing GIMP"
    sudo pacman -S --noconfirm gimp
    log_info "✓ GIMP installed"
}

install_libreoffice() {
    log_step "Installing LibreOffice"
    sudo pacman -S --noconfirm libreoffice-fresh
    log_info "✓ LibreOffice installed"
}

install_git_tools() {
    log_step "Installing Git Tools"
    sudo pacman -S --noconfirm git github-cli
    log_info "✓ Git tools installed"
}

install_nodejs_tools() {
    log_step "Installing Node.js Development Tools"
    sudo pacman -S --noconfirm nodejs npm yarn
    log_info "✓ Node.js tools installed"
}

install_python_tools() {
    log_step "Installing Python Development Tools"
    sudo pacman -S --noconfirm python python-pip python-virtualenv
    log_info "✓ Python tools installed"
}

install_rust() {
    log_step "Installing Rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    log_info "✓ Rust installed"
}

install_go() {
    log_step "Installing Go"
    sudo pacman -S --noconfirm go
    log_info "✓ Go installed"
}

install_postman() {
    log_step "Installing Postman"
    yay -S --noconfirm postman-bin
    log_info "✓ Postman installed"
}

install_dbeaver() {
    log_step "Installing DBeaver (Database Tool)"
    yay -S --noconfirm dbeaver
    log_info "✓ DBeaver installed"
}

install_obs() {
    log_step "Installing OBS Studio"
    sudo pacman -S --noconfirm obs-studio
    log_info "✓ OBS Studio installed"
}

install_spotify() {
    log_step "Installing Spotify"
    yay -S --noconfirm spotify
    log_info "✓ Spotify installed"
}

install_steam() {
    log_step "Installing Steam"
    sudo pacman -S --noconfirm steam
    log_info "✓ Steam installed"
}

install_wine() {
    log_step "Installing Wine (Windows Compatibility)"
    sudo pacman -S --noconfirm wine wine-mono wine-gecko winetricks
    log_info "✓ Wine installed"
}

update_system() {
    log_step "Updating System"
    sudo pacman -Syu --noconfirm
    log_info "✓ System updated"
}

# Display menu
show_menu() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         QuickInstall - Fast App Installer             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Development Tools:${NC}"
    echo "  1)  Docker & Docker Compose"
    echo "  2)  Visual Studio Code"
    echo "  3)  Git Tools (git + GitHub CLI)"
    echo "  4)  Node.js Tools (nodejs + npm + yarn)"
    echo "  5)  Python Tools (python + pip + virtualenv)"
    echo "  6)  Rust Programming Language"
    echo "  7)  Go Programming Language"
    echo "  8)  Postman (API Testing)"
    echo "  9)  DBeaver (Database Tool)"
    echo ""
    echo -e "${YELLOW}Browsers:${NC}"
    echo "  10) Google Chrome"
    echo "  11) Brave Browser"
    echo ""
    echo -e "${YELLOW}Communication:${NC}"
    echo "  12) Discord"
    echo "  13) Telegram"
    echo ""
    echo -e "${YELLOW}Multimedia:${NC}"
    echo "  14) VLC Media Player"
    echo "  15) OBS Studio (Streaming/Recording)"
    echo "  16) Spotify"
    echo ""
    echo -e "${YELLOW}Graphics & Office:${NC}"
    echo "  17) GIMP (Image Editor)"
    echo "  18) LibreOffice"
    echo ""
    echo -e "${YELLOW}Gaming:${NC}"
    echo "  19) Steam"
    echo "  20) Wine (Windows Compatibility)"
    echo ""
    echo -e "${YELLOW}System:${NC}"
    echo "  21) Update System"
    echo "  22) Install ALL Development Tools"
    echo "  23) Install ALL Applications"
    echo ""
    echo "  0)  Exit"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
}

# Multi-select menu
show_multi_select() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Select Multiple Applications                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Enter numbers separated by spaces (e.g., 1 2 3 10)"
    echo "Or press Enter to go back"
    echo ""
}

# Main installation handler
handle_choice() {
    case $1 in
        1) install_docker ;;
        2) install_vscode ;;
        3) install_git_tools ;;
        4) install_nodejs_tools ;;
        5) install_python_tools ;;
        6) install_rust ;;
        7) install_go ;;
        8) install_postman ;;
        9) install_dbeaver ;;
        10) install_chrome ;;
        11) install_brave ;;
        12) install_discord ;;
        13) install_telegram ;;
        14) install_vlc ;;
        15) install_obs ;;
        16) install_spotify ;;
        17) install_gimp ;;
        18) install_libreoffice ;;
        19) install_steam ;;
        20) install_wine ;;
        21) update_system ;;
        22) 
            install_docker
            install_vscode
            install_git_tools
            install_nodejs_tools
            install_python_tools
            install_postman
            install_dbeaver
            ;;
        23)
            install_docker
            install_vscode
            install_git_tools
            install_nodejs_tools
            install_python_tools
            install_rust
            install_go
            install_postman
            install_dbeaver
            install_chrome
            install_discord
            install_telegram
            install_vlc
            install_obs
            install_gimp
            install_libreoffice
            ;;
        0) 
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid option: $1"
            ;;
    esac
}

# Main function
main() {
    check_root
    
    if ! check_internet; then
        log_error "Please check your internet connection"
        exit 1
    fi
    
    # Install yay if needed
    install_yay
    
    while true; do
        show_menu
        read -p "Enter your choice: " choice
        
        if [[ "$choice" == "0" ]]; then
            log_info "Goodbye!"
            exit 0
        fi
        
        # Handle multiple selections
        if [[ "$choice" =~ [[:space:]] ]]; then
            log_step "Installing Multiple Applications"
            for app in $choice; do
                handle_choice $app
            done
        else
            handle_choice $choice
        fi
        
        echo ""
        log_info "Installation complete!"
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"
