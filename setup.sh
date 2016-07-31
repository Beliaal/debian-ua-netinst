#!/usr/bin/env bash
########################################################

RELEASE=jessie								# debian release
MIRROR=http://ftp.debian.org/debian/		# debian mirror to use
RASPBERRY=no								# "yes" for raspberry pi mirror, "no" for single partition standard debian
IMGSIZE=2048								# image size in mb
BOOTSIZE=64									# boot partition size in mb (only for rasberry pi)
APTXTRAS=yes								# if yes, add contrib and non-free to the list of repos
QUIET=no									# generate output for debug....

########################################################

set -e


function rpi_image {
	IMG=debian-$RELEASE-ua-netinst-`date +%Y%m%d`.img
	rm -f $IMG > /dev/null 2>&1
	rm -f $IMG.bz2 > /dev/null 2>&1
	rm -f $IMG.xz > /dev/null 2>&1

	BOOTSIZE="+$BOOTSIZE"M
	dd if=/dev/zero of=$IMG bs=1M count=$IMGSIZE > /dev/null 2>&1

# scripted. do not indent!
fdisk $IMG <<EOF
n
p
1

$BOOTSIZE
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

function do_cdebootstrap {
	cdebootstrap --flavour=minimal --allow-unauthenticated --foreign --arch=armhf $RELEASE rootfs/ $MIRROR
}

function do_bootstrap {
	debootstrap --variant=minbase --foreign --arch=armhf $RELEASE rootfs/ $MIRROR

	DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
	LC_ALL=C LANGUAGE=C LANG=C chroot rootfs/ /debootstrap/debootstrap --second-stage

	DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
	LC_ALL=C LANGUAGE=C LANG=C chroot rootfs/ dpkg --configure -a
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

function bootscripts {
	# /boot/config.txt
	echo "# For more options and information see" >> rootfs/boot/config.txt
	echo "# http://www.raspberrypi.org/documentation/configuration/config-txt.md" >> rootfs/boot/config.txt
	echo "# Some settings may impact device functionality. See link above for details" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# uncomment if you get no picture on HDMI for a default "safe" mode" >> rootfs/boot/config.txt
	echo "#hdmi_safe=1" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# uncomment this if your display has a black border of unused pixels visible" >> rootfs/boot/config.txt
	echo "# and your display can output without overscan" >> rootfs/boot/config.txt
	echo "#disable_overscan=1" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# uncomment the following to adjust overscan. Use positive numbers if console" >> rootfs/boot/config.txt
	echo "# goes off screen, and negative if there is too much border" >> rootfs/boot/config.txt
	echo "#overscan_left=16" >> rootfs/boot/config.txt
	echo "#overscan_right=16" >> rootfs/boot/config.txt
	echo "#overscan_top=16" >> rootfs/boot/config.txt
	echo "#overscan_bottom=16" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# uncomment to force a console size. By default it will be display's size minus" >> rootfs/boot/config.txt
	echo "# overscan." >> rootfs/boot/config.txt
	echo "#framebuffer_width=1280" >> rootfs/boot/config.txt
	echo "#framebuffer_height=720" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# uncomment if hdmi display is not detected and composite is being output" >> rootfs/boot/config.txt
	echo "#hdmi_force_hotplug=1" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# uncomment to force a specific HDMI mode (this will force VGA)" >> rootfs/boot/config.txt
	echo "#hdmi_group=1" >> rootfs/boot/config.txt
	echo "#hdmi_mode=1" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# uncomment to force a HDMI mode rather than DVI. This can make audio work in" >> rootfs/boot/config.txt
	echo "# DMT (computer monitor) modes" >> rootfs/boot/config.txt
	echo "#hdmi_drive=2" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# uncomment to increase signal to HDMI, if you have interference, blanking, or" >> rootfs/boot/config.txt
	echo "# no display" >> rootfs/boot/config.txt
	echo "#config_hdmi_boost=4" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# uncomment for composite PAL" >> rootfs/boot/config.txt
	echo "#sdtv_mode=2" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "#uncomment to overclock the arm. 700 MHz is the default." >> rootfs/boot/config.txt
	echo "#arm_freq=800" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# Uncomment some or all of these to enable the optional hardware interfaces" >> rootfs/boot/config.txt
	echo "#dtparam=i2c_arm=on" >> rootfs/boot/config.txt
	echo "#dtparam=i2s=on" >> rootfs/boot/config.txt
	echo "#dtparam=spi=on" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# Uncomment this to enable the lirc-rpi module" >> rootfs/boot/config.txt
	echo "#dtoverlay=lirc-rpi" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# Additional overlays and parameters are documented /boot/overlays/README" >> rootfs/boot/config.txt
	echo "" >> rootfs/boot/config.txt
	echo "# enable raspicam" >> rootfs/boot/config.txt
	echo "start_x=1" >> rootfs/boot/config.txt
	echo "gpu_mem=128" >> rootfs/boot/config.txt

	# /boot/cmdline.txt
	echo "dwc_otg.lpm_enable=0 console=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait" >> rootfs/boot/cmdline.txt

	# /etc/apt/sources.list
	echo "deb http://ftp.debian.org/debian/ jessie main" > rootfs/etc/apt/sources.list
	echo "deb-src http://ftp.debian.org/debian/ jessie main" >> rootfs/etc/apt/sources.list
	echo "" >> rootfs/etc/apt/sources.list
	echo "deb http://security.debian.org/ jessie/updates main" >> rootfs/etc/apt/sources.list
	echo "deb-src http://security.debian.org/ jessie/updates main" >> rootfs/etc/apt/sources.list
	echo "" >> rootfs/etc/apt/sources.list
	echo "# jessie-updates, previously known as 'volatile'" >> rootfs/etc/apt/sources.list
	echo "deb http://ftp.debian.org/debian/ jessie-updates main" >> rootfs/etc/apt/sources.list
	echo "deb-src http://ftp.debian.org/debian/ jessie-updates main" >> rootfs/etc/apt/sources.list

	if [ $APTXTRAS == "yes" ] ; then
		echo "deb http://ftp.debian.org/debian/ jessie contrib non-free" > rootfs/etc/apt/sources.list.d/additional.list
		echo "deb-src http://ftp.debian.org/debian/ jessie contrib non-free" >> rootfs/etc/apt/sources.list.d/additional.list
		echo "" >> rootfs/etc/apt/sources.list.d/additional.list
		echo "deb http://security.debian.org/ jessie/updates contrib non-free" >> rootfs/etc/apt/sources.list.d/additional.list
		echo "deb-src http://security.debian.org/ jessie/updates contrib non-free" >> rootfs/etc/apt/sources.list.d/additional.list
		echo "" >> rootfs/etc/apt/sources.list.d/additional.list
		echo "# jessie-updates, previously known as 'volatile'" >> rootfs/etc/apt/sources.list.d/additional.list
		echo "deb http://ftp.debian.org/debian/ jessie-updates contrib non-free" >> rootfs/etc/apt/sources.list.d/additional.list
		echo "deb-src http://ftp.debian.org/debian/ jessie-updates contrib non-free" >> rootfs/etc/apt/sources.list.d/additional.list
	fi
}




#################### The part that actually runs ####################

BASEDIR=$PWD


if [ $QUIET = "yes" ] ; then
	do_pre		> /dev/null 2>&1
	mk_image	> /dev/null 2>&1
	mk_fs		> /dev/null 2>&1
	do_env		> /dev/null 2>&1
	do_bootstrap	> /dev/null 2>&1
else						# This generates a lot of output. Use for debug purposes...
	do_pre
	mk_image
	mk_fs
	do_env
	do_bootstrap
fi
