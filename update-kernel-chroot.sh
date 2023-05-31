#! /bin/bash

# Inside the livecd environment

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts

export HOME=/root
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

# copy required modules and hook to copy platform firmware to initramfs-tools
# cp /modules_x13s /etc/initramfs-tools/modules
# cp /qcom-soc-firmware /etc/initramfs-tools/hooks/

# install kernel copied from earlier
# install aarch64-laptops packages for Qualcomm platforms
dpkg -i /linux-image-*.deb

umount /dev/pts
umount /sys
umount /proc

printf "exiting chroot\n"

# exit the chroot environment
exit
