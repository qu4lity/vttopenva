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
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

deploy_barplot=function(varids, oitype, oiids=NULL, starttime=NULL, endtime=NULL,dbcon,imagetype) {  
   on.exit(dbDisconnect(dbcon))
    # get data
    oiids_temp=paste("(",oiids,")",sep="")
    my_meta=getMetadata(dbcon,varids)
    my_frame=getVariableValues_partition(dbcon,variableid=varids,oiids=oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
    n=nrow(my_frame)
    if (n==0) stop(paste("OpenVA warning: No data found:", my_meta$report_title)) 
    # data found
    if (my_meta$propertytype=="b") {
    	variable=my_frame$measurement_value
    } else {
    	variable=my_frame$measurement_value
    }
    starttime=min(my_frame$measurement_time)
    endtime=max(my_frame$measurement_time)
    # make plot titles
    my_ois=getOIs(dbcon,oiids_temp,oitype=my_meta$oitype_title)
    my_ois_title=paste(my_ois[,c("report_title")],collapse = ',')
    
     #get and match nominal data codevalues
    my_code=NA
    my_code=my_meta$codes_id
    if(!is.na(my_code)) {
    #coded values
    	title = paste(my_meta$report_title, my_ois_title,"\nn= ",nrow(my_frame))
        my_codevalues=getCodeValues(dbcon,codesid=my_code)
        my_codevalues$code_value=as.numeric(my_codevalues$code_value)
        plot_frame=merge(my_frame,my_codevalues,by.x="measurement_value",by.y="code_value")
       
        rm(my_frame)
        gc()

        return_matrix <- plot_bars(variable=plot_frame$title,title,starttime,endtime)
        rm(plot_frame)
        gc()
     
    } else if (my_meta$propertytype=="b") {
    	title = paste(my_meta$report_title, my_ois_title,"\nn= ",nrow(my_frame))
    	return_matrix <- plot_bars(variable=my_frame$background_value,title)
    }  else{
    # no codevalues, numeric data
    	title = paste(my_meta$report_title, my_ois_title,"\nn= ",nrow(my_frame),"\n", starttime,"-",endtime)
        return_matrix <- plot_bars(variable=my_frame$measurement_value,title,starttime,endtime)
    }
	rm(my_frame)
    gc()
    return_list <- list(return_matrix,title,imagetype)
    names(return_list) <-c("values","main_title","imagetype")
    rm(return_matrix)
    gc()
    return(return_list)
}


plot_bars=function(variable,title,starttime,endtime)
{
  my_table=table(variable)
  barplot(my_table,main=title,col="blue")
  return(as.list(my_table))
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
						data <- deploy_barplot(varids, oitype, oiids,starttime,endtime,dbcon,imagetype)
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