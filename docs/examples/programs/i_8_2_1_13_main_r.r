#/*******************************************************************************
#* Bayer AG
# * Study            : 21651 A double-blind, randomized, placebo-controlled
# *   multicenter study to investigate efficacy and safety of elinzanetant for
# *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
# * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
# *******************************************************************************
#  *Name of program**************************************************************/
#    %iniprog(name = i_8_2_1_13_main_r.r);
#  /*
#  * Purpose          : Create table of confirmatory testing results for main estimand
#  * Programming Spec :
#  * Validation Level : 2 - Double programming
#  * R Version        : R 3.5.2
#*******************************************************************************
#  * Pre-conditions   :
#  * Post-conditions  :
#  * Comments         :
#  *******************************************************************************
#  * Author(s)        : gfsdv (Ulrike Krahn) / date: 21JUN2023
#  * Reference prog   :
#  ******************************************************************************/

################################################################################  
#PARAMETER:
#         pvalue: pvalues for main estimand
################################################################################


#overall Type I error rate at a one-sided α=0.025 level
#one.sided p values:

options(scipen=99)
library(haven) 
library(dplyr) 
library(lubridate) 
library(readr) 
library(SASxport)

getwd()

p.values0 <- read_sas("p_val_main.sas7bdat")
p.values0
p.values <- as.numeric(p.values0) 
p.values

rej1 <- rej2 <- rej3 <- rej4 <- rej5 <- rej6 <- rej7 <- FALSE
alpha1 <- 0.025
alpha2 <- alpha3 <- alpha4 <- alpha5 <- alpha6 <- alpha7 <- NA

######################      
# Step 1:
 rej1 <- p.values[1]<=alpha1
if(rej1==TRUE){
  alpha2 <- alpha1
}
 rej2 <- rej1 & p.values[2]<=alpha1
  if(rej2==TRUE){

    # Step 2:
    alpha3 <- alpha2/2
    rej3 <- p.values[3]<=alpha3
    if(rej3==TRUE){
    alpha4 <- alpha3
    }  
    rej4 <- rej3 & p.values[4]<=alpha4

    # Step 3:
    if(rej4 == FALSE) { # H_04 is not rejected in Step 2

      alpha5 <- 0.025/4
      rej5 <- p.values[5] <= alpha5
      if(rej5==TRUE)
        alpha6 <- 0.025/2
        rej6 <- p.values[6] <= alpha6
      if(rej5==FALSE)
        alpha6 <- 0.025/4
        rej6 <- p.values[6] <= alpha6

      if(rej6==TRUE & rej5 == FALSE)
        alpha5 <- 0.025/2
        rej5 <- p.values[5] <= alpha5
    }

    if(rej4 == TRUE) { # H_04 is rejected in Step 2

      alpha5 <- 0.025/2
      rej5 <- p.values[5] <= alpha5

      if(rej5==TRUE)
        alpha6 <- 0.025
        rej6 <- p.values[6] <= alpha6
      if(rej5==FALSE)
        alpha6 <- 0.025/2
        rej6 <- p.values[6] <= alpha6

      #if H_05 is not rejected in Step 3A and H_06 is rejected in Step 3B
      if(rej6==TRUE & rej5 == FALSE)
        alpha5 <- 0.025
        rej5 <- p.values[5] <= alpha5
    }

    # step 4, if both H_05 and H_06 are rejected
    if(rej5==TRUE & rej6==TRUE){
      if(rej4 ==TRUE)                      #level if H_04 is rejected in Step 2
        alpha7 <- 0.025
        rej7 <-  p.values[7] <= alpha7
      if(rej4 ==FALSE)                     #if H_04 is not rejected in Step 2 
        alpha7 <- 0.025/2 
        rej7 <-  p.values[7] <= alpha7
    }

    #step 5
    if(rej7==TRUE & rej3==FALSE & rej4==FALSE) {     #If H_03 is not rejected in Step 2, re-test the hypothesis H_03       
      alpha3 <- 0.025 
      rej3 <- p.values[3]<=alpha3
      if (rej3 ==TRUE)
      alpha4 <- 0.025   
      rej4 <- p.values[4]<=alpha4
    }
  }

  alpha <- c(alpha1,alpha2,alpha3,alpha4,alpha5,alpha6,alpha7)
  rej <- c(rej1, rej2, rej3, rej4, rej5, rej6, rej7)
  names(rej) <- paste("H", 1:7, sep="")
  names(alpha) <- paste("H", 1:7, sep="")
  alpha
  rej

  i_8_2_1_13_gmcp <- cbind(alpha, p.values, rej)
  write.csv(i_8_2_1_13_gmcp ,  "i_8_2_1_13_gmcp.csv"  )



