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
// Note: this has become obsolete: now addtionalInput in visualizationselection is used 
//     for time unit selection and other possible parameter inputs
// @author Pekka Siltanen
(function () {
	'use strict';

	angular.module('app')
	.controller('timeunitselectionController', ['$scope',"metadataService","parameterService", function ($scope,metadataService,parameterService) {
		$scope.data = {
					options: [],
					selected
		 };
		var defaultOptions = ["sec","min","hour","day","week","month","year"];
			  
		for (var i= 0; i<defaultOptions.length; i++) {
			var selected = false;
			var text = defaultOptions[i];
			var value = defaultOptions[i];
			if (value == "hour") {
				$scope.data.selected = value;
			}
			if (text == "hour") {
				text = text + " (no aggregation)";
			}
			$scope.data.options.push({value:value, selected: selected, text: text})
		}
			   
		var start = parameterService.getStartDateTime();
		var end = parameterService.getEndDateTime();		
		
		$scope.changedValue = function() {
			parameterService.setTimeUnit($scope.data.selected)
		}    
			   
		$( "#timeunitselect" ).selectmenu();
		$( "#timeunitselect" ).on( "selectmenuchange", function( event, ui ) {
			parameterService.setTimeUnit($("#timeunitselect").find(':selected').text())
		} );
	}]);
}());


