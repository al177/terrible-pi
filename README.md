# terrible-pi
*A supercomputer, but fun sized. And not super.*

In this repo you'll find hardware designs for the Terrible-Pi, a cluster computer made from
four Raspberry Pi Zero boards used as compute elements and one Raspberry Pi Zero W as a head
node and network router.

Up to date news on this project can be found at [this Hackaday project.]
(https://hackaday.io/project/27142-terrible-cluster)

The terrible_pcb directory has a board design for a compact USB hub "backplane" that all five
Pi Zero nodes plug into for communications and backplane.  The four compute nodes are used in
USB device (OTG) mode via the hub's downstream ports, and the head node connects as a USB host.
There is a USB power switch for each compute node port that is controlled by the hub chip
using the standard USB port power management APIs.

In the top of the repo are the scripts and documentation needed to set up the head node,
create and deploy a boot image for the compute nodes, and manage the nodes.

All files in this tree are by Andrew Litt and licensed as [CC-BY-SA.](https://creativecommons.org/licenses/by-sa/4.0/)
