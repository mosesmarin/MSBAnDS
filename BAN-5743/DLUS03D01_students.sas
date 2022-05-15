
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


cas; 
caslib _all_ assign;

libname mycas cas caslib=public;

/*************/
/*Text Mining*/
/*************/

/*  line 26 to 134 are text data preperation fro deep learning*/

/*Quick cleaning of raw data*/
data public.cfpb_complaints;
	set mycas.cfpb_complaints;
	complaint = lowcase(compress(complaint,'ABCDEFGHIJKLMNOPQRSTUVWXYZ.!?1234567890 ', 'ki'));
	complaint = tranwrd(complaint, ' xxxx', '');
	docid + 1;
run;

/*Look for specific terms*/
data mycas.lawyer (drop=newvar);
	set mycas.cfpb_complaints;
	newvar = find(complaint,'lawyer','i');
	if newvar>0;
run;

proc print data=mycas.lawyer (obs=5);
run;

/*Parse the data*/
proc cas;
	loadactionset 'textParse';

	textParse.tpParse /
    table = {caslib='PUBLIC', NAME='CFPB_COMPLAINTS'}
    docid = 'docid'
    text = 'complaint'
    stemming = True
    nounGroups = False
    entities = 'none'
    tagging = False
    parseConfig = {name='config', replace=True}
    offset = {name='offset', replace=True};
quit;

/*Accumulate terms*/
proc cas;
	textParse.tpAccumulate /
    stopList ={caslib='public',name='stoplist'}
    stemming = True
    tagging = False
    reduce = 1
    offset = 'offset'
    showDroppedTerms = False
    parent = {name='parent', replace=True}
    child = {name='child', replace=True}
    terms = {name='terms', replace=True};
	
	table.fetch / 
	table={caslib = 'casuser',name= 'terms'}, to=5;
quit;

/*Find unique terms*/
data terms_unique;
	set casuser.terms;
	by _Term_;
	if last._Term_;
run;

/*Order unique terms*/
proc sql;
	CREATE TABLE top_terms AS
    SELECT _Term_, _Frequency_ 
    FROM terms_unique 
    ORDER BY _Frequency_ DESC;
run;

data top_terms;
	set top_terms (obs=5);
run;

/*Plot the top 5 most used terms*/
proc sgplot data=top_terms;
	vbar _term_ / response=_frequency_;
run;

/*Word Embeddings*/
data embed_sample;
	set mycas.cfpb_complaints_embed;
	if vocab_term in ('credit','tax','loan','debt','default',
                      'unfair','difficult','conflict','fight','harm');
run;

/*View Word Representations*/
proc print data=mycas.cfpb_complaints_embed (obs=5);
run;

proc sgplot data=embed_sample;
	scatter x=x1 y=x2 / datalabel=vocab_term;
run;

/****************/
/*Model Building*/
/****************/

/*Partition the data*/
proc partition data=mycas.cfpb_complaints_clean
	samppct=80 samppct2=10 seed=802 partind;
	output out=public.cfpb_complaints_clean;
run;

proc freq data=mycas.cfpb_complaints_clean;
	tables dispute _partind_ dispute*_partind_;
run;

/*Shuffle data*/
proc cas;
	table.shuffle / 
	table = {caslib='public',name = 'cfpb_complaints_clean'}
	casout = {caslib = 'public', name='cfpb_complaints_clean', replace=True};
quit;

/*Build a RNN*/
proc cas;
	loadactionset "deeplearn";
quit;

proc cas;
	deepLearn.buildModel / 
    model = {name='rnn',replace=True}
    type = 'RNN';

	deepLearn.addLayer /
    model = 'rnn'
    layer = {type='input'}
    replace=True
    name = 'data';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='recurrent', n=30, act='sigmoid', init='xavier', rnnType='rnn', outputType='samelength'}
    srcLayers = 'data'
    replace=True
    name = 'rnn1';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='recurrent', n=30, act='sigmoid', init='xavier', rnnType='rnn', outputType='encoding'}
    srcLayers = 'rnn1'
    replace=True
    name = 'rnn2';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='output', act='auto', init='xavier', error='auto'}
    srcLayers = 'rnn2'
    replace=True
    name = 'output';

	deepLearn.modelInfo / 
    model='rnn';
quit;

/* Added CASLIB public for both dltrain and dlscore codes  */

proc cas;
	deepLearn.dlTrain /
    table    = {caslib = 'public', name = 'cfpb_complaints_clean', where = '_PartInd_ = 1'}
    validTable = {caslib = 'public',name = 'cfpb_complaints_clean', where = '_PartInd_ = 2'}
    target = 'dispute'
    inputs = 'complaint'
    texts = 'complaint'
    textParms = {initInputEmbeddings={caslib = 'public',name='cfpb_complaints_embed'}}
    nominals = 'dispute'
    seed = '649'
    modelTable = 'rnn'
    modelWeights = {name='rnn_trained_weights', replace=True}
    optimizer = {miniBatchSize=100, maxEpochs=30, 
                     algorithm={method='adam', beta1=0.9, beta2=0.999, 
                                learningRate=0.001, gamma=0.5, lrpolicy='step', stepsize=15, 
								clipGradMax=10, clipGradMin=-10}};
quit;

proc cas;
	deepLearn.dlScore / 
    table    = {caslib = 'public', name = 'cfpb_complaints_clean', where = '_PartInd_ = 0'}
    model = 'rnn'
    initWeights = 'rnn_trained_weights'
    copyVars = 'dispute'
    textParms = {initInputEmbeddings={caslib = 'public',name='cfpb_complaints_embed'}}
    casout = {name='rnn_scored', replace=True};
quit;

/*Build a deeper RNN*/
proc cas;
	deepLearn.buildModel / 
    model = {name='rnn',replace=True}
    type = 'RNN';

	deepLearn.addLayer /
    model = 'rnn'
    layer = {type='input'}
    replace=True
    name = 'data';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='recurrent', n=25, act='sigmoid', init='xavier', rnnType='rnn', outputType='samelength'}
    srcLayers = 'data'
    replace=True
    name = 'rnn1';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='recurrent', n=25, act='sigmoid', init='xavier', rnnType='rnn', outputType='samelength'}
    srcLayers = 'rnn1'
    replace=True
    name = 'rnn2';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='recurrent', n=25, act='sigmoid', init='xavier', rnnType='rnn', outputType='encoding'}
    srcLayers = 'rnn2'
    replace=True
    name = 'rnn3';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='output', act='auto', init='xavier', error='auto'}
    srcLayers = 'rnn3'
    replace=True
    name = 'output';

	deepLearn.modelInfo / 
    model='rnn';
quit;

/* Added CASLIB public for both dltrain and dlscore codes  */

proc cas;
	deepLearn.dlTrain /
    table    = {caslib = 'public',name = 'cfpb_complaints_clean', where = '_PartInd_ = 1'}
    validTable = {caslib = 'public',name = 'cfpb_complaints_clean', where = '_PartInd_ = 2'}
    target = 'dispute'
    inputs = 'complaint'
    texts = 'complaint'
    textParms = {initInputEmbeddings={caslib = 'public',name='cfpb_complaints_embed'}}
    nominals = 'dispute'
    seed = '649'
    modelTable = 'rnn'
    modelWeights = {name='rnn_trained_weights', replace=True}
    optimizer = {miniBatchSize=100, maxEpochs=30, 
                     algorithm={method='adam', beta1=0.9, beta2=0.999, 
                                learningRate=0.001, gamma=0.5, lrpolicy='step', stepsize=15, 
								clipGradMax=10, clipGradMin=-10}};
quit;

proc cas;
	deepLearn.dlScore / 
    table    = {caslib = 'public',name = 'cfpb_complaints_clean', where = '_PartInd_ = 0'}
    model = 'rnn'
    initWeights = 'rnn_trained_weights'
    copyVars = 'dispute'
    textParms = {initInputEmbeddings={caslib = 'public',name='cfpb_complaints_embed'}}
    casout = {name='rnn_scored', replace=True};
quit;

/*Build a bidirectional RNN*/
proc cas;
	deepLearn.buildModel / 
    model = {name='rnn',replace=True}
    type = 'RNN';

	deepLearn.addLayer /
    model = 'rnn'
    layer = {type='input'}
    replace=True
    name = 'data';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='recurrent', n=25, act='sigmoid', init='xavier', reverse=True, rnnType='rnn', outputType='samelength'}
    srcLayers = 'data'
    replace=True
    name = 'rnn1';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='recurrent', n=25, act='sigmoid', init='xavier', rnnType='rnn', outputType='samelength'}
    srcLayers = 'rnn1'
    replace=True
    name = 'rnn2';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='recurrent', n=25, act='sigmoid', init='xavier', rnnType='rnn', outputType='encoding'}
    srcLayers = 'rnn2'
    replace=True
    name = 'rnn3';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='output', act='auto', init='xavier', error='auto'}
    srcLayers = 'rnn3'
    replace=True
    name = 'output';

	deepLearn.modelInfo / 
    model='rnn';
quit;

/* Added CASLIB public for both dltrain and dlscore codes  */

proc cas;
	deepLearn.dlTrain /
    table    = {caslib = 'public',name = 'cfpb_complaints_clean', where = '_PartInd_ = 1'}
    validTable = {caslib = 'public',name = 'cfpb_complaints_clean', where = '_PartInd_ = 2'}
    target = 'dispute'
    inputs = 'complaint'
    texts = 'complaint'
    textParms = {initInputEmbeddings={caslib = 'public',name='cfpb_complaints_embed'}}
    nominals = 'dispute'
    seed = '649'
    modelTable = 'rnn'
    modelWeights = {name='rnn_trained_weights', replace=True}
    optimizer = {miniBatchSize=100, maxEpochs=30, 
                     algorithm={method='adam', beta1=0.9, beta2=0.999, 
                                learningRate=0.001, gamma=0.5, lrpolicy='step', stepsize=15, 
								clipGradMax=10, clipGradMin=-10}};
quit;

proc cas;
	deepLearn.dlScore / 
    table    = {caslib = 'public',name = 'cfpb_complaints_clean', where = '_PartInd_ = 0'}
    model = 'rnn'
    initWeights = 'rnn_trained_weights'
    copyVars = 'dispute'
    textParms = {initInputEmbeddings={caslib = 'public',name='cfpb_complaints_embed'}}
    casout = {name='rnn_scored', replace=True};
quit;

/*Build a GRU*/
proc cas;
	deepLearn.buildModel / 
    model = {name='rnn',replace=True}
    type = 'RNN';

	deepLearn.addLayer /
    model = 'rnn'
    layer = {type='input'}
    replace=True
    name = 'data';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='recurrent', n=15, act='sigmoid', init='xavier', rnnType='gru', reverse=True, outputType='samelength'}
    srcLayers = 'data'
    replace=True
    name = 'rnn1';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='recurrent', n=15, act='sigmoid', init='xavier', rnnType='gru', reverse=True, outputType='encoding'}
    srcLayers = 'rnn1'
    replace=True
    name = 'rnn2';

	deepLearn.addLayer / 
    model = 'rnn'
    layer = {type='output', act='auto', init='xavier', error='auto'}
    srcLayers = 'rnn2'
    replace=True
    name = 'output';

	deepLearn.modelInfo / 
    model='rnn';
quit;

/* Added CASLIB public for both dltrain and dlscore codes  */

proc cas;
	deepLearn.dlTrain /
    table    = {caslib = 'public',name = 'cfpb_complaints_clean', where = '_PartInd_ = 1'}
    validTable = {caslib = 'public',name = 'cfpb_complaints_clean', where = '_PartInd_ = 2'}
    target = 'dispute'
    inputs = 'complaint'
    texts = 'complaint'
    textParms = {initInputEmbeddings={caslib = 'public',name='cfpb_complaints_embed'}}
    nominals = 'dispute'
    seed = '649'
    modelTable = 'rnn'
    modelWeights = {name='rnn_trained_weights', replace=True}
    optimizer = {miniBatchSize=100, maxEpochs=30, 
                     algorithm={method='adam', beta1=0.9, beta2=0.999, 
                                learningRate=0.001, gamma=0.5, lrpolicy='step', stepsize=15, 
								clipGradMax=10, clipGradMin=-10}};
quit;

proc cas;
	deepLearn.dlScore / 
    table    = {caslib = 'public',name = 'cfpb_complaints_clean', where = '_PartInd_ = 0'}
    model = 'rnn'
    initWeights = 'rnn_trained_weights'
    copyVars = 'dispute'
    textParms = {initInputEmbeddings={caslib = 'public',name='cfpb_complaints_embed'}}
    casout = {name='rnn_scored', replace=True};
quit;

/*Asses the GRU*/
proc freq data=casuser.rnn_scored;
	tables _dl_predname_*dispute;
run;

proc cas; 
	loadactionset "percentile"; 

	percentile.assess / 
	table={name='rnn_scored'} 
	inputs='_dl_p0_' 
	casout={name='pct', replace=True} 
	response='dispute' 
	event='1'; 
quit;

proc print data=casuser.pct (obs=5);
run;

proc print data=casuser.pct_roc (obs=5);
run;

data pct_roc; 
	set casuser.pct_roc; 
run; 

proc sgplot data=pct_roc; 
	series y=_sensitivity_ x=_fpr_; 
run;









