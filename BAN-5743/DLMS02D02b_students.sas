/****************************************/
/* Score data with the DLSCORE action,	*/
/* using the trained model				*/
/****************************************/
/*Adding library reference name to table option in dlscore statement and added caslib reference to casout option*/

/* Adding the cas lib reference to public for smalldata shuffled */
/* Changed the GPU to False */

proc cas;
	dlScore / table={ caslib = 'public' name='SmallImageDatashuffled', where='_PartInd_=1'} model='ConVNN' 
				initWeights='ConVbestweights'
				layerOut={name='Layer_data', replace=1}
				layers='ConVLayer1'
				layerImageType='JPG'
				casout={caslib='casuser' name='ScoredData', replace=1} /* added specific user library*/
				copyVars='_Label_'
				ENCODENAME=TRUE
				gpu=False;
run;

/*Chnaged library from mycas to casuser */
proc print data=casuser.ScoredData (obs=20);
run;


/***********************************/
/* Create misclassification counts */
/***********************************/
/*Chnaged library from mycas to casuser */
data work.MISC_Counts;
	set casuser.ScoredData;
if trim(left(_label_)) = trim(left(I__label_)) then 
Misclassified_count=0;
else Misclassified_count=1;
run;


/****************************************************/
/* Sum misclassification counts at the target level */
/****************************************************/
	
proc sql;
	create table work.AssessModel as	
		select distinct _label_, sum(Misclassified_count) as number_MISC
			from work.MISC_Counts
			group by _label_;
	quit;


/*****************************************************/
/* Plot each target level's misclassification counts */
/*****************************************************/

proc sgplot data=work.AssessModel;
  vbar _label_ / response=number_MISC;
  yaxis display=(nolabel) grid;
  xaxis display=(nolabel);
  run;
