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

# Author: Paula J�rvinen, Pekka Siltanen

library(RPostgreSQL)
args <- commandArgs(trailingOnly = F)
scriptPath <- dirname(sub("--file=","",args[grep("--file",args)]))
print(scriptPath)

connectDB <- function()
{
	Sys.setenv("TZ"="UTC")
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

source(paste(scriptPath, "common.R", sep="/"))

variableCounts=function(varids,oiids, starttime=NULL,endtime=NULL,dbcon,imagetype)
{  

  on.exit(dbDisconnect(dbcon))
  variableid=varids

    my_oi=getOIbyOIId(dbcon,oiids)
    if (nrow(my_oi)==0) {
    	stop("No objectofinterest found, try another")
    }
    if (nrow(my_oi) > 1) {
    	stop("Select only one object")
    }
    my_meta= getMetadata(dbcon,variableid)
    if (nrow(my_meta)==0) {
    	stop("No variable found, try another")
    }
	if (nrow(my_meta) > 1) {
    	stop("Select only one variable")
    }
    
	#get counts
  	if (is.null(starttime)) {   
    	query=sprintf("SELECT min(measurement_time) FROM %s",my_table)  
    	response = dbGetQuery(dbcon,query)
    	starttime=response[1]
    	if (is.na(starttime$min)) {  
    		stop("OpenVA message:No starttime found, try another")  
    	}	 
  	}
  	if (is.null(endtime)) {   
    	query=sprintf("SELECT max(measurement_time) FROM %s" ,my_table) 
    	response = dbGetQuery(dbcon,query)
    	endtime=response[1]
    	if (is.na(endtime$max))  { 
    		stop("OpenVA message:No endtime found, try another")
    	}
  	}



    response=getMeasurementDailyCounts(varids=variableid,oiids=oiids, starttime,endtime,dbcon)
    response$month = format(as.Date(response$day,format="%Y-%m-%d"), format = "%m")
    print(response)
    n = count_data(variableid,my_oi$id, starttime,endtime,dbcon)

  	# time in hours (10 sec interval)
  	if (n[1]==TRUE) {
  		recorded_time = n[[2]]/360;
  	} else {
  		recorded_time = NA;
  	}
  	
  	period = as.numeric(difftime(endtime, starttime, units="hour"))  
	

    if (nrow(response)==0) {
    	stop(paste("OpenVA message: No data found for",my_meta$report_title,my_oi$report_title ))
    }

   xLabel = paste("n=",n[[2]],"Period hours=",format(round(period, 2)),"Recorded hours=",format(round(recorded_time, 2), nsmall = 2));
      print(period)
    plot(response$day,response$value,type='h',  
         main=paste(my_meta$report_title, "\ndaily observations \n",my_oi$report_title,"\n",
                    format(starttime, format="%Y-%m-%d %H:%M:%S")," - ",format(endtime, format="%Y-%m-%d %H:%M:%S")),xlab=xLabel,ylab="n",
                   col="blue", cex.main=0.9, cex.lab=0.9,xaxt="n")
    if (period > 730) {  
    	locs <- as.Date(tapply(X=response$day, FUN=min, INDEX=format(response$day, '%Y-%m')))          
   	 	axis.Date(1,at=locs,labels=format(locs,"%Y-%m"),las=2,cex.axis=0.6)
    } else {
    	axis.Date(1,at=response$day,labels=format(response$day,"%y-%m-%d"),las=2,cex.axis=0.6)
    }
    return(list(response=response,imagetype=imagetype))
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
						data <- variableCounts(varids,oiids, starttime,endtime,dbcon,imagetype)
						
						data["image"] = resultUrl
						data["title"] = "Data values daily"
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