# OpenVA - Open software platform for visual analytics
#
# Copyright (c) 2018, VTT Technical Research Centre of Finland Ltd
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1) Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2) Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 3) Neither the name of the VTT Technical Research Centre of Finland nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Author: Paula Järvinen, Pekka Siltanen

library(RPostgreSQL)
args <- commandArgs(trailingOnly = F)
scriptPath <- dirname(sub("--file=","",args[grep("--file",args)]))
print(scriptPath)

connectDB <- function()
{
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

source(paste(scriptPath, "common.R", sep="/"))

#cormat: Only for timeseries variables

deploy_cormat=function(variable_ids,oi_ids,starttime,endtime,dbcon,imagetype)
{  
  on.exit(dbDisconnect(dbcon))
  oiids=oi_ids
  oiids_temp=paste("(",oiids,")",sep="")
  my_ois=getOIs(dbcon,oiids_temp)
  ois_title=(paste(my_ois$report_title,sep=",",collapse=","))

  varids_temp=as.list(strsplit(variable_ids, ",")[[1]])

  #get metadata of all variables
  my_metadata=data.frame(id=numeric(),title=character(),variabletype=character(),oitype=character(),time_unit=character(),stringsAsFactors=FALSE) 
  for (i  in 1:length(varids_temp)){           
    my_meta=getMetadata(dbcon,varids_temp[i])
  
    my_metadata[i,"id"]=my_meta$id
    my_metadata[i,"title"]=my_meta$report_title
    my_metadata[i,"variabletype"]=my_meta$variabletype
    my_metadata[i,"oitype"]=my_meta$oitype_title
    my_metadata[i,"time_unit"]=my_meta$time_unit
    oitype = my_meta$oitype_title
  }

  #all same oitype? 
  if (length(unique(my_metadata$oitype))>1) { stop("OpenVA warning: Correlation matrix: too many oitypes")}
  #all timeseries variables? 
  if (all(my_metadata$variabletype=='ts')) 
  { 
        my_variable_id=varids_temp[[1]]

        #read first variable data
        my_var_values= getVariableValues_partition(dbcon,my_variable_id, oiids,oitype=oitype,starttime,endtime,TRUE)
        #print(my_var_values)
        #print (nrow(my_var_values))
        #data found
        if(nrow(my_var_values)==0) {
            stop(paste("OpenVA warning: No data found ",ois_title,my_metadata[1,"title"]) )
        }
    
        #clean and transform to timeseries  
        my_var_values=my_var_values[complete.cases(my_var_values),] 
        my_var_zoo=zoo(my_var_values$measurement_value,my_var_values$measurement_time)
        rm(my_var_values)
        gc()
        if (any(my_metadata$time_unit=='day'))
        {   
            my_merge=aggregate(my_var_zoo, format(index(my_var_zoo),'%Y-%m-%d'), mean)
        } else { 
            my_merge=aggregate(my_var_zoo, format(index(my_var_zoo),'%Y-%m-%d %H:%M'), mean)
        }
        rm(my_var_zoo)
        gc()
    
        #read rest and merge
        for (i in 2:length(varids_temp))
        {      
            my_variable_id=varids_temp[[i]]
            my_var_values= getVariableValues_partition(dbcon,my_variable_id, oiids,oitype=oitype,starttime,endtime,TRUE)
            if(nrow(my_var_values)==0) {
                stop(paste(",OpenVA warning: No data found ",ois_title,my_metadata[i,"title"]) )
            }
 
            #data found
            my_var_values=my_var_values[complete.cases(my_var_values),] 
            my_var_zoo=zoo(my_var_values$measurement_value,my_var_values$measurement_time)
            rm(my_var_values)
            gc()
            if (any(my_metadata$time_unit=='day'))
            {   
                my_var_merge=aggregate(my_var_zoo, format(index(my_var_zoo),'%Y-%m-%d'), mean)
            } else { 
                my_var_merge=aggregate(my_var_zoo, format(index(my_var_zoo),'%Y-%m-%d %H:%M'), mean)
            }
            rm(my_var_zoo)
            gc()
            my_merge=(merge(my_merge,my_var_merge)) 
        }
    
        my_cor_frame=fortify.zoo(my_merge)
        rm(my_merge)
        gc()
        my_cor_frame=my_cor_frame[,2:ncol(my_cor_frame)]
        colnames(my_cor_frame)=my_metadata$title
        #head(my_cor_frame)
    } else {
        #mixed, join by oi_title

        my_variable_id = varids_temp[[1]]
        my_var_values= getVariableValues_partition(dbcon,my_variable_id, oiids,oitype=oitype,starttime,endtime,TRUE)
        if(nrow(my_var_values)==0) {
            stop(paste("OpenVA warning: No data found ",ois_title,my_metadata[i,"title"]) )
        }
        if (my_metadata[1,"variabletype"]=="ts")
        {      
            my_merge=aggregate(my_var_values$measurement_value, by = list(my_var_values$oi_id), FUN = mean)
        } else {
            my_merge=my_var_values[,c("oi_id","value")]
        }
        rm(my_var_values)
        gc()
        colnames(my_merge)=c("oi_id",my_metadata[1,"title"])
    
        for (i in 2:length(varids_temp))
        {   
            #print(i)
            my_variable_id = as.integer(varids_temp[[i]])
            my_var_values= getVariableValues_partition(dbcon,my_variable_id,oitype=oitype, oiids,starttime,endtime,TRUE)
            if(nrow(my_var_values)==0) {
                stop(paste("OpenVA warning: No data found ",ois_title,my_metadata[i,"title"]) )
            }
            if (my_metadata[i,"variabletype"]=="ts")
            {       
            #   print("TS")
        
                my_var_merge=aggregate(my_var_values$measurement_value, by = list(my_var_values$oi_id), FUN = mean)
            } else {
                my_var_merge=my_var_values[,c("oi_id","value")]
            }
            rm(my_var_values)
            gc() 
     
            colnames(my_var_merge)=c("oi_id",my_metadata[i,"title"])
            my_merge = merge(my_merge, my_var_merge, by="oi_id")
            rm(my_var_merge)
            gc() 
        }
        my_cor_frame=my_merge[,2:ncol(my_merge)]
        rm(my_merge)
        gc() 
    }
    #plot preparations 

  
    my_cor_frame = my_cor_frame[complete.cases(my_cor_frame),]
    if (nrow(my_cor_frame)==0) {
        stop(paste("OpenVA warning: No joint data found ",ois_title,my_metadata[i,"title"],variable_ids) )
    }
    #print("merge ok")
    #print(head(my_merge))
  
    #if (ncol(my_cor_frame) < 3) {stop("OpenVA warning: Not enough variables for correlation matrix") }
    if (nrow(my_cor_frame) <= 3) {
        stop("OpenVA warning: Not enough observations for correlation matrix") 
    }
    #print("get_observation_matrix OK")
    # print(my_cor_frame)
    n=nrow(my_cor_frame)
    title=paste("Correlation matrix",ois_title)
  
    if (is.null(starttime)) {
        chart_title = paste("\n",title," n= ",n)
    } else {
        chart_title = paste("\n\n",title,"\nn= ",n, " ", starttime, " - ", endtime)
    }
    #print(chart_title)
    #plot
  
    #print(head(my_frame))
    #print("CORS")
 
    correlations <- cor(my_cor_frame,use="complete.obs")
    #print(correlations)
    #corrplot(correlations, method="circle",title=chart_title)
    
    corrplot.mixed(correlations, lower="number",upper="circle",title=chart_title)
  

    #corrplot(correlations, type="upper", method="circle",
    #         tl.pos="lt", tl.col="black",  tl.offset=1, tl.srt=0)
    #   corrplot(correlations, add=T, type="lower", method="number",
    #      col="black", diag=F, tl.pos="n", cl.pos="n")
    # n <- nrow(correlations)
    #symbols(1:n, n:1, add=TRUE, bg="white", fg="grey", inches=F, squares=rep(1, n))
  
    #return_matrix=as.matrix(my_cor_frame[1,])
    variableNames <-colnames(correlations)

  
    #print(unlist(strsplit(variable_ids, split=",")))
    
    colnames(correlations) <- NULL
    rownames(correlations) <- NULL
    correlations = apply(correlations, 1, as.list)
    
    return_list <- list(correlations,variableNames,chart_title,unlist(strsplit(variable_ids, split=",")),unlist(strsplit(oi_ids, split=",")),imagetype)
    names(return_list) <-c("correlations","variableNames","title","variableids","oiids","imagetype")
    rm(my_cor_frame)
    gc() 
    #return_list <- list("No vector data returned yet",imagetype)
    #names(return_list) <-c("info","imagetype")
    return(return_list)
}

varids = "<varids>"
oiids = "<oiids>"
oitype = "<oitype>"
imagetype = "<imagetype>"
starttime = "<starttime>"
endtime = "<endtime>"
timeunit = "<timeunit>"
outputfile = "<outputfile>"
localResultFile = "<localResultFile>"
resultUrl = "<resultUrl>"

if (starttime=="null")  {
	starttime=NULL;
}
if (endtime=="null")  {
	endtime=NULL;
}


output_data <- tryCatch(
		{			
			suppressWarnings(
					{
					  	if (imagetype == "vector") {
    						svglite(localResultFile)
  						} else {
							png(filename=localResultFile)
						}
						dbcon <- connectDB()
						data <- deploy_cormat(varids,oiids,starttime,endtime,dbcon,imagetype)
						data["image"] = resultUrl
						data
					}
				)	
		},
		error=function(cond) {
			message(cond)
			return_list <- list(cond$message)
			names(return_list) <-c("error")
			return(return_list)
		},
		finally={
			dev.off()
		})

print(output_data)
write(toJSON(output_data), file=outputfile)