/*Macro written by Elvire Guiot in April 2021  
 * the macro prepares the UV irradaition time sequence data acquired with the spinning disk using the metamorph software 
 * 
 * When running, the macro : 
 * - ask the user to select a .nd file in a folder
 * - open the correponding image sequence
 * - read the real time of acqusition and create a text file containing the time values
 * - read the .rgn file corresponding to the UV irradiation ROI lines saved during acqusition 
 * 	(if the.rgn file doesn't exist , the macro propose to the user to draw ROI lines by hand) 
 * - for each ROI, the macro ask to the user to draw a rectangle zone around the corresponding nucleus to crop the iamge sequence 
 * - it automatically calculates the new coordinate of the ROI taking into account the crop zone
 * - the crop image sequence containing individual nucleus and the corresponding ROI is saved in a result folder 
 * - once an image is treated, the macro ask if you want to open another .nd file ...
 * (the name of the last Image treated appears in a text window to help the user for the selection of the next image in the folder)
 * 
 * At the end the crop sequences are in the same result folder and are ready for alignment 
 
 * 
 */

var numero;					/*numero de l'image dans le nom de fichier*/
var FilePath;					/*chemin d'acces au répertoire contenant les données*/
var ParentPath; 					/* dossier contenant les données*/
var BaseName;				/*nom de base du fichier .tif*/
var nbSliceStack;    			/*nombre d'images dans la stack*/
var SequenceName;				/*nom de la pile d'images en temps*/
var imageTime = newArray(nbSliceStack);	



LoopMacro = 1; 																/* pour faire tourner la macro plusieurs fois à la demande de l'utilisateur*/

while (LoopMacro == 1) {
/* ----------------------------------------------------------------------------------------- -----------------------*/
/*                close and Reset previous images and windows
/* ----------------------------------------------------------------------------------------- -----------------------*/
while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      	} 
	roiManager("reset");
	
      	
/* ------------------------------------------------------------------------------------------------------------------*/
/*Ouverture de la premiere image pour recup pathway, basename, charge toutes les piles d'images au cours du temps---*/
/* ----------------------------------------------------------------------------------------- -----------------------*/

	


	FilePath		= File.openDialog("Select a .nd File");					/*recup pathway*/
	ParentPath	= File.getParent(FilePath);								/*recup dossier ou sont les datas */
	FileName	= File.getName  (FilePath);								/* recup nom complet de l'image */

	SequenceName	= substring(FileName, 0, lastIndexOf(FileName, ".nd")); 

	ResultPath = File.getParent(ParentPath);
	FileResult = File.getName  (ParentPath);
	destPath = ResultPath + File.separator + FileResult + "_Results";						/* creat dir for results*/	
	
	testDir = File.exists(destPath);
	if (testDir == 0) File.makeDirectory(destPath);
	
	
/* -----------------------------------------------------------------------------------------------------------------*/
/*                        Recup du parametre temps dans la sequence d'images                                    */
/* ----------------------------------------------------------------------------------------- -----------------------*/
	
	setBatchMode(true);
	open(ParentPath + File.separator + SequenceName + "_t1.tif");
	t0	= getImageTime();
		
	test=1;
	i=1;	
	while (test==1)
	{
		i=i+1;
		test=File.exists(ParentPath + File.separator + SequenceName + "_t" + i + ".tif");
		if (test ==1) open(ParentPath + File.separator + SequenceName + "_t" + i + ".tif");		//load toutes les images
			} 
	run("Images to Stack", "name=[" + SequenceName + "] title=[] use");
	IDImageSequence = getImageID();
	run("Enhance Contrast", "saturated=0.35");
	setBatchMode("exit and display");
	
	nbSliceStack=nSlices;

	imageTime = newArray(nbSliceStack);						/*prep une table pour le temps réel de la sequence d'images*/

	setSlice(1);
	t0				= getImageTime();						/* t0*/
	imageTime[0]	= 0;

for(i = 1; i < =nbSliceStack-1; i++)
	{
		setSlice(i+1);
		imageTime[i ] = getImageTime() - t0;				/*recup des valeurs de temps pour chaque image - t0*/
		//print (i, imageTime[i]);
	}
	print("\\Clear");
	print ("RealTime (sec) for ImageSeries ", SequenceName);   // creat a txt file with the time datas 
	for(i=1;i<=nSlices;i++) print( imageTime[i-1]);
	selectWindow("Log");
	resName=destPath+ File.separator  + SequenceName+"_RealTime.txt";
		saveAs("Text", resName);

	
/* ----------------------------------------------------------------------------------------- -----------------------*/
/*                read the .rgn file to import the ROI lines into the ROI manager
/* ----------------------------------------------------------------------------------------- -----------------------*/

roiFileName = ParentPath+ File.separator + SequenceName +".rgn";
testroiFile =  File.exists(roiFileName);
if (testroiFile == 1){
		roiFile	= File.openAsString(roiFileName);   // Get the FRAP ROI  from the .rgn Metamorph  file			
		rois	= split(roiFile, "\t\n\r");

		for(j = 0; j != rois.length; j++){
									 	
				roi				= split(rois[j]   , ",");
				roiData 		= split(roi[6] , " ");
	
				x1 = roiData[2];
				y1 = roiData[3];
				x2 = roiData[4];
				y2 = roiData[5];
				makeLine(x1, y1, x2, y2, 1);
				index = j+1;
				Roi.setName("ROI_" + index);
				roiManager ("Add");
				}
}else {
	setTool("line");
	waitForUser("Draw ROI line by hand- press T for each to add to ROI manager - then OK" );  
	listRoi= roiManager("count");
	for(j = 0; j != listRoi; j++){
		roiManager("select", j);
		roiManager("Rename", "ROI_" + j+1);
		}
}


		roiManager("Show All with labels");

/* -----------------------------------------------------------------------------------------------------------------*/
/*                               crop area around individual cells and recalculate ROI position                                                         */
/* ----------------------------------------------------------------------------------------- -----------------------*/


nbROI = roiManager("count");
setTool("rectangle");
for (i = 0; i < nbROI; i++){
	index = i+1;
	waitForUser("Draw a rectangle for cell corresponding to ROI " +index+ " - Press OK when DONE");
	Roi.getBounds(xcrop, ycrop, width, height);
	print("\\Clear");
	run("Duplicate...", "duplicate");
	IDtemp  = getImageID();
	
	cropImagePath = destPath+ "\\" + SequenceName+"_crop"+index+".tif";
	saveAs("tiff", cropImagePath);
	selectImage(IDtemp);
	close();
	selectImage(IDImageSequence);
	roiManager("select", i);
 	getLine(x1, y1, x2, y2, lineWidth);
 	makeLine(x1-xcrop, y1-ycrop, x2-xcrop, y2-ycrop, 1);
 	Roi.setName("ROIcrop_" + index);							//new ROI for crop zone
	roiManager ("Add");
	roiManager("select", nbROI+i);
	roiPath = destPath+ File.separator + SequenceName+"crop_ROI"+index+".roi";
	roiManager("Save", roiPath);
			}
			
selectImage(IDImageSequence);
close();

Dialog.create("Do you want to prepare another image sequence ?");
Dialog.addMessage("Another sequence to crop?");
Dialog.show();
print("\\Clear");
print ("Last Image treated is :   "+ SequenceName + ".nd");
LoopMacro = 1;


}

/* -----------------------------------------------------------------------------------------------------------------*/
/*                                               fonctions                                                         */
/* ----------------------------------------------------------------------------------------- -----------------------*/

/* get Real Time in a Metamorph TimeLapse (2D image) */
	
	
function getImageTime()
	{
		info		= getMetadata("Info");
		infolist	= split(info, "\t\n\r");
		for (i = 0; i < infolist.length; i++)
		{

			if(startsWith(infolist[i], "<prop id=\"acquisition-time-local\" type=\"time\""))
			{
//			print(infolist[i]);
				time_in_string	= substring(infolist[i], 62, lengthOf(infolist[i]) - 3);
				time_in_array	= split(time_in_string, ":");
				time_in_sec		= 3600 * time_in_array[0] + 60 * time_in_array[1] + time_in_array[2];
				//print (time_in_sec);
				return time_in_sec;
			}
		}
		return 0;
	}



