use <terrible.scad>;


X_EDGE_TO_HEAD_NODE_TOP=6.5;


//{
//    #terrible_backplane();
//    #pi_zeros();
//}

PCB_EDGE_X=38;
PCB_EDGE_XY_CLEARANCE=0.8;
PCB_EDGE_Y=65.3;
PCB_EDGE_Z=0.8;
PCB_EDGE_Z_CLEARANCE=0.2;
PCB_BOT_CLEARANCE=0.5;


PI_BOT=9.4; /* top of PCB to bottom of Pi */
PI_WIDTH=30.0;
PI_WIDTH_CLEARANCE=.8;

PI_CAM_HDR_WIDTH=17.5;
PI_CAM_HDR_HEIGHT=1.4;
PI_CAM_HDR_FROM_EDGE=6.2;
PI_CAM_HDR_EXT=1;

PI_ZERO_BOARD_EDGE_OFS_FROM_0=8.02;
PI_ZERO_BOARD_TOP_OFS_FROM_4=4.58;
PI_ZERO_BOARD_TOP_CLEARANCE=6;
PI_ZERO_BOARD_THICK=1.4;

INT_HEIGHT=PCB_EDGE_Z+PI_BOT+PI_WIDTH+PI_WIDTH_CLEARANCE/2;

SDCARD_WIDTH=12.3;
SDCARD_EXT=4;
SDCARD_FROM_EDGE=10.5;
SDCARD_THICK=2;
SDCARD_Z_FUDGE=0.4;

USB_FROM_0=15;
USB_WIDTH=8.1;
USB_HEIGHT=3.6;
USB_EXT=4;
USB_Z_FUDGE=0.5;

USB_INSET_DEPTH=1.2;
USB_INSET_ADDL_W=3.4;
USB_INSET_ADDL_H=3.4;

CASE_THICK=2;



PI_LOWER_CRADLE_L=5;
PI_LOWER_CRADLE_H=4;
PI_LOWER_CRADLE_NOTCH=2;

PI_UPPER_CRADLE_L=6;
PI_UPPER_CRADLE_H=3;



SEAM_FROM_BACK=10;

PI_SLOT_SPACING=6;

difference() {
difference() {
    outer_shape_curvy();
    
    difference()
    {
        inner_bulk_cutout();
        zero_lower_cradle();
        zero_upper_cradle_far();
    }
    inner_pcb_cutout();
    sdcard_cutouts();
    usb_cutout();
}
    translate([-10,-10,-10]) cube([80,66,80]);
}

module outer_shape() {
    translate([-CASE_THICK, -(CASE_THICK+PI_CAM_HDR_EXT), -(CASE_THICK+PCB_BOT_CLEARANCE)] )
        minkowski() {
            cube([CASE_THICK*2+PCB_EDGE_X,CASE_THICK*2+PCB_EDGE_Y+PI_CAM_HDR_EXT,CASE_THICK*2+INT_HEIGHT+PCB_BOT_CLEARANCE]);
        sphere(r=0.01, $fn=32);
    }
}

module outer_shape_curvy() {
    
    minkowski() {
        inner_bulk_cutout();
        sphere(CASE_THICK,$fn=32);
    }

}

module inner_bulk_cutout() {
    union()
    {
        translate([0, 0, -PCB_BOT_CLEARANCE] ) 
            cube([PCB_EDGE_X, PCB_EDGE_Y,PCB_EDGE_Z+PI_BOT+PCB_BOT_CLEARANCE]);
        
        translate([PI_ZERO_BOARD_EDGE_OFS_FROM_0-PI_ZERO_BOARD_TOP_CLEARANCE,-PI_CAM_HDR_EXT,PI_BOT])
        cube([PI_ZERO_BOARD_TOP_CLEARANCE+PI_ZERO_BOARD_THICK+24,PCB_EDGE_Y+PI_CAM_HDR_EXT,INT_HEIGHT-PI_BOT]);
    }
}

module inner_pcb_cutout() {
translate([-PCB_EDGE_XY_CLEARANCE/2, -PCB_EDGE_XY_CLEARANCE/2, -PCB_EDGE_Z_CLEARANCE/2] ) 
            cube([PCB_EDGE_X+PCB_EDGE_XY_CLEARANCE, PCB_EDGE_Y+PCB_EDGE_XY_CLEARANCE,PCB_EDGE_Z+PCB_EDGE_Z_CLEARANCE]);
 }

module sdcard_cutouts() {
    for(pi_slot=[0:4]) {
        translate([PI_ZERO_BOARD_EDGE_OFS_FROM_0+(pi_slot*PI_SLOT_SPACING)+SDCARD_Z_FUDGE-SDCARD_THICK-PI_ZERO_BOARD_THICK, PCB_EDGE_Y-1, SDCARD_FROM_EDGE+PI_BOT+PCB_EDGE_Z])
            cube([SDCARD_THICK,SDCARD_EXT,SDCARD_WIDTH]);
    }
}

module usb_cutout() {
    union() {
        translate([USB_FROM_0, PCB_EDGE_Y-1, PCB_EDGE_Z-USB_Z_FUDGE])
            cube([USB_WIDTH, USB_EXT, USB_HEIGHT+USB_Z_FUDGE]);
        translate([USB_FROM_0-USB_INSET_ADDL_W/2,PCB_EDGE_Y+CASE_THICK-USB_INSET_DEPTH, PCB_EDGE_Z-USB_Z_FUDGE-USB_INSET_ADDL_H/2])
            cube([USB_WIDTH+USB_INSET_ADDL_W, USB_INSET_DEPTH*2, USB_HEIGHT+USB_Z_FUDGE+USB_INSET_ADDL_W]);
    }
}

module zero_lower_cradle() {
    difference() {
    translate([-0.01, PCB_EDGE_Y-PI_LOWER_CRADLE_L, PCB_EDGE_Z+PI_BOT-PI_LOWER_CRADLE_H+PI_LOWER_CRADLE_NOTCH+0.01] ) 
            cube([PCB_EDGE_X+0.02, PI_LOWER_CRADLE_L+0.01,PI_LOWER_CRADLE_H]);
    for(pi_slot=[0:4]) {
        translate([PI_ZERO_BOARD_EDGE_OFS_FROM_0+(pi_slot*PI_SLOT_SPACING)-PI_ZERO_BOARD_THICK-0.2, PCB_EDGE_Y-PI_LOWER_CRADLE_L-0.01, PCB_EDGE_Z+PI_BOT-PI_WIDTH_CLEARANCE/2+0.01])
            cube([PI_ZERO_BOARD_THICK+0.4,PI_LOWER_CRADLE_L+0.01,PI_LOWER_CRADLE_NOTCH+PI_WIDTH_CLEARANCE/2+0.01]);
    }
    }
}

module zero_upper_cradle_far() {
    difference() {
    translate([-0.01, PCB_EDGE_Y-PI_UPPER_CRADLE_L, INT_HEIGHT-PI_UPPER_CRADLE_H+0.01] ) 
            cube([PCB_EDGE_X+0.02, PI_UPPER_CRADLE_L+0.01,PI_UPPER_CRADLE_H]);
    for(pi_slot=[0:4]) {
        translate([PI_ZERO_BOARD_EDGE_OFS_FROM_0+(pi_slot*PI_SLOT_SPACING)-PI_ZERO_BOARD_THICK-0.2, PCB_EDGE_Y-PI_UPPER_CRADLE_L-0.01, INT_HEIGHT-PI_UPPER_CRADLE_H-0.01])
            cube([PI_ZERO_BOARD_THICK+0.4,PI_UPPER_CRADLE_L+0.01,PI_UPPER_CRADLE_H+PI_WIDTH_CLEARANCE/2+0.01]);
    }
    }
}