#!/usr/bin/env bash
########################################################

release=jessie					# debian release
mirror=							# debian mirror to use
imagesize=1024					# image size in mb
bootsize=128					# boot partition size in mb

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
	kpartx -s $IMG
	kpartx -d $IMG
}

function do_bootstrap {
	wget -q http://archive.raspberrypi.org/debian/raspberrypi.gpg.key
	apt-key add raspberrypi.gpg.key
	apt-key update

	multistrap -d chroot/ -f installer.conf
}

function do_env {
	kpartx -as $IMG

	if [ ! -d chroot ] ; then
		mkdir chroot/
	fi
	mount /dev/mapper/loop0p2 chroot/

    if [ ! -d chroot/boot ] ; then
        mkdir chroot/boot/
    fi
	mount /dev/mapper/loop0p1 chroot/boot/


	if [ ! -a chroot/boot/config.txt ] ; then
		touch chroot/boot/config.txt
	fi
	if [ ! -a chroot/boot/cmdline.txt ] ; then
		touch chroot/boot/cmdline.txt
	fi

}

mk_image
mk_fs
do_env
do_bootstrap
