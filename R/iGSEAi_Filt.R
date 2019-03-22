iGSEAi_Filt <-
function(data, gene_isoform, via=c("txt","csv"),num_iso=20){
require(plyr)
## read txt or csv files ##
if(via=="txt"){
gene_iso_temp  = read.table(paste("gene_isoform",".txt",sep=""),sep="\t",header=F)
}else{
gene_iso_temp  = read.csv(paste("gene_isoform",".csv",sep=""), header=F)}
## find suitable gene names (# of isoform <= num_iso)
gene_name = unique(count(gene_iso_temp, "V2")[,1][which(count(gene_iso_temp, "V2")[,2] <= num_iso)])
gene_iso = gene_iso_temp[which(gene_iso_temp[,2]%in%gene_name),]
K = length(data)
filtdata = list()
gene_total = list()
## choose corresponding isoform-level data ##
for(i in 1:K){
location = match(gene_iso[,3], colnames(data[[i]][[1]]))
filtdata[[i]] = list(data[[i]][[1]][,location[!is.na(location )]], data[[i]][[2]])
names(filtdata[[i]]) = names(data[[i]])
gene_total[[i]] = colnames(data[[i]][[1]])
}
## assign study names ##
names(filtdata) = names(data)
gene_iso_final = gene_iso[which(gene_iso[,3]%in%unique(unlist(gene_total))),]
## return chosen isoform-level data, phenotype, gene and isoform name ##
results = list(filtdata, gene_iso_final)
names(results) = c("Data","gene_isoform")
return(results)
}
