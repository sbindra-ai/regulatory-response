/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = i_8_2_1_gloss_endpt    );
/*
 * Purpose          : Glossary: Overview of estimands addressing the primary and key secondary efficacy
 * Programming Spec :
 * Validation Level : 1 - Validation by review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : sgtja (Katrin Roth) / date: 20OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/i_8_2_1_gloss_endpt.sas (emvsx (Phani Tata) / date: 06SEP2023)
 ******************************************************************************/


/*****************************
 *Read data in
 ****************************/

 data gloss ;
     length col1 col2 col3 col4 col5 col6 $1000. ;
      col1="Primary efficacy";
     col2="Main";
     col3="Frequency of HF, week 4, effect of assigned treatment";
     col4="Mean change in frequency of moderate to severe HF from baseline to week 4 (assessed by HFDD)";
     col5="Elinzanetant 120 mg vs. placebo; including all treatment interruptions, premature discontinuation, and prohibited medications (treatment policy)";
     col6="Mean difference";
     row =1 ; output ;
     col1="";
     col2="";
     col3="Frequency of HF, week 12, effect of assigned treatment";
     col4="Mean change in frequency of moderate to severe HF from baseline to week 12 (assessed by HFDD)";
     col5="Elinzanetant 120 mg vs. placebo; including all treatment interruptions, premature discontinuation, and prohibited medications (treatment policy)";
     col6="Mean difference";
     row =2 ; output ;
     col1="";
     col2="1st supplementary";
     col3="Frequency of HF, week 4, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and in absence of prohibited/alternative VMS medications";
     col4="Mean change in frequency of moderate to severe HF from baseline to week 4 (assessed by HFDD)";
     col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy); excluding treatment-unrelated interruptions and premature discontinuation, and prohibited/alternative VMS medications (hypothetical)";
     col6="Mean difference";
     row =3 ; output ;
     col1="";
     col2="";
     col3="Frequency of HF, week 12, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and in absence of prohibited/alternative VMS medications";
     col4="Mean change in frequency of moderate to severe HF from baseline to week 12 (assessed by HFDD)";
     col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy); excluding treatment-unrelated interruptions and premature discontinuation, and prohibited/alternative VMS medications (hypothetical)";
     col6="Mean difference";
     row = 4 ; output ;
     col1="";
     col2="2nd supplementary";
     col3="Frequency of HF, week 4, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and considering initiation of prohibited/ alternative VMS medications as treatment failure";
     col4="Mean change in frequency of moderate to severe HF from baseline to week 4 (assessed by HFDD); treatment failure in case of initiation of prohibited/alternative VMS medications (composite)";
     col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy), and prohibited/alternative VMS medications (composite); excluding treatment-unrelated interruptions and premature discontinuation (hypothetical)";
     col6="Mean difference";
     row =5 ; output ;
     col1="";
     col2="";
     col3="Frequency of HF, week 12, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and considering initiation of prohibited/ alternative VMS medications as treatment failure";
     col4="Mean change in frequency of moderate to severe HF from baseline to week 12 (assessed by HFDD); treatment failure in case of initiation of prohibited/alternative VMS medications (composite)";
     col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy), and prohibited/alternative VMS medications (composite); excluding treatment-unrelated interruptions and premature discontinuation (hypothetical)";
     col6="Mean difference";
     row =6 ; output ;
      col1="Primary efficacy/ key secondary efficacy^&super_a";
      col2="Main";
      col3="Severity of HF, week 4, effect of treatment assignment";
      col4="Mean change in severity of moderate to severe HF from baseline to week 4 (assessed by HFDD)";
      col5="Elinzanetant 120 mg vs. placebo; including all treatment interruptions, premature discontinuation, and prohibited medications (treatment policy)";
      col6="Mean difference";
       row =7 ; output ;
      col1="";
      col2="";
      col3="Severity of HF, week 12, effect of treatment assignment";
      col4="Mean change in severity of moderate to severe HF from baseline to week 12 (assessed by HFDD)";
      col5="Elinzanetant 120 mg vs. placebo; including all treatment interruptions, premature discontinuation, and prohibited medications (treatment policy)";
      col6="Mean difference";
      row =8 ; output ;
      col1="";
      col2="1st supplementary";
      col3="Severity of HF, week 4, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and in absence of prohibited/alternative VMS medications";
      col4="Mean change in severity of moderate to severe HF from baseline to week 4 (assessed by HFDD)";
      col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy); excluding treatment-unrelated interruptions and premature discontinuation, and prohibited/alternative VMS medications (hypothetical)";
      col6="Mean difference";
      row =9 ; output ;
      col1="";
      col2="";
      col3="Severity of HF, week 12, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and in absence of prohibited/alternative VMS medications";
      col4="Mean change in severity of moderate to severe HF from baseline to week 12 (assessed by HFDD)";
      col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy); excluding treatment-unrelated interruptions and premature discontinuation, and prohibited/alternative VMS medications (hypothetical)";
      col6="Mean difference";
      row =10 ; output ;
      col1="";
      col2="2nd supplementary";
      col3="Severity of HF, week 4, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and considering initiation of prohibited/ alternative VMS medications as treatment failure";
      col4="Mean change in severity of moderate to severe HF from baseline to week 4 (assessed by HFDD); treatment failure in case of initiation of prohibited/alternative VMS medications (composite)";
      col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy), and prohibited/alternative VMS medications (composite); excluding treatment-unrelated interruptions and premature discontinuation (hypothetical)";
      col6="Mean difference";
      row =11 ; output ;
      col1="";
      col2="";
      col3="Severity of HF, week 12, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and considering initiation of prohibited/ alternative VMS medications as treatment failure";
      col4="Mean change in severity of moderate to severe HF from baseline to week 12 (assessed by HFDD); treatment failure in case of initiation of prohibited/alternative VMS medications (composite)";
      col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy), and prohibited/alternative VMS medications (composite); excluding treatment-unrelated interruptions and premature discontinuation (hypothetical)";
      col6="Mean difference";
       row =12 ; output ;
      col1="Key secondary efficacy";
      col2="Main";
      col3="Frequency of HF, week 1, effect of treatment assignment";
      col4="Mean change in frequency of moderate to severe HF from baseline to week 1 (assessed by HFDD)";
      col5="Elinzanetant 120 mg vs. placebo; including all treatment interruptions, premature discontinuation, and prohibited medications (treatment policy)";
      col6="Mean difference";
       row =13 ; output ;
      col1="";
      col2="";
      col3="PROMIS SD SF 8b total score, week12, effect of treatment assignment";
      col4="Mean change in PROMIS SD SF 8b total score from baseline to week 12";
      col5="Elinzanetant 120 mg vs. placebo; including all treatment interruptions, premature discontinuation, and prohibited medications (treatment policy)";
      col6="Mean difference";
       row =14 ; output ;
      col1="";
      col2="";
      col3="MENQOL total score, week 12, effect of treatment assignment";
      col4="Mean change in MENQOL total score from baseline to week 12";
      col5="Elinzanetant 120 mg vs. placebo; including all treatment interruptions, premature discontinuation, and prohibited medications (treatment policy)";
      col6="Mean difference";
       row =15 ; output ;
      col1="";
      col2="1st supplementary";
      col3="Frequency of HF, week 1, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and in absence of prohibited/alternative VMS medications";
      col4="Mean change in frequency of moderate to severe HF from baseline to week 1 (assessed by HFDD)";
      col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy); excluding treatment-unrelated interruptions and premature discontinuation, and prohibited/alternative VMS medications (hypothetical)";
      col6="Mean difference";
       row =16 ; output ;
      col1="";
      col2="";
      col3="PROMIS SD SF 8b total score, week12, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and in absence of prohibited/alternative VMS medications";
      col4="Mean change in PROMIS SD SF 8b total score from baseline to week 12";
      col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy); excluding treatment-unrelated interruptions and premature discontinuation, and prohibited/alternative VMS medications (hypothetical)";
      col6="Mean difference";
       row =17 ; output ;
      col1="";
      col2="";
      col3="MENQOL total score, week 12, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and in absence of prohibited/alternative VMS medications";
      col4="Mean change in MENQOL total score from baseline to week 12";
      col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy); excluding treatment-unrelated interruptions and premature discontinuation, and prohibited/alternative VMS medications (hypothetical)";
      col6="Mean difference";
       row =18 ; output ;
      col1="";
      col2="2nd supplementary";
      col3="Frequency of HF, week 1, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and considering initiation of prohibited/ alternative VMS medications as treatment failure";
      col4="Mean change in frequency of moderate to severe HF from baseline to week 1 (assessed by HFDD); treatment failure in case of initiation of prohibited/alternative VMS medications (composite)";
      col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy), and prohibited/alternative VMS medications (composite); excluding treatment-unrelated interruptions and premature discontinuation (hypothetical)";
      col6="Mean difference";
       row =19 ; output ;
      col1="";
      col2="";
      col3="PROMIS SD SF 8b total score, week12, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and considering initiation of prohibited/ alternative VMS medications as treatment failure";
      col4="Mean change in PROMIS SD SF 8b total score from baseline to week 12; treatment failure in case of initiation of prohibited/alternative VMS medications (composite)";
      col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy), and prohibited/alternative VMS medications (composite); excluding treatment-unrelated interruptions and premature discontinuation (hypothetical)";
      col6="Mean difference";
       row =20 ; output ;
      col1="";
      col2="";
      col3="MENQOL total score, week 12, effect of treatment assignment in absence of treatment-unrelated interruptions and premature discontinuation, and considering initiation of prohibited/ alternative VMS medications as treatment failure";
      col4="Mean change in MENQOL total score from baseline to week 12; treatment failure in case of initiation of prohibited/alternative VMS medications (composite)";
      col5="Elinzanetant 120 mg vs. placebo; including treatment-related interruptions and premature discontinuation (treatment policy), and prohibited/alternative VMS medications (composite); excluding treatment-unrelated interruptions and premature discontinuation (hypothetical)";
      col6="Mean difference";
      row =21 ; output ;
 RUN;

 data gloss;
     set gloss;
     label col1="Primary/ key secondary efficacy"
           col2= "Type"
           col3 = "Estimand label"
           col4 = "Endpoint"
           col5 = "Treatment condition"
           col6 = "Summary measure"
           ;
 RUN;
/*************************************************************/
/********************* Output   ******************************/
/*************************************************************/

%mtitle ;
%datalist(
    data     = gloss
  , by       = row
  , var      = col1 col2  col3 col4   col5 col6
  , order    = row
  , freeline = row
  , together =
  , split =  *

)


%endprog();