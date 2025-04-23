//
// Lenticular Card Maker by gsyan
//
// Update: 2024.02.22
// Release: 2020.09.07 - GSYan
//
// Pictures(PNG) size : 100x100 pixels
//
// crop the photo to equal parts horizontally (size 10x100)
//					at x axis 0,10,20,30,40,50,60,70,80,90
//
// 	ex.  magick + dos command (crop to 10x100, 10 parts) 
//			replace picture-1.png & picture-2.png  with your filenames
//			output filename numbers 0,10,20,30 ... 90
//
//			for /L %a in (0,10,90) do (magick convert -crop 10x100+%a+0 picture-1.png parts-1-%a.png )
//			for /L %a in (0,10,90) do (magick convert -crop 10x100+%a+0 picture-2.png parts-1-%a.png )
//
// 	ex.  magick + dos command (crop to 5x100, 20 parts)
//			replace picture-1.png & picture-2.png  with your filenames
//			output filename numbers 0, 5,10,15 ... 95
//
//			for /L %a in (0,5,95) do (magick convert -crop 5x100+%a+0 picture-1.png parts-1-%a0.png )
//			for /L %a in (0,5,95) do (magick convert -crop 5x100+%a+0 picture-2.png parts-2-%a0.png )
//
// image filename format : image1_filename_prefix + filename_numbers + filename_postfix
// 		ex. parts-1-0.png , parts-1-10.png, parts-1-20.png ... parts-1-90.png
//

//* [Global] */ 

//
// image size setting
//
image_width = 100; //the width of orginal image in pixel
image_height = 100; //the height of orignal image in pixel

pieces = 10; //total number of image strips

prism_orientation = 1; // [0:Horizontal, 1:Vertical]

//
// output options
//

shape = 1; //0: retangle 1:cylinder, 2:heart, 3:flower

//the dimention of object after combo
export_width = 50;  // x size : unit mm
export_height = 50; // y size : unit mm

base_thickness = 0.8; //the thickness of the base , unit : mm

//the height of image relative to prism plane
image_thickness = 0.8; // z size : pixel max height : unit mm

//Inverts how the color values of imported images are translated into height values. 
invert_colors = false; 


prism_angle = 60;


//
// image files setting
//

image1_filename_prefix = "images/parts-1-";	//filename prefix of the 1st photo
image2_filename_prefix = "images/parts-2-";	//filename prefix of the 2nd photo

//filename_numbers
// the numbers are the cropped location of x or y 
// ex.  0,10,20,....90 
//
filename_numbers = [
    for(i=[0:pieces-1]) 
        let(
            offset=(prism_orientation==1?image_width:image_height)/pieces,
            start_number=i*offset
        ) 
        start_number
    ];
//filename_numbers = [ for(i=[0:9]) let() i];
//filename_numbers = [0,10,20,30,40,50,60,70,80,90]; //when crop to size 10x100
//filename_numbers = [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95]; // when crop to size 5x100  

filename_postfix = ".png"; //filename postfix


/* [Hidden] */ //don't touch below this line unless you need to adjust under the hood


//image surface overhang the prism
overhang_size = image_thickness*cos(90-prism_angle);

//the spacing between two prism
prism_spacing = overhang_size*2;

//the width of the prism
prism_width = ((prism_orientation == 1 ? export_width : export_height)-prism_spacing*(pieces-1+1))/pieces; 
//the height of the prism
prism_height = (prism_orientation == 1 ? export_height : export_width);  

//the height of the shape (great than the object)
shape_height = prism_width/2/cos(prism_angle)*sin(prism_angle)*2;

//the width of cropped images
image_crop_size = prism_width/2/cos(prism_angle);

//move offset of next prism 
prism_x_offset = prism_width+overhang_size*2; 
prism_y_offset = 0; 

prism_first_pos = (export_width-prism_width)/-2+overhang_size;

image_offset_x = (prism_width/2-image_crop_size/2*cos(prism_angle))+(image_thickness/2*cos(90-prism_angle));
image_offset_z = (image_crop_size*sin(prism_angle)/2)+(image_thickness/2*sin(90-prism_angle));


module prism(angle, width, height) {
  r = width/2/cos(30);
  resize([0, 0, width/2/cos(angle)*sin(angle)])
  translate([0, 0, r*sin(30)])
  rotate([-90, 0, 0])
  rotate([0, 0, 30])
  cylinder(h=height, r=r, center=true ,$fn=3);
}

//direction: 1 (looking from right), -1 (looking from left)
module image_piece_to_3d(filename, direction) { 
  translate([image_offset_x*direction, 0, image_offset_z])
  rotate([0, prism_angle*direction, 0])
  //cube([image_crop_size, prism_height, image_thickness], center=true);  
  union() {
    //add a thin layer as the image base to avoid errors when rotating in Linux environment
    translate([0, 0, image_thickness/-2])
    cube([image_crop_size, prism_height, 0.001], center=true);
	
    //read image file
    translate([0, 0, image_thickness/(invert_colors?2:-2)])  //center the Z axis
    resize([image_crop_size, prism_height, 0]) //change image width and height(depath) with resize
    scale([1, 1, image_thickness/100]) //change image thickness with scale
    rotate([0, 0, (prism_orientation==1?0:90)])
    surface(file=filename, center=true, invert=invert_colors);	
  }  
}

module ImageStrip(i, dir) {
  filename_right = str(image1_filename_prefix, filename_numbers[i] , filename_postfix);
  filename_left = str(image2_filename_prefix, filename_numbers[i] , filename_postfix);
  if(dir==1) {
    //looking from right to left
    //color("green", 1)
    image_piece_to_3d(filename_right, 1);
  } else {
    //looking from left to right
    //color("pink", 1)
    image_piece_to_3d(filename_left, -1);
  }
}

module Base() {
  translate([0, 0, base_thickness/-2])
  cube([export_width, export_height,  base_thickness], center=true);
}

module RetangleLenticularCard() {
  rotate([0, 0, (prism_orientation==1?0:-90)])
  union() {
    Base();
    for(i=[0:(pieces-1)]) {
      translate([prism_x_offset*i+prism_first_pos, 0, 0])
      union() {  
        //color("yellow", 0.5) 
        prism(prism_angle, prism_width, prism_height);
        ImageStrip(i, 1);  //look from left
		ImageStrip(i, -1); //look from right
      }
    }
  }
}

module flat_heart(d) {
  square(d);

  translate([d/2, d, 0])
  circle(d/2);

  translate([d, d/2, 0])
  circle(d/2);
}
module Heart(w, h, thickness) {
  shape_height = prism_width/2/cos(prism_angle)*sin(prism_angle)*2;
  d = 20;
  //h = 1;
  resize([w, h , thickness])
    translate([0, d/cos(45)/-2-(d/2-d/2*cos(45))/2, thickness/-2])
    rotate([0, 0, 45])
    linear_extrude(height=thickness, $fn=100) 
    flat_heart(d);
}
module Flower(size_x=50, size_y=50, size_z=1) {
  petals = 8;
  sides = 100; 
  d = 10;
  d2 = d*PI/petals;
  r = d/2*(petals<10 ? 0.8 : 1);
  a = 360/petals;
  a2 = 360/sides;

  translate([0, 0, size_z/-2])
  resize([size_x, size_y, size_z])
  linear_extrude()
  union() {
    circle(d=d, $fn=100);
    for(i=[0:petals-1]) {
      translate([r*cos(a*i), r*sin(a*i), 0]) 
        rotate([0, 0, a*i])
          circle(d=d2, $fn=sides);
    }
  }
}
//set the viewport
//$vpr = [38, 0, 282]; //looking from left
$vpr = [45, 0, 80]; //looking from right
$vpt = [0, 0, 0];
$vpd = 130;


//make the lenticular card
if(shape==0) {    
  RetangleLenticularCard();
} else {
  //other shapes
  intersection() {
    if(shape==1) {
      //cylinder
      cylinder(h=shape_height, d=min(export_width, export_height), center=true, $fn=360);
    } else if(shape==2) {
      //heart
      Heart(export_width, export_height, shape_height);
    } else {
      //flower
      Flower(export_width, export_height, shape_height);
    }
    RetangleLenticularCard();
  }
}

