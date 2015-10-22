#!/usr/bin/env bash
########################################################

release=jessie					# debian release
mirror=							# debian mirror to use
imagesize=5						# image size in mb
bootsize=2						# boot partition size in mb

########################################################
set -e

function mk_image {
	IMG=debian-$release-ua-netinst-`date +%Y%m%d`.img
	rm -f $IMG
	rm -f $IMG.bz2
	rm -f $IMG.xz

	bootsize="+$bootsize"M

	dd if=/dev/zero of=$IMG bs=1M count=$imagesize

# scripted. do not indent!
fdisk $IMG <<EOF
n
p
1

$bootsize
t
b
n
p
2


w
EOF
# end script
}

function mk_fs {
	kpartx -as $IMG
	mkfs.vfat /dev/mapper/loop0p1
	mkfs.ext4 /dev/mapper/loop0p2
	kpartx -d $IMG
}

function do_bootstrap {
	sudo multistrap -d chroot/ -f installer.conf
}

function do_env {
	if [ ! -d chroot ] ; then
		mkdir -p chroot/boot
	fi

	kpartx -as $IMG
	mount /dev/mapper/loop0p1 chroot/boot/
	mount /dev/mapper/loop0p2 chroot/

	if [ ! -a chroot/boot/config.txt ] ; then
		touch chroot/boot/config.txt
	fi
	if [ ! -a chroot/boot/cmdline.txt ] ; then
		touch chroot/boot/cmdline.txt
	fi

}

mk_image
mk_fs
