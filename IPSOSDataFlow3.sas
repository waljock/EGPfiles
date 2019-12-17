%include "/sasuser/prod/hma03468/voc_coc.sas";

%_eg_conditional_dropds(WORK.HMA_INCENTIVES);

PROC SQL;
   CREATE TABLE WJSAS.HMA_INCENTIVES AS 
   SELECT t1.VEHICLE_KEY, 
   			t1.IDMVK,
          t1.VIN, 
          t1.TxtMY, 
          t1.SERIES_CD, 
          t1.SERIES_DESC, 
          t1.MODEL_CD, 
          t1.MODEL_SERIES_DESC, 
          t1.Inventory_Dealer, 
          t3.DEALER_NAME, 
          t1.ACCESSORY_GROUP_CD, 
          t1.INVENTORY_STATUS_CD, 
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
          t1.COLL_GRAD, 
          t1.BaseSTAR, 
          t1.RETAIL, 
          t1.Rebate, 
          t1.RegionalDC, 
          t1.RBC, 
          t1.STARContrib, 
          t1.FinalPay_X, 
          t1.LEASE, 
          t1.VOC, 
          t1.Military, 
          t1.DPB, 
          t1.FlexCash, 
          t1.TradeIn, 
          t1.Disaster, 
          t1.Autoshow, 
          t1.Circle_A, 
          t1.Uber, 
          t1.COC, 
          t1.Circle_E, 
          t1.Circle_M, 
          t1.Boost, 
          t1.Mobility, 
          t1.SpecEvent, 
          t1.DealerCash, 
          t1.Circle_O, 
          t1.Circle_V, 
          t1.FinalPay, 
          t1.STARBonus, 
          t1.SpecPromo, 
          t1.Circle_K, 
          t1.SRC_CPO, 
          t1.DealerCommFleet, 
          t1.UNKNOWN, 
          t1.Lease_Coupon, 
          t1.AgedVIN, 
          t1.Circle_DEPP, 
          t1.First_Responders, 
          t1.Circle_B, 
          t1.Autoshow_Coupon, 
          t1.Circle_W, 
          t1.soldcount, 
          t1.TotalIncentives, 
          t1.IS_HMFStdBC, 
          t1.DEALER_CD, 
          t1.REGION_CD, 
          t1.ADI_DESC, 
          t1.ADI_CD, 
          t1.SHOWROOM_STATE_CD, 
          t2.GEO_LATITUDE, 
          t2.GEO_LONGITUDE, 
          t2.CITY, 
          t2.STATE_CD, 
          t2.ZIP_CD, 
          t1.HMC_INVOICE_DATE, 
          t1.PURIFICATION_DATE, 
          t1.WHOLESALE_DATE, 
          t1.RETAIL_SALE_DATE, 
          t1.RDR_DATE, 
          t1.RDR_ENTRY_DATE, 
          t1.GENERIC_COLOR_DESC, 
          t1.IS_SALES_MONTH_END, 
          t1.SALES_DAY_OF_MONTH
      FROM MAIN.FINAL_FINAL_FINAL t1
           LEFT JOIN QDB_MDM.D_DEALER_CONTACT t2 ON (t1.DEALER_CD = t2.DEALER_CD)
           LEFT JOIN SALES.QM_TD_DEALER t3 ON (t1.DEALER_CD = t3.DEALER_CD)
      WHERE t1.INVENTORY_STATUS_CD IN 
           (
           'HI',
           'DS'
           ) AND t1.SALES_YEAR >= 2016 AND t1.MODEL_YEAR >= 2016 AND t2.CONTACT_TYPE_CD = 'SHOW';
QUIT;
proc sort data=WJSAS.HMA_INCENTIVES nodup;
by vin;
run;


ods CSV file= "/sasuser/prod/hma03468/IPSOS/HMA_INCENT.txt" options(delimiter="|" quote_by_type = "yes");
proc print data=WJSAS.HMA_INCENTIVES noobs;
/*format inservdate date9.;*/
/*format valasofdate date9.*/



run;

%_eg_conditional_dropds(WORK.QUERY_FOR_FINAL_FINAL_FINAL);
