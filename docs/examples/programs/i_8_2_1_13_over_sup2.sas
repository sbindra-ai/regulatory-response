/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = i_8_2_1_13_over_sup2   );
/*
 * Purpose          : 8.2.1.13 Overview of the main analyses results
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/i_8_2_1_13_over_sup2.sas (sgtja (Katrin Roth) / date: 07JUL2023)
 ******************************************************************************/
;

%let tfldata = i_8_2_1_13_gmcp_sup2 ;

data t_prog ;
  set tlfmeta.&tfldata.;

 length alphac p_valuesc $20;
 if alpha = "NA" then alphac =  "    -";
  if alpha ^= "NA" then do ;
      alphac =  strip(put(input(strip(alpha), best12.5 ) , z6.4))   ;
  end ;
  p_valuesc = strip(Put(p_values, Pvalue6.4));
  attrib alphac label = "Significance level"
         p_valuesc label = "p-value (one-sided)"  ;
  drop alpha p_values;
run;

%set_titles_footnotes(
        tit1 = Table: Overview of testing of statistical hypotheses for the second supplementary estimand
    ,   ftn1 = Significance level according to multiple testing strategy

 );


%datalist(
    data  = t_prog
  , var   = Var1 eff_var  alphac  p_valuesc rejc
   , maxlen           = 25
)


%endprog();
