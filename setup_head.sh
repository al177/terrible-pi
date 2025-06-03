#!/bin/bash
set -e

CFUSER=`whoami`

sudo apt update && sudo apt upgrade -y
sudo apt install -y libusb-1.0-0-dev nfs-kernel-server git \
        pdsh udhcpd iptables bridge-utils screen vim-nox \
        xz-utils
sudo apt remove -y vim-tiny

cd
git clone --depth=1 https://github.com/mvp/uhubctl.git
pushd uhubctl
make
sudo cp uhubctl /usr/local/bin/.
sudo chown root:root /usr/local/bin/uhubctl
popd

git clone --depth=1 https://github.com/raspberrypi/usbboot.git
pushd usbboot
make
sudo cp rpiboot /usr/local/bin/.
sudo mkdir -p /usr/share/rpiboot
sudo cp -a msd /usr/share/rpiboot
sudo chown -R root:root /usr/share/rpiboot
sudo chown -R root:root /usr/local/bin/rpiboot
popd

git clone --depth=1 https://github.com/al177/terrible-pi.git

rm terrible-pi/etc/hosts
rm terrible-pi/etc/hostname
sudo chown -R root:root /home/${CFUSER}/terrible-pi/etc
sudo cp -a /home/${CFUSER}/terrible-pi/etc/* /etc/.
sudo sh -c 'echo -e "\n127.0.1.2	head\n10.1.1.101	node1\n10.1.1.102	node2\n10.1.1.103	node3\n10.1.1.104	node4\n" >> /etc/hosts'

sudo systemctl enable udhcpd
sudo systemctl enable rpcbind
sudo systemctl enable nfs-kernel-server

sudo mkdir -p /srv/pihome
sudo chown ${CFUSER}:${CFUSER} /srv/pihome
chmod 755 /srv/pihome
mkdir -p /srv/pihome/.ssh
chmod 700 /srv/pihome/.ssh

ssh-keygen -t rsa -f /srv/pihome/.ssh/terrible.rsa -N ""
cp /srv/pihome/.ssh/terrible.rsa.pub /srv/pihome/.ssh/authorized_keys
chmod 600 /srv/pihome/.ssh/authorized_keys
#mkdir -p ~/.ssh
#chmod 700 ~/.ssh
cp /srv/pihome/.ssh/terrible.rsa ~/.ssh/.

wget --trust-server-names https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2025-05-13/2025-05-13-raspios-bookworm-armhf-lite.img.xz

sudo reboot
