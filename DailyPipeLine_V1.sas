ods select all;

%include "/sashome/prod/HMA03468/voc_coc.sas";

%let fname = %sysfunc(today(),YYmmddn8.);
%put =====> fname= &fname;


PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_QM_TF_PIPELINE AS 
   SELECT t1.REGION_KEY, 
          t1.PORT_KEY, 
          t1.DISTRICT_KEY, 
          t1.ADI_KEY, 
          t1.DEALER_KEY, 
          t1.MODEL_YEAR, 
          t1.SERIES_KEY, 
          t1.FAMILY_KEY, 
          t1.DOOR_KEY, 
          t1.TRIM_KEY, 
          t1.TRANSMISSION_KEY, 
          t1.DRIVETRAIN_KEY, 
          t1.ENGINE_TYPE_KEY, 
          t1.MODEL_EMISSION_KEY, 
          t1.MODEL_KEY, 
          t1.COLOR_KEY, 
          t1.ACCESSORY_GROUP_KEY, 
          t1.MFG_PLANT_KEY, 
          t1.PRODUCTION_ORDER_MONTH_KEY, 
          t1.VIN_BRAND_KEY, 
          t1.ORG_BRAND_KEY, 
          t1.VIN_BRAND_CD, 
          t1.ORG_BRAND_CD, 
          t1.PRODUCTION_ORDER_NUM, 
          t1.M_MINUS_0_RETAIL_UNITS, 
          t1.M_MINUS_1_RETAIL_UNITS, 
          t1.M_MINUS_2_RETAIL_UNITS, 
          t1.M_MINUS_3_RETAIL_UNITS, 
          t1.TOTAL_DS_TO_RETAIL_DAYS, 
          t1.M1_TO_M3_RETAIL_UNITS, 
          t1.DS_UNITS, 
          t1.TOTAL_DS_DAYS, 
          t1.TN_UNITS, 
          t1.IT_UNITS, 
          t1.IR_UNITS, 
          t1.PA_UNITS, 
          t1.PS_UNITS, 
          t1.AA_UNITS, 
          t1.AS_UNITS, 
          t1.LA_UNITS, 
          t1.LS_UNITS, 
          t1.RS_UNITS, 
          t1.HMA_TOTAL_UNITS, 
          t1.VA_UNITS, 
          t1.VS_UNITS, 
          t1.VPC_TOTAL_UNITS, 
          t1.BUILT_TOTAL_UNITS, 
          t1.MA_UNITS, 
          t1.MS_UNITS, 
          t1.PLANT_TOTAL_UNITS, 
          t1.HMC_ONS_UNITS, 
          t1.TOTAL_PIPELINE_UNITS, 
          /* datepart */
            (datepart(t1.REC_CREATE_DATE)) AS datepart
      FROM SALES.QM_TF_PIPELINE t1;
QUIT;
%_eg_conditional_dropds(WORK.QUERY_FOR_QM_TD_DATE);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_QM_TD_DATE AS 
   SELECT t1.DATE_KEY, 
          /* datepart */
            (datepart(t1.CALENDAR_DATE)) AS datepart, 
          t1.SALES_MONTH_KEY, 
          t1.IS_SALES_MONTH_END
      FROM SALES.QM_TD_DATE t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.Pipe AS 
   SELECT t1.REGION_KEY, 
          t1.PORT_KEY, 
          t1.DISTRICT_KEY, 
          t1.ADI_KEY, 
          t1.DEALER_KEY, 
          t1.MODEL_YEAR, 
          t1.SERIES_KEY, 
          t1.FAMILY_KEY, 
          t1.DOOR_KEY, 
          t1.TRIM_KEY, 
          t1.TRANSMISSION_KEY, 
          t1.DRIVETRAIN_KEY, 
          t1.ENGINE_TYPE_KEY, 
          t1.MODEL_EMISSION_KEY, 
          t1.MODEL_KEY, 
          t1.COLOR_KEY, 
          t1.ACCESSORY_GROUP_KEY, 
          t1.MFG_PLANT_KEY, 
          t1.PRODUCTION_ORDER_MONTH_KEY, 
          t1.VIN_BRAND_KEY, 
          t1.ORG_BRAND_KEY, 
          t1.VIN_BRAND_CD, 
          t1.ORG_BRAND_CD, 
          t1.PRODUCTION_ORDER_NUM, 
          t1.M_MINUS_0_RETAIL_UNITS, 
          t1.M_MINUS_1_RETAIL_UNITS, 
          t1.M_MINUS_2_RETAIL_UNITS, 
          t1.M_MINUS_3_RETAIL_UNITS, 
          t1.TOTAL_DS_TO_RETAIL_DAYS, 
          t1.M1_TO_M3_RETAIL_UNITS, 
          t1.DS_UNITS, 
          t1.TOTAL_DS_DAYS, 
          t1.TN_UNITS, 
          t1.IT_UNITS, 
          t1.IR_UNITS, 
          t1.PA_UNITS, 
          t1.PS_UNITS, 
          t1.AA_UNITS, 
          t1.AS_UNITS, 
          t1.LA_UNITS, 
          t1.LS_UNITS, 
          t1.RS_UNITS, 
          t1.HMA_TOTAL_UNITS, 
          t1.VA_UNITS, 
          t1.VS_UNITS, 
          t1.VPC_TOTAL_UNITS, 
          t1.BUILT_TOTAL_UNITS, 
          t1.MA_UNITS, 
          t1.MS_UNITS, 
          t1.PLANT_TOTAL_UNITS, 
          t1.HMC_ONS_UNITS, 
          t1.TOTAL_PIPELINE_UNITS, 
          t2.SALES_MONTH_KEY, 
          t1.datepart, 
          t2.IS_SALES_MONTH_END
      FROM WORK.QUERY_FOR_QM_TF_PIPELINE t1
           INNER JOIN WORK.QUERY_FOR_QM_TD_DATE t2 ON (t1.datepart = t2.datepart);
QUIT;

data WJSAS.pipedate&fname;
set pipe;
*if is_SALES_MONTH_END = 1;


run;
