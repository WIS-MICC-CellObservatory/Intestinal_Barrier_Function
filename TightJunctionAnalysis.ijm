/* 
 * TightJunctionAnalysis.ijm 
 * 
 * Morphological analysis of Intestinal Barrier Function based on images of epithelial tight junction (TJ)
 * Analysis is done from two points of view: 
 * - Shape of single cells:  area, Perimeter, Solidity, Roughness = Perim^2/(4*pi*Area)
 * - shape of borders between adjucent cells : Length, euclidean distance and straightness of the independent TJ elements
 *  
 * Written by: Ofra Golani at MICC Cell Observatory, Weizmann Institute of Science
 * 
 *  
 * Workflow 
 * ----------
 * Go over the folder of the TJ files, for each file 
 * - segment cells
 * 	 + Morphological Segmentation
 * 	 + Export the segmented objects to watershed lines
 * 	 + Convert it to binary image
 * 	 + add to RoiManager using Analyze Particles: filter by size [MinCellSize-MaxCellSize]
 * 	 
 * - Cell perspective quantification: area, Perimeter, Solidity, Roughness = Perim^2/(4*pi*Area)
 * - TJ perspective quantification: Length, euclidean distance and straightness of the independent TJ elements - between TJ junction points
 * 	 + Skeletonize the watershed lines
 * 	 + find junction points (using Analyze Skeleton)
 * 	 + delete junction points to get independent edges 
 * 	 + optionally filter small edges (MinSkeletonArea)
 * 	 + quantify euclidean distance, length and their ratio (=Straightness) of each edge
 * 	 
 * Note: Straightness = Euclidean distance / Length = 1/Tortuosity: https://en.wikipedia.org/wiki/Tortuosity
 * use Straightness instead of Tortuosity to avoid dividing by zero for the case of closed curves
 * 
 * Output
 * ---------
 * - save results: 
 * 		detailed results tables (for cells and for borders) + overlay for each image
 * 		summary table with one line for each image: including the average values of both types of analysis 
 * - save the active macro parameters in a text file in the Results folder
 * 
 * Dependencies:
 * -------------
 * MorphoLibJ\Morphological Segmentation: https://imagej.net/MorphoLibJ
 * to install it : 
 * 		Help=>Update
 * 		Click “Manage Update sites”
 * 		Check “IJPB-plugins”
 * 		Click “Close”
 * 		Click “Apply changes”
 * 
 * Instructions:
 * -------------
 *  There are 2 modes of operation controled by   processMode   parameter: 
 *  - singleFile - asks the user to select a single TJ file to process. 
 *  - wholeFolder - asks the user to select a folder of images, and process all TJ images 
 * 
 * Notes:
 * ------
 * The Morphological segmentation is controled by one parameter called "Tolerance". 
 * You may need to tune it for different conditions, but make sure to use the same parameters for different biological conditions imaged by teh same imaging conditions. 
 * 
 * The segmentation time changes based on the image size and complexity and on the computer you are using. 
 * For larger images you'll need larger  WaitTime , for smaller images you can use smaller values. 
 * If the value is too low, you will encounter errors in the macro - because the segmentation is not available yet
 * You can see the actual time it took to run Morphological Segmentation in the Log window. Look for: Whole plugin took NNNN ms. 
 * 
 */

// Parameters 
// Mode of operation
var processMode = "wholeFolder"; // "singleFile" or "wholeFolder"

// Prms for matching file names
tj_string = "_TJ"; 

// Segmentation Parameters
var useGaussBluhrFlag = 1; 	// 0 - goes with Tolerance 500/1500
var GaussBluhrSigma = 1;   	//2; 
var Tolerance = 650;       	//500; 				// Tolerance - controls the morphological segmentation
var WaitTime = 7000; 		//2500; // 130000; 	// wait Time in ms for Morphological Segmentation, watch the log to see the actual time and tune it
var MinCellSize = 1000;   	// pixel^2
var MaxCellSize = 150000;	// pixel^2

var MaxRougnessForColorCode = 4;
var MinStraigtnessForColorCode = 0.3;

var AreaLUTName = "Fire";
var SolidityLUTName = "Fire";
var RoughnessLUTName = "Fire";
var StraigtnessLUTName = "Fire";

var MinSkeletonArea = 30; 
var calibrationZoom = 1; // 6 for montage images, 1 for high resolution

var ResultsSubFolder = "Results";

// how to treat input
var fileExtention = ".tif"; // ".ome.tif"; 

var batchModeFlag = 0; // keep it to 0 - Morphological Segmentation does not work with BatchMode
var CleanupFlag = true;


// Main Workflow
//--------------------------------------
Initialization();
// Choose image folder
if (matches(processMode, "singleFile")) {
	file_name=File.openDialog("Please select TJ file to analyze");
	open(file_name);
	directory = File.directory; 
}
else if (matches(processMode, "wholeFolder")) {
	directory = getDirectory("Open Image folders"); }

resFolder = directory + File.separator + ResultsSubFolder + File.separator; 
File.makeDirectory(resFolder);
print("inDir=",directory," outDir=",resFolder);
if (batchModeFlag)
	setBatchMode(true);

if (matches(processMode, "singleFile")) {
	ProcessFile(directory, resFolder); }
else if (matches(processMode, "wholeFolder")) {
	ProcessFiles(directory, resFolder, tj_string); }
	
setBatchMode(false);
PrintPrms();


// -------------------------------------
function PrintPrms()
{
	// print parameters to Prm file for documentation
	PrmFile = resFolder+"TightJunctionAnalysisParameters.txt";
	File.saveString("useGaussBluhrFlag="+useGaussBluhrFlag, PrmFile);
	File.append("", PrmFile); 
	File.append("GaussBluhrSigma="+GaussBluhrSigma, PrmFile); 
	File.append("Tolerance="+Tolerance, PrmFile); 
	File.append("MinCellSize="+MinCellSize, PrmFile); 
	File.append("MaxCellSize="+MaxCellSize, PrmFile); 
	File.append("MaxRougnessForColorCode="+MaxRougnessForColorCode, PrmFile); 
	File.append("MinStraigtnessForColorCode="+MinStraigtnessForColorCode, PrmFile); 
	File.append("MinSkeletonArea="+MinSkeletonArea, PrmFile); 
}


//--------------------------------------
// Loop on all files in the folder and Run analysis on each of them
function ProcessFiles(directory, resFolder, file_pattern) 
{
	// Get the files in the folder 
	fileListArray = getFileList(directory);
	
	// Loop over files
	for (fileIndex = 0; fileIndex < lengthOf(fileListArray); fileIndex++) {
		//if (endsWith(fileListArray[fileIndex], fileExtention) && indexOf(fileListArray[fileIndex], file_pattern)>0) {
		if (endsWith(fileListArray[fileIndex], fileExtention) ) {
			open(directory+fileListArray[fileIndex]);	
			print("\nProcessing:",fileListArray[fileIndex]);
			showProgress(fileIndex/lengthOf(fileListArray));
			ProcessFile(directory, resFolder);
			
		} // end of if 
	} // end of for loop

	// Save Results
	if (isOpen("SummaryResults.xls"))
	{
		selectWindow("SummaryResults.xls");
		saveAs("Results", resFolder+"SummaryResults.xls");
	}

	// Cleanup
	if (CleanupFlag==true) {
		if (isOpen("SummaryResults.xls"))
		{
			selectWindow("SummaryResults.xls");
			run("Close");  // To close non-image window
		}
		roiManager("reset");
	}

} // end of ProcessFiles


//--------------------------------------
// Run analysis of single file
function ProcessFile(directory, resFolder) {
	// It is assume that the tj image is open and active
	tjName = getTitle();
	tjIm = getImageID();
	
	tjNameNoExt = replace(tjName, ".tif", "");
	rawSaveName = replace(tjNameNoExt, tj_string, "");
	
	SegmentCells(directory, resFolder, tjIm, tjName, tjNameNoExt, rawSaveName);	
	if (roiManager("count") > 0)
	{
		QuantCells(directory, resFolder, tjIm, tjName, tjNameNoExt, rawSaveName);
		QuantTJ(directory, resFolder, tjIm, tjName, tjNameNoExt, rawSaveName);
	}
		
	// Cleanup
	if (CleanupFlag==true) 
	{
		CleanUp();
	}

}


//--------------------------------------
function SegmentCells(directory, resFolder, origIm, origName, origNameNoExt, saveName)
{
	//print("SegmentCells Starts...");
	selectWindow(origName);
	run("Duplicate...", "title=SegmentedIm");
	if (useGaussBluhrFlag) 
		run("Gaussian Blur...", "sigma="+GaussBluhrSigma);
	run("Morphological Segmentation");
	wait(1000); // about 1s is usually enough
	selectWindow("Morphological Segmentation");
	// segment image and wait
	call("inra.ijpb.plugins.MorphologicalSegmentation.segment", "tolerance="+Tolerance, "calculateDams=true", "connectivity=8");
	wait(WaitTime); // this number can be read in the Log window ("Whole plugin took XXXX ms")
	//print("Morphological Segmentation Open for", origName);

	// create outputimage for watershed lines
	call("inra.ijpb.plugins.MorphologicalSegmentation.setDisplayFormat", "Watershed lines");
	call("inra.ijpb.plugins.MorphologicalSegmentation.createResultImage");
	setTool("hand");

	if (!isOpen("SegmentedIm-watershed-lines"))
	{
		exit("You need to Increase  WaitTime  parameter \n\nInspect the last line of the  Log  window, It should be like: \n   Whole plugin took NNNN ms. \n\nSet  WaitTime  to be larger than the NNNN value indicated");
	}

	selectWindow("SegmentedIm-watershed-lines");
	run("Invert");
	roiManager("Reset");

	// Filter by size
	//selectWindow("SegmentedIm-catchment-basins" );
	selectWindow("SegmentedIm-watershed-lines");
	run("Set Measurements...", "area perimeter fit shape redirect=None decimal=2");
	run("Analyze Particles...", "size="+MinCellSize+"-"+MaxCellSize+" show=[Count Masks] display exclude clear add");
	if (roiManager("count") > 0)
	{
		rename("LabeledCells");
		selectWindow(origName);
		roiManager("Show All without labels");
	
		// save the ROIs
		roiManager("Save", resFolder+saveName+"_ROIs.zip");
		//print("Saving:",resFolder+saveName+"_ROIs.zip");
	}
	else
	{ 
		print(origNameNoExt," No Cells Found");
	}	
	//print("SegmentCells Done");
}


//--------------------------------------
function QuantCells(directory, resFolder, origIm, origName, origNameNoExt, saveName)
{
	//print("QuantCells Starts...");

	nCells = roiManager("Count");
	meanArea = 0;
	meanSolidity = 0;
	meanRoughness = 0;
	for (i=0; i< nCells; i++)
	{
		roiManager("Select", i);
		Perim = getResult("Perim.", i);
		Area = getResult("Area", i);
		Solidity = getResult("Solidity", i);
		Rough = Perim * Perim / ( 4 * PI * Area);
		setResult("Roughness", i, Rough); 

		meanArea = meanArea + Area;
		meanSolidity = meanSolidity + Solidity;
		meanRoughness = meanRoughness + Rough;
	}
	updateResults();
	meanArea = meanArea / nCells;
	meanSolidity = meanSolidity / nCells;
	meanRoughness = meanRoughness / nCells;

	// Save Color-code maps for area, solidity and roughness
	CreateAndSaveColorCodeImage("LabeledCells", "Results", resFolder, saveName, "Area", 0, MaxCellSize, 0, AreaLUTName);
	CreateAndSaveColorCodeImage("LabeledCells", "Results", resFolder, saveName, "Solidity", 0, 1, 2, SolidityLUTName);
	CreateAndSaveColorCodeImage("LabeledCells", "Results", resFolder, saveName, "Roughness", 1, MaxRougnessForColorCode, 2, RoughnessLUTName);

	// Save Result Table
	selectWindow("Results");
	saveAs("Results", resFolder+saveName+"_Results.xls");
	//print("Saving:",resFolder+saveName+"_Results.xls");
	run("Close"); // close the table window

	// Output the measured values into new results table
	if (isOpen("SummaryResults.xls"))
		IJ.renameResults("SummaryResults.xls", "Results"); // make table accessible
	else
		run("Clear Results");
		
	setResult("Label", nResults, saveName); 
	setResult("nCells", nResults-1, nCells); 
	setResult("meanArea", nResults-1, meanArea); 
	setResult("meanSolidity", nResults-1, meanSolidity); 
	setResult("meanRoughness", nResults-1, meanRoughness); 

	// Save Results - actual saving is done at the higher level function as this table include one line for each image
	IJ.renameResults("Results", "SummaryResults.xls"); // rename to avoid table overwrite

	// Save Overlay on contrast enhanced orig Image  - with/without labels
	selectWindow(origName);
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	roiManager("Show All without labels");
	run("Flatten");   // imprint the boundaries
	saveAs("Tiff", resFolder+saveName+"_OverlayNoLabel.tif");
	//print("Saving:",resFolder+saveName+"_OverlayNoLabel.tif");

	// Save Overlay - with/without labels
	selectWindow(origName);
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	roiManager("UseNames", "true");
	roiManager("Show All with labels");;
	run("Flatten");   // imprint the boundaries
	saveAs("Tiff", resFolder+saveName+"_OverlayWithLabel.tif");
	//print("Saving:",resFolder+saveName+"_OverlayWithLabel.tif");
	roiManager("UseNames", "false");
	
	/*selectWindow("CellMask");
	saveAs("Tiff", resFolder+saveName+"_CellMask.tif");
	//print("Saving:",resFolder+saveName+"_CellMask.tif");*/

	selectWindow("LabeledCells");
	saveAs("Tiff", resFolder+saveName+"_LabeledCells.tif");
	//print("Saving:",resFolder+saveName+"_LabeledCells.tif");

	//print("QuantCells Done");
}


//----------------------------------------------------------------------
function CreateAndSaveColorCodeImage(labeledImName, TableName, resFolder, saveName, FtrName, MinVal, MaxVal, decimalVal, LUTName)
{		
	selectImage(labeledImName);
	run("Assign Measure to Label", "results="+TableName+" column="+FtrName+" min="+MinVal+" max="+MaxVal);
	run(LUTName);
	run("Calibration Bar...", "location=[Upper Right] fill=White label=Black number=5 decimal="+decimalVal+" font=12 zoom="+calibrationZoom+" overlay");
	run("Flatten");
	saveAs("Tiff", resFolder+origNameNoExt+"_"+FtrName+"_Flatten.tif"); 
}


//----------------------------------------------------------------------
function QuantTJ(directory, resFolder, origIm, origName, origNameNoExt, saveName)
{
	//print("QuantTJ Starts...");

	selectWindow("SegmentedIm-watershed-lines");
	run("Duplicate...", "title=SegmentedIm-watershed-lines-skel");
	run("Skeletonize (2D/3D)");
	run("Analyze Skeleton (2D/3D)", "prune=none");
	selectWindow("Tagged skeleton");
	setThreshold(99, 255);
	setOption("BlackBackground", false);
	run("Convert to Mask");	

	run("Analyze Particles...", "size="+MinSkeletonArea+"-Infinity show=Masks display clear summarize add");
	run("Set Measurements...", "area mean standard modal min median display add redirect=None decimal=2");
	CleanSkeletonIm = getImageID();
	CleanSkeletonName = getTitle();

	// now run Analyze skeleton again to get the individual labeled skeletons (after separtaion at junction points) 
	run("Analyze Skeleton (2D/3D)", "prune=none show display");
	selectWindow("Mask-labeled-skeletons");
	
	// Output the measured values into new results table
	selectWindow("Results");
	run("Close"); // close the table window
	IJ.renameResults("Branch information", "Results"); // make table accessible
	nFibers = nResults;
	meanLength = 0;
	totalLength = 0;
	meanEuclideanLength = 0;
	meanStraightness = 0;
	for (i=0; i< nFibers; i++)
	{
		Length = getResult("Branch length", i);
		EuclideanLength = getResult("Euclidean distance", i);
		Straightness = EuclideanLength / Length;  
		setResult("Straightness", i, Straightness); 

		totalLength = totalLength + Length;
		meanEuclideanLength = meanEuclideanLength + EuclideanLength;
		meanStraightness = meanStraightness + Straightness;
	}
	updateResults();
	meanLength = totalLength / nFibers;
	meanEuclideanLength = meanEuclideanLength / nFibers;
	meanStraightness = meanStraightness / nFibers;

	// Save Color-code maps for area, solidity and roughness
	CreateAndSaveColorCodeImage("Mask-labeled-skeletons", "Results", resFolder, saveName, "Straightness", MinStraigtnessForColorCode, 1, 2, StraigtnessLUTName);

	// Save Result Table
	selectWindow("Results");
	saveAs("Results", resFolder+saveName+"_JTResults.xls");
	//print("Saving:",resFolder+saveName+"_JTResults.xls");
	run("Close"); // close the table window

	// Output the measured values into new results table - the same one used for the cell-perspective results
	if (isOpen("SummaryResults.xls"))
		IJ.renameResults("SummaryResults.xls", "Results"); // make table accessible
	else
		run("Clear Results");
		
	setResult("totalLength", nResults-1, totalLength); 
	setResult("meanLength", nResults-1, meanLength); 
	setResult("meanEuclideanLength", nResults-1, meanEuclideanLength); 
	setResult("meanStraightness", nResults-1, meanStraightness); 

	// Save Results - actual saving is done at the higher level function as this table include one line for each image
	IJ.renameResults("Results", "SummaryResults.xls"); // rename to avoid table overwrite

	// Save tagged skeleton
	selectWindow("Mask-labeled-skeletons");
	saveAs("Tiff", resFolder+saveName+"_TaggedLabeledSkel.tif");
	//print("Saving:",resFolder+saveName+"_TaggedLabeledSkel.tif");

	//print("QuantTJ Done");

}

//-------------------------------------------

//============================================================================================
// Initialization - make sure the script always start at the same conditions
//============================================================================================
function Initialization()
{
	print("\\Clear");
	//run("Options...", "iterations=1 count=1 ");
	run("Options...", "iterations=1 count=1 edm=Overwrite");
	run("Set Measurements...", "area mean min centroid integrated median redirect=None decimal=2");
	if (isOpen("Results"))
	{
		selectWindow("Results");
		run("Close");  // To close non-image window
	}
	roiManager("Reset");
	roiManager("UseNames", "false");
}

//-------------------------------------------
function CleanUp()
{
	// close all images before processing the next image file, clear Results Table and RoiManager
	run("Close All");
	if (isOpen("Results"))
	{
		selectWindow("Results");
		run("Close");  // To close non-image window
	}
	if (isOpen("Summary")) // Close analyze Skeleton summary table
	{
		selectWindow("Summary");
		run("Close");  // To close non-image window
	}
	roiManager("Reset");
	if (isOpen("Morphological Segmentation"))
	{
		selectWindow("Morphological Segmentation");
		run("Close");
		//print("Morphological Segmentation Closed");
	}
}

