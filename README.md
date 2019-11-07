# Morphological analysis of Intestinal Barrier Function

## Overview
 
Morphological analysis of Intestinal Barrier Function based on images of epithelial tight junction (TJ).
Analysis is done from two points of view: 
- Shape of single cells:  area, Perimeter, Solidity, Roughness = Perim^2/(4*pi*Area)
- shape of borders between adjucent cells : Length, euclidean distance and straightness of the independent TJ elements
 
Written by: Ofra Golani at MICC Cell Observatory, Weizmann Institute of Science

Software package: Fiji (ImageJ)

Workflow language: ImageJ macro 
  
## Workflow 

Go over the folder of the TJ files, for each file 
- Segment cells
	 + Morphological Segmentation
 	 + Export the segmented objects to watershed lines
 	 + Convert it to binary image
 	 + Add to RoiManager using Analyze Particles: filter by size [MinCellSize-MaxCellSize]
 	 
- Cell perspective quantification: *Area*, *Perimeter*, *Solidity*, *Roughness* = Perim^2/(4*pi*Area)
- TJ perspective quantification: *Length*, *Euclidean distance* and *Straightness* of the independent TJ elements - between TJ junction points
 	 + Skeletonize the watershed lines
 	 + Find junction points (using Analyze Skeleton)
 	 + Delete junction points to get independent edges 
 	 + Optionally filter small edges (*MinSkeletonArea*)
 	 + Quantify euclidean distance, length and their ratio (=*Straightness*) of each edge
 	 
Note: *Straightness* = Euclidean distance / Length = 1/*Tortuosity*: https://en.wikipedia.org/wiki/Tortuosity
Use *Straightness* instead of *Tortuosity* to avoid dividing by zero for the case of closed curves
 
## Output

- Save results: 
 	+ Detailed results tables (for cells and for borders) + overlay for each image
	+ Summary table with one line for each image: including the average values of both types of analysis 
- Save the active macro parameters in a text file in the Results folder
 
## Dependencies

 MorphoLibJ\Morphological Segmentation: https://imagej.net/MorphoLibJ
 
 To install it :
 - Help=>Update
 - Click “Manage Update sites”
 - Check “IJPB-plugins”
 - Click “Close”
 - Click “Apply changes”
 
## Usage Instructions

  There are two modes of operation controled by *processMode* parameter: 
  - *singleFile* - prompt the user to select a single TJ file to process. 
  - *wholeFolder* - prompt the user to select a folder of images, and process all TJ images 
 
## Notes

The Morphological segmentation is controled by one parameter called *Tolerance*.
You may need to tune it for different conditions, but make sure to use the same parameters for different biological conditions imaged by teh same imaging conditions. 
 
The segmentation time changes based on the image size and complexity and on the computer you are using.
For larger images you'll need larger *WaitTime*, for smaller images you can use smaller values.
If the value is too low, you will get an error message asking you to increase this value.
