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

#n-n-1
#deploy_timeseries_nominal_binary
#Time series for 2-value nominal data for several variables and n ois. 
#Makes one separate plots for each variable, one line for all ois 
#input parameters
#- variableids, comma separated list of variableids 
#- oiids , comma separated list of oiids 
#- starttime,endtime, can be NULL
#- plot_time_unit: sec, min, hour, day, month, year 

#output
##output
#a list containint a sublist for each variable
#sublist elements 
#- matrix: measurement_value, measurement time
#- var_title: variable title
#- oi_title: oi titles
#- starttime
#- endtime
#- n: number of measurements
#- xTitle: x-axis title (time unit)
#- subTitle:  -
#- yTitle: y-axis title binary codevalues
#- data_time_unit: original time unit of data
#- limits: -
#requires 
#- db-functions
#- function create_ts_object_nominal for time unit aggregation, calculates modes if time unit not original
#- function plot_ts_nominal for plotting 


args <- commandArgs(trailingOnly = F)
scriptPath <- dirname(sub("--file=","",args[grep("--file",args)]))
print(scriptPath)

source(paste(scriptPath, "common.R", sep="/"))

connectDB <- function() {
	Sys.setenv("TZ"="UTC")
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}


deploy_timeseries_nominal_binary=function(variableids,oitype,oiids, starttime=NULL,endtime=NULL,plot_time_unit,dbcon,imaetype) {  
  #for one or many variables with binary values, all use same NUMERERIC coding, one or many ois.
  #plots a timeseries of each variable in the same canvas
 
    on.exit(dbDisconnect(dbcon))
    
    #read first variable
    oiids_temp=paste("(",oiids,")",sep="")
    variableids=(unlist(  strsplit(variableids, ',')))
    if (length(variableids)>5)   {
        stop("OpenVA warning: Too many variable in one plot, max five allowed")
    }

    par(mfrow=c(length(variableids),1))
#make oi_title
    my_ois=getOIs(dbcon,oiids_temp) 
    oi_title=paste(my_ois[,c("report_title")],collapse = ',')
    #print(oi_title)
        
#get value range 
    my_meta=getMetadata(dbcon,variableids[1])
    codevalues=getCodeValues(dbcon,codesid=my_meta$codes_id)
    min_y=as.numeric(min(codevalues$code_value))
    max_y=as.numeric(max(codevalues$code_value))
#create list for return data   
    return_return_list=replicate(length(variableids), list())  
        for (i in 1:length(variableids)){ 
        names(return_return_list)[i] <- paste("chart",i,sep="_")
    }
#plot each variable 

    n_total = 0;
    for (i in 1:length(variableids)) { 
        #get data 
        variableid=variableids[i]
        plot_frame=getNomBinVariableValues_partition_aggregated_by_time(dbcon,variableid, oiids,oitype,starttime,endtime,fast=FALSE, plot_time_unit) 
        #my_frame=getVariableValues_partition(dbcon,variableid=variableid,oiids=oiids,oitype=oitype,starttime=starttime,endtime=endtime,FALSE)
        n_data_frame=nrow(plot_frame)
        n_total = n_total + n_data_frame;
        if (n_data_frame>0) {
            
            my_meta=getMetadata(dbcon,variableid)
            
            plot_starttime=min(plot_frame$measurement_time)
            plot_endtime=max(plot_frame$measurement_time)
            if (plot_time_unit=="min"){ 
                plot_time_unit_title="Minute modes" 
              }  else if (plot_time_unit=="hour"){ 
                plot_time_unit_title="Hourly modes"
              } else if  (plot_time_unit=="day") { 
                plot_time_unit_title="Daily modes"
              } else if(plot_time_unit=="week") {
                plot_time_unit_title="Weekly modes"
                } else if(plot_time_unit=="month") 
              { 
                plot_time_unit_title="Monthly modes"
              } else  if (plot_time_unit=="year") {
                plot_time_unit_title="Annual modes"
              } else {
                plot_time_unit_title= plot_time_unit
              }
            #plot
            plot_ts_nominal(plot_frame,n_data_frame,meta=my_meta,oi_title,plot_starttime,plot_endtime,plot_time_unit,plot_time_unit_title,codevalues)
            
            #return_data 
            # plot_frame$measurement_time=as.character(plot_frame$measurement_time)
            if (length(plot_frame$measurement_value) > 29000/length(variableids)) {
                return_list <- list("Too many data values for SVG-visualization: showing PNG instead. Use bigger time unit!",length(plot_frame$measurement_value))
                names(return_list) <-c("warning","n")
                return_return_list[[i]]<-return_list
            } else {
                main_title=paste(variable_title=my_meta$report_title,oi_title,"n=",n_data_frame,"\n",starttime," - ",endtime)
                values = plot_frame$measurement_value
                timestamps = as.character(plot_frame$measurement_time)
                lowerlimit = "-0.5"
                upperlimit = "1.5"
                alarm_lowerlimit = as.character(my_meta["alarm_lowerlimit"])
                alarm_upperlimit = as.character(my_meta["alarm_upperlimit"])
                outlier_upperlimit = as.character(my_meta["outlier_upperlimit"])
                outlier_lowerlimit = as.character(my_meta["outlier_lowerlimit"])
                goalvalue = as.character(my_meta["goalvalue"])
                referencevalue = as.character(my_meta["referencevalue"])
                
                mean <- as.character(mean(plot_frame$measurement_value))
                alarm_level <- as.character(my_meta["alarm_level"])
                return_list <-list(values,timestamps,lowerlimit,upperlimit,alarm_lowerlimit,alarm_upperlimit,  outlier_lowerlimit,  outlier_upperlimit,  alarm_level, goalvalue,mean,referencevalue,main_title, plot_time_unit_title,"",imagetype)
                names(return_list) <-c("values","timestamps","lowerlimit","upperlimit","alarm_lowerlimit","alarm_upperlimit","outlier_lowerlimit","outlier_upperlimit","alarm_level", "goalvalue","mean","referencevalue", "main_title","x_title", "y_title","imagetype")
                return_return_list[[i]]<-return_list  
            }
        } else {   
            my_meta=getMetadata(dbcon,variableid)
            plot(0,xaxt='n',yaxt='n',bty='n',pch='',ylab='',xlab='',main= paste("OpenVA warning: no data found",my_meta$report_title," : ", starttime, "-", endtime))  
        }           
    }

    rm(plot_frame)
    gc()
    print(n_total)
    if (imagetype=="data" && n_total > 29000) {
            return_list <- list("Too many data values for interactive visualization: showing raster instead. Consider using bigger time unit!",n_total,"raster")
            names(return_list) <-c("warning","n",imagetype)
            return(return_list)
    }
    if (imagetype=="vector" && n_total > 50000) {
            return_list <- list("A lot of data points. Consider raster visualisation or bigger time unit!",n_total,imagetype)
            names(return_list) <-c("warning","n","imagetype")
            return(return_list)
    }
    if (imagetype=="raster") {
        return_list <- list("Raster image: no data returned",imagetype)
        names(return_list) <-c("info","imagetype")
        return(return_list)
    }  else if (imagetype=="vector") {
        return_list <- list("Vector image: no data returned",imagetype)
        names(return_list) <-c("info","imagetype")
        return(return_list)
    } else if ( n_total > 29000) {
            return_list <- list("Too many data values for interactive visualization: showing raster instead. Consider using bigger time unit!",n_total,"raster")
            names(return_list) <-c("warning","n","raster")
            return(return_list)
    }else {
    	return_return_list["imagetype"] = "interactive"
        return(return_return_list)
    }
}

#plot  
plot_ts_nominal=function(plot_frame,n_data_frame,meta,oi_title,starttime,endtime,plot_time_unit,plot_time_unit_title,codevalues)
{
    my_plot_value=plot_frame$measurement_value
    if (n_data_frame > 1) {
        type="l"
    } else {
        type="p"
    }
    plot(plot_frame$measurement_time, my_plot_value, type=type,col="blue",lwd=2, 
         main=paste(variable_title=meta$report_title,oi_title,"n=",n_data_frame,"\n",starttime," - ",endtime),
        xlab=plot_time_unit_title, ylab="",
        xaxt="no",
        yaxt="no"
    )
 
    #add axis to plot 
    #x axis ticks vary depending on the plot_time_unit and number of days
    my_time=unique(plot_frame$measurement_time)
    if (plot_time_unit!="year") { 
        days <-unique(as.Date(plot_frame$measurement_time))

        #plot months
        if (length(days)>30) {
            axis.POSIXct(1, at = seq(min(my_time), max(my_time), by = "month"), format = "%Y-%m",cex.axis=0.6,las=2)
            #plot days 
        }   else if (length(days)>1) {
            axis.POSIXct(1, at = seq(min(my_time), max(my_time), by = "day"), format = "%Y-%m-%d",cex.axis=0.6,las=2)
            # plot hours
        }  else  { 
            axis.POSIXct(1, at = seq(min(my_time), max(my_time), by = "hour"), format = "%d-%H",cex.axis=0.6,las=2)
        }
    } else {  
  #years 
    axis.POSIXct(1, at = seq(min(my_time), max(my_time), by = "year"), format = "%Y",cex.axis=0.6,las=2)
    }

    axis(2, at = sort(as.numeric(codevalues$code_value)))
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

if (timeunit =="null") {
	stop("Select time unit")
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
						data <- deploy_timeseries_nominal_binary(varids,oitype, oiids, starttime, endtime,timeunit,dbcon,imagetype)
						data["image"] = resultUrl
						data["title"] = "Binary timeseries"
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