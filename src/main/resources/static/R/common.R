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

if (!require(RPostgreSQL)) {
	install.packages("RPostgreSQL")
}
if (!require(reshape2)) {
	install.packages("reshape2")
}

if (!require(reshape)) {
	install.packages("reshape")
}

if (!require(rjson)) {
	install.packages("rjson")
}
if (!require(corrplot)) {
	install.packages("corrplot")
}
if (!require(zoo)) {
	install.packages("zoo")
}
if (!require(plyr)) {
	install.packages("plyr")
}
if (!require(lattice)) {
	install.packages("lattice")
}
if (!require(RColorBrewer)) {
	install.packages("RColorBrewer")
}
if (!require(ggplot2)) {
	install.packages("ggplot2")
}
if (!require(xts)) {
	install.packages("xts")
}
if (!require(KernSmooth)) {
	install.packages("KernSmooth")
}

if (!require(fasttime)) {
	install.packages("fasttime")
}

if (!require(devtools)) {
	install.packages("devtools")
}


if (!require(svglite)) {
	devtools::install_github("r-lib/svglite")
}


library(RPostgreSQL)
library(reshape2)
library(reshape)
library(rjson)
library(corrplot)
library(zoo)
library(plyr)
library(lattice)
library(RColorBrewer)
library(ggplot2)
library(xts)
library(KernSmooth)
library(fasttime)
library(svglite)

#Database queries 
# #
# Author: ttejap/ttesip


#' connectToDB Function
#' 
#' connectToDB(dburl,user,pass)
#' @param dburl: example jdbc:postgresql://<domain.name>:5432/openva_old
#' @param user: db username
#' @param pass: password for use
connectToDB <- function(dburl,user,pass)
{   
    splitted <- unlist(strsplit(dburl,"\\:|\\://|\\:|\\/"))
    host <- splitted[3]
    port <- splitted[4]
    dbname <- splitted[5]
    psql <- dbDriver("PostgreSQL")
    dbcon <- dbConnect(psql, host=host, port=port, dbname=dbname,user=user,pass=pass)
    return(dbcon)
}


###############################################################################

#Database queries 
# #
# Author: ttejap/ttesip
###############################################################################


#CODES AND CODEVALUES 

#' getCodeValues Function
#' getCodeValues(db=con,codesid=1)
#' get CodeValues
#' @param db
#' @param codesid
getCodeValues<-function(db,codesid){
  query=sprintf("select * from codevalues cv where cv.codes_id=%d;",codesid)
  return(dbGetQuery(db,query))
}


#__________________________________________________
# OITYPE

#' getOitype Function
#' 
#' getOitype(db=con,variableid=266)
#' @param db
#' @param variableid
getOitype<-function(db,variableid)
{
  myVariableType=getVariableType(db,variableid)
  query=sprintf("SELECT o.id, o.title, o.report_title,o.description
                  FROM oitype o
                  JOIN oitype_property op ON op.oitype_id=o.id
                  WHERE op.id=%d;",as.integer(variableid))
  response = dbGetQuery(db,query)
  oiType=response
  return(oiType)
}
#_______________________________________________________________________________
#OBJECTOFINTEREST 
#
#Get ois by oitype
# 
#Get ois by oitype
# 
#youngsters=getOIs(db=con,oiids=NULL,oitype='youngster')
#getOIs(db=con,oiids="(9949,9948)",oitype='youngster')
#getOIs(db=con,oiids="(9949)",oitype='youngster')
#' getOIs Function
#' 
#' get OIs
#' @param db
#' @param oiids
getOIs<-function(db,oiids=NULL,oitype=NULL){
  #print("getOIs")
  if (is.null(oiids) & is.null(oitype))
  {#get all ois 
    query=sprintf("SELECT  *
                  FROM objectofinterest where oitype_title='%s'" ,oitype)
    
  } else 
    
  { if (!is.null(oiids) & !is.null(oitype))   
    { query=sprintf("SELECT  * FROM objectofinterest 
     WHERE  id IN %s and oitype_title='%s' ;",oiids,oitype)
    } else 
      if (!is.null(oiids) & is.null(oitype)) 
      {query=sprintf("SELECT  *
                    FROM objectofinterest where id IN %s" ,oiids)
      } else 
  
        {query=sprintf("SELECT  *
                  FROM objectofinterest where oitype_title='%s'" ,oitype)
        }
    
  }

  return(dbGetQuery(db,query))
}

#' getNumberOfOIs Function
#' 
#' get Number oi OIs of an oitype
#' getNumberOfOIs(db=con,oitype="youngster")
#' @param db
#' @param oitype
getNumberOfOIs<-function(db,oitype){

    query=sprintf("SELECT  count(*) FROM objectofinterest oi
                  WHERE  oitype_title =  '%s';", oitype)

  rs = dbSendQuery(db,query)
  response = fetch(rs, n=-1)
  myOIs=response
  dbClearResult(rs)
  return(myOIs)
}
#___________________________________________________________
#OI_RELATION


#' @param db
#' @param oiid (esim nimikkeitä)
#' getOIChildVariableValues(db=con,child_variableid=236,parent_oiids=c("11517"))
#' getOIChildVariableValues(db=con,child_variableid=233,parent_oiids=c("11517","11312"))
getOIChildVariableValues<-function(db,child_variableid,parent_oiids,starttime=NULL,endtime=NULL){
  
  #get children variable values
  my_all=lapply(1:length(parent_oiids), function(x) 
  {
    
    myOIid=parent_oiids[x]
    query=sprintf("SELECT  * FROM oi_relation 
                  WHERE  parent_oi_id = %s;", myOIid)
    result=dbGetQuery(db,query)
    if (nrow(result)>0)
    {
      myChildren=unique(result$child_oi_id)
      myChildOIids=paste(myChildren,collapse=",")
      myVals=getVariableValues(db,variableid=child_variableid,oiids=myChildOIids,starttime=starttime,endtime=endtime)
    }
  }
  )
  #make matrix of the result
  if(!is.null(my_all))
  {my_result=do.call(rbind,my_all)
  } else
  {my_result <- data.frame(my_empty=character(), stringsAsFactors=FALSE)}
  return(my_result)
}


#get_parent_oi_id(db=con,oi_id=11361)
get_parent_oi_id<-function(db,oi_id)
{ parent=NA
query=sprintf("SELECT parent_oi_id,parent_title
              FROM oi_relation 
              WHERE child_oi_id=%s;",oi_id)
response = dbGetQuery(db,query)
parent=response
return(parent)
}

#
#' @param db
#' @param parent_oiids (esim nimikkeitä)
#' getChildrenOiids(con,parent_oiids=c("11517"))
getChildrenOiids<-function(db,parent_oiids,starttime=NULL,endtime=NULL){
  
  query=sprintf("SELECT  * FROM oi_relation 
                WHERE  parent_oi_id in (%s);", parent_oiids)
  result=dbGetQuery(db,query)
  
  #make matrix of the result
  #myVals=unique(result$child_oi_id)
  
  return(result)
}
#
#' @param db
#' @param parent_oiids (esim nimikkeitä)
#' getChildrenOiids(con,parent_oiids=c("11517"))
getChildrenOis<-function(db,parent_oiids,starttime=NULL,endtime=NULL){
  
  query=sprintf("SELECT  * FROM oi_relation 
                WHERE  parent_oi_id in (%s);", parent_oiids)
  result=dbGetQuery(db,query)
  return(result)
}
#__________________________________________________________
#OITYPE_PROPERTY

#' getMetadata Function
#' 
#' get gmetadata
#' @param db
#' @param variableid
#' @examples
#' variableid=58, variableid=728
#' testing
#  getMetadata(con,233)

getMetadata<-function(db,variableid)
{
  variableid=as.integer(variableid)
  myMeta=data.frame(a=NA)
    query=sprintf("SELECT * 
                  FROM oitype_property WHERE oitype_property.id=%d;",variableid)
    myMeta=dbGetQuery(db,query)
  return(myMeta)
}

getMetadata_bytitle<-function(db,variable_title)
{
 
  myMeta=data.frame(a=NA)
  query=sprintf("SELECT *   FROM oitype_property WHERE oitype_property.title='%s';",variable_title)
  myMeta=dbGetQuery(db,query)
  return(myMeta)
}

#______________________________________________ 
#VALUES 
#getVariableValues
#myVals=getVariableValues(db,variableid=232,oiids=c("11361,11360,11359,11358,11357,11356,11355,11354,11353"))
#myVals=getVariableValues(db,variableid=304,oiids=c("11528"))
getVariableValues<-function(db,variableid,oiids=NULL,starttime=NULL,endtime=NULL)
{   #oiids_temp=paste("(",oiids,")",sep="")
    #print(paste("db:",oiids))

   myMetadata=getMetadata(db,variableid)
  if (myMetadata$propertytype=="b")     { 
    myFrame=getBackgroundValues(db,variableid, oiids)
    
  }  else {
    
    myFrame=getMeasurementValues(db,variableid, oiids, starttime,endtime)
  }  
  return(myFrame)
}   


#------------------------------------
#' getMeasurementValues Function
#' 
#' Measurement values based on variableid, oiids, start and endtime. Returns the a data frame of measurement variable values of given ois during a given time period 
#' @param db
#' @param variableid the variable, given as oitype_property table id, mandatory 
#' @param oiids The objects of interest, given as a character string of oiids from objectofinterest table, e.g.  "(386,387)" . If NULL, returns all ois in databas
#' @param starttime "2014-01-08 22:00:00" . If NULL, returns values until the endtime. If endtime and starttime NULL, returns all measurement
#' @param endtime "2014-02-08 24:00:00" . If NULL, returns all values from the strarttime

#testing getMeasurementValues(db=con,variableid=232,oiids=c("11361,11360,11359,11358,11357,11356,11355,11354,11353"))
#

getMeasurementValues<-function(db,variableid, oiids=NULL, starttime=NULL,endtime=NULL){        

  if (is.null(starttime))
  { query="SELECT min(measurement_time) FROM oi_measuredproperty_value"  
  response = dbGetQuery(db,query)
  starttime=response[1]
  } 
  
  if (is.null(endtime))
  { query="SELECT max(measurement_time) FROM oi_measuredproperty_value"  
  response = dbGetQuery(db,query)
  endtime=response[1]
  } 
  
  if (is.null(oiids)) 
  {  query=sprintf("SELECT omv.id, om.oitype_property_id, om.oitype_property_title,om.oi_id, om.oi_title,omv.measurement_value, omv.measurement_time FROM oi_measuredproperty_value omv 
                   JOIN oi_measuredproperty om ON omv.oi_measuredproperty_id=om.id
                   WHERE om.oitype_property_id=%d  and omv.measurement_time >= '%s' and omv.measurement_time<= '%s' ;",as.integer(variableid), format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"))
  } else{
       query=sprintf("SELECT omv.id, om.oitype_property_id,om.oitype_property_title, om.oi_id,om.oi_title, omv.measurement_value, omv.measurement_time FROM oi_measuredproperty_value omv 
                  JOIN oi_measuredproperty om ON omv.oi_measuredproperty_id=om.id
                  WHERE om.oitype_property_id=%d and om.oi_id IN %s and omv.measurement_time >= '%s' and omv.measurement_time<= '%s' ;",as.integer(variableid),
                  oiids, format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"))
    
  }       
  
  response = dbGetQuery(db,query)
  return(response)
  }

#' getBackgroundValues Function
#' 
#' Background values based on variable id and oiids. Returns a data frame of a given background variable values of given ois
#' @param db
#' @param variableid The variable, given as oitype_property table id, mandatory 
#' @param oiids Objects of interest given as a character string of oiids, e.g. "(1,2)". If NULL, returns background values of all objects of interest
#testing
#getBackgroundValues(db=con,variableid=17, oiids=NULL)
#getBackgroundValues(db=con,variableid=287, oiids="(11361,11360,11359,11358,11357,11356,11355,11354,11353)" ) 
#getBackgroundValues(db=con,variableid=1009, oiids="(1)")  
#getBackgroundValues(db=con,variableid=17, oiids="(18)") 

 
getBackgroundValues<-function(db,variableid, oiids=NULL) {
  if (is.null(oiids))
  {
    #get all ois 
    query = sprintf("SELECT * FROM oi_backgroundproperty_value ob 
                    WHERE ob.oitype_property_id= %d ;", as.integer(variableid))
  }
  else 
  {
    #get just the given ois
    query = sprintf(
      "SELECT * FROM oi_backgroundproperty_value ob 
      WHERE ob.oitype_property_id= %s and ob.oi_id IN (%s);",
      variableid,oiids  
    )
  }

  response=dbGetQuery(db,query)
  if (nrow(response)==0) 
  {   stop(paste("no data found: background variable",variableid,"oiids",oiids) )} 
  
  return(response)
  }


#' getMinMaxTimestamps Function
#' 
#' Measurement min and max timestamps. Returns a vector with min and max timestamps
#' @param db
#' getMinMaxTimestamps(db)
getMinMaxTimestamps<-function(db){      
  
  query="SELECT min(measurement_time), max(measurement_time) FROM oi_measuredproperty_value;" 
  rs = dbSendQuery(db,query)
  response = fetch(rs, n=-1)
  if (nrow(response)!=0) return(response)
  dbClearResult(rs)
}       

#' getMinTimestamp Function
#' 
#' Measurement min timestamps. Returns a vector with min timestamps
#' @param db
getMinTimestamp<-function(db){   
  
  query="SELECT min(measurement_time) FROM oi_measuredproperty_value;" 
  rs = dbSendQuery(db,query)
  response = fetch(rs, n=-1)
  if (nrow(response)!=0) return(response[1])
  dbClearResult(rs)
} 

#' getMaxTimestamps Function
#' 
#' Measurement max timestamps. Returns a vector with max timestamps
#' @param db
getMaxTimestamps<-function(db){  
  
  query="SELECT max(timestamp) FROM oi_measuredproperty_value;" 
  rs = dbSendQuery(db,query)
  response = fetch(rs, n=-1)
  if (nrow(response)!=0) return(response[1])
  dbClearResult(rs)
}       


#

#' getTSObservationMatrix Function
#' 
#' Get Observation matrix, not complete yet, NOT IN USE
#' @param db
#' @param variableid the variable, given as oitype_index table id, mandatory 
#' @param oiids The objects of interest, given as a character string of oiids from objectofinterest table, e.g.  "(386,387)" . If NULL, returns all ois in databas
#' @param starttime "2014-01-08 22:00:00" . If NULL, returns values until the endtime. If endtime and starttime NULL, returns all measurement
#' @param endtime "2014-02-08 24:00:00" . If NULL, returns all values from the strarttime 
getTSObservationMatrix<- function(db,variableids, oiids=NULL, valueids=NULL, starttime=NULL,endtime=NULL)
{
  #get variable metadata from the DB
  count=length(variableids)
  myVariableType = rep("NA",count)
  for (i  in 1:count){
    myVariableType[i]=getVariableType(db,variableids[i])
  }
  myMetadata=data.frame(title=character(),propertytype=character(),stringsAsFactors=FALSE) 
  
  for (i  in 1:count){           
    myMeta=getMetadata(variableids[i])
    myMetadata[i,"title"]=myMeta$title
    if (myVariableType[i]=="property"){
      
      myMetadata[i,"propertytype"]=myMeta$propertytype
    } else {myMetadata[i,"propertytype"]="M"} 
  }
  myMerge=data.frame(oi_id=integer(0), value=numeric(0), timestamp=as.Date(character()),stringsAsFactors=FALSE)
  myFrame=getVariableValues(db,variableids[1], valueids[1],oiids,starttime,endtime)
  if (myVariableType[1]=="index")
  {       myMerge=myFrame[c("oi_id","value","timestamp")]
  } else if ( myVariableType[1]=="property" &   myMetadata[1,"propertytype"]=="M") {
    myMerge=myFrame[c("oi_id","value","timestamp")]
  }       else {
    myMerge=myFrame[c("oi_id","value")] 
  }
  
  for (i  in 2:count)
  {
    myFrame=getVariableValues(db,variableids[i], valueids[i],oiids,starttime,endtime)
    
    if (myVariableType[i]=="index")
    {       mySub=myFrame[c("oi_id","value","timestamp")]
    if (length(myMerge$timestamp)==0){
      myMerge=merge(myMerge,mySub,by=c("oi_id"))} else {
        myMerge=merge(myMerge,mySub,by=c("oi_id","timestamp"))
      }
    }   else if ( myVariableType[1]=="property" &        myMetadata[1,"propertytype"]=="M") {
      mySub=myFrame[c("oi_id","value","timestamp")]
      if (length(myMerge$timestamp)==0){
        myMerge=merge(myMerge,mySub,by=c("oi_id"))}   else 
        {myMerge=merge(myMerge,mySub,by=c("oi_id","timestamp"))}
    }       else {
      mySub=myFrame[c("oi_id","value")]
      myMerge=merge(myMerge,mySub,by=c("oi_id"))
    }
    
  }
  colnames(myMerge)=c("oi_id","timestamp",myMetadata[,1])
  myOis=getOIs(oiids)
  myTitles=myOis[c("id", "title")]
  colnames(myTitles)= c("oi_id", "title")
  myMerge=merge(myMerge,myTitles,by="oi_id")
  return(myMerge)
}


#
#' getObservationMatrix Function, ehkä ei käytössä
#' 
#' Get Observation matrix, not complete yet. testing myMatrix=getObservationMatrixNew(selection,valueids=NULL, starttime=NULL,endtime=NULL)
#' @param db
#' @param variableid the variable, given as oitype_index table id, mandatory 
#' @param oiids The objects of interest, given as a character string of oiids from objectofinterest table, e.g.  "(386,387)" . If NULL, returns all ois in databas
#' @param starttime "2014-01-08 22:00:00" . If NULL, returns values until the endtime. If endtime and starttime NULL, returns all measurement
#' @param endtime "2014-02-08 24:00:00" . If NULL, returns all values from the strarttime 
getObservationMatrix<- function(db, selection,valueids=NULL, starttime=NULL,endtime=NULL)
{
  #get variable metadata from the DB
  variables=unique(selection$variableid)
  count=length(variables)
  
  myMetadata=data.frame(title=character(),propertytype=character(),variabletype=character(),oitype=character(),stringsAsFactors=FALSE) 
  for (i  in seq_len(count)){           
    myMeta=getMetadata(db,variables[i])
    myMetadata[i,"title"]=myMeta$title
    myMetadata[i,"variabletype"]=getVariableType(db,variables[i])
    if (myMetadata[i,"variabletype"]=="property"){
      myMetadata[i,"propertytype"]=myMeta$propertytype
    } else {
      myMetadata[i,"propertytype"]="M"
    } 
    myMetadata[i,"oitype"]=getOitype(db,variables[i])
  }
  
  
  #Same oitype (e.g. building) of variables
  if (length(unique(myMetadata$oitype))==1) {
    myMerge <- data.frame(oi_id = as.integer(unique(selection$oiid)))
    
    propertytypes=myMetadata$propertytype
    for (i in seq_len(count))
    {
      myVariable = variables[i]
      myFrame=getData(db,myVariable)[c("oi_id","value")]
      
      if (propertytypes[i] != 'B')
        myFrame <- aggregateValue(myFrame)
      
      myMerge = merge(myMerge, myFrame, by="oi_id",all=TRUE)
    }
    
    colnames(myMerge)=c("oi_id",myMetadata[,1])
    
    oiids=myMerge$oi_id
    myObjects=getOIs(db,oiids)
    myTitles=myObjects[c("id", "title")]
    colnames(myTitles)= c("oi_id", "title")
    myMerge=merge(myMerge,myTitles,by="oi_id")
  }
  else  {
    myMerge <- NULL
    
    #different oitype, merge just by timestamps 
    myVariable = variables[1]
    myFrame <- getData(myVariable)[c("timestamp", "value")]
    
    for (i in seq_len(count))
    {
      myVariable = variables[i]
      myFrame=getData(myVariable)[c("timestamp", "value")]
      if (!is.na(myFrame[1,1]))
        myMerge = if (is.null(myMerge)) myFrame else merge(myMerge,myFrame,by=c("timestamp"))
      else
        myMerge = cbind(myMerge, 0)
    }
    
    colnames(myMerge) = c("timestamp", myMetadata[,1])
    myMerge = cbind(myMerge, title = NA)  
  }
  
  return(myMerge)
}

#NEW added 4.1.2017 PJ
#______________________________________
#' getVariableValues_partition Function
#' 
#' get VariableValues
#' @param db
#' @param variableid The variable (background/measurement), given as id of oitype_property table, e.g 19.  Mandatory 
#' @param oiids The objets of interest, given as a character string of oiids from objectofinterest table, e.g.  c(1,2). mandatory .
# oitype as text
#' @param starttime "2014-01-08 22:00:00" . If NULL, returns values until the endtime. Ignored, if the variable is background variable.
#' @param endtime "2014-02-08 24:00:00" . If NULL, returns all values from the strarttime. Ignored, if the variable is background variable. 
#variableid=52
#oiids=c(1,2)
#test cases
#1) background property
# -not in tuna data 


#2) measurements 
#data not in both
#data found
#my_response=getVariableValues_partition(db=con,variableid=316,oiids='1',oitype="ship",starttime=NULL,endtime=NULL)
#nrow(my_response)
#head(my_response)
#data not found
#my_response=getVariableValues_partition(db=con,variableid=316,oiids='3',oitype="ship",starttime=NULL,endtime=NULL)
#both
#my_response=getVariableValues_partition(db=con,variableid=316,oiids='1,3',oitype="ship",starttime=NULL,endtime=NULL)

#data found in both
#my_response=getVariableValues_partition(db=con,variableid=299,oiids='1',oitype="ship",starttime=NULL,endtime=NULL)
#nrow(my_response)
#head(my_response)
#data not found
#my_response=getVariableValues_partition(db=con,variableid=299,oiids='3',oitype="ship",starttime=NULL,endtime=NULL)
##both
#my_response=getVariableValues_partition(db=con,variableid=299,oiids='1,3',oitype="ship",starttime=NULL,endtime=NULL)


#testing timestamps starttime='2017-05-03 03:50:48.0',endtime='2017-05-28 23:25:54.0')
#is data
#my_response=getVariableValues_partition(db=con,variableid=316,oiids='1',oitype="ship",starttime='2017-05-06 03:50:48.0',endtime=NULL)
#nrow(my_response)
#head(my_response)
#no data
#my_response=getVariableValues_partition(db=con,variableid=316,oiids='3',oitype="ship",starttime='2017-05-03 03:50:48.0',endtime=NULL)
#both
#my_response=getVariableValues_partition(db=con,variableid=316,oiids='1,3',oitype="ship",starttime='2017-05-03 03:50:48.0',endtime=NULL)

#data found in both
#my_response=getVariableValues_partition(db=con,variableid=299,oiids='1',oitype="ship",starttime=NULL,endtime='2017-05-20 23:25:54.0')
#nrow(my_response)
#head(my_response)
#data  found
#my_response=getVariableValues_partition(db=con,variableid=299,oiids='3',oitype="ship",starttime=NULL,endtime='2017-05-20 23:25:54.0')
#both
#my_response=getVariableValues_partition(db=con,variableid=299,oiids='1,3',oitype="ship",starttime='2017-05-03 03:50:48.0',endtime='2017-05-20 23:25:54.0')
#my_response=getVariableValues_partition(db=con,variableid=299,oiids='3,1',oitype="ship",starttime='2017-05-03 03:50:48.0',endtime='2017-05-20 23:25:54.0')

#data not found
#my_response=getVariableValues_partition(db=con,variableid=316,oiids='3',oitype="ship",starttime='2017-05-03 03:50:48.0',endtime=NULL)

#data found 
#my_response=getVariableValues_partition(db=con,variableid=299,oiids='3',oitype="ship",starttime='2017-05-03 03:50:48.0',endtime=NULL)

#3) not in tuna data 


#function 

#function 
getVariableValues_partition<-function(db,variableid, oiids,oitype,starttime=NULL,endtime=NULL,fast=FALSE) { 

  #print("getVariableValues_partition")
  myMetadata=getMetadata(db,variableid)
  if (myMetadata$propertytype=="b") { 
    #1) read values from oi_backgroundproperty_value   
    #print("getBackgroundValues") 
    myFrame=getBackgroundValues(db,variableid, oiids)
    if (nrow(myFrame) == 0) { 
      #stop(paste("no data found: ",myMetadata$title,"oiids",oiids))  
      myFrame=  data.frame(id=numeric,  oitype_property_id=numeric, oi_id=numeric, value=character, stringsAsFactors = FALSE)
    }
    #read values from oi_measuredproperty_value table partitions 
  } else if (myMetadata$oitype_title==oitype) { 
      property_title=myMetadata$title

      #print(oiids)
      oiidstemp=(unlist(  strsplit(oiids, ',')    )    )
      #print(oiidstemp)	
      myFrame=data.frame(id=numeric,  oi_measuredproperty_id=numeric, oi_id=numeric, measurement_value=numeric, measurement_time=character,stringsAsFactors = FALSE)
      for (i in 1:length(oiidstemp)) {
          my_oi=getOIs(db,paste("(",oiidstemp[[i]],")"))

          oi_title=my_oi$title
          #print("title")
          #print(oi_title)

          my_result=get_measurements_partition(db,property_title,oi_title,starttime,endtime,fast)
          my_result$oitype_property_id=rep(variableid, each=nrow(my_result))
          my_result$oi_id=rep(my_oi$title,each=nrow(my_result))
          #head(my_result)
          #nrow(my_result)
          myFrame=rbind(my_result,myFrame)
          nrow(myFrame)
      }

      if (nrow(myFrame) ==0) {   
          #stop(paste("OpenVA warning: no data found, variable",myMetadata$title, "oiids",oiids))
      } 
  } else {
      #5) something else  
      myFrame=getMeasurementValues(db,variableid, oiids, starttime,endtime)
      if (nrow(myFrame) ==0) {   
          myFrame=data.frame(id=numeric,  oitype_property_id=numeric, oi_id=numeric, measurement_value=numeric, measurement_time=character,stringsAsFactors = FALSE)
          #stop(paste("OpenVA warning: no data found, variable",myMetadata$title, "oiids",oiids))
      }
  }
  return(myFrame)
}

#NEW added 4.1.2017 Paula J

#gets measurements directly from partitioned tables 
#
#test queries
#data timestamps not null, data exists
#my_response=get_bus_measurements(db=con,property_title='motor_rpm',oi_title='L_12R_1',starttime='2016-07-08 14:47:48',endtime='2016-08-08 14:47:48')

#data timestamps not null, no data
#my_response=get_bus_measurements(db=con,property_title='motor_rpm',oi_title='L_12R_7',starttime='2016-07-08 14:47:48',endtime='2016-08-08 14:47:48')

#both timestamps null, data exists
#my_response=get_bus_measurements(db=con,property_title='motor_rpm',oi_title='L_12R_1')


get_measurements_partition=function(db,property_title,oi_title,starttime=NULL,endtime=NULL,fast=FALSE) {  
  #print("get_measurements_partition")
  my_table=paste(tolower(oi_title),"_",property_title,sep="")
  found=TRUE
  if (is.null(starttime)) {   
    query=sprintf("SELECT min(measurement_time) FROM %s",my_table)  
    response = dbGetQuery(db,query)
    starttime=response[1]
    if (is.na(starttime$min)) {  
      found=FALSE 
    } 
  }
  if (is.null(endtime)) {   
      query=sprintf("SELECT max(measurement_time) FROM %s" ,my_table) 
      response = dbGetQuery(db,query)
      endtime=response[1]
      if (is.na(endtime$max))  {
        found=FALSE
      }
  }
  
  if(found) {  
    #starttime and endtime ok 

    if(fast) {
   	query=sprintf("SELECT id,oi_measuredproperty_id,measurement_value,to_char(measurement_time,'YYYY-MM-DD HH24:MI:SS MS') FROM %s   where measurement_time >= '%s' and measurement_time<= '%s';",my_table, format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"))
    	#print(query)  
    	response = dbGetQuery(db,query)
	colnames(response)[colnames(response)=="to_char"] <- "measurement_time"
	response$measurement_time <- fastPOSIXct(response$measurement_time) 
    } else {
    	query=sprintf("SELECT id,oi_measuredproperty_id,measurement_value,measurement_time FROM %s   where measurement_time >= '%s' and measurement_time<= '%s';",my_table, format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"))
    	#print(query)  
    	response = dbGetQuery(db,query)
	
    }

    if (nrow(response)==0) {
      found=FALSE
    }

  }
  
  if (!found) { 
    response=data.frame(id=numeric,  oi_measuredproperty_id=numeric,  measurement_value=numeric, measurement_time=character,stringsAsFactors = FALSE)
  } 

  return(response)
}


#TIME UNIT TRANSFORMATION, added 2.2.2018 / PJ 
#should not be used anywhere anymore!!!!

create_ts_object_quantitative=function(my_frame, plot_time_unit,variableid,meta)
{
print("create_ts_object_quantitative should not be used anywhere anymore!!!!")    

#create time series object
    zoo_frame=zoo(my_frame$measurement_value,my_frame$measurement_time) # saa tulla warning
   #print(head(zoo_frame))
   #print(tail(zoo_frame))
    rm(my_frame)
    gc()

    data_time_unit=meta$time_unit
    operation=meta$plottype
#is plot_time_unit=data_time_unit?
    if (plot_time_unit==data_time_unit) { 
        plot_zoo=zoo_frame
        plot_zoo <- na.omit(plot_zoo)
        plot_frame=fortify.zoo(plot_zoo)
        colnames(plot_frame)=c("measurement_time","measurement_value")
        plot_time_unit_title=paste(plot_time_unit)
    } else {   
        #create table of possible transformations 
        time_units=c("sec","min","hour","day","week","month","year")
        time_transformations=data.frame(data_time_unit=time_units,sec=numeric(7),min=numeric(7),hour=numeric(7),day=numeric(7),week=numeric(7),month=numeric(7),year=numeric(7),stringsAsFactors = FALSE)

        for (i in 1:nrow(time_transformations)){
            j=i+1
            time_transformations[i,j:ncol(time_transformations)]=1
        }
        for (i in 1:nrow(time_transformations)){
            for (j in 2:ncol(time_transformations)){
                if  (time_transformations[i,j]==1) time_transformations[i,j]=colnames(time_transformations)[j]
            }
        }

      #transformation allowed ?   
       my_trans=as.list(time_transformations[time_transformations$data_time_unit==data_time_unit,2:ncol(time_transformations)])
       plot_time_unit_title=paste(operation,"per",plot_time_unit)
       if (plot_time_unit %in% my_trans) { 
#get aggregation operation 
	
	#print(paste("Trans Meta",operation))
#do transformation 
          if (plot_time_unit=="min") { 
          # aggregate to mins 
                 plot_zoo=period.apply(zoo_frame, endpoints(zoo_frame, "mins"), operation)
                 plot_zoo <- na.omit(plot_zoo)
                plot_frame=fortify.zoo(plot_zoo)
                colnames(plot_frame)=c("measurement_time","measurement_value")
               # plot_frame$measurement_time=paste(plot_frame$measurement_time,":00",sep="")

            }  else if (plot_time_unit=="hour") {
            # aggregate to hours 
                plot_zoo=period.apply(zoo_frame, endpoints(zoo_frame, "hours"), operation)
                plot_zoo <- na.omit(plot_zoo)
                plot_frame=fortify.zoo(plot_zoo)
                colnames(plot_frame)=c("measurement_time","measurement_value")
                #plot_frame$measurement_time=paste(plot_frame$measurement_time,":00:00",sep="")
            
            } else if  (plot_time_unit=="day") {
            # aggregate to days
                plot_zoo=period.apply(zoo_frame, endpoints(zoo_frame, "days"), operation)
                plot_zoo <- na.omit(plot_zoo)
                plot_frame=fortify.zoo(plot_zoo)
                colnames(plot_frame)=c("measurement_time","measurement_value")
                #plot_frame$measurement_time=paste(plot_frame$measurement_time," 00:00:00",sep="")
        
            } else if(plot_time_unit=="week") {
            #aggregate week
                plot_zoo=period.apply(zoo_frame, endpoints(zoo_frame, "weeks"), operation)
                plot_zoo <- na.omit(plot_zoo)
                plot_frame=fortify.zoo(plot_zoo)
                colnames(plot_frame)=c("measurement_time","measurement_value")

            } else if( plot_time_unit=="month") {
                # aggregate to months
                plot_zoo=period.apply(zoo_frame, endpoints(zoo_frame, "months"), operation)
                plot_zoo <- na.omit(plot_zoo)
                plot_frame=fortify.zoo(plot_zoo)
                colnames(plot_frame)=c("measurement_time","measurement_value")
                #plot_frame$measurement_time=paste(plot_frame$measurement_time,"-01 00:00:00",sep="")
            } else  if (plot_time_unit=="year") {
            # aggregate to years
                plot_zoo=aggregate(zoo_frame, format(index(zoo_frame),'%Y'), operation)
                plot_zoo <- na.omit(plot_zoo)
                plot_frame=fortify.zoo(plot_zoo)
                colnames(plot_frame)=c("measurement_time","measurement_value")
                #plot_frame$measurement_time=paste(plot_frame$measurement_time,"-01-01 00:00:00",sep="")
            } 
        } else   {
            stop(paste("OpenVA warning: Transformation is not allowed",data_time_unit,"->",plot_time_unit))
        }
    }
    plot_frame$measurement_time=as.POSIXct(plot_frame$measurement_time)
    plot_frame=unique(plot_frame)
    total_sum=sum(plot_frame$measurement_value)
    rm(plot_zoo)
    rm(zoo_frame)
    gc()
    return(list(plot_frame,plot_time_unit_title,total_sum))
}

#NEW added 23.8.2018 Paula J

#gets measurement means aggregated by day/hour  directly from partitioned tables, for several ois , usedin contour plots
#variableid=299
#oiids='1,3'
#getVariableValues_partition_aggregated(db,variableid, oiids,oitype="ship",starttime=NULL,endtime=NULL)
  

getVariableValues_partition_aggregated<-function(db,variableid, oiids,oitype,starttime=NULL,endtime=NULL)
{ #print("getVariableValues_partition")
  myMetadata=getMetadata(db,variableid)
  if (myMetadata$propertytype=="b" | myMetadata$propertytype=="c")     stop(paste("OpenVA warning: only for timeseries data ",myMetadata$title,"oiids",oiids)) 
  
  property_title=myMetadata$title
    # print(oiids)
  oiidstemp=(unlist(  strsplit(oiids, ',')    )    )
  #print(oiidstemp)	
  my_oi=getOIs(db,paste("(",oiidstemp[[1]],")")   )
  oi_title=my_oi$title
  #print("title")
  #print(oi_title)
  #print(paste("read inner starts",1,Sys.time()))
  
  myFrame=data.frame(id=numeric,  oitype_property_id=numeric, oi_id=numeric, measurement_value=numeric, measurement_time=character,stringsAsFactors = FALSE)
  for (i in 1:length(oiidstemp))
  { 
    #print( oiidstemp[[i]])
    my_oi=getOIs(db,paste("(",oiidstemp[[i]],")")   )
    oi_title=my_oi$title
    #print("title")
    #print(oi_title)
    #print(paste("read inner starts",i,Sys.time()))
    my_result=get_measurements_partition_aggregated(db,property_title,oi_title,starttime,endtime)
    #print(paste("read inner ends",Sys.time()))
    my_result$oitype_property_id=rep(variableid, each=nrow(my_result))
    my_result$oi_id=rep(my_oi$title,each=nrow(my_result))
    #head(my_result)
    #nrow(my_result)
    myFrame=rbind(my_result,myFrame)
    nrow(myFrame)
  }
  #print("ohi")
  #print(nrow(myFrame))
  if (nrow(myFrame) ==0)
  {   
    #stop(paste("OpenVA warning: no data found, variable",myMetadata$title, "oiids",oiids))
  } 

  return(myFrame)
} 

#____________________________________________
#NEW added 23.8.2018 Paula J
#get_measurements_partition_aggregated

#used in contour plot
#returns means of measurement values aggregated by day and hour
#only for one oi at time

#property_title="me_cons_kg_per_h"
#oi_title="norway_ship"

#property_title="me_cons_kg_per_h"
#oi_title="norway_ship"


#property_title="engine_speed"
#oi_title="EUSKADI_ALAI"


#result=get_measurements_partition_aggregated(db=con,property_title,oi_title,starttime=NULL,endtime=NULL)


#get_measurements_partition_aggregated

#used in contour plot
#returns means of measurement values aggregated by day and hour
#only for one oi at time

#property_title="me_cons_kg_per_h"
#oi_title="norway_ship"
#result=get_measurements_partition_aggregated(db=con,property_title,oi_title,starttime=NULL,endtime=NULL)
get_measurements_partition_aggregated=function(db,property_title,oi_title,starttime=NULL,endtime=NULL)
{ 
 

  my_table=paste(tolower(oi_title),"_",property_title,sep="")
  found=TRUE
  #print(my_table)
  if (is.null(starttime)) {   
    query=sprintf("SELECT min(measurement_time) FROM %s",my_table)  
    response = dbGetQuery(db,query)
    starttime=response[1]
    if (is.na(starttime$min)) {  found=FALSE  } 
  }
  if (is.null(endtime)) {   
    query=sprintf("SELECT max(measurement_time) FROM %s" ,my_table) 
    response = dbGetQuery(db,query)
    endtime=response[1]
    if (is.na(endtime$max))  { found=FALSE}
  }
  
   if(found) 
  {  

    query=sprintf("
    SELECT 
    min(id) as id,
    avg(measurement_value) as value, 
    
    measurement_time::timestamp::date as day,  
    extract(hour from ns.measurement_time) as hour
    FROM %s ns
    WHERE measurement_value > 0 
    AND ns.measurement_time  BETWEEN '%s' AND '%s'
    GROUP BY day, hour
    ORDER BY  day, hour;",my_table, format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"))


    response = dbGetQuery(db,query)

    if (nrow(response)==0) found=FALSE
  }
  
  if (!found)#
  {  
    response=data.frame(id=numeric,   measurement_value=numeric,day=numeric, hour=numeric,stringsAsFactors = FALSE)
  } 
  
  return(response)
  
}

#get_rowcount
#retuns number of rows of a partitioned table
#property_title="me_cons_kg_per_h"
#oi_title="norway_ship"
#get_rowcount(db,property_title,oi_title,starttime=NULL,endtime=NULL)
get_rowcount=function(db,property_title,oi_title,starttime=NULL,endtime=NULL)
{
  my_table=paste(tolower(oi_title),"_",property_title,sep="")
  found=TRUE
  #print(my_table)
  if (is.null(starttime)) {   
    query=sprintf("SELECT min(measurement_time) FROM %s",my_table)  
    response = dbGetQuery(db,query)
    starttime=response[1]
    if (is.na(starttime$min)) {  found=FALSE  } 
  }
  if (is.null(endtime)) {   
    query=sprintf("SELECT max(measurement_time) FROM %s" ,my_table) 
    response = dbGetQuery(db,query)
    endtime=response[1]
    if (is.na(endtime$max))  { found=FALSE}
  }
  
  if(found) 
  { 
#get rowcount
  query=sprintf("SELECT count(*) FROM %s   where measurement_time >= '%s' and measurement_time<= '%s';",my_table, format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"))
#print(query) 

  response = dbGetQuery(db,query)
  if (nrow(response)==0) found=FALSE
  }
  if (!found)
  {  
    response=data.frame(id=numeric,   measurement_value=numeric,day=numeric, hour=numeric,stringsAsFactors = FALSE)
  } 
  
  return(response)
  
}

#NEW added 28.8.2018 Pekka Siltanen
get_sum_partitioned=function(dbcon,oi_title,property_type_title,starttime=NULL,endtime=NULL) {
    table_name=paste(tolower(oi_title),"_",tolower(property_type_title),sep="") 
     if (is.null(starttime)) {   
        query=sprintf("SELECT min(measurement_time) FROM %s",table_name)  
        response = dbGetQuery(dbcon,query)
        starttime=response[1]
        if (is.na(starttime$min)) {  
            return(0);
        } 
    }
    if (is.null(endtime)) {   
        query=sprintf("SELECT max(measurement_time) FROM %s" ,table_name) 
        response = dbGetQuery(dbcon,query)
        endtime=response[1]
        if (is.na(endtime$max))  { 
            return(0);
        }
    }

    query=sprintf("SELECT count(*),sum(measurement_value) FROM %s where measurement_time >= '%s' and measurement_time<= '%s';",table_name, format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"))
    #print(query)
    sum = dbGetQuery(dbcon,query)
    #print(sum)
    return(sum);
}

#NEW added 28.8.2018 Pekka Siltanen
get_mean_partitioned=function(dbcon,oi_title,property_type_title,starttime=NULL,endtime=NULL) {
    table_name=paste(tolower(oi_title),"_",tolower(property_type_title),sep="") 
     if (is.null(starttime)) {   
        query=sprintf("SELECT min(measurement_time) FROM %s",table_name)  
        response = dbGetQuery(dbcon,query)
        starttime=response[1]
        if (is.na(starttime$min)) {  
            return(0);
        } 
    }
    if (is.null(endtime)) {   
        query=sprintf("SELECT max(measurement_time) FROM %s" ,table_name) 
        response = dbGetQuery(dbcon,query)
        endtime=response[1]
        if (is.na(endtime$max))  { 
            return(0);
        }
    }

    query=sprintf("SELECT count(*),avg(measurement_value) FROM %s where measurement_time >= '%s' and measurement_time<= '%s';",table_name, format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"))
    avg = dbGetQuery(dbcon,query)
    return(avg);
}

#NEW added 28.8.2018 Pekka Siltanen
get_minmaxtime_partitioned=function(dbcon,variableid, oiids,oitype) {
	myMetadata=getMetadata(dbcon,variableid)
    	property_title=myMetadata$title
    	oiidstemp=(unlist(strsplit(oiids, ',')))

	result <- list(min=Inf,max=-Inf)
    	for (i in 1:length(oiidstemp)) {
      		my_oi=getOIs(dbcon,paste("(",oiidstemp[[i]],")"))
      		oi_title=my_oi$title
		table_name=paste(tolower(oi_title),"_",tolower(property_title),sep="") 
		query=sprintf("SELECT min(measurement_time),max(measurement_time) FROM %s",table_name)  
		#print(query)
        response = dbGetQuery(dbcon,query)
		if (response$min < result$min) {
			result$min = response$min
		}
		if (response$max > result$max) {
			result$max = response$max
		}
    	} 
    	return(result);
}




#function 
#' getVariableValues_partition_aggregated_by_time Function
#' 
#' get VariableValues
#' @param db
#' @param variableid The variable (background/measurement), given as id of oitype_property table, e.g 19.  Mandatory 
#' @param oiids The objets of interest, given as a character string of oiids from objectofinterest table, e.g.  c(1,2). mandatory .
# oitype as text
#' @param starttime "2014-01-08 22:00:00" . If NULL, returns values until the endtime. Ignored, if the variable is background variable.
#' @param endtime "2014-02-08 24:00:00" . If NULL, returns all values from the strarttime. Ignored, if the variable is background variable. 

#testing
#variableid=414 #me_cons_kg_per_h
#variableid=410
#variableid=411
#row_limit=3000000
#oiids='5'
#oitype="ship"
#plot_time_unit="hour"
plot_time_unit="sec"
#plot_time_unit="min"
plot_time_unit="day"
#plot_time_unit="week"
plot_time_unit="month"

#response=getVariableValues_partition_aggregated_by_time(db,variableid, oiids,oitype,starttime=NULL,endtime=NULL,fast=FALSE,plot_time_unit,  row_limit=NULL) 
#head(response)
getVariableValues_partition_aggregated_by_time<-function(db,variableid, oiids,oitype,starttime=NULL,endtime=NULL,fast=FALSE, plot_time_unit,row_limit=NULL) 
{ 

  myMetadata=getMetadata(db,variableid) 

  if (myMetadata$propertytype=="b") { 
 #1) read values from oi_backgroundproperty_value    
    myFrame=getBackgroundValues(db,variableid, oiids)
    if (nrow(myFrame) == 0) { 
      #stop(paste("no data found: ",myMetadata$title,"oiids",oiids))  
      myFrame=  data.frame(oitype_property_id=numeric, oi_id=numeric, value=character, stringsAsFactors = FALSE)
    }
    
  #2) read values from oi_measuredproperty_value table partitions 
  } else if (myMetadata$oitype_title==oitype) { 
    property_title=myMetadata$title
  
    #print(oiids)
    oiidstemp=(unlist(  strsplit(oiids, ',')    )    )
    #print(oiidstemp)	
    myFrame=data.frame( measurement_value=numeric, measurement_time=character,oitype_property_id=numeric, oi_id=numeric, stringsAsFactors = FALSE)
    for (i in 1:length(oiidstemp)) {
      
      #oi details
      my_oi=getOIs(db,paste("(",oiidstemp[[i]],")"))
      oi_title=my_oi$title
      #print(oi_title)
      
      #data
      my_result=get_measurements_partition_aggregated_by_time(db,property_title,oi_title,plot_time_unit,  row_limit, starttime,endtime)
      if (nrow(my_result) >0) {   
      #add oi and variableid to data
          my_result$oitype_property_id=rep(variableid, each=nrow(my_result))
          my_result$oi_id=rep(my_oi$title,each=nrow(my_result))
        #head(my_result)
        #nrow(my_result)
        myFrame=rbind(my_result,myFrame)
        #nrow(myFrame)
      } 
    }
  } else {
    #5) something else  
    #print("else")
    myFrame=getMeasurementValues(db,variableid, oiids, starttime,endtime)
    if (nrow(myFrame) ==0) {   
      myFrame=data.frame(oitype_property_id=numeric, oi_id=numeric, measurement_value=numeric, measurement_time=character,stringsAsFactors = FALSE)
      #stop(paste("OpenVA warning: no data found, variable",myMetadata$title, "oiids",oiids))
    }
  }
  
  return(myFrame)
}

  
get_measurements_partition_aggregated_by_time=function(db,property_title,oi_title,plot_time_unit, row_limit, starttime=NULL,endtime=NULL)
{

  my_table=paste(tolower(oi_title),"_",property_title,sep="")

  found=TRUE
  #print(my_table)
  if (is.null(starttime)) {   
    query=sprintf("SELECT min(measurement_time) FROM %s",my_table)  
    response = dbGetQuery(db,query)
    starttime=response[1]
    if (is.na(starttime$min)) {  found=FALSE  } 
  }
  if (is.null(endtime)) {   
    query=sprintf("SELECT max(measurement_time) FROM %s" ,my_table) 
    response = dbGetQuery(db,query)
    endtime=response[1]
    if (is.na(endtime$max))  { found=FALSE}
  }
  
  if(found) {  
  		myMetadata=getMetadata_bytitle(db,property_title)
     	aggre_operation=myMetadata$plottype
     	
     	data_time_unit=myMetadata$time_unit
     	if (plot_time_unit==data_time_unit) { 
      		rowcount=get_rowcount(db,property_title,oi_title,starttime,endtime) 
      		if (!is.null(row_limit)) {
      	 		if ((rowcount$count)> row_limit) 
      	 			stop("OpenVA warning: too many rows for plot. Limit time period or change time unit")
      		}
      
     		response=get_measurements_partition(db,property_title,oi_title,starttime,endtime)
     		response=response[,c("measurement_value","measurement_time")]
    	} else {
      		#create table of possible transformations 
      		time_units=c("sec","min","hour","day","week","month","year")
      		time_transformations=data.frame(data_time_unit=time_units,sec=numeric(7),min=numeric(7),hour=numeric(7),day=numeric(7),week=numeric(7),month=numeric(7),year=numeric(7),stringsAsFactors = FALSE)
      		for (i in 1:nrow(time_transformations)){
        		j=i+1
        		time_transformations[i,j:ncol(time_transformations)]=1
      		}
		    for (i in 1:nrow(time_transformations)){
		        for (j in 2:ncol(time_transformations)){
		          if  (time_transformations[i,j]==1) time_transformations[i,j]=colnames(time_transformations)[j]
		        }
		     }
      
      #transformation allowed ?   
      my_trans=as.list(time_transformations[time_transformations$data_time_unit==data_time_unit,2:ncol(time_transformations)])
      if (!plot_time_unit %in% my_trans) stop(paste("OpenVA warning: Can not make time transformation to ", plot_time_unit, " when data time unit is ", data_time_unit)) 
      
    #metadata corrections to match Postgres
        aggre_operation_temp=aggre_operation
        if (aggre_operation=="mean") aggre_operation_temp="avg"
      
#        plot_time_unit_temp=plot_time_unit
#        if (plot_time_unit=="min") plot_time_unit_temp="minute"
#        if (plot_time_unit=="sec") plot_time_unit_temp="second"
      

	query=sprintf("select %s(measurement_value) as measurement_value, date_trunc('%s',measurement_time) as measurement_time FROM %s WHERE measurement_time BETWEEN '%s' AND '%s' group by date_trunc('%s',measurement_time);"
			,aggre_operation_temp, plot_time_unit,my_table,format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"),plot_time_unit)

      #print(query)

      response = dbGetQuery(db,query)
      head(response)
      if (nrow(response)==0) found=FALSE
    }
  
    if (!found)#
    {  
     response=data.frame( measurement_value=numeric, measurement_time=character,stringsAsFactors = FALSE)
    } 
  
    return(response)   
    }
}

#added by PS, 11.10.2018
getMinMaxTime<-function(db,table_name) {
    query=sprintf("SELECT min(measurement_time),max(measurement_time) FROM %s",table_name)
    response = dbGetQuery(db,query)
    return(response)
}


#added by PS, 11.10.2018
#nominal binary data: 
#
getNomBinVariableValues_partition_aggregated_by_time<-function(db,variableid, oiid,oitype,starttime=NULL,endtime=NULL,fast=FALSE, plot_time_unit) 
{ 	

	if (length((unlist(strsplit(oiid, ',')))) > 1) {
		stop("OpenVA warning: Sorry, only one object of interest allowed for this analysis")
	}
  	metadata=getMetadata(db,variableid) 
    	oi=getOIs(db,paste("(",oiid,")"))
      
	if (metadata$propertytype=="b") { 
		stop("OpenVA warning: Sorry, no background variables not implemented yet for this analysis")
	}
	property_title=metadata$title
	oi_title=oi$title
	table_name=paste(tolower(oi_title),"_",property_title,sep="")

	if (is.null(starttime)) {   
		time= getMinMaxTime(db,table_name)
  		starttime = time$min
  		if (is.null(endtime)) {  
			endtime= time$max 
  		}
	}
	if (is.na(starttime) || is.na(endtime)) {
		emptyframe=data.frame(oitype_property_id=numeric, oi_id=numeric, measurement_value=numeric, measurement_time=character,stringsAsFactors = FALSE)
		return(emptyframe)
	}
	

 	if (metadata$oitype_title==oitype) { 
        	if (plot_time_unit=="min") plot_time_unit_temp="minute"
        	if (plot_time_unit=="sec") plot_time_unit_temp="second"
		select_beginning = sprintf("select distinct on(measurement_time) measurement_time, measurement_value,count_val from (select t.measurement_value, count(t.measurement_value)as count_val, date_trunc('%s',t.measurement_time) as measurement_time  from ( ",plot_time_unit)
		select =sprintf("select measurement_value,measurement_time from %s where measurement_time between '%s' and '%s'",table_name,starttime,endtime)
		select_end = sprintf(")as t group by t.measurement_value, date_trunc('%s',t.measurement_time) order by date_trunc('%s',t.measurement_time),count(t.measurement_value) desc) as t2",plot_time_unit,plot_time_unit)
		query = paste(select_beginning,select,select_end)
      		response = dbGetQuery(db,query)
      		if (nrow(response)==0) {
			stop(paste("OpenVA warning: no data found, variable",metadata$title, "oiids",oiids))
		}
		return(response)
	} else {
		stop(paste("OpenVA warning: sorry, something went wrong. Please report selected parameters to system admin"))	
	}
}


getOIbyOIId<-function(db,oiid){
  
  query=sprintf("SELECT  * FROM objectofinterest oi
                WHERE  id =  %s;", oiid)
  
  rs = dbSendQuery(db,query)
  response = fetch(rs, n=-1)
  dbClearResult(rs)
  return(response)
}
