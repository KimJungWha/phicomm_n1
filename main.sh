#!/bin/bash
# Maintainer: KimJungWha <beyondjqrz@fomail.com>

DIR="/rootfs"
PASSWORD="123"

pacman -Sy arch-install-scripts --noconfirm

pacstrap $DIR base base-devel sudo vim parted openssh uboot-tools rsync dosfstools archlinux-keyring

echo -e "en_US.UTF-8 UTF-8\n en_GB.UTF-8 UTF-8" >> $DIR/etc/locale.gen
echo 'Phicomm-N1' > $DIR/etc/hostname
echo -e '127.0.0.1\tPhicomm-N1' >> $DIR/etc/hosts
echo 'PermitRootLogin yes' >> $DIR/etc/ssh/sshd_config
sed -i '/^#.*%wheel/s/^# //g'$DIR/etc/sudoers
sed -i '2 i Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/$arch/$repo' $DIR/etc/pacman.d/mirrorlist

cat > $DIR/etc/systemd/network/eth.network <<-EOF
	[Match]
	Name=eth0

	[Network]
	DHCP=ipv4

	# Static 
	# Address=192.168.2.253/24
	# Gateway=192.168.2.254

	[Link]
	# Set to yes to disable this network
	Unmanaged=no
EOF

cat >> $DIR/etc/locale.conf <<-EOF
	LANG=en_US.UTF-8
	LC_TIME=en_GB.UTF-8
EOF

cat >> $DIR/etc/pacman.conf <<-'EOF'
	[archlinuxcn]
	Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
EOF


cp -rfv /file/uboot/* $DIR/boot
cp -rfv /file/linux* $DIR/
cp -rfv /file/{install,resize}.sh $DIR/root/
cp -rfv $DIR/etc/makepkg.conf{,.bak}
cp -rfv /file/makepkg.conf $DIR/etc/makepkg.conf

#mount --bind $DIR $DIR
arch-chroot $DIR /bin/bash <<-EOF
	locale-gen
	echo 'root:$PASSWORD' | chpasswd

	systemctl enable sshd
	systemctl enable systemd-networkd
	systemctl enable systemd-resolved

	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

	pacman-key --init
	pacman-key --populate archlinuxarm
	pacman -Syyu --noconfirm --needed archlinuxcn-keyring
	pacman -U /linux-phicomm-n1* --noconfirm
	yes | pacman -Scc
EOF

rm -rfv $DIR/linux-phicomm-n1*
rm -rfv $DIR/root/.bash_history

exit 0
