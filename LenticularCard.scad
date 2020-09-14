//
// Lenticular Card Maker by gsyan
//
// 2020.09.07
//
// Pictures(PNG) size : 100x100 pixels
//
// crop the photo to equal parts horizontally (size 10x100)
//					at x axis 0,10,20,30,40,50,60,70,80,90
//
// 	ex.  magick + dos command (crop to 10x100, 10 parts) 
//			replace picture-1.png & picture-2.png  with your filenames
//			output filename numbers 0,1,2,3 ... 9
//
//			for /L %a in (0,1,9) do (magick convert -crop 10x100+%a0+0 picture-1.png parts-1-%a.png )
//			for /L %a in (0,1,9) do (magick convert -crop 10x100+%a0+0 picture-2.png parts-1-%a.png )
//
// 	ex.  magick + dos command (crop to 5x100, 20 parts)
//			replace picture-1.png & picture-2.png  with your filenames
//			output filename numbers 00, 05,10,15 ... 95
//
//			for /L %a in (0,1,9) do (magick convert -crop 5x100+%a0+0 picture-1.png parts-1-%a0.png )
//			for /L %a in (0,1,9) do (magick convert -crop 5x100+%a5+0 picture-1.png parts-1-%a5.png )
//			for /L %a in (0,1,9) do (magick convert -crop 5x100+%a0+0 picture-2.png parts-2-%a0.png )
//			for /L %a in (0,1,9) do (magick convert -crop 5x100+%a5+0 picture-2.png parts-2-%a5.png )
//
// image filename format : image1_filename_prefix + filename_numbers + filename_postfix
// 		ex. parts-1-0.png , parts-1-1.png, parts-1-2.png ... parts-1-9.png
//

//* [Global] */ 

//
// image files setting
//

image1_filename_prefix = "images/parts-1-";	//filename prefix of the 1st photo
image2_filename_prefix = "images/parts-2-";	//filename prefix of the 2nd photo

filename_numbers = [0,1,2,3,4,5,6,7,8,9]; //when crop to size 10x100
//filename_numbers = ["00","05",10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95]; // when crop to size 5x100  

filename_postfix = ".png"; //filename postfix

//image_width = 100; //px
//image_height = 100; //px

parts_total_number = 10;

prism_orientation = 1; // [0:Horizontal, 1:Vertical]

// output options

imageSurfaceInvert = false; //Inverts how the color values of imported images are translated into height values. 

export_width = 50;  // x size : unit mm
export_depth = 50; // y size : unit mm

base_size_z = 0.8; //the height of base , unit : mm

//the height of image relative to prism plane
export_image_max_height = 0.8; // z size : pixel max height : unit mm



/* [Hidden] */ //don't touch below this line unless you need to adjust under the hood

image_size_x = (prism_orientation == 1) ? export_width/parts_total_number : export_width; //
image_size_y = (prism_orientation == 1 )? export_depth : export_depth/parts_total_number; 
image_size_z = export_image_max_height;  //

image_scale_x = (prism_orientation == 1) ? 0.1 : 0.01;
image_scale_y = (prism_orientation == 1) ? 0.01 : 0.1;

prism_angle = 60;

prism_width = (prism_orientation == 1 ? image_size_x : image_size_y); //the width of the prism
prism_radius = prism_width/2/cos(prism_angle/2); //radius of cylinder(prism)

//move offset of next prism 
prism_x_offset = (prism_orientation == 1 ? prism_width*cos(prism_angle)*2 : 0); 
prism_y_offset = (prism_orientation == 1 ? 0 : prism_width*cos(prism_angle)*2); 

prism_length = (prism_orientation == 1 ? prism_x_offset*image_size_y/image_size_x : prism_y_offset*image_size_x/image_size_y); 

image_offset_x = 0; //(prism_width-image_size_x)/2;

image_offset_z = ( imageSurfaceInvert ?
    (prism_radius*sin(prism_angle/2)+image_size_z-0.001) 
    : 
    (prism_radius*sin(prism_angle/2)-0.0001) );


base_size_x = (prism_orientation == 1 ) ? prism_x_offset*parts_total_number + prism_width : prism_length; //the width of the base
base_size_y = (prism_orientation == 1 ) ? prism_length: prism_y_offset*parts_total_number + prism_width ; //the depth of the base

base_offset_x = (prism_orientation == 1) ? base_size_x/2-prism_width : 0;
base_offset_y = (prism_orientation == 1) ? 0 : base_size_y/2-prism_width;
base_offset_z = prism_radius*sin(prism_angle/2)+base_size_z/2;


union() {
	for(i=[0:(parts_total_number-1)]) {
		//concatenate the image filename
		image_filename_1 = str(image1_filename_prefix, filename_numbers[i] , filename_postfix);
		image_filename_2 = str(image2_filename_prefix, filename_numbers[i] , filename_postfix);
		
		x = (prism_orientation == 1 ? prism_x_offset*i : 0 );
		y = (prism_orientation == 1 ? 0 : prism_y_offset*(parts_total_number-1-i) );

		//rotation angle of every stage
		ax1 =(prism_orientation == 1 ? 0 : prism_angle); 
		ay1 =(prism_orientation == 1 ? prism_angle : 0);
		ax2 =(prism_orientation == 1 ? 0 : prism_angle*-2); 
		ay2 =(prism_orientation == 1 ? prism_angle*-2 : 0);
		az =(prism_orientation == 1 ? 90 : 180);
		
		translate([x,y,0])
		rotate([ax1,ay1,0]) 
		union() {
			//rotate([0,(prism_angle*-2),0])
			rotate([ax2,ay2,0]) 
			union() {
			
			    //add a prism (Cylinder, Yellow)
				rotate([ax1,ay1,0])
					//rotate([0,-90,90]) 
					rotate([0,-90,az]) 
						color("yellow") {
							cylinder(h=prism_length,r1=prism_radius,r2=prism_radius,$fn=(180/prism_angle), center=true);
						}
						
				//the first image
				translate([0, 0, image_offset_z])
					//resize([image_size_x,prism_length,image_size_z]) 
                    //scale([0.1,0.1,image_size_z/100])
                    scale([image_size_x*image_scale_x,image_size_y*image_scale_y,image_size_z/100])
						surface(file=image_filename_1, center=true, invert=imageSurfaceInvert);
	
			};
			
			//the second image
			translate([0, 0, image_offset_z])
				//resize([image_size_x,prism_length,image_size_z])
                //scale([0.1,0.1,image_size_z/100])
                scale([image_size_x*image_scale_x,image_size_y*image_scale_y,image_size_z/100])
					surface(file=image_filename_2, center=true, invert=imageSurfaceInvert);       
			
		};

	}
	//the base (cube, Green)
	color("green") {
        translate([base_offset_x, base_offset_y, base_offset_z*-1+0.001])
			cube(size = [base_size_x,base_size_y,base_size_z], center = true);
	};
}
