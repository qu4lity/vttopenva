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

package fi.vtt.openva.service;

import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import com.revo.deployr.client.auth.RAuthentication;
import com.revo.deployr.client.auth.basic.RBasicAuthentication;
import com.revo.deployr.client.broker.RBroker;
import com.revo.deployr.client.broker.RBrokerListener;
import com.revo.deployr.client.broker.RBrokerRuntimeStats;
import com.revo.deployr.client.broker.RTask;
import com.revo.deployr.client.broker.RTaskListener;
import com.revo.deployr.client.broker.RTaskResult;
import com.revo.deployr.client.broker.RTaskToken;
import com.revo.deployr.client.broker.config.PooledBrokerConfig;
import com.revo.deployr.client.broker.options.PoolCreationOptions;
import com.revo.deployr.client.broker.options.PoolPreloadOptions;
import com.revo.deployr.client.broker.options.PooledTaskOptions;
import com.revo.deployr.client.factory.RBrokerFactory;
import com.revo.deployr.client.factory.RTaskFactory;

import fi.vtt.openva.task.OpenVATask;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;

import org.apache.log4j.Logger;

/**
 * The Class OpenVAService. To be used only with DeployR. Will be removed in near future.
 *
 * @author Markus Ylikerälä, Pekka Siltanen
 */




@Service
public class OpenVAService implements RTaskListener, RBrokerListener {
	
	/** The deployr endpoint. */
	@Value("${deployr.inuse}")
	private Boolean deployrUsed;
	
	/** The delpoyr endpoint. */
	@Value("${deployr.url}")
	private String endpoint;
	
	/** The deployr username. */
	@Value("${deployr.username}")
	private String username;
	
	/** The deployr password. */
	@Value("${deployr.password}")
	private String password;	
	
	
	
private static Logger log = Logger.getLogger(OpenVAService.class);
	
	/** The r broker. */
	private RBroker rBroker;
	
	/** The broker config. */
	private PooledBrokerConfig brokerConfig;


	/** The hash. */
	private ConcurrentHashMap<UUID, OpenVATask> hash = new ConcurrentHashMap<UUID, OpenVATask>();

	/**
	 * Instantiates a new open VA service.
	 */
	public OpenVAService(){
	}

	/**
	 * Clean up.
	 */
	@PreDestroy
	public void cleanUp() {
		System.out.println("Im inside destroy...");
		if(rBroker != null){
			System.out.println("status..." + rBroker.status() + "#" + rBroker.isConnected());
			
			rBroker.shutdown();
			System.out.println("...just did RBroker shutdown. rBroker=" + rBroker);
		}
	}

	@PostConstruct
	public void initIt() {
		if (deployrUsed) {
			buildRBrokerRuntime();
		}
	}


	/**
 * Builds the R broker runtime.
 *
 * @return true, if successful
 */
private boolean buildRBrokerRuntime() {
		try {		
			
			
		
			RAuthentication rAuth = new RBasicAuthentication(username, password);               		               

			PoolPreloadOptions preloadOptions = new PoolPreloadOptions();
			preloadOptions.author = username;

			PoolCreationOptions poolOptions = new PoolCreationOptions();
			poolOptions.preloadWorkspace = preloadOptions;

			poolOptions.releaseGridResources = true;

			brokerConfig = new PooledBrokerConfig(endpoint,
					rAuth,
					1, //PooledBrokerConfig.MAX_CONCURRENCY,
					poolOptions);
			brokerConfig.allowSelfSignedSSLCert = true;

			rBroker = RBrokerFactory.pooledTaskBroker(brokerConfig);
			
			log.info("RBroker pool initialized with " +
					rBroker.maxConcurrency() + " R sessions.");

			rBroker.addTaskListener(this);
			rBroker.addBrokerListener(this);
			
			return true;

		} catch(Exception ex) {
			log.warn("OpenVAService: init ex=" + ex);
			ex.printStackTrace();
			System.err.println("BIZARRE Couldn restart DeployR:" + ex);
			return false;
		}
	}

	/*
	 * @see com.revo.deployr.client.broker.RTaskListener#onTaskCompleted(com.revo.deployr.client.broker.RTask, com.revo.deployr.client.broker.RTaskResult)
	 */
	public void onTaskCompleted(RTask rTask, RTaskResult rTaskResult) {
		OpenVATask openVATask = null;
		try{
			log.info("OpenVAService onTaskCompleted." + rTask + "#" + rTask.getToken() + "#" + rTaskResult + "#" + rTaskResult.getID() + "#" + rTask.getToken());
			openVATask = hash.remove(rTask.getToken());
			openVATask.onTaskCompleted(rTask, rTaskResult);
		}
		catch(Throwable t){
			t.printStackTrace();
			openVATask.onError("Analytics engine failed: " + t);	
		}
	}

	/* 
	 * @see com.revo.deployr.client.broker.RBrokerListener#onRuntimeStats(com.revo.deployr.client.broker.RBrokerRuntimeStats, int)
	 */
	public void onRuntimeStats(RBrokerRuntimeStats stats, int maxConcurrency) {  	
		log.info("OpenVAService onRuntimeStats: totalTasksRun " + stats.totalTasksRun + " totalTasksRunToFailure " + stats.totalTasksRunToFailure + " totalTasksRunToSuccess " + stats.totalTasksRunToSuccess + " totalTimeTasksOnCall " + stats.totalTimeTasksOnCall 
				+ " totalTimeTasksOnCode " + stats.totalTimeTasksOnCode + " totalTimeTasksOnServer " + stats.totalTimeTasksOnServer);       
	}

	/* 
	 * @see com.revo.deployr.client.broker.RBrokerListener#onRuntimeError(java.lang.Throwable)
	 */
	public void onRuntimeError(Throwable t) {       
		System.err.println("\n\n@@@BIZARRE onRuntimeError: " + t + "#" + LocalDateTime.now());
		t.printStackTrace();
		log.info("OpenVAService onRuntimeError: " + t);
		handleDeployr(t);
	}

	/* 
	 * @see com.revo.deployr.client.broker.RTaskListener#onTaskError(com.revo.deployr.client.broker.RTask, java.lang.Throwable)
	 */
	public void onTaskError(RTask rTask, Throwable t) {
		System.err.println("\n\n@@@BIZARRE onTaskError: " + t + "#" + LocalDateTime.now());
		t.printStackTrace();
		log.info("OpenVAService onTaskError: " + t);
		OpenVATask openVATask = hash.remove(rTask.getToken());
		openVATask.onTaskError(rTask, t);				

		handleDeployr(t);
	}

	/**
	 * Handle deployr.
	 *
	 * @param t the t
	 */
	private synchronized void handleDeployr(Throwable t) {
		try{
			if(t.toString().contains("DeployR grid failure detected")){
				System.err.println("\n\n\n@@@ Deus Ex Machina @@@ \n\n");
				String str = recycle() + "error " + t.toString();
				System.err.println("\nrecycled" + str);
			}
			else{
				System.err.println("\n\n\n@@@ BIZARRE Deus Ex Machina @@@ \n\n");
				String str ="error " + t.toString();
				System.err.println("\nrecycled" + str);
			}
			System.err.println("OpenVAService onRuntimeError: " + hash.keySet().toString());
		    for (UUID i : hash.keySet()) {
		    	OpenVATask tt = hash.get(i);
		    	System.err.println("OpenVAService onRuntimeError: " + t.getMessage());
		    	tt.onError("@@@@@@@@@@@@@@@@@@ OpenVA server internal error: please try again after few seconds!");
		    }
		}
		catch(Throwable tx)
		{
			tx.printStackTrace();
			System.err.println("\n\n\n@@@BIZARRE AGAIN " + tx);
		}
		
	}

	/**
	 * Submit.
	 *
	 * @param openVATask the open VA task
	 */
	public void submit(OpenVATask openVATask) {		
		try {
			System.err.println("@@@submit: " + openVATask);
			
			PooledTaskOptions taskOptions = new PooledTaskOptions();
			taskOptions.routputs = openVATask.getOutput();			
			taskOptions.rinputs = openVATask.getInput();
			RTask rTask = RTaskFactory.pooledTask(openVATask.getScript(), "openva", username,
					null, taskOptions);
			UUID id = UUID.randomUUID();
			rTask.setToken(id);
			hash.put(id, openVATask);			
			RTaskToken taskToken = rBroker.submit(rTask);
			
			System.err.println("Submit: " + taskToken + "#" + taskToken.getTask() + "#");
		} catch(Throwable ex) {
			ex.printStackTrace();
			System.err.println(ex);
			log.warn("OpenVAService: buildTask ex=" + ex);
			openVATask.onError("Analytics engine failed:  " + rBroker + "#" + ex);	

		}		
	}

	/**
	 * Recycle.
	 *
	 * @return the string
	 */
	public synchronized String recycle() {
		try {
			new Thread(){
				public void run(){
					cleanUp();		
					initIt();
					while(buildRBrokerRuntime() == false){
						System.err.println("Retry restarting DeployR after zzz...");
						try {
							Thread.sleep(2000);
						} catch (InterruptedException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
					}
					System.err.println("DeployR restarted");
				}}.start();
				return "Analytics engine restarted: please reload";
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Analytics engine restart failed: please contact administrator";
		}		

	}

	
	
	/**
	 * Gets the result.
	 *
	 * @param openVATask the open VA task
	 * @return the result
	 */
	public String getResult(OpenVATask openVATask) {
		try{
			System.err.println("@@@getResult BEGIN: " + openVATask);
			
			String str = null;
			if(rBroker == null){		
				String errorMsg = recycle();
				JsonObject jsonObject = new JsonObject();
				JsonPrimitive error = new JsonPrimitive(errorMsg);
				jsonObject.add("error", error);				
				str = jsonObject.toString();		
			}
			else{
				System.out.println("rBroker status..." + rBroker.status() + " isConnected:" + rBroker.isConnected());																
				submit(openVATask);
				System.err.println("@@@getResult END: " + openVATask);
				str = openVATask.getResult(this);				
			}
			return str;
		}
		catch(Throwable t){
			t.printStackTrace();
			return "Analytics engine failed: " + t;
		}
	}

	

}
