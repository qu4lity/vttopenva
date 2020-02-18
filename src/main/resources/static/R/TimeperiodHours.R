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

connectDB <- function() {
	Sys.setenv("TZ"="UTC")
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

time_period_data=function(varids, oitype, oiids=NULL, starttime=NULL, endtime=NULL,dbcon,imagetype) {  
  on.exit(dbDisconnect(dbcon))
  variableid=varids

    my_oi=getOIbyOIId(dbcon,oiids)
    if (nrow(my_oi)==0) {
    	stop("No objectofinterest found, try another")
    }
    if (nrow(my_oi) > 1) {
    	stop("Select only one object")
    }
	my_ois_title = my_oi$report_title
    
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
    n = count_data(variableid,my_oi$id, starttime,endtime,dbcon)

  	# time in hours (10 sec interval) we should really red it from metadata 
  	if (n[1]==TRUE) {
  		recorded_hours = format(round(n[[2]]/360, 2));
  	} else {
  		recorded_hours = NA;
  	}
  	
  	period_hours = format(round(as.numeric(difftime(endtime, starttime, units="hour")), 2))  
	

    if (nrow(response)==0) {
    	stop(paste("OpenVA message: No data found for",my_meta$report_title,my_oi$report_title ))
    }

   title = paste(my_meta$report_title, my_ois_title,"\nn= ",n[2],"\n", starttime,"-",endtime)
   hours <- c(recorded_hours, period_hours)
   x = barplot(as.numeric(hours), main = title,names.arg = c("Recorder hours", "Total hours"),col="blue")
  	text(x, 0, hours,cex=1.5,pos=3,col="white")
    return_list <- list(hours,title,imagetype)
    names(return_list) <-c("values","main_title","imagetype")
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
			suppressMessages(
					{
					    if (imagetype == "vector") {
        					svglite(localResultFile);
    					} else {
							png(filename=localResultFile)
						}
						dbcon <- connectDB()
						data <- time_period_data(varids, oitype, oiids,starttime,endtime,dbcon,imagetype)
						data["image"] = resultUrl
						data["title"] = "Timeperiod hours"
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