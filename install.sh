#!/bin/bash

clear

echo "-------------------------------"
echo "Welcome to gentoo installer :)"
echo "-------------------------------"

ping -qc 3 gentoo.org > /dev/null

if [ $? -eq 2 ]; then
    echo "Network not working"
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

read -p "Do you want to use swap? (y/n) " answer

if [ "$answer" = "y" -o "$answer" = "Y" ]; then
    echo "Which partition do you want to format as swap?"
    read swap_part
    mkswap $swap_part
    swapon $swap_part
fi

mkfs.vfat -F 32 $fat_part
mkfs.ext4 $root_part

mkdir --parents /mnt/gentoo
mount $root_part /mnt/gentoo

cd /mnt/gentoo
links "https://gentoo.org/downloads/"

tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
