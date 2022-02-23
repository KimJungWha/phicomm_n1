#!/bin/bash
# Maintainer: KimJungWha <beyondjqrz@fomail.com>

MMC="/dev/$(lsblk | grep -o mmcblk. | uniq)"
DIR="/mnt"

#Resize Partition
parted -s -a optimal $MMC mklabel msdos mkpart primary fat32 113MB 650MB mkpart primary ext4 717MB 100%

#Format Partition
mkfs.vfat -F 32 -n ARCHBOOT "${MMC}p1"
yes | mkfs.ext4 -L ARCHROOT "${MMC}p2"

#Mount Partition
mount "${MMC}p2" $DIR
mkdir $DIR/boot
mount "${MMC}p1" $DIR/boot

#Rsync Data To MMC
rsync -avPhHAX --numeric-ids  --delete --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","$DIR/*","/lost+found","/root/"} / $DIR
mkdir $DIR/root

#Set UUID
BOOT_UUID=$(lsblk -n -o UUID "${MMC}p1")
ROOT_UUID=$(lsblk -n -o UUID "${MMC}p2")

sed -i '/root=UUID/d' $DIR/boot/extlinux/extlinux.conf
echo "APPEND root=UUID=$ROOT_UUID rootflags=data=writeback rw console=ttyAML0,115200n8 console=tty0 no_console_suspend consoleblank=0 fsck.fix=yes fsck.repair=yes net.ifnames=0 quiet loglevel=3" >> $DIR/boot/extlinux/extlinux.conf

sed -i "/UUID/d" $DIR/etc/fstab
echo "UUID=${ROOT_UUID} / ext4 rw,relatime 0 1" >> $DIR/etc/fstab 
echo "UUID=${BOOT_UUID} /boot vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2" >> $DIR/etc/fstab

umount -R $DIR

echo -e "\033[32mNow you can unplug the usb drive and reboot! \033[0m"

exit 0

