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

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

import org.apache.commons.io.IOUtils;

public class Rrunnable implements Runnable {

	Map<String, String> scriptParams;	
	String rscript;
	String outRscript;
	String commonFile;
	String ouCommonFile;
	String outputfile;
	String rscriptExec;

	RrunnableListener listener;

	public Rrunnable(RrunnableListener listener, Map<String, String> queryMap, String rscript_, String rCommonFileName, String outRscript_, String outCommonFileName, String outputfile_, String rscriptExec_) {
		this.listener = listener;
		this.scriptParams = new HashMap<String,String>(queryMap);
		this.rscript = rscript_;
		this.commonFile = rCommonFileName;
		this.outRscript = outRscript_;
		this.ouCommonFile = outCommonFileName;
		this.outputfile = outputfile_;
		this.rscriptExec = rscriptExec_;
	}




	@Override
	public void run() {

		try {
			updateR();

			Process pr = null;
			Runtime rt = Runtime.getRuntime();
			pr = rt.exec(rscriptExec + " " + outRscript); 
			BufferedReader input = new BufferedReader(new InputStreamReader(pr.getInputStream()));

			String line=null;

			while((line=input.readLine()) != null) {
				System.out.println(line);
			}

			BufferedReader error = new BufferedReader(new InputStreamReader(pr.getErrorStream()));

			while((line=error.readLine()) != null) {
				System.out.println(line);
			}

			pr.waitFor();
			this.listener.onFinished(outputfile);
		} catch (Exception e) {
			Path outpath = Paths.get(outputfile);
			outpath.toAbsolutePath();
			try {
				String message = "{\"error\": \"OpenVA error : " + e.getMessage().replace("\"","\\\"") + "\" }";
				Files.write(outpath, message.getBytes(StandardCharsets.UTF_8));
				this.listener.onFinished(outputfile);
			} catch (IOException e1) {
				e1.printStackTrace();
			} catch (InterruptedException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}
		}
	}

	private void updateR() throws IOException, URISyntaxException {
		String content;			
		content = extractContent(this.rscript);
		for (Map.Entry<String, String> entry : this.scriptParams.entrySet())
		{
			content = content.replaceAll("<" + entry.getKey() +">", entry.getValue());
		}
		writeContent(content, this.outRscript);

		if (this.commonFile != null) {
			content = extractContent(this.commonFile);
			writeContent(content, this.ouCommonFile);
		}		
	}




	private void writeContent(String content, String fileName) throws IOException {
		Path outpath = Paths.get(fileName);
		outpath.toAbsolutePath();
		Files.write(outpath, content.getBytes(StandardCharsets.UTF_8));
	}


	private String extractContent(String fileName) throws IOException {
		String content;
		URL url = getClass().getResource(fileName); 
		if (url != null) {
			// filename refers to a file within a jar
			//System.out.println("filename refers to a file within a jar" + " "+ fileName);
			InputStream in = url.openStream(); 
			content = IOUtils.toString(in, StandardCharsets.UTF_8);
		} else {
			// this is for testing in IDE
			content = new String(Files.readAllBytes( Paths.get(fileName)), StandardCharsets.UTF_8);	
		}
		return content;
	}
}
