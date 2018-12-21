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
#print(scriptPath)

source(paste(scriptPath, "common.R", sep="/"))

connectDB <- function()
{
	mysql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(mysql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}


visualize_auxengine_load=function(starttime=NULL,endtime=NULL,dbcon,imagetype)
{
    on.exit(dbDisconnect(dbcon))
#get ship ids
    ois=getOIs(dbcon,oiids=NULL,oitype="ship")
#matrix for aux values  
    aux_matrix=matrix(nrow=5,ncol=nrow(ois)) 
    colnames(aux_matrix)=ois$title
    rownames(aux_matrix)=c("aux1","aux2","aux3","aux4","aux5")
    aux_matrix[]=0
#three plots, one for each ship     
    par(mfrow=c(3,1))
    for (i in 1:nrow(ois))
    {
        my_ship=ois[i,"report_title"]
        oiid=as.character(ois[i,"id"])
        oi_title=as.character(ois[i,"title"])
#get auxengine_load_averagedata for each aux
        for (j in 1:5)
        {
            property_type_title = paste("auxengine",j,"_load_percentage",sep="")
            mean_value = get_mean_partitioned(dbcon,oi_title,property_type_title,starttime,endtime)
            #print(mean_value)
            if (is.na(mean_value$avg) || mean_value$avg==0) {
                aux_matrix[j,i] =0
            } else {
                aux_matrix[j,i]= mean_value$avg
            } 
        }
  #plot
        main_title=paste(my_ship,"Auxengines load percentage","\n",starttime,"-",endtime)
        bartitles=rownames(aux_matrix)
        midpoint=barplot(aux_matrix[,i],main=main_title,ylab="%",beside=FALSE, col=c("blue"),
                   names.arg=bartitles)
    #add percentances 
        pros1= round(aux_matrix[,i],0)
         text(midpoint, aux_matrix[,i]/2,paste(pros1,"%"),col="white",cex=0.9)
    }
    dev.off()
    return(list(ois=ois,return_matrix=aux_matrix,starttime=starttime,endtime=endtime,imagetype=imagetype))
}     


varids = "<varids>"
oiids = "<oiids>"
starttime = "<starttime>"
endtime = "<endtime>"
timeunit = "<timeunit>"
outputfile = "<outputfile>"
imagetype = "<imagetype>"
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
        					svglite(localResultFile);
    					} else {
							png(filename=localResultFile)
						}
						dbcon <- connectDB()
						data <- visualize_auxengine_load(starttime,endtime,dbcon,imagetype)
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
			while (!is.null(dev.list()))  dev.off()
		})
write(toJSON(output_data), file=outputfile)