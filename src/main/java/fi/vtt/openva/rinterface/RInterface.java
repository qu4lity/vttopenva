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

package fi.vtt.openva.rinterface;

import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;


public class RInterface {
	
	ExecutorService es = Executors.newSingleThreadExecutor(); 

	// queue is a queue for task results
	protected LinkedBlockingQueue<String> queue = new LinkedBlockingQueue<String>();
	// tasks is a queue for tasks
	protected LinkedBlockingQueue<Rrunnable> tasks = new LinkedBlockingQueue<Rrunnable>();
	// handlers is a queue for process handlers so that the process can be cancelled
	protected LinkedBlockingQueue<Future<?>> handlers = new LinkedBlockingQueue<Future<?>>();
	
	private String rscriptExec;
	private Integer timeout;
	
	private static String OS = System.getProperty("os.name").toLowerCase();
	

	public String getRscriptExec() {
		return rscriptExec;
	}

	public void setRscriptExec(String rscriptExec) {
		this.rscriptExec = rscriptExec;
	}

	public Integer getTimeout() {
		return timeout;
	}

	public void setTimeout(Integer timeout) {
		this.timeout = timeout;
	}

	
	public RInterface() {
	}
	
	
	private void run(Rrunnable r)  {
		
    	final Future<?> handler = es.submit(r);
    	// handlers is queue for handlers that are used when cancelling running task
		handlers.add(handler);
        	
            new Thread(() -> {
					try {
			        	// wait for timeout - 10 seconds and try to get result. If still running, catch exception
			        	// same timeout should be used for session, so here timeout must be shorter to be able to return message to UI
						// must be run in a new thread so it does not block calling function
						handler.get(this.timeout - 10, TimeUnit.SECONDS);
						//handler.get(30, TimeUnit.SECONDS);
					} catch (TimeoutException e) {
		        	cancel(handler,"TimeoutException");
			        } catch (InterruptedException e) {
			        	cancel(handler,"InterruptedException");
			        } catch (ExecutionException e) {
			        	cancel(handler,"ExecutionException");
					} catch (Exception e) {
						e.printStackTrace();
					}
	        }).start();           
        return ;
	}

	public String cancelAnalysis() throws InterruptedException {
		if (!handlers.isEmpty()) {
			cancel(handlers.peek(),"InterruptedException");
			return "Cancelled";
		} else {
			return "No analysis running";
		}
	}
	
	// cancel running tasks: two reasons handled: 
	// 1) TimeoutException: time exceeded
	// 2) InterruptedException: user cancelled task
	private void cancel(final Future<?> handler, String reason) {
		handler.cancel(true);
		
		// not enough to cancel task: we need to stop process running the RScript as well
		try {
			if (OS.contains("win")) {
				Runtime.getRuntime().exec("taskkill /F /IM Rscript.exe");
			} else {
				Runtime.getRuntime().exec("killall R");
			}
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				setErrorResult(reason);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
	}
	
	public void newTask(Map<String, String> queryMap, String rscript, String rCommonFileName, String outRscript, String outCommonfile, String outputfile) throws InterruptedException {		
		RrunnableListener listener = new RrunnableListenerImpl(queue);
		Rrunnable r = new Rrunnable(listener, queryMap,rscript,  rCommonFileName, outRscript,outCommonfile,outputfile,this.rscriptExec);
			// if no tasks are running, add new and run it
    	if (tasks.isEmpty()) {
    		tasks.put(r);
    		run(r);
    	} else {
    		// if another task is running, add new task to list and wait until tasks in queu are finished 
    		tasks.put(r);
    	}

	}
	
	// add errorResult to the queue so that getResult can continue and return result to UI
	private void setErrorResult(String reason) throws InterruptedException {
		queue.put(reason);
	}
	
	// takes first item from the blocking queues, returns result to UI from result queue
	// if there are tasks in the task queue, runs next task
	public String getResult() throws InterruptedException  {
		String result = queue.take();
		tasks.take();
		handlers.take();
		if (!tasks.isEmpty()) {
			try {
				run(tasks.peek());
			} catch (Exception e) {
				throw e;
			}
		}
		return result;
	}

}
