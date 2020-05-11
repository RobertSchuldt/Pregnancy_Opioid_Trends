/****************************************************************************************************************************************
*****************************************************************************************************************************************

Author: Robert Schuldt
Date : 1/30/2020
Email: rschuldt@uams.edu

	This is round two of analysis on opiod prescribing trends among commercially insured woman in their first pregnancy. Amy Lallier and I 
will be removing patients who have diagnosis of Opioid Use Disorder from the data. This is meant to update the current literature 
on how physicians have responded since changes in the guidelines and awareness of the opioid epidemic. 

*****************************************************************************************************************************************
*****************************************************************************************************************************************/


/* Set Libnames for the locations of the files*/
libname clms 'R:\PharMetrics (IQVIA)\Claims - Medical - Inpatient';
libname paper 'R:\GraduateStudents\SchuldtRobertF\paper';
libname pharm 'R:\PharMetrics (IQVIA)\Data';
libname enroll 'R:\PharMetrics (IQVIA)\Enrollment';
libname outpat 'R:\PharMetrics (IQVIA)\Claims - Medical - Outpatient';
libname project 'R:\GraduateStudents\Student Project #2\Project';
libname amy 'R:\GraduateStudents\Student Project #2\Amy-Data';
libname ndc 'R:\GraduateStudents\Student Project #2\NDC_codes';

/* Create an empty shell set to drop observations into*/
data shellset;
	set clms.clm_inpat_08 (obs = 1) ; 
	keep =. ;
	exclude = 0;
	source = '                                             ';
	year =00;
%macro yearin(sasset, date);
	data bringin;
		set &sasset;
		exclude = 0;
		year = &date;
			/*Diagnosis cariables */
			array icd (12) diag1-diag11 diag_admit;
			/* ICD 9 Codes */
			array deliver_code (3) $ ("V271", "V270", "V279");
			do i = 1 to 12;
			do v = 1 to 3;
					if substr(icd(i), 1,4 ) = 'O420' then   keep = 1;
					if substr(icd(i), 1,4 ) = 'O421' then   keep = 1;
					if substr(icd(i), 1, 4) = 'O838' then  keep = 1;
					if substr(icd(i), 1, 4) = 'O429' then  keep = 1;
					if substr(icd(i), 1, 4) = 'O603' then  keep = 1;
					if substr(icd(i), 1, 4) = 'O601' then   keep = 1;
					if substr(icd(i), 1, 4) = '6440' then keep = 1;
					if substr(icd(i), 1, 4) = '6442' then  keep = 1;
					if substr(icd(i), 1, 3) = '765' then  keep = 1;
			if substr(icd(i), 1, 4) = deliver_code(v) then keep = 1;
			end; end;

			do i = 1 to 12;
			do code_1 = 640 to 650; 
			length y $ 3;
			y = code_1;
			if substr(icd(i), 1, 3) = y then keep = 1;
			end; end;

			do i = 1 to 12;
			do code_2 = 652 to 679;
			y = code_2  ;
			if substr(icd(i), 1, 3) = y then keep = 1;
			end; end;
			
			if substr(proc_cde, 1, 2) = "72" then keep = 1;
			if substr(proc_cde, 1, 4) = "7322" then keep = 1;
			if substr(proc_cde, 1, 4) = "7359" then keep = 1;
			if substr(proc_cde, 1, 3) = "736" then keep = 1;
			if substr(proc_cde, 1, 3) = "740" then keep = 1;
			if substr(proc_cde, 1, 3) = "741" then keep = 1;
			if substr(proc_cde, 1, 3) = "742" then keep = 1;
			if substr(proc_cde, 1, 3) = "744" then keep = 1;
			if substr(proc_cde, 1, 4) = "7499" then keep = 1;
				
		


			/*ICD 10 codes*/
			array icd10_deliver(4) $ ( "O80",  "O81" , "O82" , "O83" );
			
			do i = 1 to 12;

			do m = 1 to 4; 
			if substr(icd(i), 1, 3) = icd10_deliver(m) then keep = 1;
			end; end;

			array icd10_long  (4) $ ("O601", "O420", "O421" , "O429" ) ;
			do i = 1 to 12;
			do m = 1 to 4; 
			if substr(icd(i), 1, 4) = icd10_long(m) then keep = 1;
			end; end;
			/* These are codes to exlcude but are a pregnancies. They include the 
			- ectopic
			- twins (we want single births)
			-abortions
			-molar
			-multifetal
			- Complications from abortions
			*/

			array icd10_exclude (3) $ ( "O42011" "O42111" "O42911" );
			do i = 1 to 12;
			do z = 1 to 3; 
			if substr(icd(i), 1, 6) = icd10_exclude(z) then exclude = 1;
			end; end;
			/* The large arrays take a lot of time and my do loops only work for sequential codes
			so I am just entering these in */
			do i = 1 to 12; 
			if substr(icd(i), 1, 3) = '630' then exclude = 1;
			if substr(icd(i), 1, 3) = '651' then exclude = 1;
			if substr(icd(i), 1, 4) = 'V272' then exclude = 1;
			if substr(icd(i), 1, 4) = 'V273' then exclude = 1;
			if substr(icd(i), 1, 4) = 'V274' then exclude = 1;
			if substr(icd(i), 1, 4) = 'V275' then exclude = 1;
			if substr(icd(i), 1, 4) = 'V276' then exclude = 1;
			if substr(icd(i), 1, 4) = 'V277' then exclude = 1;
			if substr(icd(i), 1, 3) = 'V91' then exclude = 1;
			if substr(icd(i), 1, 3) = 'O30' then exclude = 1;
			if substr(icd(i), 1, 3) = 'O00' then exclude = 1;
			if substr(icd(i), 1, 3) = 'O01' then exclude = 1;
			if substr(icd(i), 1, 3) = '632' then exclude = 1;
			if substr(icd(i), 1, 3) = '634' then exclude = 1;
			if substr(icd(i), 1, 3) = '635' then exclude = 1;
			if substr(icd(i), 1, 3) = '636' then exclude = 1;
			if substr(icd(i), 1, 3) = '637' then exclude = 1;
			if substr(icd(i), 1, 3) = 'O03' then exclude = 1;
			if substr(icd(i), 1, 3) = '639' then exclude = 1;
			if substr(icd(i), 1, 3) = 'O04' then exclude = 1;
			if substr(icd(i), 1, 3) = 'O08' then exclude = 1;
			if substr(icd(i), 1, 3) = '633'  then exclude = 1;

			end;
			



			source = "&sasset";

			data keep_preg;
				set bringin;
				where keep = 1 or exclude = 1;
				run;
			
			
	/* Drop them into the data set*/
	proc append base = shellset data = keep_preg force nowarn;
			run;
%mend yearin;
%yearin(clms.clm_inpat_08, 08)
%yearin(clms.clm_inpat_09, 09)
%yearin(clms.clm_inpat_10, 10)
%yearin(clms.clm_inpat_11, 11)
%yearin(clms.clm_inpat_12, 12)
%yearin(clms.clm_inpat_13, 13)
%yearin(clms.clm_inpat_14, 14)
%yearin(clms.clm_inpat_15, 15)
%yearin(clms.clm_inpat_16, 16)
%yearin(clms.clm_inpat_17, 17)
%yearin(clms.clm_inpat_18, 18)


/* Save the file into our project director*/
data project.deliveries;
	set shellset;
	where keep = 1;
	delivery = keep;
	drop keep;
	run;

/* I do want to see how many excluded  */
proc freq data = shellset;
title ' Excluded pregnancies ';
table exclude;
run;

/* Sort my data set to get the first pregnancy we have on record*/

proc sort data= project.deliveries out= sorted;
by pat_id from_dt; 
run;
/* I saved second  births for followup idea I have*/
data clean first_del project.second_del;
	set sorted;
	by pat_id from_dt;
	if first.pat_id then output first_del;
		else output clean;
		run;

/* Check number of deliveries */
title' Check total number of deliveries';
proc tabulate data = first_del;
class year;
var delivery;
table year, (N PCTSUM)*delivery;
run;
/*These are preterm preganncies we need to identify for estimated date of conception*/
data term;
	set first_del;
		array icd9 (12) diag1-diag11 diag_admit;
				do i = 1 to 12;
					if substr(icd9(i), 1, 4) = '6440' then term = 0;
					if substr(icd9(i), 1, 4) = '6442' then  term = 0;
					if substr(icd9(i), 1, 3) = '765' then  term = 0;


					if substr(icd9(i), 1,4 ) = 'O420' then  term = 0;
					if substr(icd9(i), 1,4 ) = 'O421' then  term = 0;
					if substr(icd9(i), 1, 4) = 'O838' then  term = 0;
					if substr(icd9(i), 1, 4) = 'O429' then  term = 0;
					if substr(icd9(i), 1, 4) = 'O603' then  term = 0;
					if substr(icd9(i), 1, 4) = 'O601' then  term = 0;


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
/*Calculating the index dates for our time periods*/
data edc;
	set term;
deliver_date = from_dt;
if term = 0 then edc_index_date = from_dt - 245;
if term = 1 then edc_index_date = from_dt - 270;

format deliver_date mmddyy8.;
format edc_index_date mmddyy8.;

pre6 = edc_index_date -210;
	format pre6 mmddyy8.;

run;
proc sort data = edc;
by pat_id;
run;	

/* Making sure that we have the correctindex dates for ensuring continous coverage duringour study period*/
data index_date;
	set edc;
	index_dt = pre6;
	 	format index_dt mmddyy8.;

		
		index_year = year(index_dt);                                                                                                                                                                                                                             
        index_month = month(index_dt);                                                                                                                                                                                                                       
        indyrs95 = index_year - 2001;                                                                                                                                                                                                                         
        indexyrsmonth = indyrs95*12;                                                                                                                                                                                                                              
        index_date_number = index_month+indexyrsmonth; 

		delyearindex = year(deliver_date);
		delmoindex = month(deliver_date);
		delyrs95 = delyearindex - 2001;
		delyrsmonth = delyrs95*12;
		delmonthindex = delmoindex+delyrsmonth;
		totalmonths = delmonthindex - index_date_number;

	run;

data insurance;                                                                                                                                                                                                                                                 
        merge enroll.uark087_13p_pop (in = a) index_date (in = b);                                                                                                                                                                                                     
        by pat_id;                                                                                                                                                                                                                                              
        if b;                                                                                                                                                                                                                                                   
        run;   
/* Matches the total number of months of continsous insurance coverage that
		the patient has had. We will bring in pharmacy coverage next*/

data cont;
	set insurance;
	 if substr(estring, index_date_number, 14) = 'XXXXXXXXXXXXXX' then contelig = 1;
	 if substr(estring, index_date_number, 15) = 'XXXXXXXXXXXXXXX' then contelig = 1;
	 if substr(estring, index_date_number, 16) = 'XXXXXXXXXXXXXXXX' then contelig = 1;
	 if contelig ne 1 then contelig = 0;
run;

/*see who has cont coverage*/
proc freq;
table contelig;
run;


** Now merge with pharmacy benefits so we can see what their medication looks like**;
data RXinsurance;                                                                                                                                                                                                                                               
merge cont (in=a) enroll.uark087_13p_pop2_addon (in=b);                                                                                                                                                                                                       
by pat_id;                                                                                                                                                                                                                                                      
if a; *keeping all records for first d12 months insurance post first event in data and diagnosis of hypertension*;                                                                                                                                                            
run;
/*Identifies continous RX benefits*/
data cont_rx;
	set RXinsurance;
	where type='der_ben_rx';
	if contelig = 1;
	if substr(string, index_date_number, 14) = 'YYYYYYYYYYYYYY' then ContEligRX= 1;
	if substr(string, index_date_number, 15) = 'YYYYYYYYYYYYYYY' then ContEligRX= 1;
	if substr(string, index_date_number, 16) = 'YYYYYYYYYYYYYYYY' then ContEligRX= 1;
	if conteligrx ne 1 then delete;
run;

proc freq;
table Conteligrx;
run;
/* Now I need to run these woman through all the other outpat and inpat for identfying if they had abuse 
of opioid recorded*/
data project.collect_abuse;
	set cont_rx;
	keep pat_id pre6 deliver_date edc_index_date;
	run;
proc sort data = project.collect_abuse; by pat_id;
run;

/*runs my program to identify abuse diagnosis if we want to run whole thing again activate this line of code*/
/************** %include "R:\GraduateStudents\Student Project #2\IDENTIFYING ABUSE DIAGNOSIS2020.sas"; ******************/

/*Grabbing the women with a sedative or opioid prescription from other program*/

data cont_abuse;
	merge cont_rx (in =a ) project.abuse_diag;
	by pat_id;
	if a;
run;

/* Now I want ot see if they got this diagnosis before or during pregnancy */
data time_check;
	set cont_abuse;
abuse_period = "No Disorder Diagnosis";
if disorder_dt <= edc_index_date  and abuse_diag_opi = 1 or possible_abuse = 1 then abuse_period = "Prior to EDC";
if (disorder_dt > edc_index_date and disorder_dt < deliver_date) and abuse_diag_opi = 1 or possible_abuse = 1 then abuse_period = "During Pregnancy";
run;
/*Check to see when the disorder diagnosis occurs*/
proc freq;
title 'When did diagnosis of abuse disorder occur';
table abuse_period;
run;
/* Want to see where my preg are located regionally*/
proc freq; 
title 'location of pregnancies';
table pat_region*delivery;
run;

proc sort data = time_check;
by pat_id;
run;


/*Now we need to look at opioid prescriptions that our patients have received*/
/***** data project.cleaned_dosages; USE THIS DATA SO WE CAN CHECK HOW OFTEN EACH TYPE OF DRUG WAS PRESCRIBED/MOST COMMON***/
/***************************************************************************************************************************/

/*Merge in the cleaned up dosages and mme*/
data patients;
 merge time_check (in = a) project.dosages (in = b);
 if a;
 run;

data clean_nonuser;
	set patients;
if pre_user = . then pre_user = 0;
if dur_user = . then dur_user = 0;
if any_type = . then any_type = 0;
if dur_days = . then dur_days = 0;
if pre_days = . then pre_days = 0;
if predays_mme = . then predays_mme =0;
if dur_days_mme = . then dur_days_mme = 0;

if pre_user = 0 and dur_user = 0 then movement = 0; **Non to Non**;
if pre_user = 1 and dur_user = 0 then movement = 1; * Chronic to Non*;
if pre_user = 1 and dur_user = 1 then movement = 2; **Chronic to Chronics;
if pre_user = 1 and dur_user = 2 then movement = 3; **Chronic to Intermit;

if pre_user = 2 and dur_user = 0 then movement = 4; **inter to non;
if pre_user = 2 and dur_user = 1 then movement = 5; ** inter to chronics;
if pre_user = 2 and dur_user = 2 then movement = 6; **inter to inter;

if pre_user = 0 and dur_user = 1 then movement = 7; **non to chronic;
if pre_user = 0 and dur_user = 2 then movement = 8; ** non to inter;
/*Also removing the too young nad old outliers*/
deliveryear=year(deliver_date);
deliverage = deliveryear - der_yob;
if deliverage < 12 then delete;
if deliverage >55 then delete;

if deliverage >= 12 and deliverage lt 18 then age_cat = 1;
if deliverage >= 18 and  deliverage <= 23 then age_cat = 2;
if deliverage > 23 and deliverage <= 29 then age_cat = 3;
if deliverage > 29 and deliverage <= 34 then age_cat = 4;
if deliverage > 34 and deliverage <= 39 then age_cat = 5;
if deliverage > 39 and deliverage <= 44 then age_cat = 6;
if deliverage > 44 and deliverage <= 49 then age_cat = 7;
if deliverage > 49 and deliverage <= 55 then age_cat = 8;


run;
proc freq;
table pat_region  pat_state;
run;

/*Now i need to get the product type of the insurance that the patient has*/

data insurance;
	 set enroll.uark087_13p_pop2;
keep  pat_id  type string;;
where type = "pay_type";
rename type = type2;
rename string = string2;
run;

data product;
	 set enroll.uark087_13p_pop2;
keep  pat_id  type string;;
where type = "prd_type";
rename type = type3;
rename string = string3;
run;




proc sort data = clean_nonuser; by pat_id; run;


data type;
	merge clean_nonuser (in =a) insurance product;
	by pat_id;
	if a;
	run;

data insur_type;
	set type;

/*assigning insurance product types*/
if substr( string2 , delmonthindex, 1) = 'C' then insurtype = 1;
if substr( string2, delmonthindex, 1) = 'K' then insurtype = 2;
if substr( string2, delmonthindex, 1) = 'M' then insurtype = 3;
if substr( string2, delmonthindex, 1) = 'R' then insurtype = 4;
if substr( string2, delmonthindex, 1) = 'S' then insurtype = 5;
if substr( string2, delmonthindex, 1) = 'T' then insurtype = 6;

if substr( string3, delmonthindex, 1) = 'D' then insurprd = 1;
if substr( string3, delmonthindex, 1) = 'H' then insurprd = 2;
if substr( string3, delmonthindex, 1) = 'I' then insurprd = 3;
if substr( string3, delmonthindex, 1) = 'S' then insurprd = 4;
if substr( string3, delmonthindex, 1) = 'P' then insurprd = 5;
if substr( string3, delmonthindex, 1) = 'R' then insurprd = 6;
if substr( string3, delmonthindex, 1) = 'U' then insurprd = 7;

 product = 0;
 if insurprd = 2  and insurtype = 1 then product = 1; **HMO Commercial;
 if insurprd = 2  and insurtype = 5 then product = 2; ** HMO Self Insured;
 if insurprd = 2 and insurtype = 3 then product = 3; **HMO medicaid;
 if insurprd = 5 and insurtype = 1 then product = 4; **PPO Commercial ;
 if insurprd = 5 and insurtype = 5 then product = 5;** PPO Self insured;

 if insurprd = 4 and insurtype = 1 then product = 6; **POS Commercial;
	
if dur_user > 0 then user_preg = 1;
	else user_preg = 0;

if pre_user > 0 then pre_user_preg = 1;
	else pre_user_preg =0;
run;
proc sort data = insur_type;
by pat_id;
run;
proc sort data = project.pain_type;
by pat_id;
run;

data pain_insur;
merge insur_type (in = a) project.pain_type;
by pat_id;
if a;
run;

data next_step;
	set pain_insur;
array p1(11) 	backpain1
	TRAUMA1
	burn1
	neckpain1
	arthritis1
	headache1
	fibromyalgia1 
	neuropathic1
	abdominal1
	chestpain1
	otherpain1
	;
	do i = 1 to 11;

		if p1(i) = . then p1(i) = 0;

	end;
run;



/*Load in formats from old code to help make results easier to interpret*/

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
value usertypes
0 = "No Use"
2 = "Chronic Use"
1 = "Intermittent Use"
;
run;

proc freq data = next_step;
title 'Look at number of intermittent and chronic';
table dur_user pre_user;
format dur_user usertypes. pre_user usertypes.;
run;

proc freq; 
title 'Lookin at key variables';
table deliveryear product pat_region;
format product prod.;
run;
data project.analysis;
	set next_step;
	if abuse_diag_opi = 1 or possible_abuse = 1 then delete;
	if deliveryear = 2008 then delete;
	run;


proc logistic data=project.analysis;
		class age_cat(ref = "30 to 34") product (ref = 'PPO Commercial') deliveryear (ref = '2009') pat_region (ref = "W") term (ref = "1")/ param= ref;
        model user_preg (event="1")= pre_user_preg age_cat  product  deliveryear  pat_region term backpain1
	TRAUMA1
	burn1
	neckpain1
	arthritis1
	headache1
	fibromyalgia1 
	neuropathic1
	abdominal1
	chestpain1
	otherpain1;
		ods output parameterestimates=logparms;
        output out=outlog p=p;
		format pre_user usertypes. age_cat age_c. product prod. ;
        run;
ods output;
ods pdf file = 'R:\GraduateStudents\Student Project #2\Documents\Descriptive.pdf';
proc freq;
table age_cat term pat_region pre_user dur_user deliveryear product backpain1
	TRAUMA1
	burn1
	neckpain1
	arthritis1
	headache1
	fibromyalgia1 
	neuropathic1
	abdominal1
	chestpain1
	otherpain1;
	run;

ods pdf close;

ods pdf file = 'R:\GraduateStudents\Student Project #2\Documents\table2.pdf';
proc freq;
table Drug;
run;
ods pdf close;

ods pdf file = 'R:\GraduateStudents\Student Project #2\Documents\table3.pdf';
proc freq;
table pre_user*dur_user;
run;
ods pdf close;

