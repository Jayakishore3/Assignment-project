


proc sort data=crfdata.ie out=incexc;
by sdyid subjid;
run;

data inex;
length ietest $200;
set incexc;
studyid=sdyid;
siteid=put(invid,best.);
usubjid=catx("-",studyid,siteid,subjid);
by subjid;
retain ieseq 0;
if first.subjid then ieseq=1;
else ieseq=ieseq+1;
iespid=substr(iecritcd,4,2);
ietestcd=iecritcd;
if iecritcd="INC01" then ietest="Diagnosed with DM2";
if iecritcd="INC02" then ietest="HbA1c of 7.1% to 11.0%";
if iecritcd="INC03" then ietest="BMI of 25kg/m2 to 45 kg/m2";
if iecritcd="INC04" then ietest="Has been treated with Diet and Excercise alone or in combination with stable regimen";
if iecritcd="INC05" then ietest="Either is not treated with or treated with stable regimen with any of following medications";
if iecritcd="EXC01" then ietest="Has ever been exposed to any glycogen like peptide-1 (GLP-1) analog";
if iecritcd="EXC02" then ietest="Has received any investigational drug within one month of screening";
if iecritcd="EXC03" then ietest="Has been treated or treating or undergo treatment with any of following treatment medications";
if ietestcd="INC01" or ietestcd="INC02" or ietestcd="INC03" or ietestcd="INC04" or ietestcd="INC05" then iecat="INCLUSION";
else iecat="EXCLUSION";
ieorres=ieres;
iestresc=ieres;
iedtc=put(iedt,yymmdd10.);
run;

proc sort data=inex out=inex1;
by studyid subjid ;
run;

proc sort data=crfdata.visit out=visit1;
by sdyid subjid;
run;

data ine;
merge inex1(in=a) visit1(in=b);
if a and b;
retain visitnum;
by subjid;
if first.subjid and visdt=iedt then visitnum=visit;
output;
run;
proc sort data=ine out=abc;
by subjid ieseq;
run; 

data final;
set abc;
by subjid ieseq;
if first.subjid or first.ieseq;
run;

proc sort data=final out=final1;
by subjid;
run;
proc sort data=crfdata.dm out=demo;
by subjid;
run;

libname sdtm "C:\Documents\SDTM";
options validvarname=upcase;

data sdtm.Ie;
retain STUDYID DOMAIN USUBJID IESEQ IESPID IETESTCD IETEST IECAT IEORRES IESTRESC VISITNUM IEDTC IEDY;
length STUDYID $20 DOMAIN $2  IESEQ 8  IETESTCD $8  IECAT $20 IEORRES $8 IESTRESC $8 VISITNUM 8 IEDTC $10 IEDY 8;
label STUDYID="Study Identifier"
DOMAIN="Domain Abbreviation"
USUBJID="Unique Subject Identifier"
IESEQ="Sequence Number"
IESPID="Sponsor-Defined Identifier"
IETESTCD="Inclusion/Exclusion Criterion Short Name"
IETEST="Inclusion/Exclusion Criterion"
IECAT="Inclusion/Exclusion Category"
IEORRES="I/E Criterion Original Result"
IESTRESC="I/E Criterion Result in Std Format"
VISITNUM="Visit Number"
IEDTC="Date/Time of Collection"
IEDY="Study Day of Collection ";
merge final1(in=a) demo(in=b);
by subjid;
if a and b;
iedy=iedt-input(rfstdtc,yymmdd10.);
domain="IE";
keep STUDYID DOMAIN USUBJID IESEQ IESPID IETESTCD IETEST IECAT IEORRES IESTRESC VISITNUM IEDTC IEDY;
run;

libname xpt xport "C:\Documents\CRF data\xpt\ie.xpt";
data xpt.ie;
set sdtm.ie;
run;
