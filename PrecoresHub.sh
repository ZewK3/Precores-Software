#!/bin/bash
################################################################################
# Precores Hub - Unified Control Center (All-in-One)
# 
# This script contains ALL functionality:
# - QuickInstall (App installer)
# - QuickFix (System repair)
# - SystemManager (Monitoring & updates)
# 
# Uses fzf for pure console interface
################################################################################

VERSION="4.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

################################################################################
# DISTRO DETECTION
################################################################################

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_NAME=$NAME
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
        DISTRO_NAME="Arch Linux"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        DISTRO_NAME="Debian"
    else
        DISTRO="unknown"
        DISTRO_NAME="Unknown"
    fi
    
    # Detect package manager
    if command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        PKG_UPDATE="sudo pacman -Syu --noconfirm"
        PKG_REMOVE="sudo pacman -Rns --noconfirm"
        PKG_CLEAN="sudo pacman -Sc --noconfirm"
    elif command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        PKG_INSTALL="sudo apt install -y"
        PKG_UPDATE="sudo apt update && sudo apt upgrade -y"
        PKG_REMOVE="sudo apt remove -y"
        PKG_CLEAN="sudo apt autoremove -y && sudo apt clean"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_INSTALL="sudo dnf install -y"
        PKG_UPDATE="sudo dnf upgrade -y"
        PKG_REMOVE="sudo dnf remove -y"
        PKG_CLEAN="sudo dnf autoremove -y && sudo dnf clean all"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_INSTALL="sudo yum install -y"
        PKG_UPDATE="sudo yum update -y"
        PKG_REMOVE="sudo yum remove -y"
        PKG_CLEAN="sudo yum autoremove -y && sudo yum clean all"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
        PKG_INSTALL="sudo zypper install -y"
        PKG_UPDATE="sudo zypper update -y"
        PKG_REMOVE="sudo zypper remove -y"
        PKG_CLEAN="sudo zypper clean -a"
    else
        PKG_MANAGER="unknown"
        echo -e "${RED}[ERROR]${NC} Could not detect package manager!"
        exit 1
    fi
}

# Check and install dependencies
check_dependencies() {
    detect_distro
    
    if ! command -v fzf &> /dev/null; then
        echo -e "${YELLOW}[INFO]${NC} Installing fzf..."
        $PKG_INSTALL fzf
    fi
}

# Print header
print_header() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}${BOLD}           Precores Hub v${VERSION} - Control Center           ${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${BLUE}System: $DISTRO_NAME ($PKG_MANAGER)${NC}"
    echo ""
}

################################################################################
# MAIN MENU
################################################################################

show_main_menu() {
    while true; do
        print_header
        
        # Check for updates in background
        local update_status=""
        if check_update_available_silent; then
            update_status=" (Update Available!)"
        fi
        
        local choice=$(cat <<EOF | fzf --ansi --reverse --height=80% --border=rounded --prompt="> " --header="╔══════════════════════════════════════════════════════════╗
║       PRECORES HUB v${VERSION} - MAIN MENU           ║
╚══════════════════════════════════════════════════════════╝" --color="fg:#ffffff,bg:#1e1e2e,hl:#f38ba8,fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8,info:#cba6f7,prompt:#89b4fa,pointer:#f38ba8,marker:#a6e3a1,spinner:#f5e0dc,header:#94e2d5"
[01] QuickInstall          - Install apps & tools
[02] QuickFix              - Fix system issues
[03] SystemManager         - Monitor & manage system
[04] Backup & Restore      - Backup/restore system
[05] Theme Manager         - Customize appearance
[06] System Information    - View system details
[07] Settings              - Configure PrecoresHub
[08] Update Menu${update_status}
[00] Exit
EOF
)
        
        case "$choice" in
            "[01]"*) show_quickinstall_menu ;;
            "[02]"*) show_quickfix_menu ;;
            "[03]"*) show_systemmanager_menu ;;
            "[04]"*) show_backup_menu ;;
            "[05]"*) show_theme_manager ;;
            "[06]"*) show_system_info ;;
            "[07]"*) show_settings_menu ;;
            "[08]"*) show_update_menu ;;
            "[00]"*) exit_hub ;;
            "") exit_hub ;;
        esac
    done
}

################################################################################
# QUICKINSTALL MODULE
################################################################################

show_quickinstall_menu() {
    while true; do
        print_header
        echo -e "${YELLOW}QuickInstall - Application Installer${NC}"
        echo ""
        
        local choice=$(cat <<EOF | fzf --ansi --reverse --height=90% --border=rounded --prompt="> " --header="╔══════════════════════════════════════════════════════════╗
║        QUICKINSTALL - APPLICATION INSTALLER          ║
╚══════════════════════════════════════════════════════════╝" --color="fg:#ffffff,bg:#1e1e2e,hl:#f9e2af,fg+:#cdd6f4,bg+:#313244,hl+:#f9e2af,info:#cba6f7,prompt:#f9e2af,pointer:#f9e2af,marker:#a6e3a1,spinner:#f5e0dc,header:#f9e2af"
[01]  Docker               - Container platform
[02]  Visual Studio Code   - Code editor
[03]  Git Tools            - Version control
[04]  Node.js              - JavaScript runtime
[05]  Python               - Programming language
[06]  Rust                 - Systems programming
[07]  Go                   - Google's language
[10] Google Chrome        - Web browser
[11] Chromium             - Open source browser
[12] Firefox              - Mozilla browser
[15] Discord              - Voice & chat
[16] Telegram             - Messaging app
[20] VLC                  - Media player
[21] GIMP                 - Image editor
[22] OBS Studio           - Screen recorder
[25] LibreOffice          - Office suite
[40] Postman              - API testing
[41] Insomnia             - REST client
[42] DBeaver              - Database tool
[43] MongoDB Compass      - MongoDB GUI
[44] Android Studio       - Android dev
[45] JetBrains Toolbox    - IDE manager
[50] Slack                - Team chat
[51] Zoom                 - Video calls
[52] Microsoft Teams      - Collaboration
[53] Skype                - Video chat
[54] Thunderbird          - Email client
[60] Spotify              - Music streaming
[61] Audacity             - Audio editor
[62] Kdenlive             - Video editor
[63] Blender              - 3D modeling
[64] Inkscape             - Vector graphics
[70] Timeshift            - System snapshots
[71] Bleachbit            - System cleaner
[72] Stacer               - System optimizer
[73] GParted              - Disk manager
[74] Flameshot            - Screenshot tool
[75] Etcher               - USB creator
[30] Update System        - Full system update
[31] Install ALL Dev      - All development tools
[32] Package Search       - Find & install packages
[00]  Back
EOF
)
        
        case "$choice" in
            "[01]"*) install_docker ;;
            "[02]"*) install_vscode ;;
            "[03]"*) install_git_tools ;;
            "[04]"*) install_nodejs ;;
            "[05]"*) install_python ;;
            "[06]"*) install_rust ;;
            "[07]"*) install_go ;;
            "[10]"*) install_chrome ;;
            "[11]"*) install_chromium ;;
            "[12]"*) install_firefox ;;
            "[15]"*) install_discord ;;
            "[16]"*) install_telegram ;;
            "[20]"*) install_vlc ;;
            "[21]"*) install_gimp ;;
            "[22]"*) install_obs ;;
            "[25]"*) install_libreoffice ;;
            "[30]"*) update_system ;;
            "[31]"*) install_all_dev_tools ;;
            "[32]"*) package_search ;;
            "[40]"*) install_postman ;;
            "[41]"*) install_insomnia ;;
            "[42]"*) install_dbeaver ;;
            "[43]"*) install_mongodb_compass ;;
            "[44]"*) install_android_studio ;;
            "[45]"*) install_jetbrains_toolbox ;;
            "[50]"*) install_slack ;;
            "[51]"*) install_zoom ;;
            "[52]"*) install_teams ;;
            "[53]"*) install_skype ;;
            "[54]"*) install_thunderbird ;;
            "[60]"*) install_spotify ;;
            "[61]"*) install_audacity ;;
            "[62]"*) install_kdenlive ;;
            "[63]"*) install_blender ;;
            "[64]"*) install_inkscape ;;
            "[70]"*) install_timeshift ;;
            "[71]"*) install_bleachbit ;;
            "[72]"*) install_stacer ;;
            "[73]"*) install_gparted ;;
            "[74]"*) install_flameshot ;;
            "[75]"*) install_etcher ;;
            "[00]"*) return ;;
            "") return ;;
        esac
    done
}

# Install functions
install_docker() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Docker..."
    
    if [ "$PKG_MANAGER" == "pacman" ]; then
        sudo pacman -S --noconfirm docker docker-compose
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo apt install -y docker.io docker-compose
    else
        $PKG_INSTALL docker docker-compose
    fi
    
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Docker installed!"
    echo -e "${YELLOW}[INFO]${NC} Please logout and login to use Docker"
    echo ""
    read -p "Press Enter to continue..."
}

install_vscode() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing VS Code..."
    
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm visual-studio-code-bin
        else
            sudo pacman -S --noconfirm code
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
        sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        sudo apt update
        sudo apt install -y code
        rm packages.microsoft.gpg
    else
        echo -e "${YELLOW}[INFO]${NC} Please install VS Code manually for your distro"
    fi
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} VS Code installed!"
    echo ""
    read -p "Press Enter to continue..."
}

install_git_tools() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Git Tools..."
    $PKG_INSTALL git
    echo -e "${GREEN}[SUCCESS]${NC} Git installed!"
    read -p "Press Enter to continue..."
}

install_nodejs() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Node.js..."
    $PKG_INSTALL nodejs npm
    echo -e "${GREEN}[SUCCESS]${NC} Node.js installed!"
    read -p "Press Enter to continue..."
}

install_python() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Python..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        sudo pacman -S --noconfirm python python-pip
    else
        $PKG_INSTALL python3 python3-pip
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Python installed!"
    read -p "Press Enter to continue..."
}

install_rust() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    echo -e "${GREEN}[SUCCESS]${NC} Rust installed!"
    read -p "Press Enter to continue..."
}

install_go() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Go..."
    $PKG_INSTALL go
    echo -e "${GREEN}[SUCCESS]${NC} Go installed!"
    read -p "Press Enter to continue..."
}

install_chrome() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Chrome..."
    
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm google-chrome
        else
            echo -e "${YELLOW}[INFO]${NC} Installing Chromium instead"
            sudo pacman -S --noconfirm chromium
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
        sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
        sudo apt update
        sudo apt install -y google-chrome-stable
    fi
    
    echo -e "${GREEN}[SUCCESS]${NC} Chrome installed!"
    read -p "Press Enter to continue..."
}

install_chromium() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Chromium..."
    $PKG_INSTALL chromium
    echo -e "${GREEN}[SUCCESS]${NC} Chromium installed!"
    read -p "Press Enter to continue..."
}

install_firefox() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Firefox..."
    $PKG_INSTALL firefox
    echo -e "${GREEN}[SUCCESS]${NC} Firefox installed!"
    read -p "Press Enter to continue..."
}

install_discord() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Discord..."
    $PKG_INSTALL discord
    echo -e "${GREEN}[SUCCESS]${NC} Discord installed!"
    read -p "Press Enter to continue..."
}

install_telegram() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Telegram..."
    $PKG_INSTALL telegram-desktop
    echo -e "${GREEN}[SUCCESS]${NC} Telegram installed!"
    read -p "Press Enter to continue..."
}

install_vlc() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing VLC..."
    $PKG_INSTALL vlc
    echo -e "${GREEN}[SUCCESS]${NC} VLC installed!"
    read -p "Press Enter to continue..."
}

install_gimp() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing GIMP..."
    $PKG_INSTALL gimp
    echo -e "${GREEN}[SUCCESS]${NC} GIMP installed!"
    read -p "Press Enter to continue..."
}

install_obs() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing OBS Studio..."
    $PKG_INSTALL obs-studio
    echo -e "${GREEN}[SUCCESS]${NC} OBS Studio installed!"
    read -p "Press Enter to continue..."
}

install_libreoffice() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing LibreOffice..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        sudo pacman -S --noconfirm libreoffice-fresh
    else
        $PKG_INSTALL libreoffice
    fi
    echo -e "${GREEN}[SUCCESS]${NC} LibreOffice installed!"
    read -p "Press Enter to continue..."
}

update_system() {
    clear
    echo -e "${BLUE}[INFO]${NC} Updating system..."
    $PKG_UPDATE
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} System updated!"
    read -p "Press Enter to continue..."
}

install_all_dev_tools() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing all development tools..."
    install_docker
    install_vscode
    install_git_tools
    install_nodejs
    install_python
    echo -e "${GREEN}[SUCCESS]${NC} All dev tools installed!"
    read -p "Press Enter to continue..."
}

################################################################################
# NEW APPLICATIONS - DEVELOPMENT TOOLS
################################################################################

install_postman() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Postman..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm postman-bin
        else
            echo -e "${YELLOW}[INFO]${NC} Please install yay first or download from postman.com"
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo snap install postman
    else
        echo -e "${YELLOW}[INFO]${NC} Please download from postman.com"
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Postman installed!"
    read -p "Press Enter to continue..."
}

install_insomnia() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Insomnia..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm insomnia-bin
        else
            sudo pacman -S --noconfirm insomnia
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo snap install insomnia
    else
        echo -e "${YELLOW}[INFO]${NC} Please download from insomnia.rest"
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Insomnia installed!"
    read -p "Press Enter to continue..."
}

install_dbeaver() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing DBeaver..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        sudo pacman -S --noconfirm dbeaver
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo snap install dbeaver-ce
    else
        $PKG_INSTALL dbeaver
    fi
    echo -e "${GREEN}[SUCCESS]${NC} DBeaver installed!"
    read -p "Press Enter to continue..."
}

install_mongodb_compass() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing MongoDB Compass..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm mongodb-compass
        else
            echo -e "${YELLOW}[INFO]${NC} Please install yay first"
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        wget https://downloads.mongodb.com/compass/mongodb-compass_latest_amd64.deb
        sudo dpkg -i mongodb-compass_latest_amd64.deb
        rm mongodb-compass_latest_amd64.deb
    else
        echo -e "${YELLOW}[INFO]${NC} Please download from mongodb.com/products/compass"
    fi
    echo -e "${GREEN}[SUCCESS]${NC} MongoDB Compass installed!"
    read -p "Press Enter to continue..."
}

install_android_studio() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Android Studio..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm android-studio
        else
            echo -e "${YELLOW}[INFO]${NC} Please install yay first"
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo snap install android-studio --classic
    else
        echo -e "${YELLOW}[INFO]${NC} Please download from developer.android.com/studio"
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Android Studio installed!"
    read -p "Press Enter to continue..."
}

install_jetbrains_toolbox() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing JetBrains Toolbox..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm jetbrains-toolbox
        else
            echo -e "${YELLOW}[INFO]${NC} Please install yay first"
        fi
    else
        echo -e "${YELLOW}[INFO]${NC} Downloading JetBrains Toolbox..."
        wget -O /tmp/jetbrains-toolbox.tar.gz "https://download.jetbrains.com/toolbox/jetbrains-toolbox-latest.tar.gz"
        tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /tmp
        /tmp/jetbrains-toolbox-*/jetbrains-toolbox
    fi
    echo -e "${GREEN}[SUCCESS]${NC} JetBrains Toolbox installed!"
    read -p "Press Enter to continue..."
}

################################################################################
# NEW APPLICATIONS - COMMUNICATION
################################################################################

install_slack() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Slack..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm slack-desktop
        else
            sudo pacman -S --noconfirm slack-desktop
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo snap install slack --classic
    else
        $PKG_INSTALL slack
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Slack installed!"
    read -p "Press Enter to continue..."
}

install_zoom() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Zoom..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm zoom
        else
            echo -e "${YELLOW}[INFO]${NC} Please install yay first"
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        wget https://zoom.us/client/latest/zoom_amd64.deb
        sudo dpkg -i zoom_amd64.deb
        sudo apt --fix-broken install -y
        rm zoom_amd64.deb
    else
        echo -e "${YELLOW}[INFO]${NC} Please download from zoom.us"
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Zoom installed!"
    read -p "Press Enter to continue..."
}

install_teams() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Microsoft Teams..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm teams
        else
            echo -e "${YELLOW}[INFO]${NC} Please install yay first"
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo snap install teams-for-linux
    else
        echo -e "${YELLOW}[INFO]${NC} Please download from microsoft.com/teams"
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Teams installed!"
    read -p "Press Enter to continue..."
}

install_skype() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Skype..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm skypeforlinux-stable-bin
        else
            echo -e "${YELLOW}[INFO]${NC} Please install yay first"
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo snap install skype --classic
    else
        $PKG_INSTALL skype
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Skype installed!"
    read -p "Press Enter to continue..."
}

install_thunderbird() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Thunderbird..."
    $PKG_INSTALL thunderbird
    echo -e "${GREEN}[SUCCESS]${NC} Thunderbird installed!"
    read -p "Press Enter to continue..."
}

################################################################################
# NEW APPLICATIONS - MULTIMEDIA
################################################################################

install_spotify() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Spotify..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm spotify
        else
            echo -e "${YELLOW}[INFO]${NC} Please install yay first"
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo snap install spotify
    else
        echo -e "${YELLOW}[INFO]${NC} Please download from spotify.com"
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Spotify installed!"
    read -p "Press Enter to continue..."
}

install_audacity() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Audacity..."
    $PKG_INSTALL audacity
    echo -e "${GREEN}[SUCCESS]${NC} Audacity installed!"
    read -p "Press Enter to continue..."
}

install_kdenlive() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Kdenlive..."
    $PKG_INSTALL kdenlive
    echo -e "${GREEN}[SUCCESS]${NC} Kdenlive installed!"
    read -p "Press Enter to continue..."
}

install_blender() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Blender..."
    $PKG_INSTALL blender
    echo -e "${GREEN}[SUCCESS]${NC} Blender installed!"
    read -p "Press Enter to continue..."
}

install_inkscape() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Inkscape..."
    $PKG_INSTALL inkscape
    echo -e "${GREEN}[SUCCESS]${NC} Inkscape installed!"
    read -p "Press Enter to continue..."
}

################################################################################
# NEW APPLICATIONS - UTILITIES
################################################################################

install_timeshift() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Timeshift..."
    $PKG_INSTALL timeshift
    echo -e "${GREEN}[SUCCESS]${NC} Timeshift installed!"
    echo -e "${YELLOW}[INFO]${NC} Run 'sudo timeshift-gtk' to configure backups"
    read -p "Press Enter to continue..."
}

install_bleachbit() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Bleachbit..."
    $PKG_INSTALL bleachbit
    echo -e "${GREEN}[SUCCESS]${NC} Bleachbit installed!"
    read -p "Press Enter to continue..."
}

install_stacer() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Stacer..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm stacer
        else
            echo -e "${YELLOW}[INFO]${NC} Please install yay first"
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        wget https://github.com/oguzhaninan/Stacer/releases/download/v1.1.0/stacer_1.1.0_amd64.deb
        sudo dpkg -i stacer_1.1.0_amd64.deb
        rm stacer_1.1.0_amd64.deb
    else
        echo -e "${YELLOW}[INFO]${NC} Please download from github.com/oguzhaninan/Stacer"
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Stacer installed!"
    read -p "Press Enter to continue..."
}

install_gparted() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing GParted..."
    $PKG_INSTALL gparted
    echo -e "${GREEN}[SUCCESS]${NC} GParted installed!"
    read -p "Press Enter to continue..."
}

install_flameshot() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Flameshot..."
    $PKG_INSTALL flameshot
    echo -e "${GREEN}[SUCCESS]${NC} Flameshot installed!"
    read -p "Press Enter to continue..."
}

install_etcher() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Etcher..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm balena-etcher
        else
            echo -e "${YELLOW}[INFO]${NC} Please install yay first"
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
        sudo apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 379CE192D401AB61
        sudo apt update
        sudo apt install -y balena-etcher-electron
    else
        echo -e "${YELLOW}[INFO]${NC} Please download from balena.io/etcher"
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Etcher installed!"
    read -p "Press Enter to continue..."
}

################################################################################
# PACKAGE SEARCH FEATURE
################################################################################

package_search() {
    clear
    echo -e "${CYAN}Package Search${NC}"
    echo ""
    read -p "Enter package name to search: " search_term
    
    if [ -z "$search_term" ]; then
        echo -e "${RED}[ERROR]${NC} Please enter a search term"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo -e "${BLUE}[INFO]${NC} Searching for '$search_term'..."
    echo ""
    
    if [ "$PKG_MANAGER" == "pacman" ]; then
        pacman -Ss "$search_term" | head -20
    elif [ "$PKG_MANAGER" == "apt" ]; then
        apt-cache search "$search_term" | head -20
    elif [ "$PKG_MANAGER" == "dnf" ]; then
        dnf search "$search_term" | head -20
    else
        echo -e "${YELLOW}[INFO]${NC} Package search not supported for $PKG_MANAGER"
    fi
    
    echo ""
    read -p "Enter package name to install (or press Enter to cancel): " pkg_name
    
    if [ -n "$pkg_name" ]; then
        echo ""
        echo -e "${BLUE}[INFO]${NC} Installing $pkg_name..."
        $PKG_INSTALL "$pkg_name"
        echo -e "${GREEN}[SUCCESS]${NC} Package installed!"
    fi
    
    read -p "Press Enter to continue..."
}

################################################################################
# QUICKFIX MODULE
################################################################################

show_quickfix_menu() {
    while true; do
        print_header
        echo -e "${YELLOW}QuickFix - System Repair & Fixes${NC}"
        echo ""
        
        local choice=$(cat <<EOF | fzf --ansi --reverse --height=80% --border=rounded --prompt="> " --header="╔══════════════════════════════════════════════════════════╗
║         QUICKFIX - SYSTEM REPAIR & FIXES             ║
╚══════════════════════════════════════════════════════════╝" --color="fg:#ffffff,bg:#1e1e2e,hl:#f38ba8,fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8,info:#cba6f7,prompt:#f38ba8,pointer:#f38ba8,marker:#a6e3a1,spinner:#f5e0dc,header:#f38ba8"
[01]  Fix Auto-Login       - Configure LightDM auto-login
[02]  Fix zram             - Setup compressed RAM
[03]  Fix Firewall         - Configure UFW firewall
[04]  Fix Network          - Reset network settings
[10] Update System        - Full system update
[11] Clean System         - Remove orphans & cache
[12] System Health        - Check system status
[15] GitHub QuickFix      - Download latest fixes
[20] Fix All Issues       - Run all common fixes
[21] Full Maintenance     - Complete system cleanup
[00]  Back
EOF
)
        
        case "$choice" in
            "[01]"*) fix_autologin ;;
            "[02]"*) fix_zram ;;
            "[03]"*) fix_firewall ;;
            "[04]"*) fix_network ;;
            "[10]"*) update_system ;;
            "[11]"*) clean_system ;;
            "[12]"*) check_system_health ;;
            "[15]"*) run_quickfix_from_github ;;
            "[20]"*) fix_all_common ;;
            "[21]"*) full_maintenance ;;
            "[00]"*) return ;;
            "") return ;;
        esac
    done
}

fix_autologin() {
    clear
    echo -e "${BLUE}[INFO]${NC} Fixing Auto-Login..."
    
    if [ "$PKG_MANAGER" == "pacman" ]; then
        sudo mkdir -p /etc/lightdm/lightdm.conf.d
        sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf > /dev/null <<EOF
[Seat:*]
autologin-user=$USER
autologin-user-timeout=0
autologin-session=xfce
EOF
        sudo groupadd -r autologin 2>/dev/null || true
        sudo gpasswd -a $USER autologin
        echo -e "${GREEN}[SUCCESS]${NC} Auto-login fixed!"
    else
        echo -e "${YELLOW}[INFO]${NC} Auto-login fix is for Arch/XFCE only"
    fi
    
    read -p "Press Enter to continue..."
}

fix_zram() {
    clear
    echo -e "${BLUE}[INFO]${NC} Fixing zram..."
    
    if [ ! -f /etc/systemd/zram-generator.conf ]; then
        sudo tee /etc/systemd/zram-generator.conf > /dev/null <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF
        echo -e "${GREEN}[SUCCESS]${NC} zram configured!"
        echo -e "${YELLOW}[INFO]${NC} Please reboot for changes to take effect"
    else
        echo -e "${GREEN}[INFO]${NC} zram already configured"
    fi
    
    read -p "Press Enter to continue..."
}

fix_firewall() {
    clear
    echo -e "${BLUE}[INFO]${NC} Fixing Firewall..."
    
    if ! command -v ufw &> /dev/null; then
        $PKG_INSTALL ufw
    fi
    
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw --force enable
    sudo systemctl enable ufw
    
    echo -e "${GREEN}[SUCCESS]${NC} Firewall configured!"
    read -p "Press Enter to continue..."
}

fix_network() {
    clear
    echo -e "${BLUE}[INFO]${NC} Fixing Network..."
    
    sudo systemctl restart NetworkManager
    
    if ! ping -c 1 google.com &> /dev/null; then
        echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
        echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf > /dev/null
    fi
    
    echo -e "${GREEN}[SUCCESS]${NC} Network checked!"
    read -p "Press Enter to continue..."
}

clean_system() {
    clear
    echo -e "${BLUE}[INFO]${NC} Cleaning system..."
    
    if [ "$PKG_MANAGER" == "pacman" ]; then
        sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || echo "No orphaned packages"
    fi
    
    $PKG_CLEAN
    
    if command -v journalctl &> /dev/null; then
        sudo journalctl --vacuum-time=7d
    fi
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} System cleaned!"
    read -p "Press Enter to continue..."
}

check_system_health() {
    clear
    echo -e "${CYAN}System Health Check${NC}"
    echo ""
    echo -e "${BOLD}System Information:${NC}"
    echo "  Hostname: $(cat /etc/hostname 2>/dev/null || uname -n)"
    echo "  Kernel: $(uname -r)"
    echo "  Uptime: $(uptime -p)"
    echo ""
    echo -e "${BOLD}Memory Usage:${NC}"
    free -h
    echo ""
    echo -e "${BOLD}Disk Usage:${NC}"
    df -h / | tail -1
    echo ""
    read -p "Press Enter to continue..."
}

fix_all_common() {
    fix_autologin
    fix_zram
    fix_firewall
    fix_network
}

full_maintenance() {
    update_system
    clean_system
}

# Download and run QuickFix from GitHub
run_quickfix_from_github() {
    clear
    echo -e "${BLUE}[INFO]${NC} Downloading QuickFix from GitHub..."
    echo ""
    
    QUICKFIX_URL="https://raw.githubusercontent.com/ZewK3/Precores-Software/refs/heads/main/QuiclFix.sh"
    QUICKFIX_TEMP="/tmp/QuiclFix_remote.sh"
    
    if curl -f -s -o "$QUICKFIX_TEMP" "$QUICKFIX_URL"; then
        chmod +x "$QUICKFIX_TEMP"
        echo -e "${GREEN}[SUCCESS]${NC} Downloaded QuickFix from GitHub"
        echo -e "${BLUE}[INFO]${NC} Running QuickFix..."
        echo ""
        
        # Execute the remote QuickFix script
        bash "$QUICKFIX_TEMP"
        
        echo ""
        echo -e "${GREEN}[INFO]${NC} QuickFix completed"
    else
        echo -e "${RED}[ERROR]${NC} Failed to download QuickFix from GitHub"
        echo "URL: $QUICKFIX_URL"
    fi
    
    read -p "Press Enter to continue..."
}

################################################################################
# BACKUP & RESTORE MODULE
################################################################################

BACKUP_DIR="$HOME/.precores-backups"

show_backup_menu() {
    while true; do
        print_header
        echo -e "${YELLOW}Backup & Restore - System Backup${NC}"
        echo ""
        
        # Check backup directory
        if [ -d "$BACKUP_DIR" ]; then
            backup_count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
            backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        else
            backup_count=0
            backup_size="0"
        fi
        
        local choice=$(cat <<EOF | fzf --ansi --reverse --height=75% --border=rounded --prompt="> " --header="╔══════════════════════════════════════════════════════════╗
║        BACKUP & RESTORE - SYSTEM BACKUP              ║
╚══════════════════════════════════════════════════════════╝

Backup Location: $BACKUP_DIR
Total Backups: $backup_count | Size: $backup_size
" --color="fg:#ffffff,bg:#1e1e2e,hl:#fab387,fg+:#cdd6f4,bg+:#313244,hl+:#fab387,info:#cba6f7,prompt:#fab387,pointer:#fab387,marker:#a6e3a1,spinner:#f5e0dc,header:#fab387"
[01]  Full Backup          - Packages + dotfiles + config
[02]  Backup Packages      - Package list only
[03]  Backup Dotfiles      - Config files only
[04]  Backup System        - System configuration
[10] Restore Full         - Restore complete backup
[11] Restore Packages     - Restore packages only
[12] Restore Dotfiles     - Restore config files
[20] View History         - List all backups
[21] Delete Old           - Remove old backups
[22] Open Directory       - Browse backup folder
[23] Statistics           - Backup statistics
[00]  Back
EOF
)
        
        case "$choice" in
            "[01]"*) create_full_backup ;;
            "[02]"*) backup_packages ;;
            "[03]"*) backup_dotfiles ;;
            "[04]"*) backup_system_config ;;
            "[10]"*) restore_from_backup ;;
            "[11]"*) restore_packages ;;
            "[12]"*) restore_dotfiles ;;
            "[20]"*) view_backup_history ;;
            "[21]"*) delete_old_backups ;;
            "[22]"*) open_backup_directory ;;
            "[23]"*) backup_statistics ;;
            "[00]"*) return ;;
            "") return ;;
        esac
    done
}

# Create full backup
create_full_backup() {
    clear
    echo -e "${BLUE}[INFO]${NC} Creating full backup..."
    echo ""
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Generate backup name with timestamp
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$BACKUP_PATH"
    
    echo -e "${CYAN}Backup location: $BACKUP_PATH${NC}"
    echo ""
    
    # Backup package list
    echo -e "${BLUE}[1/3]${NC} Backing up package list..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        pacman -Qqe > "$BACKUP_PATH/packages.txt"
        if command -v yay &> /dev/null; then
            yay -Qm > "$BACKUP_PATH/aur-packages.txt"
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        dpkg --get-selections > "$BACKUP_PATH/packages.txt"
    else
        echo "Package list backup not supported for $PKG_MANAGER" > "$BACKUP_PATH/packages.txt"
    fi
    
    # Backup dotfiles
    echo -e "${BLUE}[2/3]${NC} Backing up dotfiles..."
    mkdir -p "$BACKUP_PATH/dotfiles"
    
    # Common dotfiles
    for file in .bashrc .bash_profile .zshrc .vimrc .gitconfig; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$BACKUP_PATH/dotfiles/"
        fi
    done
    
    # Backup .config directory (selective)
    if [ -d "$HOME/.config" ]; then
        mkdir -p "$BACKUP_PATH/dotfiles/.config"
        for dir in Code VSCodium nvim vim fish; do
            if [ -d "$HOME/.config/$dir" ]; then
                cp -r "$HOME/.config/$dir" "$BACKUP_PATH/dotfiles/.config/"
            fi
        done
    fi
    
    # Backup system info
    echo -e "${BLUE}[3/3]${NC} Saving system information..."
    cat > "$BACKUP_PATH/system-info.txt" <<EOF
Backup Date: $(date)
Hostname: $(cat /etc/hostname 2>/dev/null || uname -n)
Kernel: $(uname -r)
Distro: $DISTRO_NAME
Package Manager: $PKG_MANAGER
PrecoresHub Version: $VERSION
EOF
    
    # Create backup manifest
    echo -e "${BLUE}[INFO]${NC} Creating backup manifest..."
    find "$BACKUP_PATH" -type f > "$BACKUP_PATH/manifest.txt"
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Full backup created!"
    echo -e "${CYAN}Location: $BACKUP_PATH${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Backup packages only
backup_packages() {
    clear
    echo -e "${BLUE}[INFO]${NC} Backing up package list..."
    
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/packages-$(date +%Y%m%d-%H%M%S).txt"
    
    if [ "$PKG_MANAGER" == "pacman" ]; then
        pacman -Qqe > "$BACKUP_FILE"
        echo -e "${GREEN}[SUCCESS]${NC} Package list saved to: $BACKUP_FILE"
    elif [ "$PKG_MANAGER" == "apt" ]; then
        dpkg --get-selections > "$BACKUP_FILE"
        echo -e "${GREEN}[SUCCESS]${NC} Package list saved to: $BACKUP_FILE"
    else
        echo -e "${YELLOW}[INFO]${NC} Package backup not supported for $PKG_MANAGER"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Backup dotfiles
backup_dotfiles() {
    clear
    echo -e "${BLUE}[INFO]${NC} Backing up dotfiles..."
    
    mkdir -p "$BACKUP_DIR"
    BACKUP_NAME="dotfiles-$(date +%Y%m%d-%H%M%S)"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$BACKUP_PATH"
    
    # Backup common dotfiles
    for file in .bashrc .bash_profile .zshrc .vimrc .gitconfig .tmux.conf; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$BACKUP_PATH/"
            echo "Backed up: $file"
        fi
    done
    
    # Backup .config
    if [ -d "$HOME/.config" ]; then
        mkdir -p "$BACKUP_PATH/.config"
        cp -r "$HOME/.config" "$BACKUP_PATH/" 2>/dev/null || true
    fi
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Dotfiles backed up to: $BACKUP_PATH"
    read -p "Press Enter to continue..."
}

# Backup system configuration
backup_system_config() {
    clear
    echo -e "${BLUE}[INFO]${NC} Backing up system configuration..."
    
    mkdir -p "$BACKUP_DIR"
    BACKUP_NAME="sysconfig-$(date +%Y%m%d-%H%M%S)"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$BACKUP_PATH"
    
    # Backup important system files (requires sudo)
    echo -e "${YELLOW}[INFO]${NC} This requires sudo access..."
    
    sudo cp /etc/fstab "$BACKUP_PATH/" 2>/dev/null || true
    sudo cp /etc/hosts "$BACKUP_PATH/" 2>/dev/null || true
    sudo cp -r /etc/systemd/system "$BACKUP_PATH/" 2>/dev/null || true
    
    echo -e "${GREEN}[SUCCESS]${NC} System config backed up to: $BACKUP_PATH"
    read -p "Press Enter to continue..."
}

# Restore from backup
restore_from_backup() {
    clear
    echo -e "${CYAN}Available Backups:${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo -e "${RED}[ERROR]${NC} No backups found!"
        read -p "Press Enter to continue..."
        return
    fi
    
    # List backups
    ls -1t "$BACKUP_DIR" | nl
    echo ""
    read -p "Enter backup number to restore (or 0 to cancel): " backup_num
    
    if [ "$backup_num" == "0" ]; then
        return
    fi
    
    BACKUP_NAME=$(ls -1t "$BACKUP_DIR" | sed -n "${backup_num}p")
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    
    if [ ! -d "$BACKUP_PATH" ]; then
        echo -e "${RED}[ERROR]${NC} Invalid backup selection!"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}[WARNING]${NC} This will restore from: $BACKUP_NAME"
    read -p "Continue? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        return
    fi
    
    # Restore packages
    if [ -f "$BACKUP_PATH/packages.txt" ]; then
        echo -e "${BLUE}[INFO]${NC} Restoring packages..."
        if [ "$PKG_MANAGER" == "pacman" ]; then
            sudo pacman -S --needed - < "$BACKUP_PATH/packages.txt"
        elif [ "$PKG_MANAGER" == "apt" ]; then
            sudo dpkg --set-selections < "$BACKUP_PATH/packages.txt"
            sudo apt-get dselect-upgrade
        fi
    fi
    
    # Restore dotfiles
    if [ -d "$BACKUP_PATH/dotfiles" ]; then
        echo -e "${BLUE}[INFO]${NC} Restoring dotfiles..."
        cp -r "$BACKUP_PATH/dotfiles/." "$HOME/"
    fi
    
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Restore completed!"
    read -p "Press Enter to continue..."
}

# Restore packages only
restore_packages() {
    clear
    echo -e "${CYAN}Available Package Backups:${NC}"
    echo ""
    
    ls -1t "$BACKUP_DIR"/packages-*.txt 2>/dev/null | nl
    echo ""
    read -p "Enter backup number (or 0 to cancel): " backup_num
    
    if [ "$backup_num" == "0" ]; then
        return
    fi
    
    BACKUP_FILE=$(ls -1t "$BACKUP_DIR"/packages-*.txt | sed -n "${backup_num}p")
    
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}[ERROR]${NC} Invalid selection!"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${BLUE}[INFO]${NC} Restoring packages from: $(basename $BACKUP_FILE)"
    
    if [ "$PKG_MANAGER" == "pacman" ]; then
        sudo pacman -S --needed - < "$BACKUP_FILE"
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo dpkg --set-selections < "$BACKUP_FILE"
        sudo apt-get dselect-upgrade
    fi
    
    echo -e "${GREEN}[SUCCESS]${NC} Packages restored!"
    read -p "Press Enter to continue..."
}

# Restore dotfiles
restore_dotfiles() {
    clear
    echo -e "${CYAN}Available Dotfile Backups:${NC}"
    echo ""
    
    ls -1td "$BACKUP_DIR"/dotfiles-* 2>/dev/null | nl
    echo ""
    read -p "Enter backup number (or 0 to cancel): " backup_num
    
    if [ "$backup_num" == "0" ]; then
        return
    fi
    
    BACKUP_PATH=$(ls -1td "$BACKUP_DIR"/dotfiles-* | sed -n "${backup_num}p")
    
    if [ ! -d "$BACKUP_PATH" ]; then
        echo -e "${RED}[ERROR]${NC} Invalid selection!"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${BLUE}[INFO]${NC} Restoring dotfiles..."
    cp -r "$BACKUP_PATH/." "$HOME/"
    
    echo -e "${GREEN}[SUCCESS]${NC} Dotfiles restored!"
    read -p "Press Enter to continue..."
}

# View backup history
view_backup_history() {
    clear
    echo -e "${CYAN}Backup History${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo -e "${YELLOW}[INFO]${NC} No backups found"
    else
        echo -e "${BOLD}Name                    Size    Date${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ls -1t "$BACKUP_DIR" | while read backup; do
            if [ -d "$BACKUP_DIR/$backup" ]; then
                size=$(du -sh "$BACKUP_DIR/$backup" 2>/dev/null | cut -f1)
                date=$(stat -c %y "$BACKUP_DIR/$backup" 2>/dev/null | cut -d' ' -f1)
                printf "%-24s %-8s %s\n" "$backup" "$size" "$date"
            fi
        done
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Delete old backups
delete_old_backups() {
    clear
    echo -e "${YELLOW}Delete Old Backups${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo -e "${YELLOW}[INFO]${NC} No backups to delete"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Select option:"
    echo "[01] Delete backups older than 30 days"
    echo "[02] Delete backups older than 90 days"
    echo "[03] Delete all backups"
    echo "[00] Cancel"
    echo ""
    read -p "Choice: " choice
    
    case "$choice" in
        1)
            find "$BACKUP_DIR" -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null
            echo -e "${GREEN}[SUCCESS]${NC} Deleted backups older than 30 days"
            ;;
        2)
            find "$BACKUP_DIR" -type d -mtime +90 -exec rm -rf {} \; 2>/dev/null
            echo -e "${GREEN}[SUCCESS]${NC} Deleted backups older than 90 days"
            ;;
        3)
            read -p "Are you sure? This will delete ALL backups! (yes/no): " confirm
            if [ "$confirm" == "yes" ]; then
                rm -rf "$BACKUP_DIR"/*
                echo -e "${GREEN}[SUCCESS]${NC} All backups deleted"
            fi
            ;;
        *)
            echo "Cancelled"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Open backup directory
open_backup_directory() {
    clear
    echo -e "${BLUE}[INFO]${NC} Opening backup directory..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
    fi
    
    if command -v xdg-open &> /dev/null; then
        xdg-open "$BACKUP_DIR"
    elif command -v nautilus &> /dev/null; then
        nautilus "$BACKUP_DIR"
    elif command -v thunar &> /dev/null; then
        thunar "$BACKUP_DIR"
    else
        echo -e "${CYAN}Backup directory: $BACKUP_DIR${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Backup statistics
backup_statistics() {
    clear
    echo -e "${CYAN}Backup Statistics${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}[INFO]${NC} No backup directory found"
    else
        total_backups=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
        total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        oldest=$(ls -1t "$BACKUP_DIR" 2>/dev/null | tail -1)
        newest=$(ls -1t "$BACKUP_DIR" 2>/dev/null | head -1)
        
        echo -e "${BOLD}Total Backups:${NC} $total_backups"
        echo -e "${BOLD}Total Size:${NC} $total_size"
        echo -e "${BOLD}Backup Location:${NC} $BACKUP_DIR"
        echo ""
        echo -e "${BOLD}Oldest Backup:${NC} $oldest"
        echo -e "${BOLD}Newest Backup:${NC} $newest"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

################################################################################
# THEME MANAGER MODULE
################################################################################

show_theme_manager() {
    while true; do
        print_header
        echo -e "${MAGENTA}Theme Manager - Customize Appearance${NC}"
        echo ""
        
        local choice=$(cat <<EOF | fzf --ansi --reverse --height=75% --border=rounded --prompt="> " --header="╔══════════════════════════════════════════════════════════╗
║       THEME MANAGER - CUSTOMIZE APPEARANCE           ║
╚══════════════════════════════════════════════════════════╝" --color="fg:#ffffff,bg:#1e1e2e,hl:#f5c2e7,fg+:#cdd6f4,bg+:#313244,hl+:#f5c2e7,info:#cba6f7,prompt:#f5c2e7,pointer:#f5c2e7,marker:#a6e3a1,spinner:#f5e0dc,header:#f5c2e7"
[01]  Dracula              - Dark purple theme
[02]  Nord                 - Arctic blue theme
[03]  Gruvbox              - Retro warm theme
[04]  Solarized            - Precision colors
[05]  Catppuccin           - Pastel theme
[10] Arc                  - Flat design theme
[11] Adapta               - Material design
[12] Materia              - Modern flat theme
[13] Numix                - Circle design
[20] Papirus              - Colorful icons
[21] Numix Circle         - Circular icons
[22] Flat Remix           - Flat style icons
[23] Tela                 - Modern icons
[30] Fira Code            - Ligature font
[31] JetBrains Mono       - Developer font
[32] Hack                 - Monospace font
[33] Source Code Pro      - Adobe font
[00]  Back
EOF
)
        
        case "$choice" in
            "[01]"*) install_dracula_theme ;;
            "[02]"*) install_nord_theme ;;
            "[03]"*) install_gruvbox_theme ;;
            "[04]"*) install_solarized_theme ;;
            "[05]"*) install_catppuccin_theme ;;
            "[10]"*) install_arc_theme ;;
            "[11]"*) install_adapta_theme ;;
            "[12]"*) install_materia_theme ;;
            "[13]"*) install_numix_theme ;;
            "[20]"*) install_papirus_icons ;;
            "[21]"*) install_numix_icons ;;
            "[22]"*) install_flatremix_icons ;;
            "[23]"*) install_tela_icons ;;
            "[30]"*) install_firacode_font ;;
            "[31]"*) install_jetbrains_font ;;
            "[32]"*) install_hack_font ;;
            "[33]"*) install_sourcecodepro_font ;;
            "[00]"*) return ;;
            "") return ;;
        esac
    done
}

# Terminal Themes
install_dracula_theme() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Dracula theme for terminal..."
    
    # For XFCE Terminal
    if [ -d ~/.config/xfce4/terminal ]; then
        mkdir -p ~/.config/xfce4/terminal
        cat > ~/.config/xfce4/terminal/terminalrc <<EOF
[Configuration]
ColorForeground=#f8f8f2
ColorBackground=#282a36
ColorPalette=#21222c;#ff5555;#50fa7b;#f1fa8c;#bd93f9;#ff79c6;#8be9fd;#f8f8f2;#6272a4;#ff6e6e;#69ff94;#ffffa5;#d6acff;#ff92df;#a4ffff;#ffffff
EOF
        echo -e "${GREEN}[SUCCESS]${NC} Dracula theme installed for XFCE Terminal!"
    fi
    
    read -p "Press Enter to continue..."
}

install_nord_theme() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Nord theme..."
    $PKG_INSTALL nordic-theme
    echo -e "${GREEN}[SUCCESS]${NC} Nord theme installed!"
    read -p "Press Enter to continue..."
}

install_gruvbox_theme() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Gruvbox theme..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm gruvbox-dark-gtk gruvbox-dark-icons-gtk
        fi
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Gruvbox theme installed!"
    read -p "Press Enter to continue..."
}

install_solarized_theme() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Solarized theme..."
    echo -e "${YELLOW}[INFO]${NC} Solarized is available in most terminal emulators"
    read -p "Press Enter to continue..."
}

install_catppuccin_theme() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Catppuccin theme..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm catppuccin-gtk-theme-mocha
        fi
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Catppuccin theme installed!"
    read -p "Press Enter to continue..."
}

# XFCE Themes
install_arc_theme() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Arc theme..."
    $PKG_INSTALL arc-gtk-theme arc-icon-theme
    echo -e "${GREEN}[SUCCESS]${NC} Arc theme installed!"
    echo -e "${YELLOW}[INFO]${NC} Apply via: Settings > Appearance"
    read -p "Press Enter to continue..."
}

install_adapta_theme() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Adapta theme..."
    $PKG_INSTALL adapta-gtk-theme
    echo -e "${GREEN}[SUCCESS]${NC} Adapta theme installed!"
    read -p "Press Enter to continue..."
}

install_materia_theme() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Materia theme..."
    $PKG_INSTALL materia-gtk-theme
    echo -e "${GREEN}[SUCCESS]${NC} Materia theme installed!"
    read -p "Press Enter to continue..."
}

install_numix_theme() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Numix theme..."
    $PKG_INSTALL numix-gtk-theme
    echo -e "${GREEN}[SUCCESS]${NC} Numix theme installed!"
    read -p "Press Enter to continue..."
}

# Icon Packs
install_papirus_icons() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Papirus icons..."
    $PKG_INSTALL papirus-icon-theme
    echo -e "${GREEN}[SUCCESS]${NC} Papirus icons installed!"
    echo -e "${YELLOW}[INFO]${NC} Apply via: Settings > Appearance > Icons"
    read -p "Press Enter to continue..."
}

install_numix_icons() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Numix Circle icons..."
    $PKG_INSTALL numix-circle-icon-theme
    echo -e "${GREEN}[SUCCESS]${NC} Numix Circle icons installed!"
    read -p "Press Enter to continue..."
}

install_flatremix_icons() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Flat Remix icons..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm flat-remix
        fi
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Flat Remix icons installed!"
    read -p "Press Enter to continue..."
}

install_tela_icons() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Tela icons..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm tela-icon-theme
        fi
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Tela icons installed!"
    read -p "Press Enter to continue..."
}

# Fonts
install_firacode_font() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Fira Code font..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        sudo pacman -S --noconfirm ttf-fira-code
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo apt install -y fonts-firacode
    else
        $PKG_INSTALL fira-code-fonts
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Fira Code font installed!"
    read -p "Press Enter to continue..."
}

install_jetbrains_font() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing JetBrains Mono font..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        sudo pacman -S --noconfirm ttf-jetbrains-mono
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo apt install -y fonts-jetbrains-mono
    else
        $PKG_INSTALL jetbrains-mono-fonts
    fi
    echo -e "${GREEN}[SUCCESS]${NC} JetBrains Mono font installed!"
    read -p "Press Enter to continue..."
}

install_hack_font() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Hack font..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        sudo pacman -S --noconfirm ttf-hack
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo apt install -y fonts-hack
    else
        $PKG_INSTALL hack-fonts
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Hack font installed!"
    read -p "Press Enter to continue..."
}

install_sourcecodepro_font() {
    clear
    echo -e "${BLUE}[INFO]${NC} Installing Source Code Pro font..."
    if [ "$PKG_MANAGER" == "pacman" ]; then
        sudo pacman -S --noconfirm adobe-source-code-pro-fonts
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo apt install -y fonts-source-code-pro
    else
        $PKG_INSTALL source-code-pro-fonts
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Source Code Pro font installed!"
    read -p "Press Enter to continue..."
}

################################################################################
# UPDATE MENU
################################################################################

show_update_menu() {
    while true; do
        print_header
        echo -e "${MAGENTA}Update Menu${NC}"
        echo ""
        
        # Get current and remote versions
        local current_version="$VERSION"
        local remote_version=$(get_remote_version_hub)
        local update_available="No"
        
        if [ "$remote_version" != "unknown" ] && [ "$remote_version" != "$current_version" ]; then
            update_available="Yes - v$current_version -> v$remote_version"
        fi
        
        local choice=$(cat <<EOF | fzf --ansi --reverse --height=70% --border=rounded --prompt="> " --header="╔══════════════════════════════════════════════════════════╗
║          UPDATE MENU - VERSION MANAGER               ║
╚══════════════════════════════════════════════════════════╝

Current: v$current_version
Remote: v$remote_version
Update Available: $update_available
" --color="fg:#ffffff,bg:#1e1e2e,hl:#cba6f7,fg+:#cdd6f4,bg+:#313244,hl+:#cba6f7,info:#cba6f7,prompt:#cba6f7,pointer:#cba6f7,marker:#a6e3a1,spinner:#f5e0dc,header:#cba6f7"
[01] Check Updates         - Check for new version
[02] Update Hub            - Update from GitHub
[03] View Changelog        - See what's new
[04] Force Update          - Re-download script
[00] Back
EOF
)
        
        case "$choice" in
            "[01]"*) check_for_updates_detailed ;;
            "[02]"*) update_precoreshub ;;
            "[03]"*) view_changelog ;;
            "[04]"*) force_update_precoreshub ;;
            "[00]"*) return ;;
            "") return ;;
        esac
    done
}

# Check if update is available (silent)
check_update_available_silent() {
    local remote_version=$(get_remote_version_hub 2>/dev/null)
    if [ "$remote_version" != "unknown" ] && [ "$remote_version" != "$VERSION" ]; then
        return 0  # Update available
    fi
    return 1  # No update
}

# Get remote version from GitHub
get_remote_version_hub() {
    local url="https://raw.githubusercontent.com/ZewK3/Precores-Software/refs/heads/main/PrecoresHub.sh"
    local version=$(curl -s "$url" 2>/dev/null | grep -m1 '^VERSION=' | cut -d'"' -f2)
    
    if [ -z "$version" ]; then
        echo "unknown"
    else
        echo "$version"
    fi
}

# Check for updates (detailed)
check_for_updates_detailed() {
    clear
    echo -e "${BLUE}[INFO]${NC} Checking for updates..."
    echo ""
    
    local current_version="$VERSION"
    local remote_version=$(get_remote_version_hub)
    
    echo -e "${CYAN}Version Information:${NC}"
    echo "  Current Version: v$current_version"
    echo "  Remote Version:  v$remote_version"
    echo ""
    
    if [ "$remote_version" == "unknown" ]; then
        echo -e "${RED}[ERROR]${NC} Could not check remote version"
        echo "Please check your internet connection"
    elif [ "$remote_version" == "$current_version" ]; then
        echo -e "${GREEN}[INFO]${NC} You are running the latest version!"
    else
        echo -e "${YELLOW}[INFO]${NC} Update available!"
        echo ""
        echo "Run option [02] to update"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Update PrecoresHub
update_precoreshub() {
    clear
    echo -e "${BLUE}[INFO]${NC} Updating PrecoresHub from GitHub..."
    echo ""
    
    local current_version="$VERSION"
    local remote_version=$(get_remote_version_hub)
    
    if [ "$remote_version" == "unknown" ]; then
        echo -e "${RED}[ERROR]${NC} Could not check remote version"
        read -p "Press Enter to continue..."
        return
    fi
    
    if [ "$remote_version" == "$current_version" ]; then
        echo -e "${GREEN}[INFO]${NC} Already running latest version (v$current_version)"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Current: v$current_version"
    echo "Remote:  v$remote_version"
    echo ""
    read -p "Update to v$remote_version? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        echo "Update cancelled"
        read -p "Press Enter to continue..."
        return
    fi
    
    GITHUB_URL="https://raw.githubusercontent.com/ZewK3/Precores-Software/refs/heads/main/PrecoresHub.sh"
    
    # Backup current version
    cp ~/PrecoresHub.sh ~/PrecoresHub.sh.bak
    
    if curl -f -s -o ~/PrecoresHub.sh.new "$GITHUB_URL"; then
        mv ~/PrecoresHub.sh.new ~/PrecoresHub.sh
        chmod +x ~/PrecoresHub.sh
        echo ""
        echo -e "${GREEN}[SUCCESS]${NC} Updated to v$remote_version!"
        echo -e "${YELLOW}[INFO]${NC} Backup saved to ~/PrecoresHub.sh.bak"
        echo -e "${YELLOW}[INFO]${NC} Please restart PrecoresHub to use new version"
        echo ""
        read -p "Restart now? (y/n): " restart
        
        if [ "$restart" == "y" ]; then
            exec ~/PrecoresHub.sh
        fi
    else
        echo ""
        echo -e "${RED}[ERROR]${NC} Failed to download update"
        mv ~/PrecoresHub.sh.bak ~/PrecoresHub.sh
        echo "Restored from backup"
    fi
    
    read -p "Press Enter to continue..."
}

# Force update (re-download)
force_update_precoreshub() {
    clear
    echo -e "${YELLOW}[WARNING]${NC} Force update will re-download PrecoresHub"
    echo ""
    read -p "Continue? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        return
    fi
    
    echo ""
    echo -e "${BLUE}[INFO]${NC} Downloading from GitHub..."
    
    GITHUB_URL="https://raw.githubusercontent.com/ZewK3/Precores-Software/refs/heads/main/PrecoresHub.sh"
    
    # Backup current version
    cp ~/PrecoresHub.sh ~/PrecoresHub.sh.bak
    
    if curl -f -s -o ~/PrecoresHub.sh.new "$GITHUB_URL"; then
        mv ~/PrecoresHub.sh.new ~/PrecoresHub.sh
        chmod +x ~/PrecoresHub.sh
        echo ""
        echo -e "${GREEN}[SUCCESS]${NC} Force update completed!"
        echo -e "${YELLOW}[INFO]${NC} Please restart PrecoresHub"
    else
        echo ""
        echo -e "${RED}[ERROR]${NC} Failed to download"
        mv ~/PrecoresHub.sh.bak ~/PrecoresHub.sh
    fi
    
    read -p "Press Enter to continue..."
}

# View changelog
view_changelog() {
    clear
    echo -e "${CYAN}Changelog${NC}"
    echo ""
    echo "View changelog on GitHub:"
    echo "https://github.com/ZewK3/Precores-Software/commits/main/PrecoresHub.sh"
    echo ""
    read -p "Press Enter to continue..."
}

################################################################################
# SYSTEMMANAGER MODULE
################################################################################

show_systemmanager_menu() {
    while true; do
        print_header
        echo -e "${YELLOW}SystemManager - Monitor & Updates${NC}"
        echo ""
        
        local choice=$(cat <<EOF | fzf --ansi --reverse --height=80% --border=rounded --prompt="> " --header="╔══════════════════════════════════════════════════════════╗
║       SYSTEMMANAGER - MONITOR & UPDATES              ║
╚══════════════════════════════════════════════════════════╝" --color="fg:#ffffff,bg:#1e1e2e,hl:#89b4fa,fg+:#cdd6f4,bg+:#313244,hl+:#89b4fa,info:#cba6f7,prompt:#89b4fa,pointer:#89b4fa,marker:#a6e3a1,spinner:#f5e0dc,header:#89b4fa"
[01]  Dashboard            - Real-time system monitor
[02]  Process Manager      - Kill/nice processes
[03]  Service Manager      - Start/stop services
[10] Update System        - Update all packages
[11] Check Updates        - Check for updates
[20] Show Versions        - Installed software versions
[21] System Info          - Detailed system info
[00]  Back
EOF
)
        
        case "$choice" in
            "[01]"*) show_dashboard ;;
            "[02]"*) process_manager ;;
            "[03]"*) service_manager ;;
            "[10]"*) update_system ;;
            "[11]"*) check_updates ;;
            "[20]"*) show_versions ;;
            "[21]"*) show_system_info ;;
            "[00]"*) return ;;
            "") return ;;
        esac
    done
}

show_dashboard() {
    clear
    
    # Get system info
    hostname=$(cat /etc/hostname 2>/dev/null || uname -n)
    kernel=$(uname -r)
    uptime=$(uptime -p | sed 's/up //')
    
    # Get CPU usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    cpu_usage_int=${cpu_usage%.*}
    
    # Get memory info
    mem_total=$(free -m | awk 'NR==2{print $2}')
    mem_used=$(free -m | awk 'NR==2{print $3}')
    mem_percent=$((mem_used * 100 / mem_total))
    
    # Get disk info
    disk_usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
    disk_used=$(df -h / | awk 'NR==2{print $3}')
    disk_total=$(df -h / | awk 'NR==2{print $2}')
    
    # Get CPU temp (if available)
    if command -v sensors &> /dev/null; then
        cpu_temp=$(sensors 2>/dev/null | grep -i 'Core 0' | awk '{print $3}' | sed 's/+//;s/°C//')
        if [ -z "$cpu_temp" ]; then
            cpu_temp="N/A"
        fi
    else
        cpu_temp="N/A"
    fi
    
    # Function to create progress bar
    create_bar() {
        local percent=$1
        local width=20
        local filled=$((percent * width / 100))
        local empty=$((width - filled))
        
        printf "["
        printf "%${filled}s" | tr ' ' '█'
        printf "%${empty}s" | tr ' ' '░'
        printf "]"
    }
    
    # Display dashboard
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}           SYSTEM DASHBOARD - REAL-TIME              ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BOLD} SYSTEM INFORMATION${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  Hostname:  ${CYAN}$hostname${NC}"
    echo -e "  Kernel:    ${CYAN}$kernel${NC}"
    echo -e "  Uptime:    ${CYAN}$uptime${NC}"
    echo -e "  Distro:    ${CYAN}$DISTRO_NAME${NC}"
    echo ""
    
    echo -e "${BOLD} CPU USAGE${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$cpu_usage_int" -lt 50 ]; then
        color="${GREEN}"
    elif [ "$cpu_usage_int" -lt 80 ]; then
        color="${YELLOW}"
    else
        color="${RED}"
    fi
    echo -e "  ${color}$(create_bar $cpu_usage_int) ${cpu_usage_int}%${NC}  Temp: ${cpu_temp}°C"
    echo ""
    
    echo -e "${BOLD} MEMORY USAGE${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$mem_percent" -lt 60 ]; then
        color="${GREEN}"
    elif [ "$mem_percent" -lt 85 ]; then
        color="${YELLOW}"
    else
        color="${RED}"
    fi
    echo -e "  ${color}$(create_bar $mem_percent) ${mem_percent}%${NC}  ${mem_used}MB / ${mem_total}MB"
    echo ""
    
    echo -e "${BOLD} DISK USAGE${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$disk_usage" -lt 70 ]; then
        color="${GREEN}"
    elif [ "$disk_usage" -lt 90 ]; then
        color="${YELLOW}"
    else
        color="${RED}"
    fi
    echo -e "  ${color}$(create_bar $disk_usage) ${disk_usage}%${NC}  ${disk_used} / ${disk_total}"
    echo ""
    
    echo -e "${BOLD} TOP PROCESSES (by CPU)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ps aux --sort=-%cpu | awk 'NR>1 && NR<=6 {printf "  %-20s %5s%%  %6s\n", $11, $3, $4}' | head -5
    echo ""
    
    echo -e "${BOLD} NETWORK${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if command -v ip &> /dev/null; then
        interface=$(ip route | grep default | awk '{print $5}' | head -1)
        ip_addr=$(ip -4 addr show $interface 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1)
        echo -e "  Interface: ${CYAN}$interface${NC}"
        echo -e "  IP:        ${CYAN}$ip_addr${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}Press Enter to continue or 'r' to refresh...${NC}"
    read -t 5 -n 1 key
    
    if [ "$key" == "r" ]; then
        show_dashboard
    fi
}

# Process Manager
process_manager() {
    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}${BOLD}               PROCESS MANAGER                        ${NC}${CYAN}║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${BOLD}Top 15 Processes (by CPU usage)${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ps aux --sort=-%cpu | awk 'NR==1 {printf "%-6s %-10s %5s %6s %s\n", "PID", "USER", "CPU%", "MEM%", "COMMAND"} NR>1 && NR<=16 {printf "%-6s %-10s %5s %6s %s\n", $2, $1, $3, $4, $11}' | head -16
        echo ""
        
        echo -e "${YELLOW}Actions:${NC}"
        echo "[01] Kill Process (by PID)"
        echo "[02] Kill Process (by Name)"
        echo "[03] Change Priority (renice)"
        echo "[04] Show Process Tree"
        echo "[05] Refresh"
        echo "[00] Back"
        echo ""
        read -p "Choice: " choice
        
        case "$choice" in
            1)
                read -p "Enter PID to kill: " pid
                if [ -n "$pid" ]; then
                    kill -9 "$pid" 2>/dev/null && echo -e "${GREEN}Process killed${NC}" || echo -e "${RED}Failed${NC}"
                    sleep 2
                fi
                ;;
            2)
                read -p "Enter process name: " pname
                if [ -n "$pname" ]; then
                    pkill -9 "$pname" && echo -e "${GREEN}Processes killed${NC}" || echo -e "${RED}Failed${NC}"
                    sleep 2
                fi
                ;;
            3)
                read -p "Enter PID: " pid
                read -p "Enter priority (-20 to 19, lower = higher priority): " priority
                if [ -n "$pid" ] && [ -n "$priority" ]; then
                    sudo renice "$priority" -p "$pid" && echo -e "${GREEN}Priority changed${NC}" || echo -e "${RED}Failed${NC}"
                    sleep 2
                fi
                ;;
            4)
                clear
                if command -v pstree &> /dev/null; then
                    pstree -p | less
                else
                    ps auxf | less
                fi
                ;;
            5)
                continue
                ;;
            0)
                return
                ;;
        esac
    done
}

# Service Manager
service_manager() {
    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}${BOLD}                SERVICE MANAGER                        ${NC}${CYAN}║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${BOLD}System Services Status${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Show common services
        services=("NetworkManager" "sshd" "docker" "ufw" "lightdm" "bluetooth" "cups")
        
        for service in "${services[@]}"; do
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                status="${GREEN}●${NC} active"
            else
                status="${RED}●${NC} inactive"
            fi
            
            if systemctl is-enabled --quiet "$service" 2>/dev/null; then
                enabled="${GREEN}enabled${NC}"
            else
                enabled="${YELLOW}disabled${NC}"
            fi
            
            printf "%-20s %s  %s\n" "$service" "$status" "$enabled"
        done
        
        echo ""
        echo -e "${YELLOW}Actions:${NC}"
        echo "[01] Start Service"
        echo "[02] Stop Service"
        echo "[03] Restart Service"
        echo "[04] Enable Service (auto-start)"
        echo "[05] Disable Service"
        echo "[06] Show Service Status"
        echo "[07] List All Services"
        echo "[08] Show Failed Services"
        echo "[00] Back"
        echo ""
        read -p "Choice: " choice
        
        case "$choice" in
            1)
                read -p "Enter service name: " service
                if [ -n "$service" ]; then
                    sudo systemctl start "$service" && echo -e "${GREEN}Service started${NC}" || echo -e "${RED}Failed${NC}"
                    sleep 2
                fi
                ;;
            2)
                read -p "Enter service name: " service
                if [ -n "$service" ]; then
                    sudo systemctl stop "$service" && echo -e "${GREEN}Service stopped${NC}" || echo -e "${RED}Failed${NC}"
                    sleep 2
                fi
                ;;
            3)
                read -p "Enter service name: " service
                if [ -n "$service" ]; then
                    sudo systemctl restart "$service" && echo -e "${GREEN}Service restarted${NC}" || echo -e "${RED}Failed${NC}"
                    sleep 2
                fi
                ;;
            4)
                read -p "Enter service name: " service
                if [ -n "$service" ]; then
                    sudo systemctl enable "$service" && echo -e "${GREEN}Service enabled${NC}" || echo -e "${RED}Failed${NC}"
                    sleep 2
                fi
                ;;
            5)
                read -p "Enter service name: " service
                if [ -n "$service" ]; then
                    sudo systemctl disable "$service" && echo -e "${GREEN}Service disabled${NC}" || echo -e "${RED}Failed${NC}"
                    sleep 2
                fi
                ;;
            6)
                read -p "Enter service name: " service
                if [ -n "$service" ]; then
                    systemctl status "$service" | less
                fi
                ;;
            7)
                systemctl list-units --type=service | less
                ;;
            8)
                systemctl --failed | less
                ;;
            0)
                return
                ;;
        esac
    done
}

check_updates() {
    clear
    echo -e "${BLUE}[INFO]${NC} Checking for updates..."
    echo ""
    
    if [ "$PKG_MANAGER" == "pacman" ]; then
        updates=$(checkupdates 2>/dev/null | wc -l)
        echo "System Updates: $updates"
        
        if command -v yay &> /dev/null; then
            aur_updates=$(yay -Qua 2>/dev/null | wc -l)
            echo "AUR Updates: $aur_updates"
        fi
    elif [ "$PKG_MANAGER" == "apt" ]; then
        sudo apt update > /dev/null 2>&1
        updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
        echo "System Updates: $updates"
    else
        echo "Check updates manually for your distro"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

show_versions() {
    clear
    echo -e "${CYAN}Installed Versions${NC}"
    echo ""
    echo -e "${BOLD}System:${NC}"
    echo "  Kernel: $(uname -r)"
    echo "  Package Manager: $PKG_MANAGER"
    echo ""
    read -p "Press Enter to continue..."
}

################################################################################
# SYSTEM INFORMATION
################################################################################

show_system_info() {
    clear
    print_header
    echo -e "${CYAN}System Information${NC}"
    echo ""
    echo -e "${BOLD}Hardware:${NC}"
    echo "  Hostname: $(cat /etc/hostname 2>/dev/null || uname -n)"
    echo "  Kernel: $(uname -r)"
    echo "  Uptime: $(uptime -p | sed 's/up //')"
    echo "  CPU: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)"
    echo "  RAM: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
    echo "  Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
    echo ""
    echo -e "${BOLD}Network:${NC}"
    echo "  Interface: $(ip route | grep default | awk '{print $5}')"
    echo "  IP: $(ip -4 addr show $(ip route | grep default | awk '{print $5}') 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1)"
    echo ""
    read -p "Press Enter to continue..."
}

################################################################################
# SETTINGS
################################################################################

show_settings_menu() {
    while true; do
        print_header
        echo -e "${MAGENTA}Settings & Configuration${NC}"
        echo ""
        
        local choice=$(cat <<EOF | fzf --ansi --reverse --height=60% --border=rounded --prompt="> " --header="╔══════════════════════════════════════════════════════════╗
║           SETTINGS & CONFIGURATION                   ║
╚══════════════════════════════════════════════════════════╝" --color="fg:#ffffff,bg:#1e1e2e,hl:#a6e3a1,fg+:#cdd6f4,bg+:#313244,hl+:#a6e3a1,info:#cba6f7,prompt:#a6e3a1,pointer:#a6e3a1,marker:#a6e3a1,spinner:#f5e0dc,header:#a6e3a1"
[01] Update Script         - Update from GitHub
[02] Auto-Start            - Configure auto-start
[03] About                 - About PrecoresHub
[00] Back
EOF
)
        
        case "$choice" in
            "[01]"*) update_script ;;
            "[02]"*) configure_autostart ;;
            "[03]"*) show_about ;;
            "[00]"*) return ;;
            "") return ;;
        esac
    done
}

update_script() {
    clear
    echo -e "${BLUE}[INFO]${NC} Updating PrecoresHub from GitHub..."
    
    GITHUB_URL="https://raw.githubusercontent.com/ZewK3/Precores-Software/refs/heads/main/PrecoresHub.sh"
    
    if curl -f -s -o ~/PrecoresHub.sh.new "$GITHUB_URL"; then
        mv ~/PrecoresHub.sh.new ~/PrecoresHub.sh
        chmod +x ~/PrecoresHub.sh
        echo -e "${GREEN}[SUCCESS]${NC} Script updated!"
        echo -e "${YELLOW}[INFO]${NC} Please restart the script"
    else
        echo -e "${RED}[ERROR]${NC} Failed to update"
    fi
    
    read -p "Press Enter to continue..."
}

configure_autostart() {
    clear
    echo -e "${BLUE}[INFO]${NC} Configure Auto-Start"
    echo ""
    read -p "Launch Precores Hub on login? (y/n): " confirm
    
    if [ "$confirm" == "y" ]; then
        mkdir -p ~/.config/autostart
        cat > ~/.config/autostart/precores-hub.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Precores Hub
Exec=$HOME/PrecoresHub.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
        echo -e "${GREEN}[SUCCESS]${NC} Auto-start enabled!"
    else
        rm -f ~/.config/autostart/precores-hub.desktop
        echo -e "${GREEN}[SUCCESS]${NC} Auto-start disabled"
    fi
    
    read -p "Press Enter to continue..."
}

show_about() {
    clear
    print_header
    echo -e "${CYAN}About Precores Hub${NC}"
    echo ""
    echo -e "${BOLD}Version:${NC} $VERSION"
    echo -e "${BOLD}Description:${NC} All-in-One Control Center"
    echo ""
    echo -e "${BOLD}Modules:${NC}"
    echo "  - QuickInstall: App installer"
    echo "  - QuickFix: System repair"
    echo "  - SystemManager: Monitoring & updates"
    echo ""
    echo -e "${BOLD}Created by:${NC} ZewK3"
    echo -e "${BOLD}GitHub:${NC} ZewK3/Precores-Software"
    echo -e "${BOLD}License:${NC} MIT"
    echo ""
    read -p "Press Enter to continue..."
}

################################################################################
# EXIT
################################################################################

exit_hub() {
    clear
    echo -e "${GREEN}Thank you for using Precores Hub!${NC}"
    echo ""
    exit 0
}

################################################################################
# MAIN
################################################################################

main() {
    check_dependencies
    show_main_menu
}

# Run
main "$@"
