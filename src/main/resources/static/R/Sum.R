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

#########################################################################################
#function for total value visualization for quantative.
#shows sum for  cumulative variables, mean for absolute variables
#launches a calculated value function for the given variableid, shows the result visualization, 
#
##input parameters 
#- variableid 
#- oiids, comma separated list of oiids 
#- starttime,endtime, can be NULL
#
#output
#a list containing
#- input variable id 
#- calculated_value, percentage or mean 
#- n, number of observateions used in calculation 
#- starttime of time period
#- endtime of time perieod
#- oi_title, names of objects of interest
#- metadata, variable metadata
#only with average calculation:
#- sd, standard deviation, 
#- min value,      
#- max value


#requires 
#- db-functions
#- functions for the variable calculations 

args <- commandArgs(trailingOnly = F)
scriptPath <- dirname(sub("--file=","",args[grep("--file",args)]))
print(scriptPath)

source(paste(scriptPath, "common.R", sep="/"))

connectDB <- function() {
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

deploy_sum_value=function(variableid,oitype,oiids, starttime=NULL,endtime=NULL,dbcon,imagetype) {

    on.exit(dbDisconnect(dbcon))
    
    n=0
    calculated_value=NA

    my_meta=getMetadata(dbcon,variableid)
    my_variable=my_meta$title
  
#title preparation
    oiids_temp=paste("(",oiids,")",sep="")
    my_ois=getOIs(dbcon,oiids_temp) 
    oi_title=paste(my_ois[,c("report_title")],collapse = ',')
  
    if (my_meta$plottype=='sum') {
        sum_vec <- NULL;
        for (i in 1:length(my_ois$title)) {
            sum<-get_sum_partitioned(dbcon,my_ois$title[[i]],my_variable,starttime,endtime)
            sum_vec[i]<-sum$sum
            n = n + sum$count
        }
        result_value = sum(sum_vec)
#        result_value=sum(result_data$measurement_value,na.rm=TRUE )
        x_title ="Total sum"
    }   else if (my_meta$plottype=='mean') {
        mean_vec <- NULL;
        for (i in 1:length(my_ois$title)) {
            avg <- get_mean_partitioned(dbcon,my_ois$title[[i]],my_variable,starttime,endtime)
            mean_vec[i]<-avg$avg
            n = n + avg$count
        }
        result_value = mean(mean_vec)
        #print(mean_vec$avg)
#        result_value=mean(result_data$measurement_value,na.rm=TRUE)
        x_title ="Mean value"
        }   else {stop("OpenVA warning: not valid plottype")}

    result_value=round(result_value,3)
    
    if (is.null(starttime) || is.null(endtime)) {

        minmax = get_minmaxtime_partitioned(dbcon,variableid, oiids,oitype)

        if (is.null(starttime)) {
            starttime=minmax$min
        }
        if (is.null(endtime)) {
            endtime=minmax$max
        }
    }
    rm(result_data)
    gc()
#visualization 
    main_title = paste(variable_title=my_meta$report_title,"\n",oi_title,"\nn=",n,"\n",starttime," - ",endtime)
    y_title = my_meta$numunit
   
    midpoint= barplot(result_value, col=c("darkblue"),
            main=main_title, cex.main=0.9,
            ylab=y_title,xlab=x_title)
    text(midpoint, result_value/2, paste(result_value,my_meta$numunit),col="white",cex=1.5)

    return_list <- list(my_variable,result_value,  n,   main_title, x_title ,y_title,imagetype)
    names(return_list) <-c("variable","calculated_value","n","main_title", "x_title", "y_title","imagetype")
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
						data <- deploy_sum_value(varids,oitype,oiids, starttime,endtime,dbcon,imagetype)
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