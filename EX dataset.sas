libname sdtm "C:\Documents\SDTM";
options validvarname=upcase;
proc sort data=crfdata.expo out=raw;;
by sdyid subjid exstdt;
run;
proc sort data=sdtm.dm out=rawdm;
by studyid subjid;
run;

data exposure1;
merge raw(in=a) rawdm(in=b) ;
by subjid;
if a;
run;
data exposure2;
set exposure1;
studyid=sdyid;
domain="EX";
siteid=put(invid,best.);
usubjid=catx("-",studyid,siteid,subjid);
exrefid=kitnum;
if armcd="placebo" then do; extrt="Placebo";exdose=0;exdosu="mg";end;
else if armcd="dcds01-40mg" then do;extrt="dcds01";exdose=40;exdosu="mg";end;
else if armcd="dcds01-20mg" then do;extrt="dcds01";exdose=20;exdosu="mg";end;
if extrt="Placebo" then excat="COMPARATOR CLASS";
exdosfrm=type;
exdosfrq="OD";
exroute="ORAL";
run;
proc sort data=exposure2 out=ex2;
by subjid exstdt;
run;
data sdtm.Ex;
length STUDYID $20 DOMAIN $2 USUBJID $20 EXSEQ 8 EXREFID $20 EXTRT $20 EXCAT $20 EXDOSE 8 EXDOSU $20 EXDOSFRM $20 EXDOSFRQ $20
EXROUTE $20 EPOCH $20 EXSTDTC $10 EXENDTC $10 EXSTDY 8 EXENDY 8;
retain STUDYID  DOMAIN USUBJID EXSEQ EXREFID EXTRT EXCAT EXDOSE EXDOSU EXDOSFRM EXDOSFRQ EXROUTE EPOCH EXSTDTC EXENDTC EXSTDY EXENDY;
label STUDYID="Study Identifier"
DOMAIN="Domain Abbreviation"
USUBJID="Unique Subject Identifier"
EXSEQ="Sequence Number"
EXREFID="Reference ID"
EXTRT="Name of Treatment"
EXCAT="CATEGORY OF TREATMENT"
EXDOSE="Dose"
EXDOSU="Dose Units"
EXDOSFRM="Dose Form"
EXDOSFRQ="Dosing Frequency per Interval"
EXROUTE="Route of Administration"
EPOCH="Epoch"
EXSTDTC="Start Date/Time of Treatment"
EXENDTC="End Date/Time of Treatment"
EXSTDY="Study Day of Start of Treatment"
EXENDY="Study Day of End of Treatment";
set ex2;
where exstdt ne .;
exstdtc=put(exstdt,yymmdd10.);
if missing (retrndt) and not missing(exstdtc) then exendtc=exstdtc;
else exendtc=put(retrndt,yymmdd10.);
if (exstdtc<rfstdtc) then exstdy=input(exstdtc,yymmdd10.)-input(rfstdtc,yymmdd10.);
else if (exstdtc>=rfstdtc) then exstdy=input(exstdtc,yymmdd10.)-input(rfstdtc,yymmdd10.)+1;
if (exendtc<rfstdtc) then exendy=input(exendtc,yymmdd10.)-input(rfstdtc,yymmdd10.);
else if (exendtc>rfstdtc) then exendy=input(exendtc,yymmdd10.)-input(rfstdtc,yymmdd10.)+1;
by subjid;
retain exseq 0;
if first.subjid then exseq=1;
else exseq=exseq+1;
if exstdtc<rfstdtc then epoch="Screening";
Else if rfstdtc<=exstdtc<=rfendtc then epoch="Treatment";
Else if exstdtc>rfendtc then epoch="Follow up";
keep STUDYID  DOMAIN USUBJID EXSEQ EXREFID EXTRT EXCAT EXDOSE EXDOSU EXDOSFRM EXDOSFRQ EXROUTE EPOCH EXSTDTC EXENDTC EXSTDY EXENDY;
run;


libname xpt xport "C:\Documents\CRF data\xpt\ex.xpt";
data xpt.ex;
set sdtm.ex;
run;
