PI_SLOT_SPACING=6;

module terrible_backplane() {
	translate([129.55,-76.46,0.4]) rotate([0,0,180]) import("terrible.stl",convexity=3);
}

module pi_zeros() {

	for(pi_slot=[0:4])
	{
		translate([32.55+(pi_slot*PI_SLOT_SPACING),114.83,-39.8]) rotate([90,0,-90]) {
			import( "pi0computer.stl",convexity=3);
			translate([24.7,0,4.8])
				import( "pi0sdcard.stl",convexity=3);
		}
	}
}

terrible_backplane();
%pi_zeros();
