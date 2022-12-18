LIBNAME COURSE 'H:\DATA\MKTG6413';
/* Program2_ARIMA_Models: ARMAX models Weekly Solar Power Data from SAS */
Ods graphics on/imagemap=on;
Title 'Generating plots on weekly solar power data for relating Y to X variables';
proc timeseries data=COURSE.SOLARPV 
                crossplots=(series ccf);
   id EDT interval=week;
   var kW_Gen;
   crossvar Cloud_Cover cosval;
   ods exclude CCFNORMPlot;
run;
ods graphics off;


Ods graphics on/imagemap=on;
Title 'Estimating ARMAX Parameters - One X Variable';
proc arima data=COURSE.SOLARPV
           plots(only)=(series(corr crosscorr)
                        residual(corr normal));
   identify var=kW_Gen crosscorr=(Cloud_Cover);
   estimate p=(1) input=(Cloud_Cover) method=ML;
   run;
ods graphics off;

Ods graphics on/imagemap=on;
Title 'Estimating ARMAX Parameters – Two X variables';
proc arima data=COURSE.SOLARPV
           plots(only)=(series(corr crosscorr)
                        residual(corr normal));
   identify var=kW_Gen crosscorr=(Cloud_Cover cosval);
   estimate p=(1) input=(Cloud_Cover cosval) method=ML;
   run;
ods graphics off;
