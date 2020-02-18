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

connectDB <- function()
{
	Sys.setenv("TZ"="UTC")
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}

visualize_ship_steaming_maneuvering=function(oiids,dbcon,oitype,starttime,endtime,imagetype)
{
    on.exit(dbDisconnect(dbcon))
print("visualize_ship_steaming_maneuvering")    
print(oiids)

#get ship ids
	ois = NULL
	if (is.null(oiids)) {
		ois=getOIs(dbcon,oiids,oitype="ship")
	} else {
		oiids=paste("(",oiids,")",sep="")
    	ois=getOIs(dbcon,oiids,oitype="ship")
    }
    
#result matrix
    sailing_matrix=matrix(nrow=2,ncol=nrow(ois)) 
    colnames(sailing_matrix)=ois$title
    rownames(sailing_matrix)=c("steam","mane")
    sailing_matrix[]=0
#get ship data
    for (i in 1:nrow(ois))
    {
        oiids=as.character(ois[i,"id"])
        oi_title = as.character(ois[i,"title"])
        sum_maneuvering = get_sum_partitioned(dbcon,oi_title,"ship_maneuvering_hours",starttime,endtime)
        sum_steaming = get_sum_partitioned(dbcon,oi_title,"ship_steaming_hours",starttime,endtime) 
        sailing_matrix[,i]=c(sum_maneuvering$sum,sum_steaming$sum)
    }   
        


#plot
    main_title=paste("Ship steaming/maneuvering hours","\n",starttime,"-",endtime)
    bartitles=paste(colnames(sailing_matrix), "\n",round(sailing_matrix["steam",]+sailing_matrix["mane",],2))
     
    par(xpd=TRUE) #for legend
  midpoint=barplot(sailing_matrix,main=main_title,ylab="h",beside=FALSE, col=c("blue","red"),
                   names.arg=bartitles)
  
  
  par(xpd=FALSE)

  
 #calculate % for bar labels
  pros1= round(sailing_matrix["steam",]/ (sailing_matrix["steam",]+ sailing_matrix["mane",])*100,0)
  pros2= round(sailing_matrix["mane",]/ (sailing_matrix["steam",]+ sailing_matrix["mane",])*100,0)
# remove zeros
    for (i in 1:nrow(sailing_matrix)) {
        for (j in 1:ncol(sailing_matrix)) {
            if (is.na(sailing_matrix[i,j]) || sailing_matrix[i,j]==0) {   
                sailing_matrix[i,j]=NA
            }
        }
    }
   
 #add bar labels 
    text(midpoint, sailing_matrix["steam",]/2, 
       paste(round(sailing_matrix["steam",],2),"/",pros1,"%"),col="white",cex=1.5)
    text(midpoint, sailing_matrix["steam",]+sailing_matrix["mane",]/2, 
       paste(round(sailing_matrix["mane",],2),"/",pros2,"%"),col="white",cex=1.5)
       
    par(xpd=TRUE)
    legend("bottomleft", inset=c(0,-0.13), c("maneuvering","steaming"), fill=c("blue","red"), horiz=FALSE)   
       
    return(list(ois=ois,return_matrix=sailing_matrix,starttime=starttime,endtime=endtime,imagetype=imagetype))
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
						data <- visualize_ship_steaming_maneuvering(oiids,dbcon,oitype,starttime,endtime,imagetype)
						data["image"] = resultUrl
						data["title"] = "Steaming/maneuvering"
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