#!/bin/bash

# Gentoo Minimal Installation Script for Virtual Machine with User and sudo (vda drives)

# Set variables
ROOT_PARTITION="/dev/vda1"   # Replace with your root partition
BOOT_PARTITION="/dev/vda2"   # Replace with your boot partition
SWAP_PARTITION="/dev/vda3"   # Replace with your swap partition

# Format partitions
mkfs.ext4 $ROOT_PARTITION
mkfs.ext2 $BOOT_PARTITION
mkswap $SWAP_PARTITION
swapon $SWAP_PARTITION

# Mount partitions
mount $ROOT_PARTITION /mnt/gentoo
mkdir /mnt/gentoo/boot
mount $BOOT_PARTITION /mnt/gentoo/boot

# Download stage3 tarball
wget http://distfiles.gentoo.org/experimental/amd64/musl/stage3-amd64-musl-<latest>.tar.xz -O /mnt/gentoo/stage3.tar.xz

# Extract stage3 tarball
tar xpvf /mnt/gentoo/stage3.tar.xz -C /mnt/gentoo --xattrs-include='*.*' --numeric-owner

# Download portage snapshot
wget http://distfiles.gentoo.org/snapshots/portage-latest.tar.xz -O /mnt/gentoo/portage.tar.xz
tar xpf /mnt/gentoo/portage.tar.xz -C /mnt/gentoo/usr

# Copy DNS info
cp -L /etc/resolv.conf /mnt/gentoo/etc/

# Chroot into the new environment
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) $PS1"

# Set timezone
echo "America/New_York" > /etc/timezone
emerge --config sys-libs/timezone-data

# Configure locale
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
locale-gen
eselect locale set 3

# Set hostname
echo "mygentoo" > /etc/hostname
echo "127.0.0.1  localhost" > /etc/hosts
echo "::1        localhost" >> /etc/hosts
echo "127.0.1.1  mygentoo.localdomain  mygentoo" >> /etc/hosts

# Install and configure the kernel
emerge --ask sys-kernel/gentoo-sources
emerge --ask sys-kernel/genkernel
genkernel all

# Install bootloader (GRUB in this example)
emerge --ask sys-boot/grub
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg

# Set the root password
passwd

# Create a user named "schneiderman"
echo "Creating user 'schneiderman'"
useradd -m -G users,wheel,audio -s /bin/bash schneiderman

# Set the password for user 'schneiderman'
echo "Set the password for user 'schneiderman':"
passwd schneiderman

# Install sudo
emerge --ask app-admin/sudo

# Configure sudo for user 'schneiderman'
echo "schneiderman ALL=(ALL) ALL" >> /etc/sudoers

# Exit the chroot environment
exit

# Unmount partitions
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount /mnt/gentoo{/proc,/sys,}

echo "Gentoo minimal installation for a virtual machine with user 'schneiderman' and sudo (vda drives) completed. You may now reboot."

