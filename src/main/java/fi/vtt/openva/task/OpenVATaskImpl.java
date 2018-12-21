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

package fi.vtt.openva.task;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.LinkedBlockingQueue;
import org.springframework.stereotype.Component;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import com.revo.deployr.client.broker.RTask;
import com.revo.deployr.client.broker.RTaskResult;
import com.revo.deployr.client.data.RBoolean;
import com.revo.deployr.client.data.RBooleanMatrix;
import com.revo.deployr.client.data.RBooleanVector;
import com.revo.deployr.client.data.RData;
import com.revo.deployr.client.data.RList;
import com.revo.deployr.client.data.RNumeric;
import com.revo.deployr.client.data.RNumericMatrix;
import com.revo.deployr.client.data.RNumericVector;
import com.revo.deployr.client.data.RString;
import com.revo.deployr.client.data.RStringMatrix;
import com.revo.deployr.client.data.RStringVector;
import com.revo.deployr.client.factory.RDataFactory;

import fi.vtt.openva.service.OpenVAService;

// TODO: Auto-generated Javadoc
/**
 * The Class OpenVATaskImpl.
 *
 * @author Markus Ylikerälä, Pekka Siltanen. Based on DeployR examples
 */
@Component
public class OpenVATaskImpl extends AbstractOpenVATask {
	
	/** The queue. */
	protected LinkedBlockingQueue<JsonObject> queue = new LinkedBlockingQueue<JsonObject>();
	
	/** The param map. */
	Map<String, String> paramMap;
	
	String deployrUrl;
	
	/**
	 * Instantiates a new open VA task impl.
	 */


	public OpenVATaskImpl() {
        
	}

	public void setDeployrUrl(String url) {
		this.deployrUrl = url;
	}
	
	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.AbstractOpenVATask#setScript(java.lang.String)
	 */
	public void setScript(String script) {
		this.script = script;
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.AbstractOpenVATask#getResult(fi.vtt.openva.service.OpenVAService)
	 */
	public String getResult(OpenVAService openVAService) throws InterruptedException {
		JsonObject jsonObject = queue.take();	
		String result = jsonObject.toString();
		return result;
	}
	

	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.AbstractOpenVATask#onTaskError(com.revo.deployr.client.broker.RTask, java.lang.Throwable)
	 */
	public void onTaskError(RTask rTask, Throwable throwable) {
		JsonObject jsonObject = new JsonObject();
		jsonObject.add("error", new JsonPrimitive(throwable.getMessage()));
		queue.add(jsonObject);				
	}
	
	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.AbstractOpenVATask#onRuntimeError(java.lang.Throwable)
	 */
	public void onRuntimeError(Throwable throwable) {
		JsonObject jsonObject = new JsonObject();
		jsonObject.add("error", new JsonPrimitive(throwable.getMessage()));
		queue.add(jsonObject);		
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.AbstractOpenVATask#onError(java.lang.String)
	 */
	public void onError(String msg) {
		JsonObject jsonObject = new JsonObject();
		jsonObject.add("error", new JsonPrimitive(msg));
		queue.add(jsonObject); 				
	}


	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.AbstractOpenVATask#onTaskCompleted(com.revo.deployr.client.broker.RTask, com.revo.deployr.client.broker.RTaskResult)
	 */

	public void onTaskCompleted(RTask rTask, RTaskResult rTaskResult) {
		JsonObject jsonObject = new JsonObject();
		
		if (rTaskResult.getFailure() != null) {		
			JsonPrimitive error = new JsonPrimitive("DeployR script: " + rTaskResult.getFailure().getMessage());
			jsonObject.add("error", error);
			queue.add(jsonObject); 
			return;
		}
		
		String imagetype = null;
		JsonArray jsonArray = new JsonArray();
		List<RData> results =  rTaskResult.getGeneratedObjects();
		for (RData res: results) {
			RList rlist = (RList) res;
			for (RData value: rlist.getValue()) {
				JsonElement rData = handleRData(value);
				if (rData != null) {
					if (value.getName().equals("imagetype")) {
						imagetype = rData.getAsString();
					}
					jsonObject.add(value.getName(), rData);
					//jsonArray.add(rData);				
				}
			}
		}
		
		
		if(rTaskResult.getGeneratedPlots() != null && ! rTaskResult.getGeneratedPlots().isEmpty()) {
			String url = rTaskResult.getGeneratedPlots().get(0).toExternalForm();
			int startIndex = url.indexOf("/deployr/");
			String end = url.substring(startIndex +8, url.length());
			String editedUrl = this.deployrUrl + end;
			
//			JsonPrimitive image = new JsonPrimitive(rTaskResult.getGeneratedPlots().get(0).toExternalForm());
			JsonPrimitive image = new JsonPrimitive(editedUrl);
			jsonObject.add("image", image);
		} else {
			if (imagetype != null && (imagetype.equals("raster") || imagetype.equals("vector") || imagetype.equals("data"))) {
				String url = rTaskResult.getGeneratedFiles().get(0).toExternalForm();
				int startIndex = url.indexOf("/deployr/");
				String end = url.substring(startIndex +8, url.length());
				String editedUrl = this.deployrUrl + end;
				JsonPrimitive file = new JsonPrimitive(editedUrl);
				if (imagetype.equals("raster")) {
					jsonObject.add("image", file);
				} else {
					jsonObject.add("file", file);
				}
			}
		}
		
		//jsonObject.add("data",jsonArray);
		queue.add(jsonObject); 
	}

	private JsonElement handleRData(RData value) {
		String rclass = value.getClass().getSimpleName();
		 switch (rclass) {
		 	case "RBooleanImpl":
		 		return rBoolean(value);
		 	case "RNumericImpl":
		 		return rNumeric(value);
		 	case "RStringImpl":
		 		return rString(value);
		 	case "RBooleanVectorImpl":
		 		return rBooleanVector(value);
		 	case "RNumericVectorImpl":
		 		return rNumericVector(value);
		 	case "RStringVectorImpl":
		 		return rStringVector(value);
		 	case "RBooleanMatrixImpl":
		 		return rBooleanMatrix(value);
		 	case "RNumericMatrixImpl":
		 		return rNumericMatrix(value);
		 	case "RStringMatrixImpl":
		 		return rStringMatrix(value);
		 	case "RListImpl":	
		 		return rList(value);
		 	case "RDataFrameImpl":
		 	case "RDateImpl":
		 	case "RDateVectorImpl":
		 	case "RFactorImpl":
				JsonPrimitive error = new JsonPrimitive("Not implemented yet: " + value.getRclass());
				return error;
		 	case "RDataNAImpl":
		 		return null;
		 }
		return null;
	}

	/**
	 * R boolean matrix.
	 *
	 * @param value the value
	 * @return the json array
	 */
	private JsonArray rBooleanMatrix(RData value) {
		JsonArray booleanMatrix = new JsonArray();
		RBooleanMatrix booleanMatrixValue = (RBooleanMatrix) value;
		for (List<Boolean> val: booleanMatrixValue.getValue()) {
			JsonArray jsonBooleanValueArray = new JsonArray();
			for (Boolean v: val) {            					
				jsonBooleanValueArray.add(new JsonPrimitive(v));
			}
			booleanMatrix.add(jsonBooleanValueArray);
		}
		return booleanMatrix;
	}
	
	/**
	 * R string matrix.
	 *
	 * @param value the value
	 * @return the json array
	 */
	private JsonArray rStringMatrix(RData value) {
		JsonArray stringMatrix = new JsonArray();
		RStringMatrix stringMatrixValue = (RStringMatrix) value;
		for (List<String> val: stringMatrixValue.getValue()) {
			JsonArray jsonStringValueArray = new JsonArray();
			for (String v: val) {            					
				jsonStringValueArray.add(new JsonPrimitive(v));
			}
			stringMatrix.add(jsonStringValueArray);
		}
		return stringMatrix;
	}

	/**
	 * R numeric matrix.
	 *
	 * @param value the value
	 * @return the json array
	 */
	private JsonArray rNumericMatrix(RData value) {
		JsonArray numericMatrix = new JsonArray();
		RNumericMatrix numericMatrixValue = (RNumericMatrix) value;
		for (List<Double> val: numericMatrixValue.getValue()) {
			JsonArray jsonNumericValueArray = new JsonArray();
			for (Double v: val) {  
				if (v != null) {
					jsonNumericValueArray.add(new JsonPrimitive(v));
				} else {
					jsonNumericValueArray.add(new JsonObject());
				}

			}
			numericMatrix.add(jsonNumericValueArray);
		}
		return numericMatrix;
	}
	
	/**
	 * R boolean vector.
	 *
	 * @param value the value
	 * @return the json object
	 */
	private JsonObject rBooleanVector(RData value) {
		JsonObject booleanObject= new JsonObject();
		JsonArray booleanArray= new JsonArray();
		RBooleanVector booleanVectorValue = (RBooleanVector) value;
		for (Boolean val: booleanVectorValue.getValue()) {
			booleanArray.add(new JsonPrimitive(val));
		}	
		booleanObject.add(booleanVectorValue.getName(),booleanArray);
		return booleanObject;
	}

	
	/**
	 * R numeric vector.
	 *
	 * @param value the value
	 * @return the json object
	 */
	private JsonArray rNumericVector(RData value) {
		JsonArray numericArray= new JsonArray();
		RNumericVector numericVectorValue = (RNumericVector) value;
		for (Double val: numericVectorValue.getValue()) {
			if (val != null) {
				numericArray.add(new JsonPrimitive(val));
			} else {
				numericArray.add(new JsonObject());
			}
		}	
		return numericArray;
	}
	
	
	/**
	 * R string vector.
	 *
	 * @param value the value
	 * @return the json object
	 */
	private JsonArray rStringVector(RData value) {
		JsonArray stringArray= new JsonArray();
		RStringVector stringVectorValue = (RStringVector) value;
		for (String val: stringVectorValue.getValue()) {
			if (val != null) {
				stringArray.add(new JsonPrimitive(val));
			} else {
				stringArray.add(new JsonPrimitive("NULL"));
			}
		}	
		return stringArray;
	}
	
	/**
	 * R numeric.
	 *
	 * @param value the value
	 * @return the json object
	 */
	private JsonPrimitive rNumeric(RData value) {
		RNumeric numericValue = (RNumeric) value;
		return new JsonPrimitive(numericValue.getValue());
	}
	
	/**
	 * R boolean.
	 *
	 * @param value the value
	 * @return the json object
	 */
	private JsonPrimitive rBoolean(RData value) {
		RBoolean booleanValue = (RBoolean) value;
		return new JsonPrimitive(booleanValue.getValue());
	}
	
	/**
	 * R string.
	 *
	 * @param value the value
	 * @return the json object
	 */
	private JsonPrimitive rString(RData value) {
		RString stringValue = (RString) value;
		// deployR cannot return null, so null is returned as string "NULL"
		if (stringValue.getValue().equals("NULL")) {
			return null;
		}
		return new JsonPrimitive(stringValue.getValue());
	}

	/**
	 * RList .
	 *
	 * @param value the value
	 * @return the json array
	 */
	private JsonObject rList(RData value) {	
		JsonObject jsonObject = new JsonObject();
		RList listValue = (RList) value;
		JsonArray listArray= new JsonArray();
		for (RData val: listValue.getValue()) {
			jsonObject.add(val.getName(), handleRData(val));
//			listArray.add(handleRData(val));
		}	
		
		return jsonObject;
	}
	
	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.AbstractOpenVATask#getOutput()
	 */
	public List<String> getOutput() {
		return Arrays.asList("output_data");
	}

	
	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.AbstractOpenVATask#getInput()
	 */
	public List<RData> getInput() {
		List<RData> list = new ArrayList<RData>();
    	for (Map.Entry<String, String> entry : paramMap.entrySet()) {
    	    System.out.println(entry.getKey() + "/" + entry.getValue());
    	    list.add((RData) RDataFactory.createString(entry.getKey(), entry.getValue()));
    	}
    	System.out.println(Arrays.toString(list.toArray()));
    	return list;
	}
	


	/**
	 * Adds the params.
	 *
	 * @param queryMap the query map
	 */
	public void addParams(Map<String, String> queryMap) {	
		paramMap = queryMap;
	}

	
	
}
