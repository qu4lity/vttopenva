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

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.io.IOUtils;

public class PythonRunnable implements Runnable {

	Map<String, String> scriptParams;	
	String pythonScript;
	String outputfile;
	String pythonScriptExec;

	PythonRunnableListener listener;
	String pythonOutputFolder;
	String pythonImportModule;

	public PythonRunnable(PythonRunnableListener listener, Map<String, String> queryMap, String pythonScript_, String outputfile_, String pythonScriptExec_, String pythonOutputFolder_, String pythonImportModule_) {
		this.listener = listener;
		this.scriptParams = new HashMap<String,String>(queryMap);
		this.pythonScript = pythonScript_;
		this.outputfile = outputfile_;
		this.pythonScriptExec = pythonScriptExec_;
		this.pythonOutputFolder = pythonOutputFolder_;
		this.pythonImportModule = pythonImportModule_;
	}




	@Override
	public void run() {

		try {

			Process pr = null;
			Runtime rt = Runtime.getRuntime();

			List<String> process_args = new ArrayList<String>();
			process_args.add(this.pythonScriptExec);
			//process_args.add(this.pythonScriptExec + " -u"); //this would print log while running the script?
			   
			


			String scriptFileName = this.pythonScript;
			String content;
			URL url = getClass().getResource(this.pythonScript); 
			if (url != null) {
				content = extractContent(this.pythonScript);
				scriptFileName = writeContent(content, this.pythonScript);

				if (this.pythonImportModule!=null) {
					content = extractContent(this.pythonImportModule);
					writeContent(content, this.pythonImportModule);
				}
			}
			
			process_args.add(scriptFileName);
			System.out.println("scriptFileName " + scriptFileName);
			String paramString = "";
			for (Map.Entry<String, String> entry : this.scriptParams.entrySet())
			{
				if (entry.getValue().contains(" ")) {
					paramString =  paramString + " " + entry.getKey() +"="  + "\"" + entry.getValue() + "\"";
//					process_args.add(entry.getKey() +"="  + "\"" + entry.getValue() + "\"");
				} else {
					paramString =  paramString + " " + entry.getKey() +"="  +entry.getValue();
					
				}
				process_args.add(entry.getKey() +"="  +entry.getValue());
			}
			System.out.println(this.pythonScript + " # " + paramString);
			System.err.println(process_args.toString());
			
			pr = rt.exec(process_args.toArray(new String[] {}));
			//pr = rt.exec(this.pythonScriptExec + " " + scriptFileName + paramString); 
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




	private String writeContent(String content, String fileName) throws IOException {
		String scriptFileName;
		File f = new File(fileName);					
		scriptFileName = this.pythonOutputFolder +  f.getAbsolutePath().substring(f.getAbsolutePath().lastIndexOf(File.separator)+1);		
		Path outpath = Paths.get(scriptFileName);
		outpath.toAbsolutePath();		
		Files.write(outpath, content.getBytes(StandardCharsets.UTF_8));
		return scriptFileName;
	}

	private String extractContent(String fileName) throws IOException {
		String content;
		URL url = getClass().getResource(fileName); 
		// filename refers to a file within a jar
		InputStream in = url.openStream(); 
		content = IOUtils.toString(in, StandardCharsets.UTF_8);
		return content;
	}

}
