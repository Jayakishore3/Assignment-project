libname crfdata "C:\Documents\CRF data";
options validvarname=upcase;
/*data that can be collected from CRF*/

data DM1;
set crfdata.dm;
length studyid $10 domain $2 usubjid $20 subjid 8 siteid $2 brthdtc $10
sex $1 race $35 ethnic $35;
keep studyid domain usubjid subjid siteid brthdtc sex race ethnic; 
studyid=sdyid;
domain="DM";
siteid=substr(put(subjid,best4.),1,2);
usubjid=catx("-",sdyid,siteid,subjid);
brthdtc=put(dob,yymmdd10.);
if racecd=1 then race="American Indian or Alaska native";
else if racecd=2 then race="Black or African American";
else if racecd=3 then race="Native Hawaian or other Pacific islander";
else if racecd=4 then race="White";
else if racecd=5 then race="Asian";
else if racecd=6 then race="Unknown";
if ethniccd=1 then ethnic="hispanic or Latino";
else if ethniccd=2 then ethnic="Not Hispanic or Latino";
else if ethniccd=3 then ethnic="Unknown";
else if ethniccd=4 then ethnic="Not reported";
run;


/*Exposure domain*/


data dm2;
set crfdata.expo;
if not missing(exstdt) then
rfstdtc = put(exstdt,yymmdd10.);
else rfstdtc =put( retrndt,yymmdd10.);
by subjid;
if first.subjid;
rfxstdtc=rfstdtc;
keep subjid rfstdtc rfxstdtc;
run;

data dm3;
set crfdata.expo;
if not missing(retrndt) then rfendtc=put(retrndt,yymmdd10.);
by subjid;
if last.subjid;
rfxendtc=rfendtc;
keep subjid rfendtc rfxendtc;
run;

/*consent*/

data dm4;
set crfdata.consent;
if icyn=1 then rficdtc=put(icdt,yymmdd10.);
keep subjid rficdtc;
run;

/*disposition and ae*/
proc sort data=crfdata.disposit;
by sdyid subjid;
run;
data dm5;
set crfdata.disposit;
where ds in (8,9,10);
if not missing(disdt) then dthdtc=put(disdt,yymmdd10.);
run;

data dm6;
set crfdata.ae;
where crit5=1;
if not missing (aeendt) then dthdtc=put(aeendt,yymmdd10.);
run;

data dthdtc;
merge dm5 dm6;
by subjid;
dthfl="Y";
keep sdyid subjid dthdtc dthfl;
run;


/*visit*/

data dm7;
set crfdata.visit dthdtc;
if not missing (visdt)then RFPENDTC=put(visdt,yymmdd10.);
else if missing (rfpendtc) and not missing (dthdtc) then rfpendtc=dthdtc;
by subjid;
if last.subjid;
keep sdyid subjid rfpendtc;
run;



/*age and units*/
data agey;
merge dm1 dm4;
by subjid;;
if not missing(RFICDTC) and not missing(BRTHDTC) then
AGE=int((input(RFICDTC,yymmdd10.)-input(BRTHDTC,yymmdd10.))/365.25);
if not missing (age) then AGEU="YEARS";
keep subjid age ageu;
run;

/*dosing and rand*/
data  dose;
merge crfdata.dosing  crfdata.rand;
by subjid;
length ARMCD $20;
if trtgroup=1 then ARMCD='placebo';
else if trtgroup=2 then ARMCD='dcds01-20mg';
else if trtgroup=3 then ARMCD='dcds01-40mg';
else if trtgroup=.  then ARMCD='notassign';
else if missing (randdt) then armcd = 'NOTASSIGN';
/* Check CRF>IE dataset conditions */
/*if not missing(iecritcd) and*/
/*((iecritcd = 'INC' and ieres = 'N') or (iecritcd = 'EXCL' and ieres = 'Y')) then*/
/*armcd = 'SCRNFAIL';*/
if trtgroup=1 then ARMCD='placebo';
else if trtgroup=2 then ARMCD='dcds01-20mg';
else if trtgroup=3 then ARMCD='dcds01-40mg';
else if trtgroup=.  then ARMCD='notassign';
else if missing (randdt) then armcd = 'NOTASSIGN';
if armcd='SCRNFAIL' then ARM="Screen Failure";
actarmcd=armcd;
keep subjid armcd;
run;

/*Merging all the datasets to make DM dataset*/

data demo (label=Demographics);
merge dm1 dm2 dm3 dm4 dthdtc dm7 agey dose;
by subjid;
run;
data demo1;
retain STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC 
RFICDTC RFPENDTC DTHDTC DTHFL SITEID BRTHDTC AGE AGEU SEX RACE ETHNIC ARMCD ARM;
set demo;
run;

/*directing to sdtm library and labels for variables*/
libname sdtm "C:\Documents\SDTM";
proc sql;
create table sdtm.DM as select
STUDYID "Study Identifier" length=10,
DOMAIN "Domain Abbreviation" length=2,
USUBJID "Unique Subject Identifier" length=20,
SUBJID "Subject Identifier for the Study" length=8,
RFSTDTC "Subject Reference Start Date/Time" length=10,
RFENDTC "Subject Reference End Date/Time" length=10,
RFXSTDTC "Date/Time of First Study Treatment" length=10,
RFXENDTC "Date/Time of Last Study Treatment" length=10,
RFICDTC "Date/Time of Informed Consent" length=10,
RFPENDTC "Date/Time of End of Participation" length=10,
DTHDTC "Date/Time of Death" length=10,
DTHFL "Subject Death Flag" length=10,
SITEID "Study Site Identifier" length=8,
BRTHDTC "Date/Time of Birth" length=10,
AGE "Age" length=8,
AGEU "Age Units" length=8,
SEX "Sex" length=8,
RACE "Race" length=100,
ETHNIC "Ethnicity" length=100,
ARMCD "Planned Arm Code" length=100
from demo1;
quit;

/*converting to xpt format*/
libname xpt xport "C:\Documents\CRF data\xpt\dm.xpt";
data xpt.DM;
set sdtm.DM;
run;













