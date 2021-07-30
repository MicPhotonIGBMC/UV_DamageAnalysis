# UV_DamageAnalysis

This is a package of 3 macros to analyse data that have been obtained from the Nikon CSU-X1 spinning disk controlled by Metamorph:

- macro 1 : **Crop_and_LoadROIline**  to prepare the data (read the roi line, crop images to obtain image with single nucleus …).
- macro2 : **AlignImageSequence**  Cell move during timelapse acquisition so we have to align the image sequences.
- macro3  for **UVdamageAnalysis** plot the kinetics curves , analyse and extract results parameters.
 
## **Crop_and_LoadROIline Macro**
The macro prepares the UV irradaition time sequence data acquired with the spinning disk using the metamorph software 
  
When running, the macro : 
- asks the user to select a .nd file in a folder
- open the correponding image sequence
- read the real time of acqusition and create a text file containing the time values
- read the .rgn file corresponding to the UV irradiation ROI lines saved during acqusition 
          (if the.rgn file doesn't exist , the macro propose to the user to draw ROI lines by hand) 
 - for each ROI, the macro ask to the user to draw a rectangle zone around the corresponding nucleus to crop the image sequence 
 - it automatically calculates the new coordinate of the ROI taking into account the crop zone
- the crop image sequence containing individual nucleus and the corresponding ROI is saved in a result folder 
- once an image is treated, the macro ask if you want to open another .nd file ...
(the name of the last Image treated appears in a text window to help the user for the selection of the next image in the folder)
 At the end the crop sequences are in the same result folder and are ready for alignment 
 
## **AlignImageSequence Macro**
 
The macro has to be apply after the Crop_And_LoadROIline macro

when running the macro:
- asks to the user to select the directory where are the "crop" sequences of images (single nucleus with corresponding ROI line)
- in batch mode, the macro will automatically align all the image files .tif containing "crop" in their name (files genertaed by the Crop_And_LoadROIline macro)
- when alignment of a sequence is finished, the aligned sequence is saved instead of the "crop" image
- a text window indicates that the alignment is in progress and how many files are still to process
- when all the files in the folder have been processed, a dialog window appears to alert that the alignment is completed.

 if new images_crop are added in the folder, you can run again the macro, it will only consider the new images-crop and run the alignment on these new sequences

 At the end the data are ready for analysis and quantification.

## **UVdamageAnalysis**

This macro has to be installed (two step macro)
First step:
- asks to the user to select .tif (aligned sequence of image obtained after running the Crop_And_LoadROIline and AlignImageSequence macros)
- load the real time of acquisition in the text file generated with Crop_And_LoadROIline macro
- the corresponding ROI for the UV laser line is automatically laoded
- the macro asks to the user to draw a ROI outside the UV damaged zone
-  plot the raw data curves and save the values in a imageBasename_Rawdatas.txt
- substract the background (fixed to 102 for the background of the Prime95B camera
- normalize the curve (base line to 1) 
- plot the normalize data curves and save the values in a imageBasename_Normdatas.txt
 - determine the max intensity value and the corresponding time to reach this max
- graph showing the raw and normalized datas are  saved in .jpeg  
 - pourcentage of increase of intensity versus the basal level is printed on the graph

Second step:
-fit the normalize data curve with a two exponentail model
-the macro asks the user if he wants to fit the data on the while time scale or to stop at a precise time (we have to stop fitting when the signal reaches the max value or plateau)
- pourcentage of increase of intensity versus the basal level is printed on the graph
- t1/2 to recah the max is extract from the analysis and also printed on the graph
Fit curve is added on the final graph 
All the results are written in tetx files taht contains the raw datas, mornalize datas, fit results and extracted parameters
All the graphs are saved in .jpeg so the user can easily have a look on the results.

