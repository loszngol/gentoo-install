#!/bin/bash

clear

echo "-------------------------------"
echo "Welcome to gentoo installer :)"
echo "-------------------------------"

ping -qc 3 gentoo.org > /dev/null

if [ $? -eq 2 ]; then
    echo "Network not working"
    exit
else
    echo "Network working"
fi

clear
lsblk

echo "Which disk do you want to partition"
read disk

cfdisk $disk

echo "Which partition wo you want to farmat as fat?"
read fat_part

echo "Which partition do you want to format as ext4?"
read root_part

read -p "Do you want to use swap? (y/n) " is_swap

if [ "$is_swap" = "y" -o "$is_swap" = "Y" ]; then
    echo "Which partition do you want to format as swap?"
    read swap_part

    echo "Creating swap partition"
    mkswap $swap_part
    echo "Mounting swap partition"
    swapon $swap_part
fi

echo "Making boot partition"
mkfs.vfat -F 32 $fat_part
echo "Formating root partition as ext4"
mkfs.ext4 $root_part

mkdir --parents -v /mnt/gentoo
echo "Mounting filesystem on /mnt/gentoo"
mount $root_part /mnt/gentoo

cd /mnt/gentoo
links "https://gentoo.org/downloads/"

tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

nano /mnt/gentoo/etc/portage/make.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

read -p "Does your system run UEFI (y/n) " is_uefi
if [ "$is_uefi" = "y" -o "$is_uefi" = "Y" ]; then
    mkdir -v /efi
    mount $fat_part /efi
else
    mount $fat_part /boot
fi

emerge-webrsync

read -p "Do you want to select mirrors? (y/n) " mirrorselect
if [ "$mirrorselect" = "y" -o "$mirrorselect" = Y ]; then
    emerge --verbose --oneshot app-portage/mirrorselect
    mirrorselect -i -o >> /etc/portage/make.conf
fi

mkdir --parents /etc/portage/repos.conf
cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf

emerge --sync

eselect profile list
read -p "Which profile to use?" profile
eselect profile set $profile

read -p "Do you want to make any changes to make.conf? (y/n) " answer
if [ "$answer" = "y" -o "$answer" = "Y" ]; then
    nano /etc/portage/make.conf
fi

emerge app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

emerge --verbose --update --deep --newuse @world
emerge --depclean

read -p "Set a timezone eg. Europe/Brussels " timezone
echo $timezone > /etc/timezone
emerge --config sys-libs/timezone-data

nano /etc/locale.gen
locale-gen

eselect locale list
read -p "Which locale to use?" locale
eselect locale set $locale

env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

emerge --ask sys-kernel/linux-firmware
read -p "Do you want to install intel micocode? (y/n) " intel_microcode

if [ "$intel_microcode" = "y" -o "$intel_microcode" = "Y" ]; then
    emerge sys-firmware/intel-microcode
fi

echo "sys-kernel/installkernel dracut" > /etc/portage/package.use/installkernel

read -p "Do you want to use a binary kernel?" answer
if [ "$answer" = "y" -o "$answer" = "Y" ]; then
    emerge sys-kernel/gentoo-kernel-bin
else
    emerge sys-kernel/gentoo-kernel
fi

emerge --depclean
