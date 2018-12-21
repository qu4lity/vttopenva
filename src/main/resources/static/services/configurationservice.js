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

app.factory('configurationService',['parameterService','visualizationService','$timeout', function(parameterService,visualizationService,$timeout){

	function getConfigurationInfo() {
		var conf = {
						oiSelectionUi:"hierarchy",
						applicationTitle: "Vessel",
						oitype: "ship"
					}
		return conf;
	}
	
	function getTemplateName(visualizationMethod) {
		switch (visualizationMethod) {
			case "TimeSeries":
			case "TimeSeriesMany":
			case "TimeSeriesNominalBinary":
			case "TimeSeriesOneQuantOneLine":
			case "TimeSeriesOneQuantOneLinePerOi":
			case "TimeSeriesNQuantOnePlotPerOi":
			case "TimeSeriesOneQuantOnePlotPerOi":
				return "timeseries";
			default:
				return visualizationMethod.toLowerCase();
		}
	}
	
	function addOpeningVisualizations() {
		parameterService.setVisualizationMethod("SailingBar");
		visualizationService.add("-opening-start1");
		$timeout(function(){ 
			parameterService.setVisualizationMethod("FuelOilBar");
			visualizationService.add("-opening-start2");
			$timeout(function(){ 
				parameterService.setVisualizationMethod("AuxBar");
				visualizationService.add("opening--start3");
				$timeout( function(){ 
					parameterService.clearVariables();
					parameterService.clearObjects();
				}, 2500);
			}, 2500);
		}, 2500);
	}
	
	
	
	return {

		getConfigurationInfo:getConfigurationInfo,
		getTemplateName: getTemplateName,
		addOpeningVisualizations: addOpeningVisualizations
	}
}]);

app.run(['configurationService', function(configurationService) {
}]);