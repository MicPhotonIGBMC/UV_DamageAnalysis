/*Macro written by Elvire Guiot in April 2021  
 * 
 * 
 * When running, the macro : 
 * - ask to the user to select .tif (aligned sequence of image obtained after running the Crop_And_LoadROIline and AlignImageSequence macros
 * - load the real time of acquisition in the text file generated with Crop_And_LoadROIline macro
 * - the corresponding ROI for the UV laser line is automatically laoded (you will be able to adjust it if necessary)
 * - the macro ask to the user to draw a ROI outside the UV damaged zone
 * -  plot the raw data curves and save the values in a imageBasename_Rawdatas.txt
 * 	- substract the background (fixed to 102 for the background of the Prime95B camera
 * 	- normalize the curve (base line to 1) 
 * 	- plot the normalize data curves and save the values in a imageBasename_Normdatas.txt
 * - determine the max intensity value and the corresponding time to reach this max
 * - graph showing the raw and normalized datas are  saved in .jpeg  
 * - max intensity value and the corresponding time to reach this max are printed on the graph
  */

var numero;					/*numero de l'image dans le nom de fichier*/
var FilePath;					/*chemin d'acces au répertoire contenant les données*/
var ParentPath; 					/* dossier contenant les données*/
var BaseName;				/*nom de base de la séquence image*/
var NameForSaving;
var nbSliceStack;    			/*nombre d'images dans la stack*/
var nameROI;
var imageTime = newArray(nbSliceStack);	
var NormFrap = newArray(nbSliceStack);	
var Norm2Frap = newArray(nbSliceStack);	
var BackMean = 102;          /* backgroung from the Prime camera*/
var xFrap;						/* index of the Frap irradiation*/ 
var timeForMax;						/* time after the irradiation to reach a max intensity value*/
var indexOfMax;
var IDimage;
var maxInt;
var maxIntNorm;

macro "Analyse_UVirradiation_Sequence [1]"
{
/* ------------------------------------------------------------------------------------------------------------------*/
/*Ouverture de la premiere image pour recup pathway, basename, lecture du temps réel           ---*/
/* ----------------------------------------------------------------------------------------- -----------------------*/
	
	while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      	} 
      	
	roiManager("reset");
	print("\\Clear");
	selectWindow("Log");
	run("Close");


	FilePath		= File.openDialog("Select a File");					/*recup pathway*/
	ParentPath	= File.getParent(FilePath);								/*recup dossier ou sont les datas */
	FileName	= File.getName  (FilePath);								/* recup nom complet de l'image */
	BaseName	= substring(FileName, 0, lastIndexOf(FileName, "_"));    /*recup du nom de base */
	nameROI		= ParentPath +File.separator+ BaseName + "crop_" +  FileName.substring( BaseName.length + 6 , FileName.length - 4 ) +".roi";  
	NameForSaving = FileName.substring( 0 , FileName.length - 4 ); 
	
	open(FilePath);	

	IDimage = getImageID();	
	nbSliceStack=nSlices;

	imageTime = newArray(nbSliceStack);						/*prep une table pour le temps réel de la sequence d'images*/
	TimePath= ParentPath +  File.separator + BaseName + "_realTime.txt";
	Imagetemps=File.openAsString(TimePath);           /*ouverture du fichier qui contient les temps réels*/
		
	stringTime=split(Imagetemps," \n");			
	
	k=5;  												 /* la premi�re valeura lire commence a la valeur 5 car en-t�te dans le fichier texte*/  
		for(i=0; i!=nbSliceStack;i++)
		{
		imageTime[i]=parseFloat(stringTime[k]);
				k=k+1;
				}
			

/* -----------------------------------------------------------------------------------------------------------------*/
/*                                                   ROI manager                                                   */
/* ----------------------------------------------------------------------------------------- -----------------------*/
	setSlice(8);
	run("ROI Manager...");
	roiManager("Open", nameROI);
	roiManager("Select", 0 );
	roiManager("Rename", "UVlaser");
	roiManager("show all");	
	setTool("polygon");
	waitForUser(" Add the ROI outside from the UV Irradiation  - Press OK when DONE");
	roiManager("Add");
	roiManager("Select", 1 );
	roiManager("Rename", "Ref");	
	roiManager("Sort");			//pour que les ROI soient toujours dans le m^me ordre car appelées ensuite selon leur index		

	waitForUser("Change the UVlaser ROI if necessary, then click OK!");
	roiManager("Update");
/* -----------------------------------------------------------------------------------------------------------------*/
/*                                                  plot Raw datas                                                */
/* ----------------------------------------------------------------------------------------- -----------------------*/


		Ref  = newArray(nSlices);
		Frap = newArray(nSlices);
		selectImage(IDimage);
/* création des tables de mesures des intensités dans les ROIs*/		
			for (i = 0; i != nbSliceStack; i++)
				{ 
			num=i+1;
			roiManager("Select", 0);
			setSlice (num);
			getStatistics (area, mean);
			Ref[i]=mean;
			roiManager("Select", 1);
			getLine(x1, y1, x2, y2, lineWidth);
			makeLine(x1, y1, x2, y2, 6);				/* lineWidth = 6 for the UV line*/
			roiManager("update");
			setSlice (num);
			getStatistics (area, mean);
			Frap[i]=mean;
				}

					
// Find the image num of the FRAP Event
	
	frapIndex = 0;
	selectImage(IDimage);
	setSlice(1);
	getStatistics(area, meanMin);
	for (i = 1; i != nbSliceStack; i++)
	{
		setSlice(i );
		getStatistics(area, mean);
		if(mean < meanMin)
		{
			meanMin		= mean;
			frapIndex	= i-1;
		}
	}
	setSlice(1);

	xFrap=frapIndex;						// xFrap is the time point when UV irradiation occurs


/*recherche du max intensity à partir du tmps de FRAP*/
			maxInt= Frap[xFrap];
			for (i = xFrap; i != nbSliceStack-1; i++)
				{ 
					testInt = maxOf(maxInt, Frap[i+1]);
					if (testInt > maxInt) {
							maxInt = Frap[i+1];
							timeForMax = imageTime[i+1] - imageTime[xFrap];                               	/*time to reach the max*/
							indexOfMax = i+1;
						}
						 }


 


/*----------------------------------------soustraction bakground et normalisation--------------------------------------------------- */

// Soustraction du background

			
		FrapCorrBack   = newArray(nbSliceStack);
		RefCorrBack   = newArray(nbSliceStack);
		for(i = 0; i != nbSliceStack; i++)
		{
			FrapCorrBack[i] = Frap[i] - BackMean;
			RefCorrBack [i] = Ref [i] - BackMean;			// soustraction BackMean
		}

	

// normalisation à 1

		// ****** Premiere normalisation (Normalisation a 1 de Frap et Ref)
		SumPBFrap = 0;
		for (i =0; i != xFrap ; i++)
			SumPBFrap += FrapCorrBack[i];											// determination de maxFrap, valeur utilisee pour normaliser la courbe de FRAP a 1
		maxFrap = SumPBFrap / (xFrap );										// maxFrap est la moyenne des intensites prebleach a l'exclusion de la 1ere (cause effet dark state)

		SumPBRef = 0;
		for(i = 0; i != xFrap ; i++)
			SumPBRef += RefCorrBack[i];											// determination de maxRef, valeur utilisee pour normaliser la courbe de FRAP a 1
		maxRef = SumPBRef / (xFrap );										// maxRef est la moyenne des intensites prebleach a l'exclusion de la 1ere (cause effet dark state)

		NormFrap = newArray(nbSliceStack);
		NormRef  = newArray(nbSliceStack);
		for(i = 0; i != nbSliceStack; i++)
		{
			NormFrap[i] = (FrapCorrBack[i] / maxFrap);
			NormRef [i] = (RefCorrBack [i] / maxRef);
		}


	// ****** Seconde Normalisation (Normalisation de Frap par Ref)
		Norm2Frap = newArray(nbSliceStack);
		for(i = 0; i != nbSliceStack; i++)
			Norm2Frap[i] = NormFrap[i] / NormRef[i];
						
			
/*recherche du max intensity */
			 maxIntNorm= NormFrap[0];
			for (i = 0; i != nbSliceStack; i++){ 
					testInt = maxOf(maxIntNorm, NormFrap[i]);
						if (testInt > maxIntNorm) {
							maxIntNorm = testInt;	
									
						}
			}

/*----------------------------------------graph raws datas--------------------------------------------------- */
		

		Plot.create    ("Raw Datas", "Temps sec", "MeanIntensity");
		Plot.setLimits (0, imageTime[imageTime.length-1], Frap[xFrap] / 1.02, maxInt * 1.02);
		
		Plot.setColor  ("green");
		Plot.add       ("line", imageTime, Ref);
		Plot.add       ("circle", imageTime, Ref);
		
		
		Plot.setColor  ("blue");
		Plot.add       ("line", imageTime, Frap);
		Plot.add       ("circle", imageTime, Frap);

		Plot.setColor  ("red");
		Plot.drawLine(imageTime[indexOfMax], Frap[xFrap] / 1.02, imageTime[indexOfMax], maxInt*1.02);
		
		Plot.show();
		FigName=ParentPath+ File.separator + NameForSaving + "_RawDataPlot";
		
			
/*print the pourcentage of intensity increase and time to reach the max  on the rawData plot */		

IntPourcent = (NormFrap[indexOfMax]-1) *100;

DrawText=toString(IntPourcent,2);
selectImage ("Raw Datas");
setColor(0, 0, 0);
drawString("Percentage increase in intensity from baseline"+ DrawText ,200, 320);

//DrawMaxInt=toString(timeForMax ,2);
//setColor(0, 0, 0);
//drawString("Time to reach the max Intensity from the UVirradiation point ="+ timeForMax  + "sec",200, 340); 

saveAs("jpeg", FigName);
				
/*-------------------------------------plot the normalized datas--------------------------------------------*/

		Plot.create    ("Data CorrNorm", "Temps sec", "MeanIntensity");
		Plot.setLimits (0, imageTime[imageTime.length-1], 0, maxIntNorm * 1.1);
		
		Plot.setColor  ("green");
		Plot.add       ("line", imageTime, NormRef);
		Plot.add       ("circle", imageTime, NormRef);

		Plot.setColor  ("blue");
		Plot.add       ("line", imageTime, NormFrap);
		Plot.add       ("circle", imageTime, NormFrap);

		Plot.setColor  ("red");
		Plot.drawLine(imageTime[indexOfMax], 0 / 1.02, imageTime[indexOfMax], maxIntNorm*1.02);
		
	//	Plot.setColor  ("red");
	//	Plot.add       ("line", imageTime, Norm2Frap);
	//	Plot.add       ("circle", imageTime, Norm2Frap);
			
		Plot.show();
		FigName=ParentPath+ File.separator + NameForSaving + "_normDataPlot";
		
/*print the pourcentage of intensity increase and time to reach the max  on the rawData plot */		

selectImage ("Data CorrNorm");
setColor(0, 0, 0);
drawString("Percentage increase in intensity from baseline"+ DrawText ,200, 320);

//DrawMaxInt=toString(timeForMax ,2);
//setColor(0, 0, 0);
//drawString("Time to reach the max Intensity from the UVirradiation point ="+ timeForMax  + "sec",200, 340); 
		
saveAs("jpeg", FigName);


		
/*----------------------------------------file.txt raws and norm datas --------------------------------------------------- */

	print("\\Clear") ;		
	
	print ("Time(sec) ", "Cell signal" , "UVirradiation");   // creat a txt file with the mean intensity datas 
	for (i = 0; i != nbSliceStack; i++)
	print(imageTime[i],Ref[i],Frap[i]);
	
	selectWindow("Log");
	resName=ParentPath+ File.separator +  NameForSaving +"_RawDatas.txt";
	saveAs("Text", resName);


	print("\\Clear") ;	
	print	("Percentage increase in intensity from baseline"+ DrawText);		
	DrawMaxInt=toString(timeForMax ,2);
	print ("Time to reach the max Intensity from the UVirradiation point ="+ timeForMax  + "sec"); 
	
	print ("Time(sec) ", "CellSignal_norm" , "UVirradiation_norm " );   // creat a txt file with the mean intensity datas 
	for (i = 0; i != nbSliceStack; i++)
	print(imageTime[i],NormRef[i], NormFrap[i]);
	
	selectWindow("Log");
	resName=ParentPath+ File.separator + NameForSaving+"_NormDatas.txt";
	saveAs("Text", resName);
	
}

/* -----------------------------------------------------------------------------------------------------------------*/
/*                                                  Analyse                                            */
/* ----------------------------------------------------------------------------------------- -----------------------*/


macro "Analyse AnalyseDoubleExpo [2]"{


roiManager("Sort");																					//pour que les ROI soient toujours dans le m^me ordre car appelées ensuite selon leur index
	
/* -----------------------------------------------------------------------------------------------------------------*/
/*                                                  plot Raw datas                                                */
/* ----------------------------------------------------------------------------------------- -----------------------*/

		selectImage(IDimage);
		//Back = newArray(nSlices);
		nbSliceStack = nSlices;
		Ref  = newArray(nbSliceStack);
		Frap = newArray(nbSliceStack);

/* création des tables de mesures des intensités dans les ROIs*/		
			for (i = 0; i != nbSliceStack; i++)
				{ 
			num=i+1;
			//roiManager("Select", 0);
			//setSlice (num);
			//getStatistics( area,mean);
			//Back[i]=mean;
			roiManager("Select", 0);
			setSlice (num);
			getStatistics (area, mean);
			Ref[i]=mean;
			roiManager("Select", 1);
			setSlice (num);
			getStatistics (area, mean);
			Frap[i]=mean;
				}


/*----------------------------------------graph raws datas--------------------------------------------------- */
		

		Plot.create    ("Raw Datas", "Temps sec", "MeanIntensity");
		Plot.setLimits (0, imageTime[imageTime.length-1], Frap[xFrap] / 1.02, maxInt * 1.02);
		
		Plot.setColor  ("green");
		Plot.add       ("line", imageTime, Ref);
		Plot.add       ("circle", imageTime, Ref);
		
		
		Plot.setColor  ("red");
		Plot.add       ("line", imageTime, Frap);
		Plot.add       ("circle", imageTime, Frap);
		
		Plot.show();

/*----------------------------------------soustraction bakground et normalisation--------------------------------------------------- */

// Soustraction du background
		
		FrapCorrBack   = newArray(nbSliceStack);
		RefCorrBack   = newArray(nbSliceStack);
		for(i = 0; i != nbSliceStack; i++)
		{
			FrapCorrBack[i] = Frap[i] - BackMean;
			RefCorrBack [i] = Ref [i] - BackMean;			// soustraction BackMean
		}

	// Find the image num of the FRAP Event
	
	frapIndex = 0;
	selectImage(IDimage);
	setSlice(1);
	getStatistics(area, meanMin);
	for (i = 1; i != nbSliceStack; i++)
	{
		setSlice(i );
		getStatistics(area, mean);
		if(mean < meanMin)
		{
			meanMin		= mean;
			frapIndex	= i-1;
		}
	}
	setSlice(1);
	//frapIndex++;
	xFrap=frapIndex;
	print ("xfrap=", xFrap);


// normalisation à 1

		// ****** Premiere normalisation (Normalisation a 1 de Frap et Ref)
		SumPBFrap = 0;
		
		for (i = 0; i != xFrap ; i++)
			SumPBFrap += FrapCorrBack[i];											// determination de maxFrap, valeur utilisee pour normaliser la courbe de FRAP a 1
		maxFrap = SumPBFrap / (xFrap );										// maxFrap est la moyenne des intensites prebleach a l'exclusion de la 1ere (cause effet dark state)

		SumPBRef = 0;
		for(i = 0; i != xFrap ; i++)
			SumPBRef += RefCorrBack[i];											// determination de maxRef, valeur utilisee pour normaliser la courbe de FRAP a 1
		maxRef = SumPBRef / (xFrap );										// maxRef est la moyenne des intensites prebleach a l'exclusion de la 1ere (cause effet dark state)

		NormFrap = newArray(nbSliceStack);
		NormRef  = newArray(nbSliceStack);
		for(i = 0; i != nbSliceStack; i++)
		{
			NormFrap[i] = (FrapCorrBack[i] / maxFrap);
			NormRef [i] = (RefCorrBack [i] / maxRef);
		}


	// ****** Seconde Normalisation (Normalisation de Frap par Ref)
		Norm2Frap = newArray(nbSliceStack);
		for(i = 0; i != nbSliceStack; i++)
			Norm2Frap[i] = NormFrap[i] / NormRef[i];


		Plot.create    ("Data CorrNorm", "Temps sec", "MeanIntensity");
		Plot.setLimits (0, imageTime[imageTime.length-1], 0, maxIntNorm * 1.1);
		
		Plot.setColor  ("green");
		Plot.add       ("line", imageTime, NormRef);
		Plot.add       ("circle", imageTime, NormRef);

		Plot.setColor  ("blue");
		Plot.add       ("line", imageTime, NormFrap);
		Plot.add       ("circle", imageTime, NormFrap);
		
	/*	Plot.setColor  ("red");
		Plot.add       ("line", imageTime, Norm2Frap);
		Plot.add       ("circle", imageTime, Norm2Frap);*/
		
		Plot.show();

/* -----------------------------------------------------------------------------------------------------------------*/
/*                                                  Analyse du FRAP                                             */
/* ----------------------------------------------------------------------------------------- -----------------------*/

	/*Dialog.create("DataSet for fitting");
	items = newArray("Red _withRefCorr", "Blue_nonRefCorr");
	Dialog.addRadioButtonGroup("DataSet for fitting", items, 1, 1, "Red _withRefCorr");
	Dialog.show();
	choix = Dialog.getRadioButton();
	test =  matches (choix,"Blue_nonRefCorr") ;*/
	NFrap=newArray (nbSliceStack);																	// la table qui contient les datas à fitter		
//	if (test ==1){
	 		for(i = 0; i != nbSliceStack; i++) NFrap[i] = NormFrap[i];									//si on ne veux pas corriger du bleaching  
	 		//}
	 	//	else {
	 		//for(i = 0; i != nbSliceStack; i++) NFrap[i] = Norm2Frap[i];									//si on veut corriger du bleaching
	 		//}


		//****** Selection de la portion de courbe à considéerer pour le fit 
		RecimageTime = newArray(nbSliceStack - xFrap );							//t0 = pour le point xFrap 
		RecFrap      = newArray(nbSliceStack - xFrap );							
		for (i = 0; i != nbSliceStack - xFrap ; i++){
		
			RecimageTime[i] = imageTime[i + xFrap ] - imageTime[xFrap ];
			RecFrap     [i] = NFrap   [i + xFrap ];
		}

		//********Fit sur toute la courbe ou selection d'une plage (limite en temps) 			
		Dialog.create("End Time for fitting?");
		Dialog.addString("Stop ", "WholeTime", 20);
		Dialog.show();
		SelectEndTime=Dialog.getString();	
		test =  matches (SelectEndTime,"WholeTime") ;							//tfin si on ne veut pas considerer la totalité de points
		if (test ==1){
	 		FrapLength= RecFrap.length; 								 
	 		}
	 		else {
			endTime=parseInt( SelectEndTime);
			i=0;
			do{
					FrapLength=i;
					i=i+1;
				}  while( RecimageTime[i]<endTime);						
	 		}
	 		
		FitFrap = newArray (FrapLength); 	

				 	
		//****** fit de la courbe de recouvrement 
		FitFrap = newArray (FrapLength); 

		XFrapToFit = newArray(FrapLength);							//t0 pour le point xFrap 
		YFrapToFit = newArray(FrapLength);							
		for (i = 0; i != FrapLength; i++)
		{
			XFrapToFit[i] = RecimageTime[i];
			YFrapToFit[i] = RecFrap[i];
		}
		
		Fit.doFit("y = a * (1 - exp(-x * b)) + c* (1 - exp(-x * d)) + e", XFrapToFit, YFrapToFit);	
		for (i = 0; i != FrapLength; i++)
			FitFrap[i] = Fit.f(XFrapToFit[i]);
		A1   =     Fit.p(0);
		Tau1 = 1 / Fit.p(1);
		A2 	=  	 Fit.p(2);
		Tau2 = 1 / Fit.p(3);
		Yo  =     Fit.p(4);
		R2  =  Fit.rSquared;

		//Fit.plot ;
		//****** Equation de la courbe

		min       = FitFrap[0];
		dynamique = 1 - min;
		max       = FitFrap[FrapLength - 1];							
		//mobile    = 100 * (max - min) / dynamique;
		maxIntensity = (max-1)*100;
		dynamique = (1 - min) * 100;										// conversion en %
		poidsTau1=100*A1/(A1+A2);
		poidsTau2=100*A2/(A1+A2);
	
/* -----------------------------------------------------------------------------------------------------------------*/
/*                                     calcul du t1/2                                       *    /

/* -----------------------------------------------------------------------------------------------------------------*/
	
	DbleExpoModel = newArray (1000);
	timeModel = newArray (1000);
	timeModel[0] =0;
	x = timeModel[0];
	DbleExpoModel[0] =  A1 * (1 - exp(-x / Tau1)) + A2* (1 - exp(-x / Tau2)) + Yo;	
	timeMax=RecimageTime[FrapLength];
	for (i = 1; i != 1000 ; i++) timeModel[i]= timeModel [i-1]+ timeMax/1000;
	for (i = 1; i != 1000 ; i++) DbleExpoModel[i] =  A1 * (1 - exp(-timeModel[i] / Tau1)) + A2* (1 - exp(-timeModel[i] / Tau2)) + Yo;	
	
	halfMaxInt = (NormFrap[indexOfMax]-RecFrap[0])/2;						// half value of the max intensity
	i=0;
	IntTest = DbleExpoModel[i]- RecFrap[0];
	while (IntTest<= halfMaxInt) {
			i=i+1;
			IntTest=DbleExpoModel[i]- RecFrap[0];
	}
	TUnDemi = timeModel[i];

	
//****** Graph du fit


		Plot.create    ("Fit", "Temps", "Intensite");
		Plot.setLimits (0, XFrapToFit[FrapLength - 1]*0.95, NFrap[xFrap ] * 0.9, maxIntNorm*1.1);
		Plot.setColor  ("blue"); 
		Plot.add       ("circle", XFrapToFit, YFrapToFit); 
	
		Plot.setColor  ("red");
		Plot.add       ("line", timeModel, DbleExpoModel); 
				
		Plot.show();
		
		FigName=ParentPath+ File.separator + NameForSaving + "FitPlot";
		
		
DrawText=toString(maxIntensity ,2);
setColor(0, 0, 0);
drawString("Percentage increase in intensity from base level ="+ DrawText  ,140, 300); 
DrawText=toString(TUnDemi ,2);
setColor(0, 0, 0);
drawString("Time to reach half maximum ="+ DrawText + "sec"  ,140, 320); 
saveAs("jpeg", FigName);

/* -----------------------------------------------------------------------------------------------------------------*/
/*                                     creation des fichiers résultats                                        *    /

/* -----------------------------------------------------------------------------------------------------------------*/

//------------------------file.txt norm et fit datas


	print("\\Clear") ;		

	
	print ("Time(sec) ", "DataNorm", "Fit");   // creat a txt file with the  datas 
	for (i = 0; i != RecFrap.length; i++)
	print(RecimageTime[i], RecFrap [i]);
			
	print("Fit curve: ");
		
		print ("Time(sec) ", "Fit");   // creat a txt file with the  datas 
	for (i = 0; i != FrapLength; i++)
	print(RecimageTime[i],FitFrap[i]);
	
 print("Param from fit analysis: ");
		
		print ("ImageSerie:",NameForSaving);
		print ("fit DoubleExponential+Offset");
		print ("efficacité FRAP =",dynamique);												//paramètres issu du fit
		print ("pourcentage increase of intensity =", maxIntensity);
		print ("Time to reach half maximum intensity =" , TUnDemi + "sec");
		print ("Tau1=", Tau1);
		print ("%Tau1=", poidsTau1);
		print ("Tau2=",Tau2);
		print ("%Tau2=", poidsTau2);
		print ("fit  goodness, R2 score=",R2); 
	
	selectWindow("Log");
	resName=ParentPath+ File.separator + NameForSaving +"_ResultDatas.txt";
	saveAs("Text", resName);

print("\\Clear");
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

/* ----------------------------------------------------------------------------------------- -----------------------*/
		
/* Create ROI in the ROI manager from the Openstring of the .rgn Metamorph  */

function createROI(str2, index)
	{
		roi				= split(str2   , ",");
		roiData 		= split(roi[6] , " ");

		// Fill the ROI x - y coordinates definitions within an array
		x_coordinates	= newArray(roiData[4]);
		y_coordinates	= newArray(roiData[5]);
		for(i = 6; i != roiData.length; i = i + 2)
		{
			x_coordinates = Array.concat(x_coordinates, roiData[i    ]);
			y_coordinates = Array.concat(y_coordinates, roiData[i + 1]);
		}

		// Needed to get rid of the spikes within the ROI definition
		x_coordinates	= deleteArrayElement(x_coordinates, 24);
		y_coordinates 	= deleteArrayElement(y_coordinates, 24);
		x_coordinates	= deleteArrayElement(x_coordinates, 16);
		y_coordinates 	= deleteArrayElement(y_coordinates, 16);
		x_coordinates	= deleteArrayElement(x_coordinates,  8);
		y_coordinates 	= deleteArrayElement(y_coordinates,  8);
		x_coordinates	= deleteArrayElement(x_coordinates,  0);
		y_coordinates 	= deleteArrayElement(y_coordinates,  0);

		makeSelection("polyline", x_coordinates, y_coordinates);
//		Roi.setStrokeWidth(1);
		Roi.setName("ROI_" + index);
		roiManager ("Add");

//		return index;
	}


	function deleteArrayElement(array, index)
	{
		return Array.concat(Array.slice(array, 0, index - 1), Array.slice(array, index + 1, array.length));
	}

   /* ----------------------------------------------------------------------------------------- -----------------------*/