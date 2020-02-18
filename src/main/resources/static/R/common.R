# OpenVA - Open software platform for visual analytics
#
# Copyright (c) 2018, VTT Technical Research Centre of Finland Ltd
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


suppressPackageStartupMessages(library(RPostgreSQL))
suppressPackageStartupMessages(library(reshape2))
suppressPackageStartupMessages(library(reshape))
suppressPackageStartupMessages(library(rjson))
suppressPackageStartupMessages(library(corrplot))
suppressPackageStartupMessages(library(zoo))
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(lattice))
suppressPackageStartupMessages(library(RColorBrewer))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(xts))
suppressPackageStartupMessages(library(KernSmooth))
suppressPackageStartupMessages(library(fasttime))
suppressPackageStartupMessages(library(svglite))
suppressPackageStartupMessages(library(tools))
suppressPackageStartupMessages(library(gridExtra))

#Database queries 
# #
# Author: ttejap/ttesip


#' connectToDB Function
#' 
#' connectToDB(dburl,user,pass)
#' @param dburl: example jdbc:postgresql://databio.westeurope.cloudapp.azure.com:5432/openva_old
#' @param user: db username
#' @param ass: password for use
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
getOIs <-function(db,oiids=NULL,oitype=NULL){
  if (is.null(oiids) & is.null(oitype)) {
  	#get all ois 
    query=sprintf("SELECT  *
                  FROM objectofinterest where oitype_title='%s'" ,oitype)
    
  } else { 
  	if (!is.null(oiids) & !is.null(oitype)) { 
    	query=sprintf("SELECT  * FROM objectofinterest  WHERE  id IN %s and oitype_title='%s' ;",oiids,oitype)
    } else 
      if (!is.null(oiids) & is.null(oitype)) {
      	query=sprintf("SELECT  *
                    FROM objectofinterest where id IN %s" ,oiids)
                   
      } else {
      	query=sprintf("SELECT  * FROM objectofinterest where oitype_title='%s'" ,oitype)
      	print(query)
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
#' @param oiid 
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
#' @param parent_oiids 
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
#' @param parent_oiids 
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

#new;added by Paula 19.6.2019
#result=getMetadata_by_propertytype(dbcon,propertytype='c')
#nrow(result)
getMetadata_by_propertytype<-function(db,propertytype)
{
  
  myMeta=data.frame(a=NA)
  query=sprintf("SELECT *   FROM oitype_property WHERE oitype_property.propertytype='%s';",propertytype)
  myMeta=dbGetQuery(db,query)
  return(myMeta)
}


#______________________________________________ 
#OI_MEASUREDPROPERTY
#new;added by Paula 19.6.2019
#result=get_oitypeproperties_by_oiid(dbcon,oiid=2)
#nrow(result)
get_oitypeproperties_by_oiid<-function(db,oiid)
{
  
  myResult=data.frame(a=NA)
  query=sprintf("SELECT distinct oi_id,oi_title, oitype_property_id,oitype_property_title   FROM oi_measuredproperty WHERE oi_measuredproperty.oi_id=%d;",oiid)
  myResult=dbGetQuery(db,query)
  return(myResult)
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
#' getObservationMatrix Function
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
		  #print(property_title)
          my_result=get_measurements_partition(db,property_title,oi_title,starttime,endtime,fast)
          #print(nrow(my_result))
          if (nrow(my_result) > 0) {
          	my_result$oitype_property_id=rep(variableid, each=nrow(my_result))
          	my_result$oi_id=rep(my_oi$title,each=nrow(my_result))
          	myFrame=rbind(my_result,myFrame)
          }
      }

      if (nrow(myFrame) ==0) {   
          #stop(paste("OpenVA warning: no data found, variable",myMetadata$title, "oiids",oiids))
      } 
  } else {
      #5) something else  
      myFrame=getMeasurementValues(db,variableid, oiids, starttime,endtime)
      if (nrow(myFrame) ==0) {   
          myFrame=data.frame(id=numeric(),  oitype_property_id=numeric(), oi_id=numeric(), measurement_value=numeric(), measurement_time=character(),stringsAsFactors = FALSE)
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


get_measurements_partition =function(db,property_title,oi_title,starttime=NULL,endtime=NULL,fast=FALSE) {  
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

    query=sprintf("SELECT count(*),sum(measurement_value::NUMERIC) FROM %s where measurement_time >= '%s' and measurement_time<= '%s';",table_name, format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"))
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

getGroupMembersByGroupTitle<-function(db,property_group_title){
  
  query=sprintf("SELECT * FROM group_member WHERE property_group_title = '%s' ORDER BY order_num;", property_group_title)
  
  rs = dbSendQuery(db,query)
  response = fetch(rs, n=-1)
  dbClearResult(rs)
  return(response)
}



#new added by Paula J. 6.11.2018

#' get measurement daily counts 
#' 
#' Measurement daily counts. Returns daily sums of the number of measurement each day. Dataframe value,day
#' @param db
#' getMeasurementDailyCounts(varids=241,oiids=1, starttime=NULL,endtime=NULL,db)
getMeasurementDailyCounts=function(varids,oiids, starttime=NULL,endtime=NULL,db){   
  variableid=varids
  #check variable
  my_meta=getMetadata(dbcon,variableid)
  #print(my_meta)
  if (nrow(my_meta)==0) {
  	stop(paste("OpenVA message: No variable", variableid, "found, try another"))
  }
  #print(my_meta$variabletype)
  
  #check oi 
  oiids_temp=paste("(",oiids,")",sep="")
  my_ois=getOIs(dbcon,oiids_temp,oitype=my_meta$oitype_title)
  my_ois_title=paste(my_ois[,c("report_title")],collapse = ',')
  if (nrow(my_ois)==0) {
  	stop(paste("OpenVA message:No objectofinterest", oiids,"found, try another"))
  }
  
  #read data    
  
  property_title=my_meta$title
  oi_title=my_ois$title
  my_table=paste(tolower(oi_title),"_",property_title,sep="")
  #print(my_table)
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
  
  query=sprintf("SELECT min(id) as id, count (*) as value, measurement_time::timestamp::date as day FROM %s ns WHERE ns.measurement_time  BETWEEN '%s' AND '%s'
                 GROUP BY day ORDER BY  day;",my_table, format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"))
  
  
  response = dbGetQuery(dbcon,query)

  return(response)
} 



#new added by Paula J. 7.11.2018

#' count_data
#' 
#' Counts measurements of a partitioned oi_measuredproeprty_value table, oi_id and variable id given 
#' returns a list:
#' First element TRUE if the table was found, otherwise FALSE
#' Second element the amount, with oi_title and oitype_property_title 
#' count_data(variableid=241,oiid=1, starttime=NULL,endtime=NULL,db)

count_data=function(variableid,oiid, starttime=NULL,endtime=NULL,db)
{  
  #dbcon = connectDB()
  #on.exit(dbDisconnect(dbcon))
  
  found=TRUE
  data_count=0
  
  #check variable
  my_meta=getMetadata(dbcon,variableid)
  #no variable found
  if (nrow(my_meta)==0) {     
  	found=FALSE 
  } else {
    #print(my_meta$variabletype)
    
    #check oi 
    print(my_meta$oitype_title)
    print(oiid)
    my_oi=getOIs(dbcon,paste("(",oiid,")"),oitype=my_meta$oitype_title) 
    property_title=my_meta$title
    oi_title=my_oi$title
    my_table=paste(tolower(oi_title),"_",property_title,sep="")
    #print(my_table)
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
    if (found) {
      query=sprintf("SELECT count (*) from %s     WHERE measurement_time  BETWEEN '%s' AND '%s';",
                      my_table, format(starttime, format="%Y-%m-%d %H:%M:%S"),format(endtime, format="%Y-%m-%d %H:%M:%S"))
        
      data_count = (dbGetQuery(db,query))
      if (nrow(data_count)==0) {
         data_count=0
      }
      count = data_count$count
      print(typeof(count))
      print("count__")
      print(count)
    }
  }
  
  
  return(list(found,count))
  
}

#inner join: not tested 
join_2_variables=function(dbcon,oi_title,property_title1,property_title2, starttime, endtime) {
	
	table_1_name = paste(tolower(oi_title),"_",property_title1,sep="")
	table_2_name = paste(tolower(oi_title),"_",property_title2,sep="")
	start = format(starttime, format="%Y-%m-%d %H:%M:%S")
	end = format(endtime, format="%Y-%m-%d %H:%M:%S")
	
	query=sprintf("select t1.measurement_time, t1.measurement_value as measurement_value_1, t2.measurement_value as measurement_value_2
					 from %s t1
						 inner join %s t2 on t1.measurement_time = t2.measurement_time
						 where t1.measurement_time > '%s' and t1.measurement_time < '%s'
						   and t2.measurement_time > '%s' and t2.measurement_time < '%s'",
						   table_1_name,table_2_name,
						   start,end,start,end)					  
    response = dbGetQuery(dbcon,query)
	return(response)
}


#inner join: not tested 
join_3_variables=function(dbcon,oi_title,property_title1,property_title2,property_title3, starttime, endtime) {
	
	table_1_name = paste(tolower(oi_title),"_",property_title1,sep="")
	table_2_name = paste(tolower(oi_title),"_",property_title2,sep="")
	table_3_name = paste(tolower(oi_title),"_",property_title3,sep="")
	start = format(starttime, format="%Y-%m-%d %H:%M:%S")
	end = format(endtime, format="%Y-%m-%d %H:%M:%S")
	
	query=sprintf("select t1.measurement_time, t1.measurement_value as measurement_value_1, t2.measurement_value as measurement_value_2, t3.measurement_value as measurement_value_3
					 from %s t1
						 inner join %s t2 on t1.measurement_time = t2.measurement_time
						 inner join %s t3 on t1.measurement_time = t3.measurement_time 
						 where t1.measurement_time > '%s' and t1.measurement_time < '%s'
						   and t2.measurement_time > '%s' and t2.measurement_time < '%s'
						   and t3.measurement_time > '%s' and t3.measurement_time < '%s'",
						   table_1_name,table_2_name,table_3_name,
						   start,end,start,end,start,end)					  
    response = dbGetQuery(dbcon,query)
	return(response)
	
}

#inner join 
join_4_variables=function(dbcon,oi_title,property_title1,property_title2,property_title3, property_title4, starttime, endtime) {
	
	table_1_name = paste(tolower(oi_title),"_",property_title1,sep="")
	table_2_name = paste(tolower(oi_title),"_",property_title2,sep="")
	table_3_name = paste(tolower(oi_title),"_",property_title3,sep="")
	table_4_name = paste(tolower(oi_title),"_",property_title4,sep="")
	start = format(starttime, format="%Y-%m-%d %H:%M:%S")
	end = format(endtime, format="%Y-%m-%d %H:%M:%S")
	
	query=sprintf("select t1.measurement_time, t1.measurement_value as measurement_value_1, t2.measurement_value as measurement_value_2, t3.measurement_value as measurement_value_3, t4.measurement_value as measurement_value_4
					 from %s t1
						 inner join %s t2 on t1.measurement_time = t2.measurement_time
						 inner join %s t3 on t1.measurement_time = t3.measurement_time 
						 inner join %s t4 on t1.measurement_time = t4.measurement_time 
						 where t1.measurement_time > '%s' and t1.measurement_time < '%s'
						   and t2.measurement_time > '%s' and t2.measurement_time < '%s'
						   and t3.measurement_time > '%s' and t3.measurement_time < '%s'",
						   table_1_name,table_2_name,table_3_name,table_4_name,
						   start,end,start,end,start,end,start,end)					  
    response = dbGetQuery(dbcon,query)
	return(response)
	
}

#inner join
join_5_variables=function(dbcon,oi_title,property_title1,property_title2,property_title3,property_title4,property_title5, starttime, endtime) {
	
	table_1_name = paste(tolower(oi_title),"_",property_title1,sep="")
	table_2_name = paste(tolower(oi_title),"_",property_title2,sep="")
	table_3_name = paste(tolower(oi_title),"_",property_title3,sep="")
	table_4_name = paste(tolower(oi_title),"_",property_title4,sep="")
	table_5_name = paste(tolower(oi_title),"_",property_title5,sep="")
	start = format(starttime, format="%Y-%m-%d %H:%M:%S")
	end = format(endtime, format="%Y-%m-%d %H:%M:%S")
	
	query=sprintf("select t1.measurement_time, t1.measurement_value as measurement_value_1, t2.measurement_value as measurement_value_2, t3.measurement_value as measurement_value_3, t4.measurement_value as measurement_value_4, t5.measurement_value as measurement_value_5
					 from %s t1
						 inner join %s t2 on t1.measurement_time = t2.measurement_time
						 inner join %s t3 on t1.measurement_time = t3.measurement_time 
						 inner join %s t4 on t2.measurement_time = t4.measurement_time
						 inner join %s t5 on t3.measurement_time = t5.measurement_time
						 where t1.measurement_time > '%s' and t1.measurement_time < '%s'
						   and t2.measurement_time > '%s' and t2.measurement_time < '%s'
						   and t3.measurement_time > '%s' and t3.measurement_time < '%s'
						   and t4.measurement_time > '%s' and t4.measurement_time < '%s'
						   and t5.measurement_time > '%s' and t5.measurement_time < '%s'",
						   table_1_name,table_2_name,table_3_name,table_4_name,table_5_name,
						   start,end,start,end,start,end,start,end,start,end)					   
    response = dbGetQuery(dbcon,query)
	return(response)
	
}

#outer full join:
full_join_5_variables=function(dbcon,oi_title,property_title1,property_title2,property_title3,property_title4,property_title5, starttime, endtime) {
	
	table_1_name = paste(tolower(oi_title),"_",property_title1,sep="")
	table_2_name = paste(tolower(oi_title),"_",property_title2,sep="")
	table_3_name = paste(tolower(oi_title),"_",property_title3,sep="")
	table_4_name = paste(tolower(oi_title),"_",property_title4,sep="")
	table_5_name = paste(tolower(oi_title),"_",property_title5,sep="")
	start = format(starttime, format="%Y-%m-%d %H:%M:%S")
	end = format(endtime, format="%Y-%m-%d %H:%M:%S")
	
	query=sprintf("select t1.measurement_time, t1.measurement_value as measurement_value_1, t2.measurement_value as measurement_value_2, t3.measurement_value as measurement_value_3, t4.measurement_value as measurement_value_4, t5.measurement_value as measurement_value_5
					 from %s t1
						 inner join %s t2 on t1.measurement_time = t2.measurement_time
						 inner join %s t3 on t1.measurement_time = t3.measurement_time 
						 inner join %s t4 on t2.measurement_time = t4.measurement_time
						 inner join %s t5 on t3.measurement_time = t5.measurement_time
						 where t1.measurement_time > '%s' and t1.measurement_time < '%s'
						   and t2.measurement_time > '%s' and t2.measurement_time < '%s'
						   and t3.measurement_time > '%s' and t3.measurement_time < '%s'
						   and t4.measurement_time > '%s' and t4.measurement_time < '%s'
						   and t5.measurement_time > '%s' and t5.measurement_time < '%s'",
						   table_1_name,table_2_name,table_3_name,table_4_name,table_5_name,
						   start,end,start,end,start,end,start,end,start,end)					   						   			   
    response = dbGetQuery(dbcon,query)
	return(response)
	
}


#########################################################################################
#Calculation functions for calculated values
#########################################################################################
#########################################################################################
#__________________________________________________
#calculated_value 2
#ship_sailing_distance
# calculate value between the given time period

#testing
#calculate_ship_sailing_distance(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_ship_sailing_distance = function(dbcon,
                                           oitype,
                                           oiids,
                                           starttime = NULL,
                                           endtime = NULL,
                                           merged_data)
{
  sailing_distance = hourly_values(dbcon,
                                   oitype,
                                   oiids,
                                   "ship_sailing_distance",
                                   "sum",
                                   starttime,
                                   endtime)
  return(sailing_distance)
  
}


#__________________________________________________
#calculated_value 3
#ship_steaming_hours
# calculate value between the given time period

#testing
#calculate_ship_steaming_hours(db=dbcon,oitype="ship",oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_ship_steaming_hours = function(dbcon,
                                         oitype,
                                         oiids,
                                         starttime = NULL,
                                         endtime = NULL,
                                         merged_data)
{
  steaming_hours = hourly_values(dbcon,
                                 oitype,
                                 oiids,
                                 "ship_steaming_hours",
                                 "sum",
                                 starttime,
                                 endtime)
  
  return(steaming_hours)
}


#__________________________________________________
#calculated_value 5
#ship_steaming_distance_percentage
# calculate value between the given time period

#testing
#calculate_ship_steaming_distance_percentage(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_ship_steaming_distance_percentage = function(dbcon,
                                                       oitype,
                                                       oiids,
                                                       starttime = NULL,
                                                       endtime = NULL,
                                                       merged_data)
{
  data_ok = TRUE
  err_msg =""
  n = 0
  calculated_value = NA
  if (nrow(merged_data) > 0) {
      ship_steaming_distance <-
        data.frame(merged_data$measurement_time,
                   merged_data$ship_steaming_distance)
      names(ship_steaming_distance) <-
        c("measurement_time", "measurement_value")
  } else { 
  	ship_steaming_distance = getVariableValues_partition(
    	dbcon,
    	variableid = getMetadata_bytitle(dbcon, "ship_steaming_distance")$id,
    	oiids,
    	oitype = oitype,
    	starttime = starttime,
    	endtime = endtime,
    	TRUE
  	)
  }
  if (nrow (ship_steaming_distance) == 0) {
    	data_ok = FALSE
    	#stop("OpenVA warning: no data for calculation")
    	err_msg ="ship_steaming_distance: no data"
    	rm(ship_steaming_distance)
    	gc()
  } else {
    ship_steaming_distance = unique(ship_steaming_distance)
    ship_steaming_distance = ship_steaming_distance[order(ship_steaming_distance$measurement_time),]
    #head(ship_steaming_distance)
    
    sailing_distance = getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "ship_sailing_distance")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )
    if (nrow (sailing_distance) == 0)
    {
      data_ok = FALSE
      err_msg ="sailing_distance: no data"
      rm(ship_steaming_distance)
      rm(sailing_distance)
      gc()
      #stop("OpenVA warning: no data for calculation")
    } else {
      sailing_distance = unique(sailing_distance)
      #head(sailing_distance)
      
      ship_steaming_sailing_distance = merge(ship_steaming_distance,
                                             sailing_distance,
                                             by = c("measurement_time"))
      n = nrow(ship_steaming_sailing_distance)
      if (n == 0)
      {
        data_ok = FALSE
        err_msg ="ship_steaming_sailing_distance: no data"
        rm(ship_steaming_distance)
        rm(sailing_distance)
        rm(ship_steaming_sailing_distance)
        gc()
        #stop("OpenVA warning: no data for calculation")
      } else {
        ship_steaming_sailing_distance = ship_steaming_sailing_distance[, c("measurement_time",
                                                                            "measurement_value.x",
                                                                            "measurement_value.y")]
        colnames(ship_steaming_sailing_distance) = c("measurement_time",
                                                     "steaming_distance",
                                                     "sailing_distance")
        if (sum(ship_steaming_sailing_distance$sailing_distance) > 0) {
          calculated_value =
            (
              sum(ship_steaming_sailing_distance$steaming_distance) / sum(ship_steaming_sailing_distance$sailing_distance)
            ) * 100
        }
        starttime = min(ship_steaming_sailing_distance$measurement_time)
        endtime = max(ship_steaming_sailing_distance$measurement_time)
        rm(ship_steaming_distance)
        rm(sailing_distance)
        rm(ship_steaming_sailing_distance)
        gc()
        
      }
    }
  }
  
  result = list(
    data_ok = data_ok,
    err_msg = err_msg,
    n = n,
    calculated_value = calculated_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "%"
  )
  
  return(result)
}


# calculated value 6
# ship_steaming_fuel_percentage
# calculate value between the given time period

# testing

#calculate_ship_steaming_fuel_percentage(db=dbcon, oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

calculate_ship_steaming_fuel_percentage = function(dbcon,
                                                   oitype,
                                                   oiids,
                                                   starttime = NULL,
                                                   endtime = NULL,
                                                   merged_data) {
  data_ok = TRUE
  err_msg =""
  n = 0
  calculated_value = NA

  ship_steaming =
	    getVariableValues_partition(
	      dbcon,
	      variableid = getMetadata_bytitle(dbcon, "mainengine_fueloil_consumption_steaming")$id,
	      oiids,
	      oitype = oitype,
	      starttime = starttime,
	      endtime = endtime,
	      TRUE
	    )
  if (nrow(ship_steaming) == 0) {
    #stop("OpenVA warning: no data for calculation ship_steaming")
    print("OpenVA warning: no data for calculation ship_steaming")
	err_msg = "ship_steaming: no data"
    rm(ship_steaming)
    gc()
    data_ok = FALSE
  } else {
    ship_steaming = unique(ship_steaming)    
    if (nrow(merged_data) > 0) {
      fueloil_consumption_total <-
        data.frame(merged_data$measurement_time,
                   merged_data$fueloil_consumption_total)
      names(fueloil_consumption_total) <-
        c("measurement_time", "measurement_value")
    } else {
      fueloil_consumption_total =
        getVariableValues_partition(
          dbcon,
          variableid = getMetadata_bytitle(dbcon, "fueloil_consumption_total")$id,
          oiids,
          oitype = oitype,
          starttime = starttime,
          endtime = endtime,
          TRUE
        )[c("measurement_time", "measurement_value")]
    }
    
    if (nrow(fueloil_consumption_total) == 0) {
      data_ok = FALSE
      rm(ship_steaming)
      rm(fueloil_consumption_total)
      gc()
      #stop("OpenVA warning: no data for calculation fueloil_consumption_total")
	  print("OpenVA warning: no data for calculation fueloil_consumption_total")
	  err_msg = "fueloil_consumption_total: no data"
    } else {
      if (sum(fueloil_consumption_total$measurement_value) == 0) {
        data_ok = FALSE
        err_msg = "fueloil_consumption_total: no data"
        rm(ship_steaming)
        rm(fueloil_consumption_total)
        gc()
        #stop("OpenVA warning: no data for calculation 2")
        print("OpenVA warning: no data for calculation 2")
      } else {
      	n = nrow(fueloil_consumption_total)
        calculated_value = (
          sum(ship_steaming$measurement_value) / sum(fueloil_consumption_total$measurement_value)
        ) * 100
        
        starttime = min(fueloil_consumption_total$measurement_time)
        endtime = max(fueloil_consumption_total$measurement_time)
        rm(ship_steaming)
        rm(fueloil_consumption_total)
        gc()
      }
    }
  }
  
  result = list(
    data_ok = data_ok,
    err_msg = err_msg,
    n = n,
    calculated_value = calculated_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "%"
  )

  return(result)
}

#__________________________________________________
#calculated_value 8
#ship_maneuvering_hours
# calculate value between the given time period

#testing
#calculate_ship_maneuvering_hours(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_ship_maneuvering_hours = function(dbcon,
                                            oitype,
                                            oiids,
                                            starttime = NULL,
                                            endtime = NULL,
                                            merged_data)
{
  maneuvering_hours = hourly_values(dbcon,
                                    oitype,
                                    oiids,
                                    "ship_maneuvering_hours",
                                    "sum",
                                    starttime,
                                    endtime)
  
  return(maneuvering_hours)
}

#__________________________________________________
#calculated_value 9
#ship_maneuvering_time_percentage
#percentage of time of the total time analyzed that ship has been maneuvering

#testing
#calculate_ship_maneuvering_time_percentage(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

# function
calculate_ship_maneuvering_time_percentage = function(dbcon,
                                                      oitype,
                                                      oiids,
                                                      starttime = NULL,
                                                      endtime = NULL,
                                                      merged_data)
{
  data_ok = TRUE
  err_msg =""
  n = 0
  calculated_value = NA
  #ship maneuvering
  ship_maneuvering_hours = getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, "ship_maneuvering_hours")$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  #head(ship_maneuvering_hours)
  n = nrow(ship_maneuvering_hours)
  if (n == 0) {
    #stop("OpenVA warning: no data for calculation")
	err_msg = "fueloil_consumption_total: no data"
    data_ok = FALSE
    rm(ship_maneuvering_hours)
    gc()
  } else {
    ship_maneuvering_time_sum = sum(ship_maneuvering_hours$measurement_value)
    #ship_total_time
    total_time_sum = nrow(ship_maneuvering_hours) * 10 / 3600
    if (total_time_sum > 0) {
      calculated_value = (ship_maneuvering_time_sum / total_time_sum) * 100
      starttime = min(ship_maneuvering_hours$measurement_time)
      endtime = max(ship_maneuvering_hours$measurement_time)
      
    } else {
      data_ok = FALSE
      
    }
    rm(ship_maneuvering_hours)
    gc()
  }
  result = list(
    data_ok = data_ok,
	err_msg = err_msg,
    n = n,
    calculated_value = calculated_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "%"
  )
  
  return(result)
}

#__________________________________________________
#calculated_value 11
#ship_fueloil_consumption_nmile_avg
#Average value of fuel consumed per nautical mile sailed
#Using values on steaming condition

#testing
#calculate_ship_fueloil_consumption_nmile_avg(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_ship_fueloil_consumption_nmile_avg = function(dbcon,
                                                        oitype,
                                                        oiids,
                                                        starttime = NULL,
                                                        endtime = NULL,
                                                        merged_data) {
  data_ok = TRUE
  err_msg = ""
  n = 0
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  #get fo consumption on steaming
  #get steaming distance
  
    if (nrow(merged_data) > 0) {
      ship_steaming_distance <-
        data.frame(merged_data$measurement_time,
                   merged_data$ship_steaming_distance)
      names(ship_steaming_distance) <-
        c("measurement_time", "measurement_value")
  	} else { 
  		ship_steaming_distance =
    	getVariableValues_partition(
      		dbcon,
      		variableid = getMetadata_bytitle(dbcon, "ship_steaming_distance")$id,
      		oiids,
      		oitype = oitype,
      		starttime = starttime,
      		endtime = endtime,
      		TRUE
    	)[, c("measurement_time", "measurement_value")]
	}
  if (nrow(ship_steaming_distance) == 0) {
    #stop("OpenVA warning: no data for calculation")
    data_ok = FALSE
    err_msg = "ship_steaming_distance: no data"
    rm(ship_steaming_distance)
    gc()
  } else {
    #get fo consumption on steaming
    mainengine_fueloil_consumption_steaming =
      getVariableValues_partition(
        dbcon,
        variableid = getMetadata_bytitle(dbcon, "mainengine_fueloil_consumption_steaming")$id,
        oiids,
        oitype = oitype,
        starttime = starttime,
        endtime = endtime,
        TRUE
      )[, c("measurement_time", "measurement_value")]
    # head(fueloil_consumption_total_steaming)
    if (nrow(mainengine_fueloil_consumption_steaming) == 0) {
      #stop("me_fueloil_consumption_steaming: no data")
	  err_msg = "me_fueloil_consumption_steaming: no data"
      data_ok = FALSE
      rm(ship_steaming_distance)
      rm(mainengine_fueloil_consumption_steaming)
      gc()
    } else {
      #calculate fueloil consumption per nautical mile
      ship_fueloil_consumption_nmile = merge(
        mainengine_fueloil_consumption_steaming,
        ship_steaming_distance,
        by = c("measurement_time")
      )
      rm(ship_steaming_distance)
      rm(mainengine_fueloil_consumption_steaming)
      gc()
      #head(ship_fueloil_consumption_nmile)
      n = nrow(ship_fueloil_consumption_nmile)
      if (n == 0) {
        #stop("OpenVA warning: no data for calculation")
		err_msg = "ship_fueloil_consumption_nmile: no data"
        data_ok = FALSE
        rm(ship_fueloil_consumption_nmile)
        gc()
      } else {
        colnames(ship_fueloil_consumption_nmile) = c(
          "measurement_time",
          "mainengine_fueloil_consumption_steaming",
          "ship_steaming_distance"
        )
        ship_fueloil_consumption_nmile = ship_fueloil_consumption_nmile[ship_fueloil_consumption_nmile$ship_steaming_distance > 0,]
        ship_fueloil_consumption_nmile$val = ship_fueloil_consumption_nmile$mainengine_fueloil_consumption_steaming /
          ship_fueloil_consumption_nmile$ship_steaming_distance
        #print(sum(ship_fueloil_consumption_nmile$mainengine_fueloil_consumption_steaming))
        #print(sum(ship_fueloil_consumption_nmile$ship_steaming_distance))
        
        #plot(ship_fueloil_consumption_nmile$measurement_time,ship_fueloil_consumption_nmile$val)
        #get mean
        #print(head(ship_fueloil_consumption_nmile), digits=10)
        #calculated_value = mean(ship_fueloil_consumption_nmile$val, na.rm = TRUE)
        #print(calculated_value)
        # hack to get same values as zigor
        calculated_value = sum(ship_fueloil_consumption_nmile$mainengine_fueloil_consumption_steaming) /
          sum(ship_fueloil_consumption_nmile$ship_steaming_distance)
        sd_value = sd(ship_fueloil_consumption_nmile$val)
        min_value = min(ship_fueloil_consumption_nmile$val)
        max_value = max(ship_fueloil_consumption_nmile$val)
        starttime = min(ship_fueloil_consumption_nmile$measurement_time)
        endtime = max(ship_fueloil_consumption_nmile$measurement_time)
        rm(ship_fueloil_consumption_nmile)
        gc()
      }
    }
  }
  return(
    list(
      data_ok = data_ok,
      n = n,
      calculated_value = calculated_value,
      starttime = starttime,
      endtime = endtime,
      sd_value = sd_value,
      min_value = min_value,
      max_value = max_value,
	  err_msg = err_msg,
      visutype = "avg"
    )
  )
}

#__________________________________________________
#calculated_value 12
#ship_velocity_avg
#ship's average velocity

#testing
#calculate_ship_velocity_avg(dbcon,oiids=oiids_temp,oitype='ship',starttime=starttime,endtime=endtime,merged_data)

#function
calculate_ship_velocity_avg = function(dbcon,
                                       oitype,
                                       oiids,
                                       starttime = NULL,
                                       endtime = NULL,
                                       merged_data)
{
  data_ok = TRUE
  err_msg = ""
  n = 0
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA

  #get speed on steaming
  ship_speed_actual =
    getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "ship_speed_actual")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )[, c("oi_id", "measurement_time", "measurement_value")]
  n = nrow(ship_speed_actual)
  if (n == 0) {
    #stop("OpenVA warning: no data for calculation")
    data_ok = FALSE
	err_msg = "ship_speed_actual: no data"
    rm(ship_speed_actual)
    gc()
  } else {
        calculated_value = mean(ship_speed_actual$measurement_value,
                                na.rm = TRUE)
        sd_value = sd(ship_speed_actual$measurement_value)
        min_value = min(ship_speed_actual$measurement_value)
        max_value = max(ship_speed_actual$measurement_value)
        starttime = min(ship_speed_actual$measurement_time)
        endtime = max(ship_speed_actual$measurement_time)
  }
  return(
    list(
      data_ok = data_ok,
      n = n,
      calculated_value = calculated_value,
      starttime = starttime,
      endtime = endtime,
      sd_value = sd_value,
      min_value = min_value,
      max_value = max_value,
      err_msg = err_msg,
      visutype = "avg"
    )
  )
}

#__________________________________________________
#calculated_value 14
#mainengine_running_hours
# calculate value between the given time period

#testing
#calculate_mainengine_running_hours(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_mainengine_running_hours = function(dbcon,
                                              oitype,
                                              oiids,
                                              starttime = NULL,
                                              endtime = NULL,
                                              merged_data)
{
  data_ok = TRUE
  err_msg = ""
  n = 0
  calculated_value = NA
  min_value = NA
  max_value = NA
  sd_value = NA
  mainengine_running_hours = NA
  #get main engine running
  
  if (nrow(merged_data) > 0) {
    mainengine_running <-
      data.frame(merged_data$measurement_time,
                 merged_data$mainengine_running)
    names(mainengine_running) <-
      c("measurement_time", "measurement_value")
  } else {
    mainengine_running = getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "main_engine_running")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )[c("measurement_time", "measurement_value")]
  }
  
  if (nrow(mainengine_running) == 0) {
    #stop("OpenVA warning: no data for calculation")
    print("main_engine_running: no data for calculation")
    data_ok = FALSE
    err_msg = "main_engine_running: no data"
    rm(mainengine_running)
    gc()
  } else {
    n = nrow(mainengine_running)
    me_running_count = nrow(mainengine_running[mainengine_running$measurement_value == 1,])
    starttime = min(mainengine_running$measurement_time)
    endtime = max(mainengine_running$measurement_time)
    
    time_difference = as.numeric(endtime - starttime, units = "secs")
    mainengine_running_hours = me_running_count * 10 / 3600
    min_value = 0
    max_value = me_running_count
    sd_value = 0
    rm(mainengine_running)
    gc()
  }
  return(
    list(
      data_ok = data_ok,
      n = n,
      calculated_value = mainengine_running_hours,
      starttime = starttime,
      endtime = endtime,
      sd_value = sd_value,
      min_value = min_value,
      max_value = max_value,
	  err_msg = err_msg,
      visutype = "sum"
    )
  )
}



# __________________________________________________
#calculated_value 15
#mainengine_runningtime_percentage
#
#testing
#calculate_mainengine_runningtime_percentage(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_mainengine_runningtime_percentage = function(dbcon,
                                                       oitype,
                                                       oiids,
                                                       starttime = NULL,
                                                       endtime = NULL,
                                                       merged_data)
{
  data_ok = TRUE
  n = 0
  calculated_value = NA
  err_msg = ""
  #get main engine running
  if (nrow(merged_data) > 0) {
    mainengine_running <-
      data.frame(merged_data$measurement_time,
                 merged_data$mainengine_running)
    names(mainengine_running) <-
      c("measurement_time", "measurement_value")
  } else {
    mainengine_running = getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "main_engine_running")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )[c("measurement_time", "measurement_value")]
  }
  
  
  n = nrow(mainengine_running)
  if (n == 0) {
    #stop("OpenVA warning: no data for calculation")
	err_msg = "main_engine_running: no data"
    data_ok = FALSE
    rm(mainengine_running)
    gc()
  } else {
    me_running_count = nrow(mainengine_running[mainengine_running$measurement_value == 1,])
    calculated_value = (me_running_count / n) * 100
    starttime = min(mainengine_running$measurement_time)
    endtime = max(mainengine_running$measurement_time)
    rm(mainengine_running)
    gc()
  }
  result = list(
    data_ok = data_ok,
    n = n,
    calculated_value = calculated_value,
    starttime = starttime,
    endtime = endtime,
    err_msg = err_msg,
    visutype = "%"
  )
  return(result)
  
}

#__________________________________________________
#calculated_value 16
#mainengine_running_steaming_percentage

#testing
#calculate_mainengine_running_steaming_percentage(db=dbcon, oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)
#
#function
calculate_mainengine_running_steaming_percentage = function(dbcon,
                                                            oitype,
                                                            oiids,
                                                            starttime = NULL,
                                                            endtime = NULL,
                                                            merged_data)
{
  data_ok = TRUE
  err_msg = ""
  n = 0
  calculated_value = NA
  #get ship steaming
  if (nrow(merged_data) > 0) {
      ship_steaming <-
        data.frame(merged_data$measurement_time,
                   merged_data$ship_steaming)
      names(ship_steaming) <-
        c("measurement_time", "measurement_value")
  } else { 
	  ship_steaming = getVariableValues_partition(
	    dbcon,
	    variableid = getMetadata_bytitle(dbcon, "ship_steaming")$id,
	    oiids,
	    oitype = oitype,
	    starttime = starttime,
	    endtime = endtime,
	    TRUE
	  )[c("measurement_time", "measurement_value")]
  }
  print(nrow(ship_steaming))
  if (nrow(ship_steaming) == 0) {
    #stop("OpenVA warning: no data for calculation")
    data_ok = FALSE
    err_msg = "ship_steaming: no data"
    rm(ship_steaming)
    gc()
  } else {
    # get mainengine_running
    
    if (nrow(merged_data) > 0) {
      mainengine_running <-
        data.frame(merged_data$measurement_time,
                   merged_data$mainengine_running)
      names(mainengine_running) <-
        c("measurement_time", "measurement_value")
    } else {
      mainengine_running = getVariableValues_partition(
        dbcon,
        variableid = getMetadata_bytitle(dbcon, "main_engine_running")$id,
        oiids,
        oitype = oitype,
        starttime = starttime,
        endtime = endtime,
        TRUE
      )[c("measurement_time", "measurement_value")]
    }
    print(nrow(mainengine_running))
    
    if (nrow(mainengine_running) == 0)
    {
      #stop("OpenVA warning: no data for calculation")
      data_ok = FALSE
      err_msg = "mainengine_running: no data"
      rm(ship_steaming)
      rm(mainengine_running)
      gc()
    } else {
      ship_steaming$measurement_time <-
        as.character(ship_steaming$measurement_time)
      mainengine_running$measurement_time <-
        as.character(mainengine_running$measurement_time)
      print("merge")  
      steaming_running = merge(ship_steaming,
                               mainengine_running,
                               "measurement_time")
  	  print("merged") 
      rm(ship_steaming)
      rm(mainengine_running)
      gc()
      n = nrow(steaming_running)
      #head(steaming_running)
      if (n == 0)
      {
        #stop("OpenVA warning: no data for calculation")
        data_ok = FALSE
       err_msg = "steaming_running: no data"
      } else {
        steaming_running = steaming_running[, c("measurement_time",
                                                "measurement_value.x",
                                                "measurement_value.y")]
        colnames(steaming_running) = c("measurement_time", "steaming", "running")
        steaming_running_count = nrow(steaming_running[steaming_running$steaming == 1 &
                                                       steaming_running$running == 1, ])
        mainengine_running_count = nrow(steaming_running[steaming_running$running, ])
        calculated_value = (steaming_running_count / mainengine_running_count) *  100
        
        starttime = min(steaming_running$measurement_time)
        endtime = max(steaming_running$measurement_time)
        rm(steaming_running)
        gc()
      }
    }
  }
  result = list(
    data_ok = data_ok,
    n = n,
    calculated_value = calculated_value,
    starttime = starttime,
    endtime = endtime,
    err_msg = err_msg,
    visutype = "%"
  )
  return(result)
}

#__________________________________________________
#calculated_value 17
#fueloil_consumption_main_engine_sum

#testing
#calculate_fueloil_consumption_main_engine_sum(dbcon, oitype='ship',oiids=oiids_temp, starttime = NULL, endtime = NULL,merged_data)

calculate_fueloil_consumption_main_engine_sum = function(dbcon,
                                                         oitype,
                                                         oiids,
                                                         starttime = NULL,
                                                         endtime = NULL,
                                                         merged_data)
{
  data_ok = TRUE
  n = 0
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  err_msg = "" 
  
  if (nrow(merged_data) > 0) {
    consumption_main_engine <-
      data.frame(merged_data$measurement_time,
                 merged_data$me_fo_consumption)
    names(consumption_main_engine) <-
      c("measurement_time", "measurement_value")
  } else {
    consumption_main_engine = getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "ME_FO_consumption")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )[c("measurement_time", "measurement_value")]
  }
  consumption_main_engine$measurement_value <- consumption_main_engine$measurement_value*10/3600
  
  
  if (nrow(consumption_main_engine) == 0) {
    #stop("OpenVA warning: no data for calculation")
    data_ok = FALSE
    err_msg = "consumption_main_engine: no data"
    rm(consumption_main_engine)
    gc()
  } else {
    n = nrow(consumption_main_engine)
    starttime = min(consumption_main_engine$measurement_time)
    endtime = max(consumption_main_engine$measurement_time)
    
    calculated_value = sum(consumption_main_engine$measurement_value)
    rm(consumption_main_engine)
    gc()
  }
  return(
    list(
      data_ok = data_ok,
      n = n,
      calculated_value = calculated_value,
      starttime = starttime,
      endtime = endtime,
      sd_value = sd_value,
      min_value = min_value,
      max_value = max_value,
      err_msg = err_msg,
      visutype = "sum"
    )
  )
  
}



#__________________________________________________
#fueloil_consumption_aux_engine_sum
#testing
#calculate_fueloil_consumption_aux_engine_sum(dbcon,oitype='ship',oiids=oiids_temp, starttime = NULL, endtime = NULL,merged_data)

calculate_fueloil_consumption_aux_engine_sum = function(dbcon,
                                                        oitype,
                                                        oiids,
                                                        starttime = NULL,
                                                        endtime = NULL,
                                                        merged_data)
{
  data_ok = TRUE
  n = 0
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  err_msg = "" 
  
  
  if (nrow(merged_data) > 0) {
    consumption_aux_engine <-
      data.frame(merged_data$measurement_time,
                 merged_data$ae_fo_consumption)
    names(consumption_aux_engine) <-
      c("measurement_time", "measurement_value")
  } else {
    consumption_aux_engine = getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "AE_FO_consumption")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )[c("measurement_time", "measurement_value")]
  }
    consumption_aux_engine$measurement_value <- consumption_aux_engine$measurement_value*10/3600
    
  if (nrow(consumption_aux_engine) == 0) {
    #stop("OpenVA warning: no data for calculation")
    print("OpenVA warning: no data for calculation")
    data_ok = FALSE
    err_msg = "consumption_aux_engine: no data" 
    rm(consumption_aux_engine)
    gc()
  } else {
    n = nrow(consumption_aux_engine)
    starttime = min(consumption_aux_engine$measurement_time)
    endtime = max(consumption_aux_engine$measurement_time)
    calculated_value = sum(consumption_aux_engine$measurement_value)
    rm(consumption_aux_engine)
    gc()
  }
  return(
    list(
      data_ok = data_ok,
      n = n,
      calculated_value = calculated_value,
      starttime = starttime,
      endtime = endtime,
      sd_value = sd_value,
      min_value = min_value,
      max_value = max_value,
	  err_msg = err_msg,
      visutype = "sum"
    )
  )
  
}


#__________________________________________________
#calculated_value 18
#mainengine_fueloil_consumption_avg

#testing
#calculate_mainengine_fueloil_consumption_avg(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_mainengine_fueloil_consumption_avg = function(dbcon,
                                                        oitype,
                                                        oiids,
                                                        starttime = NULL,
                                                        endtime = NULL,
                                                        merged_data)
{
  data_ok = TRUE
  n = 0
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  err_msg = ""

  #get running
  if (nrow(merged_data) > 0) {
    main_engine_running <-
      data.frame(merged_data$measurement_time,
                 merged_data$mainengine_running)
    names(main_engine_running) <-
      c("measurement_time", "measurement_value")
  } else {
    main_engine_running =
      getVariableValues_partition(
        dbcon,
        variableid = getMetadata_bytitle(dbcon, "main_engine_running")$id,
        oiids,
        oitype = oitype,
        starttime = starttime,
        endtime = endtime,
        TRUE
      )[c("measurement_time", "measurement_value")]
  }
  
  if (nrow(main_engine_running) == 0) {
    #stop("OpenVA warning: no data for calculation")
    data_ok = FALSE
    err_msg = "main_engine_running: no data"
    rm(main_engine_running)
    gc()
  } else {
    #take just running events
    main_engine_running = main_engine_running[main_engine_running$measurement_value >    0,]
    if (nrow(main_engine_running) == 0) {
      #stop("OpenVA warning: no data for calculation")
      data_ok = FALSE
	  err_msg = "main_engine_running: no data"
      rm(main_engine_running)
      gc()
    } else {
      #get main engine fuel oil
      
      if (nrow(merged_data) > 0) {
        main_engine_fuel_oil <-
          data.frame(
            merged_data$measurement_time,
            merged_data$me_fo_consumption
          )
        names(main_engine_fuel_oil) <-
          c("measurement_time", "measurement_value")
      } else {
        main_engine_fuel_oil =  getVariableValues_partition(
          dbcon,
          variableid = getMetadata_bytitle(dbcon, "ME_FO_consumption")$id,
          oiids,
          oitype = oitype,
          starttime = starttime,
          endtime = endtime,
          TRUE
        )[c("measurement_time", "measurement_value")]
      }
      main_engine_fuel_oil$measurement_value <- main_engine_fuel_oil$measurement_value*10/3600
      
      if (nrow(main_engine_fuel_oil) == 0)  {
        #stop("OpenVA warning: no data for calculation")
        data_ok = FALSE
        err_msg = "fo_consumption_me: no data"
        rm(main_engine_running)
        rm(main_engine_fuel_oil)
        gc()
      } else {
        #calculate consumption per hour
        main_engine_fuel_oil$measurement_time <-
          as.character(main_engine_fuel_oil$measurement_time)
        main_engine_running$measurement_time <-
          as.character(main_engine_running$measurement_time)
        main_engine_fuel_oil_running = merge(main_engine_fuel_oil,
                                             main_engine_running,
                                             "measurement_time")
        
        rm(main_engine_running)
        rm(main_engine_fuel_oil)
        gc()
        if (nrow(main_engine_fuel_oil_running) == 0) {
          #stop("OpenVA warning: no data for calculation")
          data_ok = FALSE
          err_msg = "fo_consumption_me_running: no data"
          rm(main_engine_fuel_oil_running)
          gc()
        } else {
          colnames(main_engine_fuel_oil_running) = c("measurement_time", "fuel_oil", "running")
          main_engine_fuel_oil_running$running_time = main_engine_fuel_oil_running$running /  360
          main_engine_fuel_oil_running$value = main_engine_fuel_oil_running$fuel_oil /  main_engine_fuel_oil_running$running_time
          
          #final value
          calculated_value = mean(main_engine_fuel_oil_running$value , na.rm = TRUE)
          sd_value = sd(main_engine_fuel_oil_running$value, na.rm = TRUE)
          min_value = min(main_engine_fuel_oil_running$value)
          max_value = max(main_engine_fuel_oil_running$value)
          n = nrow(main_engine_fuel_oil_running)
          starttime = min(main_engine_fuel_oil_running$measurement_time)
          endtime = max(main_engine_fuel_oil_running$measurement_time)
          rm(main_engine_fuel_oil_running)
          gc()
        }
      }
    }
  }
  return_list = list(
    data_ok = data_ok,
    n = n,
    calculated_value = calculated_value,
    starttime = starttime,
    endtime = endtime,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
	err_msg = err_msg,
    visutype = "avg"
  )
  return(return_list)
}

#__________________________________________________
#calculated_value 19
#mainengine_fueloil_consumption_percentage
#wrapper function, uses general purpose calculate_percentage function

#testing
#calculate_mainengine_fueloil_consumption_percentage(dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_mainengine_fueloil_consumption_percentage = function(dbcon,
                                                               oitype,
                                                               oiids,
                                                               starttime = NULL,
                                                               endtime = NULL,
                                                               merged_data)
{
  return(
    calculate_percentage(
      dbcon,
      oitype,
      oiids,
      variable_part = "fueloil_consumption_main_engine",
      variable_all = "fueloil_consumption_total"  ,
      starttime = starttime,
      endtime = endtime
    )
  )
}

#__________________________________________________
#calculated_value 20
# mainengine_fueloil_steaming_percentage
# wrapper function, uses general purpose calculate_percentage function

# testing
#calculate_mainengine_fueloil_steaming_percentage(db=dbcon,oitype='ship',oiids=oiids_temp,starttime,endtime,merged_data)

#function
calculate_mainengine_fueloil_steaming_percentage = function(dbcon,
                                                            oitype,
                                                            oiids,
                                                            starttime = NULL,
                                                            endtime = NULL,
                                                            merged_data)
{
  result = calculate_percentage(
    dbcon,
    oitype,
    oiids,
    variable_part = "mainengine_fueloil_consumption_steaming",
    variable_all = "fueloil_consumption_main_engine"  ,
    starttime = starttime,
    endtime = endtime
  )
  
  return(result)
}


#__________________________________________________
#calculated_value 21
# mainengine_fueloil_consumption_steaming
#calculate_mainengine_fueloil_consumption_steaming(dbcon, oitype='ship',oiids=oiids_temp, starttime=NULL, endtime=NULL,merged_data,merged_data)


#function
calculate_mainengine_fueloil_consumption_steaming = function(dbcon,
                                                             oitype,
                                                             oiids,
                                                             starttime = NULL,
                                                             endtime = NULL,
                                                             merged_data)
{
  data_ok = TRUE
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  err_msg = ""
  fo_steaming = getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, "mainengine_fueloil_consumption_steaming")$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  
  
  if (nrow (fo_steaming) == 0) {
    #stop("OpenVA warning: mainengine_fueloil_consumption_steaming, no data for calculation")
    print(
      "OpenVA warning: mainengine_fueloil_consumption_steaming, no data for calculation"
    )
    data_ok = FALSE
    err_msg = "fo_cons_steaming: no data"
    calculated_value = NA
    #    starttime = min(fo_steaming$measurement_time)
    #    endtime = max(fo_steaming$measurement_time)
    n = 0
    rm(fo_steaming)
    gc()
  } else {
    n = nrow (fo_steaming)
    calculated_value = sum(fo_steaming$measurement_value)
    starttime = min(fo_steaming$measurement_time)
    endtime = max(fo_steaming$measurement_time)
    min_value = min(fo_steaming$measurement_value)
    max_value =  max(fo_steaming$measurement_value)
    rm(fo_steaming)
    gc()
  }
  result = list(
    data_ok = data_ok,
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    err_msg = err_msg,
    visutype = "sum"
  )
  return(result)
}

#__________________________________________________
#calculated_value 22
#mainengine_running_maneuvering_percentage

#testing
#calculate_mainengine_running_maneuvering_percentage(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_mainengine_running_maneuvering_percentage = function(dbcon,
                                                               oitype,
                                                               oiids,
                                                               starttime = NULL,
                                                               endtime = NULL,
                                                               merged_data)
{
  data_ok = TRUE
  n = 0
  calculated_value = NA
  err_msg = ""
  	
  #get maneuvering
  ship_maneuvering = getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, "ship_maneuvering")$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  if (nrow(ship_maneuvering) == 0) {
    data_ok = FALSE
    rm(ship_maneuvering)
    gc()
    #stop("OpenVA warning: no data for calculation")
    print("OpenVA warning: no data for calculation ")
    err_msg = "ship_maneuvering: no data"
  } else {
    #nrow(ship_maneuvering)
    #get main engine running
    if (nrow(merged_data) > 0) {
      mainengine_running <-
        data.frame(merged_data$measurement_time,
                   merged_data$mainengine_running)
      names(mainengine_running) <-
        c("measurement_time", "measurement_value")
    } else {
      mainengine_running = getVariableValues_partition(
        dbcon,
        variableid = getMetadata_bytitle(dbcon, "main_engine_running")$id,
        oiids,
        oitype = oitype,
        starttime = starttime,
        endtime = endtime,
        TRUE
      )[c("measurement_time", "measurement_value")]
    }
    
    #nrow(mainengine_running)
    if (nrow(mainengine_running) == 0) {
      #stop("OpenVA warning: no data for calculation")
      print("OpenVA warning: no data for calculation 1")
      err_msg = "mainengine_running: no data"
      data_ok = FALSE
      rm(ship_maneuvering)
      rm(mainengine_running)
      gc()
    } else {
      ship_maneuvering$measurement_time <-
        as.character(ship_maneuvering$measurement_time)
      mainengine_running$measurement_time <-
        as.character(mainengine_running$measurement_time)
      maneuvering_running = merge(ship_maneuvering,
                                  mainengine_running,
                                  by = "measurement_time")
      rm(ship_maneuvering)
      rm(mainengine_running)
      gc()
      n = nrow(maneuvering_running)
      #  head(maneuvering_running)
      if (n == 0) {
        #stop("OpenVA warning: no data for calculation")
        data_ok = FALSE
        print("OpenVA warning: no data for calculation x")
         err_msg = "maneuvering_running: no data"
      } else {
        maneuvering_running = maneuvering_running[, c("measurement_time",
                                                      "measurement_value.x",
                                                      "measurement_value.y")]
        colnames(maneuvering_running) = c("measurement_time", "maneuvering", "running")
        maneuvering_running_count = nrow(maneuvering_running[maneuvering_running$maneuvering ==  1 &
                                                               maneuvering_running$running == 1, ])
        mainengine_running_count = nrow(maneuvering_running[maneuvering_running$running ==   1, ])
        calculated_value = (maneuvering_running_count / mainengine_running_count) *   100
        starttime = min(maneuvering_running$measurement_time)
        endtime = max(maneuvering_running$measurement_time)
        
        rm(maneuvering_running)
        gc()
      }
    }
  }
  result = list(
    data_ok = data_ok,
    n = n,
    calculated_value = calculated_value,
    starttime = starttime,
    endtime = endtime,
    err_msg = err_msg,
    visutype = "%"
  )
  return(result)
}


#__________________________________________________
#calculated_value 24
#auxengines_fueloil_consumption_percentage
#wrapper function, uses general purpose calculate_percentage function

#testing
#calculate_auxengines_fueloil_consumption_percentage(dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_auxengines_fueloil_consumption_percentage = function(dbcon,
                                                               oitype,
                                                               oiids,
                                                               starttime = NULL,
                                                               endtime = NULL,
                                                               merged_data)
{
  return(
    calculate_percentage(
      dbcon,
      oitype,
      oiids,
      variable_part = "fueloil_consumption_aux_engine",
      variable_all = "fueloil_consumption_total"  ,
      starttime = starttime,
      endtime = endtime
    )
  )
  
}

#__________________________________________________
#calculated_value 25
#auxengines_load_percentage, individual aux engines
#Wrapper functions for each aux engine + general purpose function for calculation

#wrapper calculate_auxengine1_load_percentage
#testing
#calculate_auxengine1_load_percentage(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)
#NOT IN USE; MOVED TO INDICATORS
#function  NOT IN USE
calculate_auxengine1_load_percentage = function(dbcon,
                                                oitype,
                                                oiids,
                                                starttime = NULL,
                                                endtime = NULL,
                                                merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_load_percentage(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime
  )
  return(result)
}

#wrapper function for auxengine 2

#testing
#calculate_auxengine2_load_percentage(db=con,oiids='1',starttime=starttime,endtime=endtime,merged_data)

#function NOT IN USE
calculate_auxengine2_load_percentage = function(dbcon,
                                                oitype,
                                                oiids,
                                                starttime = NULL,
                                                endtime = NULL,
                                                merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_load_percentage(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime
  )
  return(result)
}

#wrapper function for auxengine 3

#testing
#calculate_auxengine3_load_percentage(db=con,oitype,oiids='1',starttime=NULL,endtime=NULL,merged_data)

#function NOT IN USE
calculate_auxengine3_load_percentage = function(dbcon,
                                                oitype,
                                                oiids,
                                                starttime = NULL,
                                                endtime = NULL,
                                                merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_load_percentage(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime
  )
  return(result)
}

#wrapper function for auxengine 4

#testing
#calculate_auxengine4_load_percentage(db=con,oiids='1',starttime=NULL,endtime=NULL,merged_data)

#function NOT IN USE
calculate_auxengine4_load_percentage = function(dbcon,
                                                oitype,
                                                oiids,
                                                starttime = NULL,
                                                endtime = NULL,
                                                merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_load_percentage(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime
  )
  return(result)
}

#wrapper function for auxengine 5

#testing
#calculate_auxengine5_load_percentage(db=con,oitype,oiids='1',starttime=starttime,endtime=endtime,merged_data)

#function NOT IN USE
calculate_auxengine5_load_percentage = function(dbcon,
                                                oitype,
                                                oiids,
                                                starttime = NULL,
                                                endtime = NULL,
                                                merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  
  #launch calculation
  result = calculate_auxengine_load_percentage(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime
  )
  return(result)
}


#____________________
#calculation function for auxengines_load_percentage
#note:all engines
#testing

#calculate_auxengines_load_percentage(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

calculate_auxengines_load_percentage = function(dbcon,
                                                oitype,
                                                oiids,
                                                starttime = NULL,
                                                endtime = NULL,
                                                merged_data)
{
  data_ok = TRUE
  err_msg = ""
  n = 0
  calculated_value = NA
  my_var = "DG_1_power"
  if (nrow(merged_data) > 0) {
    total_DG_power <-
      data.frame(merged_data$measurement_time,
                 merged_data$DG_1_power)
    names(fueloil_consumption) <-
      c("measurement_time", "measurement_value")
  } else {
	  total_DG_power = getVariableValues_partition(
	    dbcon,
	    variableid = getMetadata_bytitle(dbcon, my_var)$id,
	    oiids,
	    oitype = oitype,
	    starttime = starttime,
	    endtime = endtime,
	    TRUE
	  )
  }
  
  if (nrow(total_DG_power) == 0)
  {
    #stop("OpenVA varning: no data in the given time period")
    data_ok = FALSE
    err_msg = "total_DG_power: no data"
    rm(total_DG_power)
    gc()
  } else {
    total_DG_power = total_DG_power[, c("measurement_value", "measurement_time")]
    colnames(total_DG_power) = c(paste0("measurement_value.", 1),"measurement_time")
    for (i in 2:5)
    {
      new_title = paste("DG_", i, "_power", sep = "")
      if (nrow(merged_data) > 0) {
      	measu <- data.frame(merged_data$measurement_time,merged_data[[new_title]])
    	names(measu) <-c("measurement_time", "measurement_value")
  	  } else {
      	measu = getVariableValues_partition(
        		dbcon,
        		variableid = getMetadata_bytitle(dbcon, new_title)$id,
        		oiids,
        		oitype = oitype,
        		starttime = starttime,
        		endtime = endtime,
        	TRUE
      	)
      }
      if (nrow(measu) == 0) {
        	total_DG_power[, paste0("measurement_value.", i)] = NA
      } else {
        	measu = measu[, c("measurement_value", "measurement_time")]
        	colnames(measu) = c(paste0("measurement_value.", i),"measurement_time")
        	total_DG_power = merge(total_DG_power,measu,by =c("measurement_time"))
      }
    }
    rm(measu)
    gc()
    if (nrow(total_DG_power) == 0)
    {
      #stop("OpenVA varning: no data in the given time period")
      data_ok = FALSE
      err_msg = "total_DG_power: no data"
      rm(total_DG_power)
      gc()
    } else {
      n = nrow(total_DG_power)
      total_DG_power$DG_value = total_DG_power$measurement_value.1 / 960 +
        total_DG_power$measurement_value.2 / 960 + total_DG_power$measurement_value.3 /
        960 +
        total_DG_power$measurement_value.4 / 960 + total_DG_power$measurement_value.5 /
        768
      calculated_value = mean(total_DG_power$DG_value) * 100
      starttime = min(total_DG_power$measurement_time)
      endtime = max(total_DG_power$measurement_time)
      rm(total_DG_power)
      gc()
    }
  }
  result = list(
    data_ok = data_ok,
    n = n,
    calculated_value = calculated_value,
    starttime = starttime,
    endtime = endtime,
    err_msg = err_msg,
    visutype = "%"
  )
  return(result)
}

#__________________________________________________
#calculated_value 28
#calculate_fueloil_consumption_aux_engine_avg
#calculate_fueloil_consumption_aux_engine_avg(dbcon, oitype='ship', oiids=oiids_temp,starttime = NULL, endtime = NULL,merged_data)

#function
calculate_fueloil_consumption_aux_engine_avg = function(dbcon,
                                                        oitype,
                                                        oiids,
                                                        starttime = NULL,
                                                        endtime = NULL
                                                        ,
                                                        merged_data)
{
  data_ok = TRUE
  err_msg = ""
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  n = NA
  
  if (nrow(merged_data) > 0) {
    fueloil_consumption <-
      data.frame(merged_data$measurement_time,
                 merged_data$ae_fo_consumption)
    names(fueloil_consumption) <-
      c("measurement_time", "measurement_value")
  } else {
    fueloil_consumption = getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "AE_FO_consumption")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )[c("measurement_time", "measurement_value")]
  }
  if (nrow (fueloil_consumption) == 0) {
    data_ok = FALSE
    err_msg = "fueloil_consumption: no data"
    rm(fueloil_consumption)
    gc()
    #stop("OpenVA warning: fueloil_consumption, no data for calculation")
    print("OpenVA warning: fueloil_consumption, no data for calculation")
  } else {
    n = nrow (fueloil_consumption)
    calculated_value = mean(fueloil_consumption$measurement_value)
    sd_value = mean(fueloil_consumption$measurement_value)
    min_value = min(fueloil_consumption$measurement_value)
    max_value = max(fueloil_consumption$measurement_value)
    starttime = min(fueloil_consumption$measurement_time)
    endtime = max(fueloil_consumption$measurement_time)
    rm(fueloil_consumption)
    gc()
    
  }
  result = list(
    data_ok = data_ok,
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    err_msg = err_msg,
    visutype = "avg"
  )
  return(result)
}

#__________________________________________________
#calculated_value 29
#calculate_auxiliary_power_total
# calculate value between the given time period

#testing
#calculate_auxiliary_power_total(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_auxiliary_power_total = function(dbcon,
                                           oitype,
                                           oiids,
                                           starttime = NULL,
                                           endtime = NULL
                                           ,
                                           merged_data)
{
  auxiliary_power_total = hourly_values(dbcon,
                                        oitype,
                                        oiids,
                                        "auxiliary_power_total",
                                        "avg",
                                        starttime,
                                        endtime)
  
  return(auxiliary_power_total)
}


# NOTE this is really average, not percentage (source: Zigor's excel)
#__________________________________________________
#calculated_value 30
#auxiliary_power_of_load_percentage
#testing
#calculate_auxiliary_power_of_load_percentage(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=starttime,endtime=endtime,merged_data)

#function
calculate_auxiliary_power_of_load_percentage = function(dbcon,
                                                        oitype,
                                                        oiids,
                                                        starttime = NULL,
                                                        endtime = NULL,
                                                        merged_data)
{
  data_ok = TRUE
  err_msg = ""
  n = 0
  sd_value = NA
  min_value = NA
  max_value = NA
  calculated_value = NA
  
  
  total_available_auxiliary_power = getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, "auxengines_running_hours")$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  
  if (nrow(total_available_auxiliary_power) == 0) {
    data_ok = FALSE
	err_msg = "auxengines_running_hours: no data"
    rm(total_available_auxiliary_power)
    gc()
  } else {
    total_auxiliary_power = getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "auxengines_energy_generated")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )
    
    if (nrow(total_auxiliary_power) == 0)
    {
      #stop("OpenVA warning: no data for calculation")
      data_ok = FALSE
      err_msg = "auxengines_energy_generated: no data"
      rm(total_available_auxiliary_power)
      rm(total_auxiliary_power)
      gc()
    } else {
      n = nrow(total_auxiliary_power)
      
      if (sum(total_available_auxiliary_power$measurement_value) == 0)
      {
        #stop("OpenVA warning: no data for calculation")
        err_msg = "sum(total_available_aux_power) == 0"
        data_ok = FALSE
        rm(total_available_auxiliary_power)
        rm(total_auxiliary_power)
        gc()
      } else {
        calculated_value =
          auxiliary_power_of_load_average = sum(total_auxiliary_power$measurement_value) /
          sum(total_available_auxiliary_power$measurement_value)
        starttime = min(total_auxiliary_power$measurement_time)
        endtime = max(total_auxiliary_power$measurement_time)
        min_value = min(
          total_auxiliary_power$measurement_value / total_available_auxiliary_power$measurement_value
        )
        max_value = max(
          total_auxiliary_power$measurement_value / total_available_auxiliary_power$measurement_value
        )
        rm(total_available_auxiliary_power)
        rm(total_auxiliary_power)
        gc()
      }
      
    }
    
  }
  result = list(
    data_ok = data_ok,
    n = n,
    calculated_value = calculated_value,
    starttime = starttime,
    endtime = endtime,
    sd_value = NA,
    min_value = min_value,
    max_value = max_value,
    err_msg = err_msg,
    visutype = "avg"
  )
  
  return(result)
}
#

#__________________________________________________
#calculated_value 32
#calculate_auxengines_running_hours
# calculate value between the given time period

#testing
#calculate_auxengines_running_hours(db=dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengines_running_hours = function(dbcon,
                                              oitype,
                                              oiids,
                                              starttime = NULL,
                                              endtime = NULL
                                              ,
                                              merged_data)
{
  auxengines_running_hours = hourly_values(dbcon,
                                           oitype,
                                           oiids,
                                           "auxengines_running_hours",
                                           "sum",
                                           starttime,
                                           endtime)
  
  return(auxengines_running_hours)
}


# calculate_auxengines_energy_generated
#calculate_auxengines_energy_generated(dbcon,oitype='ship', oiids=oiids_temp,  starttime = NULL,  endtime = NULL)

calculate_auxengines_energy_generated = function(dbcon,
                                                 oitype,
                                                 oiids,
                                                 starttime = NULL,
                                                 endtime = NULL
                                                 ,
                                                 merged_data) {
  data_ok = TRUE
  err_msg = ""
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  n=NA
  energy_generated = getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, "auxengines_energy_generated")$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  
  
  if (nrow(energy_generated) == 0) {
    data_ok = FALSE
    err_msg = "energy_generated: no data"
    rm(energy_generated)
    gc()
    #stop("OpenVA warning: energy_generated, no data for calculation")
    print("OpenVA warning: energy_generated, no data for calculation")
  } else {
    n = nrow (energy_generated)
    calculated_value = sum(energy_generated$measurement_value)
    starttime = min(energy_generated$measurement_time)
    endtime = max(energy_generated$measurement_time)
    rm(energy_generated)
    gc()
  }
  result = list(
    data_ok = data_ok,
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    err_msg = err_msg,
    visutype = "sum"
  )
  return(result)
  
}

#calculate_auxengine_energy_generated(dbcon,  oitype='ship', oiids=oiids_temp,aux_nbr=1,starttime = NULL, endtime = NULL,merged_data)
#function
calculate_auxengine_energy_generated = function(dbcon,
                                                oitype,
                                                oiids,
                                                aux_nbr,
                                                starttime = NULL,
                                                endtime = NULL,
                                                merged_data)
{
  data_ok = TRUE
  err_msg = ""
  calculated_value = NA
  variable_title = paste("auxengine", aux_nbr, "_energy_generated", sep = "")
  energy_generated = getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, variable_title)$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  
  if (nrow (energy_generated) == 0) {
    #stop("OpenVA warning: energy_generated, no data for calculation")
    print("OpenVA warning: energy_generated, no data for calculation")
    data_ok = FALSE
    err_msg = paste(variable_title, ": no data", sep = "")
    sd_value = NA
    min_value = NA
    max_value = NA
    rm(energy_generated)
    n = 0
    gc()
  } else {
    n = nrow (energy_generated)
    calculated_value = sum(energy_generated$measurement_value)
    sd_value = NA
    min_value = NA
    max_value = NA
    starttime = min(energy_generated$measurement_time)
    endtime = max(energy_generated$measurement_time)
    rm(energy_generated)
    gc()
  }
  result = list(
    data_ok = data_ok,
    err_msg = err_msg,
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "sum"
  )
  return(result)
}

#calculate_auxengine1_energy_generated(dbcon,  oitype='ship',oiids=oiids_temp, starttime = NULL, endtime = NULL,merged_data)
calculate_auxengine1_energy_generated = function(dbcon,
                                                 oitype,
                                                 oiids,
                                                 starttime = NULL,
                                                 endtime = NULL,
                                                 merged_data) {                                               
                                                 
                                                 
  result = calculate_auxengine_energy_generated(dbcon,
                                                oitype,
                                                oiids,
                                                1,
                                                starttime = starttime,
                                                endtime = endtime,
    											merged_data)
  
  return(result)
}
#calculate_auxengine2_energy_generated(dbcon,  oitype='ship',oiids=oiids_temp, starttime = NULL, endtime = NULL,merged_data)

calculate_auxengine2_energy_generated = function(dbcon,
                                                 oitype,
                                                 oiids,
                                                 starttime = NULL,
                                                 endtime = NULL
                                                 ,
                                                 merged_data) {
  result = calculate_auxengine_energy_generated(dbcon,
                                                oitype,
                                                oiids,
                                                2,
                                                starttime = starttime,
                                                endtime = endtime,
    											merged_data)
  return(result)
}

#calculate_auxengine3_energy_generated(dbcon,  oitype='ship',oiids=oiids_temp, starttime = NULL, endtime = NULL,merged_data)

calculate_auxengine3_energy_generated = function(dbcon,
                                                 oitype,
                                                 oiids,
                                                 starttime = NULL,
                                                 endtime = NULL,
                                                 merged_data) {
  result = calculate_auxengine_energy_generated(dbcon,
                                                oitype,
                                                oiids,
                                                3,
                                                starttime = starttime,
                                                endtime = endtime,
    											merged_data)
  return(result)
}
#calculate_auxengine4_energy_generated(dbcon,  oitype='ship',oiids=oiids_temp, starttime = NULL, endtime = NULL)

calculate_auxengine4_energy_generated = function(dbcon,
                                                 oitype,
                                                 oiids,
                                                 starttime = NULL,
                                                 endtime = NULL,
                                                 merged_data) {
  result = calculate_auxengine_energy_generated(dbcon,
                                                oitype,
                                                oiids,
                                                4,
                                                starttime = starttime,
                                                endtime = endtime,
    											merged_data)
  return(result)
}
#calculate_auxengine5_energy_generated(dbcon,  oitype='ship',oiids=oiids_temp, starttime = NULL, endtime = NULL,merged_data)

calculate_auxengine5_energy_generated = function(dbcon,
                                                 oitype,
                                                 oiids,
                                                 starttime = NULL,
                                                 endtime = NULL,
                                                 merged_data) {
  result = calculate_auxengine_energy_generated(dbcon,
                                                oitype,
                                                oiids,
                                                5,
                                                starttime = starttime,
                                                endtime = endtime,
    											merged_data)
  return(result)
}


#__________________________________________________
#calculated_value 34
#auxengine_power_average
#Wrapper functions for each aux engine + general purpose function for auxengine power calculation

#wrapper calculate_auxengine1_power_average

#testing
#calculate_auxengine1_power_average(dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengine1_power_average = function(dbcon,
                                              oitype,
                                              oiids,
                                              starttime = NULL,
                                              endtime = NULL,
                                              merged_data)
{
  #identify auxengine number
  
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_power_average(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime,
    merged_data
  )
  return(result)
}

#wrapper calculate_auxengine2_power_average

#testing
#calculate_auxengine2_power_average(dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengine2_power_average = function(dbcon,
                                              oitype,
                                              oiids,
                                              starttime = NULL,
                                              endtime = NULL,
                                              merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_power_average(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime,
    merged_data
  )
  return(result)
}

#wrapper calculate_auxengine3_power_average

#testing
#calculate_auxengine3_power_average(dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengine3_power_average = function(dbcon,
                                              oitype,
                                              oiids,
                                              starttime = NULL,
                                              endtime = NULL,
                                              merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_power_average(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime,
    merged_data
  )
  return(result)
}

#wrapper calculate_auxengine4_power_average

#testing
#calculate_auxengine4_power_average(dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengine4_power_average = function(dbcon,
                                              oitype,
                                              oiids,
                                              starttime = NULL,
                                              endtime = NULL,
                                              merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_power_average(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime,
    merged_data
  )
  return(result)
}

#wrapper calculate_auxengine5_power_average

#testing
#calculate_auxengine5_power_average(dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengine5_power_average = function(dbcon,
                                              oitype,
                                              oiids,
                                              starttime = NULL,
                                              endtime = NULL,
                                              merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_power_average(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime,
    merged_data
  )
  return(result)
}

#general purpose function for auxengine_power_average

#testing
#calculate_auxengine_power_average(db=dbcon,oitype='ship',oiids=oiids_temp,auxengine=5,starttime=NULL,endtime=NULL,merged_data)

calculate_auxengine_power_average = function(dbcon,
                                             oitype,
                                             oiids,
                                             auxengine,
                                             starttime = starttime,
                                             endtime = endtime,
                                             merged_data)
{
  data_ok = TRUE
  err_msg = ""
  delta_t = 10
  n = 0
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  
  total_variable = paste("DG_", auxengine, "_power", sep = "")
  #get auxengine_power_total
   if (nrow(merged_data) > 0) {
    auxengine_power_total <-
      data.frame(merged_data$measurement_time,
                 merged_data[[total_variable]])
    names(auxengine_power_total) <-
      c("measurement_time", "measurement_value")
  } else {
  	auxengine_power_total =
    	getVariableValues_partition(
      	dbcon,
      	variableid = getMetadata_bytitle(dbcon, total_variable)$id,
      	oiids,
      	oitype = oitype,
      	starttime = starttime,
      	endtime = endtime,
      	TRUE
       )[, c("oi_id", "measurement_time", "measurement_value")]
  }
    
  if (nrow(auxengine_power_total) == 0) {
    #stop("OpenVA warning: no data for calculation, auxengine_power_total")
    data_ok = FALSE
    err_msg = "ae_power_total: no data"
    rm(auxengine_power_total)
    gc()
  } else {
    #get engine on
    aux_variable = paste("DG_", auxengine, "_condition", sep = "")
    if (nrow(merged_data) > 0) {
    	auxengine_condition <-
      		data.frame(merged_data$measurement_time,merged_data[[aux_variable]])
    		names(auxengine_condition) <- c("measurement_time", "measurement_value")
  	} else {
	    auxengine_condition =
	      getVariableValues_partition(
	        dbcon,
	        variableid = getMetadata_bytitle(dbcon, aux_variable)$id,
	        oiids,
	        oitype = oitype,
	        starttime = starttime,
	        endtime = endtime,
	        TRUE
	      )[, c("measurement_time", "measurement_value")]
	 }       
    if (nrow(auxengine_condition) == 0) {
      data_ok = FALSE
      err_msg = "auxengine_condition: no data"
      rm(auxengine_power_total)
      rm(auxengine_condition)
      gc()
      #stop("OpenVA warning: no data for calculation, auxengine_condition")
    } else {
      auxengine_power_merged = merge(
        auxengine_power_total,
        auxengine_condition,
        by = c("measurement_time")
      )
      auxengine_power_merged = auxengine_power_merged[, c("measurement_time",
                                                "measurement_value.x",
                                                "measurement_value.y")]
      rm(auxengine_power_total)
      rm(auxengine_condition)
      gc()
      if (nrow(auxengine_power_merged) == 0) {
        #stop("OpenVA warning: no data for calculation, auxengine_power_merged")
        err_msg = "auxengine_power_condition: no data"
        data_ok = FALSE
      } else {
        colnames(auxengine_power_merged) = c("measurement_time",
                                             "power_total",
                                             "condition")
        engine_on = auxengine_power_merged[auxengine_power_merged$condition == 1,]
        n = nrow(engine_on)
        if (n == 0) {
          #stop("OpenVA warning: no data for calculation,n")
          err_msg = "engine_on: no data"
          print(err_msg)
          data_ok = FALSE
          rm(engine_on)
          rm(auxengine_power_merged)
          gc()
        } else {
          calculated_value = mean(engine_on[, "power_total"], na.rm = TRUE)
          
          sd_value = sd(engine_on[, "power_total"], na.rm = TRUE)
          min_value = min(engine_on[, "power_total"], na.rm = TRUE)
          max_value = max(engine_on[, "power_total"], na.rm = TRUE)
          starttime = min(auxengine_power_merged$measurement_time)
          endtime = max(auxengine_power_merged$measurement_time)
          rm(auxengine_power_merged)
          rm(engine_on)
          gc()
        }
      }
    }
  }
  return(
    list(
      data_ok = data_ok,
      err_msg = err_msg,
      n = n,
      calculated_value = calculated_value,
      starttime = starttime,
      endtime = endtime,
      sd_value = sd_value,
      min_value = min_value,
      max_value = max_value,
      endtime = endtime,
      visutype = "avg"
    )
  )
}

#__________________________________________________
#calculated_value 35
#auxengines_load_average
# note: percentage despite the name 
#Wrapper functions for each aux engine + general purpose function for calculation

#wrapper calculate_auxengine1_load_average
#testing
#calculate_auxengine1_load_average(dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengine1_load_average = function(dbcon,
                                             oitype,
                                             oiids,
                                             starttime = NULL,
                                             endtime = NULL,
                                             merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_load_average(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime,
    merged_data
  )
  return(result)
}

#wrapper function for auxengine 2

#testing
#calculate_auxengine2_load_average(dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengine2_load_average = function(dbcon,
                                             oitype,
                                             oiids,
                                             starttime = NULL,
                                             endtime = NULL,
                                             merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_load_average(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime,
    merged_data
  )
  return(result)
}

#wrapper function for auxengine 3

#testing
#calculate_auxengine3_load_average(dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengine3_load_average = function(dbcon,
                                             oitype,
                                             oiids,
                                             starttime = NULL,
                                             endtime = NULL,
                                             merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_load_average(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime,
    merged_data
  )
  return(result)
}

#wrapper function for auxengine 4

#testing
#calculate_auxengine4_load_average(dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengine4_load_average = function(dbcon,
                                             oitype,
                                             oiids,
                                             starttime = NULL,
                                             endtime = NULL,
                                             merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_load_average(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime,
    merged_data
  )
  return(result)
}

#wrapper function for auxengine 5

#testing
#calculate_auxengine5_load_average(dbcon,oitype='ship',oiids=oiids_temp,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengine5_load_average = function(dbcon,
                                             oitype,
                                             oiids,
                                             starttime = NULL,
                                             endtime = NULL,
                                             merged_data)
{
  #identify auxengine number
  my_function = (match.call()[[1]])
  ae_number = unique(as.numeric(unlist(strsplit(
    gsub("[^0-9]", "", (my_function)), ""
  ))))
  #launch calculation
  result = calculate_auxengine_load_average(
    dbcon,
    oitype,
    oiids,
    auxengine = ae_number,
    starttime = starttime,
    endtime = endtime,
    merged_data
  )
  return(result)
}

#calculation function for auxengines_load_average

#testing
#calculate_auxengine_load_average(db=dbcon,oitype='ship',oiids=oiids_temp, auxengine=1,starttime=NULL,endtime=NULL,merged_data)

#function
calculate_auxengine_load_average = function(dbcon,
                                            oitype,
                                            oiids,
                                            auxengine,
                                            starttime = NULL,
                                            endtime = NULL,
                                            merged_data)
{
  data_ok = TRUE

  n = 0
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  return_values = calculate_auxengine_power_average(
    dbcon,
    oitype,
    oiids,
    auxengine = auxengine,
    starttime = starttime,
    endtime = endtime,
    merged_data
  )
  #calculate
  
  data_ok = return_values$data_ok
  if (data_ok) {
    n = return_values$n
    power_average = return_values$calculated_value
    starttime = return_values$starttime
    endtime = return_values$endtime
    pover_sd = return_values$sd_value
    pover_min = return_values$min_value
    pover_max = return_values$max_value
    if (any(c(1:4) == auxengine))
    {
      calculated_value = (power_average / 960) * 100
      sd_value = (pover_sd / 960) * 100
      min_value = (pover_min / 960) * 100
      max_value = (pover_max / 960) * 100
    } else {
      calculated_value = (power_average / 768) * 100
      sd_value = (pover_sd / 768) * 100
      min_value = (pover_min / 768) * 100
      max_value = (pover_max / 768) * 100
    }
  }
  return(
    list(
      data_ok = data_ok,
	  err_msg = return_values$err_msg,
      n = n,
      calculated_value = calculated_value,
      starttime = starttime,
      endtime = endtime,
      sd_value = sd_value,
      min_value = min_value,
      max_value = max_value,
      visutype = "avg"
    )
  )
}



#calculation function for auxengines_load_average,all  engines
#calculate_auxengines_load_average (dbcon,oitype='ship', oiids=oiids_temp, starttime = NULL, endtime = NULL,merged_data)

# note: percentage despite the name
calculate_auxengines_load_average = function(dbcon,
                                             oitype,
                                             oiids,
                                             starttime = NULL,
                                             endtime = NULL,
                                             merged_data)
{
  data_ok = TRUE
  err_msg = ""
  n = 0
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  #first auxengine
  my_var = "DG_1_condition"
  total_load_average = getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, my_var)$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  if (nrow(total_load_average) == 0) {
    #stop("OpenVA varning: no data in the given time period")
    data_ok = FALSE
    rm(total_load_average)
    gc()
  } else {
    #head(total_load_average)
    
    total_load_average = total_load_average[, c("measurement_value", "measurement_time")]
    colnames(total_load_average) = c(paste0("measurement_value.", 1), "measurement_time")
    #other aux engines
    for (i in 2:5)
    {
      new_title = paste("DG_", i, "_condition", sep = "")
      if (nrow(merged_data) > 0) {
    		measu <-
      			data.frame(merged_data$measurement_time,merged_data[[new_title]])
    		names(measu) <- c("measurement_time", "measurement_value")
  	  } else {
	      measu = getVariableValues_partition(
	        dbcon,
	        variableid = getMetadata_bytitle(dbcon, new_title)$id,
	        oiids,
	        oitype = oitype,
	        starttime = starttime,
	        endtime = endtime,
	        TRUE
	      )
	  }
      if (nrow(measu) == 0) {
        #stop("OpenVA varning: no data in the given time period")
        total_load_average[, paste0("measurement_value.", i)] = NA
      } else {
        #head(measu)
        measu = measu[, c("measurement_value", "measurement_time")]
        colnames(measu) = c(paste0("measurement_value.", i), "measurement_time")
        total_load_average = merge(total_load_average, measu, by = c("measurement_time"))
      }
    }
    if (nrow(total_load_average) == 0)
    {
      data_ok = FALSE
      err_msg = "total_load_average: no data" 
      rm(total_load_average)
      gc()
    } else {
      delta_t = 10
      
      sum_load_average <-
        ((
          total_load_average$measurement_value.1 + total_load_average$measurement_value.2 + total_load_average$measurement_value.3 +
            total_load_average$measurement_value.4
        ) * 960 + total_load_average$measurement_value.5 * 768
        ) * delta_t / 3600
      
      
      total_load_average$max_available_AE_en = ((
        total_load_average$measurement_value.1 + total_load_average$measurement_value.2 + total_load_average$measurement_value.3
        + total_load_average$measurement_value.4
      ) * 960 + total_load_average$measurement_value.5 * 768
      ) * delta_t / 3600
      total_energy_available = sum(total_load_average$max_available_AE_en)
      my_var = "auxengines_energy_generated"
      AE_kwh_tot = getVariableValues_partition(
        dbcon,
        variableid = getMetadata_bytitle(dbcon, my_var)$id,
        oiids,
        oitype = oitype,
        starttime = starttime,
        endtime = endtime,
        TRUE
      )
      
      if (nrow(AE_kwh_tot) == 0)
      {
        data_ok = FALSE
        #stop("OpenVA varning: no data in the given time period")
        err_msg = "AE_kwh_tot: no data" 
        rm(total_load_average)
        rm(AE_kwh_tot)
        gc()
      } else {
        calculated_value = 100 * sum(AE_kwh_tot$measurement_value) / total_energy_available
        
        n = nrow(AE_kwh_tot)
        rm(total_load_average)
        rm(AE_kwh_tot)
        gc()
      }
    }
  }
  return_list = list(
    data_ok = data_ok,
    err_msg = err_msg,
    n = n,
    calculated_value = calculated_value,
    starttime = starttime,
    endtime = endtime,
    sd_value = NA,
    min_value = 0,
    max_value = 100,
    visutype = "avg"
  )
  return(return_list)
}


###############################################################################################
#calculate_ship_steaming_distance
#calculate_ship_steaming_distance(dbcon,  oitype='ship',oiids=oiids_temp,starttime = NULL, endtime = NULL,merged_data)

calculate_ship_steaming_distance = function(dbcon,
                                            oitype,
                                            oiids,
                                            starttime = NULL,
                                            endtime = NULL,
                                            merged_data) {
  data_ok = TRUE
  err_msg = ""
  n = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  calculated_value = NA
  if (nrow(merged_data) > 0) {
    	ship_steaming_distance <- data.frame(merged_data$measurement_time, merged_data$ship_steaming_distance)
    	names(ship_steaming_distance) <- c("measurement_time", "measurement_value")
  } else {
	  ship_steaming_distance = getVariableValues_partition(
	    dbcon,
	    variableid = getMetadata_bytitle(dbcon, "ship_steaming_distance")$id,
	    oiids,
	    oitype = oitype,
	    starttime = starttime,
	    endtime = endtime,
	    TRUE
	  )
  }
  if (nrow (ship_steaming_distance) == 0) {
    data_ok = FALSE
    err_msg = "ship_steaming_distance: no data"
    rm(ship_steaming_distance)
    gc()
    #stop("OpenVA warning: ship_steaming_distance, no data for calculation")
  } else {
    n = nrow (ship_steaming_distance)
    calculated_value = sum(ship_steaming_distance$measurement_value)
    starttime = min(ship_steaming_distance$measurement_time)
    endtime = max(ship_steaming_distance$measurement_time)
    rm(ship_steaming_distance)
    gc()
  }
  result = list(
    data_ok = data_ok,
    err_msg = err_msg,
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "sum"
  )
  return(result)
}

#####################################################################
#calculate_fueloil_consumption_total_h
#calculate_fueloil_consumption_total_h(dbcon, oitype='ship',  oiids=oiids_temp, starttime = NULL, endtime = NULL,merged_data)
calculate_fueloil_consumption_total_h = function(dbcon,
                                                 oitype,
                                                 oiids,
                                                 starttime = NULL,
                                                 endtime = NULL,
                                                 merged_data) {
  calculated_value = NA
  err_msg = ""
  data_ok = TRUE
      n = NA
    sd_value = NA
    min_value = NA
    max_value = NA
  
  
  if (nrow(merged_data) > 0) {
    fueloil_consumption_total <-
      data.frame(merged_data$measurement_time,
                 merged_data$fueloil_consumption_total)
    names(fueloil_consumption_total) <-
      c("measurement_time", "measurement_value")
  } else {
    fueloil_consumption_total = getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "fueloil_consumption_total")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )[c("measurement_time", "measurement_value")]
  }
  n = nrow (fueloil_consumption_total)
  if (n == 0) {
    #stop("OpenVA warning: fueloil_consumption_total, no data for calculation")
    print("OpenVA warning: fueloil_consumption_total, no data for calculation")
    data_ok = FALSE
    err_msg = "fo_consumption_total: no data"
  } else {
  
  	starttime = min(fueloil_consumption_total$measurement_time)
  	endtime = max(fueloil_consumption_total$measurement_time)
  
  	# time in hours (10 sec interval)
  	time = n / 360
  
  
  	# this would be total time but there may be missing data
  	#time = as.numeric(difftime(endtime, starttime, units="hour"))
  
  
  
  	if (time != 0) {
    	calculated_value = sum(fueloil_consumption_total$measurement_value) / time
  	} else {
    	calculated_value = 0
  	}
  	sd_value = 0
  	min_value = 0
  	max_value = calculated_value * 2
  }
  
  result = list(
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "avg",
    err_msg = err_msg,
    data_ok = data_ok
  )
  return(result)
}

calculate_fueloil_consumption_total_sum = function(dbcon,
                                                   oitype,
                                                   oiids,
                                                   starttime = NULL,
                                                   endtime = NULL,
                                                   merged_data) {
  calculated_value = NA
  data_ok = TRUE
  
  
  if (nrow(merged_data) > 0) {
    fueloil_consumption_total <-
      data.frame(merged_data$measurement_time,
                 merged_data$fueloil_consumption_total)
    names(fueloil_consumption_total) <-
      c("measurement_time", "measurement_value")
  } else  {
    fueloil_consumption_total = getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "fueloil_consumption_total")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )
  }
  
  n = nrow (fueloil_consumption_total)
  if (n == 0) {
    #stop("OpenVA warning: fueloil_consumption_total, no data for calculation")
    data_ok = FALSE
    calculated_value = NA
  }
  
  starttime = min(fueloil_consumption_total$measurement_time)
  endtime = max(fueloil_consumption_total$measurement_time)
  
  # time in hours (10 sec interval)
  
  # this would be total time but there may be missing data
  #time = as.numeric(difftime(endtime, starttime, units="hour"))
  
  calculated_value = sum(fueloil_consumption_total$measurement_value)
  sd_value = 0
  min_value = 0
  max_value = calculated_value * 2
  
  
  result = list(
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "sum",
    data_ok = data_ok
  )
  return(result)
}


#####################################################################################
#calculate_auxengines_fueloil_consumption_steaming (dbcon, oitype='ship',oiids=oiids_temp, starttime = NULL, endtime = NULL,merged_data)


calculate_auxengines_fueloil_consumption_steaming  = function(dbcon,
                                                              oitype,
                                                              oiids,
                                                              starttime = NULL,
                                                              endtime = NULL,
                                                              merged_data)
{
  data_ok = TRUE
  err_msg = ""
  n = 0
  calculated_value = NA
  min_value = NA
  max_value = NA
  sd_value = NA
  #get main engine running
  consumption_steaming = getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, "auxengines_fueloil_consumption_steaming")$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  
  if (nrow(consumption_steaming) == 0) {
    #stop("OpenVA warning: no data for calculation")
    data_ok = FALSE
    err_msg = "consumption_steaming: no data"
    rm(consumption_steaming)
    gc()
  } else {
    n = nrow(consumption_steaming)
    starttime = min(consumption_steaming$measurement_time)
    endtime = max(consumption_steaming$measurement_time)
    calculated_value = sum(consumption_steaming$measurement_value)
    rm(consumption_steaming)
    gc()
  }
  
  return(
    list(
      data_ok = data_ok,
      err_msg = err_msg,
      n = n,
      calculated_value = calculated_value,
      starttime = starttime,
      endtime = endtime,
      sd_value = sd_value,
      min_value = min_value,
      max_value = max_value,
      visutype = "sum"
    )
  )
}

#__________________________________________________________________
#general purpose function for percentance calculation
#
#Testing
#calculate_percentage(db=dbcon,oitype='ship',oiids=oiids_temp,variable_part="ME_FO_consumption",variable_all= "fueloil_consumption_total"  ,starttime=starttime,endtime=endtime,merged_data)

calculate_percentage = function(dbcon,
                                oitype,
                                oiids,
                                variable_part,
                                variable_all,
                                starttime = NULL,
                                endtime = NULL,
                                merged_data)
{
  data_ok = TRUE
  err_msg = ""
  n = 0
  calculated_value = NA
  
  variable_part_value = getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, variable_part)$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  
  
  #head(variable_part_value)
  if (nrow(variable_part_value) == 0)
  {
    data_ok = FALSE
    err_msg = "no data"
    rm(variable_part_value)
    gc()
    #stop("OpenVA warning: no data for calculation")
  } else {
    variable_all_value = getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, variable_all)$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )
    #head(variable_all_value)
    if (nrow(variable_all_value) == 0)
    {
      data_ok = FALSE
      
      rm(variable_part_value)
      rm(variable_all_value)
      gc()
      #stop("OpenVA warning: no data for calculation")
    } else {
      if (min(nrow(variable_all_value), nrow(variable_part_value)) == 0) {
        data_ok = FALSE
        err_msg = "no data"
        rm(variable_part_value)
        rm(variable_all_value)
        gc()
        #stop("OpenVA warning: no data for calculation")
      } else {
        n = max(nrow(variable_all_value), nrow(variable_part_value))
        variable_part_sum = sum(variable_part_value$measurement_value)
        variable_all_sum = sum(variable_all_value$measurement_value)
        if (variable_all_sum > 0)
        {
          calculated_value = (variable_part_sum / variable_all_sum) * 100
          starttime = min(variable_all_value$measurement_time)
          endtime = max(variable_all_value$measurement_time)
        } else {
          data_ok = FALSE
          err_msg = "no data"
        }
        rm(variable_part_value)
        rm(variable_all_value)
        gc()
      }
    }
  }
  return(
    list(
      data_ok = data_ok,
      err_msg = err_msg,
      n = n,
      calculated_value = calculated_value,
      starttime = starttime,
      endtime = endtime,
      visutype = "%",
      data_ok = TRUE
    )
  )
}

calculate_sog_steam_avg = function(dbcon,
                                   oitype,
                                   oiids,
                                   starttime = NULL,
                                   endtime = NULL,
                                   merged_data) {
  n = 0
  calculated_value = NA
  err_msg = ""
  data_ok = TRUE
  sd_value = NA
  min_value = NA
  max_value = NA
  #get speed on steaming
  ship_speed_actual =
    getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "ship_speed_actual")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )[c("measurement_time", "measurement_value")]
  
  
  n = nrow(ship_speed_actual)
  if (n == 0) {
    #stop("OpenVA warning: ship_speed_actual, no data for calculation")
    print("OpenVA warning: ship_speed_actual, no data for calculation")
    data_ok = FALSE
    err_msg = "ship_speed_actual: no data"
  } else {
    if (nrow(merged_data) > 0) {
      ship_steaming <-
        data.frame(merged_data$measurement_time,
                   merged_data$ship_steaming)
      names(ship_steaming) <-
        c("measurement_time", "measurement_value")
    } else {
      ship_steaming =
        getVariableValues_partition(
          dbcon,
          variableid = getMetadata_bytitle(dbcon, "ship_steaming")$id,
          oiids,
          oitype = oitype,
          starttime = starttime,
          endtime = endtime,
          TRUE
        )[c("measurement_time", "measurement_value")]
    }
    n = nrow(ship_steaming)
    if (n == 0) {
      #stop("OpenVA warning: ship_steaming no data for calculation")
      print("OpenVA warning: ship_steaming no data for calculation")
      data_ok = FALSE
      err_msg = "ship_steaming: no data"
    } else {
      ship_steaming <-
        ship_steaming[ship_steaming$measurement_value == 1, ]
      
      ship_speed_actual$measurement_time <-
        as.character(ship_speed_actual$measurement_time)
      ship_steaming$measurement_time <-
        as.character(ship_steaming$measurement_time)
      
      speed_steaming = merge(ship_speed_actual,
                             ship_steaming,
                             "measurement_time")
      
      calculated_value = mean(speed_steaming$measurement_value.x)
      sd_value = sd(speed_steaming$measurement_value.x)
      min_value = min(speed_steaming$measurement_value.x)
      max_value = max(speed_steaming$measurement_value.x)
      starttime = min(speed_steaming$measurement_time)
      endtime = max(speed_steaming$measurement_time)
    }
  }
  result = list(
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "avg",
    err_msg = err_msg,
    data_ok = data_ok
  )
  return(result)
}

calculate_percent_t_steam_rmpcte = function(dbcon,
                                            oitype,
                                            oiids,
                                            starttime = NULL,
                                            endtime = NULL,
                                            merged_data) {
  n = 0
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  err_msg = ""
  data_ok = TRUE
  
  #get speed on steaming
  engine_speed =
    getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "engine_speed")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )[, c("measurement_time", "measurement_value")]
    
  n = nrow(engine_speed)
  if (n == 0) {
    #stop("OpenVA warning: engine_speed, no data for calculation")
    print("engine_speed: no data")
    err_msg = "engine_speed: no data"
    data_ok = FALSE
  } else {
    engine_speed <- engine_speed[engine_speed$measurement_value > 740, ]
     
    if (nrow(merged_data) > 0) {
      ship_steaming <-
        data.frame(merged_data$measurement_time,
                   merged_data$ship_steaming)
      names(ship_steaming) <-
        c("measurement_time", "measurement_value")
    } else {
      ship_steaming =
        getVariableValues_partition(
          dbcon,
          variableid = getMetadata_bytitle(dbcon, "ship_steaming")$id,
          oiids,
          oitype = oitype,
          starttime = starttime,
          endtime = endtime,
          TRUE
        )[c("measurement_time", "measurement_value")]
    }   
    
    n = nrow(ship_steaming)
    if (n == 0) {
      #stop("OpenVA warning: no data for calculation")
      print("ship_steaming: no data")
      err_msg = "ship_steaming: no data"
      data_ok = FALSE
    } else {   
      ship_steaming <-
        ship_steaming[ship_steaming$measurement_value == 1, ]
      
      engine_speed$measurement_time <-
        as.character(engine_speed$measurement_time)
      ship_steaming$measurement_time <-
        as.character(ship_steaming$measurement_time)
      engine_speed_steaming = merge(engine_speed,
                                    ship_steaming,
                                    "measurement_time")
      
      
      
      
      t_steam_RPMcte = sum(engine_speed_steaming$measurement_value.y, na.rm = TRUE) * 10 /
        3600
      t_steam = sum(ship_steaming$measurement_value, na.rm = TRUE) * 10 /
        3600
      if (t_steam != 0) {
        calculated_value = t_steam_RPMcte / t_steam * 100
      } else {
        calculated_value = 0
      }
      
      min_value = NA
      max_value = NA
      sd_value = NA
    }
  }
  return(
    list(
      n = n,
      calculated_value = calculated_value,
      starttime = starttime,
      endtime = endtime,
      sd_value = sd_value,
      min_value = min_value,
      max_value = max_value,
      visutype = "sum",
      err_msg = err_msg,
      data_ok = data_ok
    )
  )
}

calculate_t_steam_rmpcte = function(dbcon,
                                    oitype,
                                    oiids,
                                    starttime = NULL,
                                    endtime = NULL,
                                    merged_data) {
  n = 0
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  err_msg = ""
  data_ok = TRUE
  
  #get speed on steaming
  engine_speed =
    getVariableValues_partition(
      dbcon,
      variableid = getMetadata_bytitle(dbcon, "engine_speed")$id,
      oiids,
      oitype = oitype,
      starttime = starttime,
      endtime = endtime,
      TRUE
    )[, c("oi_id", "measurement_time", "measurement_value")]
  
  
  n = nrow(engine_speed)
  if (n == 0) {
    #stop("OpenVA warning: engine_speed, no data for calculation")
    print("OpenVA warning: engine_speed, no data for calculation")
    err_msg = "engine_speed, no data"
    data_ok = FALSE
  } else {
    engine_speed <- engine_speed[engine_speed$measurement_value > 740, ]
    if (nrow(merged_data) > 0) {
      ship_steaming <-
        data.frame(merged_data$measurement_time,
                   merged_data$ship_steaming)
      names(ship_steaming) <-
        c("measurement_time", "measurement_value")
    } else {
      ship_steaming =
        getVariableValues_partition(
          dbcon,
          variableid = getMetadata_bytitle(dbcon, "ship_steaming")$id,
          oiids,
          oitype = oitype,
          starttime = starttime,
          endtime = endtime,
          TRUE
        )[c("measurement_time", "measurement_value")]
    }
    
    n = nrow(ship_steaming)
    if (n == 0) {
      #stop("OpenVA warning: no data for calculation")
      print("OpenVA warning: ship_steaming no data for calculation")
      data_ok = FALSE
      err_msg = "ship_steaming, no data"
    } else {
      ship_steaming <-
        ship_steaming[ship_steaming$measurement_value == 1, ]
      
      engine_speed$measurement_time <-
        as.character(engine_speed$measurement_time)
      ship_steaming$measurement_time <-
        as.character(ship_steaming$measurement_time)
      engine_speed_steaming = merge(engine_speed,
                                    ship_steaming,
                                    "measurement_time")
      
      
      calculated_value = sum(engine_speed_steaming$measurement_value.y, na.rm = TRUE) * 10 /
        3600
      
      min_value = NA
      max_value = NA
      sd_value = NA
    }
  }
  return(
    list(
      n = n,
      calculated_value = calculated_value,
      starttime = starttime,
      endtime = endtime,
      sd_value = sd_value,
      min_value = min_value,
      max_value = max_value,
      visutype = "sum",
      err_msg = err_msg,
      data_ok = data_ok
    )
  )
}

#average fuel oil consumption steamin
calculate_mfo_steam_avg = function(dbcon,
                                   oitype,
                                   oiids,
                                   starttime = NULL,
                                   endtime = NULL,
                                   merged_data) {
  data_ok = TRUE
  err_msg = ""
  sd_value = NA
  min_value = NA
  max_value = NA
  n = 0
  calculated_value = NA
  if (nrow(merged_data) > 0) {
      ship_steaming <-
        data.frame(merged_data$measurement_time,
                   merged_data$ship_steaming)
      names(ship_steaming) <-
        c("measurement_time", "measurement_value")
  }  else {
  	ship_steaming =
    	getVariableValues_partition(
      		dbcon,
      		variableid = getMetadata_bytitle(dbcon, "ship_steaming")$id,
      		oiids,
      		oitype = oitype,
      		starttime = starttime,
      		endtime = endtime,
      		TRUE
    	)
  }

  if (nrow(ship_steaming) == 0) {
    #stop("OpenVA warning: no data for calculation (ship_steaming)")
    print("ship_steaming: no data")
    err_msg = "ship_steaming: no data"
    data_ok = FALSE
  } else {
    ship_steaming <-
    ship_steaming[ship_steaming$measurement_value == 1, ]
    if (nrow(merged_data) > 0) {
    	me_fo_consumption <- data.frame(merged_data$measurement_time, merged_data$me_fo_consumption)
    	names(me_fo_consumption) <- c("measurement_time", "measurement_value")
  	} else {
    	me_fo_consumption =
      		getVariableValues_partition(
        		dbcon,
		        variableid = getMetadata_bytitle(dbcon, "ME_FO_consumption")$id,
		        oiids,
		        oitype = oitype,
		        starttime = starttime,
		        endtime = endtime,
		        TRUE
      		)
    }
    if (nrow(me_fo_consumption) == 0 || nrow(ship_steaming) == 0) {
      #stop("OpenVA warning: no data for calculation (me_fo_consumption)")
      if (nrow(me_fo_consumption) == 0) {
      	print("me_fo_consumption: no data")
      	err_msg = "me_fo_consumption: no data"
      } else {
      	print("ship_steaming: no data")
      	err_msg = "ship_steaming: no data"
      }
      data_ok = FALSE
    } else {
    
    	ship_steaming_fuel = merge(ship_steaming,
                               me_fo_consumption,
                               by = c("measurement_time"))
    
    	calculated_value = mean(ship_steaming_fuel$measurement_value.y, na.rm =
                              TRUE)
    
    	sd_value = sd(ship_steaming_fuel$measurement_value.y)
    	min_value = min(ship_steaming_fuel$measurement_value.y)
    	max_value = max(ship_steaming_fuel$measurement_value.y)
    
    	starttime = min(ship_steaming_fuel$measurement_time)
    	endtime = max(ship_steaming_fuel$measurement_time)
    	n = nrow(ship_steaming_fuel)
    }
  }
  
  return(
    list(
      n = n,
      calculated_value = calculated_value,
      starttime = starttime,
      endtime = endtime,
      sd_value = sd_value,
      min_value = min_value,
      max_value = max_value,
      visutype = "avg",
      err_msg = err_msg,
      data_ok = data_ok
    )
  )
}

calculate_num_aux_avg = function(dbcon,
                                 oitype,
                                 oiids,
                                 starttime = NULL,
                                 endtime = NULL,
                                 merged_data) {
  calculated_value = NA
  err_msg = ""
  data_ok = TRUE
  num_aux =  getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, "num_ae_running")$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  
  
  n = nrow (num_aux)
  if (n == 0) {
    #stop("OpenVA warning: num_aux, no data for calculation")
    print("OpenVA warning: num_aux, no data for calculation")
    err_msg = "num_ae_running, no data for calculation"
    calculated_value = NA
    sd_value = NA
    min_value = NA
    max_value = NA
    data_ok = FALSE
  } else {
    calculated_value = mean(num_aux$measurement_value)
    sd_value = sd(num_aux$measurement_value)
    min_value = min(num_aux$measurement_value)
    max_value = max(num_aux$measurement_value)
    starttime = min(num_aux$measurement_time)
    endtime = max(num_aux$measurement_time)
  }
  
  
  
  
  result = list(
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "avg",
    err_msg = err_msg,
    data_ok = data_ok
  )
  return(result)
  
}


calculate_prop_eff_avg = function(dbcon,
                                  oitype,
                                  oiids,
                                  starttime = NULL,
                                  endtime = NULL,
                                  merged_data) {
  calculated_value = NA
  err_msg = ""
  data_ok = TRUE
  
  prop_eff =  getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, "propulsion_efficiency_steaming")$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  
  
  n = nrow (prop_eff)
  if (n == 0) {
    #stop("OpenVA warning: prop_eff, no data for calculation")
    print("OpenVA warning: prop_eff, no data for calculation")
    data_ok = FALSE
    err_msg = "prop_eff_steaming: no data"
    calculated_value = NA
    sd_value = NA
    min_value = NA
    max_value = NA
  }  else {
    calculated_value = mean(prop_eff$measurement_value)
    sd_value = sd(prop_eff$measurement_value)
    min_value = min(prop_eff$measurement_value)
    max_value = max(prop_eff$measurement_value)
    starttime = min(prop_eff$measurement_time)
    endtime = max(prop_eff$measurement_time)
  }
  result = list(
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "avg",
    err_msg = err_msg,
    data_ok = data_ok
  )
  return(result)
  
}


#function
calculate_auxengine_running_hours = function(dbcon,
                                             oitype,
                                             oiids,
                                             aux_nbr,
                                             starttime = NULL,
                                             endtime = NULL)
{
  calculated_value = NA
  data_ok = TRUE
  err_msg = ""
  variable_title = paste("DG_", aux_nbr, "_condition", sep = "")
  ae_running <- getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, variable_title)$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  
  
  n = nrow (ae_running)
  if (n == 0) {
    #stop("OpenVA warning: aux engine running, no data for calculation")
    print("OpenVA warning: aux engine running, no data for calculation")
    err_msg = "ae_running: no data"
    calculated_value = NA
    sd_value = NA
    min_value = NA
    max_value = NA
    data_ok = FALSE
  } else {
 	 dt = 10
  	calculated_value = sum(ae_running$measurement_value) * dt / 3600
  	sd_value = NA
  	min_value = NA
  	max_value = NA
  	starttime = min(ae_running$measurement_time)
  	endtime = max(ae_running$measurement_time)
  }
  

  result = list(
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "sum",
    err_msg = err_msg,
    data_ok = data_ok
  )
  return(result)
}


#calculate auxengine 1 running hours
calculate_t_aux1 = function(dbcon,
                            oitype,
                            oiids,
                            starttime = NULL,
                            endtime = NULL,
                            merged_data) {
  result = calculate_auxengine_running_hours(dbcon,
                                             oitype,
                                             oiids,
                                             1,
                                             starttime = starttime,
                                             endtime = endtime)
  return(result)
}

#calculate auxengine 2 running hours
calculate_t_aux2 = function(dbcon,
                            oitype,
                            oiids,
                            starttime = NULL,
                            endtime = NULL,
                            merged_data) {
  result = calculate_auxengine_running_hours(dbcon,
                                             oitype,
                                             oiids,
                                             2,
                                             starttime = starttime,
                                             endtime = endtime)
  return(result)
}

#calculate auxengine 3 running hours
calculate_t_aux3 = function(dbcon,
                            oitype,
                            oiids,
                            starttime = NULL,
                            endtime = NULL,
                            merged_data) {
  result = calculate_auxengine_running_hours(dbcon,
                                             oitype,
                                             oiids,
                                             3,
                                             starttime = starttime,
                                             endtime = endtime)
  return(result)
}

#calculate auxengine 4 running hours
calculate_t_aux4 = function(dbcon,
                            oitype,
                            oiids,
                            starttime = NULL,
                            endtime = NULL,
                            merged_data) {
  result = calculate_auxengine_running_hours(dbcon,
                                             oitype,
                                             oiids,
                                             4,
                                             starttime = starttime,
                                             endtime = endtime)
  return(result)
}

#calculate auxengine 5 running hours
calculate_t_aux5 = function(dbcon,
                            oitype,
                            oiids,
                            starttime = NULL,
                            endtime = NULL,
                            merged_data) {
  result = calculate_auxengine_running_hours(dbcon,
                                             oitype,
                                             oiids,
                                             5,
                                             starttime = starttime,
                                             endtime = endtime)
  return(result)
}

calculate_total_period_hours = function(dbcon,
                                        oitype,
                                        oiids,
                                        starttime = NULL,
                                        endtime = NULL,
                                        merged_data) {
  n = ""
  calculated_value = NA
  sd_value = NA
  min_value = NA
  max_value = NA
  calculated_value = as.numeric(difftime(endtime, starttime, units = "hour"))
  
  
  result = list(
    n = n,
    calculated_value = calculated_value,
    starttime = starttime,
    endtime = endtime,
    visutype = "abs",
    err_msg = "",
    data_ok = TRUE
  )
  
  return(result)
}


##______________________________________________________________________
#
#function
hourly_values = function(dbcon,
                         oitype,
                         oiids,
                         title,
                         type,
                         starttime = NULL,
                         endtime = NULL) {
  data_ok = TRUE
  err_msg = ""
  sd_value = NA
  min_value = NA
  max_value = NA
  n = NA
  values = getVariableValues_partition(
    dbcon,
    variableid = getMetadata_bytitle(dbcon, title)$id,
    oiids,
    oitype = oitype,
    starttime = starttime,
    endtime = endtime,
    TRUE
  )
  if (nrow (values) == 0) {
    #stop("OpenVA warning: no data for calculation")
    data_ok = FALSE
    err_msg = "no data"
    calculated_value = NA
    min_value = NA
    max_value = NA
    sd_value = NA
    print("OpenVA warning: no data for calculation")
  } else {
    values = unique(values)
    n = nrow(values)
    starttime = min(values$measurement_time)
    endtime = max(values$measurement_time)
    if (type == "sum") {
      calculated_value = sum(values$measurement_value)
      
    } else if (type == "avg") {
      calculated_value = mean(values$measurement_value)
      min_value = min(values$measurement_value)
      max_value = max(values$measurement_value)
      sd_value = sd(values$measurement_value)
    } else {
      #stop("OpenVA warning: calculation type not implemented")
      data_ok = FALSE
    }
    rm(values)
    gc()
  }
  result = list(
    data_ok = data_ok,
    err_msg = err_msg,
    n = n,
    calculated_value = calculated_value,
    sd_value = sd_value,
    min_value = min_value,
    max_value = max_value,
    starttime = starttime,
    endtime = endtime,
    visutype = type
  )
  
  return(result)
}


AddTableRow = function(my_table,calculated_values,j,dbcon,oiids_temp,starttime,endtime,merged_data,oi_report_title) {
      my_calcvalue = calculated_values[j, ]
      my_variable = my_calcvalue$oitype_property_title
      my_function = paste("calculate_", my_variable, sep = "")
#      print(my_function)
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
#        start_time <- Sys.time()
    	table = AddTableRow(my_table,calculated_values,j, dbcon,oiids_temp,starttime,endtime,merged_data,oi_report_title)
    	if (!is.null(table)) { 
			my_table = table
		} 
#		end_time <- Sys.time()
#    	print(end_time - start_time)
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





