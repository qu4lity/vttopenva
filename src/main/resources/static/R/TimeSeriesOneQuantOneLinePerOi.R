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


#1-1-n
#deploy_ts_quant_1var_nplot1line
#Time series for quantitative variables for one variable and n ois. 
#Makes one plot with a line for each oi 
#input parameters
#- variableid, just one 
#-  oiids , comma separated list of oiids 
#- starttime,endtime, can be NULL
#- plot_time_unit: sec, min, hour, day, month, year 
#output
#a list containint a sublist for each oi
#sublist elements 
#- matrix: measurement_value, measurement time
#- var_title: variable title
#- oi_title: oi title
#- starttime
#- endtime
#- n: number of original measurements
#- xTitle: x-axis title (time unit)
#- subTitle: x-axis subtitle 
#- yTitle: y-axis title
#- data_time_unit: original time unit of data
#- limits: lower, upper, alarm etc limits
#
#
#requires 
#- db-functions
# - function create_ts_object_quantitative for time unit aggregation
# - function smooth_ts_many for plotting

args <- commandArgs(trailingOnly = F)
scriptPath <- dirname(sub("--file=","",args[grep("--file",args)]))
print(scriptPath)

source(paste(scriptPath, "common.R", sep="/"))

connectDB <- function() {
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

deploy_ts_quant_1var_1plotnline=function(variableid,oitype,oiids, starttime=NULL,endtime=NULL,plot_time_unit,dbcon,imagetype)
{  
    on.exit(dbDisconnect(dbcon))
    #read data  
    #tähän pitää laittaa joku rajoite, montako riviä samaan kuvaan 
    n_ois=length(unlist(  strsplit(oiids, ',')))
    oi_limit=5
    if (n_ois>oi_limit)  {
        stop (paste("OpenVA warning: Too many objects in one plot, max",oi_limit,"allowed"))
    }
    my_oiids=paste(oiids,collapse = ',')
    oiids_temp=paste("(",my_oiids,")",sep="")

    my_frame_all=getVariableValues_partition_aggregated_by_time(dbcon,variableid, oiids,oitype,starttime,endtime,fast=FALSE, plot_time_unit,row_limit=NULL)

    frame_oi_titles=(unique(my_frame_all$oi_id))
    n=nrow(my_frame_all)
    my_meta=getMetadata(dbcon,variableid)
    my_ois=getOIs(dbcon,oiids_temp,oitype=my_meta$oitype_title)
    my_ois_title=paste(my_ois[,c("report_title")],collapse = ',')
    if (n==0) {
        stop(paste("OpenVA warning: No data found,", my_ois_title,my_meta$report_title ))
    }
    data_time_unit=my_meta$time_unit
    starttime=min(my_frame_all$measurement_time)
    endtime=max(my_frame_all$measurement_time)
  
    # plot with smooth
    smooth_list = smooth_ts_many(my_frame_all,meta=my_meta,  oi_titles=my_ois_title,starttime,endtime,plot_time_unit,my_meta$plottype)
    #create return data

    
    if (imagetype== "raster" || imagetype=="vector") {
        if (length(my_frame_all$measurement_value) > 50000 && imagetype=="vector") {
            return(list("warning"="A lot of data points. Consider raster visualisations or bigger time unit!","imagetype"=imagetype));
        }
        return(list("imagetype"=imagetype));
    } else {
        return_return_list=replicate(n_ois, list())  
        for (i in 1:n_ois){ 
            names(return_return_list)[i] <- paste("chart",i,sep="_")
        }
        if (length(my_frame_all$measurement_value) > 29000) {
            return_list <- list("Too many data values for interactive visualization: showing raster instead. Consider using bigger time unit!",length(my_frame_all$measurement_value),"raster")
            names(return_list) <-c("warning","n","imagetype")
            return(return_list)
        }
        
        print(length(smooth_list))
        
        for (i in 1:length(frame_oi_titles)) {
       
            my_frame=my_frame_all[my_frame_all$oi_id==frame_oi_titles[i],]
             
            plot_frame=my_frame 
            plot_time_unit_title= paste(my_meta$plottype,"per",plot_time_unit) 
                main_title=paste(variable_title=my_meta$report_title,"\n",paste(frame_oi_titles,collapse=","),"\n","n=",length(my_frame_all$measurement_value),"\n",starttime," - ",endtime)
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
                ytitle =as.character(my_meta["numunit"])
                
                mean <- as.character(mean(plot_frame$measurement_value))
                alarm_level <- as.character(my_meta["alarm_level"])

                return_list <-list(values,timestamps,as.character(smooth_list[[i]]),lowerlimit,upperlimit,alarm_lowerlimit,alarm_upperlimit,  outlier_lowerlimit,  outlier_upperlimit,  alarm_level, goalvalue,mean,referencevalue,main_title, plot_time_unit_title,ytitle,frame_oi_titles[i],imagetype)
                names(return_list) <-c("values","timestamps","smooth","lowerlimit","upperlimit","alarm_lowerlimit","alarm_upperlimit","outlier_lowerlimit","outlier_upperlimit","alarm_level", "goalvalue","mean","referencevalue", "main_title","x_title", "y_title","oiTitle","imagetype")
                return_return_list[[i]]<-return_list 
 
            #return_return_list[[i]]<-return_list  
        }
        rm(my_frame_all)
        gc()
        return(return_return_list) 
    } 
}



#In use in all timeseries where many lines in one canvas
smooth_ts_many=function(plot_frame_all,meta,oi_titles,starttime,endtime,plot_time_unit,operation)
{

    ois=unique(plot_frame_all$oi_id)
    n_data_frame=nrow(plot_frame_all)
  
    #total_sum=return_list_all[[3]]
    total_sum=sum(plot_frame_all$measurement_value)
  #x-y limits
    if (is.na(meta$lowerlimit)) {
        min_y=min(plot_frame_all$measurement_value)
    } else {
        min_y=min(meta$lowerlimit,min(plot_frame_all$measurement_value))
    }
    max_y=max(plot_frame_all$measurement_value)
    min_x=min(as.POSIXct(plot_frame_all$measurement_time))
    max_x=max(as.POSIXct(plot_frame_all$measurement_time))
  
    #number of decimals
    if (meta$quanttype=='integer') {
        decimals=0 
    } else {
        decimals=3
    } 
    #sub title, use all  data
    vals=plot_frame_all$measurement_value
    if (meta$plottype=="sum") {        
        sub_title=
                paste("mean=",round(mean(vals),decimals),
                   "sum=",round(sum(vals),decimals),
                   "std=",round(sd(vals),decimals),
                   "min=",round(min(vals),decimals),
                   "max=",round(max(vals),decimals))
    } else { 
            sub_title=
                paste("mean=",round(mean(vals),decimals),
                   "std=",round(sd(vals),decimals),
                   "min=",round(min(vals),decimals),
                   "max=",round(max(vals),decimals))
    }

    #line colors
    line_colors=palette()
    #first plot 
    oi_frame=plot_frame_all[plot_frame_all$oi_id==ois[1],]
    #print("create_ts_object_quantitative")
    #return_list=create_ts_object_quantitative(oi_frame, plot_time_unit,variableid,meta)
    oi_plot_frame=oi_frame 
    plot_time_unit_title= paste(operation,"per",plot_time_unit)

    n=nrow(oi_plot_frame)
    if (n<1) {
        stop(paste("OpenVA warning: Not enough observations for time series ", starttime, "-", endtime))
    } 
    
    oi_plot_frame=oi_plot_frame[order(oi_plot_frame$measurement_time),]
    oi_plot_frame=unique(oi_plot_frame)
    my_time=oi_plot_frame$measurement_time
    y=oi_plot_frame$measurement_value
    
    rm(oi_plot_frame)
    gc()
    if (meta$quanttype=='integer') {
        y=round(y,0)
    }
    
    
    
    plot(my_time,y, type="b",
       col=line_colors[1],lwd=1, cex.main=0.9,cex.sub=0.8,cex.axis=0.9,
       main=paste(variable_title=meta$report_title,"\n",oi_titles,"\n n=",n_data_frame,"\n",starttime," - ",endtime),
       xlab=paste(plot_time_unit_title),
       ylab=meta$numunit,
       xlim=c(min_x,max_x),
       ylim=c(min_y,(max_y + max_y/5)),
       #sub=sub_title, #no sense here
       xaxt="no" )
       
    #smooth 
    smooth_list=replicate(length(ois), list()) 
    if (meta$quanttype=='desimal') {
        if (length(unique(y)) > 3)  {
            if (n>10 && n< 10000) {
                t=seq(1:n)
                #print(t)
                gridsize <-length(y)
                #print(gridsize)
                bw <- dpill(t, y, gridsize=(gridsize))
                lp <- locpoly(x=t, y=y, bandwidth=bw, gridsize=gridsize)
                
                smooth <- lp$y
                smooth_list[[1]] <- as.list(smooth)
                lines(my_time,smooth,type="l",col=line_colors[1],lwd=3)
            }
        }
    }
    rm(y)
    gc()
    #plot rest lines
    if(length(ois)>1) {
        for (i in 2:length(ois)) {  
            oi_frame=plot_frame_all[plot_frame_all$oi_id==ois[i],]
            oi_plot_frame=oi_frame                   
            n=nrow(oi_plot_frame)
            if (n>1) { 
                my_time=oi_plot_frame$measurement_time
                 y=oi_plot_frame$measurement_value
                rm(oi_plot_frame)
                gc()
                #print(head(oi_plot_frame))
                #print(n)
                if (meta$quanttype=='integer') {y=round(y,0)}
                lines(my_time,y,col=line_colors[i],type="b")
                
                #smooth
                if (meta$quanttype=='desimal') {
                    if (n>10 && n< 10000) {
                        t=seq(1:n)
                        gridsize <-length(y)
                        bw <- dpill(t, y, gridsize=(gridsize))
                        lp <- locpoly(x=t, y=y, bandwidth=bw, gridsize=gridsize)                     
                        smooth <- lp$y
                        smooth_list[[i]] <- as.list(smooth)
                        lines(my_time,smooth,type="l",col=line_colors[i],lwd=3)
                    }
                }
                rm(y)
                gc()
            }
        }
    }
 
    #add axis to plot 
    #x axis ticks vary depending on the plot_time_unit and number of days  
  
    if (plot_time_unit!="year") { 
        days <-unique(as.Date(plot_frame_all$measurement_time))
  
        #plot months
        if (length(days)>30) {
            axis.POSIXct(1, at = seq(min_x, max_x, by = "month"), format = "%Y-%m",cex.axis=0.6,las=2)
    
            #plot days 
        }   else if (length(days)>1) {
            axis.POSIXct(1, at =seq(min_x, max_x, by = "day"), format = "%Y-%m-%d",cex.axis=0.6,las=2)
        # plot hours
        }  else { 
            axis.POSIXct(1, at = seq(min_x, max_x, by = "hour"), format = "%d-%H",cex.axis=0.6,las=2)
        }  
    } else {  
        #years 
        axis.POSIXct(1, at = seq(min_x, max_x, by = "year"), format = "%Y",cex.axis=0.6,las=2)
    }

    #lines
        #abline(h=mean(vals),col="blue",lwd=2) #total mean makes no sense here
    if (!is.na(meta$referenvalue_type)){
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
    legend("topright",c("Refvalue","Alarm","Limits"), lty=c(1,4,1,4), col=c("blue","blue","red","grey"), horiz=FALSE, cex=0.6)
    legend("bottomleft",c(ois), lty=c(1,1,3), col=line_colors[1:length(ois)], horiz=FALSE, cex=0.6)
    
    return(smooth_list)
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
						data <- deploy_ts_quant_1var_1plotnline(varids,oitype,oiids, starttime,endtime,timeunit,dbcon,imagetype)
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
write(toJSON(output_data), file=outputfile)