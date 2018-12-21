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
connectDB <- function()
{
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

source(paste(scriptPath, "common.R", sep="/")) 

deploy_contourplot=function(varids,oitype,oiids=NULL, starttime=NULL,endtime=NULL,dbcon ,imagetype) {  

 
  on.exit(dbDisconnect(dbcon))
  variableid=varids
  #check time unit
 
    on.exit(dbDisconnect(dbcon))
    #check time unit
    if (length(strsplit(variableid, ",")[[1]]) > 1) {stop("OpenVA warning: only one variableid supported")}
    my_meta=getMetadata(dbcon,variableid)

    if (nrow(my_meta)==0) {
        stop("OpenVA warning: No variable found, try another")
    }
    #print(my_meta$variabletype)
    if (my_meta$variabletype=="nots") {
        stop("OpenVA warning: contour plot only for timeseries data")
    }
    #print(my_meta$time_unit)
    if (my_meta$time_unit=="day") {
        stop("OpenVA warning: no contour plot for daily indicators")
    }
  
    #read data    
    #  my_frame=getMeasurementValues(dbcon,variableid=variableid,oiids=oiids,starttime=starttime,endtime=endtime)
    oiids_temp=paste("(",oiids,")",sep="")

    day_hour_values=getVariableValues_partition_aggregated(dbcon,variableid=variableid,oiids=oiids,oitype=oitype,starttime=starttime,endtime=endtime)
    if (nrow(day_hour_values)==0) {
        stop("OpenVA warning: No data, try another time period")
    }

  if (nrow(day_hour_values)==0) {
    stop("OpenVA warning: No data, try another time period")
   }
  
      #get oi_titles
    my_ois=getOIs(dbcon,oiids_temp,oitype=my_meta$oitype_title)
    my_ois_title=paste(my_ois[,c("report_title")],collapse = ',')
  
  #rowcount=nrow(day_hour_values)
  oi_titles=my_ois$title
  property_title=my_meta$title
  rowcount = list()
  for (i in 1:length(oi_titles)) {
    oi_title = oi_titles[[i]]
    rowcounti=get_rowcount(dbcon,property_title,oi_title,starttime=starttime,endtime=endtime)$count
    rowcount = append(rowcount,rowcounti)
  }
  
  if(isTRUE(all.equal( max(day_hour_values$value) ,min(day_hour_values$value)) )) {
    stop("OpenVA warning: No valid data for contourplot")
  }
  
  if (is.null(starttime)) {
    starttime=min(day_hour_values$day)
  }
  if (is.null(endtime)) {
    endtime=max(day_hour_values$day)
  }

  #create data matrix for contour plot
  if (!is.na(my_meta$lowerlimit)) {
    missing_fill = my_meta$lowerlimit;
  } else {
    missing_fill = NA;
  }
  contour_data=cast(day_hour_values, day~hour, mean,fill=missing_fill,drop=FALSE)

  rm(day_hour_values)
  gc()
  days=as.Date(contour_data$day)
  hours=as.numeric(colnames(contour_data)[2:ncol(contour_data)])
  plot_matrix=as.matrix(contour_data[,2:ncol(contour_data)])
  colnames(plot_matrix)=hours
  rownames(plot_matrix)=(days)
  rm(contour_data)
  gc()
  return_list = plot_contour(plot_matrix=plot_matrix,days=days,hours=hours,paste(rowcount, collapse=","),metadata=my_meta, ois_title=my_ois_title, starttime,endtime)

  rm(plot_matrix)
  gc()
  return(return_list)
}


plot_contour=function(plot_matrix,days,hours,rowcounts, metadata,ois_title, starttime,endtime)
{
#create data matrix for contour plot
  n=rowcounts
  contour_title=paste(metadata$report_title, metadata$numunit,"\n",ois_title,"\nn=",n,"\n",starttime," - ",endtime)
  contour_levels=7
  contour_colors=brewer.pal(n=9, name="Blues")
  #plot
    filled.contour(x=days, y=hours , z=plot_matrix
                 ,  col =contour_colors,  nlevels= contour_levels, 
                 plot.title = title(main = contour_title, ylab = "Hour", xlab="Day"),
                 plot.axes =  { axis.Date(side=1,x=days,at=days,format="%d-%m"); axis(2) },
                 key.title=title(metadata$numunit))
               
    hours=as.character(hours)  
    days=as.character(days)  
    plot_matrix = t(plot_matrix)
    plot_matrix = plot_matrix[nrow(plot_matrix):1, ]
	colnames(plot_matrix) <- NULL
	rownames(plot_matrix) <- NULL
    plot_matrix = apply(plot_matrix, 1, as.list)
   	return_list <- list(hours,days,plot_matrix,contour_title,"Day","Hour",metadata$numunit,imagetype)
	names(return_list) <-c("hours","days","hour_data","main_title","x_title","y_title","legend_title","imagetype")
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

if (oiids=="null")  {
	oiids=NULL;
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
							png(filename=localResultFile)
						}
						dbcon <- connectDB()
						data <- deploy_contourplot(varids, oitype, oiids,  starttime, endtime,dbcon,imagetype)
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