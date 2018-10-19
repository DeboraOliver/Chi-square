library(redcapAPI)
library(dplyr)
library(tidyr)
library(stats)

rm(list=ls())

#########
#Conecting to redcapAPI
#########

source("token.txt")

rcon <- redcapConnection(url=url, token=token)

rm(token)

##########
#Calling our variables 
##########


vector_baseline <- c("record_id","icc_pd_adm_nyha_q01") 
event_baseline <- "t0_arm_1" 


vector_30days_after <- c("record_id","icc_proms_kccq_score")
event_30days_after <- "30_dias_arm_1"


data_baseline <- exportRecords(rcon,  factors = FALSE,
                        fields = vector_baseline, events = event_baseline)

data_after_treat <- exportRecords(rcon,  factors = FALSE,
                         fields = vector_30days_after,  events = event_30days_after)


#merging both tables

patient_outcome<- merge(data_baseline,data_after_treat, by.x = "record_id", by.y = "record_id") 

patient_outcome <- select(patient_outcome, "record_id", "icc_pd_adm_nyha_q01", "icc_proms_kccq_score") 


#######
#CLEANING
#########


patient_outcome <- mutate_all(patient_outcome, funs(as.numeric), 1:3)


patient_outcome <- filter(patient_outcome, patient_outcome[,2] < 100, patient_outcome[,2] != 'NA', patient_outcome[,3] != 'NA')

#######
#CALCULATING OUR QUARTILES
#########

#double checking our values

verificando <- quantile(patient_outcome$icc_proms_kccq_score,c(0.25,0.5,0.75), na.rm = TRUE)

#calculating and creating a columns for quartiles 

patient_outcome$quartil <- cut(patient_outcome$icc_proms_kccq_score, breaks=quantile(patient_outcome$icc_proms_kccq_score,probs=seq(0,1, by=0.25), na.rm = TRUE), labels=c("Q1","Q2","Q3","Q4")) 

patient_outcome_clean <- select (patient_outcome, "icc_pd_adm_nyha_q01", "quartil") 
 

############
#GERANDO A TABELA DE CONTINGÊNCIA
##################


 outcome_table <- xtabs(~icc_pd_adm_nyha_q01+quartil, data=patient_outcome_clean)


##############
#The Pearson's chi-squared 
#############
 
#a test for independence between categorical variables. 
chi_data <- chisq.test(outcome_table)
chi_data

# Observed counts: gera a nossa tabela inicial (contingency table)
chi_data$observed

# Expected counts
#calculate the expected frequency of observations in each group 
round(chi_data$expected)

#to know the most contributing cells to the total Chi-square score
round(chi_data$residuals,3)


#visualize Pearson residuals using the package corrplot
library(corrplot)

corrplot(chi_data$residuals, is.cor = FALSE)

# Contibution in percentage (%)
contrib <- 100*chi_data$residuals^2/chi_data$statistic
round(contrib, 3)

# Visualize the contribution
corrplot(contrib, is.cor = FALSE)
