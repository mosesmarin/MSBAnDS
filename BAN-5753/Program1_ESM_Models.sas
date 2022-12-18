/* File name: Program1_ESM_Models.sas */
/* Please change LIBNAME path below to where your data are located*/
/* If you have installed SAS on your PC, then you can use your C drive */
/* If you are accessing SAS Via VMware, Use One Drive or USB drive */
/* Check  instructions shared on class site*/

LIBNAME COURSE 'H:\DATA\MKTG6413';

/* US retail ecommerce sales data from census.gov site */
/* A simple exponential smoothing application of PROC ESM*/

/* Creating a temporary data set with Naive forecst (lagged 1) values */

Data temp; set course.ecommerce;
N_Forecast= Lag(Ecommerce);
run;

/* Plotting Actual versus Lagged values */

proc sgplot data=temp;
series x=date y=Ecommerce/markers;
series x=date y=N_Forecast/markers;
Title 'Plot of Actual vs. Naive Forecast';
run;

/* Exponential smoothing model with no trend or seasonality */

proc esm data=COURSE.ECOMMERCE outfor=out
back=0 lead=12 print=all;
id DATE interval=QUARTER;
forecast ECOMMERCE;
Title 'ESM Model with no trend or seasonality';
run;
proc sgplot data=out;
series x=date y=actual/markers;
series x=date y=predict/markers;
run;

/* A double exponential smoothing (Holt with trend) application of PROC ESM*/
proc esm data=COURSE.ECOMMERCE outfor=out
back=0 lead=12 print=all;
id DATE interval=QUARTER;
forecast ECOMMERCE / model=Linear;
Title 'ESM Model with linear trend but no seasonality';
run;
proc sgplot data=out;
series x=date y=actual/markers;
series x=date y=predict/markers;
run;

/*  Winter's additive seasonal with linear trend exponential smoothing application of PROC ESM*/
proc esm data=COURSE.ECOMMERCE outfor=out
back=0 lead=12 print=all;
id DATE interval=QUARTER;
forecast ECOMMERCE / model=addwinters;
Title 'ESM Model with linear trend and additive seasonality';
run;
proc sgplot data=out;
series x=date y=actual/markers;
series x=date y=predict/markers;
run;

/*  Winter's multiplicative seasonal with linear trend exponential smoothing application of PROC ESM*/
proc esm data=COURSE.ECOMMERCE outfor=out
back=0 lead=12 print=all;
id DATE interval=QUARTER;
forecast ECOMMERCE / model=winters;
Title 'ESM Model with linear trend and multiplicative seasonality';
run;
proc sgplot data=out;
series x=date y=actual/markers;
series x=date y=predict/markers;
run;


