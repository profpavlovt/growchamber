//-----------------------------------------------------------------------
// GrowChamber controller enclosure  (YAPP_Box v3)
//
// Layout derived from GrowChamberPCB.kicad_pcb:
//   Delivered panel = 100 x 100 mm, split by a scored line at KiCad X=137.34.
//     * MAIN board  : 68.34 (X, back<->front) x 100 (Y) mm  -> sits flat in the box
//     * FACEPLATE    : 31.66 (X) x 100 (Y) mm  -> razored off, becomes the FRONT wall
//
//   Faceplate carries all the user connectors/LEDs/switches. When mounted as the
//   front wall, everything faces OUT except:
//        U2      2x13 IDC  (mates to main-board U4 via ribbon)  -> faces INTO box
//        Power_FP1 screw terminal (12V in)                      -> faces INTO box
//
//   Main-board mounting holes (M3, KiCad-relative to panel back-left @ 69,36):
//        (5.73, 5) (62.43, 5) (5.73, 95) (62.43, 95)
//   Faceplate mounting holes (M3): fx=15.86 at fy=5 and fy=95
//-----------------------------------------------------------------------

//-- !! These must be defined BEFORE the include below. !!
//-- cutoutsBack is also assigned inside YAPPgenerator_v3.scad, so OpenSCAD
//-- evaluates our cutoutsBack expression at the INCLUDE's position, not at the
//-- line we write it on. Anything it references must already exist here.
//-- (A freshly-named variable would be fine; a YAPP-predefined one is not.)
//
//-- Mains group offset: slides the C14/C13 back-wall modules LEFT so their
//-- bodies (~30 mm deep) stop clear of the PSU footprint at psuYin = 110.
//-- Less negative = closer to the PSU.
mainsShiftY = -38;
c14CtrY     = 115.5 + mainsShiftY;   // C14 combo centre Y  ->  77.5
                                     // (SNAP-IN module: no ears, no screw holes -
                                     //  the panel cutout alone retains it)
c13CtrY     = 116.9 + mainsShiftY;   // C13 outlet centre Y ->  78.9
c13CtrZ     = 53.75;
c13EarPitch = 40;                    // C13 ears: HORIZONTAL pair, in line with
                                     // the socket centre                <-- measure

//-- PSU side mounts (same must-precede-the-include rule: cutoutsRight is
//-- YAPP-predefined too). Per the LRS-50 datasheet the supply has 2x M3 tapped
//-- holes, L=3.0 mm deep, BOTH on one side face: 55 mm apart, the first 20.5 mm
//-- from the terminal end, on a line 40.5 mm up from the supply's base.
//-- That face sits flush against the box's right wall, so these are plain
//-- CLEARANCE holes - the screw threads into the supply's own metal, which is
//-- far stronger than anything printed. No bosses.
psuX0      = 3;                  // PSU terminal end, from the back inner region (X)
psuRiserH  = 8;                  // riser rails the bottom flange rests on
psuHole1X  = psuX0 + 20.5;       // first M3 hole, along the box length
psuHolePitch = 55;               // datasheet spacing between the two holes
psuHoleZ   = psuRiserH + 40.5;   // 40.5 above the supply's base, which sits on the risers
psuHoleR   = 1.7;                // Ø3.4 clearance for M3

include <YAPPgenerator_v3.scad>



//-- which part(s) to print
printBaseShell  = true;
printLidShell   = true;

//---------------------------------------------------------------------
//  MAIN PCB (the 68.34 x 100 board that lies flat in the base)
//---------------------------------------------------------------------
pcbLength           = 68.34;   // X : back <-> front (front edge = razor cut = faceplate)
pcbWidth            = 100;      // Y : left <-> right
pcbThickness        = 1.6;
standoffHeight      = 4.0;      // lift PCB off the floor to clear bottom-side solder
standoffDiameter    = 6;
standoffPinDiameter = 2.8;      // locating pin into the 3.2 mm M3 holes
standoffHoleSlack   = 0.4;

pcb =
[
  ["Main", pcbLength,pcbWidth, 0,0, pcbThickness, standoffHeight, standoffDiameter, standoffPinDiameter, standoffHoleSlack]
];

//---------------------------------------------------------------------
//  Box shell
//---------------------------------------------------------------------
//-- padding between the main pcb and the inside wall
//-- FRONT gap must clear the deepest faceplate-mounted parts:
//--   Power_FP1 screw terminal = 14 mm deep, and U2 shrouded IDC box header +
//--   mated ribbon socket + cable service loop to main-board U4 (~20 mm).
//-- RIGHT gap is enlarged to hold the LRS-50-12 PSU standing on edge (see below).
//-- BACK gap enlarged so the PSU's 99 mm length fits along the right wall.
paddingFront        = 25;
paddingBack         = 8;
paddingRight        = 36;   // PSU zone: 30 mm PSU depth + clearance
paddingLeft         = 2;

wallThickness       = 2.0;
basePlaneThickness  = 1.5;
lidPlaneThickness   = 1.5;

//-- height: interior must clear the tallest main-board part, the 31.66 mm faceplate
//-- front wall, the ILI9341 on the BACK wall, AND the LRS-50-12 PSU which stands
//-- 82 mm tall on an ~8 mm riser.  The PSU is what drives the height here.
baseWallHeight      = 90;
lidWallHeight       = 6;

ridgeHeight         = 5.0;
ridgeSlack          = 0.3;
roundRadius         = 3.0;
boxType             = 0;

printerLayerHeight  = 0.2;

//---------------------------------------------------------------------
//  CONTROL / preview helpers
//---------------------------------------------------------------------
showSideBySide  = true;
showPCB         = true;    // <-- turn on to check main-board fit
showMarkersPCB  = true;
showOrientation = true;

//===================================================================
//  PCB Supports : locating standoffs with pins into the 4 main-board
//  M3 holes @ (5.73,5) (62.43,5) (5.73,95) (62.43,95)  [yappCoordPCB]
//  (positions are relative to the PCB, so they track it automatically)
//===================================================================
//-- SCREW-DOWN stands: yappHole + yappSelfThreading gives each standoff a
//-- self-tapping bore instead of a locating pin, so an M3 screw passes down
//-- through the PCB and threads into the printed stand - the board is clamped,
//-- not just located. yappBaseOnly keeps the lid clear (no opposing post).
pcbStands =
[
  [ 5.73,  5, yappHole, yappSelfThreading, yappBaseOnly],
  [62.43,  5, yappHole, yappSelfThreading, yappBaseOnly],
  [ 5.73, 95, yappHole, yappSelfThreading, yappBaseOnly],
  [62.43, 95, yappHole, yappSelfThreading, yappBaseOnly]
];

connectors  = [];

//===================================================================
//  Cutouts
//===================================================================
//-------------------------------------------------------------------
//  ILI9341 2.8" module  (board 86 x 50, holes 81 x 45, active 57.6 x 43.2)
//  Two candidate mounts (LID + BACK) - keep whichever you build, delete the other.
//  Box outer:  L = 100.34 (2*wall+padBack+pcbLen+padFront)
//              W = 108.00 (2*wall+padLeft+padRight+pcbWidth)
//  Active window is offset 8 mm from board centre toward the non-pin end (VERIFY).
//-------------------------------------------------------------------
cutoutsBase  = [];

//-- LID : long axis along box length (X). board ctr (44.17,54); active ctr (52.17,54)
//   [fromBack(X), fromLeft(Y), width(Y), length(X), r, shape, coord]
//   fromBack = 52.17 - 57.6/2 = 23.37 ; fromLeft = 54 - 43.2/2 = 32.40
cutoutsLid   =
[
  [23.37, 32.40, 43.2, 57.6, 0, yappRectangle, yappCoordBox]
];

//-- FRONT wall : window for the faceplate's external components + DC099 jack.
//   [fromLeft(Y), fromBottom(Z), width, height, radius, shape, coord]
//   For yappCircle: pos is the bounding-box corner, so center = (p0+r, p1+r).
//   DC099 barrel jack (12V -> LEDs): Ø8 hole, centered Y=54, Z=45, ABOVE window.
//   *** PLACEHOLDER: set the DC099 hole Ø to your panel-mount jack. ***
cutoutsFront =
[
  [6, 3, 96, 29, 0, yappRectangle, yappCoordBox],   // faceplate window
  [50, 41, 0, 0, 4, yappCircle, yappCoordBox]        // DC099 12V jack (Ø8)
];

//-- BACK : mains inlets only. The ILI9341 lives on the LID (the back wall can't
//   hold both the 57 mm display window and the C14/C13 modules), so the whole
//   back wall is free for mains, grouped away from the LV faceplate (front).
//   [fromLeft(Y), fromBottom(Z), width(Y), height(Z), r, shape, coord]
//   *** PLACEHOLDER sizes/positions - tune to your actual IEC modules. ***
//     C14 switched inlet : snap-in panel cutout ~47 x 27 mm
//     C13 outlet         : snap-in panel cutout ~27.8 x 19.5 mm
//   Screw holes: M3 clearance (Ø3.2, r=1.6). yappCircle position is the
//   bounding-box CORNER, so corner = hole-centre - 1.6.  *** MEASURE the real
//   centre-to-centre spacing of each connector's ears and retune. ***
//
//   The group is slid LEFT by mainsShiftY to clear the PSU. That constant and
//   the c14*/c13* centres are defined at the TOP of this file, ABOVE the
//   include - see the note there for why they cannot live here.
cutoutsBack  =
[
  [c14CtrY - 47.0/2,       8.0,           47.0, 27.0, 0, yappRectangle, yappCoordBox],  // C14 mains IN (switched, snap-in)
  [c13CtrY - 27.8/2,       c13CtrZ-19.5/2, 27.8, 19.5, 0, yappRectangle, yappCoordBox], // C13 mains OUT (heater)
  [c13CtrY + c13EarPitch/2 - 1.6, c13CtrZ-1.6, 0, 0, 1.6, yappCircle, yappCoordBox],    // C13 ear (right)
  [c13CtrY - c13EarPitch/2 - 1.6, c13CtrZ-1.6, 0, 0, 1.6, yappCircle, yappCoordBox]     // C13 ear (left)
];

cutoutsLeft  = [];

//-- RIGHT wall : the two M3 clearance holes the PSU screws pass through, from
//-- OUTSIDE the box into the supply's own tapped holes. See the psuHole* block
//-- at the top of this file. yappCircle position is the bounding-box CORNER.
//-- *** Screw length matters: the tapped holes are only 3.0 mm deep. With a
//-- 2.0 mm wall that means M3 x 5 MAX - anything longer bottoms out and jacks
//-- the supply off the wall. ***
cutoutsRight =
[
  [psuHole1X - psuHoleR,                 psuHoleZ - psuHoleR, 0, 0, psuHoleR, yappCircle, yappCoordBox],
  [psuHole1X + psuHolePitch - psuHoleR,  psuHoleZ - psuHoleR, 0, 0, psuHoleR, yappCircle, yappCoordBox]
];

snapJoins    = [];
boxMounts    = [];
lightTubes   = [];
pushButtons  = [];
labelsPlane  = [];

//===================================================================
//  Faceplate mounting bosses  (custom geometry via YAPP base hook)
//-------------------------------------------------------------------
//  The faceplate is the vertical FRONT wall; its 2 M3 holes sit at
//  fx=15.86 (height) / fy=5 & 95 (across). These bosses stand off the
//  inside of the front wall so an M3 self-tapping screw goes through
//  the faceplate into the boss.  Hook coords: X back->front (0..L),
//  Y left->right (0..W), Z up (0..H); front inner face computed below.
//-------------------------------------------------------------------
fpBossOD    = 7;      // boss outer diameter
fpBossLen   = 12;     // how far it reaches back into the box
fpBossPilot = 2.5;    // M3 self-tap pilot (use ~4.2 for a heat-set insert)
fpMountZ    = basePlaneThickness + 15.86;          // faceplate hole height
fpFrontIn   = wallThickness + paddingBack + pcbLength + paddingFront; // front wall inner face

//-- Where each boss's sideways arm ends. The front window spans Y 6..102, so
//-- solid front wall exists at Y<6 (left) and Y>102 (right) for it to bond to.
fpArmEndL   = wallThickness - 0.5;   // left arm buries into the left wall
fpArmEndR   = 107;                   // right arm stops short of the PSU
                                     // footprint - keep this < psuYin (110)

//-- Display post geometry (ILI9341 2.8")
dispPostOD    = 6;
dispPostPilot = 2.5;   // M3 self-tap
dispPostLen   = 5;     // stand-off gap between wall/lid and the module PCB
dispHoleLong  = 81;    // module hole spacing (long axis)
dispHoleShort = 45;    // module hole spacing (short axis)

//---------------------------------------------------------------------
//  LID cable management (tethered service loop).
//  The display module is NOT on the fabricated PCB - it is hand-wired via
//  two edge headers pointing down into the box: a 9-pin display/SPI header
//  and a 4-pin SD header (13 pins). Flying ribbons run from the main board
//  up to these headers. The lid is fully removable, so leave a SERVICE LOOP
//  ~ interior height (~90 mm) + 40 mm so the lid can be set beside the box
//  (like an open laptop) while it stays connected; the loop coils in the
//  open volume above the PCB (clear of the PSU in the high-Y corner).
//  These printed clips retain the ribbons so their weight never pulls on
//  the fragile header pins, and dress both runs toward the LEFT flip edge.
//  *** PLACEHOLDER positions/sizes - tune to your ribbon width. ***
//---------------------------------------------------------------------
dispHdr9X    = 44.17 - dispHoleLong/2;   // 9-pin header end (X)   <-- tune
dispHdr4X    = 44.17 + dispHoleLong/2;   // 4-pin header end (X)   <-- tune
dispHdrY     = 54;                       // headers on display Y-centre
flipEdgeY    = wallThickness + 4;        // LEFT flip edge the loop exits toward
cableClipW   = 18;     // clip opening width (across the ribbon)   <-- tune
cableClipGap = 3;      // clearance under the bar (ribbon stack thickness)
cableClipH   = 3;      // foot/bar thickness
cableClipLeg = 3;      // foot width along the ribbon run

//-- A small printable arch that HANGS DOWN from z=0 into the lid cavity
//-- (negative Z), just like dispPost. Two full-height feet at the ends and a
//-- retaining bar at the bottom leave a slot of height cableClipGap between the
//-- lid ceiling and the bar; the ribbon slides through that slot (running in Y).
module cableClip()
{
  hTot = cableClipGap + cableClipH;              // total drop
  for (x = [-cableClipW/2, cableClipW/2 - cableClipLeg])
    translate([x, -cableClipLeg/2, -hTot])
      cube([cableClipLeg, cableClipLeg, hTot]);   // two feet (ceiling -> bottom)
  translate([-cableClipW/2, -cableClipLeg/2, -hTot])
    cube([cableClipW, cableClipLeg, cableClipH]); // retaining bar at the bottom
}

//---------------------------------------------------------------------
//  PSU (Mean Well LRS-50-12, 99 x 82 x 30 mm) standing ON EDGE in the
//  right-side zone. Length(99) runs along X, depth(30) along Y from the
//  right wall inward, height(82) along Z. The bottom L-flange rests on two
//  riser rails (psuRiserH tall) so the 12V output screws sit ABOVE the PCB
//  standoffs.
//  MOUNTING: the rails carry the weight; two M3 screws through the RIGHT WALL
//  into the supply's own tapped side holes locate and secure it. There are no
//  printed bosses and nothing self-taps into plastic - see cutoutsRight and the
//  psuHole* block at the top of this file.
//  psuX0 and psuRiserH are also declared up there (they position the holes).
//---------------------------------------------------------------------
psuLen        = 99;
psuDepth      = 30;
psuRightIn    = wallThickness + paddingLeft + pcbWidth + paddingRight; // right inner wall (Y) = 140
psuYin        = psuRightIn - psuDepth;   // inboard edge of PSU footprint (Y) = 110

module dispPost(len)
{
  difference()
  {
    cylinder(h = len, d = dispPostOD, $fn = 48);
    translate([0, 0, -0.1]) cylinder(h = len + 0.2, d = dispPostPilot, $fn = 24);
  }
}

module hookBaseInside()
{
  //-- Faceplate mounting bosses (H5/H6), carried by the FRONT WALL.
  //-- Left boss reaches out to the left wall; right boss stops short of the
  //-- PSU footprint (see fpArmEndR).
  fpTower(wallThickness + paddingLeft +  5, fpArmEndL);
  fpTower(wallThickness + paddingLeft + 95, fpArmEndR);

  //-- PSU riser rails (inboard edge + wall-side edge) that the bottom L-flange
  //-- rests on. These carry the supply's weight; the two M3 screws through the
  //-- right wall (cutoutsRight) do the securing.
  translate([psuX0, psuYin,       0]) cube([psuLen, 6, psuRiserH]);
  translate([psuX0, psuRightIn-6, 0]) cube([psuLen, 6, psuRiserH]);
} //-- hookBaseInside()

//-- Faceplate mounting boss: the old floor buttress laid on its side. It is a
//-- horizontal bar at the M3 hole height, backed against the front inner face,
//-- running SIDEWAYS in Y from the screw onto the solid front-wall strip beside
//-- the window (window spans Y 6..102, so solid wall is Y<6 and Y>102). Load
//-- carries into the front wall instead of down to the floor, and nothing
//-- touches the base plane. y = box-Y centre of the hole; yEnd = where the arm
//-- stops (embedded in the left wall, or short of the PSU on the right).
module fpTower(y, yEnd)
{
  y0 = min(y - fpBossOD/2, yEnd);
  y1 = max(y + fpBossOD/2, yEnd);
  difference()
  {
    // bar: spans y0..y1 across, fpBossOD tall in Z, reaching fpBossLen back
    translate([fpFrontIn - fpBossLen, y0, fpMountZ - fpBossOD/2])
      cube([fpBossLen, y1 - y0, fpBossOD]);
    // horizontal M3 self-tap bore, entering from the faceplate (+X) going -X
    translate([fpFrontIn + 0.1, y, fpMountZ])
      rotate([0, -90, 0])
        cylinder(h = fpBossLen + 0.2, d = fpBossPilot, $fn = 24);
  }
}

module hookLidInside()
{
  //-- LID display posts (board ctr X=44.17 Y=54), hanging down from the lid
  for (x = [44.17 - dispHoleLong/2, 44.17 + dispHoleLong/2])
    for (y = [54 - dispHoleShort/2, 54 + dispHoleShort/2])
      translate([x, y, -(lidPlaneThickness + dispPostLen)])
        dispPost(dispPostLen);

  //-- Cable-retention clips. They hang from the lid ceiling in the CLEAR strip
  //-- between the display module (Y ~29..79) and the LEFT flip edge, so the
  //-- ribbons emerging from the headers rise alongside the module and dress
  //-- toward flipEdgeY. Each clip leaves a slot against the ceiling that the
  //-- ribbon tucks into, so its weight is off the fragile header pins.
  //-- [X, Y] positions are PLACEHOLDERS - tune to your ribbon routing.
  for (p = [ [20, 18],                 // near the 9-pin header run
             [70, 18],                 // near the 4-pin header run
             [44, flipEdgeY + 4] ])    // central gather toward the flip edge
    translate([p[0], p[1], -lidPlaneThickness])
      cableClip();
} //-- hookLidInside()

YAPPgenerate();
