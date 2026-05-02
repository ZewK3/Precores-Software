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
INSTALL_GUI="${INSTALL_GUI:-true}"
INSTALL_SSH="${INSTALL_SSH:-true}"
INSTALL_EXTRA="${INSTALL_EXTRA:-false}"
INSTALL_KIRO="${INSTALL_KIRO:-true}"

# Kiro IDE Configuration
KIRO_VERSION="0.11.133"
KIRO_URL="https://prod.download.desktop.kiro.dev/releases/stable/linux-x64/signed/${KIRO_VERSION}/tar/kiro-ide-${KIRO_VERSION}-stable-linux-x64.tar.gz"
KIRO_INSTALL_DIR="/opt/kiro"

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
        
        # Confirmation
        read -p "Use $DISK for installation? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
            log_error "Installation cancelled by user"
            exit 1
        fi
    fi
    
    log_info "✓ Installation disk: $DISK"
    
    # Final confirmation
    log_warn "WARNING: All data on $DISK will be DESTROYED!"
    read -p "Continue with installation? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        log_error "Installation cancelled by user"
        exit 1
    fi
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
    pacstrap /mnt base linux linux-firmware nano vim sudo networkmanager
    
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
    
    log_info "✓ System configured"
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
# Install GUI (Optional)
################################################################################

install_gui() {
    if [[ "$INSTALL_GUI" != "true" ]]; then
        log_info "Skipping GUI installation"
        return
    fi
    
    log_step "Installing GUI (XFCE)"
    
    log_info "Installing Xorg..."
    arch-chroot /mnt pacman -S --noconfirm xorg
    
    log_info "Installing XFCE..."
    arch-chroot /mnt pacman -S --noconfirm xfce4 xfce4-goodies
    
    log_info "Installing display manager..."
    arch-chroot /mnt pacman -S --noconfirm lightdm lightdm-gtk-greeter
    arch-chroot /mnt systemctl enable lightdm
    
    log_info "✓ GUI installed"
}

################################################################################
# Install Kiro IDE (Optional)
################################################################################

install_kiro() {
    if [[ "$INSTALL_KIRO" != "true" ]]; then
        log_info "Skipping Kiro IDE installation"
        return
    fi
    
    log_step "Installing Kiro IDE"
    
    log_info "Downloading Kiro IDE v${KIRO_VERSION}..."
    arch-chroot /mnt wget -O /tmp/kiro.tar.gz "$KIRO_URL"
    
    log_info "Creating installation directory..."
    arch-chroot /mnt mkdir -p "$KIRO_INSTALL_DIR"
    
    log_info "Extracting Kiro IDE..."
    arch-chroot /mnt tar -xzf /tmp/kiro.tar.gz -C "$KIRO_INSTALL_DIR" --strip-components=1
    
    log_info "Creating desktop entry..."
    cat > /mnt/usr/share/applications/kiro.desktop <<EOF
[Desktop Entry]
Name=Kiro IDE
Comment=AI-powered development environment
Exec=${KIRO_INSTALL_DIR}/kiro-ide
Icon=${KIRO_INSTALL_DIR}/resources/app/icon.png
Terminal=false
Type=Application
Categories=Development;IDE;
EOF
    
    log_info "Creating symlink..."
    arch-chroot /mnt ln -sf "$KIRO_INSTALL_DIR/kiro-ide" /usr/local/bin/kiro
    
    log_info "Setting permissions..."
    arch-chroot /mnt chmod +x "$KIRO_INSTALL_DIR/kiro-ide"
    
    log_info "Cleaning up..."
    arch-chroot /mnt rm -f /tmp/kiro.tar.gz
    
    log_info "✓ Kiro IDE installed"
    log_info "  Launch with: kiro"
}

################################################################################
# Install Extra Packages (Optional)
################################################################################

install_extras() {
    if [[ "$INSTALL_EXTRA" != "true" ]]; then
        return
    fi
    
    log_step "Installing Extra Packages"
    
    log_info "Installing development tools..."
    arch-chroot /mnt pacman -S --noconfirm base-devel git wget curl
    
    log_info "Installing utilities..."
    arch-chroot /mnt pacman -S --noconfirm htop neofetch tree
    
    log_info "✓ Extra packages installed"
}

################################################################################
# Cleanup and Finish
################################################################################

finish_installation() {
    log_step "Finishing Installation"
    
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
    log_warn "Please remove the installation media and reboot"
    echo ""
    
    read -p "Reboot now? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        reboot
    fi
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
    echo "  Install Kiro IDE: $INSTALL_KIRO"
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
    install_kiro
    install_extras
    finish_installation
}

# Run main installation
main "$@"
