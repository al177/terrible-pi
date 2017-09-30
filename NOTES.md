Some notes.

-head node creation
	-Packages
		-libusb-1.0-0-dev
		-nfs-kernel-server
		-git
		-pdsh
		-isc-dhcp-server
		-iptables
		-bridge-utils
	-Repos
		-https://github.com/al177/terrible-pi.git
			-This right here
		-https://github.com/burtyb/usbboot.git
			-Raspberry Pi USB bootloader with customizations that help with
				booting a cluster
		-https://github.com/mvp/uhubctl.git
			-Tool to control USB hub port power states
	-Directions
		-Install Raspbian on microSD
		
			-Write the latest Raspbian image to the SD card
		
			-Mount the first FAT partition of the card on another computer
		
			-Copy "wpa_supplicant.conf" from this repo to the card.  Edit
				it so that "YOUR_SSID" is replaced by the WiFi network name
				that you want the head node to connect to, and "YOUR_PASSPHRASE"
				is replaced by the network's key.  Use your Google-fu if you
				can't get it to work.
		
			-Create an empty file "ssh".  Use the UNIX command "touch ssh" or
				just open and save a new file "ssh" with your text editor.
		
		-Boot the microSD on the Pi Zero W
		
		-After 4-5 minutes, try SSHing as "pi" to the Zero W with the hostname
			"raspberrypi", "raspberrypi.lan", or "raspberrypi.local".  Use the
			password "raspberry".  If your router doesn't support Avahi, you
			may have to check the router's DHCP lease logs to see what IP
			the head node has.
		
		-Then update to the latest Raspbian packages:

sudo apt-get -y update && sudo apt-get -y upgrade
			
			You may have to reboot afterwards.

		-Install the necessary packages:
			
sudo apt-get -y install libusb-1.0-0-dev nfs-kernel-server git \
pdsh isc-dhcp-server iptables bridge-utils

		-Enable things that need enabling:

sudo systemctl enable isc-dhcp-server
sudo systemctl enable rpcbind
sudo systemctl enable nfs-kernel-server

		-Build and install the USB hub tool:

cd
git clone https://github.com/mvp/uhubctl.git
pushd uhubctl
make
sudo cp uhubctl /usr/local/bin/.
sudo chown root:root /usr/local/bin/uhubctl
popd

		-Build and install the USB boot tool:
	
git clone https://github.com/burtyb/usbboot.git
pushd usbboot
make
sudo cp rpiboot /usr/local/bin/.
sudo mkdir /usr/share/rpiboot
sudo cp -a msd /usr/share/rpiboot
sudo chown -R root:root /usr/share/rpiboot
sudo chown -R root:root /usr/local/bin/rpiboot
popd

		-Get this repo on the Pi:

git clone https://github.com/al177/terrible-pi.git

		-Copy the config files for the DHCP server, networks, NFS, SSH, and
			hosts, hostname, and startup scripts:

sudo chown -R root:root /home/pi/terrible-pi/etc			
sudo cp -a /home/pi/terrible-pi/etc/* /etc/.

		-Reboot the head node.

		-SSH to the head node again. The config files copied over have
			changed the hostname to "head".  So if you connected as
			"raspberrypi.lan", "raspberrypi", or "raspberrypi.local" above,
			use "head.lan", "head", or "head.local" when reconnecting.

		-Create an NFS directory for the clients

sudo mkdir /srv/pihome
sudo chown pi:pi /srv/pihome
chmod 755 /srv/pihome
mkdir /srv/pihome/.ssh
chmod 700 /srv/pihome/.ssh

		-Make an empty passphrase SSH key so the head can automatically
			connect to the nodes

ssh-keygen -t rsa -f /srv/pihome/.ssh/terrible.rsa -N ""
cp /srv/pihome/.ssh/terrible.rsa.pub /srv/pihome/.ssh/authorized_keys
chmod 600 /srv/pihome/.ssh/authorized_keys
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp /srv/pihome/.ssh/terrible.rsa ~/.ssh/.


		-Enable the DHCP server:


-compute node image generation
		
	-Retrieve a copy of Raspbian Lite from raspberrypi.org:

wget --trust-server-names https://downloads.raspberrypi.org/raspbian_lite_latest

	Note the filename that it downloads as.

	-Prep the boot image:

sudo terrible-pi/nodeimg_build.sh 2017-09-07-raspbian-stretch-lite.zip

	This will take 10-15 minutes.  The result will be a directory "tcboot"
	that contains the boot files and filesystems for the nodes.

	-Turn off all the nodes.  If the nodes all power up in bootstrap mode
		simultaneously, the image transfer script won't work.

sudo uhubctl -r 4 -a off

	-Transfer the SD filesystem to each node, looping over all nodes in series.

for N in 1 2 3 4; do sudo terrible-pi/node_init.sh tcboot $N; done

	This takes 5-10 minutes per node depending on the speed of the SD cards
	on the compute node Pi Zeros.

-compute node booting

	-To boot the compute nodes, first start the rpiboot server in another
		terminal session:

sudo rpiboot -o -l -d /home/pi/tcboot

	-Then cycle power on all of the nodes:

sudo uhubctl -r 4 -a cycle

	-The boot will take 2-3 minutes.  The nodes should be pingable once they are
		done.  

	-Before SSHing to a node in any given session, start the key agent and add
		the SSH key:

eval `ssh-agent`
ssh-add ~/.ssh/terrible.rsa


	-SSH to a node by name:

ssh node1


	-Run a command on all nodes with pdsh:

pdsh -R ssh -w node1,node2,node3,node4 hostname
