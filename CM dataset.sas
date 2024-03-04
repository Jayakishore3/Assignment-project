proc sort data=crfdata.cm out=new;
by subjid;
run;

data new1;
length STUDYID $10 DOMAIN $2 USUBJID $20 SUBJID 8 SITEID $8 CMSEQ 8 CMTRT $200 CMDOSTXT $20 CMDOSU $15 CMDOSFRQ $15 CMROUTE $50
CMSTDTC $20 CMENDTC $20 CMENRF $10;;
set work.new;
label STUDYID="Study Identifier"
DOMAIN ="Domain Abbreviation"
USUBJID="Unique Subject Identifier"
SUBJID='Subject Identifier'
SITEID="Study Site Identifier"
CMSEQ='Sequence Number'
CMTRT="Reported Name of Drug, Med, or Therapy"
CMDOSTXT="Dose Description"
CMDOSU ="Dose Units"
CMDOSFRQ="Dosing Frequency per Interval"
CMROUTE="Route of Administration"
CMSTDTC="Start Date/Time of Medication"
CMENDTC="End Date/Time of Medication"
CMENRF="End Relative to Reference Period";

studyid=sdyid;
domain="CM";
subjid=subjid;
siteid=substr(put(subjid,best4.),1,2);
usubjid=catx("-",sdyid,siteid,subjid);
retain cmseq 0;
by subjid;
if first.subjid then cmseq=1;
else cmseq=cmseq+1;
cmtrt=cmterm;
cmdostxt=put(dose, best.);
if unit=1 then cmdosu ="mg";
else if unit=2 then cmdosu="mg/kg";
else if unit=3 then cmdosu="mcg";
else if unit=4 then cmdosu="international units";
else if unit=5 then cmdosu="tablet";
else if unit=6 then cmdosu="table spoon";
else if unit=7 then cmdosu="other";
if freq=1 then cmdosfrq="1 time dose";
else if freq=2 then cmdosfrq="2 doses";
else if freq=3 then cmdosfrq="2 times a day";
else if freq=4 then cmdosfrq="3 times a day";
else if freq=5 then cmdosfrq="3 times a week";
else if freq=6 then cmdosfrq="4 times a day";
else if freq=7 then cmdosfrq="as needed";
else if freq=8 then cmdosfrq="every 3 hours";
else if freq=9 then cmdosfrq="every 4 hours";
else if freq=10 then cmdosfrq="every 4 weeks";
else if freq=11 then cmdosfrq="every 6 hours";
else if freq=12 then cmdosfrq="every morning";
else if freq=13 then cmdosfrq="every night";
else if freq=14 then cmdosfrq="every other day";
else if freq=15 then cmdosfrq="once a day";
else if freq=16 then cmdosfrq="once a month";
else if freq=17 then cmdosfrq="once a week";
else if freq=18 then cmdosfrq="other";
if route=1 then cmroute="oral";
else if route=2 then cmroute="IV";
else if route=3 then cmroute="IM";
else if route=4 then cmroute="NASAL";
else if route=5 then cmroute="TOPICAL";
if length(cmstdt) = 4 then cmstdtc = put(input(catt('01', 'JAN', cmstdt),date9.),yymmdd10.);
else if length(cmstdt) = 7 then cmstdtc =put(input( catt('01', cmstdt),date9.),yymmdd10.);
else cmstdtc=put(input(cmstdt,date9.),yymmdd10.);
if length(cmendt)=4 then cmendtc=put(input(catt('31','DEC',cmendt),date9.),yymmdd10.);
else if length(cmendt)=7  then cmendtc = put(intnx('month',input(cmendt,anydtdte.),0,'e'),yymmdd10.);
else cmendtc = put(input(cmendt,date9.),yymmdd10.);
run;

data demo;
set crfdata.dm;
keep subjid rfstdtc rfendtc;
run;
proc sort data=demo;
by subjid;
run;
data final;
merge new1(in=a) demo(in=b);
by subjid;
if a and b;
run;
libname sdtm "C:\Documents\SDTM";
data sdtm.Cm;
set final;
if cmstdtc > rfstdtc then cmenrf= "After";
else if cmendtc < rfstdtc then cmenrf="Before";
else cmenrf="Ongoing";
keep STUDYID DOMAIN USUBJID SUBJID SITEID CMSEQ CMTRT CMDOSTXT CMDOSU CMDOSFRQ CMROUTE CMSTDTC CMENDTC CMENRF ;
run;

libname xpt xport "C:\Documents\CRF data\xpt\cm.xpt";
data xpt.cm;
set sdtm.cm;
run;
