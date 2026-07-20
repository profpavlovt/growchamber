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

//-- The inside floor, in BOX coordinates. This is just basePlaneThickness, but it
//-- has to be spelled out here: basePlaneThickness is YAPP-predefined and so is
//-- not resolvable this early (see the note above). hookBaseInside asserts the
//-- two agree, so this cannot silently drift.
baseFloorZ = 1.5;

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
psuHoleZ   = baseFloorZ + psuRiserH + 40.5;  // 40.5 above the supply's base, which
                                             // rests on the risers, which stand on the floor
psuHoleR   = 1.7;                // Ø3.4 clearance for M3

//-- FACEPLATE BOSS NOTCHES (same must-precede-the-include rule: cutoutsFront is
//-- YAPP-predefined too). The front window is split into three stacked rectangles
//-- so a tab of SOLID WALL is left standing behind each faceplate boss. That tab
//-- is what makes the boss printable on a resin printer - it grows continuously
//-- from the plate, instead of the boss floating as a 90-degree cantilever.
//--
//-- The bands were derived from GrowChamber_FP.kicad_pcb. Outward-facing THT
//-- parts still push solder TAILS back through the window, and those set the
//-- limits:
//--    J1  pads @ Z 6.15  and  J15 pads @ Z 6.34  -> tabs must start above Z 9
//--    LED2 (THT) @ Y 94.27                       -> right tab starts at Y 96
//--    Power_FP1 @ Z 27.21, U2 @ Z 25.82          -> tabs must stop by Z 21
//-- Everything else inside the bands (J60, D1, D3, J49, R18) is SMD.
fpNotchZ0   = 9;      // tab bottom - above the J1/J15 solder tails
fpNotchZ1   = 21;     // tab top    - below Power_FP1 / U2
fpNotchL0   = 6;      // left tab : window edge (wall already solid below this)
fpNotchL1   = 12.5;   // left tab : inboard edge
fpNotchR0   = 96;     // right tab: inboard edge, trimmed 0.5 to clear LED2
fpNotchR1   = 102;    // right tab: window edge
fpScrewR    = 1.7;    // Ø3.4 M3 clearance through the wall (boss provides the thread)

//===================================================================
//  SPLIT FOR PRINTING  (130 x 82 x 160 mm resin build volume)
//-------------------------------------------------------------------
//  The base is 105.3 x 142.0 x 91.5 and fits in NO orientation:
//     142.0 on Z -> 105.3 x 91.5 footprint, 91.5 > 82
//     105.3 on Z -> 142.0 x 91.5 footprint, 142.0 > 130
//      91.5 on Z -> 142.0 x 105.3 footprint, both > 82
//  It is not the PSU bay's fault - the PCB alone is 100 wide, so the box can
//  never be under 82. So it is cut into three along Y.
//
//  A SINGLE cut is impossible: for both halves to fit, it must land in
//  Y 60..82, and that whole range is occupied by the C14 (54..101) and C13
//  (65..92.8) apertures. The only aperture-free bands are Y 15..50 and
//  Y 102..110 / 116..134, hence two cuts:
//     Y=49  -> crosses only the front window, and that seam is hidden behind
//              the faceplate PCB (which spans Y 4..104 and mounts over it)
//     Y=104 -> completely clean; clears the front window (ends 102), the C14
//              (ends 101) and the C13 ear (ends 100.6)
//  Pieces are 49 / 55 / 38 wide, all printed base-down at 91.5 tall.
//
//  JOINT: stepped lap. The innermost jointLipT of the shell carries on past the
//  seam by jointLap as a continuous lip around the whole cross-section, and the
//  neighbouring piece is relieved to accept it. The outer part of the wall butts
//  at the seam and the inner part butts jointLap further on, so there is NO
//  straight-through path from inside to outside at any seam. Bond with CA or
//  fresh resin cured under UV.
//-------------------------------------------------------------------
splitPart  = 0;          // 0 = whole box (preview) | 1, 2, 3 = printable piece
splitY     = [49, 104];  // seam positions in box Y
//-- jointLipT splits the shell thickness between the lip and the receiving
//-- ledge. In the 2.0 mm walls either value is fine, but the floor is only
//-- basePlaneThickness = 1.5 mm, so 0.75 halves it evenly: a 0.75 mm lip on one
//-- piece and a 0.75 mm ledge on the other. At 1.0 the ledge drops to 0.5 mm,
//-- which is fragile right where the PCB bridges the Y=49 seam.
//-- *** The root fix is a thicker floor - see the note in the summary. ***
jointLipT  = 0.75;       // lip thickness, taken off the shell's INNER face
jointLap   = 5.0;        // how far the lip laps past the seam
jointSlack = 0.15;       // clearance on the receiving side

include <YAPPgenerator_v3.scad>



//-- which part(s) to print. Splitting applies to the BASE only - the lid is
//-- 105.3 x 142.0 x 14.2 and fits as one piece stood on edge (142 along Z,
//-- leaned ~15 deg -> 105.3 x 50.4 footprint, 141 tall). Splitting the lid is
//-- actually harder: its window, posts and clips leave only Y 79.5..82 legal.
printBaseShell  = true;
printLidShell   = (splitPart == 0);

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
//   The window is SPLIT into three stacked bands so a tab of solid wall survives
//   behind each faceplate boss (see the fpNotch* block at the top of this file).
//   Band heights sum to 29, so the overall opening is unchanged.
cutoutsFront =
[
  //-- window, lower band: full width, below the tabs (clears J1/J15 solder tails)
  [fpNotchL0, 3, fpNotchR1 - fpNotchL0, fpNotchZ0 - 3, 0, yappRectangle, yappCoordBox],
  //-- window, middle band: narrowed - this is what leaves the two tabs standing
  [fpNotchL1, fpNotchZ0, fpNotchR0 - fpNotchL1, fpNotchZ1 - fpNotchZ0, 0, yappRectangle, yappCoordBox],
  //-- window, upper band: full width again (clears Power_FP1 and U2)
  [fpNotchL0, fpNotchZ1, fpNotchR1 - fpNotchL0, 32 - fpNotchZ1, 0, yappRectangle, yappCoordBox],

  //-- M3 clearance holes through the tabs - the boss behind provides the thread
  [ 9 - fpScrewR, 17.36 - fpScrewR, 0, 0, fpScrewR, yappCircle, yappCoordBox],  // ctr Y  9, Z 17.36
  [99 - fpScrewR, 17.36 - fpScrewR, 0, 0, fpScrewR, yappCircle, yappCoordBox],  // ctr Y 99, Z 17.36

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
fpBossOD    = 7;      // boss height in Z (the wedge's tall end, at the wall)
fpBossPilot = 2.5;    // M3 self-tap pilot (use ~4.2 for a heat-set insert)
fpMountZ    = basePlaneThickness + 15.86;          // faceplate hole height
fpFrontIn   = wallThickness + paddingBack + pcbLength + paddingFront; // front wall inner face

//-- RESIN PRINTABILITY: the boss is a wedge whose underside slopes UP at 45 deg
//-- going into the box, rooted on the solid wall tab left by the fpNotch* bands.
//-- Nothing exists below fpWedgeZ0, and no layer overhangs the one beneath it by
//-- more than 45 deg, so it grows continuously from the plate with the box
//-- printed base-down. (It replaces a horizontal bar whose whole underside floated.)
fpWedgeZ0    = fpNotchZ0;   // underside starts here, at the wall face
fpWedgeDepth = 7;           // how far the wedge reaches into the box
fpBoreDepth  = 6.5;         // pilot depth into the wedge - stops short of the thin tip

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
cableClipW   = 18;     // tunnel span (across the ribbon)          <-- tune
cableClipH   = 2.5;    // arch wall thickness
cableClipLeg = 3;      // clip depth along the ribbon run

//-- A printable ARCH that hangs DOWN from z=0 into the lid cavity (negative Z),
//-- just like dispPost. The ribbon lies flat on the lid ceiling and the arch
//-- vaults over it, running in Y.
//--
//-- RESIN PRINTABILITY: the tunnel is a TEARDROP, not a semicircle. Printed with
//-- the lid outer-face-down the clip points up, so the tunnel's crown is the
//-- overhang - and a circular crown is shallower than 45 deg across the middle
//-- ~71% of its span, which resin will not hold. The 45 deg apex removes every
//-- sub-45 deg face. (This replaces a flat bar that bridged ~12 mm unsupported.)
//-- Total drop is cableClipW/2 + cableClipH, times sqrt(2) for the apex.
module clipProfile(rad)   // half-teardrop: flat floor at y=0, 45 deg point on top
{
  intersection()
  {
    union() { circle(r = rad, $fn = 64); rotate(45) square(rad); }
    translate([-rad, 0]) square([2*rad, rad*1.5]);
  }
}

module cableClip()
{
  r = cableClipW/2;
  translate([0, cableClipLeg/2, 0])
    rotate([90, 0, 0])
      linear_extrude(height = cableClipLeg)
        mirror([0, 1])                       // flip so the arch hangs into -Z
          difference()
          {
            clipProfile(r + cableClipH);     // outer shell
            clipProfile(r);                  // ribbon tunnel
          }
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

//===================================================================
//  *** COORDINATE FRAME ***
//  YAPP calls this hook with its origin at the box's INSIDE back-left-floor
//  corner, NOT at box(0,0,0) as the library comment claims - measured, a probe
//  cube at hook (50,70,40) lands at box (52,72,41.5). So hook coords are offset
//  by (wallThickness, wallThickness, basePlaneThickness).
//
//  Everything in this file is written in BOX coordinates (the same frame the
//  cutouts* lists use), so the wrapper below converts once and the contents can
//  be authored in box coords throughout. Without it, every feature here lands
//  2 mm forward, 2 mm right and 1.5 mm high - which is exactly what used to
//  happen, harmlessly, until the faceplate screw had to line up with a hole in
//  the wall.
//===================================================================
module hookBaseInside()
{
  assert(abs(baseFloorZ - basePlaneThickness) < 0.001,
         "baseFloorZ must equal basePlaneThickness - see the note at the top of this file");

  translate([-wallThickness, -wallThickness, -basePlaneThickness])   //-- box coords below
  {
    //-- Faceplate mounting bosses (H5/H6 at box Y 9 and 99), each a self-supporting
    //-- wedge rooted on the solid wall tab behind it. Widths match the tabs: the
    //-- left one runs to the window edge at Y 6 (wall is solid below that anyway),
    //-- the right one is trimmed to Y 96 to clear LED2's through-hole pads.
    fpTower(wallThickness + paddingLeft +  5, fpNotchL0 - 0.5, fpNotchL1);  // H5 -> Y  9
    fpTower(wallThickness + paddingLeft + 95, fpNotchR0,       fpNotchR1);  // H6 -> Y 99

    //-- PSU riser rails (inboard edge + wall-side edge) that the bottom L-flange
    //-- rests on. These carry the supply's weight; the two M3 screws through the
    //-- right wall (cutoutsRight) do the securing. They stand on the inside floor.
    translate([psuX0, psuYin,       baseFloorZ]) cube([psuLen, 6, psuRiserH]);
    translate([psuX0, psuRightIn-6, baseFloorZ]) cube([psuLen, 6, psuRiserH]);
  }
} //-- hookBaseInside()

//-- Faceplate mounting boss, shaped as a SELF-SUPPORTING WEDGE for resin.
//-- Cross-section in X-Z, extruded across y0..y1:
//--
//--        wall face (fpFrontIn)
//--            |
//--   zTop  +--+          <- flat top, faces up, prints fine
//--         |   \
//--         |    \        <- 45 deg underside: each layer overhangs the one
//--         |     \          below it by exactly one layer height
//--   zBot  +------+
//--         |<- d ->|
//--
//-- The wall behind it is solid (fpNotch* tabs), so the load path is
//-- boss -> tab -> wall -> floor, with no material below zBot.
//-- yBore is the PCB hole centre (fixed by H5/H6); y0/y1 are the boss's Y extent,
//-- passed per side because the right one is trimmed to clear LED2's THT pads.
//-- They are separate arguments on purpose: retuning a tab must never drag the
//-- screw off the faceplate hole.
module fpTower(yBore, y0, y1)
{
  assert(y0 <= yBore - fpBossPilot/2 && yBore + fpBossPilot/2 <= y1,
         "fpTower: bore falls outside the boss - check the fpNotch* bands");
  zTop = fpMountZ + fpBossOD/2;
  d    = fpWedgeDepth;
  difference()
  {
    translate([0, y1, 0])
      rotate([90, 0, 0])
        linear_extrude(height = y1 - y0)
          polygon([[fpFrontIn,     fpWedgeZ0],
                   [fpFrontIn - d, fpWedgeZ0 + d],   // 45 deg underside
                   [fpFrontIn - d, zTop],
                   [fpFrontIn,     zTop]]);
    // M3 self-tap bore, entering from the faceplate (+X) going -X
    translate([fpFrontIn + 0.1, yBore, fpMountZ])
      rotate([0, -90, 0])
        cylinder(h = fpBoreDepth + 0.1, d = fpBossPilot, $fn = 24);
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

//===================================================================
//  Split-for-printing machinery. See the SPLIT FOR PRINTING block at the
//  top of this file for why the seams are where they are.
//===================================================================

//-- A slab covering the whole box, limited in Y. Used to carve out one piece.
module splitSlab(y0, y1)
{
  m = 20;   // overshoot, so the slab always fully clears the shell
  translate([-m, y0, -m]) cube([shellLength + 2*m, y1 - y0, shellHeight + 2*m]);
}

//-- The innermost `t` of the shell: the shell intersected with the interior
//-- cavity grown outward by t. Following the shell rather than hard-coding a
//-- cross-section means the lip automatically wraps the floor and both end
//-- walls, and tracks any later change to padding or wall thickness.
module shellInnerLayer(t)
{
  intersection()
  {
    YAPPgenerate();
    translate([wallThickness - t, wallThickness - t, basePlaneThickness - t])
      cube([shellLength  - 2*wallThickness + 2*t,
            shellWidth   - 2*wallThickness + 2*t,
            shellHeight  + t]);
  }
}

//-- The lap itself: a continuous lip of the shell's inner skin, running from
//-- the seam forward by `lap`.
module jointTongue(yc, t, lap)
{
  intersection()
  {
    shellInnerLayer(t);
    splitSlab(yc, yc + lap);
  }
}

//-- One printable piece. Each piece keeps the tongue at its HIGH seam and is
//-- relieved (with slack) for the tongue arriving from the piece below it.
module printPiece(n)
{
  y0 = (n == 1) ? -20            : splitY[n-2];
  y1 = (n == 3) ? shellWidth + 20 : splitY[n-1];
  difference()
  {
    union()
    {
      intersection() { YAPPgenerate(); splitSlab(y0, y1); }
      if (n < 3) jointTongue(splitY[n-1], jointLipT, jointLap);
    }
    if (n > 1) jointTongue(splitY[n-2], jointLipT + jointSlack, jointLap + jointSlack);
  }
}

if (splitPart == 0) YAPPgenerate();
else                printPiece(splitPart);
