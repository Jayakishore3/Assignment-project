
proc sort data=crfdata.consent out=rawinf;
by sdyid subjid;
run;
data infc;
set rawinf;
where icyn=1 ;
run;
data inf;
length dsterm dsdecod dscat $200;
set infc(rename=(sdyid=studyid));
dsterm="INFORM CONSENT OBTAINED";
dsdecod="INFORM CONSENT OBTAINED";
dscat="PROTOCOL MILESTONE";
DSSTDTC=put(icdt,yymmdd10.);
drop invid icyn icdt;
run;
proc sort data=crfdata.ie out=rawie;
by sdyid subjid;
run;
data ie;
length dsterm dsdecod dscat $200;
set rawie(rename=(sdyid=studyid));
if IECRITCD in ('INC01','INC02','INC03','INC04','INC05') and IERES='Y' or
IECRITCD in ('EXC01','EXC02','EXC03') and IERES='N' then do;
DSTERM = 'ELIGIBILITY CRITERIA MET';
DSDECOD = 'ELIGIBILITY CRITERIA MET';
end;
else if IECRITCD in ('INC01','INC02','INC03','INC04','INC05') and IERES='N' or
IECRITCD in ('EXC01','EXC02','EXC03') and IERES='Y' then do;
DSTERM = 'ELIGIBILITY CRITERIA NOT MET';
DSDECOD = 'ELIGIBILITY CRITERIA NOT MET';
end;
DSCAT = 'PROTOCOL MILESTONE';
DSSTDTC = put(iedt,yymmdd10.);
if first.subjid;
by subjid;
drop invid ieres iecritcd iedt;
run;

proc sort data=crfdata.rand out=rawrand;
by sdyid subjid;
run;
data randomisation;
length dsterm dsdecod dscat $200;
set rawrand (rename=(sdyid=studyid));
where randyn=1;
dsterm="RANDOMIZED";
dsdecod="RANDOMIZED";
dscat="PROTOCOL MILESTONE";
dsstdtc=put(randdt,yymmdd10.);
drop invid randyn visit randdt;
run;

proc sort data=crfdata.expo out=rawexpo;
by sdyid;
run;
data exposure;
length dsterm dsdecod dscat $200;
set rawexpo (rename=(sdyid=studyid));
by subjid;
if first.subjid;
where exstdt ne .;
dsterm="ENTERED INTO TRIAL";
dsdecod="ENTRY INTO TRIAL";
dscat="PROTOCOL MILESTONE";
dsstdtc=put(exstdt,yymmdd10.);
drop invid visit retrndt disp type retrn kitnum exstdt;
run;

data rawds;
set crfdata.disposit;
where aeid ne .;
by sdyid subjid aeid;
run;

data rawae;
set crfdata.ae;
by sdyid subjid aeid;
run;

data new(rename=(sdyid=studyid));
merge rawds(in=a) rawae(in=b);
if pterm ne " " then do dstterm= pterm;dsdecod="ADVERSE EVENT";dscat="DISPOSITION EVENT";end;
else do dstterm="ADVERSE EVENT";dsdecod="ADVERSE EVENT";dscat="DISPOSITION EVENT";end;
by sdyid subjid aeid;
if a;
run;

data dsr;
length dsterm dsdecod dscat $200;
set crfdata.disposit(rename=(sdyid=studyid)) new ;
by studyid subjid aeid;
if ds=0 then do dsterm="COMPLETED"; dsdecod="COMPLETED";dscat="DISPOSITION EVENT";end;
else if ds=1 then do dsterm="Protocol Entry Criterion Not Met"; dsdecod="SCREEN FAILURE";dscat="DISPOSITION EVENT";end;
else if ds=3 then do dsterm="SUBJECT MOVED"; dsdecod="LOST TO FOLLOW UP";dscat="DISPOSITION EVENT";end;
else if ds=4 then do dsterm="PROTOCOL VIOLATION"; dsdecod="PROTOCOL VIOLATION";dscat="DISPOSITION EVENT";end;
else if ds=5 then do dsterm="PHYSICIAN DECISION"; dsdecod="PHYSICIAN DECISION";dscat="DISPOSITION EVENT";end;
else if ds=6 then do dsterm="SPONSOR REQUEST"; dsdecod="SPONSOR REQUEST";dscat="DISPOSITION EVENT";end;
else if ds=7 then do dsterm="SUBJECT DECISION"; dsdecod="SUBJECT DECISION";dscat="DISPOSITION EVENT";end;
else if ds=8 then do dsterm="DEATH DUE TO STUDY DISEASE"; dsdecod="DEATH";dscat="DISPOSITION EVENT";end;
else if ds=9 then do dsterm="DEATH DUE TO PROCEDURAL RELATED"; dsdecod="DEATH";dscat="DISPOSITION EVENT";end;
else if ds=10 then do dsterm="DEATH DUE TO ADVERSE EVENT"; dsdecod="DEATH";dscat="DISPOSITION EVENT";end;
else do dsterm=dstterm;end;
dsstdtc=put(disdt,yymmdd10.);
keep  studyid subjid dsterm dsdecod dscat dsstdtc;
run;

proc sort data=inf out=inffinal;
by studyid;
run;
proc sort data=ie out=iefinal;
by studyid;
run;
proc sort data=randomisation out=randfinal;
by studyid;
run;
proc sort data=exposure out=exposurefinal;
by studyid;
run;
proc sort data=dsr out=dispositfinal;
by studyid subjid;
run;
data disposition;
set inffinal iefinal randfinal exposurefinal dispositfinal ;
by studyid subjid;
run;
data dsp;
length epoch $20;
keep  studyid subjid dsterm dsdecod dscat dsstdtc epoch;
merge disposition(in=a) crfdata.dm(in=b);
by studyid subjid;
if a and b;
if dsstdtc <rfendtc then Epoch="SCREENING";
if rfstdtc<=dsstdtc<=rfendtc then epoch="TREATMENT";
if dsstdtc>rfendtc then epoch="FOLLOW UP";
run;


libname sdtm "C:\Documents\SDTM";
options validvarname=upcase;
data sdtm.Ds ;retain studyid domain  usubjid dsseq dsterm dsdecod dscat dsscat epoch dsstdtc;
set dsp ;
length  domain $2 usubjid $25 dsseq 8  ;
label STUDYID="Study Identifier"
DOMAIN="Domain Abbreviation"
USUBJID="Unique Subject Identifier"
DSSEQ="Sequence Number"
DSTERM="Reported Term for the Disposition Event"
DSDECOD="Standardized Disposition Term"
DSCAT="Category for Disposition Event"
DSSCAT="Subcategory for Disposition Event"
EPOCH="Epoch"
DSSTDTC="Start Date/Time of Disposition Event";
domain="DS";
siteid=substr(put(subjid,best4.),1,2);
usubjid=catx("-",studyid,siteid,subjid);
if dsterm = " " then delete;
by subjid;
retain dsseq 0;
if first.subjid then dsseq=1;
else do dsseq=dsseq+1;end;
if dscat="DISPOSITION EVENT" then dsscat="STUDY PARTICIPATION";
else dsscat=" ";
keep studyid domain  usubjid dsseq dsterm dsdecod dscat dsscat epoch dsstdtc;
run;

libname xpt xport "C:\Documents\CRF data\xpt\ds.xpt";
data xpt.ds;
set sdtm.ds;
run;
