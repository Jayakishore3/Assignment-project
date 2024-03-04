
proc sort data=crfdata.ae out=ae_sort ;
by subjid pterm aestdt ;
run;
data ae_raw;
set work.ae_sort;
rename aeser=serious;
run;
libname sdtm "C:\Documents\SDTM";
options validvarname=upcase;
data Ae_raw1;

/* Length and label definitions for variables */
length STUDYID $ 10 DOMAIN $ 2 SUBJID  8 SITEID $ 8 USUBJID $ 20 AESEQ 8
AESPID  3 AETERM $ 200 AELLTCD $ 8 AEBODSYS $ 200 AESEV $ 8 AESER $ 10 AEACN $ 24 AEREL $ 22
AEOUT $ 22 AESCONG $ 10 AESDISAB $ 10 AESDTH $ 10 AEHOSP $ 10 AESLIFE $ 10 AESTDTC $ 20
AEENDTC $ 20 AEENRF $ 20 ;

 /* Label definitions for variables */
label STUDYID = "Study Identifier"
DOMAIN = "Domain Abbreviation"
SUBJID = "Subject ID"
SITEID = "Site ID"
USUBJID = "Unique Subject Identifier"
AESEQ = "Sequence Number"
AESPID = "Sponsor Defined Identifier"
AETERM = "Reported Term for Adverse Event"
AELLTCD = "Lowest Level Term Code"
AEBODSYS = "Body System or Organ Class"
AESEV = "Severity/Intensity"
AESER = "Serious Event"
AEACN = "Action Taken with Study Treatment"
AEREL = "Causality"
AEOUT = "Outcome of Adverse Event"
AESCONG = "Congenital Anomaly or Birth Defect"
AESDISAB = "Persist or Signif Disability/Incapacity"
AESDTH = "Results in Death"
AEHOSP = "Requires or Prolong Hospitalization"
AESLIFE = "Is Life Threatening"
AESTDTC = "Start Date/Time of Adverse Event"
AEENDTC = "End Date/Time of Adverse Event"
AEENRF = "End Relative to Reference Period";

set work.ae_raw;
Studyid=strip(sdyid);
domain="AE";
subjid=subjid;
siteid=put(invid, best8.);
usubjid=catx("-",studyid,siteid,subjid);
by subjid pterm;
retain aeseq 0;
if first.subjid then aeseq=1;
else do aeseq=aeseq+1;end;
aespid=aeid;
aeterm=pterm;
aelltcd=lltcode;
aebodsys=socterm;
if SEV=1 then AESEV="Mild";
else if SEV=2 then AESEV="Moderate";
else if SEV=3 then AESEV="Severe";
if serious=0 then AESER="No";
else if serious=1 then AESER="Yes";
If Action=1 then AEACN="None/No Action Taken";
else if Action=2 then AEACN="Dose Interrupted";
else if Action=3 then AEACN="Dose Reduced";
else if Action=4 then AEACN="Study Drug Withdrawn";
if REL=1 then AEREL="Not Related";
else if REL=2 then AEREL="Possibly Related";
else if REL=3 then AEREL="Related";
if out=1 then AEOUT= "Not Recovered/Not Resolved";
else if out=2 then AEOUT="Recovered/Resolved";
else if out=3 then AEOUT="Recovered/Resolved with Sequelae";
else if out=4 then AEOUT="Recovering/Resolving";
else if out=5 then AEOUT="Unkown";
else if out=6 then AEOUT="Fatal";
If CRIT4=0 then AESCONG="No";
else if CRIT4=1 then AESCONG="Yes";
If CRIT2=0 then AESDISAB="No";
else if CRIT1=1 then AESDISAB="Yes";
If CRIT5=0 then AESDTH="No";
else if CRIT5=1 then AESDTH="Yes";
If CRIT3=0 then AEHOSP="No";
else if CRIT3=1 then AEHOSP="Yes";
If CRIT1=0 then AESLIFE="No";
else if CRIT1=1 then AESLIFE="Yes";
aestdtc=put(aestdt, yymmdd10.);
aeendtc=put(aeendt, yymmdd10.);
aeenrf=put(aeongo, best8.);
run;

data new;
set crfdata.dm;
keep subjid rfstdtc rfendtc rficdtc;;
run;
proc sort data= new;
by subjid;
run;
proc sort data=ae_raw1;
by subjid;
run;
data final;
merge ae_raw1(in=a) new(in=b);
by subjid;
if a and b;
run;



data sdtm.ae;
set final;
length AESTDY 8 AEENDY 8 EPOCH $ 25;
label AESTDY = "Study Day of Start of Adverse Event"
AEENDY = "Study Day of End of Adverse Event"
EPOCH="epoch";
If (AESTDTC < RFSTDTC) then AESTDY=input(AESTDTC,yymmdd10.)-input(RFSTDTC,yymmdd10.);
Else if (AESTDTC >= RFSTDTC) then AESTDY=input(AESTDTC,yymmdd10.)-input(RFSTDTC,yymmdd10.)+1;
If (AEENDTC < RFSTDTC) then AEENDY=input(AEENDTC,yymmdd10.)-input(RFSTDTC,yymmdd10.);
Else if (AEENDTC >= RFSTDTC) then AEENDY=input(AEENDTC,yymmdd10.)-input(RFSTDTC,yymmdd10.)+1;
if rficdtc<=aestdtc<rfstdtc then epoch="screening";
Else if rfstdtc<=aestdtc<=rfendtc then epoch="treatment";
Else if aestdtc>rfendtc then epoch="follow up";
keep STUDYID  DOMAIN  SUBJID   SITEID  USUBJID  AESEQ  
AESPID AETERM AELLTCD AEBODSYS AESEV AESER AEACN AEREL
AEOUT AESCONG AESDISAB AESDTH AEHOSP AESLIFE EPOCH AESTDTC
AEENDTC AEENRF AESTDY AEENDY;
run;


libname xpt xport "C:\Documents\CRF data\xpt\ae.xpt";
data xpt.ae;
set sdtm.ae;
run;
