LIBNAME COURSE 'H:\DATA\MKTG6413';

/* Program1_ARIMA_Models: Weekly Solar Power Data from SAS */

Ods graphics on/imagemap=on;
Title 'Generating plots on weekly solar power data';
Proc Timeseries data=course.solarpv seasonality=52 Plots=(series acf pacf wn);
	id EDT interval=week;
	var kW_gen;
Run;
ods graphics off;

/* Identify step to figure out what models to use */
Ods graphics on/imagemap=on;
proc ARIMA data=COURSE.Solarpv plots(unpack)=series(all);
identify var=kW_Gen nlags=12;
run;
ods graphics off;


/* Identify, Estimate and then Forecast AR(1) Model */
Ods graphics on/imagemap=on;
Title 'Forecasting holdout sample on weekly solar power data';
proc ARIMA data=COURSE.Solarpv plots(only)= forecast(forecast forecastonly);
identify var=kW_Gen nlags=12;
estimate p=1 method= ML;
forecast lead=6 back=6 id=EDT out=work.AR1;
run;
ods graphics off;

