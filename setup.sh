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
if [[ "${HOSTNAME:-}" == "archiso" || -z "${HOSTNAME:-}" ]]; then
    # Generate unique hostname for VM farm (e.g., PCL-A1B2C)
    RAND_STR=$(tr -dc 'A-Z0-9' < /dev/urandom | head -c 5)
    HOSTNAME="PCL-${RAND_STR}"
fi
USERNAME="${USERNAME:-pcl}"
PASSWORD="${PASSWORD:-PCL@1231233}"
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

TOTAL_STEPS=21
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
            arch-chroot /mnt sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
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
        # Minimal X server (no unnecessary drivers) + Virtual Display (Dummy)
        arch-chroot /mnt pacman -S --noconfirm xorg-server xorg-xinit xf86-video-dummy
        
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
        
        # Configure Virtual Display (Dummy) to force 1920x1080 resolution for headless NoMachine
        mkdir -p /mnt/etc/X11/xorg.conf.d
        cat > /mnt/etc/X11/xorg.conf.d/10-dummy.conf <<EOF
Section "Device"
    Identifier "DummyDevice"
    Driver "dummy"
    VideoRam 256000
EndSection

Section "Monitor"
    Identifier "DummyMonitor"
    HorizSync 28.0-80.0
    VertRefresh 48.0-75.0
EndSection

Section "Screen"
    Identifier "DummyScreen"
    Device "DummyDevice"
    Monitor "DummyMonitor"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection
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
        
        # Essential utilities (imagemagick for screenshot reporting)
        arch-chroot /mnt pacman -S --noconfirm htop fzf jq fastfetch imagemagick
        
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
# Install and Configure NoMachine
################################################################################

install_nomachine() {
    update_progress "Installing NoMachine"
    
    {
        echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" | arch-chroot /mnt tee /etc/sudoers.d/temp_nopasswd > /dev/null
        
        arch-chroot /mnt bash -c "sudo -u $USERNAME yay -S --noconfirm nomachine"
        
        arch-chroot /mnt rm -f /etc/sudoers.d/temp_nopasswd
        
        # Optimize NoMachine for headless/VM farm
        arch-chroot /mnt sed -i 's/^[#]*EnableUPnP.*/EnableUPnP none/' /usr/NX/etc/server.cfg || true
        arch-chroot /mnt sed -i 's/^[#]*UpdateFrequency.*/UpdateFrequency 0/' /usr/NX/etc/server.cfg || true
        arch-chroot /mnt sed -i 's/^[#]*AudioInterface.*/AudioInterface disabled/' /usr/NX/etc/node.cfg || true
        arch-chroot /mnt sed -i 's/^[#]*EnableAudio.*/EnableAudio 0/' /usr/NX/etc/node.cfg || true
        arch-chroot /mnt sed -i 's/^[#]*EnableUSBSharing.*/EnableUSBSharing 0/' /usr/NX/etc/node.cfg || true
        
        arch-chroot /mnt systemctl enable nxserver.service
        
    } >> "$LOG_FILE" 2>&1 || show_error "NoMachine installation failed"
    
    log_silent "NoMachine installed and optimized"
}

################################################################################
# Setup VM Dashboard Registration
################################################################################

setup_vm_registration() {
    update_progress "Configuring VM Registration"
    
    {
        cat > /mnt/usr/local/bin/vm-register.sh <<'EOF'
#!/bin/bash
VM_REGISTRY_URL="https://vm-registry.zewk.workers.dev"

for i in {1..30}; do
    NIC=$(ip route show default | awk '/default/ {print $5}' | head -n 1)
    if [ -n "$NIC" ]; then
        IP=$(ip -4 addr show dev "$NIC" | awk '/inet/ {print $2}' | cut -d/ -f1 | head -n 1)
        MAC=$(ip link show dev "$NIC" | awk '/ether/ {print $2}')
        
        if [ -n "$IP" ]; then
            HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "LinuxVM")
            if [[ "$HOSTNAME" == PCLPCL* ]]; then
                HOSTNAME="PCL${HOSTNAME:6}"
            fi
            
            OS_CAPTION=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2 || echo "Arch Linux")
            
            JSON=$(jq -n \
              --arg mac "$MAC" \
              --arg hostname "$HOSTNAME" \
              --arg ip "$IP" \
              --arg user "pcl" \
              --arg password "PCL@1231233" \
              --arg os "$OS_CAPTION" \
              --arg nomachine "READY" \
              '{mac: $mac, hostname: $hostname, ip: $ip, user: $user, password: $password, os: $os, nomachine: $nomachine}')
            
            echo "Attempt $i: Sending registration for $HOSTNAME ($IP)..." >> /var/log/vm-register.log
            if curl -k -s -f -X POST -H "Content-Type: application/json" -d "$JSON" --max-time 15 "$VM_REGISTRY_URL/register" >> /var/log/vm-register.log 2>&1; then
                echo "EARLY_REGISTER_OK $HOSTNAME $IP" >> /var/log/vm-register.log
                exit 0
            else
                echo "Curl failed with exit code $?" >> /var/log/vm-register.log
            fi
        fi
    fi
    sleep 10
done
exit 1
EOF
        arch-chroot /mnt chmod +x /usr/local/bin/vm-register.sh

        # Create Heartbeat Script (Runs continuously to send screenshots and keep VM online)
        cat > /mnt/usr/local/bin/vm-heartbeat.sh <<'EOF'
#!/bin/bash
VM_REGISTRY_URL="https://vm-registry.zewk.workers.dev"
while true; do
    NIC=$(ip route show default | awk '/default/ {print $5}' | head -n 1)
    if [ -n "$NIC" ]; then
        IP=$(ip -4 addr show dev "$NIC" | awk '/inet/ {print $2}' | cut -d/ -f1 | head -n 1)
        if [ -n "$IP" ]; then
            HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo "LinuxVM")
            if [[ "$HOSTNAME" == PCLPCL* ]]; then HOSTNAME="PCL${HOSTNAME:6}"; fi
            OS_CAPTION=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2 || echo "Arch Linux")
            
            SCREENSHOT=""
            if command -v import &>/dev/null; then
                SCREENSHOT=$(import -window root -resize 320x180 -quality 55 jpeg:- 2>/dev/null | base64 -w0)
            fi
            
            JSON=$(jq -n \
              --arg hostname "$HOSTNAME" \
              --arg ip "$IP" \
              --arg user "pcl" \
              --arg password "PCL@1231233" \
              --arg os "$OS_CAPTION" \
              --arg nomachine "READY" \
              --arg screenshot "$SCREENSHOT" \
              '{hostname: $hostname, ip: $ip, user: $user, password: $password, os: $os, nomachine: $nomachine, screenshot: $screenshot}')
            
            curl -k -s -X POST -H "Content-Type: application/json" -d "$JSON" --max-time 10 "$VM_REGISTRY_URL/register" >/dev/null 2>&1
        fi
    fi
    sleep 60
done
EOF
        arch-chroot /mnt chmod +x /usr/local/bin/vm-heartbeat.sh
        
        # Add Heartbeat to XFCE Autostart so it can capture the GUI
        mkdir -p /mnt/home/$USERNAME/.config/autostart
        cat > /mnt/home/$USERNAME/.config/autostart/vm-heartbeat.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/vm-heartbeat.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=VM Heartbeat
EOF
        chown -R 1000:1000 /mnt/home/$USERNAME/.config/autostart

        cat > /mnt/etc/systemd/system/vm-register.service <<'EOF'
[Unit]
Description=VM Dashboard Registration
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/vm-register.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        arch-chroot /mnt systemctl enable vm-register.service
        
    } >> "$LOG_FILE" 2>&1 || show_error "VM Registration setup failed"
    
    log_silent "VM Registration configured"
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
        
        # Open NoMachine port
        arch-chroot /mnt ufw allow 4000/tcp
        arch-chroot /mnt ufw allow 4000/udp
        
        arch-chroot /mnt ufw --force enable
        arch-chroot /mnt systemctl enable ufw
        
    } >> "$LOG_FILE" 2>&1 || show_error "Firewall installation failed"
    
    log_silent "Firewall configured"
}

################################################################################
# Download and Install PrecoresHub
################################################################################

# Constants
PRECORES_DIR="/opt/precoreshub"
PRECORES_TARBALL_URL="https://raw.githubusercontent.com/ZewK3/Precores-Software/main/PrecoresHub.tar.gz"

# Ensure DNS works inside chroot before any download
setup_chroot_network() {
    if [[ ! -s /mnt/etc/resolv.conf ]] || ! grep -q "nameserver" /mnt/etc/resolv.conf 2>/dev/null; then
        cat > /mnt/etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
        log_silent "Configured /etc/resolv.conf in chroot (1.1.1.1 / 8.8.8.8)"
    fi
}

# Generate a custom SVG icon and register it in the icon theme
create_app_icon() {
    mkdir -p /mnt/usr/share/icons/hicolor/scalable/apps
    mkdir -p /mnt/usr/share/pixmaps

    cat > /mnt/usr/share/icons/hicolor/scalable/apps/precoreshub.svg <<'ICON_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0f172a"/>
      <stop offset="100%" style="stop-color:#0ea5e9"/>
    </linearGradient>
    <linearGradient id="ring" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#22d3ee"/>
      <stop offset="100%" style="stop-color:#a78bfa"/>
    </linearGradient>
  </defs>
  <rect x="6" y="6" width="116" height="116" rx="22" fill="url(#bg)"/>
  <circle cx="64" cy="64" r="40" fill="none" stroke="url(#ring)" stroke-width="6"/>
  <circle cx="64" cy="64" r="10" fill="#22d3ee"/>
  <circle cx="64" cy="24" r="6" fill="#a78bfa"/>
  <circle cx="104" cy="64" r="6" fill="#22d3ee"/>
  <circle cx="64" cy="104" r="6" fill="#22d3ee"/>
  <circle cx="24" cy="64" r="6" fill="#a78bfa"/>
  <line x1="64" y1="34" x2="64" y2="54" stroke="url(#ring)" stroke-width="3"/>
  <line x1="94" y1="64" x2="74" y2="64" stroke="url(#ring)" stroke-width="3"/>
  <line x1="64" y1="94" x2="64" y2="74" stroke="url(#ring)" stroke-width="3"/>
  <line x1="34" y1="64" x2="54" y2="64" stroke="url(#ring)" stroke-width="3"/>
</svg>
ICON_EOF

    cp /mnt/usr/share/icons/hicolor/scalable/apps/precoreshub.svg /mnt/usr/share/pixmaps/precoreshub.svg
    chmod 644 /mnt/usr/share/icons/hicolor/scalable/apps/precoreshub.svg
    chmod 644 /mnt/usr/share/pixmaps/precoreshub.svg

    arch-chroot /mnt gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
}

download_precoreshub() {
    update_progress "Installing PrecoresHub"

    # 1) Network in chroot (critical fix for download failure)
    setup_chroot_network

    # 2) Ensure required tools (curl/tar/ca-certs/desktop-file-utils for icon registration)
    log_silent "Ensuring curl/tar/ca-certificates/desktop-file-utils are installed..."
    arch-chroot /mnt pacman -S --noconfirm --needed curl tar gzip ca-certificates desktop-file-utils >> "$LOG_FILE" 2>&1 || \
        log_silent "WARNING: pacman -S for prerequisite packages returned non-zero"
    arch-chroot /mnt update-ca-trust 2>/dev/null || true

    # 3) Download with retries
    local tmp_tar="/mnt/tmp/PrecoresHub.tar.gz"
    local downloaded=0
    rm -f "$tmp_tar"
    for attempt in 1 2 3; do
        log_silent "Download attempt ${attempt}/3 from ${PRECORES_TARBALL_URL}"
        if arch-chroot /mnt curl -k -L -f --connect-timeout 30 --max-time 180 \
                -o /tmp/PrecoresHub.tar.gz "$PRECORES_TARBALL_URL" >> "$LOG_FILE" 2>&1; then
            downloaded=1
            break
        fi
        sleep 3
    done

    if [[ $downloaded -ne 1 ]] || [[ ! -f "$tmp_tar" ]]; then
        log_silent "ERROR: PrecoresHub download failed after 3 attempts - Skipping"
        return 0
    fi

    local file_size
    file_size=$(stat -c%s "$tmp_tar" 2>/dev/null || echo "0")
    if [[ "$file_size" -lt 10000 ]]; then
        log_silent "ERROR: tarball too small (${file_size} bytes), likely 404 page - Skipping"
        rm -f "$tmp_tar"
        return 0
    fi
    log_silent "Downloaded successfully (${file_size} bytes)"

    # 4) Extract straight into /opt/precoreshub (system-wide, hidden from $HOME file manager)
    log_silent "Extracting to ${PRECORES_DIR}..."
    rm -rf "/mnt${PRECORES_DIR}"
    mkdir -p "/mnt${PRECORES_DIR}"

    if ! arch-chroot /mnt tar -xzf /tmp/PrecoresHub.tar.gz \
            --strip-components=1 -C "${PRECORES_DIR}" >> "$LOG_FILE" 2>&1; then
        log_silent "WARN: --strip-components=1 failed, falling back to plain extract"
        rm -rf "/mnt${PRECORES_DIR}"
        mkdir -p /mnt/tmp/_pre_extract
        if arch-chroot /mnt tar -xzf /tmp/PrecoresHub.tar.gz -C /tmp/_pre_extract >> "$LOG_FILE" 2>&1; then
            local inner
            inner=$(ls /mnt/tmp/_pre_extract/ 2>/dev/null | head -1)
            if [[ -n "$inner" && -d "/mnt/tmp/_pre_extract/$inner" ]]; then
                mv "/mnt/tmp/_pre_extract/$inner" "/mnt${PRECORES_DIR}"
            fi
            rm -rf /mnt/tmp/_pre_extract
        else
            log_silent "ERROR: extraction failed completely - Skipping"
            shred -u "$tmp_tar" 2>/dev/null || rm -f "$tmp_tar"
            return 0
        fi
    fi

    if [[ ! -f "/mnt${PRECORES_DIR}/PrecoresHub.sh" ]]; then
        log_silent "ERROR: PrecoresHub.sh not found after extraction - Skipping"
        ls "/mnt${PRECORES_DIR}" >> "$LOG_FILE" 2>&1
        rm -rf "/mnt${PRECORES_DIR}"
        shred -u "$tmp_tar" 2>/dev/null || rm -f "$tmp_tar"
        return 0
    fi

    # 5) HIDE the tarball: securely shred + remove every leftover trace
    log_silent "Securely removing source tarball (hiding from user)..."
    shred -u "$tmp_tar" 2>/dev/null || rm -f "$tmp_tar"
    rm -rf /mnt/tmp/PrecoresHub /mnt/tmp/_pre_extract /mnt/tmp/PrecoresHub.tar.gz.* 2>/dev/null || true

    # 6) Lock down: root-owned, world read+execute, no write
    log_silent "Locking down permissions (root-owned, read+execute only)..."
    arch-chroot /mnt bash -c "
        chown -R root:root ${PRECORES_DIR}
        find ${PRECORES_DIR} -type d -exec chmod 755 {} \;
        find ${PRECORES_DIR} -type f -exec chmod 644 {} \;
        find ${PRECORES_DIR} -type f -name '*.sh' -exec chmod 755 {} \;
        chmod 755 ${PRECORES_DIR}/PrecoresHub.sh
        echo 'PrecoresHub v5.0.0 installed on \$(date)' > ${PRECORES_DIR}/.installed
        chmod 444 ${PRECORES_DIR}/.installed
    " >> "$LOG_FILE" 2>&1

    # 7) User-writable runtime dirs (config/cache/data live in $HOME, NOT in /opt)
    log_silent "Creating user runtime directories..."
    arch-chroot /mnt bash -c "
        for d in .config/precoreshub .cache/precoreshub .local/share/precoreshub; do
            mkdir -p /home/${USERNAME}/\$d /etc/skel/\$d
            chown ${USERNAME}:${USERNAME} /home/${USERNAME}/\$d
        done
    " >> "$LOG_FILE" 2>&1

    # 8) System-wide launcher
    log_silent "Creating launcher /usr/local/bin/precoreshub..."
    cat > /mnt/usr/local/bin/precoreshub <<'LAUNCHER_EOF'
#!/bin/bash
# PrecoresHub Launcher
INSTALL_DIR="/opt/precoreshub"

if [[ $EUID -eq 0 ]]; then
    echo "Error: Do not run PrecoresHub as root."
    exit 1
fi

if [[ ! -d "$INSTALL_DIR" ]] || [[ ! -f "$INSTALL_DIR/PrecoresHub.sh" ]]; then
    echo "Error: PrecoresHub is not installed at $INSTALL_DIR"
    exit 1
fi

# Auto-install missing runtime deps (one-shot)
need=()
command -v fzf >/dev/null 2>&1 || need+=("fzf")
command -v jq  >/dev/null 2>&1 || need+=("jq")
if [[ ${#need[@]} -gt 0 ]]; then
    echo "Installing required dependencies: ${need[*]}"
    sudo pacman -S --noconfirm --needed "${need[@]}" || {
        echo "Failed to install: ${need[*]}"
        exit 1
    }
fi

export SCRIPT_DIR="$INSTALL_DIR"
cd "$INSTALL_DIR"
exec bash "$INSTALL_DIR/PrecoresHub.sh" "$@"
LAUNCHER_EOF
    arch-chroot /mnt chmod 755 /usr/local/bin/precoreshub

    # 9) Application icon
    log_silent "Installing application icon..."
    create_app_icon

    # 10) Desktop entry (system menu + user Desktop + skel)
    log_silent "Creating desktop shortcut..."
    cat > /mnt/usr/share/applications/precoreshub.desktop <<'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=PrecoresHub
GenericName=Linux Control Center
Comment=Unified package & system manager for Linux
Exec=xfce4-terminal --geometry=120x35 --title=PrecoresHub --command="bash -lc 'precoreshub; echo; read -n 1 -s -r -p \"Press any key to close...\"'"
Icon=precoreshub
Terminal=false
Categories=System;Settings;PackageManager;
Keywords=hub;package;install;system;manager;
StartupNotify=true
StartupWMClass=PrecoresHub
DESKTOP_EOF
    arch-chroot /mnt chmod 644 /usr/share/applications/precoreshub.desktop
    arch-chroot /mnt update-desktop-database -q 2>/dev/null || true

    arch-chroot /mnt bash -c "
        mkdir -p /home/${USERNAME}/Desktop /etc/skel/Desktop
        cp /usr/share/applications/precoreshub.desktop /home/${USERNAME}/Desktop/
        cp /usr/share/applications/precoreshub.desktop /etc/skel/Desktop/
        chmod 755 /home/${USERNAME}/Desktop/precoreshub.desktop
        chmod 755 /etc/skel/Desktop/precoreshub.desktop
        chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/Desktop
    " >> "$LOG_FILE" 2>&1

    # 11) Auto-trust the desktop icon on first login (XFCE/GNOME require gio metadata::trusted)
    cat > /mnt/etc/profile.d/precoreshub-trust-desktop.sh <<'TRUST_EOF'
# Auto-trust PrecoresHub desktop icon for current user
if [[ -f "$HOME/Desktop/precoreshub.desktop" ]]; then
    chmod +x "$HOME/Desktop/precoreshub.desktop" 2>/dev/null || true
    if command -v gio >/dev/null 2>&1; then
        gio set "$HOME/Desktop/precoreshub.desktop" "metadata::trusted" true 2>/dev/null || true
    fi
fi
TRUST_EOF
    chmod 644 /mnt/etc/profile.d/precoreshub-trust-desktop.sh

    # 12) Immutable attribute - even root cannot edit without `chattr -i`
    log_silent "Applying immutable attributes (chattr +i)..."
    arch-chroot /mnt bash -c "find ${PRECORES_DIR} -type f -exec chattr +i {} \\; 2>/dev/null" || true

    # 13) Friendly info file in user $HOME
    cat > /mnt/home/${USERNAME}/PRECORESHUB_INFO.txt <<INFO_EOF
╔══════════════════════════════════════════════════════════╗
║              PrecoresHub v5.0.0 Installed                ║
╚══════════════════════════════════════════════════════════╝

How to run:
  • Terminal:  precoreshub
  • Desktop:   double-click the PrecoresHub icon
  • Menu:      Applications -> System -> PrecoresHub

Installation directory: ${PRECORES_DIR}
  • Owner:        root:root
  • Permissions:  read + execute only for users (no write)
  • Immutable:    files are locked with chattr +i
  • Source archive (PrecoresHub.tar.gz) was securely removed
    after install -- it is no longer present anywhere on disk.

User data (the only writable bits):
  • Config: ~/.config/precoreshub/
  • Cache:  ~/.cache/precoreshub/
  • Data:   ~/.local/share/precoreshub/

Maintenance (sudo only):
  • Unlock files: sudo chattr -R -i ${PRECORES_DIR}
  • Re-lock:      sudo chattr -R +i ${PRECORES_DIR}
  • Reinstall:    re-download tarball, then re-lock

Install log: /home/${USERNAME}/install.log
INFO_EOF
    arch-chroot /mnt chown ${USERNAME}:${USERNAME} /home/${USERNAME}/PRECORESHUB_INFO.txt
    arch-chroot /mnt chmod 644 /home/${USERNAME}/PRECORESHUB_INFO.txt

    log_silent "PrecoresHub installation complete at ${PRECORES_DIR}"
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
        
        # Save the detailed installation log to the user's home directory
        cp "$LOG_FILE" "/mnt/home/${USERNAME}/install.log"
        arch-chroot /mnt chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/install.log"
        arch-chroot /mnt chmod 644 "/home/${USERNAME}/install.log"
        
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
    echo "  ✓ PrecoresHub v5.0.0 installed (locked at /opt/precoreshub)"
    echo "  ✓ NoMachine installed & optimized"
    echo "  ✓ VM Dashboard Registration enabled"
    echo ""
    echo "After first boot:"
    echo "  • Run from terminal:  precoreshub"
    echo "  • Or click the PrecoresHub icon on the Desktop"
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
    install_nomachine
    setup_vm_registration
    install_firewall
    finish_installation
}

# Run main installation
main "$@"
