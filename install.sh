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

wget "https://raw.githubusercontent.com/loszngol/gentoo-install/main/install_stage2.sh"
mv install_stage2.sh /mnt/gentoo
chmod +x /mnt/gentoo/install_stage2.sh

chroot /mnt/gentoo /bin/bash install_stage2.sh
