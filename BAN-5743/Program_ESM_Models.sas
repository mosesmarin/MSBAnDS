/* File name: Program_ESM_Models.sas */
/* I am using H drive in this programs. If you are using SAS on your PC, you may use your C drive */
/* If you are using SAS through VMware and have H drive mapped, you may use that. If H drive is not mapped then */
/* in VMware use either USB drive or One Drive based on isntructiosn shared */
/* In all cases, the pathname in the LIBNAME statement below needs to be correctely specified*/

LIBNAME COURSE 'H:\DATA\BootCamp2';
ODS Graphics on/imagemap=on;

/* US retail ecommerce sales data from census.gov site */
/* A simple exponential smoothing application of PROC ESM*/
proc esm data=COURSE.ECOMMERCE outfor=out
back=0 lead=12 print=all;
id DATE interval=QUARTER;
forecast ECOMMERCE;
run;
proc sgplot data=out;
series x=date y=actual/markers;
series x=date y=predict/markers;
run;

/* A double exponential smoothing (Holt) application of PROC ESM*/
proc esm data=COURSE.ECOMMERCE outfor=out
back=0 lead=12 print=all;
id DATE interval=QUARTER;
forecast ECOMMERCE / model=linear; /* when I first created the program, I made a mistake and used Model=Double*/
run;
proc sgplot data=out;
series x=date y=actual/markers;
series x=date y=predict/markers;
run;

/*  Winter's additive seasonal exponential smoothing application of PROC ESM*/
proc esm data=COURSE.ECOMMERCE outfor=out
back=0 lead=12 print=all;
id DATE interval=QUARTER;
forecast ECOMMERCE / model=addwinters;
run;
proc sgplot data=out;
series x=date y=actual/markers;
series x=date y=predict/markers;
run;

/*  Winter's multiplicative seasonal exponential smoothing application of PROC ESM*/
proc esm data=COURSE.ECOMMERCE outfor=out
back=0 lead=12 print=all;
id DATE interval=QUARTER;
forecast ECOMMERCE / model=winters;
run;
proc sgplot data=out;
series x=date y=actual/markers;
series x=date y=predict/markers;
run;
ODS Graphics off;