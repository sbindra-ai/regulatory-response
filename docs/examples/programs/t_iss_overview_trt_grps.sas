/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_iss_overview_trt_grps);
/*
 * Purpose          : Integrated analysis treatment groups
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
/* Changed by       : eqczz (Petri Pulkkinen) / date: 05APR2024
 * Reason           : 1) Footnotes updated due to comments from stats
 ******************************************************************************/


ods escapechar='^';
/*****************************
 *Read data in
 ****************************/

DATA gloss ;
    LENGTH col1 col2 col3 $1000. ;
    LABEL col1='Integrated analysis treatment group'
           col2='Participants'
           col3= 'Results during treatment*'
           ;
    row =1;
    col1="EZN 120 mg (week 1-12)&newline.Placebo (week 1-12)&newline.Total (week 1-12)";
    col2="As treated** during the first 12 weeks.";
    col3="First 12 weeks of study treatment.&newline.This covers for SWITCH-1 the complete treatment period, for OASIS 1 and 2 phase 1 as defined in the study SAPs,
 for OASIS 3 events up to day 84 after start of first study drug and visit-based measurements up to and including study visit Week 12.";
    OUTPUT;
    row =2;
    col1="EZN 120 mg (week 1-26)&newline.Placebo (week 1-26)";
    col2='As treated** during the first 12 weeks or after the treatment switch in OASIS 1 and 2. Treatment switchers are presented in both treatment groups.';
    col3="First 26 weeks of study treatment&newline.
 For treatment switchers, results are only assigned to one treatment, namely the one that was given when the event started or the measurement was collected.&newline.
 Results cover for SWITCH-1 and OASIS 1 and 2 the complete treatment period, for OASIS 3 the time up to day 182 after first study drug.
";
    output;
    row =3;
    col1="EZN 120 mg (week 1-52)&newline.Placebo (week 1-52)";
    col2='As above';
    col3="Complete study treatment periods across all studies.&newline.
 For treatment switchers, events and measurements are only assigned to one treatment, namely the one that was given when the event started or the measurement was collected.
";
    output;
    row =4;
    col1="EZN 120 mg (week 1-26/ 1-52)***&newline.Placebo (week 1-26/1-52)***";
    col2='As above';
    col3="As above";
    output;

RUN;

/*************************************************************/
/********************* Output   ******************************/
/*************************************************************/

%set_titles_footnotes(
    tit1 = "Table: Integrated analysis treatment groups"
  , ftn1 = "* Baseline characteristics: presented for the participants included in the respective group and don't depend on the time window (week 1 - x). "
  , ftn2 ="Pre- and post-treatment adverse events/medication: only available for the week 1-12 treatment groups. Assignment of participants to treatment groups is done based on the treatment they started with. Post-treatment refers to the time after the last study drug given during the study, i.e. post-treatment adverse events in participants switching from placebo to elinzanetant, which occur after the 14-day TEAE window after the last elinzanetant treatment, are presented in
 Placebo (week 1-12); and post-treatment medication in participants switching from placebo to elinzanetant, which occur after the last elinzanetant treatment, are presented in Placebo (week 1-12). Post-treatment abuse potential events are available for EZN 120 mg (week 1-52) and Placebo (week 1-52) where events are only assigned to the last study drug the participant received. "
  , ftn3 = "Disposition: refer to the complete study duration, if not stated differently explicitly. "
  , ftn4 = '** For analyses based on the All randomized population, "As treated" will be replaced by "As randomized". '
  , ftn5 = '*** These groups cover analyses for which no differentiation is needed between week 1-26 and week 1-52 (baseline characteristics, analyses over time covering the 26 weeks as well as the 52 weeks time point).
'
)
;

%datalist(
    data     = gloss
  , by       = row
  , var      = col1 col2 col3
  , order    = row
  , freeline = row
  , maxlen   = 80
  , split    = /
  , hsplit   = '#'
)
;

%endprog(cleanWork = Y);

*******This is the end of t_iss_overview_trt_grps.sas******;