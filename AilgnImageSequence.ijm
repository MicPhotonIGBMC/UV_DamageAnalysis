/*Macro written by Elvire Guiot in April 2021  
 * 
 * the macro has to be apply after the Crop_And_LoadROIline macro
 * 
 * when running the macro:
 * - ash to the user to select the directory where are the "crop" sequences of images (single nucleus with corresponding ROI line)
 * - in batch mode, the macro will automatically align all the image files .tif containing "crop" in their name (files genertaed by the Crop_And_LoadROIline macro)
 * - when alignment of a sequence is finished, the aligned sequence is saved instead of the "crop" image
 * - a text window indicates that the alignment is in progress and how many files are still to process
 * - when all the files in the folder have been processed, a dialog window appears to alert that the alignment is completed.
 * 
 * if new images_crop are added in the folder, you can run again the macro, it will only consider the new images-crop and run the alignment on these new sequences
 * 
 * At the end the data are ready for analysis and quantification
 */

 
dirPath = getDir("Select the directory containing the images to align");
list= getFileList(dirPath);
listImages = newArray(list.length);
ImagesToALign=newArray(list.length);
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], ".tif")) 
		listImages[i]= dirPath + list[i];   // create the list of.tif files in the folder
		print (listImages[i]);
}

j=0;

for (i=0; i<list.length; i++) {
if (listImages[i] != 0)  {						// don't consider images that are not.tif
	test = listImages[i].contains("crop");		// don't consider images atht are not named "_crop_"
		if (test == "true"){
				ImagesToALign[j]=listImages[i];     
				j=j+1;
			}
	}
}
print("\\Clear");
nbImagesToAlign = j;

for(i=0; i!=nbImagesToAlign; i++){
		open (ImagesToALign[i]);
		imageName = getTitle();
		ID=getImageID();
		index = imageName.lastIndexOf("crop");
		newimageName = imageName.substring(0,index) + "alignROI"+ imageName.substring(index+4,imageName.length);
		rename(newimageName);
		if (nSlices >= 8) setSlice(8);												// z = 8 est le timepoint de l'irradiationUV
		print("Alignment in progress - still "+ nbImagesToAlign-i + " images to process");
		setBatchMode("hide");
		run("StackReg", "transformation=[Rigid Body]");			//Align les séquences d'images  
		setBatchMode("show");
		save(dirPath + File.separator + newimageName);						// save the aligned images 
		File.delete(dirPath + File.separator + imageName);  					// delete the crop images
		selectImage(ID); 
		close();
		
		}
showMessage("Stack alignment complete !");				
	



