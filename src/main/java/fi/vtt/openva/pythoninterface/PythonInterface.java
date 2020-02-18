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

package fi.vtt.openva.pythoninterface;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;


public class PythonInterface {
	ScheduledExecutorService es = Executors.newScheduledThreadPool(2); 
	protected LinkedBlockingQueue<String> queue = new LinkedBlockingQueue<String>();
	String pythonScriptExec;
	
	public PythonInterface(String pythonScriptExec_) {
		this.pythonScriptExec = pythonScriptExec_;
	}

	
	public void newTask(Map<String, String> queryMap, String pythonScript, String outputfile, String pythonOutputFolder, String pythonImportModule, Integer timeout) {
		PythonRunnableListener listener = new PythonRunnableListenerImpl(queue);
    	PythonRunnable r = new PythonRunnable(listener, queryMap,pythonScript, outputfile,this.pythonScriptExec, pythonOutputFolder, pythonImportModule);
    	final Future<?> handler = es.submit(r);
    	es.schedule(new Runnable(){
    	     public void run(){
 				try {
 					if (!handler.isDone()) {
 	 					handler.cancel(true);
 	 					Path outpath = Paths.get(outputfile);
 	 					outpath.toAbsolutePath();
 	 					String message = "{\"error\": \"OpenVA error : Timeout occured while running script\" }";
 						Files.write(outpath, message.getBytes(StandardCharsets.UTF_8));
 						listener.onFinished(outputfile);
 					}
				} catch (IOException e) {
					e.printStackTrace();
				} catch (InterruptedException e) {
					e.printStackTrace();
				}

    	     }      
    	 }, timeout-2, TimeUnit.SECONDS); // timeout-2: task must be cancelled before SpringBoot makes session timeout
	}
	
	
	public String getResult() throws InterruptedException {
		String result = queue.take();
		return result;
	}

}
