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
 * VisualizationRESTController
 * 
 * @author Pekka Siltanen, Markus Yliker�l�
 *
 */
package fi.vtt.openva.controller;

import fi.vtt.openva.OpenVAApp;
import fi.vtt.openva.domain.OiBackgroundpropertyValue;
import fi.vtt.openva.domain.OitypeProperty;
import fi.vtt.openva.domain.Visualization;
import fi.vtt.openva.pythoninterface.PythonInterface;
import fi.vtt.openva.repositories.RepositoryService;
import fi.vtt.openva.rinterface.RInterface;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;

import java.io.FileReader;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.FileSystem;
import java.nio.file.FileSystems;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.UUID;

import javax.annotation.PostConstruct;


import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;


@RestController
@RequestMapping("/query")
public class VisualizationRESTController{

	private static Logger log = LogManager.getLogger(VisualizationRESTController.class);


	@Autowired
	private RepositoryService repositoryService;


	
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
	
	@Value("${analysis.task.timeout}")
	private Integer timeout;
	
	@Value("${pythoninterface.outputfolder}")
	private String pythonOutputFolder;
	@Value("${pythoninterface.scriptpath}")
	private String pythonScriptExec;
	@Value("${pythoninterface.modulefilename}")
	private String pythonImportModule;
	
	
	@PostConstruct
	public void init() {
		this.ri.setRscriptExec(rscriptExec);
		this.ri.setTimeout(timeout);
	}
	
	private RInterface ri = new RInterface(); 
	
	@RequestMapping("cancelAnalysis")
	public String cancelAnalysisRequest () {
		String jsonString = "{\"FAIL\" : \"Cancel failed \"}";
		try {
			String result = ri.cancelAnalysis();
			jsonString = "{\"OK\" : \"" + result + "\"}";
		} catch (InterruptedException e) {
				e.printStackTrace();
		}			
		return jsonString; 
	}
	
	@RequestMapping("{analysisName}/params")
	public String handleAnalysisRequest (@PathVariable("analysisName") String analysisName,
			@RequestParam Map<String, String> queryMap) {
		try {
			return runAnalysis(analysisName, queryMap);
		} catch (Exception e) {
			e.printStackTrace();
			
			Object obj;
			try {
				JSONParser parser = new JSONParser();
				obj = parser.parse("{\"error\" : \"OpenVA error - " + e.getMessage() + "}");
				JSONObject jsonObject =  (JSONObject) obj;					
				return jsonObject.toJSONString(); 
			} catch (ParseException e1) {
				e1.printStackTrace();
			}

		}
		return analysisName;
	}

	private String runAnalysis(String analysisName, Map<String, String> queryMap) throws InterruptedException,
			MalformedURLException, URISyntaxException, Exception, IOException, ParseException {
		
		String filterKeyString = queryMap.get("filterKeys");
		String filterValueString = queryMap.get("filterValues");
		if (filterKeyString != null && filterKeyString.startsWith("-1")) {
			Gson gson = new Gson();
			String filterString = gson.toJson(repositoryService.findAll());		
			queryMap.put("oiids", filterString);
			queryMap.put("ois_filter_list", "filter=all");
		} else if (filterKeyString != null && !filterKeyString.equals("null")) {
			String[] filterKeys = filterKeyString.split(",");
			String[] filterValues = filterValueString.split(",");
			String filterString = "";
			for (int i = 0; i<filterKeys.length; i++ ) {
				filterString += filterKeys[i] + "=" + filterValues[i];
				if (i<filterKeys.length-1) {
					filterString +=",";
				}
			}
			queryMap.put("ois_filter_list", filterString);
			String oiidsString = getFilteredOis(filterKeys,filterValues);
			queryMap.put("oiids", oiidsString);
		}
		
		queryMap.put("dburl", url.replace("\\", ""));
		queryMap.put("user", username);
		queryMap.put("pass", password);
		queryMap.put("password",password);

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
		String imagetype = queryMap.get("imagetype");
		String end;
		switch (imagetype) {
			case "rawdata":
				end = ".csv";
				break;
			case "vector":
				end = ".svg";
				break;
			case "pdf":
				end = ".pdf";
				break;	
			default:
				end = ".png";
				break;		
		}
		String localResultFile = staticPath.toAbsolutePath().toString().replace('\\', '/') + "/" + randomname + end;
		queryMap.put("localResultFile",localResultFile);
		
		String resultUrl = serverURL + ":" + port +"/files/" + randomname + end;
		queryMap.put("resultUrl",resultUrl);
		
		String engine = repositoryService.getVisualizationEngine(analysisName);
		if (engine.equals("echo")) {
			return returnParamsAsJson(queryMap);
		} else if (engine.equals("openva")) {		
			JSONParser parser = new JSONParser();
			return runLocalRScript(analysisName, queryMap, parser, staticPath, filename); 
		} else if (engine.equals("pyopenva")) {		
			return runLocalPythonScript(analysisName, queryMap,staticPath, filename); 
		} else {
			JSONParser parser = new JSONParser();
			Object obj = parser.parse("{\"error\" : \"OpenVA error : Unknown visualization engine\"}");
			JSONObject jsonObject =  (JSONObject) obj;					
			return jsonObject.toJSONString(); 
		}
	}

	private String runLocalRScript(String analysisName, Map<String, String> queryMap, JSONParser parser,
			Path staticPath, String filename)
			throws URISyntaxException, IOException, InterruptedException, ParseException {
		Path rFilePath;				
		URI uri = OpenVAApp.class.getResource("/static/R").toURI();
		if (uri.getScheme().equals("jar")) {
		    FileSystem fileSystem = FileSystems.newFileSystem(uri, Collections.<String, Object>emptyMap());
		    rFilePath = fileSystem.getPath("/static/R");
		    fileSystem.close();
		} else {
			rFilePath = Paths.get(uri);
		}
		
//		ri.setRscriptExec(rscriptExec);
//		ri.setTimeout(timeout);
		
		Object obj = null;
		String returnString = "";
		
		String rFolder = rFilePath.toString().replace('\\', '/');
		FileReader fr = null;
		try {
			ri.newTask(queryMap,rFolder  + "/" +analysisName + ".R", rFolder  + "/" + rCommonFileName , staticPath.toAbsolutePath().toString().replace('\\', '/') + "/" + analysisName + "out.R",staticPath.toAbsolutePath().toString().replace('\\', '/') + "/" + rCommonFileName, filename);
			String result = ri.getResult();
			if (result.equals("TimeoutException")) {
				obj = parser.parse("{\"error\" : \"OpenVA error: maximum time for R script exceeded\"}");
			} else if (result.equals("InterruptedException")) {
				obj = parser.parse("{\"error\" : \"OpenVA message: running R script cancelled\"}");
			} else if (result.equals("ExecutionException")) {
				throw new Exception();
			} else {
				fr = new FileReader(result);
				obj = parser.parse(fr); 
			}		
		}  
		catch (Exception e1) {
			obj = parser.parse("{\"error\" : \"OpenVA error: running R script failed\"}");
		} finally {
			JSONObject jsonObject =  (JSONObject) obj;	
			returnString = jsonObject.toJSONString();
			if (fr != null) {
				fr.close();
			}		

		}
		return returnString;
	}

	private String runLocalPythonScript(String analysisName, Map<String, String> queryMap, Path staticPath, String outputFilename)
			throws URISyntaxException, IOException, InterruptedException, ParseException {
		JSONParser parser = new JSONParser();
		Path pyFilePath;				
		URI uri = OpenVAApp.class.getResource("/static/python").toURI();
		if (uri.getScheme().equals("jar")) {
		    FileSystem fileSystem = FileSystems.newFileSystem(uri, Collections.<String, Object>emptyMap());
		    pyFilePath = fileSystem.getPath("/static/python");
		    fileSystem.close();
		    System.out.println("jar: " + pyFilePath);
		} else {
			pyFilePath = Paths.get(uri);
			System.out.println("no jar: " + pyFilePath);
		}
		
		PythonInterface pi = new PythonInterface(pythonScriptExec);        	  
		
		String pyFolder = pyFilePath.toString().replace('\\', '/');
		pi.newTask(queryMap,pyFolder  + "/" +analysisName + ".py", outputFilename, pythonOutputFolder,pyFolder  + "/" + pythonImportModule, timeout);
		String ouputJsonFile = pi.getResult();
		
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

	public String getFilteredOis(String[] filterKeys, String[] filterValues) throws InterruptedException{
		
		
		
		MultiValueMap<String,String> filterMap = new LinkedMultiValueMap<String,String>();
		for (int i= 0; i< filterKeys.length; i++) {
			filterMap.add(filterKeys[i],filterValues[i]);
		}
		
		Set<String> titles = filterMap.keySet();
		List<OitypeProperty> codedPropertytypes = repositoryService.getFilteredCodedOiTypeProperties(new ArrayList(titles));
		List<OitypeProperty> nonCodedPropertytypes = repositoryService.getFilteredNonCodedOiTypeProperties(new ArrayList(titles));
		
		Set<String> oiIds = null;
		boolean first = true;
		for (OitypeProperty oitp: codedPropertytypes) {
			List<String> values = filterMap.get(oitp.getTitle());
			List<OiBackgroundpropertyValue> backproperies = repositoryService.getBackgroundValuesByOiTypePropertyAndCodeValues(oitp,values);
			HashSet<String> backgroundPropOiIds = new HashSet<String>();
			for (OiBackgroundpropertyValue back: backproperies) {
				backgroundPropOiIds.add(Integer.toString(back.getObjectofinterest().getId()));
			}
			if (first) {
				oiIds = backgroundPropOiIds;
				first = false;
			} else {
				oiIds.retainAll(backgroundPropOiIds);
			}
		}
		
		for (OitypeProperty oitp: nonCodedPropertytypes) {
			List<String> values = filterMap.get(oitp.getTitle());
			List<Float> floatValues = new ArrayList<Float>();
			for (String value: values) {
				floatValues.add(Float.valueOf(value));
			}
			List<OiBackgroundpropertyValue> backproperies = repositoryService.getBackgroundValuesOiTypePropertyAndBackgroundValues(oitp,floatValues);
			HashSet<String> backgroundPropOiIds = new HashSet<String>();
			for (OiBackgroundpropertyValue back: backproperies) {
				backgroundPropOiIds.add(Integer.toString(back.getObjectofinterest().getId()));
			}
			oiIds.retainAll(backgroundPropOiIds);
		}
			

		return String.join(",", oiIds);
	}
	
	/**
	 * Gets the visualisation candidates using filters
	 *
	 * @param ois the ois
	 * @param vars the vars
	 * @return the visualisation candidates
	 */
	@RequestMapping(value = "/getVisualisationCandidates/{ois}/{vars}/{filters}/{applicationTitle}", method = RequestMethod.GET)
	public String getVisualisationCandidatesWithFilters(@PathVariable Integer[] ois, @PathVariable Integer[] vars,@PathVariable String[] filters, @PathVariable String applicationTitle){


		try {
			List<Visualization> vizs = repositoryService.getVisualizations(ois, vars, filters);
			List<VisualizationCandidate> result = new ArrayList<VisualizationCandidate>(); 

			Map<String, String> distinct = new TreeMap<String, String>();			

			for(Visualization viz : vizs){
				if(viz.getEngine() == null){
					continue;
				}
				
				if(distinct.get(viz.getMethod()) != null){
					// same visualization already listed
					continue;
				}
				
				if (viz.getApplicationTitle()!=null && !viz.getApplicationTitle().equals(applicationTitle)) {
					continue;
				}

				distinct.put(viz.getMethod(), viz.getMethod());
				result.add(new VisualizationCandidate(viz));
			}

			Gson gson = new Gson();
			String jsonInString = gson.toJson(result);
			return jsonInString;

		}
		catch(Throwable t){
			log.info("Bizarre");
			t.printStackTrace();
		}

		return "";
	}

	/**
	 * Gets the visualisation candidates without filters.
	 *
	 * @param ois the ois
	 * @param vars the vars
	 * @return the visualisation candidates
	 */
	@RequestMapping(value = "/getVisualisationCandidates/{ois}/{vars}/{applicationTitle}", method = RequestMethod.GET)
	public String getVisualisationCandidates(@PathVariable Integer[] ois, @PathVariable Integer[] vars, @PathVariable String applicationTitle){

		try {
			List<Visualization> vizs = repositoryService.getVisualizations(ois, vars);
			List<VisualizationCandidate> result = new ArrayList<VisualizationCandidate>(); 

			Map<String, String> distinct = new TreeMap<String, String>();			

			for(Visualization viz : vizs){
				if(viz.getEngine() == null){
					continue;
				}
				
				if(distinct.get(viz.getMethod()) != null){
					// same visualization already listed
					continue;
				}
				
				if (viz.getApplicationTitle()!=null && !viz.getApplicationTitle().equals(applicationTitle)) {
					continue;
				}

				distinct.put(viz.getMethod(), viz.getMethod());
				result.add(new VisualizationCandidate(viz));
			}

			Gson gson = new Gson();
			String jsonInString = gson.toJson(result);
			return jsonInString;


		}
		catch(Throwable t){
			log.info("Bizarre");
			t.printStackTrace();
		}

		return "";
	}

	/**
	 * The Class VisualizationCandidate (contains visualization-table columns that are needed in UI).
	 */
	private class VisualizationCandidate{
		public String getEngine() {
			return engine;
		}

		public void setEngine(String engine) {
			this.engine = engine;
		}

		private int id;
		/** The text. (Obsolete, used in some historical versions)*/
		private String text;
		/** The method, should correspond with the script name that is run in the analysis engine */
		private String method;
		/** The title, short title of the method in user readable format*/
		private String title;
		/** The title, short title of the method in user readable format*/
		private String engine;
		/** engine to run the visualization */
		private String[] formats;
		/** engine to run the visualization */
		
		
		VisualizationCandidate(Visualization viz){
			id = viz.getId();
			text = viz.getMethod();	
			method = viz.getMethod();	
			title = viz.getTitle();	
			engine = viz.getEngine();
			setFormats(viz.getFormats());
		}

		public int getId() {
			return id;
		}

		public void setId(int id) {
			this.id = id;
		}

		public String getText() {
			return text;
		}

		public void setText(String text) {
			this.text = text;
		}

		public String getMethod() {
			return method;
		}

		public void setMethod(String method) {
			this.method = method;
		}

		public String getTitle() {
			return title;
		}

		public void setTitle(String title) {
			this.title = title;
		}
		
		public void setFormats(String formats) {
			if (formats != null) {
				List<String> items = Arrays.asList(formats.split("\\s*,\\s*"));
				this.formats = new String[items.size()];
				this.formats = items.toArray(this.formats);
			} else {
				this.formats = new String[0];
			}
		}
		
		public String[] getFormats() {
			return formats;
		}
		
	}	


}
	





