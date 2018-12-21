// OpenVA - Open software platform for visual analytics
//
// Copyright (c) 2018, VTT Technical Research Centre of Finland Ltd
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//    1) Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//    2) Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//    3) Neither the name of the VTT Technical Research Centre of Finland nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/**
 * The Class OpenVAController.
 *
 * @author Markus Ylikerälä/Pekka Siltanen
 */

package fi.vtt.openva.controller;

import fi.vtt.openva.OpenVAApp;
import fi.vtt.openva.repositories.RepositoryService;
import fi.vtt.openva.rinterface.RInterface;
import fi.vtt.openva.service.OpenVAService;
import fi.vtt.openva.task.OpenVATask;
import fi.vtt.openva.task.OpenVATaskImpl;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import java.io.FileReader;
import java.net.URI;
import java.net.URL;
import java.nio.file.FileSystem;
import java.nio.file.FileSystems;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.Map;
import java.util.UUID;
import org.apache.log4j.Logger;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

/**
 * VisualizationRESTController
 * 
 * @author Pekka Siltanen, Markus Ylikerälä
 *
 */

@RestController
@RequestMapping("/query")
public class VisualizationRESTController{


	
	/** The log. */
	private static Logger log = Logger.getLogger(VisualizationRESTController.class);

	private final OpenVAService openVAService;

	/** The repository service. */
	@Autowired
	private RepositoryService repositoryService;

	/**
	 * Instantiates a new open VA controller.
	 *
	 * @param openVAService the open VA service
	 */
	@Autowired
	public VisualizationRESTController(OpenVAService openVAService) {
		this.openVAService = openVAService;
	}

	/**
	 * Gets the result.
	 *
	 * @param openVATask the open VA task
	 * @return the result
	 */
	private String getResult(OpenVATask openVATask) {
		return openVAService.getResult(openVATask);
	}


	/**
	 * Handle analysis request.
	 *
	 * @param analysisName the analysis name
	 * @param queryMap the query map
	 * @return the string
	 */
	
	@Value("${rinterface.outputfolder}")
	private String staticURI;
	@Value("${server.url}")
	private String serverURL;
	@Value("${spring.datasource.url}")
	private String url;
	@Value("${spring.datasource.username}")
	private String username;
	@Value("${spring.datasource.password}")
	private String password;
	@Value("${server.port}")
	private String port;
	@Value("${rinterface.scriptpath}")
	private String rscriptExec;
	@Value("${rinterface.commonrfile}")
	private String rCommonFileName;
	@Value("${deployr.url}")
	private String deployrurl;
	@Value("${deployr.inuse}")
	private Boolean deployrUsed;

	@RequestMapping("{analysisName}/params")
	public String handleAnalysisRequest (@PathVariable("analysisName") String analysisName,
			@RequestParam Map<String, String> queryMap) {
		try {
			
			JSONParser parser = new JSONParser();
		
			queryMap.put("dburl", url.replace("\\", ""));
			queryMap.put("user", username);
			queryMap.put("pass", password);
			queryMap.put("password",password);

			String url2 = url.replaceFirst("^jdbc:postgresql","http");
			URL datasourceUrl = new URL(url.replaceFirst("^jdbc:postgresql","http"));
			String datasourceHost=datasourceUrl.getHost();
			queryMap.put("host",datasourceHost);
			int datasourcePort = datasourceUrl.getPort();
			queryMap.put("port",Integer.toString(datasourcePort));
			String datasourceDbName = datasourceUrl.getPath().replaceFirst("/", "");
			queryMap.put("dbname",datasourceDbName);
			
			
			
			Path staticPath = Paths.get(new URL(staticURI).toURI());
			String filename = staticPath.toAbsolutePath().toString().replace('\\', '/') + "/out" + UUID.randomUUID().toString() + ".json";
			queryMap.put("outputfile",filename);
			
			String randomname = UUID.randomUUID().toString();
			String end = analysisName.equals("Rawdata")?".csv":".png";
			String imagetype = queryMap.get("imagetype");
			if (imagetype.equals("vector")) {
				end = ".svg";
			}
			String localResultFile = staticPath.toAbsolutePath().toString().replace('\\', '/') + "/" + randomname + end;
			queryMap.put("localResultFile",localResultFile);
			
			String resultUrl = serverURL + ":" + port +"/files/" + randomname + end;
			queryMap.put("resultUrl",resultUrl);
			

			String engine = repositoryService.getVisualizationEngine(analysisName);
			if (engine.equals("echo")) {
				return returnParamsAsJson(queryMap);
			} else if (engine.equals("openva")) {			
				Path rFilePath;				
				URI uri = OpenVAApp.class.getResource("/static/R").toURI();
		        if (uri.getScheme().equals("jar")) {
		            FileSystem fileSystem = FileSystems.newFileSystem(uri, Collections.<String, Object>emptyMap());
		            rFilePath = fileSystem.getPath("/static/R");
		            fileSystem.close();
		        } else {
		        	rFilePath = Paths.get(uri);
		        }
				
	        	RInterface ri = new RInterface(rscriptExec);        	  
	        	
	        	String rFolder = rFilePath.toString().replace('\\', '/');
	        	ri.newTask(queryMap,rFolder  + "/" +analysisName + ".R", rFolder  + "/" + rCommonFileName , staticPath.toAbsolutePath().toString().replace('\\', '/') + "/" + analysisName + "out.R",staticPath.toAbsolutePath().toString().replace('\\', '/') + "/" + rCommonFileName, filename);
	        	String ouputJsonFile = ri.getResult();
	        	
	        	Object obj;
	        	FileReader fr = null;
	        	try {
	        		 fr = new FileReader(ouputJsonFile);
	        		obj = parser.parse(fr);
	        	} catch (Exception e) {
	    			obj = parser.parse("{\"error\" : \"OpenVA error : Unexpected error\"}");
	    		} finally {
	    			if (fr != null) {
	    				fr.close();
	    			}
	    			
	    		}			
				
				JSONObject jsonObject =  (JSONObject) obj;
				
				return jsonObject.toJSONString(); 
			} else {
				if (!deployrUsed) {
					Object obj = parser.parse("{\"error\" : \"OpenVA error : Trying to use DeployR: check visualization table\"}");
					JSONObject jsonObject =  (JSONObject) obj;					
					return jsonObject.toJSONString(); 
				}
				OpenVATaskImpl openVATask = new OpenVATaskImpl();
				openVATask.setScript(analysisName + ".R");
				openVATask.setDeployrUrl(deployrurl);
				openVATask.addParams(queryMap);
				
				String result = getResult(openVATask);				
				return result; 
			}
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}


	}

	
	
	
	/**
	 * Return params as json.
	 *
	 * @param queryMap the query map
	 * @return the string
	 */
	private String returnParamsAsJson(Map<String, String> queryMap) {
		JsonArray jsonArray = new JsonArray();
		JsonObject jo = new JsonObject();
		for (Map.Entry<String, String> entry : queryMap.entrySet())
		{
			jo.add(entry.getKey() ,new JsonPrimitive(entry.getValue()));
		}
		jsonArray.add(jo);
		JsonObject jsonObject = new JsonObject();
		jsonObject.add("data",jsonArray);
		return jsonObject.toString();
	}

}






