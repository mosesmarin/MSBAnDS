

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

/****************/
/*Model Building*/
/****************/
proc print data=mycas.durham (obs=5);
run;

/*Plot one year of data*/
data sample;
	set mycas.durham;
	if lst_date < 20090000 then output sample;
run;

data sample;
	set sample;
	ID+1;
run;

proc sgplot data=sample;
	series x=id y=t_max;
	yaxis min=-20 max=35;
run;

/*Create lags*/

/* lines 46-80 are creating dataset with lag calculation from raw data set*/

data mycas.durham;
	set mycas.durham;
	t_max_1 = lag1(t_max);
	t_max_2 = lag2(t_max);
	t_max_3 = lag3(t_max);
	t_max_4 = lag4(t_max);
	t_max_5 = lag5(t_max);
        
	lst_time_1 = lag1(lst_time);
	lst_time_2 = lag2(lst_time);
	lst_time_3 = lag3(lst_time);
	lst_time_4 = lag4(lst_time);
	lst_time_5 = lag5(lst_time);

	p_calc_1 = lag1(p_calc);
	p_calc_2 = lag2(p_calc);
	p_calc_3 = lag3(p_calc);
	p_calc_4 = lag4(p_calc);
	p_calc_5 = lag5(p_calc);
run;

/*Remove missing*/
data mycas.durham mycas.missing;
	set mycas.durham;
	if cmiss(of _all_) or t_max<-30 then output mycas.missing;
	else output mycas.durham;
run;

/*Partition the data*/
data public.train public.validate public.test;
	set mycas.durham;
	if lst_date < 20150000 then output public.train;
	else if lst_date < 20170000 then output public.validate;
	else output public.test;
run;

/*Build an LSTM model*/
proc cas;
	loadactionset "deeplearn";
quit;

proc cas;
	deepLearn.buildModel /
    model = {name='lstm', replace=True}
    type = 'RNN';

	deepLearn.addLayer /
    model = 'lstm'
    layer = {type='input', std='std'}
    replace = True
    name = 'data';

	deepLearn.addLayer /
    model = 'lstm'
    layer = {type='recurrent', n=15, init='xavier', rnnType='LSTM', outputType='samelength'}
    srcLayers = 'data'
    replace = True
    name = 'rnn1';

	deepLearn.addLayer /
    model = 'lstm'
    layer = {type='recurrent', n=15, init='xavier', rnnType='LSTM', outputType='encoding'}
    srcLayers = 'rnn1'
    replace = True
    name = 'rnn2';

	deepLearn.addLayer /
    model = 'lstm'
    layer = {type='output', act='identity', init='normal'}
    srcLayers = 'rnn2'
    replace = True
    name = 'output';

	deepLearn.modelInfo /
    model='lstm';
quit;

proc cas;
	deepLearn.dlTrain /
    table    = {caslib ='public',name= 'train'}
    validTable = {caslib ='public',name='validate'}
    target = 'T_MAX'
    inputs = {'t_max_5','lst_time_5','p_calc_5',
         	  't_max_4','lst_time_4','p_calc_4',
         	  't_max_3','lst_time_3','p_calc_3',
         	  't_max_2','lst_time_2','p_calc_2',
        	  't_max_1','lst_time_1','p_calc_1'}
    sequenceOpts = {timeStep=3}
    seed = '1234'
    modelTable = 'lstm'
    modelWeights = {name='trained_weights', replace=True}
    optimizer = {miniBatchSize=4, maxEpochs=50, algorithm={method='adam', gamma=0.2, 
                 learningRate=0.01, clipGradMax=10000, clipGradMin=-10000, stepSize=30, lrPolicy='step'}};
quit;

proc cas;
	deepLearn.dlScore /
    table    = {caslib ='public',name='test'}
    model = 'lstm'
    initWeights = 'trained_weights'
    copyVars = {'T_MAX','LST_DATE','LST_TIME'}
    casout = {name='lstm_scored', replace=True};
quit;

data avg_err (keep=abs_diff);
	set casuser.lstm_scored;
	abs_diff = abs(t_max - _dl_pred_);
run;

proc means data=avg_err mean;
run;

data sample;
	set casuser.lstm_scored (obs=1000);
	ID+1;
run;

proc sgplot data=sample;
	series x=ID y=t_max;
	series x=ID y=_dl_pred_;
run;




