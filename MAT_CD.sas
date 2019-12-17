PROC SQL;
   CREATE TABLE WORK.ByModelNum AS 
   SELECT DISTINCT t1.SALES_YEAR, 
          t1.SALES_MONTH, 
          t1.VIN, 
          t1.MODEL_YEAR, 
          t1.MAT_CD,
		  
		 
          
          t1.soldcount, 
          t1.TotalIncentives FORMAT=DOLLAR6., 
          /* TxtSaleMo */
            (put((t1.SALES_YEAR*100)+t1.SALES_MONTH, 6.)) AS TxtSaleMo, 
          t1.RETAIL_SALE_DATE, 
          t1.WHOLESALE_DATE
      FROM work.fin_fin_adigroup t1, SALES.QM_TD_MODEL t2
      WHERE (t1.MODEL_YEAR = t2.MODEL_YEAR AND t1.MODEL_CD = t2.MODEL_CD) AND (/*t1.ADI_GROUP = 'N' AND */
           t1.MODEL_YEAR = 2019) and t1.ADI_GROUP ne 'OTH' and t1.series_cd = '4';
QUIT;

/* Formating to work in terms of weekdays */

/*proc format;
value wd
1 = "Sun"
2 = "Mon"
3 = "Tue"
4 = "Wed"
5 = "Thu"
6 = "Fri"
7 = "Sat"
;
run;*/

/* Similar reduction as in the generic survival datset but focussing on weekdays */

proc sql;
	create table survival2t as
		select
			VIN
			,MODEL_YEAR
			,MAT_CD
			
		/*	,SHOWROOM_STATE_CD
			,ADI_DESC
			,ADI_GROUP
			,DEALER_CD*/
			/*,datepart(HMC_INVOICE_DATE) as HMC_INVOICE_DATE format mmddyy10.
			,datepart(PURIFICATION_DATE) as PURIFICATION_DATE format mmddyy10.*/
			,datepart(WHOLESALE_DATE) as WHOLESALE_DATE format mmddyy10.
			,datepart(RETAIL_SALE_DATE) as RETAIL_SALE_DATE format mmddyy10.
			/*,datepart(RDR_DATE) as RDR_DATE format mmddyy10.*/
			,datepart(RETAIL_SALE_DATE) - datepart(WHOLESALE_DATE) as WHOLESALE_RETAIL_DIFF	label="Days between the wholesale date and the retail sale date"
			/*,weekday(datepart(WHOLESALE_DATE)) as weekday_wsd format wd. label="Weekday of the wholesale date"
			,weekday(datepart(RETAIL_SALE_DATE)) as weekday format wd. label="Weekday of the sale date"*/
		from work.bymodelnum
		where datepart(RETAIL_SALE_DATE) >= datepart(WHOLESALE_DATE)
		
	/*	and SERIES_DESC IN ('SONATA', 'ELANTRA', 'SANTA FE SPORT', 'TUCSON')*/
	;
quit;
data work.PNVS_graph;
set work.ByModelNum;


/*MODEL_CD=tranwrd(MODEL_CD, "PZEV", " ");*/
/*MODEL_CD=tranwrd(MODEL_CD, "- BLACK/GRAY", " ");*/
/*MODEL_CD=tranwrd(MODEL_CD, "- BEIGE", " ");*/
/*MODEL_CD=tranwrd(MODEL_CD, "-  BEIGE", " ");*/
/*MODEL_CD=tranwrd(MODEL_CD, "SULEV", " ");*/
/**/
/*put MODEL_CD;*/


run;
data work.trim_graph;
set work.SURVIVAL2T;


/*MODEL_CD=tranwrd(MODEL_CD, "PZEV", " ");*/
/*MODEL_CD=tranwrd(MODEL_CD, "- BLACK/GRAY", " ");*/
/*MODEL_CD=tranwrd(MODEL_CD, "- BEIGE", " ");*/
/*MODEL_CD=tranwrd(MODEL_CD, "-  BEIGE", " ");*/
/*MODEL_CD=tranwrd(MODEL_CD, "SULEV", " ");*/
/*put MODEL_CD;*/


run;

/* The next code plots the PURCHASE DATE histogram in terms of weekdays */
/* Under the memoryless assumption this plot reflects the relative      */
/* effect of the weekday on the probability to sale                     */
/*ods listing style=listing;
ods graphics / width=7.5in height=3.81in;



Title "Global Histogram: Mix of Trim Level" ;*/
PROC GCHART DATA= trim_graph
;
	VBAR 
	 MAT_CD
 /
	CLIPREF
FRAME	DISCRETE
	TYPE=FREQ
	OUTSIDE=PCT
	COUTLINE=BLACK
	
	levels=all
	legend=legend1
;
RUN; QUIT;

/*data work.trim_graph;
set work.SURVIVAL2T;


ADI_GROUP=tranwrd(ADI_GROUP, "PZEV", " ");
put ADI_GROUP;


run;*/

/* Open the LISTING destination and assign the LISTING style to the graph */ 
/*ods listing style=listing;
ods graphics / width=7.5in height=3.81in;

title 'Mean Time to Sell';
axis1 label=none value=none;
axis2 label=none value=none;
/*axis3 order=(0 to 25 by 5) value=(t=6 '') offset=(0,0)
      label=(a=90) minor=none;
legend1 frame down=1;*/

proc gchart data=work.trim_graph;
  vbar MAT_CD / sumvar= WHOLESALE_RETAIL_DIFF /* group=*/
              
              type=mean nozero space=0 
			  levels=all
			  OUTSIDE=mean
              
              legend=legend1;
run;
quit;

proc gchart data=work.PNVS_graph;
TITLE "Mix By Model";
  vbar MAT_CD / sumvar= totalincentives /* group=*/
              
              type=mean nozero space=0 
			  levels=all
			  OUTSIDE=mean
              
              legend=legend1;
run;
quit;


/* This query groups sales with same time-to-sale and wholesale/retailsale weekday to simplify the next computations */

proc sql noprint;
	select
		min(WHOLESALE_DATE)
		,max(WHOLESALE_DATE)
		,max(WHOLESALE_RETAIL_DIFF)
	into
		:min_wsd
		,:max_wsd
		,:max_diff
	from survival2t;
quit;

/*data base;
	do WHOLESALE_DATE = &min_wsd. to &max_wsd.;
		do WHOLESALE_RETAIL_DIFF = 0 to &max_diff.;
		
			
			output;
		end;
	end;
run;*/

proc sql;
	create table survival_summary2a as
		select 
			MAT_CD
			,WHOLESALE_RETAIL_DIFF
			,WHOLESALE_DATE
			,count(*) as cnt
		from survival2t
		group by MAT_CD, WHOLESALE_RETAIL_DIFF, WHOLESALE_DATE
	;
quit;
data sur_summ2a;
set survival_summary2a;

/*ADI_GROUP=tranwrd(ADI_GROUP, "PZEV", " ");*/
/*ADI_GROUP=tranwrd(ADI_GROUP, "- BLACK/GRAY", " ");*/
/*ADI_GROUP=tranwrd(ADI_GROUP, "- BEIGE", " ");*/
/*ADI_GROUP=tranwrd(ADI_GROUP, "-  BEIGE", " ");*/
/*put ADI_GROUP;*/


run;
proc sql;
	create table survival_summary2a as
		select 
			 MAT_CD
			,WHOLESALE_RETAIL_DIFF
			,WHOLESALE_DATE
			,max(0,cnt) as cnt
		from sur_summ2a 
			
		order by MAT_CD, WHOLESALE_RETAIL_DIFF, WHOLESALE_DATE
	;
quit;
		
proc sql;
	create table survival_summary2b as
		select
		    /*ADI_GROUP*/
			WHOLESALE_RETAIL_DIFF
			,WHOLESALE_DATE
			,count(*) as cnt
		from survival2t
		group by  WHOLESALE_RETAIL_DIFF, WHOLESALE_DATE
		order by  WHOLESALE_RETAIL_DIFF, WHOLESALE_DATE
	;
quit;

proc sql;
	create table hazard2t as
		select
			a.MAT_CD
			,a.WHOLESALE_RETAIL_DIFF
			,a.WHOLESALE_DATE
			,a.cnt
			,sum(b.cnt) as vol
		from 
			survival_summary2a a,
			survival_summary2b b
		where
			a.WHOLESALE_DATE = b.WHOLESALE_DATE
			and a.WHOLESALE_RETAIL_DIFF <= b.WHOLESALE_RETAIL_DIFF
		group by
			a.MAT_CD
			,a.WHOLESALE_RETAIL_DIFF
			,a.WHOLESALE_DATE
			,a.cnt
		order by
			a.MAT_CD
			,a.WHOLESALE_RETAIL_DIFF
			,a.WHOLESALE_DATE
			,a.cnt
	;
quit;
/*****/
proc sql;
	create table hazard2t as
		select
			MAT_CD
			,WHOLESALE_RETAIL_DIFF
			,sum(cnt)/sum(vol) as hazard
			,sum(vol) as volumen
		from hazard2t
		group by
			MAT_CD
			,WHOLESALE_RETAIL_DIFF
		order by
			MAT_CD
			,WHOLESALE_RETAIL_DIFF
	;
quit;

/****/
/*proc sql;
	create table hazard2t as
		select
			ADI_GROUP
			,WHOLESALE_RETAIL_DIFF
			,sum(cnt)/sum(vol) as hazard
			,sum(vol) as volumen
		from hazard2t
		group by
			ADI_GROUP
			,WHOLESALE_RETAIL_DIFF
		order by
			ADI_GROUP
			,WHOLESALE_RETAIL_DIFF
	;
quit;*/

/* This code plots the hazard function for each sales weekday for the whole population in FINAL_FINAL */

%macro symbols;
	%do i=1 %to 7;
		SYMBOL&i. INTERPOL=JOIN HEIGHT=10pt VALUE=NONE LINE=1 WIDTH=2 CV = _STYLE_;
	%end;
%mend;

Legend1 FRAME;
Axis1 STYLE=1 WIDTH=1 MINOR=NONE;
Axis2 STYLE=1 WIDTH=1 MINOR=NONE;

%symbols;
TITLE "Hazard Function: Probability of Sale given the Trim Level";
Title2 "- First year -";
PROC GPLOT DATA = hazard2t(where=(volumen > 200 and WHOLESALE_RETAIL_DIFF < 365));
PLOT hazard * WHOLESALE_RETAIL_DIFF =MAT_CD	
 /
 	VAXIS=AXIS1
	HAXIS=AXIS2
FRAME	LEGEND=LEGEND1;
RUN; QUIT;
TITLE; FOOTNOTE;
GOPTIONS RESET = SYMBOL;
