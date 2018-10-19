Pearson's Chi-Square Test of Independence for NYHA and KCCQ
================
Debora Oliveira

Overview
--------

The Chi-Square test of independence, also called Pearson's chi-square test is used to determine if there is a significant relationship between two nominal (categorical) variables. It offers a great advantage once it is a nonparametric statitical procedure that does not require a normal distribution. Thus,the result determines whether the association between the variables is statistically significant. Moreover, it allows the examination of differences between expected counts and observed counts to determine which variable levels may have the most impact on association.


1.Requirements
---------------


To run this project you need the following libraries:

``` r
library(redcapAPI)
library(dplyr)
library(stats)
library(corrplot)
```

### i) Library(redcapAPI)

This project uses data from REDCap. The package redcapAPI contain functions such as exportfields(), exportevents() that allows to choose between different events, or moments, in a clinical trial. For this project only two functions will be important: redcapConnection(), that requires a url and a token, exportRecords() to bring patient's records. However, without redcapAPI a csv file with data exported from REDCap could be used as a source.

``` r
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
```

### ii) Library(dplyr)

For the project, the package dplyr is mainly used during the cleaning and data rearrangement. Thus, the function merge() allows to merge two dataframes combining them through the patient's record\_id.

``` r
patient_outcome<- merge(data_baseline,data_after_treat, by.x = "record_id", by.y = "record_id") 
```

Another very useful function from dplyr package would be select() since exportRecords() brings few not called information.

``` r
patient_outcome <- select(patient_outcome, "record_id", "icc_pd_adm_nyha_q01", "icc_proms_kccq_score") 
```

The package still provide another two important functions: mutate\_all() and filter(). The first used to turn the dataframe into numeric while, the second allows to filter missing data.

``` r
patient_outcome <- mutate_all(patient_outcome, funs(as.numeric), 1:3)

patient_outcome <- filter(patient_outcome, patient_outcome[,2] < 100, 
                          patient_outcome[,2] != 'NA', patient_outcome[,3] != 'NA')
```

The result of this entire cleaning process will be a two column table with both variables to compare.

    ##   record_id icc_pd_adm_nyha_q01 icc_proms_kccq_score
    ## 1         1                   0              92.1875
    ## 2       103                   2              25.0000
    ## 3      1083                   3             100.0000
    ## 4      1086                   3             100.0000
    ## 5      1107                   1              96.8750
    ## 6      1130                   3              87.5000

### iii) Library(stats)

The package stats allows to get quartiles, a contingency table and the chi-square. Firstly, the function quartile() takes a sequence of values from a vector, sorting it (ascending) and then produces sample quantiles corresponding to a given probability:

``` r
checking_quartiles <- quantile(patient_outcome$icc_proms_kccq_score,c(0.25,0.5,0.75), na.rm = TRUE)

patient_outcome$quartil <- cut(patient_outcome$icc_proms_kccq_score,
                               breaks=quantile(patient_outcome$icc_proms_kccq_score,probs=seq(0,1, by=0.25),
                                               na.rm = TRUE), labels=c("Q1","Q2","Q3","Q4")) 
```

The result of this process:

    ##   icc_pd_adm_nyha_q01 quartil
    ## 1                   0      Q4
    ## 2                   2      Q1
    ## 3                   3      Q4
    ## 4                   3      Q4
    ## 5                   1      Q4
    ## 6                   3      Q3

Once the data is clean and fits a xtabs() function, the following step is to create a contingency table:

``` r
outcome_table <- xtabs(~icc_pd_adm_nyha_q01+quartil, data=patient_outcome_clean) 
```

The contigency table will look like:

    ##                    quartil
    ## icc_pd_adm_nyha_q01 Q1 Q2 Q3 Q4
    ##                   0  0  0  0  2
    ##                   1  0  6  5  3
    ##                   2 13 10  5  6
    ##                   3  9  7 12 10

Lastly but not the least, the Pearson's chi-square test from the function chisq.test() will return de values for X-square, df and p-value.

``` r
chi_data <- chisq.test(outcome_table)
```

### iv) Library(corroplot)

The last part of this project requires the package corroplot to visualize Pearson residuals.
``` r
corrplot(chi_data$residuals, is.cor = FALSE)

contrib <- 100*chi_data$residuals^2/chi_data$statistic
round(contrib, 3)
```

    ##                    quartil
    ## icc_pd_adm_nyha_q01     Q1     Q2     Q3     Q4
    ##                   0  2.745  2.870  2.745 26.671
    ##                   1 19.215  8.222  3.529  0.191
    ##                   2 13.079  0.766  7.912  3.023
    ##                   3  0.144  4.751  3.612  0.526

``` r
# Visualize the contribution
corrplot(contrib, is.cor = FALSE)

```

2.Further Explanations
----------------------

<http://www.sthda.com/english/wiki/chi-square-test-of-independence-in-r>
