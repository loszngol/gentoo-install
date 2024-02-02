#!/bin/bash

echo "What do you want your new user to be called?"
read user_name

useradd -m -G users,wheel,audio -s /bin/bash $user_name
passwd $user_name

rm /stage3-*.tar.*
rm /install_vars

echo "app-admin/does persist"
emerge app-admin/doas

touch /etc/doas.conf
echo "permit persist :wheel" > /etc/doas.conf

nano /etc/portage/make.conf

emerge --ask x11-base/xorg-server
env-update
source /etc/profile

read -p "Do you want to nvidia drivers? (y/n) " answer

if [ "$answer" = "y" -o "$answer" = "Y" ]; then
    emerge x11-drivers/nvidia-drivers
else
    emerge x11-drivers/xf86-video-intel
fi

read -p "Do you want to install i3wm? (y/n) " answer

if [ "$answer" = "y" -o "$answer" = "Y" ]; then
    emerge x11-wm/i3

    read -p "Do you want to install picom? (y/n) " answer
    if [ "$answer" = "y" -o "$answer" = "Y" ]; then
        emerge picom
    fi

    read -p "Do you want to install lightDM? (y/n) " answer
    if [ "$answer" = "y" -o "$answer" = "Y" ]; then
        emerge gui-libs/display-manager-init

        rm /etc/conf.d/display-manager
        touch /etc/conf.d/display-manager

        echo "CHECKVT=7" >> /etc/conf.d/display-manager
        echo "DISPLAYMANAGER=\"lightdm\"" >> /etc/conf.d/display-manager

        rc-update add display-manager default
        rc-service display-manager start
    fi
fi


