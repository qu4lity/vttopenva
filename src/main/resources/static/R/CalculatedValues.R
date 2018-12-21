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

#########################################################################################
#function for percentage / average visualizations 
#launches a calculated value function for the given variableid, shows the result visualization, 
#either percentage or average visualization, depending on the variable unit (% or not %)
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

source(paste(scriptPath, "common.R", sep="/"))

connectDB <- function() {
	psql <- dbDriver("PostgreSQL")
	dbcon <- dbConnect(psql, host="<host>", port=<port>, dbname="<dbname>",user="<user>",pass="<password>")
	return(dbcon)
}




deploy_calculated_value=function(variableid,oitype,oiids, starttime=NULL,endtime=NULL,dbcon,imagetype)
{
  on.exit(dbDisconnect(dbcon))
  n=0
  calculated_value=NA
  sd_value=NA
  min_value=NA
  max_value=NA
#launch calculation
  my_meta=getMetadata(dbcon,variableid)
  #print(paste("my_meta",my_meta))
  my_variable=my_meta$title
  #print(my_variable)
  my_function=paste("calculate_",my_variable,sep="")
 #print(my_function)
  result=do.call(my_function,list(dbcon,oitype,oiids,starttime,endtime))
#print(result)
#title preparation
  oiids_temp=paste("(",oiids,")",sep="")
  my_ois=getOIs(dbcon,oiids_temp) 
  oi_title=paste(my_ois[,c("report_title")],collapse = ',')
#any results? 
  #print(result)
  n=result$n
  if (n==0) {stop(paste("OpenVA warning: No data available",my_variable,oi_title))}
   if (n==1) {stop(paste("OpenVA warning: Not enough data, try longer time period for ",my_variable,oi_title))}
  calculated_value=result$calculated_value
  if (is.na(calculated_value)) {stop(paste("OpenVA warning:No result available",my_variable,oi_title))}
  starttime=result$starttime
  endtime=result$endtime
#plot visualization 
  if (result$visutype=="%")
#percentage visualisation
  { 
    min_value=0
    max_value=100
    barplot(as.matrix(c(calculated_value,100-calculated_value)), col=c("darkblue","white"),
    main=paste(variable_title=my_meta$report_title,"\n",oi_title,"\nn=",n,"\n",starttime," - ",endtime), cex.main=0.9,
    ylab=my_meta$numunit,xlab=paste(my_meta$report_title,"=", round(calculated_value,2),my_meta$numunit))
  }  else if (result$visutype=="avg"){
    
#avg visualization 
    sd_value=result$sd_value
    min_value=result$min_value
    max_value=result$max_value
   # lower_limit=my_meta$lowerlimit
#    print(paste("loverlimit",lower_limit))
 #   if(is.null(lower_limit)) {lower_limit=min_value}
    lower_limit=min_value
    #upper_limit=my_meta$upperlimit
  #  print(paste("upperlimit",upper_limit))
   # if(is.null(upper_limit)) {upper_limit=max_value}
    upper_limit=max_value
    
    
    
    barplot(as.matrix(c(lower_limit,upper_limit-lower_limit,(upper_limit+0.1* upper_limit)-upper_limit)), 
            col=c("white","grey","white"),
            main=paste(variable_title=my_meta$report_title,"\n",oi_title,"\nn=",n,"\n",starttime," - ",endtime), cex.main=0.9,
            ylab=my_meta$numunit,xlab=paste(my_meta$report_title,"=", round(calculated_value,2),my_meta$numunit),cex.axis=0.9,
            sub=paste("min=",round(min_value,2),"max=",round(max_value,2),"sd=",round(sd_value,2)), cex.sub=0.9
    )
  
  abline(h=calculated_value,col="red",lwd=2)
  abline(h=min_value,col="black",lwd=1)
  abline(h=max_value,col="black",lwd=1)
  legend("topright",  
         c("mean","min,max"), lty=c(1,1), col=c("red","black"), horiz=FALSE, cex=0.6)
  } else if (result$visutype=="sum")
  {
  #sum visualization 

     midpoint= barplot(calculated_value, col=c("darkblue"),
      main=paste(variable_title=my_meta$report_title,"\n",oi_title,"\nn=",n,"\n",starttime," - ",endtime), cex.main=0.9,
      ylab=my_meta$numunit,xlab="Total sum of the given time period")
      #xlab=paste(my_meta$report_title,"=", round(calculated_value,2),my_meta$numunit))
       text(midpoint, calculated_value/2, paste(round(calculated_value,2),my_meta$numunit),col="white",cex=1.5)
      

  }
  main_title = paste(variable_title=my_meta$report_title,"\n",oi_title,"\nn=",n,"\n",starttime," - ",endtime)
  y_title = my_meta$numunit
  x_title =paste(my_meta$report_title,"=", round(calculated_value,2),my_meta$numunit)

  return_list <- list(my_variable,calculated_value,  n,  sd_value, min_value, max_value, main_title, x_title ,y_title,imagetype)
  names(return_list) <-c("variable","calculated_value","n","sd","min","max","main_title", "x_title", "y_title","imagetype")
  return(return_list)
  
} 



#########################################################################################
#Calculation functions for calculated values
#########################################################################################
#__________________________________________________
#calculated_value 5 
#ship_steaming_distance_percentage
# calculate value between the given time period

#testing
#calculate_ship_steaming_distance_percentage(db=con,oiids,starttime=starttime,endtime=endtime)

#function
calculate_ship_steaming_distance_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{   
    n=0
    calculated_value=NA
    ship_steaming_distance=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"ship_steaming_distance")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
    if (nrow (ship_steaming_distance) == 0 ) stop("OpenVA warning: no data for calculation")
    ship_steaming_distance=unique(ship_steaming_distance)
    ship_steaming_distance=ship_steaming_distance[order(ship_steaming_distance$measurement_time),]
    #head(ship_steaming_distance)
    
    sailing_distance=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"ship_sailing_distance")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
     if (nrow (sailing_distance) == 0 ) stop("OpenVA warning: no data for calculation")
    sailing_distance=unique(sailing_distance)
    #head(sailing_distance)
    
    ship_steaming_sailing_distance=merge(ship_steaming_distance,sailing_distance,by=c("oi_id","measurement_time"))
    n=nrow(ship_steaming_sailing_distance)
    if (n==0) stop("OpenVA warning: no data for calculation")
      
    ship_steaming_sailing_distance=ship_steaming_sailing_distance[,c("measurement_time","measurement_value.x","measurement_value.y")]
    colnames(ship_steaming_sailing_distance)=c("measurement_time","steaming_distance","sailing_distance")
    head(ship_steaming_sailing_distance)
 
      if (sum(ship_steaming_sailing_distance$sailing_distance)>0) {
        calculated_value=
          (sum(ship_steaming_sailing_distance$steaming_distance)/sum(ship_steaming_sailing_distance$sailing_distance))*100
          }
    
    starttime=min(ship_steaming_sailing_distance$measurement_time)
    endtime=max(ship_steaming_sailing_distance$measurement_time)
    result=list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,visutype="%")
    return(result)
}

# calculated value 6 
# ship_steaming_fuel_percentage
# calculate value between the given time period

# testing 
#calculate_ship_steaming_fuel_percentage(db=con,oiids,starttime=starttime,endtime=endtime)

# function
calculate_ship_steaming_fuel_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{  
  n=0
  calculated_value=NA
  ship_steaming=
  getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"ship_steaming")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  if (nrow(ship_steaming)==0) {stop("OpenVA warning: no data for calculation")}
  ship_steaming=unique(ship_steaming)
  #head(ship_steaming)
  #nrow(ship_steaming)
  
  fueloil_consumption_total=
    getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"fueloil_consumption_total")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  if (nrow(fueloil_consumption_total)==0) {stop("OpenVA warning: no data for calculation")}
  
  fueloil_consumption_total=unique(fueloil_consumption_total)
  #head(fueloil_consumption_total)
  #nrow(fueloil_consumption_total)
  
  ship_steaming_fuel=merge(ship_steaming,fueloil_consumption_total,by=c("oi_id","measurement_time"))
  ship_steaming_fuel=ship_steaming_fuel[,c("measurement_time","measurement_value.x","measurement_value.y")]
  colnames(ship_steaming_fuel)=c("measurement_time","ship_steaming","fueloil_consumption_total")

  ship_steaming_fuel$steaming_consumption=ship_steaming_fuel$fueloil_consumption_total*ship_steaming_fuel$ship_steaming
  n=nrow(ship_steaming_fuel)
  if (n==0) {stop("OpenVA warning: no data for calculation")}
  if (sum(ship_steaming_fuel$fueloil_consumption_total)==0) {stop("OpenVA warning: no data for calculation")} 
    calculated_value=(sum(ship_steaming_fuel$steaming_consumption)/sum(ship_steaming_fuel$fueloil_consumption_total))*100 

  {starttime=min(ship_steaming_fuel$measurement_time)}
  {endtime=max(ship_steaming_fuel$measurement_time)}
  result=list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,visutype="%")
  return(result)
 }

#__________________________________________________
#calculated_value 9 
#ship_maneuvering_time_percentage
#percentage of time of the total time analyzed that ship has been maneuvering

#testing
#calculate_ship_maneuvering_time_percentage(db=con,oiids,starttime=starttime,endtime=endtime)

# function
calculate_ship_maneuvering_time_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{
  n=0
  calculated_value=NA
 #ship maneuvering   
  ship_maneuvering_hours=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"ship_maneuvering_hours")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  #head(ship_maneuvering_hours)
  n=nrow(ship_maneuvering_hours)
 if (n==0) {stop("OpenVA warning: no data for calculation")}

    ship_maneuvering_time_sum=sum(ship_maneuvering_hours$measurement_value)
    #ship_total_time 
    total_time_sum=nrow(ship_maneuvering_hours)*10/3600
    if (total_time_sum>0) {calculated_value=(ship_maneuvering_time_sum/total_time_sum)*100
    } 
 

 {starttime=min(ship_maneuvering_hours$measurement_time)}
  {endtime=max(ship_maneuvering_hours$measurement_time)}
  result=list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,visutype="%")
  return(result)
}

#__________________________________________________
#calculated_value 11 
#ship_fueloil_consumption_nmile_avg
#Average value of fuel consumed per nautical mile sailed
#Using values on steaming condition 

#testing
#calculate_ship_fueloil_consumption_nmile_avg(db=con,oiids=oiids,starttime=starttime,endtime=endtime)

#function
calculate_ship_fueloil_consumption_nmile_avg=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL){
  n=0
  calculated_value=NA
  sd_value=NA
  min_value=NA
  max_value=NA
#get fo consumption on steaming
 #get steaming distance
  ship_steaming_distance=
  getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"ship_steaming_distance")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)[,c("oi_id","measurement_time","measurement_value")]
  #head(ship_steaming_distance)
  if (nrow(ship_steaming_distance)==0) stop("OpenVA warning: no data for calculation")
  
  
#get fo consumption on steaming
  mainengine_fueloil_consumption_steaming=
  getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"mainengine_fueloil_consumption_steaming")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)[,c("oi_id","measurement_time","measurement_value")]
  # head(fueloil_consumption_total_steaming)
  if (nrow(mainengine_fueloil_consumption_steaming)==0) stop("OpenVA warning: no data for calculation")
  
#calculate fueloil consumption per nautical mile
  ship_fueloil_consumption_nmile=merge(mainengine_fueloil_consumption_steaming,ship_steaming_distance,by=c("oi_id","measurement_time"))
  #head(ship_fueloil_consumption_nmile)
  n=nrow(ship_fueloil_consumption_nmile)
  if (n==0) stop("OpenVA warning: no data for calculation")
  
    colnames(ship_fueloil_consumption_nmile)=c("oi_id","measurement_time","mainengine_fueloil_consumption_steaming", "ship_steaming_distance")
    ship_fueloil_consumption_nmile=ship_fueloil_consumption_nmile[ship_fueloil_consumption_nmile$ship_steaming_distance>0,]
    ship_fueloil_consumption_nmile$val=ship_fueloil_consumption_nmile$mainengine_fueloil_consumption_steaming/ship_fueloil_consumption_nmile$ship_steaming_distance
    #plot(ship_fueloil_consumption_nmile$measurement_time,ship_fueloil_consumption_nmile$val)
    #get mean
    calculated_value=mean(ship_fueloil_consumption_nmile$val,na.rm=TRUE)
    sd_value=sd(ship_fueloil_consumption_nmile$val)
    min_value=min(ship_fueloil_consumption_nmile$val)
    max_value=max(ship_fueloil_consumption_nmile$val)
  
  if (is.null(starttime)) {starttime=min(ship_fueloil_consumption_nmile$measurement_time)}
  if (is.null(endtime)) {endtime=max(ship_fueloil_consumption_nmile$measurement_time)}
  return(list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,sd_value=sd_value,min_value=min_value,max_value=max_value,visutype="avg"))
}

#__________________________________________________
#calculated_value 12 
#ship_velocity_avg
#ship's average velocity
#on steaming condition

#testing
#calculate_ship_velocity_avg(db,oiids,starttime=starttime,endtime=endtime)

#function
calculate_ship_velocity_avg=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL){
  n=0
  calculated_value=NA
  sd_value=NA
  min_value=NA
  max_value=NA
#get speed on steaming
  ship_speed_actual_steaming=
  getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"ship_speed_actual")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)[,c("oi_id","measurement_time","measurement_value")]
  n=nrow(ship_speed_actual_steaming)
  if(n==0) stop("OpenVA warning: no data for calculation")
  
    calculated_value=mean(ship_speed_actual_steaming$measurement_value,na.rm=TRUE )
    sd_value=sd(ship_speed_actual_steaming$measurement_value)
    min_value=min(ship_speed_actual_steaming$measurement_value)
    max_value=max(ship_speed_actual_steaming$measurement_value)
  
  if (is.null(starttime)) {starttime=min(ship_speed_actual_steaming$measurement_time)}
  if (is.null(endtime)) {endtime=max(ship_speed_actual_steaming$measurement_time)}
  return(list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,sd_value=sd_value,min_value=min_value,max_value=max_value,visutype="avg"))
}


# __________________________________________________
#calculated_value 15
#mainengine_runningtime_percentage
# 
#testing
#calculate_mainengine_runningtime_percentage(db=con,oiids,starttime=starttime,endtime=endtime)

#function
calculate_mainengine_runningtime_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{
  n=0
  calculated_value=NA
  #get main engine running
  mainengine_running=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"main_engine_running")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  n=nrow(mainengine_running)
  if (n==0) stop("OpenVA warning: no data for calculation")
   
    me_running_count= nrow(mainengine_running[mainengine_running$measurement_value==1,])
    calculated_value=(me_running_count/n)*100
  
  {starttime=min(mainengine_running$measurement_time)}
  {endtime=max(mainengine_running$measurement_time)}
  result=list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,visutype="%")
  return(result)
  
}

#__________________________________________________
#calculated_value 16 
#mainengine_running_steaming_percentage

#testing
#calculate_mainengine_running_steaming_percentage(db=con,oitype,oiids,starttime=starttime,endtime=endtime)

#function
calculate_mainengine_running_steaming_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ n=0
  calculated_value=NA
#get ship steaming
  ship_steaming=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"ship_steaming")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  #nrow(ship_steaming)
  if (nrow(ship_steaming)==0) stop("OpenVA warning: no data for calculation")
# get mainengine_running
  mainengine_running=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"main_engine_running")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  #nrow(mainengine_running)
  if (nrow(mainengine_running)==0) stop("OpenVA warning: no data for calculation")
  steaming_running=merge(ship_steaming,mainengine_running,by=c("oi_id","measurement_time"))
  n=nrow(steaming_running)
  #head(steaming_running)
  if (n==0) stop("OpenVA warning: no data for calculation") 
 
    steaming_running=steaming_running[,c("measurement_time","measurement_value.x","measurement_value.y")]
    colnames(steaming_running)=c("measurement_time","steaming","running")
    steaming_running_count=nrow(steaming_running[steaming_running$steaming==1 & steaming_running$running==1, ])
    mainengine_running_count=nrow(steaming_running[steaming_running$running, ])
    calculated_value=(steaming_running_count/mainengine_running_count)*100
  
  {starttime=min(steaming_running$measurement_time)}
  {endtime=max(steaming_running$measurement_time)}
  result=list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,visutype="%")
  return(result)
}


#__________________________________________________
#calculated_value 18 
#mainengine_fueloil_consumption_avg

#testing
#calculate_mainengine_fueloil_consumption_avg(db=con,oitype,oiids,starttime=starttime,endtime=endtime)

#function
calculate_mainengine_fueloil_consumption_avg=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{
  n=0
  calculated_value=NA
  sd_value=NA
  min_value=NA
  max_value=NA
  
 #get running
  main_engine_running=
  getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"main_engine_running")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)[,c("oi_id","measurement_time","measurement_value")]
  if (nrow(main_engine_running)==0) stop("OpenVA warning: no data for calculation")
  #take just running events
  main_engine_running=main_engine_running[main_engine_running$measurement_value>0,]
  #print(head(main_engine_running))
#get main engine fuel oil
  main_engine_fuel_oil=
  getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"fueloil_consumption_main_engine")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)[,c("oi_id","measurement_time","measurement_value")]
  if (nrow(main_engine_fuel_oil)==0) stop("OpenVA warning: no data for calculation")
  #print(head(main_engine_fuel_oil))
  #nrow( main_engine_fuel_oil)
  
#calculate consumption per hour
  main_engine_fuel_oil_running=merge(main_engine_fuel_oil,main_engine_running,by= c("measurement_time","oi_id"))
  if (nrow(main_engine_fuel_oil)==0) stop("OpenVA warning: no data for calculation")
  #head(main_engine_fuel_oil_running)
  colnames(main_engine_fuel_oil_running)=c("measurement_time","oi_id", "fuel_oil","running")
  main_engine_fuel_oil_running$running_time=main_engine_fuel_oil_running$running/360
  main_engine_fuel_oil_running$value=main_engine_fuel_oil_running$fuel_oil/main_engine_fuel_oil_running$running_time
  #print(head(main_engine_fuel_oil_running))
 
#final value
  calculated_value=mean(main_engine_fuel_oil_running$value ,na.rm=TRUE)
  sd_value=sd(main_engine_fuel_oil_running$value,na.rm=TRUE)
  min_value=min(main_engine_fuel_oil_running$value)
  max_value=max(main_engine_fuel_oil_running$value)
  n=nrow(main_engine_fuel_oil_running)
  
  if (is.null(starttime)) {starttime=min(main_engine_running_fueloil_consumption$measurement_time)}
  if (is.null(endtime)) {endtime=max(main_engine_running_fueloil_consumption$measurement_time)}
  return_list=list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,sd_value=sd_value,min_value=min_value,max_value=max_value,visutype="avg")
  #print(return_list)
  return(return_list)
}

#__________________________________________________
#calculated_value 19 
#mainengine_fueloil_consumption_percentage
#wrapper function, uses general purpose calculate_percentage function

#testing  
#calculate_mainengine_fueloil_consumption_percentage(db,oitype,oiids,starttime=starttime,endtime=endtime)

#function
calculate_mainengine_fueloil_consumption_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{
  return(calculate_percentage(dbcon,oitype,oiids,variable_part="ME_FO_consumption",variable_all= "fueloil_consumption_total"  ,starttime=starttime,endtime=endtime))
}

#__________________________________________________
#calculated_value 20 
# mainengine_fueloil_steaming_percentage
# wrapper function, uses general purpose calculate_percentage function

# testing
#calculate_mainengine_fueloil_steaming_percentage(db,oitype,oiids,starttime,endtime)

#function
calculate_mainengine_fueloil_steaming_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{
  result=calculate_percentage(dbcon, oitype,oiids,variable_part="mainengine_fueloil_consumption_steaming",
                              variable_all= "fueloil_consumption_total"  ,starttime=starttime,endtime=endtime)
  print(paste("RESULT:",result))
  return(result)
}

#__________________________________________________
#calculated_value 22 
#mainengine_running_maneuvering_percentage

#testing
#calculate_mainengine_running_maneuvering_percentage(db=con,oitype,oiids,starttime=starttime,endtime=endtime)

#function
calculate_mainengine_running_maneuvering_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{   n=0
    calculated_value=NA
#get maneuvering
  ship_maneuvering=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"ship_maneuvering")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  if (nrow(ship_maneuvering)==0) {stop("OpenVA warning: no data for calculation")}
  #nrow(ship_maneuvering)
#get main engine running
  mainengine_running=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"main_engine_running")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  #nrow(mainengine_running)
 if (nrow(mainengine_running)==0){stop("OpenVA warning: no data for calculation")}
  maneuvering_running=merge(ship_maneuvering,mainengine_running,by=c("oi_id","measurement_time"))
  n=nrow(maneuvering_running)
#  head(maneuvering_running)
  if (n==0) stop("OpenVA warning: no data for calculation")
  
    maneuvering_running=maneuvering_running[,c("measurement_time","measurement_value.x","measurement_value.y")]
    colnames(maneuvering_running)=c("measurement_time","maneuvering","running")
    maneuvering_running_count=nrow(maneuvering_running[maneuvering_running$maneuvering==1 & maneuvering_running$running==1, ])
    mainengine_running_count=nrow(maneuvering_running[maneuvering_running$running==1, ])
    calculated_value=(maneuvering_running_count/mainengine_running_count)*100
 
  {starttime=min(maneuvering_running$measurement_time)}
  {endtime=max(maneuvering_running$measurement_time)}
  result=list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,visutype="%")
  return(result)
}


#__________________________________________________
#calculated_value 24
#auxengines_fueloil_consumption_percentage
#wrapper function, uses general purpose calculate_percentage function

#testing
#calculate_auxengines_fueloil_consumption_percentage(db,oitype,oiids,starttime=starttime,endtime=endtime)

#function
calculate_auxengines_fueloil_consumption_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{
  return(calculate_percentage(dbcon, oitype,oiids,variable_part="AE_FO_consumption",
                              variable_all= "fueloil_consumption_total"  ,starttime=starttime,endtime=endtime))
  
}

#__________________________________________________
#calculated_value 25 
#auxengines_load_percentage, individual aux engines
#Wrapper functions for each aux engine + general purpose function for calculation

#wrapper calculate_auxengine1_load_percentage
#testing
#calculate_auxengine1_load_percentage(db=con,oitype,oiids='1',starttime=starttime,endtime=endtime)
#NOT IN USE; MOVED TO INDICATORS
#function  NOT IN USE
calculate_auxengine1_load_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_load_percentage(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#wrapper function for auxengine 2

#testing
#calculate_auxengine2_load_percentage(db=con,oiids='1',starttime=starttime,endtime=endtime)

#function NOT IN USE
calculate_auxengine2_load_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_load_percentage(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#wrapper function for auxengine 3

#testing
#calculate_auxengine3_load_percentage(db=con,oitype,oiids='1',starttime=NULL,endtime=NULL)

#function NOT IN USE
calculate_auxengine3_load_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_load_percentage(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#wrapper function for auxengine 4

#testing
#calculate_auxengine4_load_percentage(db=con,oiids='1',starttime=NULL,endtime=NULL)

#function NOT IN USE
calculate_auxengine4_load_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_load_percentage(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#wrapper function for auxengine 5

#testing
#calculate_auxengine5_load_percentage(db=con,oitype,oiids='1',starttime=starttime,endtime=endtime)

#function NOT IN USE
calculate_auxengine5_load_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  #print(paste("my_function",my_function))
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #print(ae_number)
  #launch calculation
  result=calculate_auxengine_load_percentage(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#calculation function for auxengine_load_percentage

#testing
#calculate_auxengine_load_percentage(db=con,oitype,oiids='1', auxengine=1,starttime=starttime,endtime=endtime)

#function NOT IN USE
calculate_auxengine_load_percentage=function(dbcon,oitype,oiids, auxengine,starttime=NULL,endtime=NULL)
{  
    n=0
    calculated_value=NA
    my_var=paste("DG_",auxengine,"_power",sep="")
    DG_power=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,my_var)$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
    if (nrow(DG_power)==0) stop("OpenVA warning: no data for calculation")
    DG_power=DG_power[,c("oi_id","measurement_value","measurement_time")]

#get condition
    my_condition=paste("DG_",auxengine,"_condition",sep="")
    DG_condition=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,my_condition)$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
    if (nrow(DG_condition)==0) stop("OpenVA warning: no data for calculation")
    DG_condition=DG_condition[,c("oi_id","measurement_value","measurement_time")]
#nrow(DG_condition)
#head(DG_condition)
#hist(DG_condition$measurement_value)
#plot(DG_condition$measurement_time,DG_condition$measurement_value)
    DG_condition_on=DG_condition[DG_condition$measurement_value==1,]
    if(nrow(DG_condition_on)==0) stop("OpenVA warning: no data for calculation")

#merge
    DG_power_condition=merge(DG_power, DG_condition_on,by=c("measurement_time","oi_id"))
    if (nrow(DG_power_condition)==0) stop("OpenVA warning: no data for calculation")

    colnames(DG_power_condition)=c("measurement_time","oi_id","power","condition")
    n=nrow(DG_power_condition)
#sum((power_condition$load)/(n*960)) * 100

 
  if (any(c(1:4) == auxengine))
  {DG_power_condition$value=(DG_power_condition$power/960)*100

  } else {
    DG_power_condition$value=(DG_power_condition$power/768)*100
  }

    calculated_value=mean(DG_power_condition$value)
    if (is.null(starttime)) {starttime=min(DG_power_condition$measurement_time)}
    if (is.null(endtime)) {endtime=max(DG_power_condition$measurement_time)}
    result=list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,visutype="%")
    return(result)
}

#____________________
#calculation function for auxengines_load_percentage
#note:all engines 
#testing

#my_result=calculate_auxengines_load_percentage(db=con,oitype,oiids='1',starttime=NULL,endtime=NULL)

calculate_auxengines_load_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{   n=0
    calculated_value=NA
    my_var="DG_1_power"
    total_DG_power=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,my_var)$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
    if (nrow(total_DG_power)==0) stop("OpenVA varning: no data in the given time period")
#head(total_DG_power)
    total_DG_power=total_DG_power[,c("oi_id","measurement_value","measurement_time")]
    for (i in 2:5)
    { new_title=paste("DG_",i,"_power",sep="") 
        measu=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,new_title)$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
        if (nrow(total_DG_power)==0) stop("OpenVA varning: no data in the given time period")
        #head(total_DG_power)
        total_DG_power=merge(total_DG_power,measu[,c("oi_id","measurement_time","measurement_value")],by=c("oi_id","measurement_time"))
    }   
    colnames(total_DG_power)=c("oi_id","measurement_time","measurement_value.1",
                                            "measurement_value.2","measurement_value.3",
                                            "measurement_value.4","measurement_value.5")
    #head(total_DG_power)
    total_DG_power$DG_value=total_DG_power$measurement_value.1/960+
    total_DG_power$measurement_value.2/960+total_DG_power$measurement_value.3/960+
    total_DG_power$measurement_value.4/960+total_DG_power$measurement_value.5/768

    n=nrow(total_DG_power)
    if (n==0) stop("OpenVA warning: no data for calculation")
    calculated_value= mean(total_DG_power$DG_value)*100
    if (is.null(starttime)) {starttime=min(total_DG_power$measurement_time)}
    if (is.null(endtime)) {endtime=max(total_DG_power$measurement_time)}

    result=list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,visutype="%")
    return(result)
}
#__________________________________________________
#calculated_value 30 
#auxiliary_power_of_load_percentage
#testing
#calculate_auxiliary_power_of_load_percentage(db=con,oitype,oiids,starttime=starttime,endtime=endtime)

#function
calculate_auxiliary_power_of_load_percentage=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{
  n=0
  calculated_value=NA
  total_available_auxiliary_power=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"DG_1_condition")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  if (nrow(total_available_auxiliary_power)==0) stop("OpenVA warning: no data for calculation")
  total_available_auxiliary_power=total_available_auxiliary_power[,c("oi_id","measurement_value","measurement_time")]
  for (i in 2:5)
  { new_title=paste("DG_",i,"_condition",sep="") 
      measu=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,new_title)$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
      if(nrow(total_available_auxiliary_power)==0) stop("OpenVA warning: no data for calculation")
      total_available_auxiliary_power=merge(total_available_auxiliary_power,measu[,c("oi_id","measurement_time","measurement_value")],by=c("oi_id","measurement_time"))
  }   
  colnames(total_available_auxiliary_power)=c("oi_id","measurement_time","measurement_value.1",
                                              "measurement_value.2","measurement_value.3",
                                              "measurement_value.4","measurement_value.5")
  #head(total_available_auxiliary_power)
  total_available_auxiliary_power$measurement_value=total_available_auxiliary_power$measurement_value.1*960+
  total_available_auxiliary_power$measurement_value.2*960+total_available_auxiliary_power$measurement_value.3*960+
  total_available_auxiliary_power$measurement_value.4*960+total_available_auxiliary_power$measurement_value.5*768

  total_auxiliary_power=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,"auxiliary_power_total")$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  n=nrow(total_auxiliary_power)
  if (n==0) stop("OpenVA warning: no data for calculation")
 
    if ( sum(total_available_auxiliary_power$measurement_value) >0)
    { calculated_value=
      auxiliary_power_of_load_percentage=sum(total_auxiliary_power$measurement_value)/sum(total_available_auxiliary_power$measurement_value)*100
    }
 
  if (is.null(starttime)) {starttime=min(total_auxiliary_power$measurement_time)}
  if (is.null(endtime)) {endtime=max(total_auxiliary_power$measurement_time)}
  result=list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,visutype="%")
  return(result)
}
#


#__________________________________________________
#calculated_value 34 
#auxengine_power_average
#Wrapper functions for each aux engine + general purpose function for auxengine power calculation

#wrapper calculate_auxengine1_power_average

#testing
#calculate_auxengine1_power_average(dbcon,oitype,oiids,starttime=starttime,endtime=endtime)

#function
calculate_auxengine1_power_average=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_power_average(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#wrapper calculate_auxengine2_power_average

#testing
#calculate_auxengine2_power_average(db=con,oiids,starttime=starttime,endtime=endtime)

#function
calculate_auxengine2_power_average=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_power_average(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#wrapper calculate_auxengine3_power_average

#testing
#calculate_auxengine3_power_average(db=con,oiids,starttime=starttime,endtime=endtime)

#function
calculate_auxengine3_power_average=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_power_average(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}  

#wrapper calculate_auxengine4_power_average

#testing
#calculate_auxengine4_power_average(db=con,oiids,starttime=starttime,endtime=endtime)

#function
calculate_auxengine4_power_average=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_power_average(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#wrapper calculate_auxengine5_power_average

#testing
#calculate_auxengine5_power_average(db=con,oiids,starttime=starttime,endtime=endtime)

#function
calculate_auxengine5_power_average=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_power_average(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#general purpose function for auxengine_power_average

#testing
#calculate_auxengine_power_average(db,oiids,auxengine=5,starttime=NULL,endtime=NULL)

calculate_auxengine_power_average=function(dbcon,oitype,oiids,auxengine,starttime=starttime,endtime=endtime)
{ n=0
  calculated_value=NA
  sd_value=NA
  min_value=NA
  max_value=NA

  total_variable=paste("DG_",auxengine,"_power",sep="") 
#get auxengine_power_total
  auxengine_power_total=
  getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,total_variable)$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)[,c("oi_id","measurement_time","measurement_value")]
  if (nrow(auxengine_power_total)==0) stop("OpenVA warning: no data for calculation, auxengine_power_total")

#get engine on
  aux_variable=paste("DG_",auxengine,"_condition",sep="") 
  auxengine_condition=
  getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,aux_variable)$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)[,c("oi_id","measurement_time","measurement_value")]
  if (nrow(auxengine_condition)==0) stop("OpenVA warning: no data for calculation, auxengine_condition")
  auxengine_power_merged=merge(auxengine_power_total,auxengine_condition,by=c("oi_id","measurement_time"))
  if (nrow(auxengine_power_merged)==0) stop("OpenVA warning: no data for calculation, auxengine_power_merged")
  colnames(auxengine_power_merged)=c("oi_id",    "measurement_time", "power_total","condition")
  engine_on=auxengine_power_merged[auxengine_power_merged$condition==1,]
  n=nrow(engine_on)
  if (n==0) stop("OpenVA warning: no data for calculation,n")
   
    calculated_value=mean(engine_on[,"power_total"],na.rm=TRUE)
    sd_value=sd(engine_on[,"power_total"])
    min_value=min(engine_on[,"power_total"])
    max_value=max(engine_on[,"power_total"])
 
  if (is.null(starttime)) {starttime=min(auxengine_power_merged$measurement_time)}
  if (is.null(endtime)) {endtime=max(auxengine_power_merged$measurement_time)}
  return(list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,sd_value=sd_value,min_value=min_value,max_value=max_value,visutype="avg"))
  
}

#__________________________________________________
#calculated_value 35 
#auxengines_load_average
#huom! nämä on prosentteja nimestä huolimatta!!
#Wrapper functions for each aux engine + general purpose function for calculation

#wrapper calculate_auxengine1_load_average
#testing
#calculate_auxengine1_load_average(db=con,oiids,starttime=starttime,endtime=endtime)

#function 
calculate_auxengine1_load_average=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_load_average(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#wrapper function for auxengine 2

#testing
#calculate_auxengine2_load_average(db=con,oiids,starttime=starttime,endtime=endtime)

#function
calculate_auxengine2_load_average=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_load_average(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#wrapper function for auxengine 3

#testing
#calculate_auxengine3_load_average(db=con,oiids,starttime=starttime,endtime=endtime)

#function
calculate_auxengine3_load_average=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_load_average(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#wrapper function for auxengine 4

#testing
#calculate_auxengine4_load_average(db=con,oitype,oiids,starttime=starttime,endtime=endtime)

#function
calculate_auxengine4_load_average=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  #launch calculation
  result=calculate_auxengine_load_average(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#wrapper function for auxengine 5

#testing
#calculate_auxengine5_load_average(db=con,oitype,oiids,starttime=starttime,endtime=endtime)

#function 
calculate_auxengine5_load_average=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{ 
  #identify auxengine number
  my_function=(match.call()[[1]])
  #print(paste("my_function",my_function))
  ae_number=unique(as.numeric(unlist(strsplit(gsub("[^0-9]", "", (my_function)), ""))))
  print(ae_number)
  #launch calculation
  result=calculate_auxengine_load_average(dbcon,oitype,oiids,auxengine=ae_number,starttime=starttime,endtime=endtime)
  return(result)
}

#calculation function for auxengines_load_average

#testing
#calculate_auxengines_load_average(db=con,oitype,oiids, auxengine=1,starttime=starttime,endtime=endtime)

#function
calculate_auxengine_load_average=function(dbcon,oitype,oiids, auxengine,starttime=NULL,endtime=NULL)
{ 

n=0
  calculated_value=NA
  sd_value=NA
  min_value=NA
  max_value=NA
  return_values= calculate_auxengine_power_average(dbcon,oitype,oiids, auxengine=auxengine,starttime=starttime,endtime=endtime)
  #calculate 
  n=return_values[[1]]

  if (n==0) stop("OpenVA warning: no data for calculation")
  
    power_average=return_values[[2]]
    starttime=return_values[[3]]
    endtime=return_values[[4]]
    pover_sd=return_values[[5]]
    pover_min=return_values[[6]]
    pover_max=return_values[[7]]
    if (any(c(1:4) == auxengine))
    { calculated_value=(power_average/960)*100
      sd_value=(pover_sd/960)*100
      min_value=(pover_min/960)*100
      max_value=(pover_max/960)*100
    } else {
      calculated_value=(power_average/768)*100
      sd_value=(pover_sd/768)*100
      min_value=(pover_min/768)*100
      max_value=(pover_max/768)*100
    }
  return(list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,sd_value=sd_value,min_value=min_value,max_value=max_value,visutype="avg"))
}

#calculation function for auxengines_load_average,all  engines
#huom! tämä on prosentti nimestä huolimatta!!
#calculate_auxengines_load_average(db=con,oiids='1',starttime=NULL,endtime=NULL)
calculate_auxengines_load_average=function(dbcon,oitype,oiids,starttime=NULL,endtime=NULL)
{
  n=0
  calculated_value=NA
 
  total_load_average.names=c("1","2","3","4","5")
  total_load_average <- sapply(total_load_average.names,function(x) 0)
  for (auxengine in 1:5)
    { 
    measu=calculate_auxengine_power_average(dbcon,oitype,oiids, auxengine,starttime=starttime,endtime=endtime)
 
      total_load_average[auxengine]=measu[[2]]
      n=n+measu[[1]]
    }  

  total_load_average[1]=(total_load_average[1]/960)*100
  
  total_load_average[2]=(total_load_average[2]/960)*100
  total_load_average[3]=(total_load_average[3]/960)*100
  total_load_average[4]=(total_load_average[4]/960)*100
  total_load_average[5]=(total_load_average[5]/768)*100
  calculated_value=mean(total_load_average)

    result=list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,visutype="%")
return(result)
}

#__________________________________________________________________
#general purpose function for percentance calculation
#
#Testing
#calculate_percentage(db=con,oiids,variable_part="ME_FO_consumption",variable_all= "fueloil_consumption_total"  ,starttime=starttime,endtime=endtime)

calculate_percentage=function(dbcon,oitype,oiids,variable_part,variable_all,starttime=NULL,endtime=NULL)
{ n=0
  calculated_value=NA

  variable_part_value=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,variable_part)$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  #head(variable_part_value)
  if (nrow(variable_part_value)==0) stop("OpenVA warning: no data for calculation")
  
  variable_all_value=getVariableValues_partition(dbcon,variableid=getMetadata_bytitle(dbcon,variable_all)$id, oiids,oitype=oitype,starttime=starttime,endtime=endtime,TRUE)
  #head(variable_all_value)
  if (nrow(variable_all_value)==0) stop("OpenVA warning: no data for calculation")
  n=min(nrow(variable_all_value),nrow(variable_part_value))
  if (n==0) stop("OpenVA warning: no data for calculation")
  n=max(nrow(variable_all_value),nrow(variable_part_value))
    variable_part_sum=sum(variable_part_value$measurement_value)
    #print(variable_part_sum)
    variable_all_sum=sum( variable_all_value$measurement_value)
    #print(variable_all_sum)
    if (variable_all_sum>0)
    { calculated_value=(variable_part_sum/ variable_all_sum)*100    } 

  if (is.null(starttime)) {starttime=min( variable_all_value$measurement_time)}
  if (is.null(endtime)) {endtime=max( variable_all_value$measurement_time)}
  return(list(n=n,calculated_value=calculated_value,starttime=starttime,endtime=endtime,visutype="%"))
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
        					svglite(localResultFile)
    					} else {
							png(filename=localResultFile)
						}
						dbcon <- connectDB()
						data <- deploy_calculated_value(varids,oitype,oiids, starttime,endtime,dbcon,imagetype)
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