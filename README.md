# terrible-pi



![](https://i.imgur.com/5njScmk.jpg) ![](https://i.imgur.com/kaebvPF.jpg)

*A supercomputer, but fun sized. And not super.*

In this repo you'll find hardware designs for the Terrible-Pi, a cluster
computer made from four Raspberry Pi Zero boards used as compute elements
and one Raspberry Pi Zero W as a head node and network router.

terrible-pi is based around a USB backplane that powers and interconnects
all five Pi Zeros and allows the head node to control power to each of the
compute nodes.  The USB boot feature of the Pi Zero is used to automate
deployment of new OS images to each compute node.

Up to date news on this project can be found at [this Hackaday project.](https://hackaday.io/project/27142-terrible-cluster)


Repo Contents
-------------
The terrible_pcb directory has a board design for the backplane and a 3D printable case.  See terrible_pcb/README for instructions for printing the case and the backplane board.

`etc` contains config files to be copied on top of the Raspbian install for
the head node.

wpa_supplicant.conf is a template WiFi config for the head node.  This is used
for headless setup of the head node Raspbian SD card for remote SSH access.

`nodeimg_build.sh` is a script for extracting a Raspbian distribution image into
a set of files used to deploy new compute nodes.

`node_init.sh` is a script used to upload the compute node Raspbian generated
by `nodeimg_build.sh` to the SD card of a compute node.

terrible-pi Install and Usage Guide
===================================

Setting up a terrible-pi cluster head node
------------------------------------------

1. Get the latest Raspbian (https://downloads.raspberrypi.org/raspbian_lite_latest)
   and install to a microSD
   
2. Mount the first (FAT) partition of the card on a PC.
		
3. Copy "wpa_supplicant.conf" from this repo to the card.  Edit it so that
   "YOUR_SSID" is replaced by the WiFi network name that you want the head node
   to connect to, and "YOUR_PASSPHRASE" is replaced by the network's key.  Use
   your Google-fu if you can't get it to work.
		
4. Create an empty file on the card named "ssh".  Use the UNIX command "touch
   ssh" or just open and save a new file "ssh" with your text editor.
		
5. Boot the microSD on the Pi Zero W
		
6. After 4-5 minutes, try SSHing as "pi" to the Zero W with the hostname
   "raspberrypi", "raspberrypi.lan", or "raspberrypi.local".  Use the password
   "raspberry".  If your router isn't serving DNS for local domains, you may
   have to check the router's DHCP lease logs to see what IP the head node has.
		
7. Now that you're logged into the Pi Zero W, update to the latest Raspbian
   packages:

```
sudo apt-get -y update && sudo apt-get -y upgrade
```
			
8. Install the necessary packages:
			
```
sudo apt-get -y install libusb-1.0-0-dev nfs-kernel-server git \
pdsh udhcpd iptables bridge-utils
```
9. Build and install the USB hub tool:

```
cd
git clone https://github.com/mvp/uhubctl.git
pushd uhubctl
make
sudo cp uhubctl /usr/local/bin/.
sudo chown root:root /usr/local/bin/uhubctl
popd
```
10. Build and install the USB boot tool:
	
```
git clone https://github.com/raspberrypi/usbboot.git
pushd usbboot
make
sudo cp rpiboot /usr/local/bin/.
sudo mkdir /usr/share/rpiboot
sudo cp -a msd /usr/share/rpiboot
sudo chown -R root:root /usr/share/rpiboot
sudo chown -R root:root /usr/local/bin/rpiboot
popd
```
11. Get this repo on the Pi:

```
git clone https://github.com/al177/terrible-pi.git
```

12. Copy the config files for the DHCP server, networks, NFS, SSH, and
hosts, hostname, and startup scripts:

```
sudo chown -R root:root /home/pi/terrible-pi/etc			
sudo cp -a /home/pi/terrible-pi/etc/* /etc/.
```		
13. Enable necessary services:

```
sudo systemctl enable udhcpd
sudo systemctl enable rpcbind
sudo systemctl enable nfs-kernel-server
```
14. Create an NFS directory for the clients:

```
sudo mkdir /srv/pihome
sudo chown pi:pi /srv/pihome
chmod 755 /srv/pihome
mkdir /srv/pihome/.ssh
chmod 700 /srv/pihome/.ssh
```

15. Reboot the head node.

16. SSH to the head node again. The config files copied over have changed the
    hostname to "head".  So if you connected as "raspberrypi.lan",
    "raspberrypi", or "raspberrypi.local" above, use "head.lan", "head", or
    "head.local" when reconnecting.

17. Make an empty passphrase SSH key so the head can automatically connect to
    the nodes:

```
ssh-keygen -t rsa -f /srv/pihome/.ssh/terrible.rsa -N ""
cp /srv/pihome/.ssh/terrible.rsa.pub /srv/pihome/.ssh/authorized_keys
chmod 600 /srv/pihome/.ssh/authorized_keys
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp /srv/pihome/.ssh/terrible.rsa ~/.ssh/.
```

Setting up terrible cluster compute nodes
-----------------------------------------

### Creating the compute node filesystem

1. Get the Raspbian Lite zip file on the head node in /home/pi.  This can be
   the zip used to create the head node microSD card, or can be downloaded by:

```
wget --trust-server-names https://downloads.raspberrypi.org/raspbian_lite_latest
```
	 
Note the filename that it downloads as.

2. Prep the boot image:

```
sudo terrible-pi/nodeimg_build.sh 2017-09-07-raspbian-stretch-lite.zip
```
	
This will take 10-15 minutes.  The result will be a directory "tcboot"
that contains the boot files and filesystems for the nodes.  This process
needs to be repeated only when changing or upgrading the Raspbian install on
the compute nodes.

### Deploying Raspbian to the compute nodes

1. Insure that the microSD cards in nodes do not contain the Raspberry Pi
   bootloader, or the USB boot method used to manage this cluster will not work.
   Insure that "bootcode.bin" does not exist in the root of any of the
   partitions on any of the cards.  If in doubt, do a full erase on the SD card
   to wipe out the bootloader in any of the partitions.
	 
2. Turn off all the nodes.  If the nodes all power up in bootstrap mode
   simultaneously, the image transfer script won't work.

```
sudo uhubctl -r 4 -a off
```

3. Transfer the SD filesystem to each node, looping over all nodes in series:

```
for N in 1 2 3 4; do sudo terrible-pi/node_init.sh tcboot $N; done
```

This takes 5-10 minutes per node depending on the speed of the SD cards
on the compute node Pi Zeros.

Terrible cluster management
---------------------------

### Booting the cluster

To boot the compute nodes, first start the rpiboot server in another
terminal session:

```
sudo rpiboot -o -l -d /home/pi/tcboot
```

Then cycle power on all of the nodes:

```
sudo uhubctl -r 4 -a cycle
```

The boot will take 2-3 minutes.  The nodes should be pingable once they are
done.  

### Connecting to the nodes

Before SSHing to a node in any given session, start the key agent and add
the SSH key:

```
eval `ssh-agent`
ssh-add ~/.ssh/terrible.rsa
```

You can SSH to a node by name:

```
ssh node1
```

Or you can run a command on all nodes with pdsh:

```
pdsh -R ssh -w node1,node2,node3,node4 hostname
```


Raspberry Pi Zero 1.3 models
[pi0computer.stl and pi0sdcard.stl](https://www.thingiverse.com/thing:2101674)
are created by jdhorvat and licensed CC-BY-NC.  [OpenSCAD parametric fan model](https://www.thingiverse.com/thing:625905) is created by GelatinousSlime and licensed CC-BY-SA. All other files in this tree are by Andrew Litt and licensed as 
[CC-BY-SA.](https://creativecommons.org/licenses/by-sa/4.0/)
