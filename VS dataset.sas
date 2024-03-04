libname sdtm "C:\Documents\SDTM";
proc sort data=crfdata.vitals out=raw;
by sdyid subjid visit;
run;

proc transpose data=raw out=vital;
by subjid visit;
var temp sysbp diabp pulse ;
run;
data new;
length vstestcd $8 vstest $45 vsorresu $20;
merge vital(in=a) raw(in=b);
by subjid visit;
if a and b;
if _name_="temp" then vstestcd="TEMP";
else if _name_="sysbp" then vstestcd="SYSBP";
else if _name_="diabp" then vstestcd="DIABP";
else if _name_="pulse" then vstestcd="PULSE";
if vstestcd="TEMP" then vstest="Temperature";
else if vstestcd="SYSBP" then vstest="Systolic Blood Pressure";
else if vstestcd="DIABP" then vstest="Diastolic Blood Pressure";
else if vstestcd="PULSE" then vstest="Pulse Rate";
vsorres=col1;
if vstestcd="TEMP" then units=tempu;
else if vstestcd="DIABP" then units=bpu;
else if vstestcd="SYSBP" then units=bpu;
else if vstestcd="PULSE" then units=pulseu;
if units="degree C" then vsorresu="C";
else if units="mmHg" then vsorresu="mmHg";
else if units="bpm" then vsorresu="beats/min";
vsstresc=vsorres;
vsstresn=vsorres;
vsstresu=vsorresu;
if vsorres ne . then vsstat=" ";
else vsstat="Not Done";
visitnum=visit;
vsdtc=catx("T",put(vsdt,yymmdd10.),put(vstm,time5.));
keep subjid vstestcd vstest vsorres vsorresu vsstresc vsstresn vsstresu vsstat visitnum vsdtc;
run;

data sdtm.Vs; 
retain STUDYID DOMAIN USUBJID VSSEQ VSTESTCD VSTEST VSORRES VSORRESU VSSTRESC VSSTRESN VSSTRESU VSSTAT VISITNUM VSDTC;
merge raw(in=a) new(in=b);
by subjid ;
if a;
label STUDYID="Study Identifier"
DOMAIN="Domain Abbreviation"
USUBJID="Unique Subject Identifier"
VSSEQ="Sequence Number"
VSTESTCD="Vital Signs Test Short Name"
VSTEST="Vital Signs Test Name"
VSORRES="Result or Finding in Original Units"
VSORRESU="Original Units"
VSSTRESC="Character Result/Finding in Std Format"
VSSTRESN="Numeric Result/Finding in Standard Units"
VSSTRESU="Standard Units"
VSSTAT="Completion Status"
VISITNUM="Visit Number"
VSDTC="Date/Time of Measurements";
length usubjid $20 ;
studyid=sdyid;
domain="VS";
siteid=substr(put(subjid,best4.),1,2);
usubjid=catx("-",studyid,siteid,subjid);
retain vsseq 0;
if first.subjid then vsseq=1;
else do vsseq=vsseq+1;end;
keep STUDYID DOMAIN USUBJID VSSEQ VSTESTCD VSTEST VSORRES VSORRESU VSSTRESC VSSTRESN VSSTRESU VSSTAT VISITNUM VSDTC;
run;

libname xpt xport "C:\Documents\CRF data\xpt\vs.xpt";
data xpt.vs;
set sdtm.vs;
run;
