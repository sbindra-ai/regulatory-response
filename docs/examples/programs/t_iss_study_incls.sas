/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
%iniprog(name = t_iss_study_incls)
;
/*
 * Purpose          : Overview of studies included
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gdcpl (Derek Li) / date: 29FEB2024
 * Reference prog   :
 ******************************************************************************/

/*****************************
 *Read data in
 ****************************/


DATA gloss ;
    LENGTH col1 col2 col3 col4 col5 col6 $1000. ;
    LABEL col1='Study name'
           col2='Study ID'
           col3='Phase'
           col4='Planned treatment# duration'
           col5='Treatment arms'
           col6='Inclusion in this# integrated analysis'
           ;
    col1="SWITCH-1";
    col2="21686";
    col3="2b";
    col4='12 weeks';
    ARRAY _arms[5] $60 _TEMPORARY_ ('Elinzanetant 40 mg','Elinzanetant 80 mg','Elinzanetant 120 mg','Elinzanetant 160 mg','Placebo');
    ARRAY _yn[5] $10 _TEMPORARY_ ('No','No','Yes','No','Yes');
    row=1;
    DO i=1 TO dim(_arms);
        col5=_arms[i];
        col6=_yn[i];
        OUTPUT;
    END;
    col1="OASIS 1";
    col2="21651";
    col3="3";
    col4='12+14 weeks';
    ARRAY _arms1[2] $60 _TEMPORARY_ ('Elinzanetant 120 mg','Placebo - Elinzanetant 120 mg');
    ARRAY _yn1[2] $10 _TEMPORARY_ ('Yes','Yes');
    row=2;
    DO i=1 TO dim(_arms1);
        col5=_arms1[i];
        col6=_yn1[i];
        OUTPUT;
    END;

    col1="OASIS 2";
    col2="21652";
    col3="3";
    col4='12+14 weeks';
    ARRAY _arms2[2] $60 _TEMPORARY_ ('Elinzanetant 120 mg','Placebo - Elinzanetant 120 mg');
    ARRAY _yn2[2] $10 _TEMPORARY_ ('Yes','Yes');
    row=3;
    DO i=1 TO dim(_arms2);
        col5=_arms2[i];
        col6=_yn2[i];
        OUTPUT;
    END;
    col1="OASIS 3";
    col2="21810";
    col3="3";
    col4='52 weeks';
    ARRAY _arms3[2] $60 _TEMPORARY_ ('Elinzanetant 120 mg','Placebo');
    ARRAY _yn3[2] $10 _TEMPORARY_ ('Yes','Yes');
    row=4;
    DO i=1 TO dim(_arms3);
        col5=_arms3[i];
        col6=_yn3[i];
        OUTPUT;
    END;

RUN;

/*************************************************************/
/********************* Output   ******************************/
/*************************************************************/

%set_titles_footnotes(
    tit1 = "Table: Overview of studies included  "
  , ftn1 = "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks."
)
;

%datalist(
    data     = gloss
  , by       = row  col1 col2  col3 col4
  , var      = col5 col6
  , order    = row
  , freeline = row
  , together =
  , split    = '#'
)
;

%endprog()
;
