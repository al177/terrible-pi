#!/bin/bash

BOOTDIR_PATH=`readlink -f $1`
NODE=$2

UHUBCTL=uhubctl
RPIBOOT=rpiboot


if [ ! -e $BOOTDIR_PATH ]; then
	echo "Missing boot dir path"
	exit 255
fi

if [ -z "$NODE" ]; then
	echo "Must specify node number"
	exit 255
fi

BOOT_MNTPT=/tmp/boot$NODE
ROOT_MNTPT=/tmp/root$NODE

rm -rf $BOOT_MNTPT
mkdir $BOOT_MNTPT

rm -rf $ROOT_MNTPT
mkdir $ROOT_MNTPT

echo "---Cycling power"
$UHUBCTL -r 4 -p $NODE -a cycle

echo "---Putting node ${NODE} into USB MSD mode"
$RPIBOOT

sleep 10

DISKDEV=`ls -1 /dev/disk/by-path/*usb-*.${NODE}*:0`
echo "---Checking ${DISKDEV}"

if [ ! -L $DISKDEV ]; then
      	echo "Could not find mass storage device"
	exit 255
fi

echo -e ",85622,0xC\n,+,L" | sfdisk $DISKDEV
sync

# tell the kernel that the partitions have changed
partx ${DISKDEV}

# need to wait for the symlinks to update
sleep 10
sfdisk -l $DISKDEV
ls -l /dev/disk/by-path

mkdosfs ${DISKDEV}-part1
mkfs.ext4 -F ${DISKDEV}-part2

mount ${DISKDEV}-part1 $BOOT_MNTPT
mount ${DISKDEV}-part2 $ROOT_MNTPT

echo "---Untarring boot partition"
tar -C $BOOT_MNTPT -xzf $BOOTDIR_PATH/bootfs.tar.gz
echo "---Untarring root partition"
tar -C $ROOT_MNTPT -xzf $BOOTDIR_PATH/rootfs.tar.gz

echo "---Fixup hostname for node${NODE}"
sed -i -e "s/raspberrypi/node${NODE}/g" $ROOT_MNTPT/etc/hosts
echo "node${NODE}" > $ROOT_MNTPT/etc/hostname

echo "---Unmounting filesystems"
umount $BOOT_MNTPT
umount $ROOT_MNTPT
rmdir $BOOT_MNTPT
rmdir $ROOT_MNTPT
sync

echo "---Done"
