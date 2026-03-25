/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_iss_overview_trt_grp_ana);
/*
 * Purpose          : Integrated analysis treatment groups used by analysis topic
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gdcpl (Derek Li) / date: 28MAR2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 30MAY2024
 * Reason           : Add text liver safety to row 4 in the output dataset and file
 ******************************************************************************/


ods escapechar='^';
/*****************************
 *Read data in
 ****************************/

DATA gloss ;
    LENGTH col1 col2 $1000. ;
    LABEL col1='Analysis topic'
           col2='Integrated analysis treatment group'
           ;
    row =1;
    col1="Demography and baseline characteristics&newline.Reproductive and menstrual history&newline.Medical history";
    col2="EZN 120 mg (week 1-12)&newline.Placebo (week 1-12)&newline.Total (week 1-12)&newline.EZN 120 mg (week 1-26/1-52)&newline.Placebo (week 1-26/1-52)";
    OUTPUT;
    row =2;
    col1="Disposition";
    col2="EZN 120 mg (week 1-12)&newline.Placebo (week 1-12)&newline.EZN 120 mg (week 1-26/1-52)";
    output;
    row =3;
    col1="Prior medication / Pre-treatment AEs";
    col2="EZN 120 mg (week 1-12)&newline.Placebo (week 1-12)&newline.Total (week 1-12)";
    output;
    row =4;
    col1="Concomitant medication&newline.Exposure by treatment, treatment duration, compliance, liver safety";
    col2="EZN 120 mg (week 1-12)&newline.Placebo (week 1-12)*&newline.EZN 120 mg (week 1-26)&newline.Placebo (week 1-26)*&newline.EZN 120 mg (week 1-52)&newline.Placebo (week 1-52)*";
    output;
    row =5;
    col1="Safety tables by visit&newline.Cumulative incidence for time to AEs";
    col2="EZN 120 mg (week 1-12)&newline.Placebo (week 1-12)&newline.EZN 120 mg (week 1-26/1-52)";
    output;
    row =6;
    col1="Safety tables about minimum or maximum values during treatment-emergent or post-baseline time window&newline.Close liver observation";
    col2="EZN 120 mg (week 1-12)&newline.Placebo (week 1-12)&newline.EZN 120 mg (week 1-26)&newline.EZN 120 mg (week 1-52)";
    output;
    row =7;
    col1="TEAEs up to week 12, post-treatment AEs, post-treatment medication&newline.Safety tables including only Baseline (BL)/Screening and EoT, Abuse potential";
    col2="EZN 120 mg (week 1-12)&newline.Placebo (week 1-12)";
    output;

    row =8;
    col1="TEAEs up to week 26, Abuse potential";
    col2="EZN 120 mg (week 1-26)&newline.Placebo (week 1-26)";
    output;
    row =9;
    col1="TEAEs up to week 52&newline.Abuse potential";
    col2="EZN 120 mg (week 1-52)&newline.Placebo (week 1-52)";
    output;

RUN;

/*************************************************************/
/********************* Output   ******************************/
/*************************************************************/

%set_titles_footnotes(
    tit1 = "Table: Integrated analysis treatment groups used by analysis topic"
  , ftn1 = "* Placebo is not presented for both the Treatment dose of elinzanetant per day and Total dose of elinzanetant by integrated analysis treatment group tables."
  , ftn2 = 'EZN= Elinzanetant.'
  , ftn3 = 'AE = Adverse Event.'
  , ftn4 = 'TEAE = Treatment-Emergent Adverse Event'
)
;

%datalist(
    data     = gloss
  , by       = row
  , var      = col1 col2
  , order    = row
  , freeline = row
  , maxlen   = 80
  , split    = /
  , hsplit   = '#'
)
;

%endprog(cleanWork = Y);

*******This is the end of t_iss_overview_trt_grp_ana.sas******;