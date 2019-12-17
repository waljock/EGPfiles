%include '/sasuser/prod/hma03468/voc_coc.sas';

PROC SQL;
   CREATE TABLE WORK.SM_RDR AS 
   SELECT t1.SALES_MONTH_KEY, 
          t3.SALES_QUARTER_DESC, 
          t2.DEALER_CD, 
		  
          
		t1.SALES_MANAGER_KEY, 
          /* SALES */
            (SUM(ifn(t1.RDR_TYPE='RDR',1,-1))) AS SALES
          /* YrQrtr */
            
      FROM INCENT.IDM_TH_RDR t1, INCENT.IDM_TD_DEALER t2, INCENT.IDM_TD_DATE t3
      WHERE (t1.DEALER_KEY = t2.DEALER_KEY AND t1.RDR_DATE_KEY = t3.DATE_KEY) AND (t1.INCENTIVE_SALE_TYPE_KEY NOT IN 
           (
           13,
           14,
           15,
           16,
           12
           ) AND (t1.SALES_MONTH_KEY between 201901 and 201906) AND SUBSTRN(t2.DEALER_CD,3,1) ne '7') 
      GROUP BY t1.SALES_MONTH_KEY,
               t3.SALES_QUARTER_DESC,
               t2.DEALER_CD,
               
			   t1.SALES_MANAGER_KEY;
QUIT;



PROC SQL;
   CREATE TABLE WORK.LastActive_SM AS 
   SELECT  t1.SALES_MANAGER_KEY, 
   			max(t1.RDR_DATE_KEY) as maxdate,
			min(t1.RDR_DATE_KEY) as mindate,
          /* SALES */
            (SUM(ifn(t1.RDR_TYPE='RDR',1,-1))) AS SALES 
          
      FROM INCENT.IDM_TH_RDR t1, INCENT.IDM_TD_DEALER t2, INCENT.IDM_TD_DATE t3
      WHERE (t1.DEALER_KEY = t2.DEALER_KEY AND t1.RDR_DATE_KEY = t3.DATE_KEY) AND (t1.INCENTIVE_SALE_TYPE_KEY NOT IN 
           (
           13,
           14,
           15,
           16,
           12
           ) )
      GROUP BY 
               t1.SALES_MANAGER_KEY
	ORDER BY 
		(calculated maxdate) 
               ;
QUIT;

data current_sm;
set LastActive_SM;
/*where maxdate >= 20180101;*/
run;
%_eg_conditional_dropds(WORK.QUERY_FOR_IDM_TH_RDR_0000);

PROC SQL;
   CREATE TABLE WORK.MNTH_SALES AS 
   SELECT t1.SALES_MONTH_KEY, 
          t1.DEALER_CD, 
          /* SUM_of_SALES */
            (SUM(t1.SALES)) AS SUM_of_SALES
      FROM WORK.SM_RDR t1
      WHERE t1.SALES_MONTH_KEY BETWEEN 201901 and 201906
      GROUP BY t1.SALES_MONTH_KEY,
               t1.DEALER_CD
      ORDER BY t1.DEALER_CD,
               t1.SALES_MONTH_KEY;
QUIT;





%_eg_conditional_dropds(WORK.QUERY_FOR_IDM_TH_DEALER_EMP_0001);

PROC SQL;
   CREATE TABLE WORK.EMP1 AS 
   SELECT t1.DEALER_EMPLOYEE_KEY, 
          t1.AS400_DEALER_PERSONNEL_CD, 
          t1.DEALER_CD, 
          t1.EMP_JOB_CD, 
          t1.EMP_JOB_STATUS_CD, 
		  t1.ACTIVATION_DATE,
          
          t1.ENROLLMENT_DATE, 
          t1.IS_ACTIVE, 
          
          t2.DEALER_PERSONNEL_KEY, 
          t2.AS400_DEALER_PERSONNEL_KEY 
          
      FROM INCENT.IDM_TH_DEALER_EMPLOYEE t1
           INNER JOIN INCENT.IDM_VD_DEALER_PERSONNEL t2 ON (t1.AS400_DEALER_PERSONNEL_CD = 
          t2.AS400_DEALER_PERSONNEL_KEY);
QUIT;
PROC SQL;
   CREATE TABLE WORK.EMP2 AS 
   SELECT *
      FROM WORK.EMP1 t1
      WHERE t1.EMP_JOB_CD IN 
           (
           
		   'SM'
           
           ) 
			AND t1.IS_ACTIVE = 1;
QUIT;
PROC SQL;
   CREATE TABLE WORK.ALL_SPSM AS 
   SELECT *
      FROM WORK.EMP1 t1
      WHERE t1.EMP_JOB_CD IN 
           (
           
		   'SM'
           
           ) 
			AND t1.IS_ACTIVE = 1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.SalesbySM AS 



   SELECT DISTINCT put(t1.SALES_MONTH_KEY,w6.) as txtSaleMo, 
          t1.SALES_MONTH_KEY,
          t1.DEALER_CD, 
          t1.SALES_MANAGER_KEY, 
          t1.SALES, 
		   
          t2.DEALER_EMPLOYEE_KEY, 
          t2.AS400_DEALER_PERSONNEL_CD, 
          t2.DEALER_CD AS DEALER_CD1, 
          t2.EMP_JOB_CD, 
          t2.EMP_JOB_STATUS_CD, 
          t2.ENROLLMENT_DATE, 
          t2.IS_ACTIVE, 
          t2.DEALER_PERSONNEL_KEY, 
          t2.AS400_DEALER_PERSONNEL_KEY
      FROM WORK.SM_RDR t1, WORK.EMP2 t2
      WHERE t2.EMP_JOB_CD ='SM' AND (t1.DEALER_CD = t2.DEALER_CD AND t1.SALES_MANAGER_KEY = t2.DEALER_PERSONNEL_KEY) 
      ORDER BY t1.SALES_MANAGER_KEY,
               t1.SALES_MONTH_KEY;
QUIT;


PROC SQL;
   CREATE TABLE WORK.alldates AS 
   SELECT DISTINCT /* txtSalemo */
                     (put(t1.SALES_MONTH_KEY, w6.)) AS txtSalemo
					 
					 

      FROM SALES.QM_TD_DATE t1
      WHERE t1.SALES_MONTH_KEY BETWEEN 201801 and 201906;
QUIT;

data alldates2;
set alldates;
by txtsalemo ;
seq = _N_;
run;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_ALLDATES AS 
   SELECT t2.DEALER_PERSONNEL_KEY, 
   		t2.DEALER_CD,
         t1.txtSaleMo AS txtSaleMo1,
 		
         t1.seq,
		  sum(t2.SALES) as totalSales 
      FROM WORK.ALLDATES2 t1
           LEFT JOIN WORK.SALESBYSM t2 ON (t1.txtSalemo = t2.txtSaleMo)
		   where t2.DEALER_PERSONNEL_KEY ne . 

	  group by 
		t2.DEALER_PERSONNEL_KeY,
		
   		t2.DEALER_CD,
         txtSaleMo1,
 			  
		 
         t1.seq
      ORDER BY 
		t2.DEALER_PERSONNEL_KEY, 
   		t2.DEALER_CD,
         txtSaleMo1,
 		
         t1.seq;
QUIT;

data laggs;
set QUERY_FOR_ALLDATES;

by dealer_personnel_key DEALER_CD txtSaleMo1 ;

/* Create and assign values to three new variables.  Use ENDLAG1-      */
  /* ENDLAG3 to store lagged values of END, from the most recent to the  */
  /* third preceding value.                                              */   
  array x(*) endlag1-endlag3;
  endlag1=lag1(totalsales);
  endlag2=lag2(totalsales);
  endlag3=lag3(totalsales);
  endlag4=lag4(totalsales);
  endlag5=lag5(totalsales);
  endlag6=lag6(totalsales);
  seqlag = lag1(seq);
  /* Reset COUNT at the start of each new BY-Group */
  if first.dealer_personnel_key then count=1;
  /* On each iteration, set to missing array elements   */
  /* that have not yet received a lagged value for the  */
  /* current BY-Group.  Increase count by 1.            */   
  do i=count to dim(x);
    x(i)=.;
  end;
  count + 1;

 

  
run;
data laggs;
  set laggs;
  array change _numeric_;
       do over change;
           if change=. then change=0;
       end;
run ;
%_eg_conditional_dropds(WORK.LAGGS2);
PROC SQL;
   CREATE TABLE WORK.DLR_MO_SALES AS 
   SELECT put(t1.SALES_MONTH_KEY,w6.) as txtSaleMo1, 
          t1.DEALER_CD, 
          /* SUM_of_SALES */
            (SUM(t1.SALES)) AS SUM_of_SALES
      FROM WORK.SM_RDR t1
      GROUP BY calculated txtSaleMo1,
               t1.DEALER_CD;
QUIT;

PROC SQL;
   CREATE TABLE WORK.DLR_TOT_SALES AS 
   SELECT t1.DEALER_CD, 
          /* SUM_of_SUM_of_SALES */
            (SUM(t1.SUM_of_SALES)) AS TOTAL_SALES
      FROM WORK.DLR_MO_SALES t1
	  WHERE t1.txtsalemo1 >= '201901'
      GROUP BY t1.DEALER_CD
      ORDER BY calculated TOTAL_SALES;
QUIT;

proc rank data=WORK.DLR_TOT_SALES out=work.dlr_ranks descending;
var TOTAL_SALES;
ranks rank;
run;

PROC SQL;
   CREATE TABLE WORK.rank_Date AS 
   SELECT t1.DEALER_CD, 
   			t2.DEALER_NAME,
          
          t1.TOTAL_SALES, 
          t1.rank,
		  t2.OPERATION_DATE
      FROM WORK.DLR_RANKS t1
           INNER JOIN SALES.QM_TD_DEALER t2 ON (t1.DEALER_CD = t2.DEALER_CD);
QUIT;
proc sort data=rank_date;
by rank;
run;

PROC SQL;
   CREATE TABLE WORK.Ranked_Dealers_SM AS 
   SELECT DISTINCT t1.DEALER_CD, 
   			t1.DEALER_NAME,
          t1.TOTAL_SALES, 
          t2.DEALER_PERSONNEL_KEY, 
          t1.rank AS Dealer_Sales_Rank, 
          /* SM_SALES */
            (SUM(t2.totalSales)) AS SM_SALES
      FROM WORK.RANK_DATE t1
           INNER JOIN WORK.LAGGS t2 ON (t1.DEALER_CD = t2.DEALER_CD)
      GROUP BY t1.DEALER_CD, 
   			t1.DEALER_NAME,
          t1.TOTAL_SALES, 
          t2.DEALER_PERSONNEL_KEY 
      ORDER BY t1.rank;
QUIT;

PROC SQL;
   CREATE TABLE WORK.Top_X_Dealers AS 
   SELECT t1.DEALER_CD, 
   			t1.DEALER_NAME,
          t1.TOTAL_SALES, 
          t1.DEALER_PERSONNEL_KEY, 
          t1.Dealer_Sales_Rank, 
          t1.SM_SALES
      FROM WORK.Ranked_Dealers_SM t1
      WHERE t1.Dealer_Sales_Rank <= 30
      ORDER BY t1.SM_SALES DESC;
QUIT;

proc sql;
	create table work.TOP_X_exclude as select distinct
	dealer_cd, Dealer_Name
	from Top_X_Dealers;
quit;

