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

(function () {
	'use strict';

	var counter = 0;
	var oldValues = [];
	
	
	angular.module('app')
	.controller('selectedObjectsController', ["$scope","$rootScope", "parameterService","metadataService","visualizationService","configurationService", function ($scope, $rootScope,	parameterService,metadataService,visualizationService,configurationService) {
		   $scope.data = {
				    ois:  [],
		   };
		
		
		$scope.removeOI = function(node) { 
				var item = node.$modelValue;
				var index = $scope.data.ois.indexOf(item);
				$scope.data.ois.splice(index, 1);  
				parameterService.removeSelectedParameter(item); 
				if ($scope.data.ois.length == 0) {
					parameterService.clearParameters("m");
				}
		}    
		   
		$scope.$watch(function () { 
				return parameterService.getObjects();         
			}, function (value) {
				$scope.data.ois = value; 
				if($scope.data.ois.length == 0) {
					parameterService.clearObjects();
					parameterService.clearVariables();
					$scope.data.vars = [];
					$rootScope.setVisualizations([]);
				} else {
					var oisString = Array.prototype.map.call($scope.data.ois, function(item) { return item.id; }).join(",");
					var varString = Array.prototype.map.call($scope.data.vars, function(item) { return item.id; }).join(",");
					if (oisString.length > 0 && varString.length >0) {
						metadataService.getVisualizationCandidates( oisString, varString, configurationService.getConfigurationInfo().applicationTitle).then(function(response) { 
							var visualizations = [];
							var specialVisualizations = [];
							$.each(response, function(i, item) {
								if (item.engine != "none") {
									var dataItem = {"id": i, "title": item.title,  "visid":item.method.toLowerCase(),"method":item.method,"nodes": []} 
									if (configurationService.getConfigurationInfo().specialVisualizations.indexOf(dataItem.method) > -1) {
										specialVisualizations.push(dataItem);
									} else {
										visualizations.push(dataItem);
									}
								}
							});
							$scope.data.visualizations = visualizations;
							$rootScope.setVisualizations(visualizations);
							parameterService.setSpecialVisualizations(specialVisualizations);
						});	
					}
				}
		},true);

		$scope.$watch(function () { 
			return parameterService.getVariables();         
		}, function (value) {
			$scope.data.vars = value;
			if($scope.data.vars.length == 0) {
				parameterService.clearVariables();
				$scope.data.vars = [];
				$scope.data.visualizations = [];
				oldValues = [];
			} else {
				// no need to update UI if nothing has changed
				if (oldValues.length == $scope.data.vars.length) {
					return;
				}
				oldValues = $scope.data.vars;
				var oisString = Array.prototype.map.call($scope.data.ois, function(item) { return item.id; }).join(",");
				var varString = Array.prototype.map.call($scope.data.vars, function(item) { return item.id; }).join(",");
				if (oisString.length > 0 && varString.length >0) {
					metadataService.getVisualizationCandidates( oisString, varString, configurationService.getConfigurationInfo().applicationTitle).then(function(response) { 
						var visualizations = [];
						var specialVisualizations = [];
						$.each(response, function(i, item) {
							if (item.engine != "none") {
								var dataItem = {"id": i, "title": item.title, "visid":item.method.toLowerCase(),"method":item.method,"nodes": []} 
								if (configurationService.getConfigurationInfo().specialVisualizations.indexOf(dataItem.method) > -1) {
									specialVisualizations.push(dataItem);
								} else {
									visualizations.push(dataItem);
								}
								
							}
						});
						$scope.data.visualizations = visualizations;
						$rootScope.setVisualizations(visualizations);
						parameterService.setSpecialVisualizations(specialVisualizations);
					});	
				}
			}
		},true);
		
	}]);

}());

