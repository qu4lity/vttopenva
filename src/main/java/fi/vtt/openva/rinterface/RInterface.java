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

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.stream.Collectors;


public class RInterface {
	ExecutorService es = Executors.newSingleThreadExecutor();
	protected LinkedBlockingQueue<String> queue = new LinkedBlockingQueue<String>();
	String rscriptExec;
	
	public RInterface(String rscriptExec) {
		this.rscriptExec = rscriptExec;
	}

	public List<String> listRfiles() throws IOException {
		Path pp = Paths.get("R");
        Path absolutePath = pp.toAbsolutePath();

        System.out.println(absolutePath.toString());
		return Files.find(absolutePath, 100,
			    (p, a) -> p.toString().toLowerCase().endsWith(".r"))
			    .map(path -> path.toString())
			    .collect(Collectors.toList());
		
				
	}
	
	public void newTask(Map<String, String> queryMap, String rscript, String rCommonFileName, String outRscript, String outCommonfile, String outputfile) {
		RrunnableListener listener = new RrunnableListenerImpl(queue);
    	Rrunnable r = new Rrunnable(listener, queryMap,rscript,  rCommonFileName, outRscript,outCommonfile,outputfile,rscriptExec);
    	es.submit(r);
	}
	
	
	public String getResult() throws InterruptedException {
		return queue.take();
	}

}
