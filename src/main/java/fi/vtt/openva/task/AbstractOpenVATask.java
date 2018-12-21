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

import java.util.Arrays;
import java.util.List;
import java.util.concurrent.LinkedBlockingQueue;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import com.revo.deployr.client.broker.RTask;
import com.revo.deployr.client.broker.RTaskResult;
import com.revo.deployr.client.data.RData;
import com.revo.deployr.client.data.RString;
import com.revo.deployr.client.data.RStringVector;
import com.revo.deployr.client.data.impl.RStringImpl;
import com.revo.deployr.client.factory.RDataFactory;

import fi.vtt.openva.service.OpenVAService;

// TODO: Auto-generated Javadoc
/**
 * The Class AbstractOpenVATask.
 *
 * @author tteyli
 */
public abstract class AbstractOpenVATask implements OpenVATask{
	
	/** The queue. */
	protected LinkedBlockingQueue<JsonObject> queue = new LinkedBlockingQueue<JsonObject>();
	
	/** The script. */
	protected String script;
	
	

	/**
	 * Instantiates a new abstract open VA task.
	 */
	public AbstractOpenVATask() {
		// TODO Auto-generated constructor stub
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.OpenVATask#getScript()
	 */
	@Override
	public String getScript() {
		return script;
	}

	/**
	 * Sets the script.
	 *
	 * @param script the new script
	 */
	public void setScript(String script) {
		this.script = script;
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.OpenVATask#getResult(fi.vtt.openva.service.OpenVAService)
	 */
	@Override
	public String getResult(OpenVAService openVAService) throws InterruptedException {
		JsonObject jsonObject = queue.take();
		
		String result = jsonObject.toString();
		return result;
	}
	
	
	/**
	 * Gets the result ORG.
	 *
	 * @param openVAService the open VA service
	 * @return the result ORG
	 * @throws Exception 
	 */
//	public String getResultORG(OpenVAService openVAService) throws Exception {
//		try {
//			JsonObject jsonObject = queue.take();
//			
//			String result = jsonObject.toString();
//			return result;
//		
//		} catch (InterruptedException e) {
//			e.printStackTrace();
//			return createErrorMsg(e.toString());
//		
//		}
//		catch(Throwable t){
//			t.printStackTrace();
//			System.err.println("BIZARRE: " + t.getClass().getName() + "#" + t.getCause() + "#" + t.toString());
//			
//			if(t.toString().contains("DeployR")){
//				System.err.println("\n\n\n@@@ Deus Ex Machina @@@ \n\n");
//				String str = openVAService.recycle() + " error " + t.toString();
//				return createErrorMsg(str);
//			}					
//			else {
//				return createErrorMsg(t.toString());
//			}
//		}
//		//return null;
//	}

	/**
	 * Creates the error msg.
	 *
	 * @param msg the msg
	 * @return the string
	 */
//	private String createErrorMsg(String msg) {
//		JsonObject jsonObject = new JsonObject();
//		JsonPrimitive error = new JsonPrimitive("Analytics engine failed: " + msg);
//		jsonObject.add("error", error);
//		return jsonObject.toString();
//	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.OpenVATask#onTaskError(com.revo.deployr.client.broker.RTask, java.lang.Throwable)
	 */
	@Override
	public void onTaskError(RTask rTask, Throwable throwable) {
		JsonObject jsonObject = new JsonObject();
		jsonObject.add("error", new JsonPrimitive(throwable.getMessage()));
		queue.add(jsonObject);				
	}
	
	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.OpenVATask#onRuntimeError(java.lang.Throwable)
	 */
	@Override
	public void onRuntimeError(Throwable throwable) {
		JsonObject jsonObject = new JsonObject();
		jsonObject.add("error", new JsonPrimitive(throwable.getMessage()));
		queue.add(jsonObject);		
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.OpenVATask#onError(java.lang.String)
	 */
	@Override
	public void onError(String msg) {
		JsonObject jsonObject = new JsonObject();
		jsonObject.add("error", new JsonPrimitive(msg));
		queue.add(jsonObject); 				
	}

	/**
	 * Gets the strings.
	 *
	 * @param value the value
	 * @param arr the arr
	 * @return the strings
	 */
	protected void getStrings(RData value, JsonArray arr){
		if(value instanceof RStringVector){
			RStringVector vectorValue = (RStringVector) value;
			for (String val: vectorValue.getValue()) {
				arr.add(new JsonPrimitive(val));
			}
		}
		else if(value instanceof RStringImpl){
			RString stringValue = (RString) value;
			arr.add(new JsonPrimitive(stringValue.getValue()));
		}
		else{
			System.err.println("BIZARRE :" + value.getClass().getName());
		}
	}
	

	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.OpenVATask#onTaskCompleted(com.revo.deployr.client.broker.RTask, com.revo.deployr.client.broker.RTaskResult)
	 */
	@Override
	public void onTaskCompleted(RTask rTask, RTaskResult rTaskResult) {
		// TODO Auto-generated method stub
		
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.task.OpenVATask#getOutput()
	 */
	@Override
	public List<String> getOutput() {
		return Arrays.asList("deploy_data");
	}

//	@Override
//	public List<RData> getInput() {
//		// TODO Auto-generated method stub
//		return null;
//	}
	
	/* (non-Javadoc)
 * @see fi.vtt.openva.task.OpenVATask#getInput()
 */
@Override
	public List<RData> getInput() {
		return Arrays.asList();
	}
	

	

	/* (non-Javadoc)
	 * @see java.lang.Object#toString()
	 */
	@Override
	public String toString() {
		return "AbstractOpenVATask";
	}


	
	
}
