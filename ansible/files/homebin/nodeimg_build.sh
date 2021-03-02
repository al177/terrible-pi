#!/bin/bash
set -e

BOOTPART=""
ROOTPART=""

export BOOT=/tmp/boot
export ROOT=/tmp/root

function cleanup()
{
	rm -rf $ROOT | true
	rm -rf $BOOT | true
}

NODEBOOT="/home/pi/tcboot"

rm -rf $NODEBOOT 2>/dev/null | true
mkdir $NODEBOOT

cleanup 
mkdir $BOOT
mkdir $ROOT

# copy boot partition contents to the new remote boot dir and working dir
cp -a /boot/* $NODEBOOT/.
cp -a $NODEBOOT/* $BOOT/.

# clean up before packing up
apt clean

# copy root partition to the new root path

rsync -aAX --info=progress2 / \
	--exclude "/dev/*" \
	--exclude "/proc/*" \
       	--exclude "/sys/*" \
       	--exclude "/srv/*" \
	--exclude "/tmp/*" \
	--exclude "/run/*" \
	--exclude "/mnt/*" \
	--exclude "/media/*" \
	--exclude "/lost+found" \
	--exclude "/home/pi/*" \
	--exclude "/boot/*" \
	--exclude "/var/swap" \
	$ROOT

# make device specific boot paths

for F in 1 2 3 4; do
	mkdir $NODEBOOT/1-1.$F
	cp $NODEBOOT/config.txt $NODEBOOT/cmdline.txt $NODEBOOT/1-1.$F
	sed -i -e "s/rootwait.*$/rootwait modules-load=dwc2,g_ether g_ether.dev_addr=68:08:11:55:aa:0${F}/g" $NODEBOOT/1-1.$F/cmdline.txt
	sed -i -e "s/PARTUUID=[^ ]*/\/dev\/mmcblk0p2/g" $NODEBOOT/1-1.$F/cmdline.txt
	echo "dtoverlay=dwc2" >> $NODEBOOT/1-1.$F/config.txt
done

rm $NODEBOOT/cmdline.txt
rm $NODEBOOT/config.txt
# Use bootcode.bin from the rpiboot distribution
rm $NODEBOOT/bootcode.bin
cp /usr/share/rpiboot/msd/bootcode.bin $NODEBOOT/bootcode.bin

echo "---Fixing up root and boot contents"
# clean out the first stage bootloader so we don't accidentally boot
# from SD
rm $BOOT/bootcode.bin

# remove host-specific network interfaces 
rm $ROOT/etc/network/interfaces.d/usb*
rm $ROOT/etc/network/interfaces.d/br0

# set jumbo frames on the USB network interface
echo 'auto usb0' > $ROOT/etc/network/interfaces.d/usb0
echo 'allow-hotplug usb0' >> $ROOT/etc/network/interfaces.d/usb0
echo '    iface usb0 inet dhcp' >> $ROOT/etc/network/interfaces.d/usb0
echo '    post-up ifconfig usb0 mtu 15000'  >> $ROOT/etc/network/interfaces.d/usb0

# add hostnames for all nodes to the node hosts file
for N in 1 2 3 4; do
	echo "10.1.1.10${N}	node${N}" >> $ROOT/etc/hosts
done
sed -ie "/^127\.0\.1\.1.*/d" $ROOT/etc/hosts
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
tar -czp -C $ROOT -f $NODEBOOT/rootfs.tar.gz .
tar -czp -C $BOOT -f $NODEBOOT/bootfs.tar.gz .

echo "---Fixing perms for the boot dir"
chown -R pi $NODEBOOT

cleanup
