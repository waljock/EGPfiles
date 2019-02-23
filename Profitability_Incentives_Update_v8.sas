%include "/sashome/prod/HMA03468/voc_coc.sas";




options validvarname = ANY;


/*libname lookups META library= "HMA_PROD_LOOKUP";
libname PRO_ODS META library= "CVA_PROD_HMA_ODS";
libname PRO_MDM META library= "CVA_PROD_HMA_MDM";


/*Imports happen from an excel file which will need updating on a regular basis
  Do the imports before running the program */

/*Now lets do the system queries first*/

/* This is where the sales basis starts */

/*PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_QM_VH_RDR AS 
   SELECT DISTINCT t1.VEHICLE_KEY, 
          t1.VIN, 
          t2.MODEL_YEAR, 
          t2.SERIES_CD, 
          t2.MODEL_CD, 
		  t2.TRIM_CD,
          t3.CURRENT_PORT_CD, 
          t2.ACCESSORY_GROUP_KEY
      FROM SALES.QM_VH_RDR t1, SALES.QM_TH_VEHICLE t2, SALES.QM_TH_VEHICLE_STATUS t3
      WHERE (t1.VEHICLE_KEY = t2.VEHICLE_KEY AND t1.VEHICLE_KEY = t3.VEHICLE_KEY) AND t2.MODEL_YEAR >= 2018;
QUIT;*/
PROC SQL;
   CREATE TABLE WORK.ALL_VEHICLES AS 
   SELECT t1.VEHICLE_KEY, 
          t1.VIN, 
          t1.MODEL_YEAR, 
		  t1.PLANT_CD,
          t1.SERIES_CD,
		  t3.SERIES_DESC, 
          t1.MODEL_CD, 
          t1.TRIM_CD, 
          t2.CURRENT_PORT_CD, 
		  t2.ALLOCATION_DEALER_KEY,
		  ifn(t2.INVENTORY_DEALER_KEY is missing, t2.ALLOCATION_DEALER_KEY, t2.INVENTORY_DEALER_KEY) as dk,
          t1.ACCESSORY_GROUP_KEY
      FROM SALES.QM_TH_VEHICLE t1, SALES.QM_TH_VEHICLE_STATUS t2, SALES.QM_TD_SERIES t3
      WHERE (t1.VEHICLE_KEY = t2.VEHICLE_KEY AND t1.SERIES_KEY = t3.SERIES_KEY) AND t1.MODEL_YEAR >= 2015
		AND CURRENT_REGION_KEY in(-2,1,2,3,8,9,10);
QUIT;

proc sort data=profit.accessory out=profit.accessory nodup ;
by TxtMY Model_Code ACC_Code;
run;
PROC SQL;
   CREATE TABLE WORK.ACC_CONSOL AS 
   SELECT DISTINCT /* TxtMY */
                     (put(t1.MODEL_YEAR,best4.)) AS TxtMY, 
          t1.MODEL_CD, 
          t1.ACCESSORY_GROUP_CD, 
          t1.ACCESSORY_01_CD, 
          t1.ACCESSORY_02_CD, 
          t1.ACCESSORY_03_CD, 
          t1.ACCESSORY_04_CD, 
          t1.ACCESSORY_05_CD, 
          t1.ACCESSORY_06_CD, 
          t1.ACCESSORY_07_CD, 
          t1.ACCESSORY_08_CD, 
          t1.ACCESSORY_09_CD, 
          t1.ACCESSORY_10_CD, 
          t1.ACCESSORY_11_CD, 
          t1.ACCESSORY_12_CD, 
          t1.ACCESSORY_13_CD, 
          t1.ACCESSORY_14_CD, 
          t1.ACCESSORY_15_CD, 
          t1.ACCESSORY_16_CD, 
          t1.ACCESSORY_17_CD, 
          t1.ACCESSORY_18_CD, 
          t1.ACCESSORY_19_CD, 
          t1.ACCESSORY_20_CD
      FROM SALES.QM_TD_ACCESSORY_GROUP t1
      WHERE t1.MODEL_YEAR >= 2015;
QUIT;
PROC SQL;
   CREATE TABLE WORK.INCENTIVE_DATA0 AS 
   SELECT t2.IDMVK, 
          t2.SALESVK, 
          /*t2.VIN, */
          t1.*
      FROM WJSAS.INCENTIVES_DATABASE t1
           INNER JOIN WJSAS.IDMCONVERT t2 ON (t1.VK = t2.IDMVK);

QUIT;
data WORK.INCENTIVE_DATA (drop=SERIES_DESC);
   set WORK.INCENTIVE_DATA0;
   array change _numeric_;
        do over change;
            if change=. then change=0;
        end;
 run ;

PROC SQL;
   CREATE TABLE WORK.SALES_VEHINFO AS 
   SELECT  
          t1.*, 
		  t1.dk as Inventory_dealer_key,
          /* TxtMY */
            (put(t3.MODEL_YEAR,best4.)) AS TxtMY, 
          

         
          t3.ACCESSORY_GROUP_CD, 
          /* ManifestTot */
            (t2.MANIFEST_FOB_AMT+t2.MANIFEST_FREIGHT_AMT+t2.MANIFEST_INSURE_AMT) AS ManifestTot, 
          t3.ACCESSORY_01_CD, 
          t3.ACCESSORY_02_CD, 
          t3.ACCESSORY_03_CD, 
          t3.ACCESSORY_04_CD, 
          t3.ACCESSORY_05_CD, 
          t3.ACCESSORY_06_CD, 
          t3.ACCESSORY_07_CD, 
          t3.ACCESSORY_08_CD, 
          t3.ACCESSORY_09_CD, 
          t3.ACCESSORY_10_CD, 
          t3.ACCESSORY_11_CD, 
          t3.ACCESSORY_12_CD, 
          t3.ACCESSORY_13_CD, 
          t3.ACCESSORY_14_CD, 
          t3.ACCESSORY_15_CD, 
          t3.ACCESSORY_16_CD, 
          t3.ACCESSORY_17_CD, 
          t3.ACCESSORY_18_CD, 
          t3.ACCESSORY_19_CD, 
          t3.ACCESSORY_20_CD, 
          t2.DEALER_COST_BASE_AMT, 
          t2.DEALER_COST_FACTORY_ACCY_AMT, 
          t2.DEALER_COST_PIO_ACCY_AMT, 
          t2.FREIGHT_CHARGE_AMT, 
          t2.ADVERTISING_AMT, 
          t2.OTHER_CHARGE_AMT, 
          t2.MSRP_BASE_AMT, 
          t2.MSRP_FACTORY_ACCY_AMT, 
          t2.MSRP_PIO_ACCY_AMT
      FROM WORK.ALL_VEHICLES t1, SALES.QM_TH_VEHICLE_COST t2, SALES.QM_TD_ACCESSORY_GROUP t3
      WHERE (t1.VEHICLE_KEY = t2.VEHICLE_KEY AND t1.ACCESSORY_GROUP_KEY = t3.ACCESSORY_GROUP_KEY AND t1.MODEL_YEAR = 
           t3.MODEL_YEAR AND t1.SERIES_CD = t3.SERIES_CD AND t1.MODEL_CD = t3.MODEL_CD);
QUIT;

PROC SQL;
   CREATE TABLE WORK.Sales_With_Acces_Group AS 
   SELECT DISTINCT t1.VEHICLE_KEY, 
          t1.VIN, 
          t1.TxtMY, 
          t1.SERIES_CD, 
		  t1.SERIES_DESC,
		  t1.PLANT_CD,

          t1.MODEL_CD, 
		  t1.TRIM_CD,
          t1.CURRENT_PORT_CD, 
		  t1.ALLOCATION_DEALER_KEY,
		  t1.INVENTORY_DEALER_KEY,
          t1.ACCESSORY_GROUP_CD, 
          t1.ManifestTot, 
          t1.DEALER_COST_BASE_AMT, 
          t1.DEALER_COST_FACTORY_ACCY_AMT, 
          t1.DEALER_COST_PIO_ACCY_AMT, 
          t1.FREIGHT_CHARGE_AMT, 
          t1.ADVERTISING_AMT, 
          t1.OTHER_CHARGE_AMT, 
          t1.MSRP_BASE_AMT, 
          t1.MSRP_FACTORY_ACCY_AMT, 
          t1.MSRP_PIO_ACCY_AMT
      FROM WORK.SALES_VEHINFO t1;
QUIT;


proc transpose data=work.acc_consol out=consolidated (rename=(col1=ACCCD));
by TxtMY model_cd accessory_group_cd;
var accessory_01_cd accessory_02_cd accessory_03_cd accessory_04_cd accessory_05_cd accessory_06_cd
	accessory_07_cd accessory_08_cd accessory_09_cd accessory_10_cd accessory_11_cd accessory_12_cd
	accessory_13_cd accessory_14_cd accessory_15_cd accessory_16_cd accessory_17_cd accessory_18_cd 
	accessory_19_cd accessory_20_cd;

run;


PROC SQL;
   CREATE TABLE WORK.SYS_ACC_CODE AS 
   SELECT DISTINCT t1.TxtMY, 
          t1.MODEL_CD, 
          t1.ACCESSORY_GROUP_CD, 
          t1.ACCCD
      FROM WORK.consolidated t1
      WHERE t1.ACCCD NOT IS MISSING;
QUIT;

PROC SQL;
   CREATE TABLE WORK.ByGroupCode AS 
   SELECT DISTINCT t1.TxtMY, 
          t1.MODEL_CD, 
          t1.ACCESSORY_GROUP_CD, 
          /* Acc_Group_Cost */
            (SUM(t2.ACC_COST)) FORMAT=NEGPAREN12. AS Acc_Group_Cost
      FROM WORK.SYS_ACC_CODE t1
           LEFT JOIN PROFIT.ACCESSORY t2 ON (t1.TxtMY = t2.TxtMY) AND (t1.MODEL_CD = t2.Model_Code) AND (t1.ACCCD = t2.ACC_Code)
      GROUP BY t1.TxtMY,
               t1.MODEL_CD,
               t1.ACCESSORY_GROUP_CD;
QUIT;
proc sort data=profit.ppr;
by TxtMY Model_Code Port;
run;
PROC SQL;
   CREATE TABLE WORK.SalesbyAccGroupCost AS 
   SELECT t1.VEHICLE_KEY, 
          t1.VIN, 
          t1.TxtMY, 
          t1.SERIES_CD,
		  t1.PLANT_CD,
		  t1.SERIES_DESC,	 
		  t1.TRIM_CD,
          t1.MODEL_CD, 
          t1.CURRENT_PORT_CD, 
		  t1.ALLOCATION_DEALER_KEY,
		  t1.INVENTORY_DEALER_KEY,
          t1.ACCESSORY_GROUP_CD, 
          /* ACC_GROUP_COST1 */
            (ifn(t2.ACCESSORY_GROUP_CD is missing, 0,t2.Acc_Group_Cost)) AS ACC_GROUP_COST1, 
          t1.ManifestTot, 
          t1.DEALER_COST_BASE_AMT, 
          t1.DEALER_COST_FACTORY_ACCY_AMT, 
          t1.DEALER_COST_PIO_ACCY_AMT, 
          t1.FREIGHT_CHARGE_AMT, 
          t1.ADVERTISING_AMT, 
          t1.OTHER_CHARGE_AMT, 
          t1.MSRP_BASE_AMT, 
          t1.MSRP_FACTORY_ACCY_AMT, 
          t1.MSRP_PIO_ACCY_AMT
      FROM WORK.SALES_WITH_ACCES_GROUP t1
           LEFT JOIN WORK.BYGROUPCODE t2 ON (t1.TxtMY = t2.TxtMY) AND (t1.MODEL_CD = t2.MODEL_CD) AND 
          (t1.ACCESSORY_GROUP_CD = t2.ACCESSORY_GROUP_CD);
QUIT;
/* Start of new code 2018 06 28 */

/*PROC SQL;*/
/*   CREATE TABLE WORK.SALESBYPORTCOSTS AS */
/*   SELECT t1.VEHICLE_KEY, */
/*          t1.VIN, */
/*          t1.TxtMY, */
/*          t1.SERIES_CD,*/
/*		t1.SERIES_DESC, */
/*		t1.PLANT_CD,*/
/*		  t1.TRIM_CD,*/
/*          t1.MODEL_CD, */
/*          t1.CURRENT_PORT_CD, */
/*		  t1.ALLOCATION_DEALER_KEY,*/
/*		  t1.INVENTORY_DEALER_KEY,*/
/*          t1.ACCESSORY_GROUP_CD, */
/*          t1.ManifestTot, */
/*          t1.ACC_GROUP_COST1, */
/*          t2.MAX_of_RFT_STD AS RFT_STD, */
/*          t3.PPR_STD AS PPR_COST, */
/*          t4.MFT_Std, */
/*          t1.DEALER_COST_BASE_AMT, */
/*          t1.DEALER_COST_FACTORY_ACCY_AMT, */
/*          t1.DEALER_COST_PIO_ACCY_AMT, */
/*          t1.FREIGHT_CHARGE_AMT, */
/*          t1.ADVERTISING_AMT, */
/*          t1.OTHER_CHARGE_AMT, */
/*          t1.MSRP_BASE_AMT, */
/*          t1.MSRP_FACTORY_ACCY_AMT, */
/*          t1.MSRP_PIO_ACCY_AMT*/
/*      FROM WORK.SALESBYACCGROUPCOST t1*/
/*           LEFT JOIN PROFIT.RFT t2 ON (t1.TxtMY = t2.TxtMY) AND (t1.MODEL_CD = t2.Model_Code) AND */
/*          (t1.CURRENT_PORT_CD = t2.Port)*/
/*           LEFT JOIN PROFIT.PPR t3 ON (t1.TxtMY = t3.TxtMY) AND (t1.MODEL_CD = t3.Model_Code) AND */
/*          (t1.CURRENT_PORT_CD = t3.Port)*/
/*           LEFT JOIN PROFIT.MFT t4 ON (t1.TxtMY = t4.TxtMY) AND (t1.MODEL_CD = t4.Model_Code) AND */
/*          (t1.CURRENT_PORT_CD = t4.Port);*/
/*QUIT;*/

PROC SQL;
   CREATE TABLE WORK.Pricing_Draft AS 
   SELECT DISTINCT t1.VEHICLE_KEY, 
          t1.VIN, 
          t1.TxtMY, 
          t1.SERIES_CD,
		t1.SERIES_DESC, 
		  t1.TRIM_CD,
          t1.MODEL_CD, 
          t1.CURRENT_PORT_CD,
		  t1.PLANT_CD,
		 	t1.ALLOCATION_DEALER_KEY,
		  t1.INVENTORY_DEALER_KEY, 
          t1.ACCESSORY_GROUP_CD, 
          t1.ManifestTot, 
/*          t1.RFT_STD AS RFT_COST, */
          t1.ACC_GROUP_COST1, 
/*          t1.PPR_COST, */
/*          t1.MFT_Std, */
          t2.FOBSTD3 as FOB_STD, 
/*          t2.FOBSTD3*t3.DutyStd as DutyDollar, */
/*          t2.BEF2017, */
/*          t2.AF2017, */
          t1.DEALER_COST_BASE_AMT, 
          t1.DEALER_COST_FACTORY_ACCY_AMT, 
          t1.DEALER_COST_PIO_ACCY_AMT, 
          t1.FREIGHT_CHARGE_AMT, 
          t1.ADVERTISING_AMT, 
          t1.OTHER_CHARGE_AMT, 
          t1.MSRP_BASE_AMT, 
          t1.MSRP_FACTORY_ACCY_AMT, 
          t1.MSRP_PIO_ACCY_AMT
      FROM WORK.SalesbyAccGroupCost t1
           LEFT JOIN PROFIT.STD_PRICE t2 ON (t1.TxtMY = t2.TxtMY) AND (t1.MODEL_CD = t2.Model_Code)
		  /* LEFT JOIN PROFIT.DUTY1 t3 ON (t1.TxtMY = t3.TxtMY) AND (t1.Model_CD = t3.Model_Code)*/
;
QUIT;


/*data WORK.Pricing_Draft;*/
/*  set WORK.Pricing_Draft;*/
/*  array change _numeric_;*/
/*       do over change;*/
/*           if change=. then change=0;*/
/*       end;*/
/*run ;*/

PROC SQL;
   CREATE TABLE PROFIT.FINAL_PRICING_FOB AS 
   SELECT t1.VEHICLE_KEY, 
          t1.VIN, 
          t1.TxtMY, 
          t1.SERIES_CD,
		  t1.SERIES_DESC,
		  t1.TRIM_CD, 
          t1.MODEL_CD,
		  t1.plant_cd, 
          t1.CURRENT_PORT_CD,
		  t1.ALLOCATION_DEALER_KEY,
		  t1.INVENTORY_DEALER_KEY, 
          t1.ManifestTot, 
          t1.ACCESSORY_GROUP_CD, 
          t1.ACC_GROUP_COST1, 
/*          t1.RFT_COST AS RFT_COST, */
/*          t1.PPR_COST, */
          t1.FOB_STD AS FOB_STD, 
/*          t1.MFT_Std, */
/*          t1.DutyDollar, */
/*          t1.BEF2017, */
/*          t1.AF2017, */
/*          /* STD_FOB_DATED */
/*          t1.AF2017  AS STD_INS_DATED, */
			/*(ifn(t2.HMC_INVOICE_DATE>='1Jan2017:0:0:1'dt,t1.AF2017,t1.BEF2017)) AS STD_INS_DATED, */
          t2.HMC_INVOICE_DATE, 
          t2.PURIFICATION_DATE, 
          t2.WHOLESALE_DATE, 
          t2.RETAIL_SALE_DATE, 
          t2.RDR_DATE, 
          /* days2whse */
            (INTCK('days', datepart(t2.HMC_INVOICE_DATE), datepart(t2.WHOLESALE_DATE))) AS days2whse, 
          /* days2rdr */
            (intck('days',datepart(t2.WHOLESALE_DATE),datepart(t2.RDR_DATE))) AS days2rdr, 
		   /* CY */
		    (YEAR(datepart(t2.PURIFICATION_DATE))) AS CY,
          t1.DEALER_COST_BASE_AMT, 
          t1.DEALER_COST_FACTORY_ACCY_AMT, 
          t1.DEALER_COST_PIO_ACCY_AMT, 
          t1.FREIGHT_CHARGE_AMT, 
          t1.ADVERTISING_AMT, 
          t1.OTHER_CHARGE_AMT, 
          t1.MSRP_BASE_AMT, 
          t1.MSRP_FACTORY_ACCY_AMT, 
          t1.MSRP_PIO_ACCY_AMT
      FROM WORK.PRICING_DRAFT t1
           LEFT JOIN SALES.QM_TH_VEHICLE_STATUS t2 ON (t1.VEHICLE_KEY = t2.VEHICLE_KEY);
QUIT;

data PROFIT.pricingdata;
   set PROFIT.final_pricing_fob (drop=hmc_invoice_date PURIFICATION_DATE WHOLESALE_DATE RETAIL_SALE_DATE RDR_DATE) ;
   array change _numeric_;
        do over change;
            if change=. then change=0;
        end;
		set PROFIT.final_pricing_fob (keep=hmc_invoice_date PURIFICATION_DATE WHOLESALE_DATE RETAIL_SALE_DATE RDR_DATE) ;
 run ;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_PRICINGDATA0 AS 
   SELECT t1.VEHICLE_KEY, 
          t1.VIN, 
          t1.TxtMY, 
          t1.SERIES_CD,
		t1.SERIES_DESC,
			t1.PLANT_CD, 
		  t1.TRIM_CD,
          t1.MODEL_CD, 
		  t1.CY,
		  
		  t2.DEALER_CD AS Allocation_Dealer,
		  t1.INVENTORY_DEALER_KEY, 
		  /*t2.DEALER_CD as Inventory_Dealer,*/



          t1.CURRENT_PORT_CD, 
          t1.ManifestTot, 
          t1.ACCESSORY_GROUP_CD, 
          t1.ACC_GROUP_COST1, 
/*          t1.RFT_COST, */
/*          t1.PPR_COST, */
          t1.FOB_STD, 
/*          t1.MFT_Std, */
/*          t1.DutyDollar, */
/*          t1.BEF2017, */
/*          t1.AF2017, */
/*          t1.STD_INS_DATED, */
          t1.HMC_INVOICE_DATE, 
          t1.PURIFICATION_DATE, 
          t1.WHOLESALE_DATE, 
          t1.RETAIL_SALE_DATE, 
          t1.RDR_DATE, 
          t1.days2whse, 
          t1.days2rdr, 
          t1.DEALER_COST_BASE_AMT, 
          t1.DEALER_COST_FACTORY_ACCY_AMT, 
          t1.DEALER_COST_PIO_ACCY_AMT, 
          t1.FREIGHT_CHARGE_AMT, 
          t1.ADVERTISING_AMT, 
          t1.OTHER_CHARGE_AMT, 
          t1.MSRP_BASE_AMT, 
          t1.MSRP_FACTORY_ACCY_AMT, 
          t1.MSRP_PIO_ACCY_AMT,
		  t3.Eqfrt as EQ_FREIGHT,
		  t3.Duty*t1.FOB_STD as EQ_DUTY,
		  t3.INS*t1.FOB_STD as EQ_MINS,
		  t3.MFT as EQ_MFT,
		  t3.PPR as EQ_PPR,
		  t3.PDI as EQ_PDI
		  
      FROM PROFIT.PRICINGDATA t1
	  LEFT JOIN SALES.QM_TD_DEALER t2 ON (t1.ALLOCATION_DEALER_KEY = t2.DEALER_KEY)
	  LEFT JOIN PROFIT.EQUALIZED_FRT t3 on (t1.CY = t3.CY) and (t1.SERIES_CD = T3.SERIES_CD) and (t1.PLANT_CD = T3.PLANT_CD)
      WHERE t1.TxtMY >= '2015';
QUIT;
proc sql;
create table work.pricingdatapdi as
	select t1.*,
			t2.DEALER_CD as Inventory_Dealer,
	(Case
		
			when t1.PURIFICATION_DATE  < '01Jan2018:0:0:0'dt AND 
				t1.series_cd in('7','B','J', 'S') then 159.21
			when t1.PURIFICATION_DATE  < '01Jan2018:0:0:0'dt AND 
				 t1.series_cd in('E', 'T') then 201.86
			when t1.PURIFICATION_DATE  < '01Jan2018:0:0:0'dt AND 
				 t1.series_cd not in('E', 'T', '7','B','J', 'S') then 116.56

			when t1.PURIFICATION_DATE  >= '01Jan2018:0:0:0'dt AND 
			     t1.series_cd in('7','B','J', 'S') then 164.40
			when t1.PURIFICATION_DATE >= '01Jan2018:0:0:0'dt AND 
				 t1.series_cd in('E', 'T') then 208.79
			else  120.02



	end) as PDI /*Pre Delivery Inspection*/
		
from WORK.QUERY_FOR_PRICINGDATA0 t1
LEFT JOIN SALES.QM_TD_DEALER t2 ON (t1.INVENTORY_DEALER_KEY = t2.DEALER_KEY);
quit;

PROC SQL;
   CREATE TABLE WORK.FINAL_ONE0 AS 
   SELECT t1.* ,
          
          t1.ManifestTot AS SYSTEM_MANIFEST_TOTAL, 
          /* FOB_PRICE */
/*            (t1.ACC_GROUP_COST1+t1.RFT_COST+t1.PPR_COST+t1.FOB_STD+t1.MFT_Std+t1.DutyDollar+t1.STD_INS_DATED+PDI) AS */
/*            FOB_PRICE, */

			/* EQ_FOB_PRICE */
            (t1.ACC_GROUP_COST1 + t1.FOB_STD + t1.EQ_FREIGHT + t1.EQ_DUTY + t1.EQ_PDI + t1.EQ_MINS + t1.EQ_MFT + t1.EQ_PPR) AS 
            EQ_FOB_PRICE, 

          /* DEALER_INVOICE */
            
            (t1.DEALER_COST_BASE_AMT+t1.DEALER_COST_FACTORY_ACCY_AMT+t1.DEALER_COST_PIO_ACCY_AMT+t1.FREIGHT_CHARGE_AMT)/*+t1.ADVERTISING_AMT) ?????????*/
            AS DEALER_INVOICE, 
          /* FINAL_MSRP */
            (t1.MSRP_BASE_AMT+t1.MSRP_FACTORY_ACCY_AMT+t1.MSRP_PIO_ACCY_AMT+t1.FREIGHT_CHARGE_AMT) AS FINAL_MSRP, 
          t2.* 
          
      FROM WORK.PRICINGDATApdi t1
           LEFT JOIN WORK.INCENTIVE_DATA t2 ON (t1.VIN = t2.VIN)
		;
QUIT;
data WORK.FINAL_ONE;
   set WORK.FINAL_ONE0 (drop=hmc_invoice_date PURIFICATION_DATE WHOLESALE_DATE RETAIL_SALE_DATE RDR_DATE RDR_ENTRY_DATE);
   array change _numeric_;
        do over change;
            if change=. then change=0;
		end;
	set WORK.FINAL_ONE0 (keep=hmc_invoice_date PURIFICATION_DATE WHOLESALE_DATE RETAIL_SALE_DATE RDR_DATE RDR_ENTRY_DATE);
 run ;
PROC SQL;
   CREATE TABLE WORK.ERNBCK_FLOOR AS 
   SELECT t1.VEHICLE_KEY, 
          /* SUM_of_DEALER_EARNBACK */
            (SUM(t1.DEALER_EARNBACK)) FORMAT=17.2 AS SUM_of_DEALER_EARNBACK, 
          /* SUM_of_FLOORING_ALLOWANCE */
            (SUM(t1.FLOORING_ALLOWANCE)) FORMAT=17.2 AS SUM_of_FLOORING_ALLOWANCE
      FROM SALES.QM_TH_WHOLESALE t1
      WHERE t1.WHOLESALE_DATE >= '1Jan2014:0:0:0'dt
      GROUP BY t1.VEHICLE_KEY;
QUIT;

PROC SQL;
   CREATE TABLE WORK.ADD_PIO_TO_FINAL_ONE AS 
   SELECT t1.VEHICLE_KEY, 
          t1.TxtMY, 
          t1.MODEL_CD, 
          t1.CURRENT_PORT_CD, 
          t2.ACCESSORY_CD, 
          t2.ACCESSORY_INSTALL_TYPE_CD
      FROM WORK.FINAL_ONE t1
           LEFT JOIN SALES.QM_TH_VEHICLE_ACCESSORY t2 ON (t1.SALESVK = t2.VEHICLE_KEY)
      WHERE t2.ACCESSORY_INSTALL_TYPE_CD IN 
           (
           'FLP',
           'PIO'
           );
QUIT;
/* BERAKDOWNSOSNSOSMN */

PROC SQL;
   CREATE TABLE WORK.FINAL_ONE_TOT_PIO AS 
   SELECT DISTINCT t1.VEHICLE_KEY, 
          /* PIO_Total */
            (SUM(t2.PIO_MAX)) FORMAT=NEGPAREN12.2 AS PIO_Total
      FROM WORK.ADD_PIO_TO_FINAL_ONE t1
           LEFT JOIN PROFIT.PIO t2 ON (t1.TxtMY = t2.TxtMY) AND (t1.MODEL_CD = t2.Model_Code) AND (t1.CURRENT_PORT_CD = 
          t2.Port) AND (t1.ACCESSORY_CD = t2.PIO_Code)
      GROUP BY t1.VEHICLE_KEY;
QUIT;
 
PROC SQL;
   CREATE TABLE PROFIT.FINAL_TWO AS 
   SELECT t1.* ,
   		/*	t1.DEALER_CD AS Inventory_Dealer, */
          
          t1.ManifestTot AS FOB_SYSTEM, 
          
/*          t1.PPR_COST AS PPR_COST, */
          t1.FOB_STD AS FOB_STD, 
/*          t1.MFT_Std AS MFT_Std, */
/*          t1.DutyDollar AS DUTY, */
          /* PIO */
            (ifn(t2.PIO_Total is missing, 0,t2.PIO_Total)) AS PIO, 
          
/*          t1.FOB_PRICE + (ifn(t2.PIO_Total is missing, 0,t2.PIO_Total)) AS FOB_TOTAL ,*/
		  t1.EQ_FOB_PRICE + (ifn(t2.PIO_Total is missing, 0,t2.PIO_Total)) AS EQ_FOB_TOTAL
          
      FROM WORK.FINAL_ONE t1
           LEFT JOIN WORK.FINAL_ONE_TOT_PIO t2 ON (t1.VEHICLE_KEY = t2.VEHICLE_KEY)
		  /* LEFT JOIN SALES.QM_TD_DEALER t3 ON (t1.INVENTORY_DEALER_KEY = t3.DEALER_KEY) */
      WHERE t1.DEALER_COST_BASE_AMT > 0 AND t1.SALES_YEAR IN 
           (
           2016,
           2017,
           2015,
		   2018,
			2019,
			2020
           ) AND t1.TxtMY IN 
           (
           '2016',
           '2017',
           '2015',
		   '2018',
		   '2019',
		   '2020'
           );
		   
QUIT;
PROC SQL;
   CREATE TABLE WORK.HLD_FLOOR AS 
   SELECT DISTINCT t1.VEHICLE_KEY, 
          t1.*, 
		  
          
          t1.OTHER_CHARGE_AMT AS Holdback, 
         
          /* DEALER_EARNBACK */
            (ifn(t2.SUM_of_DEALER_EARNBACK is missing,0,t2.SUM_of_DEALER_EARNBACK)) AS DEALER_EARNBACK, 
          /* FLOORING_ALLOWANCE */
            (ifn(t2.SUM_of_FLOORING_ALLOWANCE is missing, 0 , t2.SUM_of_FLOORING_ALLOWANCE)) AS FLOORING_ALLOWANCE
      FROM PROFIT.FINAL_TWO t1
           LEFT JOIN WORK.ERNBCK_FLOOR t2 ON (t1.VEHICLE_KEY = t2.VEHICLE_KEY)
      WHERE t1.DEALER_COST_BASE_AMT NOT IS MISSING /*AND t1.FOB_TOTAL NOT IS MISSING */ AND t1.HMC_INVOICE_DATE >= 
           '4Jan2013:0:0:0'dt;
QUIT;
PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_HLD_FLOOR AS 
   SELECT t1.*,
          t1.Holdback LABEL="OTHER_CHARGE_AMT", 
          
          /* HMA_FINAL_COST */
/*            (t1.FOB_STD+t1.ACC_GROUP_COST1+t1.RFT_COST+t1.PPR_COST+t1.MFT_Std+t1.DUTY+t1.STD_INS_DATED+t1.PIO+t1.PDI) */
/*            AS HMA_FINAL_COST, */
          /* DEALER_FINAL_COST */
            (CASE
            
            WHEN t1.SERIES_DESC in('G80', 'G90', 'G70') then 
            ( t1.DEALER_COST_BASE_AMT + t1.DEALER_COST_FACTORY_ACCY_AMT + t1.DEALER_COST_PIO_ACCY_AMT + 
            t1.FREIGHT_CHARGE_AMT /*+ t1.ADVERTISING_AMT*/ - t1.Holdback - t1.DEALER_EARNBACK - t1.FLOORING_ALLOWANCE)
            
            else
            ( t1.DEALER_COST_BASE_AMT + t1.DEALER_COST_FACTORY_ACCY_AMT + t1.DEALER_COST_PIO_ACCY_AMT + 
            t1.FREIGHT_CHARGE_AMT  /* + t1.ADVERTISING_AMT*/ - t1.Holdback - t1.DEALER_EARNBACK - t1.FLOORING_ALLOWANCE)
            end) AS DEALER_FINAL_COST

      FROM WORK.HLD_FLOOR t1;
QUIT;
PROC SQL;
   CREATE TABLE PROFIT.FINAL_FINAL AS 
   SELECT t1.*, 
   		t2.SALES_DAY_OF_MONTH,
		t2.IS_SALES_MONTH_END,
          
          /* GROSS_MARGIN */
/*            (t1.DEALER_FINAL_COST-t1.HMA_FINAL_COST) AS GROSS_MARGIN, */
          /* NET_MARGIN */
/*            (t1.DEALER_FINAL_COST-t1.HMA_FINAL_COST-t1.TotalIncentives) AS NET_MARGIN, */
          /* IS_NET_NEG */
/*            (ifn((t1.DEALER_FINAL_COST-t1.HMA_FINAL_COST-t1.TotalIncentives)>0,0,1)) AS IS_NET_NEG, */

			/* EQ_GROSS_MARGIN */
           /* (t1.DEALER_FINAL_COST-t1.EQ_FOB_PRICE) AS EQ_GROSS_MARGIN, */
          /* NET_MARGIN */
            (t1.DEALER_FINAL_COST-t1.EQ_FOB_PRICE-t1.TotalIncentives) AS EQ_NET_MARGIN, 
          /* IS_NET_NEG */
            (ifn((t1.DEALER_FINAL_COST-t1.EQ_FOB_PRICE-t1.TotalIncentives)>0,0,1)) AS EQ_IS_NET_NEG 
          /* FOB_DIFF */
       /*     (t1.FOB_SYSTEM-t1.HMA_FINAL_COST) AS FOB_DIFF*/
      FROM WORK.QUERY_FOR_HLD_FLOOR t1 
		LEFT JOIN SALES.QM_TD_DATE t2 ON (t1.RDR_ENTRY_DATE = t2.CALENDAR_DATE);
QUIT;
DATA HMASAS.FINAL_FINAL (drop=Dealer_Key Inventory_dealer_key);
SET PROFIT.FINAL_FINAL;
	EQ_FOB_BASE = (ACC_GROUP_COST1 + FOB_STD + EQ_DUTY + EQ_PDI + EQ_MINS + EQ_MFT + EQ_PPR) ;
	EQ_DLR_BASE = (DEALER_COST_BASE_AMT + DEALER_COST_FACTORY_ACCY_AMT - Holdback - DEALER_EARNBACK 
	- FLOORING_ALLOWANCE + (MSRP_PIO_ACCY_AMT*.04) -14 ); /* 1% for Floor, 3% Holdback $14 for Hope on Wheels*/

	EQ_BASE_MSRP = MSRP_BASE_AMT + MSRP_FACTORY_ACCY_AMT;
	EQ_BASE_DLR_PROF = EQ_BASE_MSRP - EQ_DLR_BASE; 

    EQ_BASE_MAR = EQ_DLR_BASE - EQ_FOB_BASE;

	EQ_PIO_MAR = (DEALER_COST_PIO_ACCY_AMT - (MSRP_PIO_ACCY_AMT*.04) - PIO ); /* 1% for Floor, 3% Holdback */
	EQ_FRT_MAR = (FREIGHT_CHARGE_AMT - EQ_FREIGHT);

	EQ_GROSS_MARGIN = EQ_BASE_MAR + EQ_PIO_MAR + EQ_FRT_MAR;
	EQ_NET_MAR = EQ_GROSS_MARGIN - TotalIncentives;

/*if LEASE >= 1 Then */
/*	LEASE = (LEASE + ((FINAL_MSRP *.04)*.65));*/
/*	else*/
/*	LEASE = 0;*/
/*            */

RUN;
Quit;
DATA main.FINAL_FINAL (drop=Dealer_Key Inventory_dealer_key);
SET PROFIT.FINAL_FINAL;
EQ_FOB_BASE = (ACC_GROUP_COST1 + FOB_STD + EQ_DUTY + EQ_PDI + EQ_MINS + EQ_MFT + EQ_PPR) ;
/*		EQ_FOB_BASE = (ACC_GROUP_COST1 + FOB_STD + EQ_DUTY + EQ_PDI + EQ_MINS + EQ_MFT + EQ_PPR) ;*/
	EQ_DLR_BASE = (DEALER_COST_BASE_AMT + DEALER_COST_FACTORY_ACCY_AMT - Holdback - DEALER_EARNBACK 
	- FLOORING_ALLOWANCE + (MSRP_PIO_ACCY_AMT*.04) -14 ); /* 1% for Floor, 3% Holdback $14 for Hope on Wheels*/

	EQ_BASE_MSRP = MSRP_BASE_AMT + MSRP_FACTORY_ACCY_AMT;
	EQ_BASE_DLR_PROF = EQ_BASE_MSRP - EQ_DLR_BASE; 

    EQ_BASE_MAR = EQ_DLR_BASE - EQ_FOB_BASE;

	EQ_PIO_MAR = (DEALER_COST_PIO_ACCY_AMT - (MSRP_PIO_ACCY_AMT*.04) - PIO ); /* 1% for Floor, 3% Holdback */
	EQ_FRT_MAR = (FREIGHT_CHARGE_AMT - EQ_FREIGHT);

	EQ_GROSS_MARGIN = EQ_BASE_MAR + EQ_PIO_MAR + EQ_FRT_MAR;
	EQ_NET_MAR = EQ_GROSS_MARGIN - TotalIncentives;

/*if LEASE >= 1 Then */
/*	LEASE = (LEASE + ((FINAL_MSRP *.04)*.65));*/
/*	else*/
/*	LEASE = 0;*/

RUN;
Quit;
/*PULL IN HMFBC INDICATOR*/

PROC SQL;
   CREATE TABLE WORK.HMFBC AS 
   SELECT t1.VEHICLE_KEY AS IDMVK, 
          t2.PROGRAM_TYPE_DESC
          
      FROM INCENT.IDM_TH_HMF_RETAIL_BOOKING t1
           INNER JOIN INCENT.IDM_TD_INCENTIVE_PROGRAM t2 ON (t1.INCENTIVE_PROGRAM_KEY = t2.INCENTIVE_PROGRAM_KEY)
      WHERE t1.IS_REBOOK = 0 AND t1.HCA_BONUS_CASH_PAY_TO_DLR_AMT NOT IN(0, 400) AND t1.NEW_USED_CAR_CONTRACT_CD IN 
           (
           'Y',
           'D'
           ) AND t2.PROGRAM_TYPE_DESC = 'Standard APR' AND t1.VEHICLE_KEY > 1;
QUIT;
proc sort data=work.hmfbc nodup;
by IDMVK;
run;
/*data work.hmfbcDUP;
set work.HMFBC;
by IDMVK;
if first.IDMVK then fir_IDM = 1;
else fir_IDM = 0;
run;*/

PROC SQL;
   CREATE TABLE PROFIT.FINAL_FINAL_FINAL0 AS 
   SELECT t1.*,
		  t1.MODEL_YEAR, 
          t3.SERIES_CD, 
          t3.MODEL_CD, 
          t3.EXTERIOR_COLOR_CD, 
          t3.INTERIOR_COLOR_CD, 
          t3.COLOR_CD, 
          t3.ACCESSORY_GROUP_CD, 
          t2.CURRENT_PORT_CD, 
          t2.CURRENT_REGION_CD, 
          t2.HMC_INVOICE_DATE, 
          t2.PURIFICATION_DATE, 
          t2.WHOLESALE_DATE, 
          t2.RETAIL_SALE_DATE, 
          t2.RDR_DATE, 
          t2.INVENTORY_STATUS_CD 
          
      FROM WORK.FINAL_ONE t1, SALES.QM_TH_VEHICLE_STATUS t2, SALES.QM_TH_VEHICLE t3
      WHERE (t1.VEHICLE_KEY = t2.VEHICLE_KEY AND t1.VEHICLE_KEY = t3.VEHICLE_KEY) AND (t2.IS_NATIONAL_FLEET NOT = 1 OR 
           t2.IS_RDR_FLEET NOT = 1);
QUIT;
PROC SQL;
   CREATE TABLE WORK.FINAL_FINAL_FINAL_0_1 AS 
   SELECT 
   			t1.*,
          /* IS_HMFStdBC */
            (ifn(t2.PROGRAM_TYPE_DESC='Standard APR',1,0)) AS IS_HMFStdBC
      FROM PROFIT.FINAL_FINAL_FINAL0 t1
           LEFT JOIN WORK.HMFBC t2 ON (t1.IDMVK = t2.IDMVK);
QUIT;
/* BEGIN ADDING MORE VEHICLE INFO */ 
%_eg_conditional_dropds(WORK.FINAL_FINAL_FINAL_0_0_1);
%_eg_conditional_dropds(WORK.QUERY_FOR_QM_TH_VEHICLE);

PROC SQL;
   CREATE TABLE WORK.colors AS 
   SELECT t1.VEHICLE_KEY, 
          t2.GENERIC_COLOR_DESC
      FROM SALES.QM_TH_VEHICLE t1
           LEFT JOIN SALES.QM_TD_COLOR t2 ON (t1.COLOR_KEY = t2.COLOR_KEY) AND (t1.PLANT_CD = t2.PLANT_CD) AND 
          (t1.MODEL_YEAR = t2.MODEL_YEAR) AND (t1.MODEL_CD = t2.MODEL_CD) AND (t1.SERIES_CD = t2.SERIES_CD)  
/*          AND (t1.FAMILY_CD = t2.FAMILY_CD) AND (t1.DOOR_CD = t2.DOOR_CD) AND (t1.TRIM_CD = t2.TRIM_CD) AND */
/*          (t1.MFG_EXTERIOR_COLOR_CD = t2.MFG_EXTERIOR_COLOR_CD) AND (t1.MFG_INTERIOR_COLOR_CD = */
/*          t2.MFG_INTERIOR_COLOR_CD) AND (t1.EXTERIOR_COLOR_CD = t2.EXTERIOR_COLOR_CD) AND (t1.INTERIOR_COLOR_CD = */
/*          t2.INTERIOR_COLOR_CD)*/
      WHERE t2.MODEL_YEAR >= 2014;
QUIT;
PROC SQL;
   CREATE TABLE WORK.FINAL_FINAL_FINAL_0_0_1 AS 
   SELECT t1.*,
          t2.GENERIC_COLOR_DESC, 
          
          t3.IS_SALES_MONTH_END, 
          t3.SALES_DAY_OF_MONTH
      FROM WORK.FINAL_FINAL_FINAL_0_1 t1
           
           LEFT JOIN SALES.QM_TD_SITE t4 ON (t1.Inventory_dealer = t4.DEALER_CD)
           LEFT JOIN SALES.QM_TD_DATE t3 ON (t1.RETAIL_SALE_DATE = t3.CALENDAR_DATE)
		   LEFT JOIN WORK.COLORS t2 on (t1.vehicle_key = t2.vehicle_key);
QUIT;


PROC SQL;
   CREATE TABLE WORK.FINAL_FINAL_FINAL_0_0_2 AS 
   SELECT DISTINCT t1.VEHICLE_KEY, 
          t1.* ,
          
          t2.HORSEPOWER, 
          t2.ENGINE_DESC, 
          t2.MODEL_EMISSION_DESC, 
          t2.NUMBER_OF_CYLINDERS, 
          t2.DOOR_DESC, 
          t2.ENGINE_TYPE_DESC
      FROM WORK.FINAL_FINAL_FINAL_0_0_1 t1
           LEFT JOIN SALES.QM_TD_MODEL t2 ON (t1.MODEL_YEAR = t2.MODEL_YEAR) AND (t1.MODEL_CD = t2.MODEL_CD) AND 
          (t1.SERIES_CD = t2.SERIES_CD) AND (t1.PLANT_CD = t2.PLANT_CD);
QUIT;



PROC SQL;
   CREATE TABLE PROFIT.FINAL_FINAL_FINAL AS 
   SELECT t1.*,
/*          t2.DUTY, */
/*          t2.PIO, */
/*          t2.FOB_TOTAL, */
          /*t2.SUM_of_DEALER_EARNBACK, 
          t2.SUM_of_FLOORING_ALLOWANCE, */
          t2.Holdback, 
          t2.DEALER_EARNBACK, 
          t2.FLOORING_ALLOWANCE, 
 /*         t2.HMA_FINAL_COST, */
/*		  t3.SALES_DAY_OF_MONTH,*/
/*		  t3.IS_SALES_MONTH_END,*/
          t2.DEALER_FINAL_COST
      FROM WORK.FINAL_FINAL_FINAL_0_0_2 t1
           LEFT JOIN WORK.QUERY_FOR_HLD_FLOOR t2 ON (t1.VEHICLE_KEY = t2.VEHICLE_KEY)
		  /* LEFT JOIN SALES.QM_TD_DATE t3 ON  (t1.RDR_ENTRY_DATE = t3.CALENDAR_DATE)*/
; 
QUIT;
/*This produces the Sales Objective Table for the Optimization Process*/



DATA HMASAS.FINAL_FINAL_FINAL (drop=Dealer_Key Inventory_dealer_key) ;
SET PROFIT.FINAL_FINAL_FINAL;
/*		if LEASE >= 1 Then */
/*	LEASE = (LEASE + ((FINAL_MSRP *.035)*.65));*/
/*	else*/
/*	LEASE = 0;*/


RUN;
Quit;
DATA main.FINAL_FINAL_FINAL (drop=Dealer_Key Inventory_dealer_key) ;
SET PROFIT.FINAL_FINAL_FINAL;
/*			if LEASE >= 1 Then */
/*	LEASE = (LEASE + ((FINAL_MSRP *.035)*.65));*/
/*	else*/
/*	LEASE = 0;*/
	MODEL_YEAR = input(TxtMY, 4.);

RUN;
Quit;

/*data hmasas.historical_incentives;*/
/*set wjsas.incentives_database;*/
/*run;*/
/*data main.historical_incentives;*/
/*set wjsas.incentives_database;*/
/*run;*/
/*data hmasas.coopspend;*/
/*set sales.dw_vh_dealer_sales_coop_allow;*/
/*run;*/
/*data main.coopspend;*/
/*set sales.dw_vh_dealer_sales_coop_allow;*/
/*run;*/

/*PROC SQL;*/
/*   CREATE TABLE HMASAS.DLR_GEO AS */
/*   SELECT t1.D_DEALER_ID, */
/*   			t2.REGION_CD,	*/
/*          t2.ADI_CD, */
/*          t2.ADI_DESC, */
/*          t1.DEALER_CD, */
/*          /* LAT */
/*            max((input(t1.GEO_LATITUDE,Best20.20))) AS LAT, */
/*          /* LON */
/*            max((input(t1.GEO_LONGITUDE,best20.20))) AS LON*/
/*      FROM PRO_MDM.D_DEALER_CONTACT t1*/
/*           INNER JOIN SALES.QM_TD_DEALER t2 ON (t1.DEALER_CD = t2.DEALER_CD)*/
/*      WHERE t1.GEO_LATITUDE NOT IS MISSING;*/
/*QUIT;*/
/*PROC SQL;*/
/*   CREATE TABLE main.DLR_GEO AS */
/*   SELECT t1.D_DEALER_ID, */
/*   			t2.REGION_CD,	*/
/*          t2.ADI_CD, */
/*          t2.ADI_DESC, */
/*          t1.DEALER_CD, */
/*          /* LAT */
/*            (input(t1.GEO_LATITUDE,Best20.20)) AS LAT, */
/*          /* LON */
/*            (input(t1.GEO_LONGITUDE,best20.20)) AS LON*/
/*      FROM PRO_MDM.D_DEALER_CONTACT t1*/
/*           INNER JOIN SALES.QM_TD_DEALER t2 ON (t1.DEALER_CD = t2.DEALER_CD)*/
/*      WHERE t1.GEO_LATITUDE NOT IS MISSING;*/
/*QUIT;*/


PROC SQL;
   CREATE TABLE WORK.ADDLC AS 
   SELECT DISTINCT t2.VIN, 
          t1.CONTRACT_BOOKING_DATE_KEY, 
          t1.LEASE_CASH_AMT
      FROM INCENT.IDM_TH_HMF_LEASE_BOOKING t1
           INNER JOIN INCENT.IDM_TH_VEHICLE t2 ON (t1.VEHICLE_KEY = t2.VEHICLE_KEY);
QUIT;
proc sort data=work.addlc nodup;
by vin contract_booking_date_key;
run;
data firstlc;
set addlc;
by vin contract_booking_date_key;
if last.contract_booking_date_key then lastlc = 1;
else lastlc = 0;
run;
data secondlc;
set firstlc;
where lastlc = 1;
run;


PROC SQL;
   CREATE TABLE WORK.FINFINLC AS 
   SELECT t1.*, 
          
          /* LeaseCash */
            (ifn(t1.LEASE>0,t2.LEASE_CASH_AMT,0)) AS LeaseCash
      FROM HMASAS.FINAL_FINAL_FINAL t1
           LEFT JOIN WORK.SECONDLC t2 ON (t1.VIN = t2.VIN);
QUIT;

data hmasas.final_final_final;
set work.finfinlc;
run;
data main.final_final_final;
set work.finfinlc;
run;
Quit;
%_eg_conditional_dropds(WORK.FINFINLC);
%_eg_conditional_dropds(WORK.firstlc);
%_eg_conditional_dropds(WORK.ork.addlc);
%_eg_conditional_dropds(WORK.secondlc);
%_eg_conditional_dropds(WORK.FINAL_FINAL_FINAL_0_0_2);
%_eg_conditional_dropds(WORK.FINAL_FINAL_FINAL_0_0_1);
%_eg_conditional_dropds(WORK.FINAL_FINAL_FINAL_0_1);
%_eg_conditional_dropds(WORK.WORK.HMFBC);
%_eg_conditional_dropds(WORK.QUERY_FOR_HLD_FLOOR);
%_eg_conditional_dropds(WORK.HLD_FLOOR);
%_eg_conditional_dropds(WORK.ADD_PIO_TO_FINAL_ONE);
%_eg_conditional_dropds(WORK.ERNBCK_FLOOR);
%_eg_conditional_dropds(WORK.FINAL_ONE);
%_eg_conditional_dropds(WORK.WORK.FINAL_ONE0);
%_eg_conditional_dropds(WORK.FINAL_ONE_TOT_PIO);
%_eg_conditional_dropds(WORK.QUERY_FOR_PRICINGDATA0);
%_eg_conditional_dropds(WORK.Pricing_Draft);
%_eg_conditional_dropds(WORK.SalesbyAccGroupCost);
%_eg_conditional_dropds(WORK.ByGroupCode);
%_eg_conditional_dropds(WORK.SYS_ACC_CODE);

