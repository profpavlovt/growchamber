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
pcbStands =
[
  [ 5.73,  5, yappPin],
  [62.43,  5, yappPin],
  [ 5.73, 95, yappPin],
  [62.43, 95, yappPin]
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
//     C14 combo centre (Y115.5,Z21.5): vertical ear pair (placeholder 35 mm).
//     C13 outlet centre (Y116.9,Z53.75): diagonal ear pair (placeholder 40 mm).
cutoutsBack  =
[
  [92.0,   8.0, 47.0, 27.0, 0, yappRectangle, yappCoordBox],    // C14 mains IN (switched)
  [113.9,  37.4, 0, 0, 1.6, yappCircle, yappCoordBox],          // C14 ear (top)    ctr 115.5,39.0  <-- tune
  [113.9,   2.4, 0, 0, 1.6, yappCircle, yappCoordBox],          // C14 ear (bottom) ctr 115.5, 4.0  <-- tune
  [103.0, 44.0, 27.8, 19.5, 0, yappRectangle, yappCoordBox],    // C13 mains OUT (heater)
  [129.4, 66.3, 0, 0, 1.6, yappCircle, yappCoordBox],           // C13 ear (upper-R) ctr 131.0,67.9 <-- tune
  [101.2, 38.0, 0, 0, 1.6, yappCircle, yappCoordBox]            // C13 ear (lower-L) ctr 102.8,39.6 <-- tune
];

cutoutsLeft  = [];
cutoutsRight = [];

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
//  standoffs; the side flange screws horizontally into a boss on the right
//  wall.  *** PLACEHOLDER hole positions - measure your LRS-50 and tune. ***
//---------------------------------------------------------------------
psuLen        = 99;
psuDepth      = 30;
psuRiserH     = 8;      // lifts 12V output screws above PCB standoff height
psuX0         = 3;      // PSU back end, measured from box back inner region (X)
psuRightIn    = wallThickness + paddingLeft + pcbWidth + paddingRight; // right inner wall (Y) = 140
psuYin        = psuRightIn - psuDepth;   // inboard edge of PSU footprint (Y) = 110
psuBossOD     = 7;
psuBossPilot  = 2.8;    // M3 self-tap (use ~4.2 for a heat-set insert)
psuFootX      = psuX0 + 8;           // floor screw X        <-- tune to your flange
psuFootY      = psuYin + 4;          // floor screw Y        <-- tune to your flange
psuWallX      = psuX0 + psuLen - 8;  // wall screw X         <-- tune to your flange
psuWallZ      = psuRiserH + 70;      // wall screw height Z  <-- tune to your flange
psuWallBossLen = 8;

module psuFootBoss()
{
  difference()
  {
    cylinder(h = psuRiserH + 4, d = psuBossOD, $fn = 48);
    translate([0, 0, -0.1]) cylinder(h = psuRiserH + 4.2, d = psuBossPilot, $fn = 24);
  }
}

module psuWallBoss()
{
  difference()
  {
    cylinder(h = psuWallBossLen, d = psuBossOD, $fn = 48);
    translate([0, 0, -0.1]) cylinder(h = psuWallBossLen + 0.2, d = psuBossPilot, $fn = 24);
  }
}

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
  //-- Faceplate mounting towers (H5/H6). The front WINDOW cutout removes the
  //-- wall where these M3 holes land, so the bosses can't hang off the wall.
  //-- Instead each is a buttress rising from the FLOOR with a horizontal bore;
  //-- the faceplate screw enters -X into the bore, load carries down to floor.
  for (y = [ wallThickness + paddingLeft + 5,
             wallThickness + paddingLeft + 95 ])
    fpTower(y);

  //-- PSU riser rails (inboard edge + wall-side edge) that the bottom
  //-- L-flange rests on, plus floor + wall mounting bosses.
  translate([psuX0, psuYin,       0]) cube([psuLen, 6, psuRiserH]);
  translate([psuX0, psuRightIn-6, 0]) cube([psuLen, 6, psuRiserH]);
  translate([psuFootX, psuFootY, 0]) psuFootBoss();
  translate([psuWallX, psuRightIn, psuWallZ]) rotate([90, 0, 0]) psuWallBoss();
} //-- hookBaseInside()

//-- Faceplate mounting tower: a solid buttress rising from the floor to the
//-- M3 hole height, with a horizontal pilot bore the faceplate screw taps into.
//-- Rooted to the floor (not the wall) because the front window removes the
//-- wall material at this Y/Z. y = box-Y centre of the faceplate hole.
module fpTower(y)
{
  towerTop = fpMountZ + fpBossOD/2;      // above the bore so it's fully wrapped
  translate([0, y, 0])
    difference()
    {
      // buttress block: floor -> towerTop, backed against the front inner face
      translate([fpFrontIn - fpBossLen, -fpBossOD/2, 0])
        cube([fpBossLen, fpBossOD, towerTop]);
      // horizontal M3 self-tap bore, entering from the faceplate (+X) going -X
      translate([fpFrontIn + 0.1, 0, fpMountZ])
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
