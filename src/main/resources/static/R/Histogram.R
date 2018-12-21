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
source(paste(scriptPath, "common.R", sep="/"))

connectDB <- function()
{
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}


deploy_histogram=function(variableid, oitype,oiids=NULL, starttime=NULL, endtime=NULL,plot_time_unit,dbcon,imagetype)
{  
    on.exit(dbDisconnect(dbcon))
    my_meta=getMetadata(dbcon,variableid)
    
    print(paste(variableid,oiids,oitype,starttime,endtime,plot_time_unit))
    my_frame=getVariableValues_partition_aggregated_by_time(dbcon,variableid, oiids,oitype,starttime,endtime,fast=FALSE, plot_time_unit,row_limit=NULL) 
print("getVariableValues_partition_aggregated_by_time OK")
    n=nrow(my_frame)

    if(n==0) {
        stop (paste("OpenVA warning: no data found",   my_meta$report_title, sep=" "))
    }
    
    #time unit transformations 
     #print(paste("time unit transformations starts",Sys.time()))
        operation=my_meta$plottype
        oiids_temp=paste("(",oiids,")",sep="")
        my_ois=getOIs(dbcon,oiids_temp,oitype=my_meta$oitype_title)
        
        #return_list=create_ts_object_quantitative(my_frame, plot_time_unit,variableid,meta=my_meta) #saa tulla warning
     #print("end")
        zoo_frame=zoo(my_frame$measurement_value,my_frame$measurement_time)
        timeunit=paste(plot_time_unit,"s",sep="")
        plot_zoo=period.apply(zoo_frame, endpoints(zoo_frame, timeunit), operation)
        plot_zoo <- na.omit(plot_zoo)
        zoo_frame=fortify.zoo(plot_zoo)
        colnames(zoo_frame)=c("measurement_time","measurement_value")
        plot_frame=zoo_frame

        #plot_frame=my_frame 
        plot_time_unit_title=plot_time_unit 
        total_sum=sum(my_frame$measurement_value)
        rm(my_frame)
        gc()
        #print(head(plot_frame))
    #title preparations
        starttime=min(plot_frame$measurement_time)
        endtime=max(plot_frame$measurement_time)

        ois_title=paste(my_ois[,c("report_title")],collapse = ',')
        yLabel = "observations"
        xLabel = paste(my_meta$numunit, plot_time_unit_title)
        #print(xLabel)
  #plot histogram
        histData <- plothist(plot_frame$measurement_value,my_meta, ois_title=ois_title,starttime=starttime,endtime=endtime, yLabel,xLabel,total_sum,total_n=n)

   #return plot data
        return_matrix=as.matrix(plot_frame[1,c("measurement_value","measurement_time")])
        if (my_meta$quanttype=='integer') {
            decimals=0 
        } else {
            decimals=3
        } 
        mean=round(mean(plot_frame$measurement_value),decimals)
        sum=round(sum(plot_frame$measurement_value),decimals)
        std=round(sd(plot_frame$measurement_value),decimals)
        min=round(min(plot_frame$measurement_value),decimals)
        max=round(max(plot_frame$measurement_value),decimals)
        sub=paste("mean=", mean,"sum=",sum,"std=",std,"min=",min,"max=",max)
        main=paste(my_meta$report_title,"\n",ois_title,"\nn=",n,"\n",starttime,"-",endtime)
        return_list <- list(histData,main,xLabel,yLabel,sub,my_meta$lowerlimit,my_meta$upperlimit,mean,sum,std,min,max,my_meta$alarm_lowerlimit,my_meta$alarm_upperlimit,imagetype)
        names(return_list) <-c("matrix","main_title", "x_title","y_title","sub_title","lowerlimit","upperlimit","mean","sum","std","min","max","alarm_lowerlimit","alarm_upperlimit","imagetype")
            rm(plot_frame)
        gc()
    return(return_list)
}


plothist=function(variable_values,meta,ois_title,starttime=NULL,endtime=NULL, yLabel,xLabel,total_sum,total_n)
{  
    barcol="grey"
    n=length(variable_values)
    #if all equal? 
    if(isTRUE(all.equal( max(variable_values) ,min(variable_values)) )) {
    
        plot(x=variable_values, y = seq(1:length(variable_values)), type='l', main=paste(meta$report_title,"\n",ois_title,"\nn=",n,"\n",starttime,"-",endtime),
        sub=paste( 
                 "mean=",round(mean(variable_values),1),
                 "sum=",round(total_sum,1),
                 "std=",round(sd(variable_values),1),
                 "min=",round(min(variable_values),1),
                 "max=",round(max(variable_values),1)),
                  freq=TRUE,col=barcol, ylab=yLabel,xlab=xLabel        )
        h <- variable_values   

    } else {
        #normal histogram 
        #set limits for the image 
        #print("limits") 
        lowerlimit=meta$lowerlimit
        if (is.na(lowerlimit)) 
            lowerlimit=min(variable_values)
        lower_alarmlimit=meta$lower_alarmlimit
        if (is.null(lower_alarmlimit)) 
            lower_alarmlimit=min(variable_values)
        xlim_lowend=min(min(variable_values),lowerlimit, lower_alarmlimit)
        xlim_lowend=xlim_lowend+(xlim_lowend/10)
        upperlimit=meta$upperlimit
        if (is.na(upperlimit)) 
            upperlimit=max(variable_values)
        upper_alarmlimit=meta$upper_alarmlimit
        if (is.null(upper_alarmlimit)) 
            upper_alarmlimit=max(variable_values)
        xlim_uppend=max(max(variable_values),upperlimit, upper_alarmlimit)
        xlim_uppend=xlim_uppend+(xlim_uppend/10)

        #plot    
        h <-hist(variable_values
        ,main=paste(meta$report_title,"\n",ois_title,"\nN=",n,"n=",total_n,"\n",starttime,"-",endtime)
        ,xlim=c(xlim_lowend,xlim_uppend)
        ,sub=paste("mean=",round(mean(variable_values),2)
        ,        "sum=",round(total_sum,2)
        ,        "std=",round(sd(variable_values),2)
        ,        "min=",round(min(variable_values),2)
        ,         "max=",round(max(variable_values),2))
        ,           freq=TRUE,col=barcol, ylab=yLabel,xlab=xLabel )
    }
    
    #add mean
    abline(v=mean(variable_values),col="blue",lwd=3)
    
    #add reference value lines
    if (!is.na(meta$referenvalue_type)) {
        if (meta$referenvalue_type=='value') { 
            if (!is.na(meta$referencevalue)) {
                abline(v=meta$referencevalue,col="blue",lty="dotted",lwd=2)
            }
        }
        if (meta$referenvalue_type=='range') {
            if (!is.na(meta$referencevalue) )  { 
                abline(v=meta$referencevalue,col="blue",lty="dotted",lwd=2)
            }
            if (!is.na(meta$referencevalue_high)){ 
                abline(v=meta$referencevalue_high,col="blue",lty="dotted",lwd=2)
            }
        }
    }
    
    #add alarm limits 
    if (!is.na(meta$alarm_lowerlimit))  {abline(v=meta$alarm_lowerlimit,col="red",lty="dotted",lwd=2)}
    if (!is.na(meta$alarm_upperlimit) )  {abline(v=meta$alarm_upperlimit,col="red",lty="dotted",lwd=2)}
    
    #add value limits 
    if (!is.na(meta$lowerlimit) ) {abline(v=meta$lowerlimit,col="black",lwd=1)}
    if (!is.na(meta$upperlimit) ) {abline(v=meta$upperlimit,col="black",lwd=1)}
    legend("topright",  
         c("Mean","Refvalue","Alarm","Limits" ), 
         lty=c(1,4,1,4), 
         col=c("blue","blue","red","grey"), 
         horiz=FALSE, 
         cex=0.8)
    return(h)
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

output_data <- tryCatch(
		{			
			suppressWarnings(
					{
					    if (imagetype == "vector") {
        					svglite(localResultFile);
    					} else {
							png(filename=localResultFile)
						}
						dbcon <- connectDB()
						data <- deploy_histogram(varids,oitype, oiids,starttime,endtime,timeunit,dbcon,imagetype);
						data["image"] = resultUrl
						data
					})
		},
		error=function(cond) {
			message(cond)
			return_list <- list(cond$message)
			names(return_list) <-c("error")
			return(return_list)
		},
		warning=function(cond) {
			message(cond)
			return(cond)
		},
		finally={
			dev.off()
		})
print(output_data)
	write(toJSON(output_data), file=outputfile)
