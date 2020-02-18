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


source(paste(scriptPath, "common.R", sep="/"))

connectDB <- function()
{
	Sys.setenv("TZ"="UTC")
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

visualize_ship_fueloil_consumption=function(oiids,starttime=NULL,endtime=NULL,dbcon,imagetype)
{
  on.exit(dbDisconnect(dbcon))

#get ship ids
	ois = NULL
	if (is.null(oiids)) {
	print("getOIs")
		ois=getOIs(dbcon,oiids,oitype="ship")
	} else {
		oiids=paste("(",oiids,")",sep="")
    	ois=getOIs(dbcon,oiids,oitype="ship")
    }

#matrix for results
  consumptions_matrix=matrix(nrow=2,ncol=nrow(ois)) 
  colnames(consumptions_matrix)=ois$title
  rownames(consumptions_matrix)=c("me","aux")
  consumptions_matrix[]=0
  
#get data for ships
  sum_tot = 0;
    for (i in 1:nrow(ois)) {
        oiids=as.character(ois[i,"id"])
        oi_title=as.character(ois[i,"title"])
        sum_distance = get_sum_partitioned(dbcon,oi_title,"ship_sailing_distance",starttime,endtime)
        if (!is.na(sum_distance$sum) && sum_distance$sum>0) {
            sum_consumption = get_sum_partitioned(dbcon,oi_title,"fueloil_consumption_main_engine",starttime,endtime);
            if (!is.na(sum_distance$sum)) {
            	sum_tot = sum_tot + sum_distance$sum 
			}
            consumption_per_distance = sum_consumption$sum/sum_distance$sum
#get aux consumption 
            sum_aux_consumption = get_sum_partitioned(dbcon,oi_title,"fueloil_consumption_aux_engine",starttime,endtime);
            consumption_aux_per_distance = sum_aux_consumption$sum/sum_distance$sum

            consumptions_matrix[,i]=c(consumption_per_distance,consumption_aux_per_distance)
        }
    }
    

    print("sum")
#   if (sum(consumptions_matrix)==0) {
	if (sum_tot==0) {
        stop("OpenVA warning, no data for plot")
    }
    print(sum_tot)
#plot
    main_title=paste("Fueloil consumption/nautical mile","\n",starttime,"-",endtime)
    print("paste")
    bartitles=paste(colnames(consumptions_matrix), "\n",round(consumptions_matrix[1,]+consumptions_matrix[2,],2))
    par(xpd=TRUE) #for legend
      print("plot")
    midpoint=barplot(consumptions_matrix,main=main_title,ylab="kg/Nm",beside=FALSE, col=c("blue","red"),
                 names.arg=bartitles)
    bar_height=max(apply(consumptions_matrix, 2, function(x) sum(x)))
    legend(0,-round(bar_height/10,0),   c("main eng","aux eng"), fill=c("blue","red"), horiz=TRUE)
    par(xpd=FALSE)
       print("plotted")
  #calculate % for plot
    pros_me= round(consumptions_matrix["me",]/ (consumptions_matrix["me",]+ consumptions_matrix["aux",])*100,0)
    pros_aux= round( consumptions_matrix["aux",]/ (consumptions_matrix["me",]+ consumptions_matrix["aux",])*100,0)
    #clean zeros
    for (i in 1:nrow(consumptions_matrix))
    {
        for (j in 1:ncol(consumptions_matrix))
        {   if (consumptions_matrix[i,j]==0) 
            {consumptions_matrix[i,j]=NA}
        }
    }   
    
           print("labels")
#add bar labels
    text(midpoint, consumptions_matrix["me",]/2, 
        paste(round(consumptions_matrix["me",],2),"/",pros_me,"%"),col="white",cex=1.5)
    text(midpoint, consumptions_matrix["me",]+consumptions_matrix["aux",]/2, 
      paste(round(consumptions_matrix["aux",],2),"/",pros_aux,"%"),col="white",cex=1.5)
    return(list(ois=ois,return_matrix=consumptions_matrix,starttime=starttime,endtime=endtime,imagetype=imagetype))
    
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
						start.time <- Sys.time()
						data <- visualize_ship_fueloil_consumption(oiids,starttime,endtime,dbcon,imagetype)
						end.time <- Sys.time()
						time.taken <- end.time - start.time
						data["time"] = time.taken
						data["image"] = resultUrl
						data["title"] = "Fuel oil consumption/NM"
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