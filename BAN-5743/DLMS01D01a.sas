/****************************************/
/* Creates a connection to a CAS server */
/* and specifies a CAS library name.    */
/****************************************/

libname mycas cas;

/***************************/
/* Creates a local library */
/***************************/

libname local '/sasdata/GC';

/*****************************/
/* Loads data sets from the  */
/* local machine into memory.*/
/*****************************/

data mycas.train_develop;
	set local.train_develop;
run;

data mycas.valid_develop;
	set local.valid_develop;
run;

data mycas.test_develop;
	set local.test_develop;
run;

proc casutil;
	list tables incaslib="casuser";
	promote casdata="train_develop"
	incaslib="casuser" outcaslib="casuser" casout="train_develop";
	promote casdata="test_develop"
	incaslib="casuser" outcaslib="casuser" casout="test_develop";
	promote casdata="valid_develop"
	incaslib="casuser" outcaslib="casuser" casout="valid_develop";
	list tables incaslib="casuser";
	run;