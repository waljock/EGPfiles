%include "/sasuser/prod/hma03468/voc_coc.sas";




options validvarname = ANY;

PROC SQL;
   CREATE TABLE WORK.BBVal AS 
   SELECT t1.SENT_TO_BLACKBOOK_VIN AS BBVIN, 
          t1.VIN AS HMAVIN, 
          t1.VALUE_AS_OF_DATE AS VALASOFDATE, 
          t1.DEMO_DATE AS INSERVDATE, 
          t1.MSRP, 
          t1.MODEL_YEAR, 
          t1.MODEL_NAME, 
          t1.SERIES_DESC, 
          t1.MILEAGE, 
          t1.FULLY_ADJ_TRADE_IN_CLEAN_VALUE AS BBClean, 
          t1.FULLY_ADJ_TRADE_IN_AVG_VALUE AS BBAverage, 
          t1.FULLY_ADJ_TRADE_IN_ROUGH_VALUE AS BBRough, 
          /* VINMATCH */
            (ifn(t1.SENT_TO_BLACKBOOK_VIN=t1.VIN,1,0)) AS VINMATCH
      FROM PROD.VW_BLACKBOOK_VIN t1
      WHERE t1.DEMO_DATE <= '1Jun2017:0:0:0'dt;
QUIT;
data eqcalcs;
set work.bbval;
/*orig_mo = month(datepart(INSERVDATE));*/
orig_yr = year(datepart(INSERVDATE));
/*orig_dy = day(datepart(INSERVDATE));
orig_qtr = qtr(datepart(INSERVDATE));*/
today = date();
mos_since_org = int((intck('days',datepart(inservdate), today))/365*12);
if orig_yr = 2010 then rate = .0677;
else if orig_yr = 2011 then rate = .0540;
else if orig_yr = 2012 then rate = .0439;
else if orig_yr = 2013 then rate = .0396;
else if orig_yr = 2014 then rate = .0375;
else if orig_yr = 2015 then rate = .0401;
else if orig_yr >= 2016 then rate = .0401;
else if orig_yr >= 2017 then rate = .0485;
else if orig_yr >= 2018 then rate = .0525;
else if orig_yr >= 2019 then rate = .0505;
else rate = .0525;
est_bal_Starting = MSRP * 1.10;
pmt_60 = mort(est_bal_Starting,.,(rate)/12,60);
pmt_72 = mort(est_bal_Starting,.,(rate)/12,72);
bal_60 = finance('FV', rate/12, mos_since_org,pmt_60*-1, est_bal_Starting, 0)*-1;
bal_72 = finance('FV', rate/12, mos_since_org,pmt_72*-1, est_bal_Starting, 0)*-1;
/*eq_60_Clean_Dlr = bbclean-bal_60;*/
eq_60_Average_Dlr = bbaverage-bal_60;
/*eq_60_Rough_Dlr = bbrough - bal_60;*/
/*eq_72_Clean_Dlr = bbclean-bal_72;*/
eq_72_Average_Dlr = bbaverage-bal_72;
/*eq_72_Rough_Dlr = bbrough - bal_72;*/
/*eq_60_Clean = (bbclean-bal_60)/MSRP;
eq_60_Average = (bbaverage-bal_60)/MSRP;
eq_60_Rough = (bbrough - bal_60)/MSRP;
eq_72_Clean = (bbclean-bal_72)/MSRP;
eq_72_Average = (bbaverage-bal_72)/MSRP;
eq_72_Rough = (bbrough - bal_72)/MSRP;*/
wtd_EQT = (eq_60_Average_Dlr * .25)+(eq_72_Average_Dlr * .75);
eqtPCTMSRP = wtd_EQT/MSRP;
where MSRP > 1000 and model_year > 2011;

run;



PROC SQL;
   CREATE TABLE WORK.PIDVINMATCH AS 
   SELECT DISTINCT 
			t1.BBVIN, 
          t1.HMAVIN, 
          t2.PERSON_ID, 
          t2.OWNER_TYPE_CD, 
          t2.MERGE_PERSON_ID, 
          t1.VALASOFDATE, 
          t1.INSERVDATE, 
          t1.MSRP, 
          t1.MODEL_YEAR, 
          t1.MODEL_NAME, 
          t1.SERIES_DESC, 
          t1.MILEAGE, 
          t1.BBClean, 
          t1.BBAverage, 
          t1.BBRough, 
          t1.VINMATCH, 
          t1.orig_yr, 
          t1.today, 
          t1.mos_since_org, 
          t1.rate, 
          t1.est_bal_Starting, 
          t1.pmt_60, 
          t1.pmt_72, 
          t1.bal_60, 
          t1.bal_72, 
          t1.eq_60_Average_Dlr, 
          t1.eq_72_Average_Dlr, 
          t1.wtd_EQT, 
          t1.eqtPCTMSRP
          /*t1.rank_eqtPCTMSRP*/
      FROM work.eqcalcs /*HAEA.BBDECILE*/ t1
           INNER JOIN CUST.CUSTOMER_VEHICLE t2 ON (t1.HMAVIN = t2.VIN)
      WHERE t2.OWNER_TYPE_CD = 'PRI' AND DISPOSAL_CD <> 'H'
      ORDER BY t2.PERSON_ID;
QUIT;
PROC SQL;
   CREATE TABLE WORK.GIDMATCH AS 
   SELECT t1.BBVIN, 
          t1.HMAVIN, 
          t2.GROUP_ID, 
          t1.PERSON_ID, 
          t1.OWNER_TYPE_CD, 
          t1.MERGE_PERSON_ID, 
          t1.VALASOFDATE, 
          t1.INSERVDATE, 
          t1.MSRP, 
          t1.MODEL_YEAR, 
          t1.MODEL_NAME, 
          t1.SERIES_DESC, 
          t1.MILEAGE, 
          t1.BBClean, 
          t1.BBAverage, 
          t1.BBRough, 
          t1.VINMATCH, 
          t1.orig_yr, 
          t1.today, 
          t1.mos_since_org, 
          t1.rate, 
          t1.est_bal_Starting, 
          t1.pmt_60, 
          t1.pmt_72, 
          t1.bal_60, 
          t1.bal_72, 
          t1.eq_60_Average_Dlr, 
          t1.eq_72_Average_Dlr, 
          t1.wtd_EQT ,
          t1.eqtPCTMSRP 
          /*t1.rank_eqtPCTMSRP*/
      FROM WORK.PIDVINMATCH t1
           INNER JOIN CUST.CUSTOMER t2 ON (t1.PERSON_ID = t2.PERSON_ID)
      ORDER BY t1.PERSON_ID;
QUIT;


PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_IDM_TH_HMF_LEASE_BOOKI AS 
   SELECT DISTINCT t1.VEHICLE_KEY
      FROM INCENT.IDM_TH_HMF_LEASE_BOOKING t1;
QUIT;
PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_IDM_TH_HMF_RETAIL_BOOK AS 
   SELECT DISTINCT t1.VEHICLE_KEY
      FROM INCENT.IDM_TH_HMF_RETAIL_BOOKING t1;
QUIT;
PROC SQL;
CREATE TABLE WORK.HMFVK AS 
SELECT * FROM WORK.QUERY_FOR_IDM_TH_HMF_LEASE_BOOKI
 OUTER UNION CORR 
SELECT * FROM WORK.QUERY_FOR_IDM_TH_HMF_RETAIL_BOOK
;
Quit;
PROC SQL;
   CREATE TABLE WORK.HMFMASTER AS 
   SELECT DISTINCT t2.VEHICLE_KEY, 
          t2.VIN
      FROM WORK.HMFVK t1
           INNER JOIN INCENT.IDM_TH_VEHICLE t2 ON (t1.VEHICLE_KEY = t2.VEHICLE_KEY);
QUIT;
PROC SQL;
   CREATE TABLE WORK.HMFCUST AS 
   SELECT t1.BBVIN, 
          t1.HMAVIN, 
          t2.VIN AS HMFVIN, 
          t2.VEHICLE_KEY AS HMFVK, 
          t1.GROUP_ID, 
          t1.PERSON_ID, 
          t1.OWNER_TYPE_CD, 
          t1.MERGE_PERSON_ID, 
          t1.VALASOFDATE, 
          t1.INSERVDATE, 
          t1.MSRP, 
          t1.MODEL_YEAR, 
          t1.MODEL_NAME, 
          t1.SERIES_DESC, 
          t1.MILEAGE, 
          t1.BBClean, 
          t1.BBAverage, 
          t1.BBRough, 
          t1.VINMATCH, 
          t1.orig_yr, 
          t1.today, 
          t1.mos_since_org, 
          t1.rate, 
          t1.est_bal_Starting, 
          t1.pmt_60, 
          t1.pmt_72, 
          t1.bal_60, 
          t1.bal_72, 
          t1.eq_60_Average_Dlr, 
          t1.eq_72_Average_Dlr, 
          t1.wtd_EQT,
          t1.eqtPCTMSRP 
          /*t1.rank_eqtPCTMSRP*/
      FROM WORK.GIDMATCH t1
           LEFT JOIN WORK.HMFMASTER t2 ON (t1.HMAVIN = t2.VIN);
QUIT;
PROC SQL;
   CREATE TABLE WORK.HMFSCRUBBED_0 AS 
   SELECT t1.HMAVIN, 
          t1.GROUP_ID, 
		  put(t1.PERSON_ID, 8.) as PERSON_ID, 
          put(t1.VALASOFDATE, datetime19.) as VALASOFDATE, 
          put(t1.INSERVDATE, datetime19.) as INSERVDATE, 
          t1.MSRP AS MSRP_N, 
          t1.MODEL_YEAR AS YEAR_N, 
          t1.MODEL_NAME, 
          t1.SERIES_DESC, 
          t1.MILEAGE AS MILEAGE_N, 
          t1.BBClean AS BBCLEAN_N, 
          t1.BBAverage AS BBAVERAGE_N, 
          t1.BBRough as BBROUGH_N, 
          t1.mos_since_org AS mos_since_org_N, 
          t1.eq_60_Average_Dlr as eq_60_Average_Dlr_N, 
          t1.eq_72_Average_Dlr as eq_72_Average_Dlr_N, 
          t1.wtd_EQT as WTD_EQT_N,
          t1.eqtPCTMSRP as PCTMSRP_N
          /*t1.rank_eqtPCTMSRP as rank_eqtPCTMSRP_N*/
      FROM WORK.HMFCUST t1
      WHERE t1.HMFVK IS MISSING;
QUIT;
proc rank data=HMFSCRUBBED_0 groups=10 descending out=work.bbdecile;
var PCTMSRP_N;
ranks rank_eqtPCTMSRP_N;
run;
data work.BBdecile;
set work.BBdecile;
rank_eqtPCTMSRP_N = rank_eqtPCTMSRP_N + 1;
run;
quit;
data work.hmfscrubbed_1 (drop= MSRP_N YEAR_N MILEAGE_N BBCLEAN_N BBAVERAGE_N BBROUGH_N mos_since_org_N 
eq_60_Average_Dlr_N WTD_EQT_N rank_eqtPCTMSRP_N  eq_72_Average_Dlr_N PCTMSRP_N );
set work.BBDecile;



/*PERSON_ID = put(PID,8.); */
MSRP = put(msrp_N, Best.);
MODEL_YEAR = put(YEAR_N, BEST.); 
MILEAGE = put(MILEAGE_N, BEST. -L); 
BBClean = put(BBCLEAN_N, BEST.-L);
BBAVERAGE = put(BBAVERAGE_N, BEST. -L);
BBROUGH = put(BBROUGH_N, BEST.-L);
mos_since_org = put(mos_since_org_N, BEST.-L);
eq_60_Average_Dlr = put(eq_60_Average_Dlr_N,BEST. -L);
eq_72_Average_Dlr = put(eq_72_Average_Dlr_N,BEST. -L);
WTD_EQT = put(WTD_EQT_N, BEST. -L);
PCTMSRP = put(PCTMSRP_N*100, BEST. -L) ;
rank_eqtPCTMSRP = put(rank_eqtPCTMSRP_N, BEST. -L);
 

run;
proc sort data=work.hmfscrubbed_1/*(keep=person_id)*/ NODUPKEY out=wjsas.hmfscrubbed;
by person_id;
run;

/*data bbdup;
set bbsort;
if first.person_id then pid=1;
run;
data null;
set bbdup;
where pid = 1;
run;

/*proc sort data=wjsas.hmfscrubbed (obs=10000) NODUPKEY;
by person_id;
run;
/*data wjsas.hmfscrubbed2;
set wjsas.hmfscrubbed;
if first.person_id then pid_ct = 0;
else pid_ct = 1;

run;
data */

ods CSV file= "/sasuser/prod/hma03468/AA_HAEA/equity.txt" options(delimiter="|" quote_by_type = "yes");
proc print data=WJSAS.HMFSCRUBBED noobs;
/*format inservdate date9.;*/
/*format valasofdate date9.*/



run;
ods CSV close;
proc contents data=wjsas.hmfscrubbed;
run;
