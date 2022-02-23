#!/bin/bash
# Maintainer: KimJungWha <beyondjqrz@fomail.com>

cat > /etc/systemd/system/resizefs.service <<-EOF
	[Unit]
	Description=Resize the root filesystem to fill partition
	DefaultDependencies=no
	Conflicts=shutdown.target
	After=systemd-remount-fs.service
	Before=systemd-sysusers.service sysinit.target shutdown.target
	[Service]
	Type=oneshot
	RemainAfterExit=yes
	ExecStart=/usr/bin/resizefs
	StandardOutput=tty
	StandardInput=tty
	StandardError=tty
	[Install]
	WantedBy=sysinit.target
EOF

cat > /usr/bin/resizefs <<'EOF'
#!/bin/bash
set -aux

ROOT=$(findmnt / -o source -n)
DEV=${ROOT%?}
NUM=${ROOT:0-1}
yes | parted $DEV resizepart $NUM 100%
partprobe
resize2fs "$ROOT"
systemctl disable resizefs
rm -rf /usr/bin/resizefs
rm -rf /etc/systemd/system/resizefs.service
EOF

chmod +x /usr/bin/resizefs
systemctl enable resizefs

echo -e "\033[32mNow you can reboot! \nThe system will resizepart on next boot \033[0m"

exit 0
