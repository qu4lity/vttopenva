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

import java.util.List;

import com.revo.deployr.client.broker.RTask;
import com.revo.deployr.client.broker.RTaskResult;
import com.revo.deployr.client.data.RData;

import fi.vtt.openva.service.OpenVAService;

// TODO: Auto-generated Javadoc
/**
 * The Interface OpenVATask.
 *
 * @author Markus Ylikerälä
 */
public interface OpenVATask {	
	
	/**
	 * On task completed.
	 *
	 * @param rTask the r task
	 * @param rTaskResult the r task result
	 */
	void onTaskCompleted(RTask rTask, RTaskResult rTaskResult);	
	
	/**
	 * Gets the output.
	 *
	 * @return the output
	 */
	List<String> getOutput();
	
	/**
	 * Gets the input.
	 *
	 * @return the input
	 */
	List<RData> getInput();
	
	/**
	 * Gets the script.
	 *
	 * @return the script
	 */
	String getScript();	
	
	/**
	 * Gets the result.
	 *
	 * @param openVAService the open VA service
	 * @return the result
	 * @throws InterruptedException the interrupted exception
	 */
	String getResult(OpenVAService openVAService) throws InterruptedException;
	
	/**
	 * On task error.
	 *
	 * @param rTask the r task
	 * @param throwable the throwable
	 */
	void onTaskError(RTask rTask, Throwable throwable);
	
	/**
	 * On runtime error.
	 *
	 * @param throwable the throwable
	 */
	void onRuntimeError(Throwable throwable);
	
	/**
	 * On error.
	 *
	 * @param msg the msg
	 */
	void onError(String msg);
}
