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
//
// @author Pekka Siltanen

app.factory('analysisService',['$http','$window',function($http,$window){
		return {

		    /**
		     * run: a function for running analytics
		     * 
		     * @function
		     * @param {string} analysisId the identifier of analysis to be run. Must be known by OpenVA server.
		     * @param {string} params parameters parameters used by the analytics engine. json string {"params":[{"param1": "value1"}, {"param2":"value2"}...]}
		     * @return {string} json string response
		     */
			run : function(analysisId, params){
				var parameters = params.params;
				var oitype = "ship";
				var paramString = "?";
				parameters.push({oitype: oitype});
				for(var i=0; i< parameters.length; i++)
				{
					for(var keys = Object.keys(parameters[i]), j = 0, end = keys.length; j < end; j++) {
						var key = keys[j], 
						value = parameters[i][key];
						if (value == "") {
							value = "null";
						}
						paramString += key + "=" + value;
					}									
					if (i< parameters.length -1) {
						paramString+="&"
					}
				}
				
				return $http({url:'query/' + analysisId +"/params" +paramString, method:"GET", timeout:60*60*1000})
				.then(function(response){ 
					if (typeof response.data === 'string' || response.data instanceof String) {
						// this is a hack to handle session time out redirection
						$window.alert('Command failed. Please login again.')
						$window.location.href = '/logout'
					} else {
						return response.data;
					}					 
				},function(response){ 
					if (response.status == -1) {
						return ({error: "OpenVA script: Timeout error."})
					} else {
							$window.alert('Database query failed. If the problem recurs, please contact software administrator.');
					}
					
				});
				
				
			},
			cancel : function(){
				return $http({url:'query/cancelAnalysis', method:"GET"})
					.then(function(response){ 
				return response; 
			},function(response){ 
					connectionError();			
			});			
		}
		}
	}]);
