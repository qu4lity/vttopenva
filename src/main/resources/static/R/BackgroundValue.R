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

show_background_value=function(db,variableid,oiids)
{
  my_meta=getMetadata(db,variableid)
  my_variable=my_meta$title
  result=getVariableValues(db,variableid,oiids=paste("(",oiids,")"),starttime=NULL,endtime=NULL)
  n=nrow(result)
  #data found? 
  if (n==0) {stop(paste("No data available",my_variable,oi_title))}
  
  lower_limit=my_meta$lowerlimit
  upper_limit=my_meta$upperlimit
  oi=getOIbyOIId(db,oiids) 
  barplot(as.matrix(c(lower_limit,upper_limit-lower_limit,(upper_limit+0.1* upper_limit)-upper_limit)), 
            col=c("white","grey","white"),
            main=paste(my_meta$report_title,"\n",oi$report_title), cex.main=0.9  ,
            ylab=my_meta$numunit,xlab=paste(my_meta$report_title,"=", round(result$background_value,2),my_meta$numunit),cex.axis=0.9)          
  abline(h=result$background_value,col="red",lwd=2)
  
  return(list(calculated_value=result$background_value, main_title=paste(my_meta$report_title,"\n",oi$report_title),x_title=paste(my_meta$report_title,"=", round(result$background_value,2)),y_title=""))
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
						data <- show_background_value(dbcon,varids,oiids)
						data["image"] = resultUrl
						data["imagetype"] = imagetype
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