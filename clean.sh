#!/usr/bin/env bash

umount rootfs/boot
umount rootfs
kpartx -d debian-jessie-ua-netinst-*.img
rm -fr debian-jessie-ua-netinst-*.img
rm -fr rootfs
