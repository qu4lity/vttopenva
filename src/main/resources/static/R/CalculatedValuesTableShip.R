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
# Author: Paula JÃ¤vinen, Pekka Siltanen
#CalculatedValuesTable
#function for creating a pdf-table of calculated values (calculated by R-script CalculatedValues.R)
###input parameters
#-result_file
#- oi_id (one ship)

#output
#- pdf plotted to given file
#uses functions
#-     CalculatedValues.R
#-     plot_nodata_message.R
#-     db-functions
#notes
#-

args <- commandArgs(trailingOnly = F)
scriptPath <-
  dirname(sub("--file=", "", args[grep("--file", args)]))

source(paste(scriptPath, "common.R", sep = "/"))
library(grid)

connectDB <- function() {
  Sys.setenv("TZ" = "UTC")
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
oiids_temp = paste("(", oiids, ")", sep = "")

 					  
####################################################################
#only one oidi

CalculatedValuesTable  = function(dbcon, oiids,varids ,starttime, endtime)
{
  #create table
  
  if (length(oiids) > 1) {
    
  } else {
    oiids_temp = paste("(", oiids, ")", sep = "")

    
    my_oi = getOIs(dbcon, oiids_temp)
    oi_title = my_oi$title
    oi_report_title=my_oi$report_title
    property_titles = c("fueloil_consumption_total","main_engine_running","me_fo_consumption","ship_steaming","ae_fo_consumption",
    					"DG_1_power","DG_2_power","DG_3_power","DG_4_power","DG_5_power",
    					"DG_1_condition","DG_2_condition","DG_3_condition","DG_4_condition","DG_5_condition","ship_steaming_distance")
    merged_data = full_join_n_variables(dbcon,oi_title,property_titles, starttime, endtime);
    if (nrow(merged_data) > 0) {
      names(merged_data) <-
        c(
          "measurement_time",
          "fueloil_consumption_total",
          "mainengine_running",
          "me_fo_consumption",
          "ship_steaming",
          "ae_fo_consumption",
          "DG_1_power",
          "DG_2_power",
          "DG_3_power",
          "DG_4_power",
          "DG_5_power",
    	  "DG_1_condition",
    	  "DG_2_condition",
    	  "DG_3_condition",
    	  "DG_4_condition",
    	  "DG_5_condition",
    	  "ship_steaming_distance"
        )
    }
#    merged_data=data.frame(matrix(ncol=0,nrow=0))
  
   mytheme <- gridExtra::ttheme_default(
      core = list(fg_params = list(cex = 0.8)),
      colhead = list(fg_params = list(cex = 0.8)),
      rowhead = list(fg_params = list(cex = 0.8))
    )
   
   
   NewTable("report_ship","SHIP",dbcon,oiids_temp,starttime,endtime,merged_data,mytheme,oi_report_title) 
 
  }
}



output_data <- tryCatch({
  suppressWarnings({
	start_time <- Sys.time()
    filePath = file_path_sans_ext(localResultFile)
    localResultFile = paste(filePath, "pdf", sep = ".")
    pdf(localResultFile, height = 11, width = 9)
    dbcon <- connectDB()
    data <- CalculatedValuesTable(dbcon, oiids,varids, starttime, endtime)
    filePath = file_path_sans_ext(resultUrl)
    resultUrl = paste(filePath, "pdf", sep = ".")
    data["file"] = resultUrl
    #size in pixels
    data["width"] = 750
    data["height"] = 1000
    data["imagetype"] = "pdf"
	data["title"] = "Report pdf"
	end_time <- Sys.time()
	print("total time")
 	print(end_time - start_time)
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
