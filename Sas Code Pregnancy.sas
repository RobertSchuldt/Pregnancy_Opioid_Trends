*Work on Pregnancy and Opioid Utilization. **;

libname clms 'R:\PharMetrics LifeLink+ (2015)\claims - medical - inpatient';
libname paper 'R:\GraduateStudents\SchuldtRobertF\paper';
libname pharm 'R:\PharMetrics LifeLink+ (2015)\claims - retail pharmacy';
libname enroll 'R:\PharMetrics LifeLink+ (2015)\enrollment';
libname outpat 'R:\PharMetrics LifeLink+ (2015)\claims - medical - outpatient';
libname project 'R:\GraduateStudents\Student Project #2\Project';
libname amy 'R:\GraduateStudents\Student Project #2\Amy-Data';
libname ndc 'R:\GraduateStudents\Student Project #2\NDC_codes';

**tested the initial grab for deliveries. Now need to develop macro for all data sets**;
proc options option = macro;
run;

data shellset;
	set clms.clm_inpat_2015 (obs = 1) ; 
	delivery = 0;
	exclude =0;
	source = '                                             ';

%macro yearin(sasset);
	data bringin;
		set &sasset;
			 array icd9 (12) diag1-diag11 diag_admit;
				do i = 1 to 12;
					if substr(icd9(i), 1, 3) = 'V27' then delivery = 1;
					if substr(icd9(i), 1, 3) = '650' then delivery = 1;
						if substr(icd9(i), 1, 3) = '630' then exclude = 1;
							if substr(icd9(i), 1, 3) = '631' then exclude = 1;
							if substr(icd9(i), 1, 3) = '633' then exclude = 1;
							if substr(icd9(i), 1, 3) = '632' then exclude = 1;
							if substr(icd9(i), 1, 3) = '634' then exclude = 1;
							if substr(icd9(i), 1, 3) = '635' then exclude = 1;
							if substr(icd9(i), 1, 3) = '636' then exclude = 1;
							if substr(icd9(i), 1, 3) = '637' then exclude = 1;
							if substr(icd9(i), 1, 3) = '638' then exclude = 1;
							if substr(icd9(i), 1, 3) = '639' then exclude = 1;
							if substr(icd9(i), 1, 4) = '6901' then exclude = 1;
							if substr(icd9(i), 1, 3) = '750' then exclude = 1;
							if substr(icd9(i), 1, 4) = '6951' then exclude = 1;
							if substr(icd9(i), 1, 4) = '7491' then exclude = 1;
								end;
									source = "&sasset";

	data deliveries;
	set bringin;
	if delivery = 1;

	proc sort;
	by pat_id;

	data deliverysort;
	set deliveries; 
	proc append base = shellset data = deliverysort force;

%mend yearin;

%yearin(clms.clm_inpat_2006)
%yearin(clms.clm_inpat_2007)
%yearin(clms.clm_inpat_2008)
%yearin(clms.clm_inpat_2009)
%yearin(clms.clm_inpat_2010)
%yearin(clms.clm_inpat_2011)
%yearin(clms.clm_inpat_2012)
%yearin(clms.clm_inpat_2013)
%yearin(clms.clm_inpat_2014)
%yearin(clms.clm_inpat_2015)


run;
**Saved our dataset into our director**; 
data project.delivered;
	set shellset;
	where delivery = 1;
		run;
*** Now we exclude those patients who had excludible patient conidtions**;
proc freq data = project.delivered;
table exclude;
run;
title "Number of excluded pregnancies due to ICD9 codes";

data exclude;
	set project.delivered;
	where delivery = 1;
	if exclude = 1 then delete;
run;
** THis generates a total count of pregnancies that we have that are valid**;
proc sort data= exclude out= sorted;
by pat_id from_dt; 
run;

proc sort data = sorted nodupkey;
by conf_num;
run;

title' Check total number of deliveries';
proc freq data = sorted;
table delivery;
run;

**Counting number of deliveries that each women had**;
data pregcount;
	set sorted;
		count = 1;
		idl = lag(pat_id);
			retain pregnum 1;
				if idl = pat_id then pregnum = pregnum +1;
					else pregnum = 1;
run;

proc freq data = pregcount;
table pregnum;
run;
title "Number of Pregnancy each patient has had";

data term;
	set pregcount;
		array icd9 (12) diag1-diag11 diag_admit;
				do i = 1 to 12;
					if substr(icd9(i), 1, 4) = '6440' then term = 0;
					if substr(icd9(i), 1, 4) = '6442' then  term = 0;
					if substr(icd9(i), 1, 3) = '765' then  term = 0;

				end;

				if term ne 0 then term = 1;
			run;
proc format;
value termtype
0 = "Pre-Term"
1 = "Term"
;
run;
title ' Pre-term or Full-term pregnancies';
proc freq data = term;
table term;
where pregnum= 1;
format term termtype.;
run;

data edc;
	set term;
deliver_date = from_dt;
if term = 0 then edc_index_date = from_dt - 245;
if term = 1 then edc_index_date = from_dt - 270;

format deliver_date mmddyy8.;
format edc_index_date mmddyy8.;

run;
proc sort data = edc;
by pat_id;
run;

**WE Want to keep all records regardless of number of births in our new data set. However, do we don't want;
**Other patients coming into the new data set. A 1 to M match**;

data insurance;
	merge enroll.uark1986_enroll (in = a) edc (in = b);
	by pat_id;
	if b;
	run;

**Setting our index dates from where we need to calculate our coverage of patients**;
**we subtracted 7 months from EDC so we start looking 1 month before the pregnancy begins for usage**;

data prepostdate;
	set insurance;
	pre6 = edc_index_date -210;
	format pre6 mmddyy8.;
run;

data insurancecont;
	set prepostdate;

	**Pre year index position for estrng**;

	preyearindex = year(pre6);
	premoindex = month(pre6);
	preyrs1995 = preyearindex - 1995;
	preyrsmonth =preyrs1995*12;
	preyrmonthindex = preyrsmonth+premoindex;

***calculating index for delivery date;

	delyearindex = year(deliver_date);
	delmoindex = month(deliver_date);
	delyrs95 = delyearindex - 1995;
	delyrsmonth = delyrs95*12;
	delmonthindex = delmoindex+delyrsmonth;

run;
 **Now calculate the months needed to be eligible**;

data monthnumbers;
	set insurancecont;
	totalmonths = delmonthindex - preyrmonthindex;
run;

proc freq;
table totalmonths;
run;

data cont;
	set monthnumbers;
	 if substr(estring, preyrmonthindex, 14) = 'XXXXXXXXXXXXXX' then contelig = 1;
	 if substr(estring, preyrmonthindex, 15) = 'XXXXXXXXXXXXXXX' then contelig = 1;
	 if substr(estring, preyrmonthindex, 16) = 'XXXXXXXXXXXXXXXX' then contelig = 1;
	 if contelig ne 1 then contelig = 0;
	 

	run;
proc format;
value cont
1 = "Continous Coverage"
0 = "Not Continous"
;
run;

title' How many patients have continuous coverage between pre and post period';
proc freq;
table contelig;
format contelig cont.;
run;

data contpop;	
	set cont;
	where contelig = 1 and pregnum = 1;
run;
title 'test to make sure we have one first pregnancy patient id';
proc freq;
table pregnum;
run;

proc options option = macro;
run;
***this is being used to generate a list of those who have inpatient diagnosis of opioid abuse disorders**;
data abuseshellset;
	set clms.clm_inpat_2015 (obs = 1) ; 
	abuse = 0;
	source = '                                             ';

%macro yearin(sasset);
	data bringin;
		set &sasset;
			 array icd9 (12) diag1-diag11 diag_admit;
				do i = 1 to 12;
					if substr(icd9(i), 1, 4) = '3040' then abuse = 1;
					if substr(icd9(i), 1, 4) = '3047' then abuse = 1;
					if substr(icd9(i), 1, 4) = '3055' then abuse = 1;
								end;
									source = "&sasset";

	data abuse;
	set bringin;
	if abuse = 1;

	proc sort;
	by pat_id;

	data abusesort;
	set abuse; 
	proc append base = abuseshellset data = abusesort force;

%mend yearin;

%yearin(clms.clm_inpat_2006)
%yearin(clms.clm_inpat_2007)
%yearin(clms.clm_inpat_2008)
%yearin(clms.clm_inpat_2009)
%yearin(clms.clm_inpat_2010)
%yearin(clms.clm_inpat_2011)
%yearin(clms.clm_inpat_2012)
%yearin(clms.clm_inpat_2013)
%yearin(clms.clm_inpat_2014)
%yearin(clms.clm_inpat_2015)


run;
***this is being used to generate a list of those who have outpatient diagnosis of opioid abuse disorders**;
data abuseshellset2;
set outpat.clm_outpat_2015 (obs = 1); 
abuse = 0;
source ='                               ';

%macro yearin(sasset);
	data bringin;
		set &sasset;
			 array icd9 (12) diag1-diag11 diag_admit;
				do i = 1 to 12;
					if substr(icd9(i), 1, 4) = '3040' then abuse = 1;
					if substr(icd9(i), 1, 4) = '3047' then abuse = 1;
					if substr(icd9(i), 1, 4) = '3055' then abuse = 1;
								end;
									source = "&sasset";

	data abuse2;
	set bringin;
	if abuse = 1;

	proc sort;
	by pat_id;

	data abusesort2;
	set abuse2; 
	proc append base = abuseshellset2 data = abusesort2 force;

%mend yearin;

%yearin(outpat.clm_outpat_2006)
%yearin(outpat.clm_outpat_2007)
%yearin(outpat.clm_outpat_2008)
%yearin(outpat.clm_outpat_2009)
%yearin(outpat.clm_outpat_2010)
%yearin(outpat.clm_outpat_2011)
%yearin(outpat.clm_outpat_2012)
%yearin(outpat.clm_outpat_2013)
%yearin(outpat.clm_outpat_2014)
%yearin(outpat.clm_outpat_2015)


run;
**Hard save outpatient abuse diagnosis**;
data project.outpatabuse;
set abuseshellset2;
abusediag_dt = from_dt;
run;

proc sort data = project.outpatabuse nodupkey;
by pat_id abusediag_dt;
run;
proc sort data = project.outpatabuse nodupkey;
by pat_id;
run;

*hard save of inpatient abuse diagnosis**;
data project.inpatabuse;
set amy.dxabuseinptall;
abusediag_dt = from_dt;
run;

proc sort data = project.inpatabuse nodupkey;
by pat_id abusediag_dt;
run;
proc sort data = project.inpatabuse nodupkey;
by pat_id;
run;
*** Now stack the inpatient and outpatient data only keeping variables that help identify the diagnosis**;
data project.allabuse;
	set project.outpatabuse
	project.inpatabuse;
	keep pat_id diag1-diag11 diag_admit abusediag_dt abuse;
	run;

**Sorted and deduped the data***;

	proc sort data= project.allabuse out= project.abusesorted nodupkey;
	by pat_id abusediag_dt;
	run;

	proc sort data = project.abusesorted nodupkey;
	by pat_id;
	run;


**Now I check to make sure we only have 1 pat_id**;


data project.abusepreg;
	merge contpop (in=a) project.abusesorted (in= b);
	by pat_id;
	if a;
	run;

proc freq data = project.abusepreg;
table abuse;
run;

data noabuse;
set project.abusepreg;
if abuse ne 1 then abuse = 0;
if abusediag_dt <= edc_index_date then abuse_period = 1;
if abusediag_dt > edc_index_date and abusediag_dt < deliver_date then abuse_period = 2;
if abusediag_dt >= deliver_date then abuse_period = 3;
if abuse= 0 then abuse_period = 0;
run;

proc format;
value period

0 = 'Never Diag Abuse Disorder'
1 = 'Diag Pre EDC'
2 = 'Diag during pregnancy'
3 = 'Diag after delivery'
;
run;

proc freq;
table abuse_period;
format abuse_period period.;
run;


data RXinsurance;
merge noabuse(in=a) enroll.uark1986_enroll2_addon (in=b);
by pat_id; 
if a; *keeping all records for first deliveries in women with continuou medical insurance coverage.;
run;

data RXInsurance2;
set RXinsurance;
where string_type='der_ben_rx';
run;

data ContinuousRX;
set RXinsurance2;
ContEligRx = 0;
if substr(string_value, preyrmonthindex, 14) = 'YYYYYYYYYYYYYY' then ContEligRX= 1;
if substr(string_value, preyrmonthindex, 15) = 'YYYYYYYYYYYYYYY' then ContEligRX= 1;
if substr(string_value, preyrmonthindex, 16) = 'YYYYYYYYYYYYYYYY' then ContEligRX = 1;
run;

proc freq;
table conteligrx*abuse_period;
run;
**Saving only those with continous coverage of both pharma and insurance with our periods **;

data project.fullsample;
set ContinuousRX;
where ContEligRX= 1;
run;

proc freq data = project.fullsample;
table delivery;
where abuse_period ne 1;
run;
data drugfromrename;
	set project.drugs;
	 script_dt = from_dt;
	 run;



data phmarmpreg;
	merge project.fullsample (in = a) drugfromrename (in = b);
	by pat_id;
	if a;
	run;

proc sort data = phmarmpreg out= idtest nodupkey;
by pat_id;
run;

proc freq data= idtest;
table delivery;
run;

data identify;
	set phmarmpreg;
	where abuse ne 1;
	if substr(gpi, 1, 2) = '65' then opioid = 1; *analgesics;
	if substr(gpi, 1, 4) = '6510' then opioid = 2; *agonist*;
	if substr(gpi, 1, 4) = '9340' then opioid = 3; *antagonist*;
	if substr(gpi, 1, 4) = '6599' then opioid = 4; *OpioidCombo*;
	if substr(gpi, 1, 5) = '43101' then opioid = 5; **tussive**;
	run;

data opioidmark;
	set identify;
	where opioid >0;
	scripttime = 0;
	if script_dt >= pre6 and < edc_index_date and opioid > 0 then scriptime = 1;
	if (script_dt >= edc_index_date and script_dt <= deliver_date ) and opioid > 0 then scriptime = 2;
	

	if script_dt < pre6 then outrange = 1;
	if script_dt > deliver_date then outrange = 1;
	run;


proc sort data = opioidmark out = idtest2 nodupkey;
by pat_id;
run;

proc freq data = idtest2;
table delivery;
run;	

data project.opioid;
set opioidmark;
where outrange ne 1;
run;
title 'Time frame of opioid prescriptions';
proc freq data=project.opioid;
table user*pat_region;
format user users.;
run;
proc freq;
table opioid drugs;
run;
 proc sort data = project.opioid out = idtest3 nodupkey;
 by pat_id;
 run;

 proc freq; 
 table delivery;
 run;

data project.fixloss;
merge project.fullsample (in = a) project.opioid (in = b);
by pat_id;
if a;
run;

proc sort data = project.fixloss out = idtest4 nodupkey;
by pat_id;
run;

proc freq data = idtest4;
table delivery;
run;
/*
data scriptcount;
	set project.opioid;
	where opioid = 1;
		count = 1;
		idl = lag(pat_id);
			retain scriptnum 1;
				if idl = pat_id  then scriptnum = scriptnum +1;
					else scriptnum = 1;

					run;
proc freq;
title 'How many scripts people got';
table scriptnum;
run;

proc sort data = scriptcount nodupkey;
by pat_id descending scriptnum;
run;

proc sort data = scriptcount out= perpat nodupkey;
by pat_id;
run;

proc freq data = perpat;
title 'How many scripts inidividuals got';
table scriptnum;
run;
**/
***Now need to identify atangonist and partial agonist stuff ;

proc format;
value typeopi
1 = "Analgesics"
2 = "Agonist"
3 = "Antagonist"
4 = "Opioid Combo"
;
run;

proc freq;
table opioid;
format opioid typeopi.;
run;

proc freq;
tables opioid*scripttime;
format opioid typeopi. ;
run;
proc means;
var quan;
run;

data datedrug;
	set project.fixloss;
		where abuse_period ne 1;
		kick = 0;
	if dayssup <= 0 and opioid > 0 then kick = 1;
	if quan <= 0 and opioid >0 then kick = 1;
	
		run;

proc sort data = datedrug out = idtest5 nodupkey;
by pat_id;
run;

proc freq data = idtest5;
table delivery;
run;


**We went through and  identified scripts with an unrealistic quantity. If the quaintity was negative
or was above a 3 months supply at 3 pills per day: 270 ;
proc freq;
table scriptime kick;
run;

proc freq;
tables opioid*scriptime;
format opioid typeopi. ;
where kick = 0;
run;

** only kicked out 1,000 opioid scripts, so most of our results are good.**;


data quansup;
	set datedrug;
	where kick = 0;
	
	run;
/*
proc freq;
table brand_name*gpi;
run;

*/

proc sort data = quansup out = idtest6 nodupkey;
by pat_id;
run;

proc freq data = idtest6;
table delivery*kick;
run;

data opioidkick;
	set quansup;

	exclusion = 0;
	if opioid = 3 and scriptime = 1 then exlusion = 1;
	if substr(gpi, 1, 10) = '6520004030' and scriptime = 1 then exlusion = 1; ** Naloxone;
	if substr(gpi, 1, 10) = '6520001020' and scriptime = 1 then exlusion = 1; **Naloxone-Bupre;
	if substr(gpi, 1, 10) = '6510005010' and scriptime = 1 then exlusion = 1; **Methadone;
	if substr(gpi, 1, 11) =  '65200010100' and scriptime = 1 then exlusion = 1; ** Buprenorphine;
	if substr(gpi, 1, 10) = '9340003000' and scriptime = 1 then exlusion = 1; **naltrexone;
	if substr(gpi, 1, 10) = '9668424000' and scriptime = 1 then exlusion = 1; **naltrexone;
	if substr(gpi, 1, 10) = '9340003010' and scriptime = 1 then exlusion = 1; **naltrexone;
	



	if opioid = 3 and scriptime = 1 then exlusion = 1;
	if substr(gpi, 1, 10) = '6520004030' and scriptime = 2 then develop = 1; ** Naloxone;
	if substr(gpi, 1, 10) = '6520001020' and scriptime = 2 then develop = 1; **Naloxone-Bupre;
	if substr(gpi, 1, 10) = '6510005010' and scriptime = 2 then develop = 1; **Methadone;
	if substr(gpi, 1, 11) = '65200010100' and scriptime = 2 then develop = 1; ** Buprenorphine;
	if substr(gpi, 1, 10) = '9340003000' and scriptime = 1 then exlusion = 1; **naltrexone;
	if substr(gpi, 1, 10) = '9668424000' and scriptime = 1 then exlusion = 1; **naltrexone;
	if substr(gpi, 1, 10) = '9340003010' and scriptime = 1 then exlusion = 1; **naltrexone;
		run;

proc freq data = opioidkick;
table exlusion;
run;

proc sort data = opioidkick out = idtest7 nodupkey;
by pat_id;
run;

proc freq data = idtest7;
table delivery;
run;




data opioidkickmerge;
set opioidkick;
	where exlusion = 1;
	run;

proc sort nodupkey;
by pat_id;
run;


data opioidkickmerge2;
	set opioidkickmerge;
	dropvar = exlusion;
	run;
data project.kickmerge;
merge opioidkick (in=a) opioidkickmerge2 (in = b);
by pat_id;
run;

data nopreabuse;
set project.kickmerge;
where dropvar ne 1 and opioid > 0;
run;





proc freq data =nopreabuse;
table scriptime;
run;	
** count totals person has taken in time frame**;
proc sql;
create table days as
	select *  , sum(case when scriptime = 1 then dayssup end) as predays, sum(case when scriptime = 2 then dayssup end) as dur_days
	from nopreabuse
	group by pat_id
	;
	quit;

**Create trimesters for women**;

data trimester;
	set days;
	f_trimster_m = edc_index_date+90;
	s_trimster_m = edc_index_date+180;
	if script_dt > edc_index_date and script_dt <= f_trimster_m then first_tri = 1;
	if script_dt > f_trimster_m and script_dt <= s_trimster_m then second_tri = 1;
	if script_dt > s_trimster_m then third_tri = 1;
	run;

proc freq data = trimester;
	table first_tri second_tri third_tri;
	run;

proc sql;
create table trimesterquan as
	select *  , sum(case when first_tri = 1 then dayssup end) as first_t_quan, sum(case when second_tri = 1 then dayssup end) as second_t_quan, sum(case when third_tri = 1 then dayssup end) as third_t_quan
	from trimester
	group by pat_id
	;
	quit;

**identify what type of user the person is**;
data project.fixloss2;

merge  trimesterquan (in = a) project.kickmerge (in = b);
where dropvar ne 1;
by pat_id;
if b;
run;

data usertype;
set project.fixloss2;
pre_user = 0;
dur_user = 0;
if predays >= 90 then pre_user = 1;
if predays <90 and predays > 0 then pre_user = 2;

if dur_days   >= 90 and term = 1 then dur_user = 1;
if dur_days   >= 90 and term = 0 then dur_user = 1;

if dur_days   < 90 and dur_days > 0 and term = 1 then dur_user = 2;
if dur_days   < 90 and dur_days > 0  and term = 0 then dur_user = 2;

run;

proc freq data = usertype;
table gen_nm;
where opioid gt 0 and pre_user >= 1;
run;

proc freq data = usertype;
table gen_nm;
where opioid gt 0 and dur_user >= 1;
run;


proc freq;
table pre_user dur_user;
run;

proc sort data = usertype out = cleaneddata nodupkey;
by pat_id;
run;
data deliveryear;
set cleaneddata;
	deliveryear=year(deliver_date);
	deliverage = deliveryear - der_yob;
	run;
proc means;
var deliverage;
run;
proc freq;
table deliverage;
run;
data ageclean;
set deliveryear;
where deliverage >= 12 and deliverage <=55;
run;

proc format;
value usertypes
0 = "No Use"
1 = "Chronic Use"
2 = "Intermittent Use"
;
run;

data project.finaldataset;
	set ageclean;
	run;






 /***
proc tabulate;
class deliveryear;
var pre_user dur_user post_user;
table pre_user*deliveryear dur_user*deliveryear post_user*deliveryear;
run;
**;**/
**Look at some freq tables;

proc freq;
table pre_user abuse_period*opioid;
run;

data groupopioids;
set project.finaldataset;
if pre_user >= 1 then pre_overall = 1;
else pre_overall = 0;
if dur_user >= 1 then dur_overall = 1;
else dur_overall = 0;
run;

data agerange;
	set project.finaldataset;
	if deliverage ge 12 and deliverage le 19 then age_cat = 1;
	if deliverage ge 20 and deliverage le 34 then age_cat = 2;
	if deliverage ge 35 then age_cat = 3;
proc format;
value ages
1 = "Ages 12-19"
2 = "Ages 20-34"
3 = "Ages 35+"
;
run;


proc sql;
create table statebirths as
	select *  , sum(delivery) as sumdeliver, sum(dur_overall) as stateusers
	from groupopioids 
	group by pat_state
	;
	quit;
proc freq;
table pat_state;
run;

data cleanupstate;
	set statebirths;
	if pat_state = "-" then delete;
	if pat_state = "13" then delete;
	if pat_state = "19" then delete;
	if pat_state = "ON" then delete;
	if pat_state = "01" then delete;
	if pat_state = " " then delete;
	if pat_state = "99" then delete;
	if pat_state = "AP" then delete;
run;

proc sql;
create table cleanupstate2 as
	select *  , sum(delivery) as totaldeliver
	from cleanupstate 
	group by pat_state
	;
	quit;
data percent;
	set cleanupstate2;
	percentbirth = (stateusers/ totaldeliver)*100;
	run;

	proc sort data = percent out= mapping nodupkey;
	by pat_state;
	run;

proc rank data=mapping out=project.quintiles groups=5;
 var percentbirth;
 ranks q;
run;
proc sort data = project.quintiles;
by q;
run;


proc means data = project.quintiles;
by q;
var percentbirth;
run;

proc freq;
table percentbirth;
run; 

proc means data = project.finaldataset;
var predays;
where predays ne 0;
run;

proc means data = project.finaldataset;
var dur_days;
where dur_days ne 0;
run;

** identify insurance type;




**identify movement between classes*;

data move_user;
set project.finaldataset;
if pre_user = 0 and dur_user = 0 then movement = 0; **Non to Non**;
if pre_user = 1 and dur_user = 0 then movement = 1; * Chronic to Non*;
if pre_user = 1 and dur_user = 1 then movement = 2; **Chronic to Chronics;
if pre_user = 1 and dur_user = 2 then movement = 3; **Chronic to Intermit;

if pre_user = 2 and dur_user = 0 then movement = 4; **inter to non;
if pre_user = 2 and dur_user = 1 then movement = 5; ** inter to chronics;
if pre_user = 2 and dur_user = 2 then movement = 6; **inter to inter;

if pre_user = 0 and dur_user = 1 then movement = 7; **non to chronic;
if pre_user = 0 and dur_user = 2 then movement = 8; ** non to inter;


run;
proc format;
value move

0 = "Non to Non"
1 = "Chronic to Non"
2 = "Chronic to Chronic"
3 = "Chronic to Intermit"
4 = "Intermit to Non"
5 = "Intermit to Chronic"
6 = "Intermit to Intermit"
7 = "Non to Chronic"
8 = "Non to Intermit"
;
run;


proc freq;
table movement;
format movement move.;
run;

*** set ages 5 year increments say for young**;

data age_set;
	set move_user;

	if deliverage >= 12 and deliverage lt 18 then age_cat = 1;
	if deliverage >= 18 and  deliverage <= 23 then age_cat = 2;
	if deliverage > 23 and deliverage <= 29 then age_cat = 3;
	if deliverage > 29 and deliverage <= 34 then age_cat = 4;
	if deliverage > 34 and deliverage <= 39 then age_cat = 5;
	if deliverage > 39 and deliverage <= 44 then age_cat = 6;
	if deliverage > 44 and deliverage <= 49 then age_cat = 7;
	if deliverage > 49 and deliverage <= 55 then age_cat = 8;

run;
proc format;
value age_c 
1 = "12 to 17"
2 = "18 to 23"
3 = "24 to 29"
4 = "30 to 34"
5 = "35 to 39"
6 = "40 to 44"
7 = "45 to 49"
8 = "50 to 55"
;
run;

proc freq;
table age_cat;
run;
*** identify insurance type**;

proc freq;
table pay_type product_type;
run;

proc sort data = age_set;
by pat_id;
run;

data overall;
	set age_set;

if pre_user >= 1 then pre_overall = 1;
else pre_overall = 0;
if dur_user >= 1 then dur_overall = 1;
else dur_overall = 0;
run;

data project.finalv2;
set overall;
run;



	

proc means;
var deliverage;
run;

proc freq data = agerange;
table pat_region;
run;

proc freq;
table pre_user dur_user deliveryear gen_nm;
run;

proc sort data = move_user;
by predays;
run;

***Gather insurance data**;

data insurance_type;
merge project.finalv2 (in = a) enroll.uark1986_enroll2;
by pat_id;
if a;
run;


data insurance_paytype;
set insurance_type
(keep = pat_id  string_type string_value delmonthindex);
where string_type = "pay_type";
if substr( string_value , delmonthindex, 1) = 'C' then insurtype = 1;
if substr( string_value, delmonthindex, 1) = 'K' then insurtype = 2;
if substr( string_value, delmonthindex, 1) = 'M' then insurtype = 3;
if substr( string_value, delmonthindex, 1) = 'R' then insurtype = 4;
if substr( string_value, delmonthindex, 1) = 'S' then insurtype = 5;
if substr( string_value, delmonthindex, 1) = 'T' then insurtype = 6;
run;

proc format;
value pay
1 = "Commercial"
2 = "SCHIP"
3 = "Medicaid"
4 = "Medicare Risk"
5 = "Self-insured"
6 = "Medi-Gap"
;
run;

proc freq; 
table insurtype;
run;


data insurance_prdtype;
set insurance_type
(keep = pat_id string_type string_value delmonthindex);
where string_type = "prd_type";
if substr( string_value, delmonthindex, 1) = 'D' then insurprd = 1;
if substr( string_value, delmonthindex, 1) = 'H' then insurprd = 2;
if substr( string_value, delmonthindex, 1) = 'I' then insurprd = 3;
if substr( string_value, delmonthindex, 1) = 'S' then insurprd = 4;
if substr( string_value, delmonthindex, 1) = 'P' then insurprd = 5;
if substr( string_value, delmonthindex, 1) = 'R' then insurprd = 6;
if substr( string_value, delmonthindex, 1) = 'U' then insurprd = 7;
run;

proc format;
value prd
1 = "Consumer Directed"
2 = "HMO"
3 = "Idemnity"
4 = "Point of Service"
5 = "PPO"
6 = "HSA"
7 = "other/unknown"
;
run;

data mergeinsurtype;
 merge project.finalv2 (in = a) insurance_paytype (in = b);
 by pat_id;
 if a ;
 run;

 
data mergeinsurprd;
 merge mergeinsurtype (in = a) insurance_prdtype (in = b);
 by pat_id;
 if a ;
 run;

 proc freq;
 table insurprd insurtype insurprd*insurtype;
 format insurprd prd. insurtype pay.;
 run;

 data insurgroups;
 set mergeinsurprd;
 product = 0;
 if insurprd = 2  and insurtype = 1 then product = 1; **HMO Commercial;
 if insurprd = 2  and insurtype = 5 then product = 2; ** HMO Self Insured;
 if insurprd = 2 and insurtype = 3 then product = 3; **HMO medicaid;
 if insurprd = 5 and insurtype = 1 then product = 4; **PPO Commercial ;
 if insurprd = 5 and insurtype = 5 then product = 5;** PPO Self insured;

 if insurprd = 4 and insurtype = 1 then product = 6; **POS Commercial;

 run;

 
proc sql;
create table personyears as
select *, 180*sum(delivery)*1/365 as personyears, 245*sum(case when term = 0 then delivery end)*1/365 as pretermyears,270*sum(case when term = 1 then delivery end)*1/365 as termyears,  sum(case when scriptime = 1 then dayssup end) as predaysquan, sum(case when scriptime = 2 then dayssup end) as durdaysquan
from insurgroups
;
quit;

data calcyears;
set personyears;
pre_years = (predaysquan/365);
dur_years = (durdaysquan/365);
run;
 
proc freq;
table product;
run;


proc format;
value prod
1 = "HMO Commercial"
2 = "HMO Self Insured"
3 = "HMO Medicaid"
4 = "PPO Commercial"
5 = "PPO Self-Insured"
6 = "POS Commercial"
0 = "Other"
;
run;


proc freq;
table product;
format product prod.;
run;
data project.insurancetype;
	set calcyears;
	run;

data stats;
	set project.insurancetype;
	run;

proc means;
var deliverage;
run;

proc freq;
table pat_region pre_user dur_user deliveryear product age_cat movement;
format pre_user usertypes. movement  move. dur_user usertypes. age_cat age_c. product prod. ;
run;

title'Pre Users Opioids';
proc freq;
table gen_nm movement;
where pre_user > 0;
run;

title'Dur Users Opioids';
proc freq;
table gen_nm movement;
where dur_user > 0;
run;
proc freq data = stats;
table age_cat*pre_user age_cat*dur_user;
run;
proc means;
vars first_t_quan second_t_quan third_t_quan;

run;

proc import datafile = 'R:\GraduateStudents\Student Project #2\Project\Opioid NDC.xlsx' dbms= XLSX out = ndc.codes;
run; 

proc sort data = ndc.codes;
by ndc;
run;

proc sort data = project.insurancetype;
by ndc;
run;

data merg2;
merge project.insurancetype (in = a) ndc.codes (in = b);
by ndc;
if a;
run;

data morphine; 
	set merg2;
	if opioid > 0 then mme_dose = strength_per_unit*mme_conversion_factor;
	if mme_dose = "." then missing = 1;
	run;


*** Get the NDC codes so that I can extract the dosages for conversion to Morphine equivalents;
proc import datafile = 'R:\GraduateStudents\Student Project #2\NDC_codes\package.xlsx' dbms= XLSX out = ndc.pack;
run; 

proc import datafile = 'R:\GraduateStudents\Student Project #2\NDC_codes\product.xlsx' dbms= XLSX out = ndc.prod;
run;

proc sort data=ndc.pack;
by PRODUCTID PRODUCTNDC;
run;
proc sort data=ndc.prod;
by PRODUCTID PRODUCTNDC;
run;

data ndc.FDC_NDC_final(compress=yes reuse=yes);
merge ndc.pack ndc.prod;
by PRODUCTID PRODUCTNDC;
if substr(NDCPACKAGECODE,5,1)='-' then ndc= compress('0'||substr(NDCPACKAGECODE,1,4)||substr(NDCPACKAGECODE,6,4)||substr(NDCPACKAGECODE,11,2) );
else if substr(NDCPACKAGECODE,6,1)='-' and substr(NDCPACKAGECODE,10,1)='-' then 
       ndc= compress(substr(NDCPACKAGECODE,1,5)||'0'||substr(NDCPACKAGECODE,7,3)||substr(NDCPACKAGECODE,11,2) );
else if substr(NDCPACKAGECODE,6,1)='-' and substr(NDCPACKAGECODE,11,1)='-' then 
       ndc= compress(substr(NDCPACKAGECODE,1,5)||substr(NDCPACKAGECODE,7,4)||'0'||substr(NDCPACKAGECODE,12,1) );
run;

proc sort data = morphine;
by ndc;
run;

proc sort data = ndc.FDC_NDC_final;
by ndc;
run;

data missing_ndc;
set morphine;
keep ndc;
where missing = 1 and opioid > 0;
run;

data ndc_dose;
merge missing_ndc (in = a) ndc.FDC_NDC_final (in = b);
by ndc;
if a;
run;

*** Now I need to break up strings with drug names and doseage amounts**;
data sep_substance;
	set ndc_dose;
   length subst1-subst4 $15.;
   array subst(4) $;
   do i = 1 to dim(subst);
      subst[i]=scan(SUBSTANCENAME,i,';','M');
   end;

    length dose1-dose4 $15.;
   array dose(4) $;
   do i = 1 to dim(dose);
      dose[i]=scan(ACTIVE_NUMERATOR_STRENGTH,i,';','M');
   end;

   new1 = input(dose1, 8.);
   drop dose1;
   rename new1=dose1;

   new2 = input(dose2, 8.);
   drop dose2;
   rename new2=dose2;

   new3 = input(dose3, 8.);
   drop dose3;
   rename new3=dose3;

    new4 = input(dose4, 8.);
   drop dose4;
   rename new4=dose4;
run;

**identify types of drugs**;
data mme;
	set sep_substance;

			 x = index(subst1, "CODEINE");
	 	     if x > 0 then mme_dose = dose1*0.15;
			 x = index(subst2, "CODEINE");
	 	     if x > 0 then mme_dose = dose2*0.15;


			 x = index(subst1, "BUPRENOR"); 
			 if x > 0 then mme_dose = dose1*12.6;
			 x = index(subst2, "BUPRENOR"); 
			 if x > 0 then mme_dose = dose2*12.6;

			 x = index(subst1, "HYDROCODONE"); 
			 if x > 0 then mme_dose = dose1*1;
			 x = index(subst2, "HYDROCODONE"); 
			 if x > 0 then mme_dose = dose2*1;

			  x = index(subst1, "FENTANYL"); 
			 if x > 0 then mme_dose = dose1*.13;
			 x = index(subst2, "FENTANYL"); 
			 if x > 0 then mme_dose = dose2*.13;

			 
			  x = index(subst1, "MEPERIDINE"); 
			 if x > 0 then mme_dose = dose1*.1;
			 x = index(subst2, "MEPERIDINE"); 
			 if x > 0 then mme_dose = dose2*.1;

			 	 
			  x = index(subst1, "MORPHINE"); 
			 if x > 0 then mme_dose = dose1*1;
			 x = index(subst2, "MORPHINE"); 
			 if x > 0 then mme_dose = dose2*1;

if ndc = '00121065516' then dose1 = 7.5 ;
if ndc = '00121065516' then subst1 = "HYDROCODONE";
if ndc = '00121065516' then mme_dose = 1*dose1;

if ndc = '00603102058' then dose1 = 2.4;
if ndc = '00603102058' then subst1 = "CODEINE";
if ndc = '00603102058' then mme_dose = .15*dose1;

if ndc = '00603442421' then dose1 = 50;
if ndc = '00603442421' then subst1 = "MEPERIDINE";
if ndc = '00603442421' then mme_dose = .1*dose1;

if ndc = '00677099633' then dose1 = 12;
if ndc = '00677099633' then subst1 = "CODEINE";
if ndc = '00677099633' then mme_dose = .15*dose1;

if ndc = '10019003867' then dose1 = 50;
if ndc = '10019003867' then subst1 = "FENTANYL";
if ndc = '10019003867' then mme_dose = .18*dose1;

if ndc = '43386035001' then dose1 = 5;
if ndc = '43386035001' then subst1 = "HYDROCODONE";
if ndc = '43386035001' then mme_dose = 1*dose1;

if ndc = '43386035003' then dose1 = 5;
if ndc = '43386035003' then subst1 = "HYDROCODONE";
if ndc = '43386035003' then mme_dose = 1*dose1;

if ndc = '50474090916' then dose1 = 7.5;
if ndc = '50474090916' then subst1 = "HYDROCODONE";
if ndc = '50474090916' then mme_dose = 1*dose1;

if ndc = '52152014002' then dose1 = 5;
if ndc = '52152014002' then subst1 = "HYDROCODONE";
if ndc = '52152014002' then mme_dose = 1*dose1;

if ndc = '54569351500' then dose1 = 5;
if ndc = '54569351500' then subst1 = "HYDROCODONE";
if ndc = '54569351500' then mme_dose = 1*dose1;

if ndc = '55390018401' then dose1 = 2;
if ndc = '55390018401' then subst1 = "BUTORPHANOL";
if ndc = '55390018401' then mme_dose = 7*dose1;

if ndc = '58177002704' then dose1 = 50;
if ndc = '58177002704' then subst1 = "MEPERIDINE";
if ndc = '58177002704' then mme_dose = .1*dose1;

if ndc = '58177090907' then dose1 = 7.5;
if ndc = '58177090907' then subst1 = "HYDROCODONE";
if ndc = '58177090907' then mme_dose = 1*dose1;

if ndc = '60258072016' then dose1 = 5;
if ndc = '60258072016' then  subst1 = "HYDROCODONE";
if ndc = '60258072016' then  mme_dose = 1*dose1;

if ndc = '61570008101' then dose1 = 5;
if ndc = '61570008101' then subst1 = "HYDROCODONE";
if ndc = '61570008101' then  mme_dose = 1*dose1;

if ndc = '52152019002' then dose1 = 50;
if ndc = '52152019002' then subst1 = "MEPERIDINE";
if ndc = '52152019002' then mme_dose = .1*dose1;


if ndc = '66479057416' then dose1 = 7.5;
if ndc = '66479057416' then subst1 = "HYDROCODONE";
if ndc = '66479057416' then mme_dose = 1*dose1;

if ndc = '00074117830' then dose1 = 50;
if ndc = '00074117830' then subst1 = "MEPERIDINE";
if ndc = '00074117830' then mme_dose = .1*dose1;

if ndc = '00074909335' then dose1 = 50;
if ndc = '00074909335' then subst1 = "FENTANYL";
if ndc = '00074909335' then mme_dose = .18*dose1;


if ndc = '00406037516' then dose1 = 7.5;
if ndc = '00406037516' then subst1 = "HYDROCODONE";
if ndc = '00406037516' then mme_dose = 1*dose1;


if ndc = '00409126130' then dose1 = 7.5;
if ndc = '00409126130' then subst1 = "MORPHINE";
if ndc = '00409126130' then mme_dose = 1*dose1;

if ndc = '00603102058' then dose1 = 2.4;
if ndc = '00603102058' then subst1 = "CODEINE";
if ndc = '00603102058' then mme_dose = .15*dose1;

if ndc = '00603129558' then dose1 = 2.5;
if ndc = '00603129558' then subst1 = "HYDROCODONE";
if ndc = '00603129558' then mme_dose = 1*dose1;

run;
	
data part2;
	set mme;
	keep ndc dose1-dose4 mme_dose subst1-subst4;
	run;

proc sort;
by ndc;
run;

data complete_mme;
merge morphine (in = a) mme (in = b);
by ndc;
if a;
run;

** Now I need to look at the variable that we used to calculate the dosages;

** count totals person has taken in time frame**;
/*
proc sql;
create table mme_doses as
	select *  , sum(case when scriptime = 1 then dayssup end) as predays, sum(case when scriptime = 2 then dayssup end) as dur_days
	from nopreabuse
	group by pat_id
	;
	quit;
*/



data mme_doses;
	set complete_mme;
		if opioid > 0 and dayssup gt 0 then mme_eq_dose = (QUAN*mme_dose)/dayssup;
			else mme_eq_dose = quan*mme_dose;
		if opioid > 0 then quantity_check = dayssup/quan;
			run;



proc freq;
	table mme_eq_dose quantity_check;
		run;

/* We kick out five observations of opioid users cause they have a negative days supplied**/
data doses_total;
	set mme_doses;
	where mme_eq_dose > 0 or mme_eq_dose = .;
	run;

proc sql;
create table mme_dose_days as
	select *  , sum(case when scriptime = 1 then mme_eq_dose end) as predays_mme, sum(case when scriptime = 2 then mme_eq_dose end) as dur_days_mme
	from doses_total
	group by pat_id
	;
	quit;

proc means data = mme_dose_days;
var predays_mme dur_days_mme;
where opioid > 0;
run;

/* MAke the measurements by Trimester to see if the drugs on loaded onto the Third trimester. I.E prep for birth*/
proc sql;
create table mme_trimester_doses as
	select *  , sum(case when first_tri = 1 then mme_eq_dose end) as first_t_mme, sum(case when second_tri = 1 then mme_eq_dose end) as second_t_mme, sum(case when third_tri = 1 then mme_eq_dose end) as third_t_mme
	from mme_dose_days
	group by pat_id
	;
	quit;

proc means data = mme_trimester_doses;
var first_t_mme second_t_mme third_t_mme;
where opioid > 0;
run;

data full_dose_info;
	set mme_trimester_doses;
	run;

/* Getting rid of absurdly high dosages*/

data project.cleaned_dosages;
	set full_dose_info;;
	where mme_eq_dose le 360;
	

		run;
title 'Opioid Prescribing Habits During Trimesters of Pregnancy';
proc means data = project.cleaned_dosages;
var first_t_mme second_t_mme third_t_mme;
where opioid > 0;
run;

title 'Opioid Prescribing Habits Before and During Pregnancy';
proc means data = project.cleaned_dosages;
var predays_mme dur_days_mme;
where opioid > 0;

run;

title 'Product';
proc freq;
table product;
run;

proc format;
value usertypes
0 = "No Use"
1 = "Chronic Use"
2 = "Intermittent Use"
;
run;
proc format;
value prod
1 = "HMO Commercial"
2 = "HMO Self Insured"
3 = "HMO Medicaid"
4 = "PPO Commercial"
5 = "PPO Self-Insured"
6 = "POS Commercial"
0 = "Other"
;
run;
proc format;
value age_c 
1 = "12 to 17"
2 = "18 to 23"
3 = "24 to 29"
4 = "30 to 34"
5 = "35 to 39"
6 = "40 to 44"
7 = "45 to 49"
8 = "50 to 55"
;
run;

proc format;
value move

0 = "Non to Non"
1 = "Chronic to Non"
2 = "Chronic to Chronic"
3 = "Chronic to Intermit"
4 = "Intermit to Non"
5 = "Intermit to Chronic"
6 = "Intermit to Intermit"
7 = "Non to Chronic"
8 = "Non to Intermit"
;
run;

proc freq data = project.cleaned_dosages;
table product*dur_user;
format product prod.;
run;

proc means data = project.cleaned_dosages ;
var deliverage;
run;

title 'tables';
proc freq data = project.cleaned_dosages;
table pat_region*dur_user pre_user*dur_user deliveryear*dur_user product*dur_user age_cat*dur_user;
format pre_user usertypes.  dur_user usertypes. age_cat age_c. product prod. ;
run;

title 'Drugs used During Preg';
proc freq data = project.cleaned_dosages;
table brand_name*scriptime*dur_user;
where scriptime = 2;
run;

proc means data = project.cleaned_dosages;
class pre_user;
var predays_mme;
run;


proc means data = project.cleaned_dosages;
class dur_user;
var dur_days_mme;
run;
proc sort data = project.cleaned_dosages;
by deliveryear;
run;

proc logistic data = project.cleaned_dosages;
data regression;
	set project.cleaned_dosages;
	if dur_user gt 0 then user_preg = 1;
	else user_preg = 0;
		run;
proc format;
value age_c 
1 = "12 to 17"
2 = "18 to 23"
3 = "24 to 29"
4 = "30 to 34"
5 = "35 to 39"
6 = "40 to 44"
7 = "45 to 49"
8 = "50 to 55"
;
run;
    proc logistic data=regression;
		class age_cat(ref = "30 to 34") product (ref = 'PPO Commercial') deliveryear (ref = '2008') pat_region (ref = "E") / param= ref;
        model user_preg (event="1")= age_cat  product  deliveryear  pat_region ;
        ods output parameterestimates=logparms;
        output out=outlog p=p;
		format pre_user usertypes. age_cat age_c. product prod. ;
        run;

 proc qlim data=regression;
   class  age_cat product deliveryear pat_region ;
   model user_preg = age_cat  product  deliveryear  pat_region/ discrete (dist = logit);
   output out=outqlim marginal;
run;
/* I don't need right now
data logparms2;
	set logparms;
	if variable = "Intercept" then ClassVal0 = "Intercept";
	run;


proc transpose data=logparms2 out=tlog (rename=(age_cat=t_cat product=tproduct deliveryear = tdeliveryear pat_region = tpat_region));
	id ClassVal0;
	var estimate ;
    run;

 data outlog;
        if _n_=1 then set tlog;
        set outlog;
        MEffage_cat_12_to_17 = p*(1-p)*_12_to_17;
		MEffage_cat_18_to_23 = p*(1-p)*_18_to_23;
		MEffage_cat_24_to_29 = p*(1-p)*_24_to_29;
		MEffage_cat_35_to_39 = p*(1-p)*_35_to_39;
		MEffage_cat_40_to_44 = p*(1-p)*_40_to_44;
		MEffage_cat_45_to_49 = p*(1-p)*_45_to_49;
		MEffage_cat_45_to_49 = p*(1-p)*_45_to_49;


		MEffHMO_Commercial = p*(1-p)*HMO_Commercial;
		MEffHMO_Medicaid = p*(1-p)*HMO_Medicaid;
		MEffHMO_Self_Insured = p*(1-p)*HMO_Self_Insured;
		MEffOther = p*(1-p)*Other;
		MEffPOS_Commercial = p*(1-p)*POS_Commercial;
		MEffPPO_Self_Insured = p*(1-p)*PPO_Self_Insured;

		MEff_2007 = p*(1-p)*_2007;
		MEff_2009 = p*(1-p)*_2009;
		MEff_2010 = p*(1-p)*_2010;
		MEff_2011 = p*(1-p)*_2011;
		MEff_2012 = p*(1-p)*_2012;
		MEff_2013 = p*(1-p)*_2013;
		MEff_2014 = p*(1-p)*_2014;
		MEff_2015 = p*(1-p)*_2015;

        MEffMW = p*(1-p)*MW;
		MEffS = p*(1-p)*S;
		MEffW = p*(1-p)*W;

        run;
   proc print noobs;
        var age_cat product pat_region deliveryear  MEff:;
        run;
