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

echo "sys-kernel/installkernel dracut grub" > /etc/portage/package.use/installkernel

read -p "Do you want to use a binary kernel?" answer
if [ "$answer" = "y" -o "$answer" = "Y" ]; then
    emerge sys-kernel/gentoo-kernel-bin
else
    emerge sys-kernel/gentoo-kernel
fi

emerge --depclean
