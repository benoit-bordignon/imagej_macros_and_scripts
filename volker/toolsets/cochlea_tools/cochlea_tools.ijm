/*
 
 MRI Cochlea Tools
 
 Measure the length and area of the cochlea over time. Measure the relative area covered by dead cells.
 
 (c) 2021, INSERM
 
 written by Volker Baecker at Montpellier Ressources Imagerie, Biocampus Montpellier, INSERM, CNRS, University of Montpellier (www.mri.cnrs.fr)
 
*/

var _THRESHOLDING_METHODS = getList("threshold.methods");
var _DEAD_CELLS_CHANNEL = 1;
var _DEAD_CELLS_THRESHOLDING_METHOD = "Triangle";
var _COCHLEA_CHANNEL = 2;
var _COCHLEA_THRESHOLDING_METHOD = "IsoData";
var _INTERPOLATION_LENGTH = 20;

var _CLOSE_COUNT = 1;

var _COCHLEA_SIZE_THRESHOLD = 800000000;
var _COCHLEA_SIZE_THRESHOLD_M = _COCHLEA_SIZE_THRESHOLD/100000;



var helpURL = "https://github.com/MontpellierRessourcesImagerie/imagej_macros_and_scripts/wiki/MRI_COCHLEA_TOOLS";

macro "cochlea tools help [f4]" {
	run('URL...', 'url='+helpURL);
}

macro "cochlea tools help (f4) Action Tool - C000L0090C001Da0C002Db0C001Dc0C000Ld0f0L0121C001D31C004D41C007D51C002D61C000L7191C001La1c1C000Ld1f1L0212C006D22C00fL3262C007D72C000L82f2D03C004D13C00fD23C00dD33C003D43C001D53C005L6373C000L83f3D04C00fD14C00dD24C001L3444C003D54C006D64C001D74C000L84c4C001Dd4C000Le4f4C002D05C00fD15C004D25C001D35C005D45C00fD55C004D65C000L75f5C004D06C00fD16C002D26C001D36C00dD46C00fD56C004D66C000L76b6C001Lc6d6C000De6C001Df6C003D07C00fD17C002L2737C00bD47C00fD57C006D67C000L77a7C006Db7C00aDc7C002Dd7C001Le7f7D08C00fD18C005D28C001D38C003D48C009D58C001D68C000L7898C003Da8C00fLb8c8C005Dd8C002De8C000Df8D09C00fL1929C001L3949C002L5969C006D79C007D89C00aD99C00fLa9b9C00aDc9C001Ld9e9C000Df9D0aC004D1aC00fD2aC009D3aC000D4aC001D5aC002D6aC009D7aC00eD8aC00fL9aaaC006DbaC001DcaC000LdafaL0b1bC008D2bC00fD3bC008D4bC001L5bbbC000DcbC004DdbC008DebC000DfbL0c2cC009D3cC00fL4c5cC004D6cC001L7cbcC007DccC00fDdcC00bDecC000DfcL0d3dC003D4dC00fL5d7dC00eD8dC00cD9dC00eDadC00fLbdcdC007DddC000LedfdL0e4eC001D5eC003D6eC008D7eC00dD8eC00fL9eaeC007DbeC001DceC000LdefeL0fff"{
	run('URL...', 'url='+helpURL);
}

macro "measure cochlea [f5]" {
	analyzeImage();
}

macro "analyze image (f5) Action Tool - C000T4b12a" {
	analyzeImage();
}

macro "analyze image (f5) Action Tool Options" {
	Dialog.create("cochlea tools options");
	Dialog.addNumber("dead cells channel: ", _DEAD_CELLS_CHANNEL);
	Dialog.addChoice("dead cells thresholding method: ", _THRESHOLDING_METHODS, _DEAD_CELLS_THRESHOLDING_METHOD);
	Dialog.addNumber("cochlea channel: ", _COCHLEA_CHANNEL);
	Dialog.addChoice("cochlea thresholding method: ", _THRESHOLDING_METHODS, _COCHLEA_THRESHOLDING_METHOD);
	Dialog.addNumber("interpolation length: ", _INTERPOLATION_LENGTH);
	Dialog.addNumber("Close Count", _CLOSE_COUNT);
	Dialog.addMessage("Minimal Size for an object to be considered as part of the cochlea");
	Dialog.addNumber("Cochlea Size Threshold", _COCHLEA_SIZE_THRESHOLD_M,0,10,"000 000 microns^2");
	Dialog.show();

	_DEAD_CELLS_CHANNEL = Dialog.getNumber();
	_DEAD_CELLS_THRESHOLDING_METHOD = Dialog.getChoice();
	_COCHLEA_CHANNEL = Dialog.getNumber();
	_COCHLEA_THRESHOLDING_METHOD = Dialog.getChoice();
	_INTERPOLATION_LENGTH = Dialog.getNumber();	
	_CLOSE_COUNT = Dialog.getNumber();
	_COCHLEA_SIZE_THRESHOLD_M = Dialog.getNumber();
	_COCHLEA_SIZE_THRESHOLD = _COCHLEA_SIZE_THRESHOLD_M * 100000;
}

function analyzeImage() {
	Overlay.remove;
	getSelectionBounds(xOffset, yOffset, width, height);
	run("Set Measurements...", "area stack display redirect=None decimal=9");
	getStatistics(totalArea);
	setBatchMode("hide");
	inputImageID = getImageID();
	areasDeadCells = measureAreasOfDeadCells(xOffset, yOffset);

	selectImage(inputImageID);
	makeRectangle(xOffset, yOffset, width, height);
	areasOfCochlea = measureAreaOfCochlea(xOffset, yOffset);
	setBatchMode("exit and display");
	lengthsOfCochlea = measureLengthOfCochlea(xOffset, yOffset, inputImageID);

	setBatchMode(true);
	selectImage(inputImageID);
	makeRectangle(xOffset, yOffset, width, height);
	areasOfDeadCellsInCochlea = measureDeadCellsAreaInCochlea(xOffset, yOffset, inputImageID);
	
	roiManager("reset");
	selectImage("cochlea");
	close();
	
	selectImage("dead_cells");
	close();
	
	run("Clear Results");
	close("Results");
	close("Roi Manager");
	selectImage(inputImageID);
	setSlice(2);
	makeRectangle(xOffset, yOffset, width, height);
	tableTitle = "cochlea results";
	setBatchMode(false);
	
	Table.create(tableTitle);
	Table.showRowIndexes(true, tableTitle);
	Table.set("total area", 0, totalArea, tableTitle);
	Table.setColumn("rel. area dead cells", areasDeadCells, tableTitle);
	Table.setColumn("rel. area cochlea", areasOfCochlea, tableTitle);
	Table.setColumn("rel. area dead cells in cochlea", areasOfDeadCellsInCochlea, tableTitle);
	Table.setColumn("length of cochlea", lengthsOfCochlea, tableTitle);
}

function measureDeadCellsAreaInCochlea(xOffset, yOffset, inputImageID) {
	getStatistics(totalArea);
	imageID = getImageID();
	imageCalculator("AND create stack", "dead_cells","cochlea");
	maskID = getImageID();
	areas = newArray(nSlices);
	for (i = 1; i <= nSlices; i++) {
		showProgress(i, nSlices);
		Stack.setFrame(i);
		setThreshold(1, 255);
		run("Create Selection");
		getStatistics(area);

		selectImage(inputImageID);
		Stack.setFrame(i);
		run("Restore Selection");
		getSelectionBounds(x, y, width, height);
		Roi.move(x+xOffset, y+yOffset);
		Roi.setGroup(4);
		Roi.setStrokeColor("green");
		Overlay.addSelection;
		Overlay.setPosition(_COCHLEA_CHANNEL, 0, i);
		run("Select None");

		selectImage(maskID);
		run("Select None");
		areas[i-1] = area / totalArea;
	}
	selectImage(maskID);
	close();
	selectImage(imageID);
	return areas;
}

function measureLengthOfCochlea(xOffset, yOffset, inputImageID) {
	imageID = getImageID();
	run("Duplicate...", "duplicate");
	skeletonID = getImageID();
	//title = getTitle();
	roiManager("reset");
	run("Clear Results");

	Stack.setFrame(1);
	run("Analyze Particles...", "size=10000-Infinity display clear add slice");
	areas = Table.getColumn("Area", "Results");
	ranks = Array.rankPositions(areas);

	for(i=0;i<ranks.length;i++){
		run("Duplicate...", " ");
		title = getTitle();
		roiManager("select",ranks[i]);
		run("Clear Outside", "slice");
		run("Skeletonize", "slice");
		
		run("Geodesic Diameter", "label="+title+" distances=[Chessknight (5,7,11)] export");
		roiManager("Select", roiManager("count")-1);
		run("Interpolate", "interval="+_INTERPOLATION_LENGTH+" smooth ");
		run("Interpolate", "interval=1 smooth adjust");
		roiManager("Update");
		close();
	}
	cochleaLength = 0;
	selectImage(inputImageID);
	for(i=0;i<ranks.length;i++){
		roiManager("select", roiManager("count")-(1+i));
		Stack.setFrame(1);
		getSelectionBounds(x, y, width, height);
		Roi.move(x+xOffset, y+yOffset);
		Roi.setGroup(3);
		Roi.setStrokeColor("white");
		Overlay.addSelection;
		Overlay.setPosition(_COCHLEA_CHANNEL, 0, 1);
		roiManager("measure");
		run("Select None");
		cochleaLength = cochleaLength + Table.get("Length", nResults-1,"Results");
	}
	close("cochlea-1-GeodDiameters");
	close("cochlea-2-GeodDiameters");
	selectImage(skeletonID);
	close();
	
	selectImage(imageID);

	lengths = newArray();
	lengths[0] = cochleaLength;
	return lengths;
}

function measureAreaOfCochlea(xOffset, yOffset) {
	getStatistics(totalArea);
	extractCochlea(xOffset, yOffset);
	
	imageID = getImageID();
	areas = newArray(nSlices);
	for (i = 1; i <= nSlices; i++) {
		showProgress(i, nSlices);
		Stack.setFrame(i);
		setThreshold(1, 255);
		run("Create Selection");
		getStatistics(area);
		run("Select None");
		areas[i-1] = area / totalArea;
	}
	selectImage(imageID);
	return areas;
}

function extractCochlea(xOffset, yOffset) {
	resetMinAndMax();
	inputImageID = getImageID();
	
	Stack.setChannel(_COCHLEA_CHANNEL);
	run("Duplicate...", "duplicate channels="+_COCHLEA_CHANNEL+"-"+_COCHLEA_CHANNEL);
	resetMinAndMax();
	setAutoThreshold(""+_COCHLEA_THRESHOLDING_METHOD+" dark no-reset stack");
	run("Convert to Mask", "method="+_COCHLEA_THRESHOLDING_METHOD+" background=Dark");

	for(g=0;g<_CLOSE_COUNT;g++){
		run("Dilate", "stack");
	}
	run("Fill Holes", "stack");
	for(g=0;g<_CLOSE_COUNT;g++){
		run("Erode", "stack");
	}
	maskID = getImageID();
	for (i = 1; i <= nSlices; i++) {
		showProgress(i, nSlices);
		Stack.setFrame(i);
		run("Analyze Particles...", "size=10000-Infinity display clear add slice");
		
		areas = Table.getColumn("Area", "Results");
		ranks = Array.rankPositions(areas);

		biggestArea = areas[ranks[ranks.length - 1]];

		sizeThreshold = _COCHLEA_SIZE_THRESHOLD;
		
		cochleaParts = newArray();
		cochleaParts = Array.trim(cochleaParts, 0);
		tooSmall = false;
		while(!tooSmall){
			index = ranks[ranks.length - (1+cochleaParts.length)];
			if(areas[index]>=sizeThreshold){
				cochleaParts = Array.concat(cochleaParts,index);
				//Array.print(cochleaParts);
			}else{
				tooSmall = true;
			}
		}
		if(cochleaParts.length < 1){
				cochleaParts = Array.concat(cochleaParts,ranks[ranks.length - 1]);
		}
	
		roiManager("select",cochleaParts);
		roiManager("combine");
		run("Clear Outside", "slice");
		selectImage(inputImageID);
		Stack.setFrame(i);
		roiManager("select", cochleaParts);
		roiManager("combine");
		getSelectionBounds(x, y, width, height);
		Roi.move(x+xOffset, y+yOffset);
		Roi.setGroup(2);
		Roi.setStrokeColor("magenta");
		Overlay.addSelection;
		Overlay.setPosition(_COCHLEA_CHANNEL, 0, i);
		run("Select None");

		selectImage(maskID);
		roiManager("reset");
		run("Select None");
	}
	Stack.setFrame(1);
	rename("cochlea");
}

function measureAreasOfDeadCells(xOffset, yOffset) {
	getStatistics(totalArea);
	inputImageID = getImageID();
	
	Stack.setChannel(_DEAD_CELLS_CHANNEL);
	run("Duplicate...", "duplicate channels="+_DEAD_CELLS_CHANNEL+"-"+_DEAD_CELLS_CHANNEL);
	run("Convert to Mask", "method="+_DEAD_CELLS_THRESHOLDING_METHOD+" background=Dark calculate");
	
	maskID = getImageID();
	areas = newArray(nSlices);
	for (i = 1; i <= nSlices; i++) {
		showProgress(i, nSlices);
		Stack.setFrame(i);
		setThreshold(1, 255);
		run("Create Selection");
		getStatistics(area);
		
		selectImage(inputImageID);
		Stack.setFrame(i);
		run("Restore Selection");
		getSelectionBounds(x, y, width, height);
		Roi.move(x+xOffset, y+yOffset);
		Roi.setGroup(1);
		Roi.setStrokeColor("cyan");
		Overlay.addSelection;
		Overlay.setPosition(_DEAD_CELLS_CHANNEL, 0, i);
		run("Select None");

		selectImage(maskID);
		run("Select None");
		areas[i-1] = area / totalArea;
	}
	rename("dead_cells");
	return areas;
}