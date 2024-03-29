iGSEAi_Path <-
function(isoformdata, transformation=TRUE, phenotype="binomial", pathway, size.min=15, size.max=500, methods="permutation",nperm=500){
require(limma)
require(GSEABase)
require(psych) 
require(qvalue)
K = length(isoformdata[[1]])
gene_name = unique(isoformdata[[2]][,2])
## find gene names in pathway ##
Gene_ID = isoformdata[[2]][,1][match(gene_name,isoformdata[[2]][,2])]
## total number of genes in studies ##
G = length(gene_name)

## calculate the isoform locations and the number of isoforms within each gene in each study ##
Iso_loc = list()
iso_len = list()
for (i in 1:K){
loc_cal = function(x,w){
return(which(isoformdata[[2]][match(colnames(isoformdata[[1]][[w]][[1]]), isoformdata[[2]][,3]),1]%in%x))
}
Iso_loc[[i]] = sapply(Gene_ID, loc_cal, w=i)
iso_len[[i]] = lapply(1:G, function(g) length(Iso_loc[[i]][[g]]))
}
## only keep the genes with the same number of isoforms in different study ##
Check = function(g){
ww = sapply(iso_len, "[[",g)
return(all(ww[ww>0]==max(ww)))
}
Update = sapply(1:G, Check)
G = length(Update[Update==TRUE])
## no suiable genes ##
if (G == 0) stop("No suitable genes to analyze")
## update gene names ##
gene_name = gene_name[Update]
Gene_ID = Gene_ID[Update]
Iso_loc = lapply(1:K, function(k) Iso_loc[[k]][Update])
iso_len = lapply(1:K, function(k) iso_len[[k]][Update])  
iso_number = lapply(1:G, function(g) max(sapply(iso_len, "[[", g)))

## Choose Pathway ##
Pathway_temp = lapply(pathway, geneIds)
set.name = names(pathway)
gene.common = intersect(gene_name,unique(unlist(Pathway_temp)))
Path_loc_cal = function(p){
geneId = geneIds(pathway[[p]])
pathlen = length(intersect(geneId,gene_name))
if (size.min <= pathlen & pathlen <=  size.max & pathlen<length(gene_name)) {return(p)}
else {return(NA)}
}
Path_loc = lapply(1:length(set.name), Path_loc_cal)
## suiable pathways ##
pathway_new = pathway[unlist(Path_loc[!is.na(Path_loc)])]
## pathway names ##
set.name_new = names(pathway_new)
Pathway = lapply(pathway_new, geneIds)
P_num = length(set.name_new)
if (P_num == 0) stop("No suitable pathway")

## Median Transformation ##
## default is true ##
if (transformation){
Isoform_Data = lapply(1:K, function(x) normalizeBetweenArrays(isoformdata[[1]][[x]][[1]]))
}else{
Isoform_Data = lapply(1:K, function(x) isoformdata[[1]][[x]][[1]])}

## function to calculate Ukg and Vkg if phenotype is binomial ##
if (phenotype == "binomial"){
Ukg_Vkg_cal = function(i, Iso_loc, response){
temp = glm(response ~ 1, family="binomial")
f1 = function(x){
if (length(x) == 0){
## Ukg and Vkg are 0 if the gene g is not in study k ##
Ukg = 0
Vkg = 0
}else{
Ukg = t(response-exp(temp$coefficients[1])/(1+exp(temp$coefficients[1])))%*%Isoform_Data[[i]][,x]
Vkg = exp(temp$coefficients[1])/((1+exp(temp$coefficients[1]))^2)*t(Isoform_Data[[i]][,x])%*%Isoform_Data[[i]][,x]}
 return(list(Ukg,Vkg))
}
return(lapply(Iso_loc, f1))
}
} else {
## function to calculate Ukg and Vkg if phenotype is normal ##
Ukg_Vkg_cal = function(i, Iso_loc, response){
temp = glm(response ~ 1, family="gaussian")
f1 = function(x){
if (length(x) == 0){
Ukg = 0
Vkg = 0
}else{
Ukg = 1/var(response)*t(response - temp$coefficients[1])%*%Isoform_Data[[i]][,x]
Vkg = 1/var(response)*t(Isoform_Data[[i]][,x])%*%Isoform_Data[[i]][,x]}
 return(list(Ukg,Vkg))
}
return(lapply(Iso_loc, f1))
}
}
## calculate Ukg and Vkg ##
Ukg_Vkg = list()
for (i in 1:K){
Ukg_Vkg[[i]] = Ukg_Vkg_cal(i, Iso_loc[[i]], isoformdata[[1]][[i]][[2]])
}

## calculate Qg for FE and RE ##
Qg_cal = function(Ukg_Vkg){
## combine Ukg and Vkg into Ug and Vg ##
Ug =  lapply(1:G, function(g) Reduce("+",lapply(1:K, function(k) Ukg_Vkg[[k]][[g]][[1]])))
Vg =  lapply(1:G, function(g) Reduce("+",lapply(1:K, function(k) Ukg_Vkg[[k]][[g]][[2]])))
Qg_cal_temp = function(g){
f = function(m) class(try(solve(m),silent=T))=="matrix"
if (f(Vg[[g]]) == TRUE){
return(Ug[[g]]%*%solve(Vg[[g]])%*%t(Ug[[g]]))
}else {return(0)}
}
## calculate Qg of FE ##
Qg_fix = lapply(1:G, Qg_cal_temp)
## calculate for random part ##
Ug_Sig = lapply(1:G, function(g) Reduce("+",lapply(1:K, function(k) 0.5*Ukg_Vkg[[k]][[g]][[1]]%*%diag(rep(1, length(Ukg_Vkg[[k]][[g]][[1]])))%*%t(Ukg_Vkg[[k]][[g]][[1]])))- 0.5*tr(Vg[[g]]%*%diag(rep(1, length(Ug[[g]])))))
Vg_Sig = list()
for (g in 1:G){
Vg_K = list()
for (k in 1:K){
f = function(m) class(try(solve(m),silent=T))=="matrix"
if (f(Ukg_Vkg[[k]][[g]][[2]]) == FALSE){Vg_K[[k]] = 0}
else {Vg_K[[k]] = Ukg_Vkg[[k]][[g]][[2]]%*%diag(rep(1, length(Ukg_Vkg[[k]][[g]][[1]])))%*%Ukg_Vkg[[k]][[g]][[2]]%*%diag(rep(1, length(Ukg_Vkg[[k]][[g]][[1]])))}
}
Vg_Sig[[g]] = 0.5*tr(as.matrix(Reduce("+", Vg_K)))
}
## calculate Qg of RE ##
Qg_ran = list()
for (g in 1:G){
if (Vg_Sig[[g]] == 0){Qg_ran[[g]] = Qg_fix[[g]]}
else{Qg_ran[[g]] = Qg_fix[[g]]+(Ug_Sig[[g]])^2/Vg_Sig[[g]]}
}
return(list(Qg_fix, Qg_ran))
}
Qg = Qg_cal(Ukg_Vkg)

## asymptotic method to calculate p-values of Qg based on chi-squared ##
if (methods == "asymptotic"){
Qg_P = list(lapply(1:G, function(x) 1-pchisq(Qg[[1]][[x]], iso_number[[x]])), lapply(1:G, function(x) 1-pchisq(Qg[[2]][[x]], iso_number [[x]]+1)))}else
{
## permutation method to caluculate p-values using Algorithm 2 ##
## calculate number of perumtation times ##
Per_num = ceiling(exp(log(nperm)/K)*2)
## permute phenotypes ##
response = list()
for (k in 1:K){
response[[k]] = replicate(Per_num,sample(isoformdata[[1]][[k]][[2]]))
}
## calculate permutations of Ukg and Vkg ##
Ukg_Vkg_per = list()
for (n in 1:Per_num){
Ukg_Vkg_temp = list()
for (i in 1:K){
Ukg_Vkg_temp[[i]] = Ukg_Vkg_cal(i, Iso_loc[[i]],response[[i]][,n])
}
Ukg_Vkg_per[[n]] = Ukg_Vkg_temp
}
## randomly choose Ukg and Vkg from permutations, and conduct new permutations ## 
Ukg_Vkg_comb = list()
for (n in 1:nperm){
Ukg_Vkg = list()
for (i in 1:K){
num = sample(c(1:Per_num),1)
Ukg_Vkg[[i]] = Ukg_Vkg_per[[num]][[i]]
}
Ukg_Vkg_comb[[n]] = Ukg_Vkg
}
## calculate permutation of Qg ##
Qg_per = list()
for (n in 1:nperm){
Qg_per[[n]] = Qg_cal(Ukg_Vkg_comb[[n]])
}
## calculate p-values of Qg ##
Qg_P = list()
for (i in 1:2){
temp = lapply(Qg_per, "[[", i)
Qg_P[[i]] = sapply(1:G, function(g) 1-sum(Qg[[i]][g]>=sapply(temp, "[[", g))/nperm)
}
}

## ordered gene names according to p-values ##
Geneorder = lapply(Qg_P, function(x) as.character(gene_name[sort.int(unlist(x), index.return=TRUE)$ix]))

## set analysis ##
## permute gene names randomly 500 times ##
NADD = 500
## permutations of ordered gene names ##
Geneorder_per = lapply(1:NADD, function(x) sample(Geneorder[[1]]))
## one-sided KS (OKS) based on permutations ##
Vp_cal_per = function(pathway){
Vp_cal_cal = function(Geneorder){
Pathord_temp = match(pathway, Geneorder) ## in pathway order ##
Pathord = Pathord_temp[!is.na(Pathord_temp)]
OutPathord = c(1:G)[-Pathord]
Vp = as.numeric(ks.test(Pathord, OutPathord, alternative = "greater" )$statistic)
return(Vp)
}
return(sapply(Geneorder_per, Vp_cal_cal))
}
Vp_per = sapply(Pathway, Vp_cal_per)
## OKS based on calculate p-values: 1 for FE, and 2 for RE ##
Vp_cal_star = function(k){
Vp_cal =  function(pathway){
Pathord_temp = match(pathway, Geneorder[[k]]) ## in pathway order ##
Pathord = Pathord_temp[!is.na(Pathord_temp)]
OutPathord = c(1:G)[-Pathord]
Vp = as.numeric(ks.test(Pathord, OutPathord, alternative = "greater" )$statistic)
return(Vp)
}
return(sapply(Pathway, Vp_cal))
}
Vp = lapply(1:2, Vp_cal_star)

## adjustment of OKS ##
Pathway_len_cal = function(p){
intersect(Pathway[[p]],gene.common)
}
Pathway_len = lapply(1:P_num, Pathway_len_cal)
Vp_per_ad = sapply(1:P_num, function(i) Vp_per[,i]/sqrt((1/length(intersect(Pathway[[i]],gene_name)))+(1/(G-length(intersect(Pathway[[i]],gene_name))))))
Vp_ad_cal = function(k){
sapply(1:P_num, function(i) Vp[[k]][i]/sqrt((1/length(intersect(Pathway[[i]],gene_name)))+(1/(G-length(intersect(Pathway[[i]],gene_name))))))
}
Vp_ad = sapply(1:2, Vp_ad_cal)

## p-values for one pathway ##
if (P_num == 1){Qg_Method = lapply(1:2, function(k) 1-sum(Vp_ad[k]>=Vp_per_ad)/NADD)
Results = cbind(Qg_Method[[1]],Qg_Method[[2]])
} else 
## Q-values for multiple pathways ##
{Qg_Method = lapply(1:2, function(k) qvalue(p = empPvals(stat = Vp_ad[,k], stat0 = t(Vp_per_ad))))
Results = cbind(Qg_Method[[1]]$qvalues,Qg_Method[[2]]$qvalues)}
## add row and column names to results ##
rownames(Results) = set.name_new
colnames(Results) = c("iGSEAi_FE","iGSEAi_RE")
return(Results)
}
