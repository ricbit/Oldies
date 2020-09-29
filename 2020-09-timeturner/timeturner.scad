// Hermione's Time Turner
// remix from https://www.thingiverse.com/thing:176345

module erase_stars() {
    union() {
        translate([-0.5, -10.5, 0]) color("green") cylinder(h=1, r1 = 1.2, r2 = 1.2, center = true, $fn=25);
        translate([-3.5, -12.5, 0]) color("green") cylinder(h=1, r1 = 1.2, r2 = 1.2, center = true, $fn=25);
        translate([-14.15, -7.7, 0]) color("green") cylinder(h=1, r1 = 0.9, r2 = 0.9, center = true, $fn=25);
        translate([11, -10, 0]) color("green") cylinder(h=1, r1 = 1.2, r2 = 1.2, center = true, $fn=25);
        translate([7, -13.5, 0]) color("green") cylinder(h=1, r1 = 1.2, r2 = 1.2, center = true, $fn=25);
        translate([3.5, 11, 0]) color("green") cylinder(h=1, r1 = 1.2, r2 = 1.2, center = true, $fn=25);
        translate([4.5, 14.5, 0]) color("green") cylinder(h=1, r1 = 1.2, r2 = 1.2, center = true, $fn=25);
        translate([-3.5, 12.5, 0]) color("green") cylinder(h=1, r1 = 1.2, r2 = 1.2, center = true, $fn=25);
        translate([-10.5, 11.5, 0]) color("green") cylinder(h=1, r1 = 1.2, r2 = 1.2, center = true, $fn=25);
    }
}

function disjoint(x1, y1, r1, x2, y2, r2) = 
    pow(x1 - x2, 2) + pow(y1 - y2, 2) > pow(r1 + r2, 2);

function inside(x1, y1, rbig, x2, y2, rsmall) = 
    pow(x1 - x2, 2) + pow(y1 - y2, 2) < pow(rbig - rsmall, 2);

Rb = 16.0;
Re = 1.0;
Rs = 10.0;
Xs = 8;
s = 10000;

function valid(x, y, r) = 
    inside(0, 0, Rb, x, y, r) && 
    disjoint(Xs, 0, Rs, x, y, r) &&
    disjoint(-Xs, 0, Rs, x, y, r);

function all_disjoint(r, rv) = len([for (rr = rv) if (disjoint(r[0], r[1], r[2], rr[0], rr[1], rr[2])) 1]) == len(rv);

function chosen(rv, i=0, ans=[]) = i >= len(rv) ? ans :
    all_disjoint(rv[i], ans) ? 
        chosen(rv, i + 1, concat([rv[i]], ans))
        : chosen(rv, i + 1, ans);

module star(side, r) {
    union() {
        x = rands(0,360,1)[0];
        rotate([0, 0, 0 + x])linear_extrude(height=2, center=true) circle(r, $fn=side);
        rotate([0, 0, 360/side/2 + x]) linear_extrude(height=2, center=true) circle(r, $fn=side);
    }
}

module add_stars() {
    rx = rands(-16, 16, s, 1);
    ry = rands(-16, 16, s, 2);
    rr = rands(0.7, 2, s, 3);
    rv = [for (i = [0:s-1]) if (valid(rx[i], ry[i], rr[i])) [rx[i], ry[i], rr[i]]];
    added = [];
    union() {
        /*difference() {
            color("red") cylinder(h=2.5, r=16, center=true, $fn=30);
            union() {
                translate([-8, 0, 0]) color("blue") cylinder(h=3, r=10, center=true, $fn=30);
                translate([8, 0, 0]) color("blue") cylinder(h=3, r=10, center=true, $fn=30);
            }
        }*/
        for (v = chosen(rv)) {
            translate([v[0], v[1], 0]) color("pink") star(3, v[2]-0.1);

        }       
    }
}

module original() {
    disk_stl = "/home/ricbit/work/3dprinter/Hermiones_Time_Turner/Disk.stl";
    rings_stl = "/home/ricbit/work/3dprinter/Hermiones_Time_Turner/Rings.stl";
    intersection() {
        union() {
            import(disk_stl);
            import(rings_stl);
        }
        cylinder(h = 20, r1 = 20, r2 = 20, center = true);
    }
}

difference() {
    union() {
        difference() {
        rotate([0, 90, 0]) color("green") cylinder(h=42, r1 = 2.3, r2 = 2.3, center = true, $fn=25);
        rotate([0, 90, 0]) color("green") cylinder(h=38, r1 = 2.5, r2 = 2.5, center = true, $fn=25);
        }
        original();
        erase_stars();
    }
    add_stars();
}