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


time_period_hours=function(varids, oitype, oiids=NULL, starttime=NULL, endtime=NULL,dbcon) {  
  variableid=varids

    my_oi=getOIbyOIId(dbcon,oiids)
    if (nrow(my_oi)==0) {
    	stop("No objectofinterest found, try another")
    }
    if (nrow(my_oi) > 1) {
    	stop("Select only one object")
    }
	my_ois_title = my_oi$report_title
    
    my_meta= getMetadata(dbcon,variableid)
    if (nrow(my_meta)==0) {
    	stop("No variable found, try another")
    }
	if (nrow(my_meta) > 1) {
    	stop("Select only one variable")
    }
    
    
	#get counts
  	if (is.null(starttime)) {   
    	query=sprintf("SELECT min(measurement_time) FROM %s",my_table)  
    	response = dbGetQuery(dbcon,query)
    	starttime=response[1]
    	if (is.na(starttime$min)) {  
    		stop("OpenVA message:No starttime found, try another")  
    	}	 
  	}
  	if (is.null(endtime)) {   
    	query=sprintf("SELECT max(measurement_time) FROM %s" ,my_table) 
    	response = dbGetQuery(dbcon,query)
    	endtime=response[1]
    	if (is.na(endtime$max))  { 
    		stop("OpenVA message:No endtime found, try another")
    	}
  	}



    response=getMeasurementDailyCounts(varids=variableid,oiids=oiids, starttime,endtime,dbcon)
    n = count_data(variableid,my_oi$id, starttime,endtime,dbcon)

  	# time in hours (10 sec interval) we should really read it from metadata 
  	if (n[1]==TRUE) {
  		recorded_hours = format(round(n[[2]]/360, 1));
  	} else {
  		recorded_hours = NA;
  	}
  	
  	period_hours = format(round(as.numeric(difftime(endtime, starttime, units="hour")), 1))  
	

    if (nrow(response)==0) {
    	stop(paste("OpenVA message: No data found for",my_meta$report_title,my_oi$report_title ))
    }

	return(list(period_hours=period_hours,recorded_hours=recorded_hours))
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

AddTableRow = function(my_table,calculated_values,j,dbcon,oiids_temp,starttime,endtime,merged_data,oi_report_title) {
      my_calcvalue = calculated_values[j, ]
      my_variable = my_calcvalue$oitype_property_title
      my_function = paste("calculate_", my_variable, sep = "")
      print(my_function)
	  if (my_function == "calculate_total_recorded_hours") {
	  	# calculate_total_recorded_hours requires variable to be selected
#	  if (my_function != "calculate_ship_steaming_hours") {
      			return(NULL)
      }
      
      my_table_row = NULL
      row <- tryCatch({
        result = do.call(
          my_function,
          list(
            dbcon,
            oitype = "ship",
            oiids_temp,
            starttime,
            endtime,
            merged_data
          )
        )
        
        meta = getMetadata_bytitle(dbcon, my_variable)
        if (result$data_ok) {
          #add row
          my_table_row <-
            cbind(
              calculated_value = meta$report_title,
              value = round(result$calculated_value, 1),
              unit = meta$numunit
            )
          
        } else {
          #add empty row
          my_table_row <-
            cbind(
              calculated_value = paste(meta$report_title, "[", result$err_msg, "]",sep = " "),
              value = " ",
              unit = " "
            )
        }
        my_table_row
      },
      error = function(cond) {
        #add empty row
        print("error:")
        print(cond)
        meta = getMetadata_bytitle(dbcon, my_variable)
        my_table_row <-
          cbind(
            calculated_value = paste(meta$report_title, "[", substr(cond, (nchar(cond) - 20), nchar(cond)), "]",sep = " "),
            value = NA,
            unit = NA
          )
          my_table_row
      })
      
      colnames(row) = c(paste(oi_report_title, starttime, "-", endtime),
                           "value",
                           "unit")
                           
      return(rbind(my_table, row))
}


NewTable= function(group_title,group_report_title,dbcon,oiids_temp,starttime,endtime,merged_data,mytheme,oi_report_title) {
   plot.new()
    my_table = data.frame(
      calculated_value = character(),
      value = numeric(),
      unit = character(),
      stringsAsFactors = FALSE
    )
    colnames(my_table) = c(paste(oi_report_title, starttime, "-", endtime),
                           "value",
                           "unit")
                                 
    calculated_values = getGroupMembersByGroupTitle(dbcon,group_title)                                                      
    #add row for each calculated value 
    for (j in 1:nrow(calculated_values)) {
        start_time <- Sys.time()
    	table = AddTableRow(my_table,calculated_values,j, dbcon,oiids_temp,starttime,endtime,merged_data,oi_report_title)
    	if (!is.null(table)) { 
			my_table = table
		} 
		end_time <- Sys.time()
    	print(end_time - start_time)
    }
    grid.table(my_table[, c(1:3)], theme = mytheme)
    mtext(group_report_title, side=3, line=-1, outer=F, adj=0.5, cex=1.5)
}

full_join_n_variables=function(dbcon,oi_title,property_titles, starttime, endtime) {
  
  start = format(starttime, format="%Y-%m-%d %H:%M:%S")
  end = format(endtime, format="%Y-%m-%d %H:%M:%S")
  string1 = ""
  string2 =""
  string3 =""
  
  print(property_titles)
  for (i in 1:length(property_titles)) {
    table_name = paste(tolower(oi_title),"_",property_titles[i],sep="")
    string1 = paste(string1,", t",i,".measurement_value as measurement_value_",i,sep="")
    if (i<2) {
      string2 = paste(" from ",table_name," t1 ",sep="")
    } else {
      string2 = paste(string2,"full join ",table_name," t",i," on t",i-1,".measurement_time = t",i,".measurement_time ",sep="") 
    }
    if (i<2) {
      string3 = paste("where t",i,".measurement_time > '",start,"' and t",i,".measurement_time <'",end,"' ",sep="")
    } else {
      string3 =paste(string3,"and t",i,".measurement_time > '",start,"' and t",i,".measurement_time <'",end,"' ",sep="") 
    }
       
  }

  query = paste("select t1.measurement_time ", string1,string2,string3,sep="")  				  
  response = dbGetQuery(dbcon,query)
  return(response)
  
}
 					  
####################################################################
#only one oidi

CalculatedValuesTable  = function(dbcon, oiids,varids ,starttime, endtime)
{
  #create table
  
  if (length(oiids) > 1) {
    
  } else {
    oiids_temp = paste("(", oiids, ")", sep = "")   
    my_oi = getOIs(dbcon, oiids_temp)
    oi_report_title=my_oi$report_title
  
   mytheme <- gridExtra::ttheme_default(
      core = list(fg_params = list(cex = 0.8)),
      colhead = list(fg_params = list(cex = 0.8)),
      rowhead = list(fg_params = list(cex = 0.8))
    )
   
   
   hours = time_period_hours(varids, oitype, oiids, starttime, endtime,dbcon)    
   my_table = data.frame(
      calculated_value = character(),
      value = numeric(),
      unit = character(),
      stringsAsFactors = FALSE
    )
    colnames(my_table) = c(paste(oi_report_title, starttime, "-", endtime),
                           "value",
                           "unit")
	plot.new()
    my_table_row <-
            cbind(
              calculated_value = "Total period hours",
              value = hours$period_hours,
              unit = "h"
            ) 
    colnames(my_table_row) = c(paste(oi_report_title, starttime, "-", endtime),
                           "value",
                           "unit")                     
    my_table = rbind(my_table, my_table_row)
    my_table_row <-
            cbind(
              calculated_value = "Recorded hours",
              value = hours$recorded_hours,
              unit = "h"
            )
    colnames(my_table_row) = c(paste(oi_report_title, starttime, "-", endtime),
                           "value",
                           "unit")  
    my_table = rbind(my_table, my_table_row) 
        my_table_row <-
            cbind(
              calculated_value = "Recorded vs. total period hours",
              value = round((as.numeric(hours$recorded_hours)/as.numeric(hours$period_hours))*100,1),
              unit = "%"
            ) 
    colnames(my_table_row) = c(paste(oi_report_title, starttime, "-", endtime),
                           "value",
                           "unit")                     
    my_table = rbind(my_table, my_table_row)
    
   grid.table(my_table[, c(1:3)], theme = mytheme)       
	mtext("REPORT", side=3, line=-2, outer=F, adj=0.5, cex=2) 
 
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
