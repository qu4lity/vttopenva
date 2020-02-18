'''
Created on 8.5.2019

@author: ttesip
'''

import pandas as pd
import math
from datetime import datetime
import psycopg2.extras
import io

class Common(object):
    '''
    classdocs
    '''
    
    def parse_parameters(self, pars):
        params = {}
        for arg in pars:
            keyvalue = arg.split("=")
            if (len(keyvalue)>1):
                params[keyvalue[0]] = keyvalue[1]
        return params

    def get_measurements_partition(self, conn, property_title, oi_title, min_time, max_time):
        table_name = oi_title.lower() + "_" + property_title.lower()
             
        query = u"select id,oi_measuredproperty_id,measurement_value,measurement_time from "  + table_name + " where measurement_time  >= %s and measurement_time  <= %s;"
        variables = (min_time, max_time)
        
        cur = conn.cursor()
        cur.execute(query,variables)
        
        res = cur.fetchall()
        col_names = []
        for desc in cur.description:
            col_names.append(desc[0])
        data_frame = pd.DataFrame(res, columns=col_names)                
        return data_frame

    def fetch_data_frame(self,cur):
        res = cur.fetchall()
        col_names = []
        for desc in cur.description:
            col_names.append(desc[0])
            
        return pd.DataFrame(res, columns=col_names)

    def get_metadata(self,conn,variableid):    
        variableid = int(variableid)
        query = u"select * from oitype_property where oitype_property.id= %s;"
        variables = [variableid]
        cur = conn.cursor()
        cur.execute(query,variables)
        return self.fetch_data_frame(cur).iloc[0]

    def get_metadata_by_title(self,conn,title):    
        query = u"select * from oitype_property where oitype_property.title= %s;"
        variables = (title)
        cur = conn.cursor()
        cur.execute(query,variables)
        return self.fetch_data_frame(cur)
    
    def get_ois(self,conn,oiids,oitype):
        cur = conn.cursor()
        if ((oiids is None) & (oitype is None)):
            #get all ois 
            query=u"select  * from objectofinterest;"
            cur.execute(query)    
        else: 
            if ((oiids is not None) & (oitype is not None)):  
                query=u"select  * from objectofinterest where id in (%s) and oitype_title=%s;"
                variables = [tuple(oiids),oitype]
            else: 
                if ((oiids is not None) & (oitype is None)): 
                    query=u"select  * from objectofinterest where id in (%s);"
                    [tuple(oiids)]
                else: 
                    query=u"select  * from objectofinterest where oitype_title=%s;"
                    variables = (oitype)      
            cur.execute(query,variables)
        return self.fetch_data_frame(cur)

    def get_measurement_daily_counts(self,varid,oiids, starttime,endtime,conn): 
  
        print(starttime)
        print(endtime)
  
        #check variable
        my_meta=self.get_metadata(conn,varid)
        if len(my_meta) == 0:
            print("OpenVA message: No variable " + varid + " found, try another")
            return
  
        #check oi 
        #oiids_temp="(" + oiids + ")"
        oiids_list = oiids.split(",")
        my_ois= self.get_ois(conn,oiids_list,oitype=my_meta.oitype_title).iloc[0]
        print(my_ois['report_title'])
      
        if len(my_ois) == 0:
            print("OpenVA message:No object of interest " + oiids + " found, try another")
            return        
  
        #read data    
  
        property_title=my_meta.title
        oi_title=my_ois.title
        my_table= oi_title.lower() + "_" + property_title
        #print(my_table)
        cur = conn.cursor()  
        if (starttime is None):  
            query=u"select  min(measurement_time) from %s;"
            cur.execute(query)
            df = self.fetch_data_frame(cur)
            starttime= df.iloc[0].min
            if (math.isnan(starttime)): 
                print("OpenVA message:No starttime found, try another") 
                return

        if (endtime is None):   
            query=u"select  max(measurement_time) from %s;"
            cur.execute(query)
            df = self.fetch_data_frame(cur)
            endtime= df.iloc[0].max
            if (math.isnan(endtime)): 
                print("OpenVA message:No endtime found, try another") 
                return

        start_time = datetime.strptime(starttime, '%Y-%m-%d %H:%M:%S')
        end_time = datetime.strptime(endtime, '%Y-%m-%d %H:%M:%S')
        print(start_time)
        print(end_time)
        
        query=u"select min(id) as id, count (*) as value, measurement_time::timestamp::date as day FROM " + my_table + " ns WHERE ns.measurement_time  BETWEEN %s AND %s group by day order by  day;"
        variables = (start_time,end_time,) 
        cur.execute(query,variables)
        df = self.fetch_data_frame(cur)
        return(df)


class Postgres(object):
    def connect(self,params):
        conn = None
        print("connect")
        print(params)
        try:
            print('Connecting to the PostgreSQL database...')
            conn = psycopg2.connect(**params)
 
            # create a cursor
            cur = conn.cursor()
        
            print('PostgreSQL database version:')
            cur.execute('SELECT version()')
 
            # display the PostgreSQL database server version
            db_version = cur.fetchone()
            print(db_version)
        except (Exception, psycopg2.DatabaseError) as error:
            print(error)
        finally:
            return conn

    def get_max_time(self):
        return self.max_time
    def get_min_time(self):
        return self.min_time

    def import_data_frame(self,oiTitle, columnName,import_data,conn):

        if (len(import_data) < 1):
            return False

        cur = conn.cursor()
        query = u"select * from oi_measuredproperty where oi_title =%s and  oitype_property_source_title =%s;"
        variables = (oiTitle, columnName)
        try:
            cur.execute(query,variables)
            res = cur.fetchall()
            col_names = []
            for desc in cur.description:
                col_names.append(desc[0])
            meta_data = pd.DataFrame(res, columns=col_names)

            # remove values not within limits
            outlier_lowerlimit = meta_data['outlier_lowerlimit'].iloc[0]
            outlier_upperlimit = meta_data['outlier_upperlimit'].iloc[0]
            oi_measuredproperty_id = meta_data['id'].iloc[0]
                       

            #oitype_property_title = meta_data['oitype_property_title'].iloc[0].rstrip()
            #print(oitype_property_title)           
#            if (oitype_property_title == 'AE_FO_consumption' or oitype_property_title == 'AE_FO_inlet_Temp' or oitype_property_title == 'ME_FO_inlet_Temp' or oitype_property_title == 'ME_FO_consumption'
#                                        or oitype_property_title == 'DG_1_power' or oitype_property_title == 'DG_2_power' or oitype_property_title == 'DG_3_power' or oitype_property_title == 'DG_4_power'
#                                        or oitype_property_title == 'DG_5_power' or oitype_property_title == 'DG_1_condition' or oitype_property_title == 'DG_2_condition'
#                                        or oitype_property_title == 'DG_3_condition' or oitype_property_title == 'DG_4_condition' or oitype_property_title == 'DG_5_condition'
#                                        or oitype_property_title == 'engine_speed' or oitype_property_title == 'propeller_pitch' or oitype_property_title == 'ship_speed_actual' 
#                                        or oitype_property_title == 'Eng_Relative_load' or oitype_property_title == 'torque' or oitype_property_title == 'FO_Rack_position'
#                                        or oitype_property_title == 'propeller_shaft_rpm' or oitype_property_title == 'FO_demand' or oitype_property_title == 'propeller_shaft_output'
#                                        or oitype_property_title == 'FO_consumption_kg_NM' or oitype_property_title == 'Specific_FO_consumption'  or oitype_property_title == 'propeller_shaft_thrust'):                    
            if True: 
#            if (oitype_property_title == 'AE_FO_consumption'):  
                value_data = import_data.loc[:, ['TIME', columnName]]
                value_data['oi_measuredproperty_id'] =  oi_measuredproperty_id
                value_data[columnName] = import_data[columnName].astype('float')
                value_data['TIME'] =  pd.to_datetime(value_data['TIME'], format='%Y/%m/%d %H:%M:%S.%f')
                max_val = value_data['TIME'].max()
                min_val = value_data['TIME'].min()
                if max_val > self.max_time: 
                    self.max_time = max_val  
                if min_val < self.min_time: 
                    self.min_time = min_val 
                    
                     
                if not outlier_upperlimit is None:
                    value_data = value_data[value_data[columnName] <= outlier_upperlimit];
                if not outlier_lowerlimit is None:
                    value_data = value_data[value_data[columnName] >= outlier_lowerlimit];
 
                value_data=value_data.rename(columns = {'TIME':'measurement_time',columnName:'measurement_value'})    
                output = io.StringIO()
                value_data.to_csv(output, sep='\t', header=False, index=False)
                output.seek(0)
                cur.copy_from(output, 'oi_measuredproperty_value', null="", columns=('measurement_time', 'measurement_value','oi_measuredproperty_id')) # null values become '
            return True
        except Exception as e :
            print(e)    
            return False