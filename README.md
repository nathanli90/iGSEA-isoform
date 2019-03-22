# iGSEA-isoform

## Introduction
The iGSEA-isoform package includes the two proposed methods, iGSEAi-FE and iGSEAi-RE introduced in "Integrative gene set enrichment 
analysis utilizing isoform‐specific expression" (L Li, X Wang, G Xiao, A Gazdar,Genetic epidemiology). iGSEAi stands for integrative Gene Set
Enrichment Analysis with isoform. 
Please refer to https://onlinelibrary.wiley.com/doi/abs/10.1002/gepi.22052.
## User Guide
There are three functions in the pakcage:iGSEAi_Read, iGSEAi_Filt and iGSEAi_Path. 

iGSEAi_Read is used to read isoform data from text and csv files.  
iGSEAi_Read = function(filenames,via=c("txt","csv"),log=TRUE)  

iGSEAi_Filt is used to filter suitable genes and isoforms for the enrichement analysis.  
iGSEAi_Filt = function(data, gene_isoform, via=c("txt","csv"))  

iGSEAi_Path is used to do the enrichment analysis for isoform data and pathways.  
iGSEAi_Path = function(isoformdata, transformation=TRUE, phenotype=binomial, pathway, size.min=15, size.max=500, methods="permutation",nperm=500)
