//OpenVA - Open software platform for visual analytics

//Copyright (c) 2018, VTT Technical Research Centre of Finland Ltd
//All rights reserved.
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:

//1) Redistributions of source code must retain the above copyright
//notice, this list of conditions and the following disclaimer.
//2) Redistributions in binary form must reproduce the above copyright
//notice, this list of conditions and the following disclaimer in the
//documentation and/or other materials provided with the distribution.
//3) Neither the name of the VTT Technical Research Centre of Finland nor the
//names of its contributors may be used to endorse or promote products
//derived from this software without specific prior written permission.

//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY
//EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE FOR ANY
//DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// @author Pekka Siltanen

(function () {
	'use strict';

	var counter = 0;

	angular.module('app')
	.controller('additionalInputController', ["$scope", "parameterService","visualizationService", function ($scope, parameterService,visualizationService) {

		$scope.data = $scope.$parent.data;

		var defaultOptions = ["ms","sec","min","hour","day","week","month","year"];

		// get all different timeunits in the metadata
		var variables = parameterService.getVariables();
		var timeUnits = [];
		for (var i=0; i< variables.length; i++) {
			if (timeUnits.indexOf(variables[i].timeUnit) < 0) {
				timeUnits.push(variables[i].timeUnit);
			}
		}

		// get index of the biggest metadata
		var max = -1;
		for (var i=0; i< timeUnits.length; i++) {
			var index = defaultOptions.indexOf(timeUnits[i]);
			if (index > max) {
				max = index;
			}
		}

		$scope.data.options = [];
		$scope.data.selected = "";

		
		
		for (var i= max; i<defaultOptions.length; i++) {
			var selected = false;
			var text = defaultOptions[i];
			var value = defaultOptions[i];
			if (i == index) {
				$scope.data.selected = value;
				text = text + " (no aggregation)";
			}
			$scope.data.options.push({value:value, selected: selected, text: text})
		}
		var start = parameterService.getStartDateTime();
		var end = parameterService.getEndDateTime();
		
		var startMoment = moment(start);
		var endMoment = moment(end);
		var hours = endMoment.diff(startMoment,'hours');
		if (hours < 24) {
			$scope.data.selected = "sec";
		} else if (hours < 720) {
			$scope.data.selected = "min";
		} else if (hours < 8760) {
			$scope.data.selected = "hour";
		} else {
			$scope.data.selected = "day"
		}
		parameterService.setTimeUnit($scope.data.selected);

		$scope.timeUnitChanged = function(selectedValue) {
			parameterService.setTimeUnit(selectedValue);

		};

		$scope.visualize = function () {
			parameterService.setVisualizationMethod($scope.data.method);
			parameterService.setVisualizationTitle($scope.data.title);
			visualizationService.add("visualization-"+ $scope.data.counter);
			$scope.$close();
		};

		$scope.close = function () {
			$scope.$close();			
		};

	}]);



}());

