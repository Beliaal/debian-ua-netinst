#!/usr/bin/env bash
########################################################

release=jessie					# debian release
mirror=http://ftp.debian.org/debian/		# debian mirror to use
imagesize=1024					# image size in mb
bootsize=64					# boot partition size in mb

########################################################
set -e

function mk_image {
	IMG=debian-$release-ua-netinst-`date +%Y%m%d`.img
	rm -f $IMG  > /dev/null 2>&1
	rm -f $IMG.bz2  > /dev/null 2>&1
	rm -f $IMG.xz  > /dev/null 2>&1

	bootsize="+$bootsize"M
	dd if=/dev/zero of=$IMG bs=1M count=$imagesize  > /dev/null 2>&1

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
	debootstrap --foreign --arch=armhf jessie rootfs/ $mirror

	DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
	LC_ALL=C LANGUAGE=C LANG=C chroot rootfs/ /debootstrap/debootstrap --second-stage
}

function do_pre {
	apt-get update

	mkdir tmp
	cd tmp

	wget http://ftp.debian.org/debian/pool/main/d/debootstrap/debootstrap_1.0.75_all.deb
	dpkg -i debootstrap_1.0.75_all.deb
	apt-get install kpartx

	cd ..
	rm -fr tmp

	if [ ! -d rootfs ] ; then
                mkdir rootfs/
        fi
}

function do_env {
	kpartx -as $IMG

	mount /dev/mapper/loop0p2 rootfs/

	if [ ! -d rootfs/boot ] ; then
		mkdir rootfs/boot/
	fi
	mount /dev/mapper/loop0p1 rootfs/boot/


	if [ ! -a rootfs/boot/config.txt ] ; then
		touch rootfs/boot/config.txt
	fi
	if [ ! -a rootfs/boot/cmdline.txt ] ; then
		touch rootfs/boot/cmdline.txt
	fi
}













#################### The part that actually runs ####################

do_pre		> /dev/null 2>&1
mk_image	> /dev/null 2>&1
mk_fs		> /dev/null 2>&1
do_env
do_bootstrap
