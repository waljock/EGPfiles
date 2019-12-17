libname lkps '/sasuser/prod/hma03468/XX_IOS/lookup/';
%let worklib = WORK;
%let mainlib = MAIN;
%let lookuplib = lkps;
%include '/sasuser/prod/hma03468/voc_coc.sas';

PROC SQL;
   CREATE TABLE PipelineSALES_DLR AS 
   SELECT	DISTINCT 
		
				
          t1.MODEL_YEAR, 
          t2.ADI_CD, 
          t2.REGION_CD, 
          t2.DEALER_CD, 
          t3.SERIES_CD, 
/*          t3.MODEL_CD, */
/*          t4.ACCESSORY_GROUP_CD, */
          /* PipeSales */
            (SUM(t1.M_MINUS_0_RETAIL_UNITS)) AS ADI_PipeSales, 
          /* PipeMinus_1 */
            (SUM(t1.M_MINUS_1_RETAIL_UNITS)) AS ADI_PipeMinus_1, 
          /* PipeMinus_2 */
            (SUM(t1.M_MINUS_2_RETAIL_UNITS)) AS ADI_PipeMinus_2, 
          /* PipeMinus_3 */
            (SUM(t1.M_MINUS_3_RETAIL_UNITS)) AS ADI_PipeMinus_3, 
          /* DS_UNITS */
            (SUM(t1.DS_UNITS)) AS ADI_DS_UNITS
      FROM SALES.QM_TF_PIPELINE t1

			INNER JOIN SALES.QM_TD_MODEL t3 ON t1.MODEL_KEY = t3.MODEL_KEY AND t1.MODEL_YEAR = t3.MODEL_YEAR
			INNER JOIN SALES.QM_TD_ACCESSORY_GROUP t4 ON t1.ACCESSORY_GROUP_KEY = t4.ACCESSORY_GROUP_KEY 
				AND t1.MODEL_YEAR = t4.MODEL_YEAR
				AND t1.MODEL_KEY = t4.MODEL_KEY

			INNER JOIN SALES.QM_TD_DEALER t2 ON 				
				(t1.DEALER_KEY = t2.DEALER_KEY)

			



              
         WHERE  ( t3.MODEL_YEAR > 2000 AND t2.REGION_CD IN 
           (
           'CE',
           'EA',
           'SC',
           'SO',
           'WE',
		   'MA',
		   'MS'
           )  ) 
      GROUP BY 
	  
			 
			   
               t1.MODEL_YEAR,
               t2.ADI_CD,
               t2.REGION_CD,
         		 t2.DEALER_CD, 
               t3.SERIES_CD
/*               t3.MODEL_CD,*/
/*               t4.ACCESSORY_GROUP_CD*/
;
QUIT; 
proc sql;
	create table &LOOKUPLIB..DEALER_LOCATION as
		select distinct
			a.Inventory_dealer
			,a.ADI_CD
			,a.ADI_DESC
			,a.REGION_CD
			,SUBSTR(a.DEALER_CD,1,2) AS STATE
			,b.ADI_GROUP

		from &MAINLIB..FINAL_FINAL_FINAL a	, &LOOKUPLIB..ADIS  b
			
		where
			a.ADI_CD = b.ADI_CD and
			not missing(a.Inventory_dealer)
			and not missing(a.ADI_CD)
			and not missing(a.ADI_DESC)
			and not missing(a.REGION_CD)
	;
quit;
PROC SQL;
   CREATE TABLE &worklib..DLRS0 AS 
   SELECT t1.DEALER_KEY, 
          t1.DEALER_CD, 
          t1.DEALER_NAME, 
          t1.REGION_CD, 
          t1.ADI_CD, 
          t1.ADI_DESC, 
          t1.ACTIVITY_STATUS_CD, 
          t2.SHOWROOM_ADDRESS_1 as ADDRESS, 
          t2.SHOWROOM_CITY as CITY, 
          t2.SHOWROOM_STATE_CD as STATE,
          input(t2.SHOWROOM_ZIP_5, 5.)  as ZIP
      FROM SALES.QM_TD_DEALER t1
           INNER JOIN SALES.QM_TD_DEALER_CONTACT t2 ON (t1.DEALER_KEY = t2.DEALER_KEY)
      WHERE t1.ACTIVITY_STATUS_CD = 'A' AND t1.REGION_CD IN 
           (
           'CE',
           'EA',
           'SC',
           'SO',
           'WE',
		   'MA',
		   'MS'
           ) and t2.SHOWROOM_ZIP_5 not is missing;
QUIT;
proc sort data=&worklib..DLRS0;
by zip;
run;

proc geocode 
data=&worklib..DLRS0 
out=&worklib..DLRS1
method = zip
attribute_var=(msa areacode);
run;
quit;
data &mainlib..dealer_geo (drop= x y);
set  &worklib..DLRS1;
LAT=y;
LON=x;
run;

 %_eg_conditional_dropds(WORK.QUERY_FOR_PIPELINESALES_DLR);

PROC SQL;
   CREATE TABLE WORK.dealer_pipe_geo AS 
   SELECT DISTINCT t1.MODEL_YEAR, 
          t1.ADI_CD, 
          t1.REGION_CD, 
          t1.DEALER_CD, 
          t1.SERIES_CD, 
          t1.ADI_PipeSales, 
          t1.ADI_PipeMinus_1, 
          t1.ADI_PipeMinus_2, 
          t1.ADI_PipeMinus_3, 
          t1.ADI_DS_UNITS, 
          t2.LAT, 
          t2.LON as LONG,

		  ifn(
		  sum(t1.ADI_DS_UNITS)/((sum(t1.ADI_PipeMinus_1) + sum(t1.ADI_PipeMinus_2) + sum(t1.ADI_PipeMinus_3))/3) > 0, 
			sum(t1.ADI_DS_UNITS)/((sum(t1.ADI_PipeMinus_1) + sum(t1.ADI_PipeMinus_2) + sum(t1.ADI_PipeMinus_3))/3), 0)as MOS
/*          t2.D_DEALER_ID, */
/*          t2.REGION_CD AS REGION_CD1, */
/*          t2.ADI_CD AS ADI_CD1, */
/*          t2.ADI_DESC, */
/*          t2.DEALER_CD AS DEALER_CD1*/
      FROM WORK.PIPELINESALES_DLR t1
           LEFT JOIN &mainlib..dealer_geo t2 ON (t1.DEALER_CD = t2.DEALER_CD) AND (t1.ADI_CD = t2.ADI_CD) AND (t1.REGION_CD = 
          t2.REGION_CD) 
		Where t2.LAT is not missing
		group by 
		  t1.MODEL_YEAR, 
          t1.ADI_CD, 
          t1.REGION_CD, 
          t1.DEALER_CD, 
          t1.SERIES_CD

		;
QUIT;

proc export data=WORK.dealer_pipe_geo
DBMS=XLSX
outfile="/sasuser/prod/hma03468/git/geoShiny/GEO_DLR.xlsx"
replace;
run;



%_eg_conditional_dropds(WORK.DealersForGrouping);

PROC SQL;
   CREATE TABLE WORK.DealersForGrouping AS 
   SELECT t2.DEALER_CD, 
          /* M3 */
            (SUM(t1.M_MINUS_3_RETAIL_UNITS)) AS M3, 
          /* M2 */
            (SUM(t1.M_MINUS_2_RETAIL_UNITS)) AS M2, 
          /* M1 */
            (SUM(t1.M_MINUS_1_RETAIL_UNITS)) AS M1, 
          /* DLRSTOCK */
            (SUM(t1.DS_UNITS)) AS DLRSTOCK, 
          /* SUM_of_TOTAL_PIPELINE_UNITS */
            (SUM(t1.TOTAL_PIPELINE_UNITS)) AS SUM_of_TOTAL_PIPELINE_UNITS, 
          t4.LAT, 
          t4.LON, 
          t3.GEO_LONGITUDE, 
          t3.GEO_LATITUDE,
		  ifn(t3.GEO_LATITUDE is missing, t4.LAT, input(t3.geo_latitude, 30.10))  as adj_lat format = 30.10,
		  ifn(t3.GEO_LONGITUDE is missing, t4.LON, input(t3.geo_LONGITUDE, 30.10)) as adj_long format = 30.10


      FROM SALES.QM_TF_PIPELINE t1
           LEFT JOIN SALES.QM_TD_DEALER t2 ON (t1.DEALER_KEY = t2.DEALER_KEY)
           LEFT JOIN SALES.QM_TD_SITE t3 ON (t1.DEALER_KEY = t3.DEALER_KEY)
           LEFT JOIN MAIN.DEALER_GEO t4 ON (t1.DEALER_KEY = t4.DEALER_KEY)
      WHERE t1.MODEL_YEAR >= 2000 AND t2.REGION_CD IN 
           (
           'CE',
           'EA',
           'SC',
           'SO',
           'WE',
		   'MA',
		   'MS',
           )   
      GROUP BY t2.DEALER_CD,
               t4.LAT,
               t4.LON,
               t3.GEO_LONGITUDE,
               t3.GEO_LATITUDE;
QUIT;
      
 
proc rank data=work.Dealersforgrouping groups=10 out=dealers_ranked;
var DLRSTOCK;
ranks decile;
run;

%_eg_conditional_dropds(WORK.QUERY_FOR_DEALER_PIPE_GEO);

PROC SQL;
   CREATE TABLE WORK.geo_decile AS 
   SELECT t1.MODEL_YEAR, 
          t1.ADI_CD, 
          t1.REGION_CD, 
          t1.DEALER_CD, 
          t1.SERIES_CD, 
          t1.ADI_PipeSales, 
          t1.ADI_PipeMinus_1, 
          t1.ADI_PipeMinus_2, 
          t1.ADI_PipeMinus_3, 
          t1.ADI_DS_UNITS, 
          t1.LAT, 
          t1.LONG, 
          t1.MOS, 
          t2.decile,
			t2.decile+1 as decile_adj 
      FROM WORK.DEALER_PIPE_GEO t1
           INNER JOIN WORK.DEALERS_RANKED t2 ON (t1.DEALER_CD = t2.DEALER_CD);
QUIT;
proc export data=WORK.geo_decile
DBMS=CSV

outfile="/sasuser/prod/hma03468/git/geoDecile/GEO_decile.csv"

replace;
run;
