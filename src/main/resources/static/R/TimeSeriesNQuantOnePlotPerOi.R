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
#single timeseries
#deploy_ts_quant_nvar_nplot1line
#Time series for quantitative variables for several variables and n ois. Makes one separate plots for each variable, on line for all ois 
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
#- oi_title: oi title
#- starttime
#- endtime
#- n: number of measurements
#- xTitle: x-axis title (time unit)
#- subTitle: x-axis subtitle 
#- yTitle: y-axis title
#- data_time_unit: original time unit of data
#- limits: lower, upper, alarm etc limits
#requires 
#- db-functions
#- function create_ts_object_quantitative for time unit aggregation
#- function smooth_ts for plotting 


args <- commandArgs(trailingOnly = F)
scriptPath <- dirname(sub("--file=","",args[grep("--file",args)]))

source(paste(scriptPath, "common.R", sep="/"))

connectDB <- function() {
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}



deploy_ts_quant_nvar_nplot1line=function(variableids,oitype,oiids, starttime=NULL,endtime=NULL,plot_time_unit,dbcon,imagetype)
{  
    on.exit(dbDisconnect(dbcon))
    #read first variable
    oiids_temp=paste("(",oiids,")",sep="")
    variableids=(unlist(  strsplit(variableids, ',')))
    if (length(variableids)>5) {
        stop("OpenVA warning:Too many variables, max five in one plot")
    }
    par(mfrow=c(length(variableids),1))
    #make oi_title
    my_ois=getOIs(dbcon,oiids_temp) 
    oi_title=paste(my_ois[,c("report_title")],collapse = ',')
        
    #create list for return data   
    return_return_list=replicate(length(variableids), list())  
    for (i in 1:length(variableids)){ 
        names(return_return_list)[i] <- paste("chart",i,sep="_")
    }
        
    plot_time_unit=timeunit
    #plot each variable 

	n_tot = 0;
    for (i in 1:length(variableids)){ 
        #get data 
        variableid=as.numeric(variableids[[i]])
  
        plot_frame=getVariableValues_partition_aggregated_by_time(dbcon,variableid, oiids,oitype,starttime,endtime,fast=FALSE, plot_time_unit,row_limit=NULL) 
        
        n=nrow(plot_frame)
        my_meta=getMetadata(dbcon,variableid)
        operation=my_meta$plottype
        plot_time_unit_title= paste(operation,"per",plot_time_unit)
        n_tot = n_tot + n
        if (n>1) {
            timeunit=paste(plot_time_unit,"s",sep="")
            zoo_frame=zoo(plot_frame$measurement_value,plot_frame$measurement_time)
            plot_zoo=period.apply(zoo_frame, endpoints(zoo_frame, timeunit), operation)
            plot_zoo <- na.omit(plot_zoo)
            zoo_frame=fortify.zoo(plot_zoo)
            colnames(zoo_frame)=c("measurement_time","measurement_value")
            plot_frame=zoo_frame
            
            starttime=min(plot_frame$measurement_time)
            endtime=max(plot_frame$measurement_time)
            

            total_sum=sum(plot_frame$measurement_value)
            #plot  
            #par(mfrow=c(1,1),oma = c(0, 0, 2, 0)) #jos päällä, tekee jokaisesta oman kuvan
            smooth <- smooth_ts(plot_frame,n_data_frame=n,meta=my_meta,oi_titles=oi_title,starttime,endtime,plot_time_unit, plot_time_unit_title,total_sum)
#           if (imagetype=="raster") {
#                return_list <- list("Raster image: no data returned",imagetype)
#               names(return_list) <-c("warning","imagetype")
#                return_return_list[[i]]<-return_list
#                rm(plot_frame)
#                gc()
#           }  else if (imagetype=="vector") {
#                return_list <- list("Vector image: no data returned",imagetype)
#                names(return_list) <-c("warning","imagetype")
#                return_return_list[[i]]<-return_list
#                rm(plot_frame)
#                gc()
#           }
#           else if (length(plot_frame$measurement_value) > 29000/length(variableids)) {
#                return_list <- list("Too many data values for interactive visualization: showing PNG instead. Use bigger time unit!",length(plot_frame$measurement_value),imagetype)
#                names(return_list) <-c("warning","n","imagetype")
#                return_return_list[[i]]<-return_list
#                rm(plot_frame)
#                gc()
#            } else {           
            
            plot_frame$measurement_time=as.character(plot_frame$measurement_time)
            return_matrix=as.list(plot_frame[c("measurement_value","measurement_time")])
            xsub=paste("mean",mean(plot_frame$measurement_value),
                "sum",sum(plot_frame$measurement_value),
                "std",sd(plot_frame$measurement_value),  
                "min",min(plot_frame$measurement_value), 
                "max",min(plot_frame$measurement_value))
            main_title =paste(my_meta$report_title,"\n",oi_title,"\n","n=",n,"\n",starttime," - ",endtime)
                  
            return_matrix["smooth"] <- NA
            if (length(smooth$y)==0) {
                smoothpoints = NA
            } else {
                smoothpoints = smooth$y
            }
            values = return_matrix$measurement_value
            timestamps = return_matrix$measurement_time
            lowerlimit = as.character(my_meta["lowerlimit"])
            upperlimit = as.character(my_meta["upperlimit"])
            alarm_lowerlimit = as.character(my_meta["alarm_lowerlimit"])
            alarm_upperlimit = as.character(my_meta["alarm_upperlimit"])
            outlier_upperlimit = as.character(my_meta["outlier_upperlimit"])
            outlier_lowerlimit = as.character(my_meta["outlier_lowerlimit"])
            goalvalue = as.character(my_meta["goalvalue"])
            referencevalue = as.character(my_meta["referencevalue"])
            mean <- as.character(mean(plot_frame$measurement_value))
            alarm_level <- as.character(my_meta["alarm_level"])
            return_list <-list(values,       timestamps,smoothpoints,lowerlimit,upperlimit,  alarm_lowerlimit,  alarm_upperlimit,  outlier_lowerlimit,  outlier_upperlimit,  alarm_level, goalvalue,mean,referencevalue,main_title, plot_time_unit_title,xsub, my_meta$numunit,imagetype)
            names(return_list) <-c("values","timestamps","smooth","lowerlimit","upperlimit","alarm_lowerlimit","alarm_upperlimit","outlier_lowerlimit","outlier_upperlimit","alarm_level", "goalvalue","mean","referencevalue", "main_title","x_title",  "sub_title", "y_title","imagetype")
  
                return_return_list[[i]]<-return_list 
                rm(plot_frame)
                gc()
 #           }
        }  else {
            plot(0,xaxt='n',yaxt='n',bty='n',pch='',ylab='',xlab='',main= paste("OpenVA warning: not enough data found\n",oi_title,my_meta$report_title,"\n",plot_time_unit_title))  
        }           
    } 
  	if (imagetype=="raster" || imagetype=="vector") {
    	return(list(imagetype=imagetype))
  	} else {
  		if (n_tot > 29000) {
  			return_list <- list("Too many data values for interactive visualization: showing raster image instead. Use bigger time unit or shorter time period.",n_tot,"raster")
            names(return_list) <-c("warning","n","imagetype")
            return(return_list)
  		} else {
    		return(return_return_list)
    	}
  }
}


#same with all ts when one line plot
smooth_ts=function(plot_frame,n_data_frame,meta,oi_titles,starttime,endtime,plot_time_unit, plot_time_unit_title,total_sum)
{
    plot_frame=plot_frame[order(plot_frame$measurement_time),]
    plot_frame=unique(plot_frame)
    n=nrow(plot_frame)
    my_time=plot_frame$measurement_time
    y=plot_frame$measurement_value
  
    if (is.na(meta$lowerlimit)) {
        min_y=min(plot_frame$measurement_value)
    } else {
        min_y=min(meta$lowerlimit,min(plot_frame$measurement_value))
    }
  
    if (is.na(meta$upperlimit)) {
        max_y=max(plot_frame$measurement_value)
    } else {
        max_y=max(meta$upperlimit,max(plot_frame$measurement_value))
    }
#number of decimals
    if (meta$quanttype=='integer') {
        decimals=0 
        y=round(y,0)
    } else {decimals=3} 
    
    if (meta$plottype=="sum")
    {        sub_title=
                paste("mean=",round(sum(y)/n,decimals),
                   "sum=",round(total_sum,decimals),
                   "std=",round(sd(y),decimals),
                   "min=",round(min(y),decimals),
                   "max=",round(max(y),decimals))
    } else { sub_title=
                paste("mean=",round(sum(y)/n,decimals),
                   "std=",round(sd(y),decimals),
                   "min=",round(min(y),decimals),
                   "max=",round(max(y),decimals))
        }
    if (n>1) { 
    
        plot(my_time,y, type="b",cex.main=0.9,cex.sub=0.8,cex.axis=0.9,
            col="black",lwd=1, main=paste(meta$report_title, 
                                       "\n",oi_titles,"\n",
                                       "n=",n_data_frame,"\n",starttime," - ",endtime),
         xlab=plot_time_unit_title,
         ylab=meta$numunit,
         
         ylim=c(min_y,(max_y + max_y/5)),
         sub=sub_title,
         xaxt="no" )
    
    
        #add axis to plot 
        #x axis ticks vary depending on the plot_time_unit and number of days  
    
        if (plot_time_unit!="year") { 
            days <-unique(as.Date(plot_frame$measurement_time))
    
            #plot months
            if (length(days)>30) {
                axis.POSIXct(1, at = seq(min(my_time), max(my_time), by = "month"), format = "%Y-%m",cex.axis=0.6,las=2)
      
                #plot days 
            }   else if (length(days)>1) {
                axis.POSIXct(1, at = seq(min(my_time), max(my_time), by = "day"), format = "%Y-%m-%d",cex.axis=0.6,las=2)
      
            # plot hours
            }  else { 
                axis.POSIXct(1, at = seq(min(my_time), max(my_time), by = "hour"), format = "%d-%H",cex.axis=0.6,las=2)
            }  
        } else {  
            #years 
            axis.POSIXct(1, at = seq(min(my_time), max(my_time), by = "year"), format = "%Y",cex.axis=0.6,las=2)
        }
    
    } else {
        #stop("OpenVA warning:Not enough observations for time series")
    }
    #  print("PLOT END")
  
    #smooth 
    if (meta$quanttype=='desimal'){
        if (length(unique(y)) > 3) {
            if (n>10 && n< 10000) {
                # dpill seems to fail with large point sets
                t=seq(1:n)
                #print(t)
                gridsize <-length(y)
            #print(gridsize)
                bw <- dpill(t, y, gridsize=(gridsize))
    
                lp <- locpoly(x=t, y=y, bandwidth=bw, gridsize=gridsize)
                smooth <- lp$y
    
                lines(my_time,smooth,type="l",col="blue",lwd=3)
            }
        }
    }

  
     #lines
     #mean
    abline(h=mean(plot_frame$measurement_value),col="blue",lwd=2)
  
    #reference values
    if (!is.na(meta$referenvalue_type)) {
        if (meta$referenvalue_type=='value') {
            abline(h=meta$referencevalue,col="blue",lty="dotted",lwd=1)
        }
  
        if (meta$referenvalue_type=='range') {
            abline(h=meta$referencevalue,col="blue",lty="dotted",lwd=1)
            abline(h=meta$referencevalue_high,col="blue",lty="dotted",lwd=1)
        }
    }
    abline(h=meta$alarm_lowerlimit,col="red",lwd=2)
    abline(h=meta$alarm_upperlimit,col="red",lwd=2)
    abline(h=meta$lowerlimit,col="grey",lty="dotted",lwd=1)
    abline(h=meta$upperlimit,col="grey",lty="dotted",lwd=1)
    legend("topright",  
            c("Mean","Refvalue","Alarm","Limits"), lty=c(1,4,1,4), col=c("blue","blue","red","grey"), horiz=FALSE, cex=0.6)
    if (exists("lp")) {
        return(lp)
    } else {
        return(NULL)
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
        					svglite(localResultFile);
    					} else {
							png(filename=localResultFile)
						}
						dbcon <- connectDB()
						data <- deploy_ts_quant_nvar_nplot1line(varids,oitype,oiids, starttime,endtime,timeunit,dbcon,imagetype)
						data["image"] = resultUrl
						print(data["imagetype"])
						if (data["imagetype"] != "raster" && data["imagetype"] != "vector") {
							data["imagetype"] = "multi_interactive"
						}	
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