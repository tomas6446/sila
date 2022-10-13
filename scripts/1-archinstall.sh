#!/usr/bin/env bash
set -e
timedatectl set-ntp true

# root of the github repository to download files from
gur="https://raw.githubusercontent.com/richard96292/alis/master"

# get user input
curl --output /tmp/get-user-input.sh "${gur}/scripts/1-archinstall/get-user-input.sh"
source /tmp/get-user-input.sh

# format and partition the drive
curl --output /tmp/work-with-drives.sh "${gur}/scripts/1-archinstall/work-with-drives.sh"
source /tmp/work-with-drives.sh

# install basic packages
pacstrap /mnt base base-devel linux linux-headers linux-firmware git vim libnewt btrfs-progs
# generate fstab
genfstab -U /mnt >>/mnt/etc/fstab

# transfer later stages of the script
curl --output /mnt/root/post-archinstall.sh "${gur}/scripts/post-archinstall.sh"
curl --output /mnt/root/2-archinstall.sh "${gur}/scripts/2-archinstall.sh"
chmod +x /mnt/root/2-archinstall.sh # TODO: do i even need to chmod it?

# transfer variables to chroot
cat <<EOF >/mnt/root/vars.sh
hostname="$hostname"
password="$password"
diskname="$diskname"
rootPartition="$rootPartition"
mappedRoot="$mappedRoot"
UEFIBIOS="$UEFIBIOS"
passwordLuks="$passwordLuks"
EOF

# chroot into the new install
arch-chroot /mnt /root/2-archinstall.sh

# clean up
shred -zu -n5 /mnt/root/vars.sh /mnt/root/2-archinstall.sh

# final notice
if (whiptail --title "Congratulations" --yesno "First part of the installation has finished succesfully.\n\nDo you want to reboot your computer now?" 0 0); then
  whiptail --title "Important!" --msgbox "You will have to log in as a root user after rebooting.\n\n" 0 0
  # unmount the drive before rebooting
  umount -R /mnt
  reboot
fi
