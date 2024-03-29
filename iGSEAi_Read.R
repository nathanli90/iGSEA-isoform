iGSEAi_Read <-
function(filenames,via=c("txt","csv"),log=TRUE){
## number of studies ##
K = length(filenames)
expdata = list()
for(i in 1:K){
## read txt or csv files ##
if(via=="txt"){
raw = read.table(paste(filenames[i],".txt",sep=""),sep="\t",header=T,row.names=1)
}else{
raw = read.csv(paste(filenames[i],".csv",sep=""),header=T,row.names=1)}
y = as.numeric(raw[1,])
## log(x+1) transformation ##
if (log){
exprs = log(t(raw[-1,])+1)
}else{
exprs = raw[-1,]}
expdata[[i]] = list(x=as.matrix(exprs),y=y)
## add names to isoform data and phenotypes ##
names(expdata[[i]]) = c("isoform","phenotypes")
}
## add study names ##
names(expdata) = paste(filenames)
return(expdata)
}
