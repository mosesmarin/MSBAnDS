/*****************************************************************************/
/*  Create a default CAS session and create SAS librefs for existing caslibs */
/*  so that they are visible in the SAS Studio Libraries tree.               */
/*****************************************************************************/
/***********************************Warning**************************************************************************************/
/* Please run below code (Loading the CAS library code) before exexuting the Deep Learning code                   */
/* if                                                                                                                           */
/*	1) you did not load cas libraries in this session                                                                           */
/*	2) when you receive an error either mycas library does not exist or Train develop / validation develop table doesnot exist  */
/********************************************************************************************************************************/

cas; 
caslib _all_ assign;

/* setting mycas as public caslib where data has been promoted already*/

libname mycas cas caslib=public;



/*Adding library refenece to the Table option below*/

/* Added the caslib reference below to public folder */

proc cas;
image.summarizeimages / table={caslib = 'public' name='SMALLIMAGEDATASHUFFLED', where='_PartInd_=1'};
run;

/* Added code below to load Image and DeepLearn action set */
proc cas;
loadactionset 'DeepLearn';
loadactionset 'image';
run;

Proc Cas;
/*****************************/
/* Build a model shell		 */
/*****************************/

BuildModel / modeltable={name='ConVNN', replace=1} type = 'CNN';


/*****************************/
/* Add an input layer		 */
/*****************************/

AddLayer / model='ConVNN' name='data' layer={type='input' nchannels=3 width=32 height=32 offsets={113.852228,123.021097,125.294747}}; 


/************************************/
/* Add several Convolutional layers */
/************************************/

AddLayer / model='ConVNN' name='ConVLayer1a' layer={type='CONVO' nFilters=8  width=1 height=1 stride=1} srcLayers={'data'};
AddLayer / model='ConVNN' name='ConVLayer1b' layer={type='CONVO' nFilters=8  width=3 height=3 stride=1} srcLayers={'data'};
AddLayer / model='ConVNN' name='ConVLayer1c' layer={type='CONVO' nFilters=8  width=5 height=5 stride=1} srcLayers={'data'};
AddLayer / model='ConVNN' name='ConVLayer1d' layer={type='CONVO' nFilters=8  width=7 height=7 stride=1} srcLayers={'data'};
AddLayer / model='ConVNN' name='ConVLayer1e' layer={type='CONVO' nFilters=10  width=4 height=4 stride=2 dropout=.2} srcLayers={'data'};
AddLayer / model='ConVNN' name='ConVLayer1f' layer={type='CONVO' nFilters=10  width=6 height=6 stride=4 dropout=.2} srcLayers={'data'};


/*****************************/
/* Add a concatination layer */
/*****************************/

AddLayer / model='ConVNN' name='concatlayer1a' layer={type='concat'} srcLayers={'ConVLayer1a','ConVLayer1b','ConVLayer1c','ConVLayer1d'}; 


/***************************/
/* Add a max pooling layer */
/***************************/

AddLayer / model='ConVNN' name='PoolLayer1max' layer={type='POOL'  width=2 height=2 stride=2 pool='max'} srcLayers={'concatlayer1a'}; 


/*****************************/
/* Add a concatination layer */
/*****************************/

AddLayer / model='ConVNN' name='concatlayer2' layer={type='concat'} srcLayers={'PoolLayer1max','ConVLayer1e'}; 


/***************************/
/* Add a max pooling layer */
/***************************/

AddLayer / model='ConVNN' name='PoolLayer2max' layer={type='POOL'  width=2 height=2 stride=2 pool='max'} srcLayers={'concatlayer2'}; 


/*****************************/
/* Add a concatination layer */
/*****************************/

AddLayer / model='ConVNN' name='concatlayer3' layer={type='concat'} srcLayers={'PoolLayer2max','ConVLayer1f'}; 


/***************************/
/* Add a max pooling layer */
/***************************/

AddLayer / model='ConVNN' name='PoolLayer3max' layer={type='POOL'  width=2 height=2 stride=2 pool='max'} srcLayers={'concatlayer3'}; 


/******************************************************/
/* Add a Convolutional layer with Batch Normalization */
/******************************************************/

AddLayer / model='ConVNN' name='ConVLayer1g' layer={type='CONVO' nFilters=64 width=3 height=3 stride=1 init='msra2' dropout=.2} srcLayers={'concatlayer3'}; 
AddLayer / model='ConVNN' name='BatchLayer1' layer={type='BATCHNORM' act='ELU'} srcLayers={'ConVLayer1g'}; 


/******************************************************/
/* Add a Convolutional layer with Batch Normalization */
/******************************************************/

AddLayer / model='ConVNN' name='ConVLayer1h' layer={type='CONVO' nFilters=128  width=3 height=3 stride=2 init='msra2' dropout=.2} srcLayers={'BatchLayer1'}; 
AddLayer / model='ConVNN' name='BatchLayer2' layer={type='BATCHNORM' act='ELU'} srcLayers={'ConVLayer1h'}; 


/*****************************/
/* Add a concatination layer */
/*****************************/

AddLayer / model='ConVNN' name='concatlayer4' layer={type='concat'} srcLayers={'PoolLayer3max','BatchLayer2'}; 


/********************************************************/
/* Add a fully-connected layer with Batch Normalization */
/********************************************************/

AddLayer / model='ConVNN' name='FCLayer1' layer={type='FULLCONNECT' n=240 act='Identity' init='msra2' dropout=.65 includeBias=False}  srcLayers={'concatlayer4'};  
AddLayer / model='ConVNN' name='BatchLayer3' layer={type='BATCHNORM' act='ELU'} srcLayers={'FCLayer1'};


/***********************************************/
/* Add an output layer with softmax activation */
/***********************************************/

AddLayer / model='ConVNN' name='outlayer' layer={type='output' act='SOFTMAX'} srcLayers={'BatchLayer3'};
run;


/****************************************/
/* Train the CNN model, ConVNN			*/
/****************************************/

/* Changes the GPU status from True to False */
/* added caslib refrence to public for both train and validation */

proc cas;
	dlTrain / table={caslib = 'public' name='SMALLIMAGEDATASHUFFLED', where='_PartInd_=1'} model='ConVNN' 
        modelWeights={name='ConVTrainedWeights_d', replace=1}
        bestweights={name='ConVbestweights', replace=1}
        inputs='_image_' 
        target='_label_' nominal={'_label_'}
        GPU=False
         ValidTable={caslib = 'public' name='SMALLIMAGEDATASHUFFLED', where='_PartInd_=2'} 
 
        optimizer={minibatchsize=60, 
        			
        			algorithm={method='ADAM', lrpolicy='Step', gamma=0.5, stepsize=5
       							beta1=0.9, beta2=0.999, learningrate=.01}
        			
        			maxepochs=60} 
        seed=12345
;
run;
