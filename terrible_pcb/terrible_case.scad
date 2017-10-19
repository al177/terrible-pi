use <terrible.scad>;
use <parametric-fan.scad>;

// Set true to render for printing
PRODUCTION=true;

SHOW_INNARDS=true;

if(SHOW_INNARDS && !PRODUCTION) {
    translate([0,PCB_EDGE_Y_EXTRA,0]) {
        #terrible_backplane();
        #pi_zeros();
    } 
    translate([PCB_EDGE_X/2,-FAN_THICK/2-FAN_PI_BACK_GAP-0.01,FAN_Z_OFS-PCB_BOT_CLEARANCE/2]) rotate([90,0,0]) fan(FAN_WIDTH, FAN_THICK, 32, 4.3);

}

X_EDGE_TO_HEAD_NODE_TOP=6.5;

PCB_EDGE_X=38;
PCB_EDGE_X_CLEARANCE=0.8;
PCB_EDGE_Y_EXTRA=0;
PCB_EDGE_Y=65.3;
PCB_EDGE_Z=0.8;
PCB_EDGE_Z_CLEARANCE=0.2;
PCB_BOT_CLEARANCE=0.8;


PI_BOT=9.4; /* top of PCB to bottom of Pi */
PI_WIDTH=30.0;
PI_WIDTH_CLEARANCE=.8;

PI_CAM_HDR_WIDTH=17.5;
PI_CAM_HDR_HEIGHT=1.4;
PI_CAM_HDR_FROM_EDGE=6.2;

PI_ZERO_BOARD_EDGE_OFS_FROM_0=8.02;
PI_ZERO_BOARD_TOP_OFS_FROM_4=4.58;
PI_ZERO_BOARD_TOP_CLEARANCE=6;
PI_ZERO_BOARD_THICK=1.4;

INT_HEIGHT=PCB_EDGE_Z+PI_BOT+PI_WIDTH+PI_WIDTH_CLEARANCE/2;

SDCARD_WIDTH=12.3;
SDCARD_EXT=4;
SDCARD_FROM_EDGE=10.5;
SDCARD_THICK=2.5;
SDCARD_Z_FUDGE=0.4;

SD_VENT_WIDTH=19;
SD_VENT_EXT=4;
SD_VENT_FROM_EDGE=6.5;
SD_VENT_THICK=5;
SD_VENT_Z_FUDGE=-0.5;

USB_FROM_0=15;
USB_WIDTH=8.1;
USB_HEIGHT=3.6;
USB_EXT=4;
USB_Z_FUDGE=0.5;

USB_INSET_DEPTH=1.2;
USB_INSET_ADDL_W=3.4;
USB_INSET_ADDL_H=3.4;

CASE_THICK=2.5;

PI_LOWER_CRADLE_L=5;
PI_LOWER_CRADLE_H=4;
PI_LOWER_CRADLE_NOTCH=2;

PI_UPPER_CRADLE_L=6;
PI_UPPER_CRADLE_H=3;

/* Dimensions for standard 40x40x10 box fan */
FAN_THICK=10;
FAN_WIDTH=40;
FAN_HOLE_SPACE=36;

FAN_PI_BACK_GAP=3;
FAN_END_Z_OFS=2;
FAN_CLEARANCE=0.6;
FAN_CASE_INNER_WIDTH=FAN_WIDTH+FAN_CLEARANCE;

FAN_CASE_INSET=FAN_PI_BACK_GAP+FAN_THICK;
FAN_X_OFFSET=(FAN_WIDTH-PCB_EDGE_X)/2;

FAN_Z_OFS=FAN_WIDTH/2;

SEAM_FROM_BACK=10;

PI_SLOT_SPACING=6;

SECURING_PIN_DIA=2.1; //guess at dia for 1.75mm
SECURING_PIN_Y_EXTRA=0.4; //amount to nudge closer to PCB edge


if(PRODUCTION) {
    translate([FAN_X_OFFSET+FAN_CLEARANCE/2+CASE_THICK, CASE_THICK+PCB_EDGE_Z+PCB_BOT_CLEARANCE,PCB_EDGE_Y+CASE_THICK])
        rotate([-90,0,0]) case_body();
} else {
    case_body();
}

module case_body() {
    difference() {
        hull() {
            outer_shape_curvy();
            //fan_end();
            fan_end_minimal();
        }
        
        
        
        difference()
        {
            inner_bulk_cutout();
            
            zero_lower_cradle();
            zero_upper_cradle_far();
        }
        
        inner_pcb_cutout();
        fan_cutout();
        sd_vent_cutouts();
        usb_cutout();
        securing_pins_cutout();
        
    }
}



module outer_shape() {
    translate([-CASE_THICK, -(CASE_THICK), -(CASE_THICK+PCB_BOT_CLEARANCE)] )
        minkowski() {
            cube([CASE_THICK*2+PCB_EDGE_X,CASE_THICK*2+PCB_EDGE_Y,CASE_THICK*2+INT_HEIGHT+PCB_BOT_CLEARANCE]);
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
        
        translate([PI_ZERO_BOARD_EDGE_OFS_FROM_0-PI_ZERO_BOARD_TOP_CLEARANCE,0,PI_BOT])
        cube([PI_ZERO_BOARD_TOP_CLEARANCE+PI_ZERO_BOARD_THICK+24,PCB_EDGE_Y,INT_HEIGHT-PI_BOT]);
    }
}

module fan_cutout() {
    union()
    {
        translate([0, -FAN_CASE_INSET, -PCB_BOT_CLEARANCE] ) 
            cube([PCB_EDGE_X, PCB_EDGE_Y,PCB_EDGE_Z+PI_BOT+PCB_BOT_CLEARANCE]);
        translate([-PCB_EDGE_X_CLEARANCE/2, -FAN_CASE_INSET, -PCB_EDGE_Z_CLEARANCE/2] ) 
            cube([PCB_EDGE_X+PCB_EDGE_X_CLEARANCE, PCB_EDGE_Y+PCB_EDGE_Y_EXTRA,PCB_EDGE_Z+PCB_EDGE_Z_CLEARANCE]);
        
        translate([PI_ZERO_BOARD_EDGE_OFS_FROM_0-PI_ZERO_BOARD_TOP_CLEARANCE,-FAN_CASE_INSET,PI_BOT])
        cube([PI_ZERO_BOARD_TOP_CLEARANCE+PI_ZERO_BOARD_THICK+24,PCB_EDGE_Y,INT_HEIGHT-PI_BOT]);
    
        translate([-FAN_X_OFFSET-FAN_CLEARANCE/2, -FAN_THICK-FAN_PI_BACK_GAP-5, -PCB_BOT_CLEARANCE])
            cube([FAN_CASE_INNER_WIDTH, FAN_THICK+4, FAN_CASE_INNER_WIDTH]);
    }
}

module inner_pcb_cutout() {
translate([-PCB_EDGE_X_CLEARANCE/2, 0, -PCB_EDGE_Z_CLEARANCE/2] ) 
            cube([PCB_EDGE_X+PCB_EDGE_X_CLEARANCE, PCB_EDGE_Y+PCB_EDGE_Y_EXTRA,PCB_EDGE_Z+PCB_EDGE_Z_CLEARANCE]);
 }

module sdcard_cutouts() {
    for(pi_slot=[0:4]) {
        translate([PI_ZERO_BOARD_EDGE_OFS_FROM_0+(pi_slot*PI_SLOT_SPACING)+SDCARD_Z_FUDGE-SDCARD_THICK-PI_ZERO_BOARD_THICK, PCB_EDGE_Y-1, SDCARD_FROM_EDGE+PI_BOT+PCB_EDGE_Z])
            cube([SDCARD_THICK,SDCARD_EXT,SDCARD_WIDTH]);
    }
}

module sd_vent_cutouts() {
    for(pi_slot=[0:4]) {
        translate([PI_ZERO_BOARD_EDGE_OFS_FROM_0+(pi_slot*PI_SLOT_SPACING)+SD_VENT_Z_FUDGE-(SD_VENT_THICK/2)-PI_ZERO_BOARD_THICK, PCB_EDGE_Y-1, SD_VENT_FROM_EDGE+PI_BOT+PCB_EDGE_Z])
            cube([SD_VENT_THICK,SD_VENT_EXT,SD_VENT_WIDTH]);
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

module fan_end() {
     difference() {
        translate([-CASE_THICK/2,-FAN_THICK-FAN_PI_BACK_GAP,-PCB_BOT_CLEARANCE])
         minkowski() {
            cube([FAN_CASE_INNER_WIDTH,FAN_THICK+FAN_PI_BACK_GAP,FAN_CASE_INNER_WIDTH]);
            sphere(CASE_THICK,$fn=32);
        }
        translate([-CASE_THICK/2, -FAN_THICK-FAN_PI_BACK_GAP, -PCB_BOT_CLEARANCE])
            cube([FAN_CASE_INNER_WIDTH, FAN_THICK, FAN_CASE_INNER_WIDTH]);
        BORE_WIDTH=FAN_WIDTH-4.5;
        translate([PCB_EDGE_X/2,-FAN_THICK-0.01,FAN_Z_OFS]) rotate([90,0,0]) cylinder(r=BORE_WIDTH/2, h=20,$fn=32);
    }
}

module fan_end_minimal() {
     
        translate([-FAN_X_OFFSET-FAN_CLEARANCE/2,-FAN_THICK-FAN_PI_BACK_GAP+CASE_THICK,-PCB_BOT_CLEARANCE])
         minkowski() {
            cube([FAN_CASE_INNER_WIDTH,FAN_THICK+FAN_PI_BACK_GAP-CASE_THICK,FAN_CASE_INNER_WIDTH]);
            sphere(CASE_THICK,$fn=32);
        }
}

module securing_pins_cutout() {
    translate([-FAN_X_OFFSET-FAN_CLEARANCE/2-CASE_THICK-0.01,-SECURING_PIN_DIA/2+PCB_EDGE_Y_EXTRA+SECURING_PIN_Y_EXTRA,PCB_EDGE_Z/2])
    rotate([0,90,0])
        cylinder(d=SECURING_PIN_DIA, h=FAN_CASE_INNER_WIDTH+CASE_THICK*2+0.01, $fn=32);
}

