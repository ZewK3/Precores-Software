#!/bin/bash
################################################################################
# Arch Linux Auto-Install Script
# 
# This script performs a fully automated Arch Linux installation with:
# - Automatic disk detection and partitioning
# - Base system installation
# - User creation and configuration
# - GRUB bootloader (BIOS/UEFI)
# - XFCE desktop environment
# - Network and SSH configuration
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

################################################################################
# Configuration
################################################################################

# System Configuration
HOSTNAME="${HOSTNAME:-archlinux}"
USERNAME="${USERNAME:-pcl}"
PASSWORD="${PASSWORD:-123123}"
TIMEZONE="${TIMEZONE:-Asia/Ho_Chi_Minh}"
LOCALE="${LOCALE:-en_US.UTF-8}"

# Disk Configuration (auto-detect if not set)
DISK="${DISK:-}"
BOOT_MODE=""  # Will be detected (BIOS or UEFI)

# Installation Options
INSTALL_GUI="${INSTALL_GUI:-true}"  # XFCE Desktop
INSTALL_SSH="${INSTALL_SSH:-true}"
INSTALL_EXTRA="${INSTALL_EXTRA:-true}"  # Dev tools

################################################################################
# Colors and Logging
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

################################################################################
# Pre-flight Checks
################################################################################

preflight_checks() {
    log_step "Pre-flight Checks"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    # Check internet connection
    log_info "Checking internet connection..."
    if ping -c 1 archlinux.org &> /dev/null; then
        log_info "✓ Internet connection OK"
    else
        log_error "No internet connection. Please check network."
        exit 1
    fi
    
    # Detect boot mode
    if [[ -d /sys/firmware/efi/efivars ]]; then
        BOOT_MODE="UEFI"
        log_info "✓ Boot mode: UEFI"
    else
        BOOT_MODE="BIOS"
        log_info "✓ Boot mode: BIOS"
    fi
    
    # Auto-detect disk if not specified
    if [[ -z "$DISK" ]]; then
        log_info "Auto-detecting installation disk..."
        
        # List available disks
        echo ""
        lsblk -d -o NAME,SIZE,TYPE | grep disk
        echo ""
        
        # Try to find the largest disk
        DISK="/dev/$(lsblk -d -o NAME,SIZE,TYPE | grep disk | sort -k2 -h | tail -1 | awk '{print $1}')"
        log_warn "Auto-detected disk: $DISK"
        
        # Auto-confirm in unattended mode
        log_info "✓ Using disk: $DISK (auto-confirmed)"
    fi
    
    log_info "✓ Installation disk: $DISK"
    
    # Auto-confirm warning in unattended mode
    log_warn "WARNING: All data on $DISK will be DESTROYED!"
    log_info "✓ Proceeding with installation (auto-confirmed)"
}

################################################################################
# Disk Partitioning
################################################################################

partition_disk() {
    log_step "Disk Partitioning"
    
    log_info "Wiping disk $DISK..."
    wipefs -a "$DISK"
    
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        log_info "Creating GPT partition table (UEFI)..."
        parted -s "$DISK" mklabel gpt
        parted -s "$DISK" mkpart primary fat32 1MiB 512MiB
        parted -s "$DISK" set 1 esp on
        parted -s "$DISK" mkpart primary ext4 512MiB 100%
        
        BOOT_PART="${DISK}1"
        ROOT_PART="${DISK}2"
    else
        log_info "Creating MBR partition table (BIOS)..."
        parted -s "$DISK" mklabel msdos
        parted -s "$DISK" mkpart primary ext4 1MiB 100%
        
        ROOT_PART="${DISK}1"
    fi
    
    log_info "Reloading partition table..."
    partprobe "$DISK"
    sleep 2
    
    log_info "✓ Partitioning complete"
}

################################################################################
# Filesystem Creation
################################################################################

format_partitions() {
    log_step "Formatting Partitions"
    
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        log_info "Formatting EFI partition..."
        mkfs.fat -F32 "$BOOT_PART"
    fi
    
    log_info "Formatting root partition..."
    mkfs.ext4 -F "$ROOT_PART"
    
    log_info "✓ Formatting complete"
}

################################################################################
# Mount Filesystems
################################################################################

mount_partitions() {
    log_step "Mounting Partitions"
    
    log_info "Mounting root partition..."
    mount "$ROOT_PART" /mnt
    
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        log_info "Mounting EFI partition..."
        mkdir -p /mnt/boot
        mount "$BOOT_PART" /mnt/boot
    fi
    
    log_info "✓ Mounting complete"
}

################################################################################
# Install Base System
################################################################################

install_base() {
    log_step "Installing Base System"
    
    log_info "Installing base packages..."
    pacstrap /mnt base linux linux-firmware nano vim sudo networkmanager wget curl zram-generator
    
    log_info "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    
    log_info "✓ Base system installed"
}

################################################################################
# System Configuration
################################################################################

configure_system() {
    log_step "Configuring System"
    
    log_info "Setting timezone..."
    arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    arch-chroot /mnt hwclock --systohc
    
    log_info "Setting locale..."
    arch-chroot /mnt sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=$LOCALE" > /mnt/etc/locale.conf
    
    log_info "Setting hostname..."
    echo "$HOSTNAME" > /mnt/etc/hostname
    
    cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
    
    log_info "Configuring zram (compressed RAM)..."
    # Create zram configuration for better memory management
    cat > /mnt/etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF
    
    log_info "Configuring memory management..."
    # Optimize memory settings
    cat > /mnt/etc/sysctl.d/99-vm.conf <<EOF
# Reduce swappiness (prefer RAM over swap)
vm.swappiness = 10

# Improve cache pressure
vm.vfs_cache_pressure = 50

# Dirty ratio for better write performance
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
EOF
    
    log_info "✓ System configured with zram and memory optimizations"
}

################################################################################
# User Configuration
################################################################################

configure_users() {
    log_step "Configuring Users"
    
    log_info "Setting root password..."
    echo "root:$PASSWORD" | arch-chroot /mnt chpasswd
    
    log_info "Creating user $USERNAME..."
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$USERNAME"
    echo "$USERNAME:$PASSWORD" | arch-chroot /mnt chpasswd
    
    log_info "Configuring sudo..."
    arch-chroot /mnt sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    
    log_info "✓ Users configured"
}

################################################################################
# Install Bootloader
################################################################################

install_bootloader() {
    log_step "Installing Bootloader"
    
    log_info "Installing GRUB..."
    arch-chroot /mnt pacman -S --noconfirm grub
    
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        log_info "Installing GRUB for UEFI..."
        arch-chroot /mnt pacman -S --noconfirm efibootmgr
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    else
        log_info "Installing GRUB for BIOS..."
        arch-chroot /mnt grub-install --target=i386-pc "$DISK"
    fi
    
    log_info "Generating GRUB config..."
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    
    log_info "✓ Bootloader installed"
}

################################################################################
# Install Network Tools
################################################################################

install_network() {
    log_step "Installing Network Tools"
    
    log_info "Enabling NetworkManager..."
    arch-chroot /mnt systemctl enable NetworkManager
    
    if [[ "$INSTALL_SSH" == "true" ]]; then
        log_info "Installing and enabling SSH..."
        arch-chroot /mnt pacman -S --noconfirm openssh
        arch-chroot /mnt systemctl enable sshd
    fi
    
    log_info "✓ Network configured"
}

################################################################################
# Install GUI (XFCE Desktop)
################################################################################

install_gui() {
    if [[ "$INSTALL_GUI" != "true" ]]; then
        log_info "Skipping GUI installation"
        return
    fi
    
    log_step "Installing GUI (XFCE)"
    
    log_info "Installing Xorg (minimal)..."
    arch-chroot /mnt pacman -S --noconfirm xorg-server xorg-xinit
    
    log_info "Installing XFCE (minimal)..."
    arch-chroot /mnt pacman -S --noconfirm xfce4 xfce4-terminal
    
    log_info "Installing file manager..."
    arch-chroot /mnt pacman -S --noconfirm thunar
    
    log_info "Installing display manager..."
    arch-chroot /mnt pacman -S --noconfirm lightdm lightdm-gtk-greeter
    
    log_info "Configuring auto-login..."
    # Create lightdm config directory
    mkdir -p /mnt/etc/lightdm/lightdm.conf.d
    
    # Configure auto-login properly
    cat > /mnt/etc/lightdm/lightdm.conf.d/50-autologin.conf <<EOF
[Seat:*]
autologin-user=$USERNAME
autologin-user-timeout=0
autologin-session=xfce
EOF
    
    # Add user to autologin group
    arch-chroot /mnt groupadd -r autologin || true
    arch-chroot /mnt gpasswd -a $USERNAME autologin
    
    # Configure PAM for autologin
    cat > /mnt/etc/pam.d/lightdm-autologin <<EOF
#%PAM-1.0
auth        sufficient  pam_succeed_if.so user ingroup autologin
auth        required    pam_permit.so
account     include     system-local-login
password    include     system-local-login
session     include     system-local-login
EOF
    
    # Create .xinitrc for the user to start XFCE
    cat > /mnt/home/$USERNAME/.xinitrc <<EOF
#!/bin/sh
exec startxfce4
EOF
    
    chmod +x /mnt/home/$USERNAME/.xinitrc
    chown 1000:1000 /mnt/home/$USERNAME/.xinitrc
    
    arch-chroot /mnt systemctl enable lightdm
    
    log_info "✓ XFCE Desktop installed (minimal) with auto-login"
}

################################################################################
################################################################################
# Install Extra Packages (Development Tools)
################################################################################

install_extras() {
    if [[ "$INSTALL_EXTRA" != "true" ]]; then
        return
    fi
    
    log_step "Installing Development Tools"
    
    log_info "Installing build tools..."
    arch-chroot /mnt pacman -S --noconfirm base-devel git wget curl
    
    log_info "Installing programming languages..."
    arch-chroot /mnt pacman -S --noconfirm python nodejs npm
    
    log_info "Installing utilities..."
    arch-chroot /mnt pacman -S --noconfirm htop neofetch
    
    log_info "Installing browser..."
    arch-chroot /mnt pacman -S --noconfirm firefox
    
    log_info "✓ Development tools installed"
}

################################################################################
# System Optimizations
################################################################################

optimize_system() {
    log_step "Optimizing System Performance"
    
    log_info "Configuring I/O scheduler for better disk performance..."
    cat > /mnt/etc/udev/rules.d/60-ioschedulers.rules <<EOF
# Set deadline scheduler for non-rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# Set BFQ scheduler for rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF
    
    log_info "Disabling unnecessary services..."
    # Disable PC speaker beep
    echo "blacklist pcspkr" > /mnt/etc/modprobe.d/nobeep.conf
    
    log_info "Configuring faster boot..."
    # Reduce systemd timeout
    mkdir -p /mnt/etc/systemd/system.conf.d
    cat > /mnt/etc/systemd/system.conf.d/timeout.conf <<EOF
[Manager]
DefaultTimeoutStartSec=10s
DefaultTimeoutStopSec=10s
EOF
    
    log_info "Configuring network optimizations..."
    cat > /mnt/etc/sysctl.d/99-network.conf <<EOF
# Increase network buffer sizes
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

# Enable TCP Fast Open
net.ipv4.tcp_fastopen = 3
EOF
    
    log_info "✓ System optimizations applied"
}

################################################################################
# Install Firewall
################################################################################

install_firewall() {
    log_step "Installing Firewall"
    
    log_info "Installing ufw (Uncomplicated Firewall)..."
    arch-chroot /mnt pacman -S --noconfirm ufw
    
    log_info "Configuring firewall rules..."
    arch-chroot /mnt ufw default deny incoming
    arch-chroot /mnt ufw default allow outgoing
    
    if [[ "$INSTALL_SSH" == "true" ]]; then
        log_info "Allowing SSH through firewall..."
        arch-chroot /mnt ufw allow ssh
    fi
    
    log_info "Enabling firewall..."
    arch-chroot /mnt ufw --force enable
    arch-chroot /mnt systemctl enable ufw
    
    log_info "✓ Firewall configured"
}

################################################################################
# Install AUR Helper
################################################################################

install_aur_helper() {
    log_step "Installing AUR Helper (yay)"
    
    log_info "Installing yay for AUR package management..."
    
    # Install as user (not root)
    arch-chroot /mnt bash -c "cd /tmp && \
        sudo -u $USERNAME git clone https://aur.archlinux.org/yay.git && \
        cd yay && \
        sudo -u $USERNAME makepkg -si --noconfirm"
    
    log_info "✓ AUR helper (yay) installed"
}

################################################################################
# Cleanup and Finish
################################################################################

create_post_install_script() {
    log_step "Creating Post-Install Helper Script"
    
    log_info "Creating helper script for user..."
    cat > /mnt/home/$USERNAME/post-install.sh <<'POSTEOF'
#!/bin/bash
################################################################################
# Post-Installation Helper Script
# Run this after first boot to install additional software
################################################################################

echo "=== Arch Linux Post-Install Helper ==="
echo ""
echo "Available options:"
echo "1. Install AUR packages (using yay)"
echo "2. Install Docker"
echo "3. Install VS Code"
echo "4. Install Chrome/Chromium"
echo "5. Update system"
echo "6. Install all of the above"
echo "0. Exit"
echo ""
read -p "Choose option (0-6): " choice

case $choice in
    1)
        echo "Installing popular AUR packages..."
        yay -S --noconfirm google-chrome visual-studio-code-bin
        ;;
    2)
        echo "Installing Docker..."
        sudo pacman -S --noconfirm docker docker-compose
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        echo "Docker installed! Please logout and login again."
        ;;
    3)
        echo "Installing VS Code..."
        yay -S --noconfirm visual-studio-code-bin
        ;;
    4)
        echo "Installing Chrome..."
        yay -S --noconfirm google-chrome
        ;;
    5)
        echo "Updating system..."
        sudo pacman -Syu --noconfirm
        ;;
    6)
        echo "Installing everything..."
        sudo pacman -Syu --noconfirm
        sudo pacman -S --noconfirm docker docker-compose
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        yay -S --noconfirm google-chrome visual-studio-code-bin
        echo "All done! Please logout and login again."
        ;;
    0)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        ;;
esac
POSTEOF
    
    chmod +x /mnt/home/$USERNAME/post-install.sh
    chown 1000:1000 /mnt/home/$USERNAME/post-install.sh
    
    log_info "✓ Post-install script created at ~/post-install.sh"
}

finish_installation() {
    log_step "Finishing Installation"
    
    create_post_install_script
    
    log_info "Unmounting filesystems..."
    umount -R /mnt || true
    
    log_step "Installation Complete!"
    
    echo ""
    log_info "System Information:"
    echo "  Hostname: $HOSTNAME"
    echo "  Username: $USERNAME"
    echo "  Password: $PASSWORD"
    echo "  Boot Mode: $BOOT_MODE"
    echo "  Disk: $DISK"
    echo ""
    log_info "Features installed:"
    echo "  ✓ XFCE Desktop with auto-login"
    echo "  ✓ zram (compressed RAM swap)"
    echo "  ✓ Firewall (ufw) configured"
    echo "  ✓ AUR helper (yay) installed"
    echo "  ✓ System optimizations applied"
    echo "  ✓ Firefox browser"
    echo ""
    log_info "After first boot, run: ~/post-install.sh"
    log_info "to install additional software (Docker, VS Code, Chrome, etc.)"
    echo ""
    log_warn "Please remove the installation media"
    log_info "System will reboot in 10 seconds..."
    echo ""
    
    # Auto-reboot after 10 seconds
    sleep 10
    reboot
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    log_step "Arch Linux Auto-Install"
    
    echo "Configuration:"
    echo "  Hostname: $HOSTNAME"
    echo "  Username: $USERNAME"
    echo "  Timezone: $TIMEZONE"
    echo "  Locale: $LOCALE"
    echo "  Install GUI: $INSTALL_GUI"
    echo "  Install SSH: $INSTALL_SSH"
    echo ""
    
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
    install_extras
    optimize_system
    install_firewall
    install_aur_helper
    finish_installation
}

# Run main installation
main "$@"
