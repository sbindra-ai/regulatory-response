/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog=#runall_21651_ilistings;
/*
 * Purpose          : Create iListings For Medical Writers
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 08JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/#runall_21652_ilistings.sas (enpjp (Prashant Patel) / date: 06NOV2023)
 ******************************************************************************/


/*< Initialize study */
%initsystems(initstudy=5, mosto=7, spro=3, adamap=2, gral=4, ilisting=1, woops = 1);

%initstudy(
    display_formats = Y
  , inimode         = ANALYSIS
);

/*< Get all metadata of listings in one file */
DATA imeta;
    SET tlfmeta.meta_l: ;
RUN;

/*< Create file for iListing */

%ilisting(
    mosto_allmeta      = imeta
  , filter             = 21651_ph42782_10_.*
  , ilistingdir        = &outdir/ilisting
  , subject_vars       = usubjid uasr randno
);

/*< clean up */
%endprog;
