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

app.factory('metadataService',['$http','$window',function($http,$window){
		var failed = false;
	
		function connectionError() {
			$window.alert('Database query failed. If the problem recurs, please contact software administrator.')
		}
		
		return {
			getVisualizationCandidates : function(ois,vars,applicationTitle){
				return  $http.get('query/getVisualisationCandidates/' + ois + '/' + vars + '/' + applicationTitle)
				.then(function(response){ 
					if (typeof response.data === 'string' || response.data instanceof String) {
						// this is a hack to handle session time out redirection
						if (!failed) {
							$window.alert('Command failed because of session timeout. Please login again.')
							failed = true;
							$window.location.href = '/logout'
						}
					} else {
						return response.data;
					}	
				},function(response){ 
					connectionError();
				});
			},
			getVariables : function(oiId, propertyId){
				return  $http.get('query/getVariables/' + oiId + '/' + propertyId)
				.then(function(response){
					if (typeof response.data === 'string' || response.data instanceof String) {
						// this is a hack to handle session time out redirection
						if (!failed) {
							$window.alert('Command failed because of session timeout. Please login again.')
							failed = true;
							$window.location.href = '/logout'
						}
					} else {
						return response.data;
					}	
				},function(response){ 
					connectionError();
				});
			},
			getVariablesByOiTypeTitle : function(oiTypeTitle, propertyId){
				return  $http.get('query/getVariablesByOiTypeTitle/' + oiTypeTitle + '/' + propertyId)
				.then(function(response){
					if (typeof response.data === 'string' || response.data instanceof String) {
						// this is a hack to handle session time out redirection
						if (!failed) {
							$window.alert('Command failed because of session timeout. Please login again.')
							failed = true;
							$window.location.href = '/logout'
						}
					} else {
						return response.data;
					}	
				},function(response){ 
					connectionError(); 
				});
			},
			getObjectList : function(oitypeTitle){
				return  $http.get('query/getObjectList/' + oitypeTitle).then(function(response){
					if (typeof response.data === 'string' || response.data instanceof String) {
						// this is a hack to handle session time out redirection
						if (!failed) {
							$window.alert('Command failed because of session timeout. Please login again.')
							failed = true;
							$window.location.href = '/logout'
						}
					} else {
						return response.data;
					}	
				},function(response){ 
					connectionError(); 
				});
			},
			getObjectHierarchy : function(){
				return  $http.get('query/getObjectHierarchy/').then(function(response){
					
					
					if (typeof response.data === 'string' || response.data instanceof String) {
						// this is a hack to handle session time out redirection
						if (!failed) {
							$window.alert('Command failed because of session timeout. Please login again.')
							failed = true;
							$window.location.href = '/logout'
						}
					} else {
						return response.data;
					}	
				},function(response){ 
					connectionError(); 
				});
			},
			getCodeValues : function(codeTitle){
				return  $http.get('query/getCodeValues/' + codeTitle).then(function(response){
					if (typeof response.data === 'string' || response.data instanceof String) {
						// this is a hack to handle session time out redirection
						if (!failed) {
							$window.alert('Command failed because of session timeout. Please login again.')
							failed = true;
							$window.location.href = '/logout'
						}
					} else {
						return response.data;
					}	
				},function(response){ 
					connectionError(); 
				});
			},
			getUniqueBackgroundValues : function(typePropTitle){
				return  $http.get('query/getUniqueBackgroundValues/' + typePropTitle).then(function(response){
					if (typeof response.data === 'string' || response.data instanceof String) {
						// this is a hack to handle session time out redirection
						if (!failed) {
							$window.alert('Command failed because of session timeout. Please login again.')
							failed = true;
							$window.location.href = '/logout'
						}
					} else {
						return response.data;
					}	
				},function(response){ 
					connectionError(); 
				});
			},
			getMaxMinDateTime : function(typePropTitle){
				return  $http.get('query/getMinMaxTime').then(function(response){
					if (typeof response.data === 'string' || response.data instanceof String) {
						// this is a hack to handle session time out redirection
						if (!failed) {
							$window.alert('Command failed because of session timeout. Please login again.')
							failed = true;
							$window.location.href = '/logout'
						}
					} 	
					var startYear = String(response.data[0][0].date.year);
					var endYear = String(response.data[0][1].date.year);
					
					var startMonth = String(response.data[0][0].date.month);
					if (startMonth.length==1) startMonth = "0" + startMonth;
					var endMonth = String(response.data[0][1].date.month);
					if (endMonth.length==1) endMonth = "0" + endMonth;
					
					var startDay = String(response.data[0][0].date.day);
					if (startDay.length==1) startDay = "0" + startDay;
					var endDay = String(response.data[0][1].date.day);
					if (endDay.length==1) endDay = "0" + endDay;
					
					var startHour = String(response.data[0][0].time.hour);
					if (startHour.length==1) startHour = "0" + startHour;
					var endHour = String(response.data[0][1].time.hour);
					if (endHour.length==1) endHour = "0" + endHour;
					
					var startMinute = String(response.data[0][0].time.minute);
					if (startMinute.length==1) startMinute = "0" + startMinute;
					var endMinute = String(response.data[0][1].time.minute);
					if (endMinute.length==1) endMinute = "0" + endMinute;
					
					var startSecond = String(response.data[0][0].time.second);
					if (startSecond.length==1) startSecond = "0" + startSecond;
					var endSecond = String(response.data[0][1].time.second);
					if (endSecond.length==1) endSecond = "0" + endSecond;
					var retVal = {min: startYear + "-" + startMonth + "-" + startDay + " " + startHour + ":" + startMinute + ":" + startSecond,
								  max: endYear + "-" + endMonth + "-" + endDay + " " + endHour + ":" + endMinute + ":" + endSecond};

					
					return retVal;
				},function(response){ 
					connectionError(); 
				});
			},
		}
	}])	
	

