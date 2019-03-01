%include "/sashome/prod/HMA03468/voc_coc.sas";




options validvarname = ANY;
PROC SQL;
	CREATE TABLE WORK.LEASE AS 
		SELECT t1.VEHICLE_KEY AS VK, 
			/*t1.DEALER_KEY AS DK, */
	t1.CONTRACT_BOOKING_DATE_KEY AS ConDate, 
	/* TYPE */

	("LEASE") AS TYPE, /* CustPayment */
	(t1.MONTHLY_PAYMENT_AMT) AS CustPayment,  
	t1.MONEY_FACTOR_SUBVENTION_AMT+t1.LEASE_CASH_AMT+(
			(CASE
					WHEN t1.CONTRACT_BOOKING_DATE_KEY BETWEEN 20180103 AND 20181006 THEN t1.MSRP *.04 * .65
					else (t1.MSRP * (RESIDUAL_VALUE_ENHANCEMENT_PCT)/100)*.63
			END)) AS INCENTIVEAMT,
	t2.SALES_MONTH,
	t2.SALES_YEAR,
	(1) as COUNTER 
	FROM INCENT.IDM_TH_HMF_LEASE_BOOKING t1 INNER JOIN INCENT.IDM_TD_DATE t2 ON (t1.CONTRACT_BOOKING_DATE_KEY = t2.DATE_KEY) WHERE t2.SALES_YEAR >= 2014;
QUIT;
/*PROC SQL;*/
/*	CREATE TABLE WORK.LEASE AS */
/*		SELECT t1.VEHICLE_KEY AS VK, */
/*			/*t1.DEALER_KEY AS DK, */*/
/*	t1.CONTRACT_BOOKING_DATE_KEY AS ConDate, */
/*	/* TYPE */*/
/**/
/*	("LEASE") AS TYPE, /* CustPayment */*/
/*	(t1.MONTHLY_PAYMENT_AMT) AS CustPayment,  t1.MONEY_FACTOR_SUBVENTION_AMT+t1.LEASE_CASH_AMT+(t1.HMA_RESIDUAL_ENHANCEMENT_AMT*.60) AS INCENTIVEAMT, t2.SALES_MONTH, t2.SALES_YEAR, (1) as COUNTER */
/*	FROM INCENT.IDM_TH_HMF_LEASE_BOOKING t1 INNER JOIN INCENT.IDM_TD_DATE t2 ON (t1.CONTRACT_BOOKING_DATE_KEY = t2.DATE_KEY) WHERE t2.SALES_YEAR >= 2014;*/
/*QUIT;*/
*’; *”; */;

PROC SQL;
	CREATE TABLE WORK.RETAIL AS 
		SELECT DISTINCT t1.VEHICLE_KEY AS VK, 
			/*t1.DEALER_KEY AS DK, */
	t1.CONTRACT_BOOKING_DATE_KEY AS ConDate, 
	/* TYPE */
	("RETAIL") AS TYPE, t1.CUST_MONTHLY_PAYMENT_AMT AS CustPayment, t1.HMA_RATE_SUBVENTION_AMT+t1.HCA_BONUS_CASH_PAY_TO_DLR_AMT AS INCENTIVEAMT, t2.SALES_MONTH, t2.SALES_YEAR, (1) as COUNTER 
FROM INCENT.IDM_TH_HMF_RETAIL_BOOKING t1 INNER JOIN INCENT.IDM_TD_DATE t2 ON (t1.CONTRACT_BOOKING_DATE_KEY = t2.DATE_KEY) WHERE t2.SALES_YEAR >= 2014 AND t1.NEW_USED_CAR_CONTRACT_CD IN ( 'Y', 'D' );
QUIT;

proc sql;
	create table work.coll_lse as 
		select t1.vehicle_key as vk,
			("COLL_GRAD") AS TYPE, 
			t1.college_grad_rebate_amt as INCENTIVEAMT

		FROM INCENT.IDM_TH_HMF_LEASE_BOOKING t1
			where t1.college_grad_rebate_amt > 1;
QUIT;

proc sql;
	create table work.coll_rtl as 
		select t1.vehicle_key as vk,
			("COLL_GRAD") AS TYPE, 
			t1.college_grad_rebate_amt as INCENTIVEAMT

		FROM INCENT.IDM_TH_HMF_RETAIL_BOOKING t1
			where t1.college_grad_rebate_amt > 1;
QUIT;

PROC SQL;
	CREATE TABLE WJSAS.ALLRDRS AS 
		SELECT t1.VEHICLE_KEY AS vk, 
			t1.DEALER_KEY, 	
			t1.RDR_ENTRY_DATE AS RDRDATE, 
			t1.RDR_TYPE, 
			/* SALES */
	(SUM(ifn(t1.RDR_TYPE = 'RDR',1,-1))) AS SALES, 
	t2.SALES_YEAR, 
	t2.SALES_MONTH, 
	t1.vin 
	FROM INCENT.IDM_TH_RDR t1, INCENT.IDM_TD_DATE t2, INCENT.IDM_TD_INCENTIVE_SALE_TYPE t3 
	WHERE (t1.RDR_DATE_KEY = t2.DATE_KEY AND t1.INCENTIVE_SALE_TYPE_KEY = t3.INCENTIVE_SALE_TYPE_KEY) AND (t1.RDR_ENTRY_DATE >= '1Nov2012:0:0:0'dt AND t1.INCENTIVE_SALE_TYPE_KEY NOT IN ( 9, 15, 16, 14, 13, )) GROUP BY t1.VEHICLE_KEY, t1.RDR_ENTRY_DATE, t1.RDR_TYPE, t2.SALES_YEAR, t2.SALES_MONTH, t1.vin;
QUIT;

data _null_ (keep=vk vin);
	set wjsas.allrdrs;
run;

proc sort data=wjsas.allrdrs (keep=vk vin) nodupkey out=work.convert1;
	by vk;
run;

proc sort data=work.retail;
	by vk condate;
run;

data work.retail2;
	set work.retail;
	by vk condate;

	if last.vk then
		lastcon = 1;
	else lastcon = 0;
	where vk > 1;
run;

proc sort data=work.lease;
	by vk condate;
run;

data work.lease2;
	set work.lease;
	by vk condate;

	if last.vk then
		lastcon = 1;
	else lastcon = 0;
	where vk > 1;
run;

PROC SQL;
	CREATE TABLE WJSAS.IDMCONVERT AS 
		SELECT t1.vk AS IDMVK, 
			t2.VEHICLE_KEY AS SALESVK,
			t1.VIN,
			t2.Model_year,
			t2.SERIES_CD
		FROM WORK.CONVERT1 t1
			INNER JOIN SALES.QM_TH_VEHICLE t2 ON (t1.VIN = t2.VIN);
QUIT;

PROC SQL;
	CREATE TABLE WORK.ALLHMF AS 
		SELECT * FROM WORK.LEASE2
			OUTER UNION CORR 
				SELECT * FROM WORK.RETAIL2
	;
Quit;

PROC SQL;
	CREATE TABLE WORK.collgrad AS 
		SELECT * FROM WORK.coll_lse
			OUTER UNION CORR 
				SELECT * FROM WORK.coll_rtl
	;
Quit;

proc sort data=work.collgrad NODUPKEY out=WORK.ALLCOLL;;
	by vk;
run;

proc sort data=WORK.ALLHMF NODUPKEY out=WORK.HMFNODUP;
	by vk conDate;
	where vk <> -1;
	where lastcon = 1;
run;

PROC SQL;
	CREATE TABLE WJSAS.SALESSAMPLE AS 
		SELECT t1.vk, 
			/* SALES */
	(SUM(t1.SALES)) AS SALES FROM WJSAS.ALLRDRS t1 WHERE t1.SALES_YEAR >= 2010 GROUP BY t1.vk;
QUIT;

PROC SQL;
	CREATE TABLE WORK.HMAPMTS AS 
		SELECT t1.vk, 
			t3.PROGRAM_TYPE_DESC AS TYPE, 
			/* INCENTIVEAMT */
	(SUM(t2.TOTAL_PAYMENT_AMT + TOTAL_CHARGEBACK_AMT)) AS INCENTIVEAMT, (1) as COUNTER 
     FROM WJSAS.SALESSAMPLE t1 LEFT JOIN INCENT.IDM_TF_INCENTIVE_PAYMENT_STMNT t2 ON (t1.vk = t2.VEHICLE_KEY) 
	LEFT JOIN INCENT.IDM_TD_INCENTIVE_PROGRAM t3 ON (t2.INCENTIVE_PROGRAM_KEY = t3.INCENTIVE_PROGRAM_KEY) 
	GROUP BY t1.vk, t3.PROGRAM_TYPE_DESC;
QUIT;
/***************************


PROC SQL;
	CREATE TABLE WORK.HMAPMTS AS 
		SELECT t1.vk, 
			t3.PROGRAM_TYPE_DESC AS TYPE, 
			t2.INCENTIVE_PROGRAM_KEY,
			/* INCENTIVEAMT */
	/*(SUM(t2.TOTAL_PAYMENT_AMT + TOTAL_CHARGEBACK_AMT)) AS INCENTIVEAMT, (1) as COUNTER 
     FROM WJSAS.SALESSAMPLE t1 LEFT JOIN INCENT.IDM_TF_INCENTIVE_PAYMENT_STMNT t2 ON (t1.vk = t2.VEHICLE_KEY) 
	LEFT  JOIN INCENT.IDM_TD_INCENTIVE_PROGRAM t3 ON (t2.INCENTIVE_PROGRAM_KEY = t3.INCENTIVE_PROGRAM_KEY) 
	GROUP BY t1.vk, t3.PROGRAM_TYPE_DESC;
QUIT;

****************************/




PROC SQL;
	CREATE TABLE WJSAS.VOLUME AS 
		SELECT 
			t2.rdr_date_key,  
			t3.PROGRAM_TYPE_DESC AS TYPE,
			t4.MODEL_YEAR,
			t4.series_desc, 
			t4.series_cd,
			/* INCENTIVEAMT */
			SUM(t2.TOTAL_PAYMENT_AMT + TOTAL_CHARGEBACK_AMT) AS INCENTIVEAMT
			/*COUNT(t1.vk) as PGMCount*/
	FROM WJSAS.SALESSAMPLE t1
		LEFT JOIN INCENT.IDM_TF_INCENTIVE_PAYMENT_STMNT t2 ON (t1.vk = t2.VEHICLE_KEY)
			LEFT JOIN INCENT.IDM_TD_INCENTIVE_PROGRAM t3 ON (t2.INCENTIVE_PROGRAM_KEY = t3.INCENTIVE_PROGRAM_KEY)
			LEFT JOIN INCENT.IDM_TH_VEHICLE t4 on (t1.vk = t4.VEHICLE_KEY)
				GROUP BY t2.rdr_date_key,
					t3.PROGRAM_TYPE_DESC,
					t4.MODEL_YEAR,
					t4.series_desc ,
					t4.series_cd
	;
QUIT;

PROC SQL;
	CREATE TABLE WJSAS.INCENTYPEVOLUME AS 
		SELECT  
			t2.SALES_YEAR, 
			t2.SALES_MONTH,
			t1.TYPE, 
			t1.MODEL_YEAR, 
			t1.SERIES_DESC, 
			t1.SERIES_CD,
			/*sum(t1.PGMCount) as ProgCount,*/
			sum(t1.Incentiveamt) as Incentiveamt

		FROM WJSAS.VOLUME t1
			INNER JOIN INCENT.IDM_TD_DATE t2 ON (t1.RDR_DATE_KEY = t2.DATE_KEY)
				GROUP BY          
					t2.SALES_YEAR, 
					t2.SALES_MONTH,
					t1.TYPE, 
					t1.MODEL_YEAR, 
					t1.SERIES_DESC,
					t1.SERIES_CD;
QUIT;

data IncentivesbyType (keep=vk type incentiveamt);
	set work.hmfnodup;
run;

data TotalbyVin (drop= type);
	set work.IncentivesbyType;
	where incentiveamt = sum(incentiveamt);
run;

proc sort data = totalbyvin;
	by descending incentiveamt;
run;

data hmf0 (keep=vk type incentiveamt);
	set work.hmfnodup;
	format type $char40.;
run;

data hma1 (keep=vk type incentiveamt);
	set work.hmapmts;
run;

PROC SQL;
	CREATE TABLE work.hmf1 AS 
		SELECT * FROM work.hmf0
			OUTER UNION CORR 
				SELECT * FROM work.allcoll
	;
Quit;

PROC SQL;
	CREATE TABLE WJSAS.ALLINCENT AS 
		SELECT * FROM work.hmf1
			OUTER UNION CORR 
				SELECT * FROM work.hma1
	;
Quit;

PROC SQL;
	CREATE TABLE WJSAS.INCENTTOTAL AS 
		SELECT t1.VK, 
			/* TotalIncentives */
	(SUM(t1.INCENTIVEAMT)) FORMAT=17.2 AS TotalIncentives FROM WJSAS.ALLINCENT t1 GROUP BY t1.VK;
QUIT;

proc sort data = wjsas.allincent;
	by descending vk;
run;

proc sort data=wjsas.allincent out=allincent_sorted;
	by vk type;
run;

proc transpose data=work.allincent_sorted out=wjsas.allincent_trans
	name=column_that_was_transposed;
	by vk;
	id type;
run;

PROC SQL;
	CREATE TABLE WJSAS.SALES AS 
		SELECT t1.RDR_ENTRY_DATE AS RDRDATE, 
			/* Sales */
	(SUM(ifn(t1.RDR_TYPE='RDR',1,-1))) AS Sales FROM INCENT.IDM_TH_RDR t1 WHERE t1.RDR_ENTRY_DATE >= '1Nov2012:0:0:0'dt 
		AND t1.INCENTIVE_SALE_TYPE_KEY NOT IN ( 9, 15, 16, 14, 13 ) 
	GROUP BY t1.RDR_ENTRY_DATE;
QUIT;

/*PROC SQL;
  CREATE TABLE WJSAS.SALESBYYRMODEL AS 
  SELECT t1.SALES_MONTH_KEY AS SALEMO,
         t2.MODEL_YEAR, 
         t2.SERIES_DESC, 
/* SALES */

/*         (SUM(ifn(t1.RDR_TYPE='RDR',1,-1))) AS Sales
  FROM INCENT.IDM_TH_RDR t1
       INNER JOIN INCENT.IDM_TH_VEHICLE t2 ON (t1.VEHICLE_KEY = t2.VEHICLE_KEY)
WHERE t1.RDR_ENTRY_DATE >= '1Nov2009:0:0:0'dt AND t1.INCENTIVE_SALE_TYPE_KEY NOT IN 
       (
       9,
       15,
       16,
       14,
       13
       )
  
  GROUP BY t1.SALES_MONTH_KEY,
           t2.MODEL_YEAR,
           t2.SERIES_DESC;
QUIT;*/
PROC SQL;
	CREATE TABLE WORK.SALES_SQUISH AS 
		SELECT t1.VEHICLE_KEY, 
			t1.RDR_ENTRY_DATE, 
			t1.RDR_SEQUENCE, 
			t1.DEALER_KEY
		FROM INCENT.IDM_TH_RDR t1
			WHERE t1.RDR_ENTRY_DATE >= '1Nov2012:0:0:0'dt AND t1.RDR_TYPE = 'RDR'
				ORDER BY t1.VEHICLE_KEY,
					t1.RDR_ENTRY_DATE,
					t1.RDR_SEQUENCE,
					t1.DEALER_KEY;
QUIT;

data work.lastsale;
	set work.sales_squish;
	by vehicle_key rdr_entry_date rdr_sequence;

	if last.vehicle_key then
		soldcount = 1;
	else soldcount = 0;
run;

data wjsas.sold_dates (drop=rdr_sequence);
	set lastsale;
	where soldcount = 1;
run;

PROC SQL;
	CREATE TABLE WJSAS.INCENT_TRANS_VK AS 
		SELECT *
			FROM WJSAS.ALLINCENT_TRANS t1
				LEFT JOIN WJSAS.SOLD_DATES t2 ON (t1.VK = t2.VEHICLE_KEY);
QUIT;

PROC SQL;
	CREATE TABLE WORK.INCENTDB0 AS 
		SELECT t1.*, 
			t4.TotalIncentives,
			t2.MODEL_YEAR, 
			t2.SERIES_CD, 
			t2.SERIES_DESC,
			t2.vin, 
			t3.SALES_YEAR, 
			t3.SALES_MONTH

		FROM WJSAS.INCENT_TRANS_VK t1, INCENT.IDM_TH_VEHICLE t2, INCENT.IDM_TD_DATE t3, WJSAS.INCENTTOTAL t4
			WHERE (t1.VEHICLE_KEY = t2.VEHICLE_KEY AND t1.RDR_ENTRY_DATE = t3.CALENDAR_DATE AND t4.VK = t1.VEHICLE_KEY);
QUIT;

data work.incentdb1 (drop= column_that_was_transposed _LABEL_);
	set work.INCENTDB0;
run;

PROC SQL;
	CREATE TABLE work.incentives_database0 AS 
		SELECT t1.*,
			t2.DEALER_CD, 
			t2.REGION_CD, 
			t2.ADI_DESC, 
			t2.ADI_CD, 
			t2.SHOWROOM_STATE_CD 

		FROM work.incentdb1 t1
			INNER JOIN INCENT.IDM_TD_DEALER t2 ON (t1.DEALER_KEY = t2.DEALER_KEY)
	;
QUIT;

data wjsas.incentives_database;
	set work.incentives_database0;
	rename 'Base Star'N = BaseSTAR;
	rename	'Dealer Cash'N = DealerCash;
		rename	'Autoshow Rebate'N = Autoshow;
		rename	'star contribution'n =STARContrib;
		rename 'Star Bonus'n=STARBonus;
		rename 'Trade-In'n=TradeIn;
		rename 'Final Pay'n=FinalPay;
		rename 'Special Event'n=SpecEvent;
		rename 'Flex Cash - Redeem'n=FlexCash;
		rename 'Special Promotion'n=SpecPromo;
		rename 'Retail Bonus Cash'n=RBC;
		rename 'Disaster Relief'n=Disaster;
		rename 'Aged VIN'n = AgedVIN;
		rename 'Dealer Commercial Fleet'n = DealerCommFleet;
		rename 'Regional Dealer Cash'n=RegionalDC;
		rename 'Circle A'n = Circle_A;
		rename 'Circle DEPP'n = Circle_DEPP;
		rename 'Circle E'n = Circle_E;
		rename 'Circle M'n = Circle_M;
		rename 'Circle O'n = Circle_O;
		rename 'Circle V'n = Circle_V;
		rename 'Circle B'n = Circle_B;
		rename 'Circle W'n = Circle_W;
		rename 'Boost Up'n = Boost;
		rename 'Final Pay X'n = FinalPay_X;
		rename 'Circle K'n = Circle_K;
		rename 'Lease Coupon'n = Lease_Coupon;
		rename 'Dealer Performance Bonus'n = DPB;
		rename 'SRC-CPO'n = SRC_CPO;
	;
run;

/*data wjsas.Incentives_database;
  set wjsas.Incentives_database;
  array change _numeric_;
       do over change;
           if change=. then change=0;
       end;
run ;*/
PROC SQL;
	CREATE TABLE WORK.SALES_SQUISH_ACT AS 
		SELECT t1.VEHICLE_KEY, 
			t1.PURCHASE_DATE, 
			t1.RDR_SEQUENCE, 
			t1.DEALER_KEY
		FROM INCENT.IDM_TH_RDR t1
			WHERE t1.RDR_ENTRY_DATE >= '1Nov2012:0:0:0'dt AND t1.RDR_TYPE = 'RDR'
				ORDER BY t1.VEHICLE_KEY,
					t1.PURCHASE_DATE,
					t1.RDR_SEQUENCE,
					t1.DEALER_KEY;
QUIT;

data work.lastsale_ACT;
	set work.sales_squish_ACT;
	by vehicle_key purchase_date rdr_sequence;

	if last.vehicle_key then
		soldcount = 1;
	else soldcount = 0;
run;

data wjsas.sold_dates_ACT (drop=rdr_sequence);
	set lastsale_ACT;
	where soldcount = 1;
run;

PROC SQL;
	CREATE TABLE WJSAS.INCENT_BY_MDL_GEO AS 
		SELECT t1.SALES_YEAR, 
			t1.SALES_MONTH, 
			t1.MODEL_YEAR, 
			t1.SERIES_DESC, 
			t1.DEALER_CD, 
			t1.REGION_CD, 
			t1.ADI_DESC, 
			t1.SHOWROOM_STATE_CD, 
		(CASE
			WHEN t1.DEALER_CD IN('MI007','MI017','MI027','MI039','MI040','MI042','MI048','MI049','MI054') THEN "MIPLAN"
			ELSE
			"USPLAN"
		END)
	as MICHIND,
		/* SUM_of_LEASE */
	(SUM(t1.LEASE)) FORMAT=17.2 AS SUM_of_LEASE, /* SUM_of_RETAIL */
	(SUM(t1.RETAIL)) FORMAT=17.2 AS SUM_of_RETAIL, /* SUM_of_collgrad */
	(SUM(t1.COLL_GRAD)) FORMAT=17.2 AS SUM_of_COLLGRAD, /* SUM_of_RETAIL */

	/* SUM_of_Military */
	(SUM(t1.Military)) FORMAT=17.2 AS SUM_of_Military, /* SUM_of_Mobility */
	(SUM(t1.Mobility)) FORMAT=17.2 AS SUM_of_Mobility, /* SUM_of_SpecPromo */
	(SUM(t1.SpecPromo)) FORMAT=17.2 AS SUM_of_SpecPromo, /* SUM_of_VOC */
	(SUM(t1.VOC)) FORMAT=17.2 AS SUM_of_VOC, /* SUM_of_FinalPay */
	(SUM(t1.FinalPay)) FORMAT=17.2 AS SUM_of_FinalPay, /* SUM_of_STARBonus */
	(SUM(t1.STARBonus)) FORMAT=17.2 AS SUM_of_STARBonus, /* SUM_of_BaseSTAR */
	(SUM(t1.BaseSTAR)) FORMAT=17.2 AS SUM_of_BaseSTAR, /* SUM_of_DealerCash */
	(SUM(t1.DealerCash)) FORMAT=17.2 AS SUM_of_DealerCash, /* SUM_of_Rebate */
	(SUM(t1.Rebate)) FORMAT=17.2 AS SUM_of_Rebate, /* SUM_of_COC */
	(SUM(t1.COC)) FORMAT=17.2 AS SUM_of_COC, /* SUM_of_RBC */
	(SUM(t1.RBC)) FORMAT=17.2 AS SUM_of_RBC, /* SUM_of_STARContrib */
	(SUM(t1.STARContrib)) FORMAT=17.2 AS SUM_of_STARContrib, /* SUM_of_Autoshow */
	(SUM(t1.Autoshow)) FORMAT=17.2 AS SUM_of_Autoshow, /* SUM_of_FlexCash */
	(SUM(t1.FlexCash)) FORMAT=17.2 AS SUM_of_FlexCash, /* SUM_of_RegionalDC */
	(SUM(t1.RegionalDC)) FORMAT=17.2 AS SUM_of_RegionalDC, /* SUM_of_AgedVIN */
	(SUM(t1.AgedVIN)) FORMAT=17.2 AS SUM_of_AgedVIN, /* SUM_of_Circle_E */
	(SUM(t1.Circle_E)) FORMAT=17.2 AS SUM_of_Circle_E, /* SUM_of_Circle_DEPP */
	(SUM(t1.Circle_DEPP)) FORMAT=17.2 AS SUM_of_Circle_DEPP, /* SUM_of_Circle_A */
	(SUM(t1.Circle_A)) FORMAT=17.2 AS SUM_of_Circle_A, /* SUM_of_Uber */
	(SUM(t1.Uber)) FORMAT=17.2 AS SUM_of_Uber, /* SUM_of_UNKNOWN */
	(SUM(t1.UNKNOWN)) FORMAT=17.2 AS SUM_of_UNKNOWN, /* SUM_of_Disaster */
	(SUM(t1.Disaster)) FORMAT=17.2 AS SUM_of_Disaster, /* SUM_of_Boost */
	(SUM(t1.Boost)) FORMAT=17.2 AS SUM_of_Boost, /* SUM_of_SpecEvent */
	(SUM(t1.SpecEvent)) FORMAT=17.2 AS SUM_of_SpecEvent, /* SUM_of_DealerCommFleet */
	(SUM(t1.DealerCommFleet)) FORMAT=17.2 AS SUM_of_DealerCommFleet, /* SUM_of_Circle_M */
	(SUM(t1.Circle_M)) FORMAT=17.2 AS SUM_of_Circle_M, /* SUM_of_TradeIn */
	(SUM(t1.TradeIn)) FORMAT=17.2 AS SUM_of_TradeIn, /* SUM_of_Circle_O */
	(SUM(t1.Circle_O)) FORMAT=17.2 AS SUM_of_Circle_O, /* SUM_of_Circle_V */
	(SUM(t1.Circle_B)) FORMAT=17.2 AS SUM_of_Circle_B, /* SUM_of_Circle_B */
	(SUM(t1.Circle_V)) FORMAT=17.2 AS SUM_of_Circle_V, /* SUM_of_Circle_V */
	(SUM(t1.Circle_K)) FORMAT=17.2 AS SUM_of_Circle_K, /* SUM_of_CircleK */
	(SUM(t1.SRC_CPO)) FORMAT=17.2 AS SUM_of_SRC_CPO, /* SUM_of_SRC_CPO */


	/*(SUM(t1.Circle_W)) FORMAT=17.2 AS SUM_of_Circle_W, /* SUM_of_CircleW */

	(SUM(t1.Lease_Coupon)) FORMAT=17.2 AS SUM_of_Lease_Coupon, /* SUM_of_Lease_coupon */
	(SUM(t1.FinalPay_X)) FORMAT=17.2 AS SUM_of_FinalPay_X, /* SUM_of_FinalPay_X */
	(SUM(t1.DPB)) FORMAT=17.2 AS SUM_of_DPB, /* SUM_of_DPB */
	(SUM(t1.soldcount)) AS SUM_of_soldcount, /* SUM_of_TotalIncentives */
	(SUM(t1.TotalIncentives)) FORMAT=17.2 AS SUM_of_TotalIncentives, /* COUNT_of_LEASE */
	(COUNT(t1.LEASE)) AS COUNT_of_LEASE, /* COUNT_of_COLL_GRAD */
	(COUNT(t1.COLL_GRAD)) AS COUNT_of_COLLGRAD, /* COUNT_of_RETAIL */
	(COUNT(t1.RETAIL)) AS COUNT_of_RETAIL, /* COUNT_of_Military */
	(COUNT(t1.Military)) AS COUNT_of_Military, /* COUNT_of_Mobility */
	(COUNT(t1.Mobility)) AS COUNT_of_Mobility, /* COUNT_of_SpecPromo */
	(COUNT(t1.SpecPromo)) AS COUNT_of_SpecPromo, /* COUNT_of_VOC */
	(COUNT(t1.VOC)) AS COUNT_of_VOC, /* COUNT_of_FinalPay */
	(COUNT(t1.FinalPay)) AS COUNT_of_FinalPay, /* COUNT_of_STARBonus */
	(COUNT(t1.STARBonus)) AS COUNT_of_STARBonus, /* COUNT_of_BaseSTAR */
	(COUNT(t1.BaseSTAR)) AS COUNT_of_BaseSTAR, /* COUNT_of_DealerCash */
	(COUNT(t1.DealerCash)) AS COUNT_of_DealerCash, /* COUNT_of_Rebate */
	(COUNT(t1.Rebate)) AS COUNT_of_Rebate, /* COUNT_of_COC */
	(COUNT(t1.COC)) AS COUNT_of_COC, /* COUNT_of_RBC */
	(COUNT(t1.RBC)) AS COUNT_of_RBC, /* COUNT_of_STARContrib */
	(COUNT(t1.STARContrib)) AS COUNT_of_STARContrib, /* COUNT_of_Autoshow */
	(COUNT(t1.Autoshow)) AS COUNT_of_Autoshow, /* COUNT_of_FlexCash */
	(COUNT(t1.FlexCash)) AS COUNT_of_FlexCash, /* COUNT_of_RegionalDC */
	(COUNT(t1.RegionalDC)) AS COUNT_of_RegionalDC, /* COUNT_of_AgedVIN */
	(COUNT(t1.AgedVIN)) AS COUNT_of_AgedVIN, /* COUNT_of_Circle_E */
	(COUNT(t1.Circle_E)) AS COUNT_of_Circle_E, /* COUNT_of_Circle_DEPP */
	(COUNT(t1.Circle_DEPP)) AS COUNT_of_Circle_DEPP, /* COUNT_of_Circle_A */
	(COUNT(t1.Circle_A)) AS COUNT_of_Circle_A, /* COUNT_of_Uber */
	(COUNT(t1.Uber)) AS COUNT_of_Uber, /* COUNT_of_UNKNOWN */
	(COUNT(t1.UNKNOWN)) AS COUNT_of_UNKNOWN, /* COUNT_of_Disaster */
	(COUNT(t1.Disaster)) AS COUNT_of_Disaster, /* COUNT_of_Boost */
	(COUNT(t1.Boost)) AS COUNT_of_Boost, /* COUNT_of_SpecEvent */
	(COUNT(t1.SpecEvent)) AS COUNT_of_SpecEvent, /* COUNT_of_DealerCommFleet */
	(COUNT(t1.DealerCommFleet)) AS COUNT_of_DealerCommFleet, /* COUNT_of_Circle_M */
	(COUNT(t1.Circle_M)) AS COUNT_of_Circle_M, /* COUNT_of_TradeIn */
	(COUNT(t1.TradeIn)) AS COUNT_of_TradeIn, /* COUNT_of_Circle_O */
	(COUNT(t1.Circle_O)) AS COUNT_of_Circle_O, /* COUNT_of_Circle_V */
	(COUNT(t1.Circle_V)) AS COUNT_of_Circle_V,
	(COUNT(t1.Circle_B)) AS COUNT_of_Circle_B,
	/*(COUNT(t1.Circle_W)) AS COUNT_of_Circle_W,*/
	(COUNT(t1.Circle_K)) FORMAT=17.2 AS COUNT_of_Circle_K, /* COUNT_of_CircleK */
	(COUNT(t1.Lease_Coupon)) FORMAT=17.2 AS COUNT_of_Lease_Coupon, /* COUNT_of_Lease_Coupon */
	(COUNT(t1.FinalPay_X)) FORMAT=17.2 AS COUNT_of_FinalPay_X, /* COUNT_of_FinalPay_X */
	(COUNT(t1.DPB)) FORMAT=17.2 AS COUNT_of_DPB, /* COUNT_of_DPB */
	(COUNT(t1.SRC_CPO)) FORMAT=17.2 AS COUNT_of_SRC_CPO /* COUNT_of_SRC_CPO */
FROM WJSAS.INCENTIVES_DATABASE t1 GROUP BY t1.SALES_YEAR, t1.SALES_MONTH, t1.MODEL_YEAR, t1.SERIES_DESC, t1.DEALER_CD, t1.REGION_CD, t1.ADI_DESC, t1.SHOWROOM_STATE_CD, MICHIND;
QUIT;
data wjsas.INCENT_BY_MDL_GEO;
  set wjsas.INCENT_BY_MDL_GEO;
  array change _numeric_;
       do over change;
           if change=. then change=0;
       end;
run ;
PROC SQL;
   CREATE TABLE WJSAS.SALEBYDLR AS 
   SELECT t4.SALES_YEAR, 
          t4.SALES_MONTH, 
          t3.REGION_CD,
			t1.DEALER_KEY ,
          t3.DEALER_CD, 
          t3.DEALER_NAME, 
          t2.MODEL_YEAR, 
		  t2.SERIES_DESC,
		  t2.SERIES_CD,
          t3.ADI_DESC, 
          t3.SHOWROOM_STATE_CD, 
          t3.SALES_DISTRICT_CD, 
          /* Sales */
            (SUM(ifn(t1.RDR_TYPE = 'RDR',1,-1))) AS Sales
      FROM INCENT.IDM_TH_RDR t1, INCENT.IDM_TH_VEHICLE t2, INCENT.IDM_TD_DEALER t3, INCENT.IDM_TD_DATE t4
      WHERE (t1.VEHICLE_KEY = t2.VEHICLE_KEY AND t1.DEALER_KEY = t3.DEALER_KEY AND t1.RDR_DATE_KEY = t4.DATE_KEY) AND 
           (t1.RDR_ENTRY_DATE >= '1Jan2012:0:0:0'dt AND t1.INCENTIVE_SALE_TYPE_KEY NOT IN 
           (
           9,
           13,
           14,
           15,
           16
           ))
      GROUP BY t4.SALES_YEAR,
               t4.SALES_MONTH,
               t3.REGION_CD,
			   t1.DEALER_KEY ,
               t3.DEALER_CD,
               t3.DEALER_NAME,
               t2.MODEL_YEAR,
			   t2.SERIES_DESC,
			   t2.SERIES_CD,
               t3.ADI_DESC,
               t3.SHOWROOM_STATE_CD,
               t3.SALES_DISTRICT_CD;
QUIT;

