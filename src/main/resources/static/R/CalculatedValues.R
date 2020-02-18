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
#

# Author: Paula Järvinen, Pekka Siltanen


#requires
#- db-functions
#- functions for the variable calculations

args <- commandArgs(trailingOnly = F)
scriptPath <- dirname(sub("--file=", "", args[grep("--file", args)]))

source(paste(scriptPath, "common.R", sep = "/"))

connectDB <- function() {
  Sys.setenv("TZ"="UTC")
  psql <- dbDriver("PostgreSQL")
  dbcon <-
    dbConnect(
      psql,
      host = "<host>",
      port =  <port> ,
      dbname = "<dbname>",
      user = "<user>",
      pass = "<password>"
    )
  return(dbcon)
}

percentage_barplot = function(calculated_value,min_value,max_value,oi_title,starttime,endtime,n,my_meta) {
    min_value = 0
    max_value = 100
    barplot(
      as.matrix(c(
        calculated_value, 100 - calculated_value
      )),
      col = c("darkblue", "white"),
      main = paste(
        variable_title = my_meta$report_title,
        "\n",
        oi_title,
        "\nn=",
        n,
        "\n",
        starttime,
        " - ",
        endtime
      ),
      cex.main = 0.9,
      ylab = my_meta$numunit,
      xlab = paste(
        my_meta$report_title,
        "=",
        round(calculated_value, 2),
        my_meta$numunit
      )
    )
}

percentage_simpleplot = function(calculated_value,min_value,max_value,oi_title,starttime,endtime,n,my_meta) {
	par(mar = c(0,0,0,0))
	plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
	text(x = 0.5, y = 0.8, paste(my_meta$report_title,"\n",
        				         oi_title,"\n",
        				         starttime," - ",endtime,"\n",
        				         "Percentage value:"),font=2)
       
    text(x = 0.5, y = 0.5, paste(round(calculated_value, 2),my_meta$numunit),cex=2)   
        					     
   	text(x = 0.5, y = 0.3, paste("n=",n))        					
}


avg_barplot = function(calculated_value,sd_value,min_value,max_value,lower_limit,upper_limit,oi_title,starttime,endtime,n,my_meta) {
    barplot(
      as.matrix(c(
        lower_limit,
        upper_limit - lower_limit,
        (upper_limit + 0.1 * upper_limit) - upper_limit
      )),
      col = c("white", "grey", "white"),
      main = paste(
        variable_title = my_meta$report_title,
        "\n",
        oi_title,
        "\nn=",
        n,
        "\n",
        starttime,
        " - ",
        endtime
      ),
      cex.main = 0.9,
      ylab = my_meta$numunit,
      xlab = paste(
        my_meta$report_title,
        "=",
        round(calculated_value, 2),
        my_meta$numunit
      ),
      cex.axis = 0.9,
      sub = paste(
        "min=",
        round(min_value, 2),
        "max=",
        round(max_value, 2),
        "sd=",
        round(sd_value, 2)
      ),
      cex.sub = 0.9
    )
    
    abline(h = calculated_value, col = "red", lwd = 2)
    abline(h = min_value, col = "black", lwd = 1)
    abline(h = max_value, col = "black", lwd = 1)
    legend(
      "topright",
      c("mean", "min,max"),
      lty = c(1, 1),
      col = c("red", "black"),
      horiz = FALSE,
      cex = 0.6
    )
}

avg_simpleplot = function(calculated_value,sd_value,min_value,max_value,lower_limit,upper_limit,oi_title,starttime,endtime,n,my_meta) {
	par(mar = c(0,0,0,0))
	plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
	text(x = 0.5, y = 0.8, paste(my_meta$report_title,"\n",
        				         oi_title,"\n",
        				         starttime," - ",endtime,"\n",
        				         "Average value:"),font=2)
       
    text(x = 0.5, y = 0.5, paste(round(calculated_value, 2),my_meta$numunit),cex=2)    
        					     
   	text(x = 0.5, y = 0.3, paste("n=",n,"\n",        					 
        					     "sd=",round(sd_value, 2),"\n", 
        					     "min=",round(min_value, 2),"\n",
        					     "max=",round(max_value, 2),"\n"))    					     
}

sum_barplot = function(calculated_value,oi_title,starttime,endtime,n,my_meta) {
	    midpoint = barplot(
      calculated_value,
      col = c("darkblue"),
      main = paste(
        variable_title = my_meta$report_title,
        "\n",
        oi_title,
        "\nn=",
        n,
        "\n",
        starttime,
        " - ",
        endtime
      ),
      cex.main = 0.9,
      ylab = my_meta$numunit,
      xlab = "Total sum of the given time period"
    )
    #xlab=paste(my_meta$report_title,"=", round(calculated_value,2),my_meta$numunit))
    text(
      midpoint,
      calculated_value / 2,
      paste(round(calculated_value, 2), my_meta$numunit),
      col = "white",
      cex = 2
    )
}

sum_simpleplot = function(calculated_value,oi_title,starttime,endtime,n,my_meta) {

	par(mar = c(0,0,0,0))
	plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')   
        					     
	text(x = 0.5, y = 0.8, paste(my_meta$report_title,"\n",
        				         oi_title,"\n",
        				         starttime," - ",endtime,"\n",
        				         "Sum of the values:"),font=2)
       
    text(x = 0.5, y = 0.5, paste(round(calculated_value, 2),my_meta$numunit),cex=2)    
        					              					     
	text(x = 0.5, y = 0.3, paste("n=",n))        					          					             					   
}

abs_barplot = function(calculated_value,oi_title,starttime,endtime,n,my_meta) {
    midpoint = barplot(
      calculated_value,
      col = c("darkblue"),
      main = paste(
        variable_title = my_meta$report_title,
        "\n",
        oi_title,
        "\nn=",
        n,
        "\n",
        starttime,
        " - ",
        endtime
      ),
      cex.main = 0.9,
      ylab = my_meta$numunit,
      xlab = "Value the given time period"
    )
    #xlab=paste(my_meta$report_title,"=", round(calculated_value,2),my_meta$numunit))
    text(
      midpoint,
      calculated_value / 2,
      paste(round(calculated_value, 2), my_meta$numunit),
      col = "white",
      cex = 2
    )
}


abs_simpleplot = function(calculated_value,oi_title,starttime,endtime,n,my_meta) {
	par(mar = c(0,0,0,0))
	plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
        					     
	text(x = 0.5, y = 0.8, paste(my_meta$report_title,"\n",
        				         oi_title,"\n",
        				         starttime," - ",endtime,"\n",
        				         "Calculated value:"),font=2)
       
    text(x = 0.5, y = 0.5, paste(round(calculated_value, 2),my_meta$numunit),cex=2)    
        					             					     
        					     
}

deploy_calculated_value = function(variableid,
                                   oitype,
                                   oiids,
                                   starttime = NULL,
                                   endtime = NULL,
                                   dbcon,
                                   imagetype)
{
  on.exit(dbDisconnect(dbcon))
  n = 0
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  #launch calculation
  my_meta = getMetadata(dbcon, variableid)
  #print(paste("my_meta",my_meta))
  my_variable = my_meta$title
  print(my_variable)
  my_function = paste("calculate_", my_variable, sep = "")
  #print(my_function)
  
  merged_data=data.frame(matrix(ncol=0,nrow=0))   
  result = do.call(my_function, list(dbcon, oitype, oiids, starttime, endtime,merged_data))
  #print(result)
  #title preparation
  oiids_temp = paste("(", oiids, ")", sep = "")
  my_ois = getOIs(dbcon, oiids_temp)
  oi_title = paste(my_ois[, c("report_title")], collapse = ',')
  #any results?
  #print(result)
  n = result$n
  if (n == 0) {
    stop(paste("OpenVA warning: No data available", my_variable, oi_title))
  }
  if (n == 1) {
    stop(
      paste(
        "OpenVA warning: Not enough data, try longer time period for ",
        my_variable,
        oi_title
      )
    )
  }
  calculated_value = result$calculated_value
  if (is.na(calculated_value)) {
    stop(paste("OpenVA warning:No result available", my_variable, oi_title))
  }
  starttime = result$starttime
  endtime = result$endtime
  #plot visualization
  if (result$visutype == "%") {
    #percentage visualisation
    print("percentage visualisation")
    #percentage_barplot(calculated_value,min_value,max_value,oi_title,starttime,endtime,n,my_meta)
    percentage_simpleplot(calculated_value,min_value,max_value,oi_title,starttime,endtime,n,my_meta)
    
  }  else if (result$visutype == "avg") {
    #avg visualization
    
    print("avg visualization")
    sd_value = result$sd_value
    min_value = result$min_value
    max_value = result$max_value
    lower_limit = min_value
    upper_limit = max_value
    
    #avg_barplot(calculated_value,sd_value,min_value,max_value,lower_limit,upper_limit,oi_title,starttime,endtime,n,my_meta)
    avg_simpleplot(calculated_value,sd_value,min_value,max_value,lower_limit,upper_limit,oi_title,starttime,endtime,n,my_meta)
  } 
  else if (result$visutype == "sum")
  {
    #sum visualization
	print("sum visualization")
    #sum_barplot(calculated_value,oi_title,starttime,endtime,n,my_meta)  
    sum_simpleplot(calculated_value,oi_title,starttime,endtime,n,my_meta)  
  } 
  else if (result$visutype == "abs") {
	#abs visualization
	print("abs visualization")
    #abs_barplot(calculated_value,oi_title,starttime,endtime,n,my_meta)  
    abs_simpleplot(calculated_value,oi_title,starttime,endtime,n,my_meta)    
  } 
  main_title = paste(
    variable_title = my_meta$report_title,
    "\n",
    oi_title,
    "\nn=",
    n,
    "\n",
    starttime,
    " - ",
    endtime
  )
  y_title = my_meta$numunit
  x_title = paste(my_meta$report_title,
                  "=",
                  round(calculated_value, 2),
                  my_meta$numunit)
  
  return_list <-
    list(
      my_variable,
      calculated_value,
      n,
      sd_value,
      min_value,
      max_value,
      main_title,
      x_title ,
      y_title,
      imagetype
    )
  names(return_list) <-
    c(
      "variable",
      "calculated_value",
      "n",
      "sd",
      "min",
      "max",
      "main_title",
      "x_title",
      "y_title",
      "imagetype"
    )
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

if (oiids == "null")  {
  oiids = NULL
  
}
if (starttime == "null")  {
  starttime = NULL
  
}
if (endtime == "null")  {
  endtime = NULL
  
}


output_data <- tryCatch({
  	suppressWarnings({
    	if (imagetype == "vector") {
      		svglite(localResultFile)
    	} else {
      		png(filename = localResultFile)
    	}
    	dbcon <- connectDB()
    	data <- deploy_calculated_value(varids, oitype, oiids, starttime, endtime, dbcon, imagetype)
    	data["image"] = resultUrl
		data["title"] = "Calculated value"
		data["width"] = 600
		data["height"] = 600	
    	data
  })
},
error = function(cond) {
  message(cond)
  return_list <- list(cond$message)
  names(return_list) <- c("error")
  return(return_list)
},
finally = {
  dev.off()
})
write(toJSON(output_data), file = outputfile)