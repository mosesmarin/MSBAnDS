* Use this code to create means and cross-tabs of bases and descriptors by clusters in SAS EM *;
* Please change the name _SEGMENT_ to SOM_SEGMENT in 3 places below if you have run SOM in SAS EM and then trying to use this code*;
* Please change the name _SEGMENT_ to CLUSTER in 3 places below if you have run Hirerechical clustering via SAS code in SAS EM and then trying to use this code*;

PROC SUMMARY 
	DATA=&EM_IMPORT_DATA NOPRINT; 
  	CLASS _SEGMENT_ ;  /* Change ro SOM_SEGMENT or CLUSTER as needed*/;
	VAR %EM_INTERVAL_INPUT ; 
	OUTPUT OUT=CLUSTERMEANS   
	Mean = %EM_INTERVAL_INPUT ;
RUN;

TITLE1 "Means of all numeric variables by clusters";
PROC PRINT DATA=CLUSTERMEANS(DROP=_type_) NOOBS; 
	ID _SEGMENT_; /* Change ro SOM_SEGMENT or CLUSTER as needed*/;
	VAR	%EM_INTERVAL_INPUT; 
RUN; QUIT;

TITLE1 "Frequency Distribution of all nominal variables by clusters";
PROC FREQ DATA=&EM_IMPORT_DATA;
TABLES _SEGMENT_*(%EM_NOMINAL_INPUT)/PLOTS=NONE; /* Change ro SOM_SEGMENT or CLUSTER as needed*/;
RUN;
QUIT;
