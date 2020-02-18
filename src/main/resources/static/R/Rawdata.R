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

library(tools)
args <- commandArgs(trailingOnly = F)
scriptPath <- dirname(sub("--file=","",args[grep("--file",args)]))

connectDB <- function()
{
	Sys.setenv("TZ"="UTC")
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

source(paste(scriptPath, "common.R", sep="/"))

get_rawdata=function(variableid,oiids=NULL, starttime=NULL,endtime=NULL,dbcon,localResultFile,resultUrl) {  
    on.exit(dbDisconnect(dbcon))
    my_meta=getMetadata(dbcon,variableid)
    print(starttime)
    print(endtime)
    
    if (nrow(my_meta)==0) {
        stop("No variable found, try another")
    }
  
    #read data    
    oiids_temp=paste("(",oiids,")",sep="")

    my_frame=getVariableValues_partition(dbcon,variableid=variableid,oiids=oiids,oitype=oitype,starttime=starttime,endtime=endtime,FALSE)
    if (nrow(my_frame)==0) {
        stop("OpenVA warning: No data, try another time period")
    }
    
    print("order")
    my_frame[order(my_frame$measurement_time),]
    
    print(head(my_frame))
  

    fileName <- paste(my_meta$ title,".csv",sep="")
      
    write.csv(my_frame[c("measurement_value", "measurement_time","oi_id")], file = localResultFile)
    rm(my_frame)
    gc()
    
 	return_list <- list(fileName,"data",resultUrl)
	names(return_list) <-c("filename","imagetype","file")
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
						filePath = file_path_sans_ext(localResultFile)
						localResultFile = paste(filePath, "csv", sep=".")
						filePath = file_path_sans_ext(resultUrl)
						resultUrl = paste(filePath, "csv", sep=".")
						dbcon <- connectDB()
						data <- get_rawdata(varids, oiids, starttime, endtime,dbcon,localResultFile,resultUrl)
						data["title"] = "Raw data"
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
		})
print(output_data)
write(toJSON(output_data), file=outputfile)