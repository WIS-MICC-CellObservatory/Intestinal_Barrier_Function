# Morphological analysis of Intestinal Barrier

## Overview

Morphological analysis of Intestinal Barrier based on images of epithelial tight junction (TJ).
Analysis is done from two points of view:
- Shape of single cells:  Area, Perimeter, Solidity, Roughness = Perim^2 / (4 * pi * Area)
- Shape of edges between adjacent cells : Length, Euclidean distance and Straightness of the independent TJ elements

This macro was used in:  <br/> <br/>

<p align="center"> <strong> High-Throughput Screen Identifies Host and Microbiota Regulators of Intestinal Barrier Function </strong><br/> <br/> </p>
	
<p align="center"> <strong>Inna Grosheva, Danping Zheng, Maayan Levy, Omer Polansky, Alexandra Lichtenstein, Ofra Golani, MallyDori-Bachash, Claudia Moresi, HagitShapiro, Sara Del Mare-Roumani, Rafael Valdes-Mas, Yiming He, Hodaya Karbi, MinhuChen, Alon Harmelin, Ravid Straussman, Nissan Yissachar, Eran Elinav, Benjamin Geiger </strong><br/> <br/>
	</p>

https://doi.org/10.1053/j.gastro.2020.07.003

Software package: Fiji (ImageJ)

Workflow language: ImageJ macro

<p align="center">
<img src="https://github.com/WIS-MICC-CellObservatory/Intestinal_Barrier_Function/blob/master/PNG/control_2.png" width="250" title="control_2">
<img src="https://github.com/WIS-MICC-CellObservatory/Intestinal_Barrier_Function/blob/master/PNG/TypeI_zig_zag_1.png" width="250" title="zig_zag_1">
<img src="https://github.com/WIS-MICC-CellObservatory/Intestinal_Barrier_Function/blob/master/PNG/TypeII_flowers_2.png" width="250" title="flower_2"> <br/> <br/>
<img src="https://github.com/WIS-MICC-CellObservatory/Intestinal_Barrier_Function/blob/master/PNG/control_2_Roughness_Flatten.png" width="250" title="control_2 cell roughness">
<img src="https://github.com/WIS-MICC-CellObservatory/Intestinal_Barrier_Function/blob/master/PNG/TypeI_zig_zag_1_Roughness_Flatten.png" width="250" title="zig_zag_1  cell roughness">
<img src="https://github.com/WIS-MICC-CellObservatory/Intestinal_Barrier_Function/blob/master/PNG/TypeII_flowers_2_Roughness_Flatten.png" width="250" title="flower_2  cell roughness"> 
	<br/> <br/> </p>
     
## Workflow

Go over the folder of the TJ files, for each file
- Segment cells
	 + Morphological Segmentation
 	 + Export the segmented objects to watershed lines
 	 + Convert it to binary image
 	 + Add to RoiManager using Analyze Particles: filter by size [*MinCellSize*-*MaxCellSize*]

- Cell perspective quantification: Area, Perimeter, Solidity, Roughness = Perim^2 / (4 * pi * Area)
- TJ perspective quantification: Length, Euclidean distance and Straightness of the independent TJ elements (between TJ junction points)
 	 + Skeletonize the watershed lines
 	 + Find junction points (using Analyze Skeleton)
 	 + Delete junction points to get independent edges
 	 + Optionally filter small edges (*MinSkeletonArea*)
 	 + Quantify Euclidean distance, length and their ratio (=Straightness) of each edge

Note: Straightness = Euclidean distance / Length = 1/Tortuosity: https://en.wikipedia.org/wiki/Tortuosity

Use Straightness instead of Tortuosity to avoid dividing by zero for the case of closed curves

## Output

- Save results:
 	+ Detailed results tables (for cells and for edges) + overlay for each image
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

  There are two modes of operation controlled by *processMode* parameter:
  - *singleFile* - prompt the user to select a single TJ file to process.
  - *wholeFolder* - prompt the user to select a folder of images, and process all TJ images

## Notes

The Morphological segmentation is controlled by one parameter called *Tolerance*.
You may need to tune it for different conditions, but make sure to use the same parameters for different biological conditions imaged by the same imaging conditions.

The segmentation time changes based on the image size and complexity and on the computer you are using. For larger images you'll need larger *WaitTime*, for smaller images you can use smaller values. If the value is too low, you will get an error message asking you to increase this value.
