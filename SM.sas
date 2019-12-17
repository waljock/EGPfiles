




proc sort data=work.categorysales_sm;
by sales_person_key salequarter  name target;
run;

data firstpass_sm;
set work.categorysales_sm;
by sales_person_key salequarter  ;
if sm_sales >= target ;
/*if first.salequarter then firstind = 1;*/
/*else firstind = 0;*/


run;

data secpass_sm;
set work.firstpass_sm;
by sales_person_key salequarter  ;

if first.salequarter then firstind = 1;
else firstind = 0;


run;
data traypass_sm;
set work.secpass_sm;
by sales_person_key salequarter  ;

if firstind = 1;


run;
