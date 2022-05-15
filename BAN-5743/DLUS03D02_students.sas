
/*****************************************************************************/
/*  Create a default CAS session and create SAS librefs for existing caslibs */
/*  so that they are visible in the SAS Studio Libraries tree.               */
/*****************************************************************************/
/***********************************Warning**************************************************************************************/
/* Please run below code (Loading the CAS library code) before exexuting the Deep Learning code                   */
/* if                                                                                                                           */
/*	1) you did not load cas libraries in this session                                                                           */
/*	2) when you receive an error either casuser library does not exist or Train develop / validation develop table doesnot exist  */
/********************************************************************************************************************************/


/* cas;  */
/* caslib _all_ assign; */
/*  */
/* libname mycas cas caslib=public; */

/***********************/
/*Create GOFstats Macro*/
/***********************/
%macro GOFstats(ModelName=,DSName=,OutDS=,NumParms=0,
                ActualVar=Actual,ForecastVar=Forecast);
data &OutDS;
   attrib Model length=$12
          MAPE  length=8
          NMAPE length=8
          MSE   length=8
          RMSE  length=8
          NMSE  length=8
          NumParm length=8;
   set &DSName end=lastobs;
   retain MAPE MSE NMAPE NMSE 0 NumParm &NumParms;
   Residual=&ActualVar-&ForecastVar;
   /*----  SUM and N functions necessary to handle missing  ----*/
   MAPE=sum(MAPE,100*abs(Residual)/&ActualVar);
   NMAPE=NMAPE+N(100*abs(Residual)/&ActualVar);
   MSE=sum(MSE,Residual**2);
   NMSE=NMSE+N(Residual);
   if (lastobs) then do;
      Model="&ModelName";
      MAPE=MAPE/NMAPE;
      RMSE=sqrt(MSE/NMSE);
      if (NumParm>0) and (NMSE>NumParm) then 
         RMSE=sqrt(MSE/(NMSE-NumParm));
      else RMSE=sqrt(MSE/NMSE);
      output;
   end;
   keep Model MAPE RMSE NumParm;
run;
%mend GOFstats;

/****************/
/*Model Building*/
/****************/
/*  Line 58 to 104 are train and validation data set preparation steps */

data public.widgets_t;
	set mycas.simts2 (obs=40000);
	lwidgets=log(widgets);
	w1 = lag1(lwidgets);
	w2 = lag2(lwidgets);
	w3 = lag3(lwidgets);
	w4 = lag4(lwidgets);
	w5 = lag5(lwidgets);
	w6 = lag6(lwidgets);
	w7 = lag7(lwidgets);
	w8 = lag8(lwidgets);
	w9 = lag9(lwidgets);
	w10 = lag10(lwidgets);
	w11 = lag11(lwidgets);
	w12 = lag12(lwidgets);
	w13 = lag13(lwidgets);
	if _n_ > 13;
	keep date lwidgets w1 - w13 ;
run;

data plotin;
	set public.widgets_t (obs=100);
run;

proc sgplot data=plotin;
	series x=date y=lwidgets;
run;

data public.widgets_v;
 	set mycas.simts2 (firstobs=40001 obs=40401);
 	lwidgets=log(widgets);
	w1 = lag1(lwidgets);
	w2 = lag2(lwidgets);
	w3 = lag3(lwidgets);
	w4 = lag4(lwidgets);
	w5 = lag5(lwidgets);
	w6 = lag6(lwidgets);
	w7 = lag7(lwidgets);
	w8 = lag8(lwidgets);
	w9 = lag9(lwidgets);
	w10 = lag10(lwidgets);
	w11 = lag11(lwidgets);
	w12 = lag12(lwidgets);
	w13 = lag13(lwidgets);
	if _n_ > 13;
	keep date lwidgets w1 - w13;
run;

/*Build Model 0 - plain RNN*/
proc cas;
	loadactionset 'deeplearn';
quit;

proc cas;
	deepLearn.buildModel / 
	model={name='tsRnn0', replace=1} 
	type = 'RNN';

	deepLearn.addLayer / 
	model='tsRnn0' 
	name='data' 
	layer={type='input' std='std'}; 

	deepLearn.addLayer / 
	model='tsRnn0' 
	name='rnn1' 
	layer={type='recurrent' n=5 act='sigmoid' init='msra' rnnType='rnn' outputtype='samelength'} 
	srcLayers={'data'}; 

	deepLearn.addLayer / 
	model='tsRnn0' 
	name='rnn2' 
	layer={type='recurrent' n=5 act='sigmoid' init='msra' rnnType='rnn' outputtype='encoding'} 
	srcLayers={'rnn1'};

	deepLearn.addLayer / 
	model='tsRnn0' 
	name='outlayer' 
	layer={type='output' act='identity' error='normal'} 
	srcLayers={'rnn2'};
quit;

/* Added CASLIB public for both dltrain and dlscore codes  */

proc cas;
	deepLearn.dlTrain / 
	table= {caslib='public',name='widgets_t' }
	model='tsRnn0' 
	modelWeights={name='tsTrainedWeights0', replace=1} 
	bestweights={name='bestbaseweights0', replace=1}
	inputs=${w13 w12 w11 w10 w9 w8 w7 w6 w5 w4 w3 w2 w1}
	target='lwidgets'
	optimizer={minibatchsize=5, algorithm={method='adam', lrpolicy='step',  gamma=0.5,
	beta1=0.9, beta2=0.99, learningrate=.001 clipgradmin=-1000 clipgradmax=1000 } 
	maxepochs=30}
	seed=54321;
quit;

proc cas;
	deepLearn.dlscore / 
	table={caslib='public',name='widgets_v' }
	model='tsRnn0'
	initweights={name='bestbaseweights0'}
	copyvars={'lwidgets' 'date'}
	casout={name='scoreOut0', replace=1};
quit;

data scored;
	set casuser.scoreout0;
	widgets = exp(lwidgets);
	forecast = exp(_dl_pred_);
run;

%GOFstats(ModelName=rnn, DSName=work.scored ,OutDS=work.rnn,
          NumParms=2,ActualVar=widgets,ForecastVar=Forecast);

proc sgplot data=scored;
	scatter x=date y=widgets;
	series x=date y=forecast;
run;

/*Build Model 1 - LSTM*/
proc cas;
	deepLearn.buildModel / 
	model={name='tsRnn1', replace=1} 
	type = 'RNN';

	deepLearn.addLayer / 
	model='tsRnn1' 
	name='data' 
	layer={type='input' std='std' }; 

	deepLearn.addLayer / 
	model='tsRnn1' 
	name='rnn1' 
	layer={type='recurrent' n=5 act='sigmoid' init='msra' rnnType='lstm' outputtype='samelength'} 
	srcLayers={'data'}; 

	deepLearn.addLayer / 
	model='tsRnn1' 
	name='rnn2' 
	layer={type='recurrent' n=5 act='sigmoid' init='msra' rnnType='lstm' outputtype='encoding'} 
	srcLayers={'rnn1'};  

	deepLearn.addLayer / 
	model='tsRnn1' 
	name='outlayer' 
	layer={type='output' act='identity' error='normal'} 
	srcLayers={'rnn2'};
quit;

/* Added CASLIB public for both dltrain and dlscore codes  */

proc cas;
	deepLearn.dlTrain / 
	table={caslib='public',name='widgets_t' }
	model='tsRnn1' 
	modelWeights={name='tsTrainedWeights1', replace=1} 
	bestweights={name='bestbaseweights1', replace=1}
	inputs=${w1-w13}
	target='lwidgets'  
	optimizer={minibatchsize=5, algorithm={method='ADAM', lrpolicy='step',  gamma=0.5,
	beta1=0.9, beta2=0.99, learningrate=.001 clipgradmin=-1000 clipgradmax=1000 }  
	maxepochs=30} 
	seed=54321;
quit;

proc cas;
	deepLearn.dlscore / 
	table={caslib='public',name='widgets_v' }
	model='tsRnn1'
	initweights={name='bestbaseweights1'}
	copyvars={'lwidgets' 'date' }
	casout={name='scoreOut1', replace=1};
quit;

data scored1;
	set casuser.scoreout1;
	widgets = exp(lwidgets);
	forecast = exp(_dl_pred_);
run;

%GOFstats(ModelName=lstm_shallow,DSName=work.scored1 ,OutDS=work.lstm_shallow,
          NumParms=2,ActualVar=widgets,ForecastVar=Forecast);

proc sgplot data=scored1;
	scatter x=date y=widgets;
	series x=date y=forecast;
run;

/*Build Model 2 - same as above, but deeper*/
proc cas;
	deepLearn.buildModel / 
	model={name='tsRnn2', replace=1} 
	type = 'RNN';

	deepLearn.addLayer / 
	model='tsRnn2' 
	name='data' 
	layer={type='input' std='std' }; 

	deepLearn.addLayer / 
	model='tsRnn2' 
	name='rnn1' 
	layer={type='recurrent' n=10 act='sigmoid' init='msra' rnnType='lstm' outputtype='samelength'} 
	srcLayers={'data'}; 

	deepLearn.addLayer / 
	model='tsRnn2' 
	name='rnn2' 
	layer={type='recurrent' n=10 act='sigmoid' init='msra' rnnType='lstm' outputtype='samelength'} 
	srcLayers={'rnn1'}; 

	deepLearn.addLayer / 
	model='tsRnn2' 
	name='rnn3' 
	layer={type='recurrent' n=10 act='sigmoid' init='msra' rnnType='lstm' outputtype='samelength'} 
	srcLayers={'rnn2'};

	deepLearn.addLayer / 
	model='tsRnn2' 
	name='rnn4' 
	layer={type='recurrent' n=10 act='sigmoid' init='msra' rnnType='lstm' outputtype='samelength'} 
	srcLayers={'rnn3'};  

	deepLearn.addLayer / 
	model='tsRnn2' 
	name='rnn5' 
	layer={type='recurrent' n=10 act='sigmoid' init='msra' rnnType='lstm' outputtype='encoding'} 
	srcLayers={'rnn4'}; 
 
	deepLearn.addLayer / 
	model='tsRnn2' 
	name='outlayer' 
	layer={type='output' act='identity' error='normal'} 
	srcLayers={'rnn5'};
quit;

/* Added CASLIB public for both dltrain and dlscore codes  */

proc cas;
	deepLearn.dlTrain / 
	table={caslib='public',name='widgets_t' }
	model='tsRnn2' 
	initweights={name='bestbaseweights1', where='_layerid_< 3'}
	modelWeights={name='tsTrainedWeights2', replace=1} 
	bestweights={name='bestbaseweights2', replace=1}
	inputs=${w1-w13}
	target='lwidgets'  
	optimizer={minibatchsize=5, algorithm={method='ADAM', lrpolicy='step',  gamma=0.5,
	beta1=0.9, beta2=0.99, learningrate=.001 clipgradmin=-1000 clipgradmax=1000 }  
	maxepochs=50} 
	seed=54321;
quit;

proc cas;
	deepLearn.dlscore / 
	table={caslib='public',name='widgets_v' }
	model='tsRnn2'
	initweights={name='bestbaseweights2'}
	copyvars={'lwidgets' 'date' }
	casout={name='scoreOut2', replace=1};
quit;

data scored2;
	set casuser.scoreout2;
	widgets = exp(lwidgets);
	forecast = exp(_dl_pred_);
run;

%GOFstats(ModelName=lstm_deep,DSName=work.scored2 ,OutDS=work.lstm_deep,
          NumParms=2,ActualVar=widgets,ForecastVar=Forecast);

proc sgplot data=scored2;
	scatter x=date y=widgets;
	series x=date y=forecast;
run;



