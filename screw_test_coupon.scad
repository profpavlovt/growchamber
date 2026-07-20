//====================================================================
//  Self-tap screw test coupon for GrowChamber enclosure
//  Prints a row of bosses matching the PCB standoff geometry, each with
//  a different bore, so you can find the size your PC self-tapping screws
//  thread into firmly WITHOUT splitting the boss. Print in the SAME
//  material + layer height you'll use for the enclosure.
//
//  Try each screw; pick the smallest bore that drives in fully by hand/
//  driver with firm resistance and does not crack the boss. Then set that
//  value as (standoffPinDiameter + standoffHoleSlack) in Enclosure.scad.
//====================================================================

bores        = [2.8, 3.0, 3.2, 3.4];  // candidate bore diameters (mm)
bossOD       = 8;      // matches standoffDiameter in Enclosure.scad
bossHeight   = 6;      // a bit taller than standoffHeight(4) for grip while testing
baseThick    = 2;      // raft/label plate under the bosses
pitch        = 14;     // spacing between bosses
$fn          = 64;

// connecting base plate
plateLen = pitch * len(bores);
translate([-pitch/2, -bossOD, 0])
  cube([plateLen, bossOD*2, baseThick]);

for (i = [0 : len(bores) - 1])
{
  d = bores[i];
  translate([i * pitch, 0, 0])
  {
    // the boss
    difference()
    {
      cylinder(h = bossHeight + baseThick, d = bossOD);
      translate([0, 0, baseThick])
        cylinder(h = bossHeight + 0.1, d = d);
    }
    // embossed size label on the plate in front of each boss
    translate([0, -bossOD - 0.5, baseThick])
      linear_extrude(0.6)
        text(str(d), size = 4, halign = "center", valign = "top");
  }
}
