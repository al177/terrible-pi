#!/bin/bash

IMGLOOP=""
BOOTPART=""
ROOTPART=""

BOOT=/tmp/boot
ROOT=/tmp/root

function unmount_cleanup()
{
	umount $ROOT
	umount $BOOT
	rmdir $ROOT
	rmdir $BOOT
	losetup -d $IMGLOOP
	rm $IMGFILE
}

if [ -z "$1" ]; then
	echo "Must pass a Raspbian .zip file on the command line"
	exit 255
fi

unzip -o $1
IMGBASENAME=`sed -e "s/\.zip//g" <<< "$1"`

IMGFILE="${IMGBASENAME}.img"
BOOTDIR="tcboot"
rm -rf $BOOTDIR
mkdir $BOOTDIR

if [ ! -e $IMGFILE ]; then
	echo "Missing Raspbian .img file"
	exit 255
fi

IMGLOOP=`losetup -f`
losetup -P $IMGLOOP $IMGFILE

echo $IMGLOOP
sync
sleep 10
BOOTPART=${IMGLOOP}p1
ROOTPART=${IMGLOOP}p2

if [ ! -e $BOOTPART ]; then

	echo "Missing boot partition"
	unmount_cleanup
	exit 255
fi

if [ ! -e $ROOTPART ]; then

	echo "Missing root partition"
	unmount_cleanup
	exit 255
fi

mkdir $BOOT
mkdir $ROOT
mount $BOOTPART $BOOT
mount $ROOTPART $ROOT

# copy boot partition contents to the new remote boot dir
cp -a $BOOT/* $BOOTDIR/.

# make device specific boot paths

for F in 1 2 3 4; do
	mkdir $BOOTDIR/1-1.$F
	cp $BOOTDIR/config.txt $BOOTDIR/cmdline.txt $BOOTDIR/1-1.$F
	sed -i -e "s/rootwait.*$/rootwait modules-load=dwc2,g_ether g_ether.dev_addr=68:08:11:55:aa:0${F}/g" $BOOTDIR/1-1.$F/cmdline.txt
	sed -i -e "s/PARTUUID=[^ ]*/\/dev\/mmcblk0p2/g" $BOOTDIR/1-1.$F/cmdline.txt
	echo "dtoverlay=dwc2" >> $BOOTDIR/1-1.$F/config.txt
done

rm $BOOTDIR/cmdline.txt
rm $BOOTDIR/config.txt
# Use bootcode.bin from the rpiboot distribution
rm $BOOTDIR/bootcode.bin


echo "---Fixing up root and boot contents"
# clean out the first stage bootloader so we don't accidentally boot
# from SD
rm $BOOT/bootcode.bin

# enable SSH
touch $BOOT/ssh

# disable host key checking for the nodes
echo 'Host "node?"' >> $ROOT/etc/ssh/ssh_config
echo '    StrictHostKeyChecking no' >> $ROOT/etc/ssh/ssh_config
echo '    UserKnownHostsFile /dev/null' >> $ROOT/etc/ssh/ssh_config
echo '    IdentityFile /srv/pihome/.ssh/terrible.rsa' >> $ROOT/etc/ssh/ssh_config
echo 'Host "head"' >> $ROOT/etc/ssh/ssh_config
echo '    StrictHostKeyChecking no' >> $ROOT/etc/ssh/ssh_config
echo '    UserKnownHostsFile /dev/null' >> $ROOT/etc/ssh/ssh_config
echo '    IdentityFile /srv/pihome/.ssh/terrible.rsa' >> $ROOT/etc/ssh/ssh_config

# set jumbo frames on the USB network interface
echo 'auto usb0' > $ROOT/etc/network/interfaces.d/usb0
echo 'allow-hotplug usb0' >> $ROOT/etc/network/interfaces.d/usb0
echo '    iface usb0 inet dhcp' >> $ROOT/etc/network/interfaces.d/usb0
echo '    post-up ifconfig usb0 mtu 15000'  >> $ROOT/etc/network/interfaces.d/usb0

# add hostnames for all nodes to the node hosts file
for N in 1 2 3 4; do
	echo "10.1.1.10${N}	node${N}" >> $ROOT/etc/hosts
done
echo "10.1.1.1	head" >> $ROOT/etc/hosts

# set up home dir nfs mount
echo "head:/srv/pihome /home/pi       nfs defaults,noatime,nolock,x-systemd.automount 0 0" >> $ROOT/etc/fstab

# disable HDMI on boot
sed -i -e "$ i /usr/bin/tvservice -o" $ROOT/etc/rc.local

# make LED show the heartbeat
sed -i -e "$ i echo heartbeat > /sys/class/leds/led0/trigger" $ROOT/etc/rc.local

# switch fstab to using mmcblk partitions
sed -i -e "s/PARTUUID=[^ \t]*\([12][ \t]\)/\/dev\/mmcblk0p\1/g" $ROOT/etc/fstab

echo "---Tarring up the filesystems"
tar -czp -C $ROOT -f $BOOTDIR/rootfs.tar.gz .
tar -czp -C $BOOT -f $BOOTDIR/bootfs.tar.gz .

echo "---Fixing perms for the boot dir"
chown -R pi $BOOTDIR

unmount_cleanup
