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

library(RPostgreSQL)
args <- commandArgs(trailingOnly = F)
scriptPath <- dirname(sub("--file=","",args[grep("--file",args)]))

connectDB <- function() {
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

source(paste(scriptPath, "common.R", sep="/"))

# note this version of boxplot requires the oiids to be selected on same hierarchy level
# if only one oi, only one boxplot
# 

deploy_boxplot=function(child_variableid, oitype,child_oiids,starttime,endtime,dbcon,imagetype)
{  
    on.exit(dbDisconnect(dbcon))
    my_frame= getVariableValues_partition(dbcon,variableid=child_variableid,oiids= child_oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)

    n=nrow(my_frame)
    my_meta=getMetadata(dbcon,child_variableid)

    if (n==0)  {stop(paste("OpenVA warning: No data found",    my_meta$report_title))}
    
    oiids_temp=paste("(",child_oiids,")",sep="")
    my_ois=getOIs(dbcon,oiids_temp) 
    oi_title=paste(my_ois[,c("report_title")],collapse = ',')

   
    if (my_meta$variabletype=="ts") {
            starttime=min(my_frame$measurement_time)
            endtime=max(my_frame$measurement_time)
    }
    N=length(unique(my_frame$oi_id))
    my_title=paste(my_meta$report_title,"\n",oi_title,"\nN=",N," n=",n,"\n",starttime,"-",endtime)
   


    my_plot_frame=merge(my_frame,my_ois,by.x="oi_id",by.y="title")
    my_plot_frame=my_plot_frame[,c("measurement_value","report_title") ]

    

    my_plot_frame$report_title=as.factor(my_plot_frame$report_title)

    boxplot_stats= boxplot(my_plot_frame$measurement_value~my_plot_frame$report_title, main=my_title,cex.main=0.9,  ylab=my_meta$numunit, col="blue",las=2)
    rm(my_frame)
    gc()
    if (imagetype=="raster" || imagetype == "vector") {
                return_list <- list(paste(imagetype,"image: no data returned"),imagetype)
                names(return_list) <-c("info","imagetype")
    } else { 
        bp_stats <- boxplot_stats$stats
        bp_n <- boxplot_stats$n
        if (length(boxplot_stats$conf)==0) {
            bp_conf <- "NULL"
        } else {
            bp_conf <- boxplot_stats$conf 
        }
        if (length(boxplot_stats$out)==0) {
            bp_out <- "NULL"
        } else {
            bp_out <- boxplot_stats$out
        }
        if (length(boxplot_stats$group)==0) {
        bp_group <- "NULL"
        } else {
            bp_group <- boxplot_stats$group
        }
        bp_names <- c(boxplot_stats$names)
    

    	bp_stats = apply(bp_stats, 1, as.list)
    
        return_list <- list(bp_stats,bp_n,bp_conf,bp_out,bp_group,bp_names,my_title,my_meta$numunit,imagetype)
        names(return_list) <-c("bp_stats","bp_n","bp_conf","bp_out","bp_group","bp_names","title","y_title","imagetype")
    }
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
	parent_oiid=NULL;
	child_oiid=NULL;
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
        					svglite(localResultFile)
    					} else {
							png(filename=localResultFile)
						}
						dbcon <- connectDB()
						data <- deploy_boxplot(varids,oitype, oiids,starttime,endtime,dbcon,imagetype)
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
print(output_data)
write(toJSON(output_data), file=outputfile)