#!/bin/bash

set -e

DISK="/dev/sda"
HOSTNAME="archlinux"
USERNAME="pcl"
PASSWORD="123123"

echo "== Wiping disk =="
wipefs -a $DISK

echo "== Creating partition (BIOS) =="
parted -s $DISK mklabel msdos
parted -s $DISK mkpart primary ext4 1MiB 100%

echo "== Reload partition table =="
partprobe $DISK
sleep 2

ROOT_PART="${DISK}1"

echo "== Formatting =="
mkfs.ext4 -F $ROOT_PART

echo "== Mounting =="
mount $ROOT_PART /mnt

echo "== Installing base system =="
pacstrap /mnt base linux linux-firmware nano sudo networkmanager

genfstab -U /mnt >> /mnt/etc/fstab

echo "== Configuring system =="

arch-chroot /mnt bash -c "
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

echo $HOSTNAME > /etc/hostname

echo '127.0.0.1 localhost' >> /etc/hosts
echo '::1       localhost' >> /etc/hosts
echo '127.0.1.1 $HOSTNAME.localdomain $HOSTNAME' >> /etc/hosts

echo root:$PASSWORD | chpasswd

useradd -m -G wheel -s /bin/bash $USERNAME
echo $USERNAME:$PASSWORD | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

pacman -S --noconfirm grub networkmanager openssh

systemctl enable NetworkManager
systemctl enable sshd

echo '== Installing GRUB BIOS =='
grub-install --target=i386-pc $DISK
grub-mkconfig -o /boot/grub/grub.cfg

echo '== Installing XFCE GUI =='
pacman -S --noconfirm xorg xfce4 xfce4-goodies lightdm lightdm-gtk-greeter

systemctl enable lightdm
"

echo "== DONE =="
echo "👉 Remove ISO and reboot!"
