# Intestinal_Barrier_Function

## Overview
 
 Morphological analysis of Intestinal Barrier Function based on images of epithelial tight junction (TJ)
 Analysis is done from two points of view: 
 - Shape of single cells:  area, Perimeter, Solidity, Roughness = Perim^2/(4*pi*Area)
 - shape of borders between adjucent cells : Length, euclidean distance and straightness of the independent TJ elements
 
 Written by: Ofra Golani at MICC Cell Observatory, Weizmann Institute of Science
 Software package: Fiji (ImageJ)
 Workflow language: ImageJ macro 
  
## Workflow 

 Go over the folder of the TJ files, for each file 
 - segment cells
 	 + Morphological Segmentation
 	 + Export the segmented objects to watershed lines
 	 + Convert it to binary image
 	 + add to RoiManager using Analyze Particles: filter by size [MinCellSize-MaxCellSize]
 	 
 - Cell perspective quantification: area, Perimeter, Solidity, Roughness = Perim^2/(4*pi*Area)
 - TJ perspective quantification: Length, euclidean distance and straightness of the independent TJ elements - between TJ junction points
 	 + Skeletonize the watershed lines
 	 + find junction points (using Analyze Skeleton)
 	 + delete junction points to get independent edges 
 	 + optionally filter small edges (MinSkeletonArea)
 	 + quantify euclidean distance, length and their ratio (=Straightness) of each edge
 	 
 Note: Straightness = Euclidean distance / Length = 1/Tortuosity: https://en.wikipedia.org/wiki/Tortuosity
 use Straightness instead of Tortuosity to avoid dividing by zero for the case of closed curves
 
## Output

 - save results: 
 		detailed results tables (for cells and for borders) + overlay for each image
 		summary table with one line for each image: including the average values of both types of analysis 
 - save the active macro parameters in a text file in the Results folder
 
## Dependencies:

 MorphoLibJ\Morphological Segmentation: https://imagej.net/MorphoLibJ
 to install it : 
 		Help=>Update
 		Click “Manage Update sites”
 		Check “IJPB-plugins”
 		Click “Close”
 		Click “Apply changes”
 
## Usage Instructions:

  There are 2 modes of operation controled by   processMode   parameter: 
  - singleFile - asks the user to select a single TJ file to process. 
  - wholeFolder - asks the user to select a folder of images, and process all TJ images 
 
## Notes:

 The Morphological segmentation is controled by one parameter called "Tolerance". 
 You may need to tune it for different conditions, but make sure to use the same parameters for different biological conditions imaged by teh same imaging conditions. 
 
 The segmentation time changes based on the image size and complexity and on the computer you are using. 
 For larger images you'll need larger  WaitTime , for smaller images you can use smaller values. 
 If the value is too low, you will encounter errors in the macro - because the segmentation is not available yet
 You can see the actual time it took to run Morphological Segmentation in the Log window. Look for: Whole plugin took NNNN ms. 
 