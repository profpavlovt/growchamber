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
standoffDiameter    = 8;        // wider boss: ~2.5 mm wall around the 3.0 mm bore
standoffPinDiameter = 3.0;      // yappHole bore = Pin+Slack = 3.0 mm self-tap for the
standoffHoleSlack   = 0.0;      //   PC self-tapping screws (~3.2 mm core / ~3.8 mm crest)

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
//-- SCREW-DOWN stands: yappHole makes each standoff a bore (diameter =
//-- standoffPinDiameter+standoffHoleSlack = 3.0 mm) instead of a locating pin,
//-- so a PC self-tapping screw passes down through the PCB and forms threads in
//-- the printed stand - the board is clamped, not just located. yappBaseOnly
//-- keeps the lid clear (no opposing post). (yappSelfThreading is NOT a YAPP
//-- token; the self-tap comes from sizing the bore ~= the screw core diameter.)
//-- yappNoFillet: REQUIRED here. YAPP's default hole fillet radius = basePlaneThickness
//-- (1.5). When the bore radius equals it (bore = 2*1.5 = exactly 3.0 mm, our case)
//-- its pinFillet() rotate_extrude sweeps a profile through the rotation axis and
//-- makes a non-manifold ("mesh is not closed") shell. Dropping the cosmetic hole
//-- fillet sidesteps that bug and keeps the exact 3.0 mm self-tap bore.
pcbStands =
[
  [ 5.73,  5, yappHole, yappBaseOnly, yappNoFillet],
  [62.43,  5, yappHole, yappBaseOnly, yappNoFillet],
  [ 5.73, 95, yappHole, yappBaseOnly, yappNoFillet],
  [62.43, 95, yappHole, yappBaseOnly, yappNoFillet]
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

//-- LID display window for the RED ILI9341 2.8" board. Viewable glass ~43.2 x
//   57.6. On this rigid board the glass LONG edge is parallel to the mounting
//   holes' LONG spacing (both along box Y here), and the glass is NOT centred in
//   the hole rectangle - it sits hard against ONE short-edge hole pair, leaving
//   a wide red PCB margin at the header end (see the photo). So:
//     * glass long edge (57.6) -> Y  (aligned with the 79.5 hole spacing)
//     * glass short edge (43.2) -> X  (fills the 43.5 hole spacing)
//     * shifted -11 mm in Y so its top edge sits at the Y=14 hole pair, big
//       margin toward the Y=94 (header) pair - matching the image.
//   Glass is CENTRED in the 4-hole rectangle (centre 44.17, 54): equal margins
//   to the top and bottom hole pairs, and centred left-right between the side
//   holes.
//   AXIS MAPPING (verified by render): for the lid cutout the 3rd param spans
//   box-X and the 4th spans box-Y. So to put the glass LONG edge (57.6) along Y
//   - parallel to the 79.5 hole spacing - the 43.2 goes in slot 3 (X) and 57.6
//   in slot 4 (Y). Getting these backwards rotates the window 90 deg vs the holes.
//   [fromBack(X), fromLeft(Y), Xspan, Yspan, r, shape, coord]
//   fromBack = 44.17 - 43.2/2 = 22.57 ; fromLeft = 54 - 57.6/2 = 25.2
//   *** MEASURE the real glass W x H; if the real glass sits off-centre toward
//   the header, add that offset to fromLeft when you fit the module. ***
cutoutsLid   =
[
  [22.57, 25.2, 43.2, 57.6, 0, yappRectangle, yappCoordBox]   // <-- MEASURE glass
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
fpBossOD    = 7;      // boss outer diameter (2.0 mm wall around the 3.0 mm bore)
fpBossLen   = 12;     // how far it reaches back into the box
//-- Bore tracks the SAME PC self-tapping screw as the PCB stands. Set once via
//-- standoffPinDiameter+standoffHoleSlack (3.0 mm) after the screw_test_coupon
//-- print, and every self-tap bore in the design follows.
fpBossPilot = standoffPinDiameter + standoffHoleSlack;   // 3.0 mm PC self-tap
fpMountZ    = basePlaneThickness + 15.86;          // faceplate hole height
fpFrontIn   = wallThickness + paddingBack + pcbLength + paddingFront; // front wall inner face

//-- Where each boss's sideways arm ends. The front window spans Y 6..102, so
//-- solid front wall exists at Y<6 (left) and Y>102 (right) for it to bond to.
fpArmEndL   = wallThickness - 0.5;   // left arm buries into the left wall
fpArmEndR   = 107;                   // right arm stops short of the PSU
                                     // footprint - keep this < psuYin (110)

//-- Display post geometry. The SHIPPED module is the classic RED portrait
//-- ILI9341 2.8" board (9-pin SPI header on a short edge, SD slot on the back) -
//-- NOT the CR2013-MI2120 landscape footprint the KiCad PCB happens to reference.
//-- Standard red-board dims (board ~50 x 86 mm): 4 corner holes ~2.5 mm at a
//-- 43.5 x 79.5 mm rectangle; viewable glass ~43.2 x 57.6.  These are the widely
//-- published figures - *** MEASURE with calipers when the module arrives. ***
//-- ORIENTATION: hookLidInside() maps dispHoleLong to Y and dispHoleShort to X,
//-- so the long screw spacing crosses the screen's SHORT edge (matches the part).
dispPostOD    = 8;     // widened 6->8 so the fat PC screw has ~2.5 mm wall (was M3)
dispPostPilot = standoffPinDiameter + standoffHoleSlack;   // 3.0 mm PC self-tap
dispPostLen   = 5;     // stand-off gap between wall/lid and the module PCB
dispHoleLong  = 79.5;  // hole spacing, long axis (along board length)  <-- measure
dispHoleShort = 43.5;  // hole spacing, short axis (across board width) <-- measure

//---------------------------------------------------------------------
//  LID cable management (tethered service loop).
//  The display module is NOT on the fabricated PCB - it is hand-wired via
//  two edge headers on OPPOSITE ends, pointing down into the box: a 13-pin
//  top header (9 display/SPI wired + 4 touch pins UNUSED) and, on the far
//  edge, a 4-pin SD header the user solders into the unpopulated holes.
//  Flying ribbons run from the main board
//  up to these headers. The lid is fully removable, so leave a SERVICE LOOP
//  ~ interior height (~90 mm) + 40 mm so the lid can be set beside the box
//  (like an open laptop) while it stays connected; the loop coils in the
//  open volume above the PCB (clear of the PSU in the high-Y corner).
//  These printed clips retain the ribbons so their weight never pulls on
//  the fragile header pins, and dress both runs toward the LEFT flip edge.
//  *** PLACEHOLDER positions/sizes - tune to your ribbon width. ***
//---------------------------------------------------------------------
dispHdr13X   = 44.17 - dispHoleLong/2;   // 13-pin top header end (X) <-- tune
dispHdr4X    = 44.17 + dispHoleLong/2;   // 4-pin SD header end (X)   <-- tune
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
  //-- LID display posts (hole-rectangle centre X=44.17 Y=54), hanging from the
  //-- lid. The hole rectangle is 43.5 (X) x 79.5 (Y) - long spacing along Y - to
  //-- match the board. The glass window (cutoutsLid) is ALIGNED to this: its long
  //-- edge also runs along Y, offset toward the Y=14 pair (see the note there).
  for (x = [44.17 - dispHoleShort/2, 44.17 + dispHoleShort/2])
    for (y = [54 - dispHoleLong/2, 54 + dispHoleLong/2])
      translate([x, y, -(lidPlaneThickness + dispPostLen)])
        dispPost(dispPostLen);

  //-- Cable-retention clips. After rotating the display, its posts now occupy the
  //-- rectangle X 22..66 x Y 14..94, so the old low-Y strip is taken. The CLEAR
  //-- strip is now IN FRONT of the window (X >= 78, running the full Y), well
  //-- clear of the window (X < 73) and every post (X < 70). The clips form a
  //-- column there; the ribbons from the display's short-edge headers dress into
  //-- this column so their weight is off the fragile header pins.
  //-- [X, Y] positions are PLACEHOLDERS - finalise once the module arrives and the
  //-- real header positions are known.
  for (p = [ [84, 24],
             [84, 54],
             [84, 84] ])
    translate([p[0], p[1], -lidPlaneThickness])
      cableClip();
} //-- hookLidInside()

YAPPgenerate();
