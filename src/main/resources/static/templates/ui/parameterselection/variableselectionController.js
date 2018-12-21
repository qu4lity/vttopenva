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

//control the data used by the angular-ui-tree component
//https://github.com/angular-ui-tree/angular-ui-tree

(function () {
	'use strict';

	angular.module('app')
	.controller('variableselectionController', ["$rootScope",'$scope',"metadataService","parameterService", function ($rootScope,$scope,metadataService,parameterService) {
		$scope.data = {
			oi:  [],
			index: [],
			calculated: [],			
			measurement: [],
			background: []
		};
		
		

		$rootScope.$watch('authenticated', function() {
	        if ($rootScope.authenticated == true) {
	    		metadataService.getObjectHierarchy().then(function(response) { 
	    			var data = [];
	    			$.each(response, function(i, item) {
	    				data.push(addDataItem(item,0))
	    			});
	    			$scope.data.oi = data;
	    			console.log(JSON.stringify($scope.data.oi));
	    		});
	        }
	    });
	    

		
		
		$scope.remove = function (scope) {
			scope.remove();
		};


			
		$rootScope.addVariables = function (node) {
			metadataService.getVariablesByOiTypeTitle(node.type, "i").then(function(response) { 
				var data = [];
				$.each(response, function(i, item) {
//					var dataItem = {"id": item.id, "title": item.text.substring(0, 32),  "nodes": [], nodeType: "var"} 
					var dataItem = {"id": item.id, "title": item.text,  "nodes": [], nodeType: "var", timeUnit: item.timeunit} 
					data.push(dataItem)
				});
				data.sort($scope.compare);				
			    $scope.data.index = data;
			});
			metadataService.getVariablesByOiTypeTitle(node.type, "c").then(function(response) { 
				var data = [];
				$.each(response, function(i, item) {
//					var dataItem = {"id": item.id, "title": item.text.substring(0, 32),  "nodes": [], nodeType: "var"} 
					var dataItem = {"id": item.id, "title": item.text,  "nodes": [], nodeType: "var", timeUnit: item.timeunit} 
					data.push(dataItem)
				});
				data.sort($scope.compare);				
			    $scope.data.calculated = data;
			});
			metadataService.getVariablesByOiTypeTitle(node.type, "m").then(function(response) { 
				var data = [];
				$.each(response, function(i, item) {
//					var dataItem = {"id": item.id, "title": item.text.substring(0, 32),  "nodes": [], nodeType: "var"} 
					var dataItem = {"id": item.id, "title": item.text,  "nodes": [], nodeType: "var", timeUnit: item.timeunit} 
					data.push(dataItem)
				});
				data.sort($scope.compare);				
			    $scope.data.measurement = data;
			});
			metadataService.getVariablesByOiTypeTitle(node.type, "b").then(function(response) { 
				var data = [];
				$.each(response, function(i, item) {
//					var dataItem = {"id": item.id, "title": item.text.substring(0, 32),  "nodes": [], nodeType: "var"} 
					var dataItem = {"id": item.id, "title": item.text,  "nodes": [], nodeType: "var", timeUnit: item.timeunit} 
					data.push(dataItem)
				});
				data.sort($scope.compare);
			    $scope.data.background = data;
			});
		}
		
		$scope.selectVariable = function (selected) {
			var node = selected.$modelValue;
			console.log("selected var" + node.id)
			parameterService.addSelectedVar(node);
		};
		
		$scope.compare = function(a,b) {
			  if (a.title < b.title)
				    return -1;
				  if (a.title > b.title)
				    return 1;
				  return 0;
				}
	}]);
	

}());


//function compare(a,b) {
//	  if (a.title < b.title)
//	    return -1;
//	  if (a.title > b.title)
//	    return 1;
//	  return 0;
//	}
