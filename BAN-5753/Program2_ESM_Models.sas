/* File name: Program2_ESM_Models.sas */
/* Please change LIBNAME path below to where your data are located*/
/* If you have installed SAS on your PC, then you can use your C drive */
/* If you are accessing SAS Via VMware, Use One Drive or USB drive */
/* Check  instructions shared on class site*/

LIBNAME COURSE 'H:\DATA\MKTG6413';
/*  Winter's multiplicative seasonal exponential smoothing application of PROC ESM*/
proc esm data=COURSE.ECOMMERCE outfor=out
back=0 lead=12 print=all  plot=(corr errors modelforecasts) ;
id DATE interval=QUARTER;
forecast ECOMMERCE / model=winters;
Title 'Winters mult model with no holdout, back=0';
run;
proc sgplot data=out;
series x=date y=actual/markers;
series x=date y=predict/markers;
run;

/*  Winter's multiplicative seasonal exponential smoothing application of PROC ESM*/
proc esm data=COURSE.ECOMMERCE outfor=out
back=4 lead=12 print=all  plot=(corr errors modelforecasts) ;
id DATE interval=QUARTER;
forecast ECOMMERCE / model=winters;
Title 'Winters mult model with holdout, back=4';
run;
proc sgplot data=out;
series x=date y=actual/markers;
series x=date y=predict/markers;
run;