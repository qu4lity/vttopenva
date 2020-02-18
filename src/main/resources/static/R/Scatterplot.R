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

args <- commandArgs(trailingOnly = F)
scriptPath <- dirname(sub("--file=","",args[grep("--file",args)]))
print(scriptPath)

source(paste(scriptPath, "common.R", sep="/"))

connectDB <- function()
{
	Sys.setenv("TZ"="UTC")
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

deploy_scatplot_fast=function(varids,oitype,oiids,starttime=NULL,endtime=NULL,time_unit,dbcon,imagetype)
{ 
    on.exit(dbDisconnect(dbcon))
    oiids_temp=paste("(",oiids,")",sep="")
    varidstemp=as.list(strsplit(varids, ",")[[1]])
    variableid1=(varidstemp[[1]])
    variableid2=varidstemp[[2]]
    my_meta1=getMetadata(dbcon,variableid1)
    my_meta2=getMetadata(dbcon,variableid2)

    my_ois=getOIs(dbcon,oiids_temp)
    my_ois_title=paste(my_ois[,c("report_title")],collapse = ',')

    var1_frame = getVariableValues_partition_aggregated_by_time(dbcon,variableid=variableid1, oiids=oiids,oitype=oitype,starttime=starttime,endtime=endtime,fast=FALSE, time_unit,row_limit=NULL) 
    if(nrow(var1_frame)==0) {stop(paste("OpenVA warning: No data found",my_ois_title,my_meta1$report_title) )}
    var1_frame=var1_frame[complete.cases(var1_frame),]
    zoo_frame=zoo(var1_frame$measurement_value,var1_frame$measurement_time)
    timeunit=paste(time_unit,"s",sep="")
    plot_zoo=period.apply(zoo_frame, endpoints(zoo_frame, timeunit), my_meta1$plottype)
    plot_zoo <- na.omit(plot_zoo)
    zoo_frame=fortify.zoo(plot_zoo)
    colnames(zoo_frame)=c("measurement_time","measurement_value")
    plot_frame1=zoo_frame
    

    var2_frame = getVariableValues_partition_aggregated_by_time(dbcon,variableid=variableid2, oiids=oiids,oitype=oitype,starttime=starttime,endtime=endtime,fast=FALSE, time_unit,row_limit=NULL) 
    if(nrow(var2_frame)==0) {stop(paste("OpenVA warning: No data found",my_ois_title,my_meta2$report_title) )}
    var2_frame=var2_frame[complete.cases(var2_frame),]
    zoo_frame=zoo(var2_frame$measurement_value,var2_frame$measurement_time)
    timeunit=paste(time_unit,"s",sep="")
    plot_zoo=period.apply(zoo_frame, endpoints(zoo_frame, timeunit), my_meta2$plottype)
    plot_zoo <- na.omit(plot_zoo)
    zoo_frame=fortify.zoo(plot_zoo)
    colnames(zoo_frame)=c("measurement_time","measurement_value")
    plot_frame2=zoo_frame
  
    
#create ts objects with righ timeunit
    rm(var1_frame1)
    gc()
    plot_time_unit_title= paste(my_meta2$plottype,"per",time_unit)
    rm(var2_frame2)
    gc()
    #total_sum=return_list[[3]] 
     
#merge variables   
   plot_frame=merge(plot_frame1,plot_frame2, by="measurement_time")
    
    starttime = min(min(plot_frame1$measurement_time),min(plot_frame2$measurement_time))
    endtime = max(max(plot_frame1$measurement_time),max(plot_frame2$measurement_time))
    rm(plot_frame1)
    rm(plot_frame2)
    gc()
  
  if (nrow(plot_frame)==0) {stop(paste("no joint data found: ",variableid1,variableid2,"oiids",oiids) )}
  
  colnames(plot_frame)=c("measurement_time","measurement_value1","measurement_value2")

  if ( length(unique(plot_frame$measurement_value1))==1 | length(unique(plot_frame$measurement_value2))==1) 
  { 
    stop("OpenVA warning: Not enough variation in observations for scatterplot")}


#plotting
    n=nrow(plot_frame)
#    if (nrow(plot_frame) > 29000 && imagetype == "vector") {
#        dev.off()
#    } 
    
    
    my_cor=round(cor(plot_frame$measurement_value1,plot_frame$measurement_value2,  method = "pearson", use = "complete.obs"),2)
    my_title=paste("\nCorrelation",my_meta1$report_title,"-",my_meta2$report_title,"\n",my_ois_title,"\n n=",n,"\n", starttime," - ",endtime,"\n")

    my_meta1_lowerlimit= min(plot_frame$measurement_value1)
    if (is.null(my_meta1$lowerlimit)) my_meta1$lowerlimit=NA
    if (!is.na(my_meta1$lowerlimit) )  my_meta1_lowerlimit=my_meta1$lowerlimit
        
    my_meta1_lower_alarmlimit= min(plot_frame$measurement_value1)
    if (is.null(my_meta1$lower_alarmlimit)) my_meta1$lower_alarmlimit=NA
    if (!is.na(my_meta1$lower_alarmlimit))  my_meta1_lower_alarmlimit=my_meta1$lower_alarmlimit
        
    my_meta1_upperlimit= max(plot_frame$measurement_value1)
    if (is.null(my_meta1$upperlimit) ) my_meta1$upperlimit=NA
    if (!is.na(my_meta1$upperlimit) ) my_meta1_upperlimit=my_meta1$upperlimit
        
    my_meta1_upper_alarmlimit= max(plot_frame$measurement_value1)
    if (is.null(my_meta1$upper_alarmlimit)) my_meta1$upper_alarmlimit=NA
    if (!is.na(my_meta1$upper_alarmlimit)) my_meta1_upper_alarmlimit=my_meta1$upper_alarmlimit
        
    my_meta2_lowerlimit= min(plot_frame$measurement_value2)
    if (is.null(my_meta2$lowerlimit) ) my_meta2$lowerlimit=NA
    if (!is.na(my_meta2$lowerlimit) ) my_meta2_lowerlimit=my_meta2$lowerlimit
        
    my_meta2_lower_alarmlimit= min(plot_frame$measurement_value2)
    if (is.null(my_meta2$lower_alarmlimit))  my_meta2$lower_alarmlimit=NA
    if (!is.na(my_meta2$lower_alarmlimit)) my_meta2_lower_alarmlimit=my_meta2$lower_alarmlimit
        
    my_meta2_upperlimit= max(plot_frame$measurement_value2)
    if (is.null(my_meta2$upperlimit) ) my_meta2$upperlimit =NA
    if (!is.na(my_meta2$upperlimit) )  my_meta2_upperlimit=my_meta2$upperlimit
        
    my_meta2_upper_alarmlimit= min(plot_frame$measurement_value2)
    if (is.null(my_meta2$upper_alarmlimit) ) my_meta2$upper_alarmlimit=NA
    if (!is.na(my_meta2$upper_alarmlimit) )  my_meta2_upper_alarmlimit=my_meta2$upper_alarmlimit
        
    xlim_lowend=min(min(plot_frame$measurement_value1), my_meta1_lowerlimit, my_meta1_lower_alarmlimit)
    xlim_lowend=0.9*xlim_lowend
        
    xlim_uppend=max(max(plot_frame$measurement_value1), my_meta1_upperlimit, my_meta1_upper_alarmlimit)
    xlim_uppend=1.1*xlim_uppend
     
    ylim_lowend=min(min(plot_frame$measurement_value2), my_meta2_lowerlimit, my_meta2_lower_alarmlimit)
    ylim_lowend=ylim_lowend-(ylim_lowend/10)
    ylim_uppend=max(max(plot_frame$measurement_value2), my_meta2_upperlimit, my_meta2_upper_alarmlimit)
    ylim_uppend=ylim_uppend+(ylim_uppend/10)
        
    plot(plot_frame$measurement_value1,plot_frame$measurement_value2,
            xlab=my_meta1$report_title, ylab=my_meta2$report_title, 
            xlim=c(xlim_lowend,xlim_uppend),ylim=c(ylim_lowend,ylim_uppend), 
            main=my_title, sub=paste(plot_time_unit_title,"r=",my_cor),
            cex.main=0.9)

      abline(v=my_meta1$alarm_lowerlimit,col="red",lwd=2)
      #print(meta$alarm_lowerlimit)
      abline(v=my_meta1$alarm_upperlimit,col="red",lwd=2)
      #print(meta$alarm_upperlimit)
      abline(v=my_meta1$lowerlimit,col="black",lwd=1)
      abline(v=my_meta1$upperlimit,col="black",lwd=1)
      abline(h=my_meta2$alarm_lowerlimit,col="red",lwd=2)
      print(my_meta2$alarm_lowerlimit)
      abline(h=my_meta2$alarm_upperlimit,col="red",lwd=2)
      abline(h=my_meta2$lowerlimit,col="black",lwd=1)
      abline(h=my_meta2$upperlimit,col="black",lwd=1)
    abline(lm(plot_frame$measurement_value2~plot_frame$measurement_value1), col="blue") # may not work if not much data, need to make some kind of check

    if (imagetype == "raster") {
        return_list <- list("No data returned for raster",imagetype)
        names(return_list) <-c("info","imagetype")
        return(return_list) 
    } else if (imagetype == "vector") {
        if (nrow(plot_frame) > 50000) {
                return_list <- list("Too many data values for vector visualization: showing raster instead. \n You may want to use bigger time unit!",nrow(plot_frame),"raster")
                names(return_list) <-c("warning","n","imagetype")
                return(return_list)
        }  else {
                return_list <- list("No data returned for vector",imagetype)
                names(return_list) <-c("info","imagetype")
                return(return_list) 
        }
    } else {
        if (nrow(plot_frame) > 29000) {
            return_list <- list("Too many data values for interactive visualization: showing raster instead. \n You may want to use bigger time unit!",nrow(plot_frame),"raster")
            names(return_list) <-c("warning","n","imagetype")
            return(return_list)
        }  else {
            reg <- lm(plot_frame$measurement_value2~plot_frame$measurement_value1)
            intercept <-as.character(reg[1]$coefficients[1])
            slope <- as.character(reg[1]$coefficients[2])
            print(intercept)
            print(slope)
            
            colnames( plot_frame)=c("measurement_time",my_meta1$title,my_meta2$title)

            return_matrix=as.matrix(plot_frame[,c(2,3)])
            colnames(return_matrix) <- NULL
    		rownames(return_matrix) <- NULL
    		return_matrix = apply(return_matrix, 1, as.list)

            return_list <- list(return_matrix,intercept,slope,my_title,my_ois_title,my_meta1$title,my_meta2$title,my_meta1$alarm_lowerlimit, my_meta1$alarm_upperlimit,my_meta2$alarm_lowerlimit, my_meta2$alarm_upperlimit,my_meta1$lowerlimit, my_meta1$upperlimit,my_meta2$lowerlimit, my_meta2$upperlimit,"interactive")
            names(return_list) <-c("matrix","intercept","slope","title","ois_title","xTitle","yTitle","xAlarmLowerLimit","xAlarmUpperLimit","yAlarmLowerLimit","yAlarmUpperLimit","xLowerLimit","xUpperLimit","yLowerLimit","yUpperLimit","imagetype")
            rm(plot_frame)
            gc()
            return(return_list)
        }
    }
  
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

if (timeunit =="null") {
	stop("Select time unit and aggregation operation")
}

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
        					svglite(localResultFile);
    					} else {
							png(filename=localResultFile, width = 600, height = 600)
						}
						dbcon <- connectDB()
						data <- deploy_scatplot_fast(varids,oitype,oiids,starttime,endtime,timeunit,dbcon,imagetype)
						data["image"] = resultUrl
						data["title"] = "Scatter plot"
						data["width"] = 600
    					data["height"] = 600						
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
write(toJSON(output_data), file=outputfile)