'''
Created on 3.5.2019

@author: ttesip
'''
import sys

from db_classes import Common
from db_classes import Postgres
import numpy as np
import math
import matplotlib.pyplot as plt

import json
from sqlalchemy.engine.url import make_url

c=Common()
params = c.parse_parameters(sys.argv)
ps_params = {}
ps_params["host"] = params["host"]
url =  params["dburl"].split("jdbc:",1)[1]
url = make_url(url)
ps_params["database"] = url.database
ps_params["user"] = params["user"]
ps_params["password"] = params["password"]

ps = Postgres()
try:
    conn = ps.connect(ps_params)
except:
    print("Database connection failed")
    print(ps_params)
    data = {}
    data['error'] = "Database connection failed"
    with open(params['outputfile'],'w') as outfile:
        json.dump(data,outfile)
    sys.exit()

try: 
    df = c.get_measurement_daily_counts(params["varids"],params["oiids"], params["starttime"],params["endtime"],conn)
    height = df.value
    bars = df.day
    y_pos = np.arange(len(bars))
     
    plt.ioff() 
    dpi=96
    plt.figure(figsize=(600/dpi, 600/dpi), dpi=dpi)
    ax = plt.subplot()
    ax.tick_params(labelsize=8)
    # Create bars
    plt.bar(y_pos, height)
    # Create names on the x-axis
    plt.xticks(y_pos, bars, rotation='vertical')
    
    
    
    every_nth = math.ceil(bars.size/31)
    print(every_nth)
    for n, label in enumerate(ax.xaxis.get_ticklabels()):
        if n % every_nth != 0:
            label.set_visible(False)
     
    # Show graphic
    #plt.show()
    plt.savefig(params['localResultFile'])
    
    data = {}
    data['imagetype'] = params['imagetype']
    data['image'] = params['resultUrl']
    with open(params['outputfile'],'w') as outfile:
        json.dump(data,outfile)
except:
    data = {}
    data['error'] = "Unexpected error"
    with open(params['outputfile'],'w') as outfile:
        json.dump(data,outfile)
    print("Database connection failed")
    print(ps_params)
    sys.exit()    
finally:
    print("conn.close()")
    conn.close()       

if __name__ == '__main__':
    pass