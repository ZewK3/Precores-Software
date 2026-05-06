#!/bin/bash
################################################################################
# Arch Linux Ultra-Optimized Auto-Install Script
# 
# Features:
# - 100% Automated (no user input required)
# - Ultra-lightweight (minimal RAM usage)
# - Silent installation with progress bar
# - Optimized for performance
# - Removes unnecessary services and packages
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

################################################################################
# Configuration
################################################################################

# System Configuration
HOSTNAME="${HOSTNAME:-precores}"
USERNAME="${USERNAME:-pcl}"
PASSWORD="${PASSWORD:-123123}"
TIMEZONE="${TIMEZONE:-Asia/Ho_Chi_Minh}"
LOCALE="${LOCALE:-en_US.UTF-8}"

# Disk Configuration (auto-detect)
DISK="${DISK:-}"
BOOT_MODE=""

# Installation Options
INSTALL_GUI="${INSTALL_GUI:-true}"
INSTALL_SSH="${INSTALL_SSH:-true}"

# Silent mode (hide all logs except errors)
SILENT_MODE=true
LOG_FILE="/tmp/arch-install.log"

################################################################################
# Progress Bar System with Beautiful UI
################################################################################

TOTAL_STEPS=14
CURRENT_STEP=0
PROGRESS_BAR_WIDTH=56  # Optimized for logo alignment

# Colors for progress bar
COLOR_RESET='\033[0m'
COLOR_BLUE='\033[1;34m'
COLOR_GREEN='\033[1;32m'
COLOR_CYAN='\033[1;36m'
COLOR_YELLOW='\033[1;33m'
COLOR_WHITE='\033[1;37m'
COLOR_GRAY='\033[0;37m'

# Initialize progress with beautiful header
init_progress() {
    clear
    echo -e "${COLOR_CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                       ║"
    echo "║   ██████╗ ██████╗ ███████╗ ██████╗ ██████╗ ██████╗ ███████╗███████╗   ║"
    echo "║   ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝   ║"
    echo "║   ██████╔╝██████╔╝█████╗  ██║     ██║   ██║██████╔╝█████╗  ███████╗   ║"
    echo "║   ██╔═══╝ ██╔══██╗██╔══╝  ██║     ██║   ██║██╔══██╗██╔══╝  ╚════██║   ║"
    echo "║   ██║     ██║  ██║███████╗╚██████╗╚██████╔╝██║  ██║███████╗███████║   ║"
    echo "║   ╚═╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝   ║"
    echo "║                                                                       ║"
    echo "║              Ultra-Optimized Installation - Silent Mode               ║"
    echo "║                                                                       ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GRAY}Starting installation... Please wait...${COLOR_RESET}"
    echo ""
    > "$LOG_FILE"  # Clear log file
}

# Update progress bar with beautiful colors and animation
update_progress() {
    local step_name="$1"
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((percent * PROGRESS_BAR_WIDTH / 100))
    local empty=$((PROGRESS_BAR_WIDTH - filled))
    
    # Clear screen and redraw header
    clear
    echo -e "${COLOR_CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                       ║"
    echo "║   ██████╗ ██████╗ ███████╗ ██████╗ ██████╗ ██████╗ ███████╗███████╗   ║"
    echo "║   ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝   ║"
    echo "║   ██████╔╝██████╔╝█████╗  ██║     ██║   ██║██████╔╝█████╗  ███████╗   ║"
    echo "║   ██╔═══╝ ██╔══██╗██╔══╝  ██║     ██║   ██║██╔══██╗██╔══╝  ╚════██║   ║"
    echo "║   ██║     ██║  ██║███████╗╚██████╗╚██████╔╝██║  ██║███████╗███████║   ║"
    echo "║   ╚═╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝   ║"
    echo "║                                                                       ║"
    echo "║              Ultra-Optimized Installation - Silent Mode               ║"
    echo "║                                                                       ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${COLOR_RESET}"
    echo ""
    
    # Draw progress bar
    printf "${COLOR_WHITE}Progress: [${COLOR_RESET}"
    printf "${COLOR_CYAN}"
    for ((i=0; i<filled; i++)); do
        printf "█"
    done
    printf "${COLOR_GRAY}"
    for ((i=0; i<empty; i++)); do
        printf "░"
    done
    printf "${COLOR_RESET}${COLOR_WHITE}] %3d%%${COLOR_RESET}\n" "$percent"
    echo ""
    printf "${COLOR_CYAN}▸ %s${COLOR_RESET}\n" "$step_name"
}

# Log to file (silent)
log_silent() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Show error and exit
show_error() {
    echo ""
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                         ERROR OCCURRED                         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Error: $1"
    echo ""
    echo "Last 20 lines of log:"
    echo "─────────────────────────────────────────────────────────────────"
    tail -20 "$LOG_FILE"
    echo "─────────────────────────────────────────────────────────────────"
    echo ""
    echo "Full log: $LOG_FILE"
    exit 1
}

################################################################################
# Pre-flight Checks
################################################################################

preflight_checks() {
    update_progress "Pre-flight checks"
    
    # Check root
    if [[ $EUID -ne 0 ]]; then
        show_error "This script must be run as root"
    fi
    
    # Check internet
    if ! ping -c 1 archlinux.org &>/dev/null; then
        show_error "No internet connection"
    fi
    log_silent "Internet connection OK"
    
    # Detect boot mode
    if [[ -d /sys/firmware/efi/efivars ]]; then
        BOOT_MODE="UEFI"
    else
        BOOT_MODE="BIOS"
    fi
    log_silent "Boot mode: $BOOT_MODE"
    
    # Auto-detect disk
    if [[ -z "$DISK" ]]; then
        DISK="/dev/$(lsblk -d -o NAME,SIZE,TYPE | grep disk | sort -k2 -h | tail -1 | awk '{print $1}')"
    fi
    log_silent "Installation disk: $DISK"
}

################################################################################
# Disk Partitioning
################################################################################

partition_disk() {
    update_progress "Partitioning disk"
    
    {
        wipefs -a "$DISK"
        
        if [[ "$BOOT_MODE" == "UEFI" ]]; then
            parted -s "$DISK" mklabel gpt
            parted -s "$DISK" mkpart primary fat32 1MiB 512MiB
            parted -s "$DISK" set 1 esp on
            parted -s "$DISK" mkpart primary ext4 512MiB 100%
            
            BOOT_PART="${DISK}1"
            ROOT_PART="${DISK}2"
        else
            parted -s "$DISK" mklabel msdos
            parted -s "$DISK" mkpart primary ext4 1MiB 100%
            
            ROOT_PART="${DISK}1"
        fi
        
        partprobe "$DISK"
        sleep 2
    } >> "$LOG_FILE" 2>&1 || show_error "Disk partitioning failed"
    
    log_silent "Partitioning complete"
}

################################################################################
# Format Partitions
################################################################################

format_partitions() {
    update_progress "Formatting partitions"
    
    {
        if [[ "$BOOT_MODE" == "UEFI" ]]; then
            mkfs.fat -F32 "$BOOT_PART"
        fi
        
        mkfs.ext4 -F "$ROOT_PART"
    } >> "$LOG_FILE" 2>&1 || show_error "Formatting failed"
    
    log_silent "Formatting complete"
}

################################################################################
# Mount Partitions
################################################################################

mount_partitions() {
    update_progress "Mounting partitions"
    
    {
        mount "$ROOT_PART" /mnt
        
        if [[ "$BOOT_MODE" == "UEFI" ]]; then
            mkdir -p /mnt/boot
            mount "$BOOT_PART" /mnt/boot
        fi
    } >> "$LOG_FILE" 2>&1 || show_error "Mounting failed"
    
    log_silent "Mounting complete"
}

################################################################################
# Install Base System (Ultra-Minimal)
################################################################################

install_base() {
    update_progress "Installing base system"
    
    # Ultra-minimal package list (only essentials)
    local base_packages="base linux linux-firmware"
    
    # Add only necessary packages
    base_packages="$base_packages nano sudo networkmanager"
    
    # Add zram for memory optimization
    base_packages="$base_packages zram-generator"
    
    {
        pacstrap /mnt $base_packages
        genfstab -U /mnt >> /mnt/etc/fstab
    } >> "$LOG_FILE" 2>&1 || show_error "Base installation failed"
    
    log_silent "Base system installed"
}

################################################################################
# System Configuration
################################################################################

configure_system() {
    update_progress "Configuring system"
    
    {
        # Timezone
        arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
        arch-chroot /mnt hwclock --systohc
        
        # Locale
        arch-chroot /mnt sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
        arch-chroot /mnt locale-gen
        echo "LANG=$LOCALE" > /mnt/etc/locale.conf
        
        # Hostname
        echo "$HOSTNAME" > /mnt/etc/hostname
        cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
        
        # ZRAM configuration (compressed RAM for better memory usage)
        cat > /mnt/etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF
        
        # Ultra-aggressive memory optimization
        cat > /mnt/etc/sysctl.d/99-vm-ultra.conf <<EOF
# Ultra-aggressive memory optimization
vm.swappiness = 5
vm.vfs_cache_pressure = 30
vm.dirty_ratio = 5
vm.dirty_background_ratio = 3
vm.min_free_kbytes = 8192
vm.overcommit_memory = 1
vm.overcommit_ratio = 80
fs.file-max = 2097152

# Disable unnecessary features
kernel.nmi_watchdog = 0
kernel.printk = 3 3 3 3
EOF
        
    } >> "$LOG_FILE" 2>&1 || show_error "System configuration failed"
    
    log_silent "System configured"
}

################################################################################
# User Configuration
################################################################################

configure_users() {
    update_progress "Configuring users"
    
    {
        echo "root:$PASSWORD" | arch-chroot /mnt chpasswd
        arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$USERNAME"
        echo "$USERNAME:$PASSWORD" | arch-chroot /mnt chpasswd
        arch-chroot /mnt sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    } >> "$LOG_FILE" 2>&1 || show_error "User configuration failed"
    
    log_silent "Users configured"
}

################################################################################
# Install Bootloader
################################################################################

install_bootloader() {
    update_progress "Installing bootloader"
    
    {
        arch-chroot /mnt pacman -S --noconfirm grub
        
        if [[ "$BOOT_MODE" == "UEFI" ]]; then
            arch-chroot /mnt pacman -S --noconfirm efibootmgr
            arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
        else
            arch-chroot /mnt grub-install --target=i386-pc "$DISK"
        fi
        
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    } >> "$LOG_FILE" 2>&1 || show_error "Bootloader installation failed"
    
    log_silent "Bootloader installed"
}

################################################################################
# Network Configuration
################################################################################

install_network() {
    update_progress "Configuring network"
    
    {
        arch-chroot /mnt systemctl enable NetworkManager
        
        if [[ "$INSTALL_SSH" == "true" ]]; then
            arch-chroot /mnt pacman -S --noconfirm openssh
            arch-chroot /mnt systemctl enable sshd
        fi
    } >> "$LOG_FILE" 2>&1 || show_error "Network configuration failed"
    
    log_silent "Network configured"
}

################################################################################
# Install Minimal GUI (Ultra-Lightweight XFCE)
################################################################################

install_gui() {
    if [[ "$INSTALL_GUI" != "true" ]]; then
        return
    fi
    
    update_progress "Installing minimal GUI"
    
    {
        # Minimal X server (no unnecessary drivers)
        arch-chroot /mnt pacman -S --noconfirm xorg-server xorg-xinit
        
        # Ultra-minimal XFCE (only core components)
        arch-chroot /mnt pacman -S --noconfirm xfce4 xfce4-terminal thunar
        
        # Lightweight display manager
        arch-chroot /mnt pacman -S --noconfirm lightdm lightdm-gtk-greeter
        
        # Auto-login configuration
        mkdir -p /mnt/etc/lightdm/lightdm.conf.d
        cat > /mnt/etc/lightdm/lightdm.conf.d/50-autologin.conf <<EOF
[Seat:*]
autologin-user=$USERNAME
autologin-user-timeout=0
autologin-session=xfce
EOF
        
        arch-chroot /mnt groupadd -r autologin || true
        arch-chroot /mnt gpasswd -a $USERNAME autologin
        
        cat > /mnt/etc/pam.d/lightdm-autologin <<EOF
#%PAM-1.0
auth        sufficient  pam_succeed_if.so user ingroup autologin
auth        required    pam_permit.so
account     include     system-local-login
password    include     system-local-login
session     include     system-local-login
EOF
        
        # Disable compositor for better performance
        mkdir -p /mnt/home/$USERNAME/.config/xfce4/xfconf/xfce-perchannel-xml
        cat > /mnt/home/$USERNAME/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="vblank_mode" type="string" value="off"/>
  </property>
</channel>
EOF
        
        chown -R 1000:1000 /mnt/home/$USERNAME/.config
        arch-chroot /mnt systemctl enable lightdm
        
    } >> "$LOG_FILE" 2>&1 || show_error "GUI installation failed"
    
    log_silent "Minimal GUI installed"
}

################################################################################
# Install Essential Tools
################################################################################

install_essentials() {
    update_progress "Installing essential tools"
    
    {
        # Build tools
        arch-chroot /mnt pacman -S --noconfirm wget curl git base-devel
        
        # Development tools
        arch-chroot /mnt pacman -S --noconfirm python python-pip nodejs npm
        
        # Minimal browser (Firefox is lighter than Chrome)
        arch-chroot /mnt pacman -S --noconfirm firefox
        
        # Essential utilities
        arch-chroot /mnt pacman -S --noconfirm htop fzf jq fastfetch
        
    } >> "$LOG_FILE" 2>&1 || show_error "Essential tools installation failed"
    
    log_silent "Essential tools installed"
}

################################################################################
# Ultra-Aggressive Optimization
################################################################################

optimize_system() {
    update_progress "Applying ultra optimizations"
    
    {
        # Disable PC speaker
        echo "blacklist pcspkr" > /mnt/etc/modprobe.d/nobeep.conf
        
        # Disable unnecessary kernel modules
        cat > /mnt/etc/modprobe.d/blacklist-bloat.conf <<EOF
# Disable unnecessary modules for RAM optimization
blacklist bluetooth
blacklist btusb
blacklist uvcvideo
blacklist snd_pcsp
blacklist pcspkr
EOF
        
        # Faster boot configuration
        mkdir -p /mnt/etc/systemd/system.conf.d
        cat > /mnt/etc/systemd/system.conf.d/timeout.conf <<EOF
[Manager]
DefaultTimeoutStartSec=5s
DefaultTimeoutStopSec=5s
EOF
        
        # Network optimizations
        cat > /mnt/etc/sysctl.d/99-network.conf <<EOF
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1
EOF
        
        # I/O scheduler optimization
        cat > /mnt/etc/udev/rules.d/60-ioschedulers.rules <<EOF
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF
        
        # Transparent huge pages
        cat > /mnt/etc/tmpfiles.d/thp.conf <<EOF
w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise
w /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise
EOF
        
        # Add noatime to fstab for better disk performance
        arch-chroot /mnt sed -i 's/relatime/noatime/' /etc/fstab || true
        
    } >> "$LOG_FILE" 2>&1 || show_error "Optimization failed"
    
    log_silent "Ultra optimizations applied"
}

################################################################################
# Disable Unnecessary Services
################################################################################

disable_bloat_services() {
    update_progress "Disabling unnecessary services"
    
    {
        # Disable services that consume RAM but aren't needed
        local services_to_disable=(
            "bluetooth.service"
            "ModemManager.service"
            "avahi-daemon.service"
            "cups.service"
            "cups-browsed.service"
        )
        
        for service in "${services_to_disable[@]}"; do
            arch-chroot /mnt systemctl disable "$service" 2>/dev/null || true
            arch-chroot /mnt systemctl mask "$service" 2>/dev/null || true
        done
        
    } >> "$LOG_FILE" 2>&1
    
    log_silent "Unnecessary services disabled"
}

################################################################################
# Install AUR Helper (yay)
################################################################################

install_aur_helper() {
    update_progress "Installing AUR helper"
    
    {
        echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" | arch-chroot /mnt tee /etc/sudoers.d/temp_nopasswd > /dev/null
        
        arch-chroot /mnt bash -c "cd /tmp && \
            sudo -u $USERNAME git clone https://aur.archlinux.org/yay.git 2>/dev/null && \
            cd yay && \
            sudo -u $USERNAME makepkg -si --noconfirm" 2>/dev/null || true
        
        arch-chroot /mnt rm -f /etc/sudoers.d/temp_nopasswd
        
    } >> "$LOG_FILE" 2>&1
    
    log_silent "AUR helper installed"
}

################################################################################
# Install Firewall
################################################################################

install_firewall() {
    update_progress "Installing firewall"
    
    {
        arch-chroot /mnt pacman -S --noconfirm ufw
        arch-chroot /mnt ufw default deny incoming
        arch-chroot /mnt ufw default allow outgoing
        
        if [[ "$INSTALL_SSH" == "true" ]]; then
            arch-chroot /mnt ufw allow ssh
        fi
        
        arch-chroot /mnt ufw --force enable
        arch-chroot /mnt systemctl enable ufw
        
    } >> "$LOG_FILE" 2>&1 || show_error "Firewall installation failed"
    
    log_silent "Firewall configured"
}

################################################################################
# Download and Install PrecoresHub
################################################################################

download_precoreshub() {
    update_progress "Installing PrecoresHub"
    
    {
        # Download PrecoresHub.tar.gz
        echo "[INFO] Downloading PrecoresHub from GitHub..."
        arch-chroot /mnt bash -c "cd /tmp && curl -L -o PrecoresHub.tar.gz https://github.com/ZewK3/Precores-Software/raw/refs/heads/main/PrecoresHub.tar.gz"
        
        if [ ! -f /mnt/tmp/PrecoresHub.tar.gz ]; then
            echo "[ERROR] Failed to download PrecoresHub.tar.gz"
            return 1
        fi
        
        echo "[INFO] Download successful, extracting..."
        
        # Extract archive
        arch-chroot /mnt bash -c "cd /tmp && tar -xzf PrecoresHub.tar.gz"
        
        if [ ! -d /mnt/tmp/PrecoresHub ]; then
            echo "[ERROR] Failed to extract PrecoresHub archive"
            return 1
        fi
        
        echo "[INFO] Extraction successful, installing to /usr/local/..."
        
        # Install to /usr/local/PrecoresHub (system-wide installation)
        arch-chroot /mnt bash -c "cp -r /tmp/PrecoresHub /usr/local/"
        
        if [ ! -d /mnt/usr/local/PrecoresHub ]; then
            echo "[ERROR] Failed to copy PrecoresHub to /usr/local/"
            return 1
        fi
        
        echo "[INFO] Setting proper permissions..."
        
        # Set ownership to root
        arch-chroot /mnt bash -c "chown -R root:root /usr/local/PrecoresHub"
        
        # Set proper permissions (755 = rwxr-xr-x - readable and executable by all)
        # Main script needs to be readable and executable
        arch-chroot /mnt bash -c "chmod 755 /usr/local/PrecoresHub/PrecoresHub.sh"
        
        # Library files need to be readable and executable
        arch-chroot /mnt bash -c "chmod 755 /usr/local/PrecoresHub/lib/*.sh 2>/dev/null || true"
        
        # Config and lang files need to be readable
        arch-chroot /mnt bash -c "chmod 644 /usr/local/PrecoresHub/config/*.json 2>/dev/null || true"
        arch-chroot /mnt bash -c "chmod 644 /usr/local/PrecoresHub/lang/*.json 2>/dev/null || true"
        
        # Directories need to be accessible
        arch-chroot /mnt bash -c "chmod 755 /usr/local/PrecoresHub"
        arch-chroot /mnt bash -c "chmod 755 /usr/local/PrecoresHub/lib 2>/dev/null || true"
        arch-chroot /mnt bash -c "chmod 755 /usr/local/PrecoresHub/config 2>/dev/null || true"
        arch-chroot /mnt bash -c "chmod 755 /usr/local/PrecoresHub/lang 2>/dev/null || true"
        arch-chroot /mnt bash -c "chmod 755 /usr/local/PrecoresHub/plugins 2>/dev/null || true"
        arch-chroot /mnt bash -c "chmod 755 /usr/local/PrecoresHub/docs 2>/dev/null || true"
        
        echo "[INFO] Creating user config directories..."
        
        # Create user config directory structure
        arch-chroot /mnt bash -c "mkdir -p /home/$USERNAME/.config/precoreshub"
        arch-chroot /mnt bash -c "mkdir -p /home/$USERNAME/.cache/precoreshub"
        arch-chroot /mnt bash -c "mkdir -p /home/$USERNAME/.local/share/precoreshub"
        arch-chroot /mnt bash -c "chown -R $USERNAME:$USERNAME /home/$USERNAME/.config/precoreshub"
        arch-chroot /mnt bash -c "chown -R $USERNAME:$USERNAME /home/$USERNAME/.cache/precoreshub"
        arch-chroot /mnt bash -c "chown -R $USERNAME:$USERNAME /home/$USERNAME/.local/share/precoreshub"
        
        # Create skeleton directories for future users
        arch-chroot /mnt bash -c "mkdir -p /etc/skel/.config/precoreshub"
        arch-chroot /mnt bash -c "mkdir -p /etc/skel/.cache/precoreshub"
        arch-chroot /mnt bash -c "mkdir -p /etc/skel/.local/share/precoreshub"
        
        echo "[INFO] Creating system-wide launcher..."
        
        # Create system-wide launcher script with proper error handling
        cat > /mnt/usr/local/bin/precoreshub <<'LAUNCHER_EOF'
#!/bin/bash
# PrecoresHub Launcher Script

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Error: Do not run PrecoresHub as root"
    echo "Please run as a regular user"
    exit 1
fi

# Check dependencies
if ! command -v fzf &>/dev/null; then
    echo "Error: fzf is not installed"
    echo "Please install fzf: sudo pacman -S fzf"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is not installed"
    echo "Please install jq: sudo pacman -S jq"
    exit 1
fi

# Set SCRIPT_DIR for PrecoresHub
export SCRIPT_DIR="/usr/local/PrecoresHub"

# Change to PrecoresHub directory and run
cd "$SCRIPT_DIR" && exec bash "$SCRIPT_DIR/PrecoresHub.sh" "$@"
LAUNCHER_EOF
        arch-chroot /mnt bash -c "chmod 755 /usr/local/bin/precoreshub"
        
        echo "[INFO] Creating desktop icon with fixed terminal size..."
        
        # Download PrecoresHub icon (if available) or create a placeholder
        arch-chroot /mnt bash -c "mkdir -p /usr/share/pixmaps"
        
        # Create desktop entry with fixed terminal size (67x25 - perfect fit)
        mkdir -p /mnt/etc/skel/Desktop
        mkdir -p /mnt/home/$USERNAME/Desktop
        
        cat > /mnt/usr/share/applications/precoreshub.desktop <<'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=PrecoresHub
Comment=Precores Software Hub - Package Manager
Exec=xfce4-terminal --geometry=67x25 --title="PrecoresHub" -e "bash -c 'precoreshub; exec bash'"
Icon=utilities-terminal
Terminal=false
Categories=System;PackageManager;
StartupNotify=true
DESKTOP_EOF
        
        # Copy desktop file to user desktop
        arch-chroot /mnt bash -c "cp /usr/share/applications/precoreshub.desktop /home/$USERNAME/Desktop/"
        arch-chroot /mnt bash -c "chmod +x /home/$USERNAME/Desktop/precoreshub.desktop"
        arch-chroot /mnt bash -c "chown $USERNAME:$USERNAME /home/$USERNAME/Desktop/precoreshub.desktop"
        
        # Also copy to skeleton for future users
        arch-chroot /mnt bash -c "cp /usr/share/applications/precoreshub.desktop /etc/skel/Desktop/"
        arch-chroot /mnt bash -c "chmod +x /etc/skel/Desktop/precoreshub.desktop"
        
        echo "[INFO] Verifying installation..."
        
        # Verify installation
        if [ -f /mnt/usr/local/PrecoresHub/PrecoresHub.sh ] && [ -x /mnt/usr/local/PrecoresHub/PrecoresHub.sh ]; then
            echo "[SUCCESS] PrecoresHub installed successfully"
            echo "[INFO] Location: /usr/local/PrecoresHub"
            echo "[INFO] Run with: precoreshub (from anywhere)"
            echo "[INFO] Desktop icon created with fixed 67x25 terminal size"
            echo "[INFO] User config: ~/.config/precoreshub"
            echo "[INFO] Cache: ~/.cache/precoreshub"
            echo "[INFO] Permissions: 755 (readable and executable)"
        else
            echo "[ERROR] PrecoresHub installation verification failed"
            return 1
        fi
        
        # Cleanup - Remove tar file and temp directory
        echo "[INFO] Cleaning up temporary files..."
        arch-chroot /mnt bash -c "rm -rf /tmp/PrecoresHub /tmp/PrecoresHub.tar.gz"
        
    } >> "$LOG_FILE" 2>&1
    
    log_silent "PrecoresHub installed to /usr/local/ with proper permissions"
}

################################################################################
# Cleanup and Remove Bloat
################################################################################

cleanup_bloat() {
    update_progress "Removing unnecessary packages"
    
    {
        # Remove package cache to save space
        arch-chroot /mnt pacman -Scc --noconfirm
        
        # Remove orphaned packages
        arch-chroot /mnt pacman -Rns $(arch-chroot /mnt pacman -Qtdq) --noconfirm 2>/dev/null || true
        
        # Clear logs
        arch-chroot /mnt journalctl --vacuum-size=10M
        
    } >> "$LOG_FILE" 2>&1
    
    log_silent "Cleanup complete"
}

################################################################################
# Finish Installation
################################################################################

finish_installation() {
    update_progress "Finalizing installation"
    
    {
        download_precoreshub
        cleanup_bloat
        
        umount -R /mnt || true
        
    } >> "$LOG_FILE" 2>&1 || show_error "Finalization failed"
    
    update_progress "Installation complete!"
    
    # Show completion message
    echo ""
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              Installation Completed Successfully!             ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "System Information:"
    echo "  • Hostname: $HOSTNAME"
    echo "  • Username: $USERNAME"
    echo "  • Password: $PASSWORD"
    echo "  • Boot Mode: $BOOT_MODE"
    echo ""
    echo "Optimizations Applied:"
    echo "  ✓ Ultra-minimal package installation"
    echo "  ✓ ZRAM (compressed RAM swap)"
    echo "  ✓ Aggressive memory optimization"
    echo "  ✓ Unnecessary services disabled"
    echo "  ✓ Bloat packages removed"
    echo "  ✓ Firewall configured"
    echo "  ✓ PrecoresHub v5.0.0 installed"
    echo ""
    echo "After first boot, run: ./precoreshub"
    echo ""
    echo "System will reboot in 10 seconds..."
    echo ""
    
    sleep 10
    reboot
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    init_progress
    
    preflight_checks
    partition_disk
    format_partitions
    mount_partitions
    install_base
    configure_system
    configure_users
    install_bootloader
    install_network
    install_gui
    install_essentials
    optimize_system
    disable_bloat_services
    install_aur_helper
    install_firewall
    finish_installation
}

# Run main installation
main "$@"
