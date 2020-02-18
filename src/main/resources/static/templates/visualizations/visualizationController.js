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

	angular.module('app')
	.controller('visualizationController', ["$attrs","$timeout", "visualizationService",
		function ($attrs,  $timeout , visualizationService) {		
		$timeout((function() {
			var id = $attrs.id;
			visualizationService.run(id, interactiveVisualization);
		}), 0);

	}]);
}());

function interactiveVisualization(responsedata,window,id,visualizationMethod) {
	switch(visualizationMethod) {
		case "BoxPlot":
    	case "StatsBoxPlot":
    		node = boxPlotChart(responsedata,window,id);
    		break;
    	case "Histogram":
    		node = histogramChart(responsedata,window,id,visualizationMethod);
    		break;	
		case "TimeSeriesOneQuantOneLine":
		case "TimeSeriesOneQuantOnePlotPerOi":
		case "TimeSeriesNominalBinary":		
		case "TimeSeriesOneQuantNOis":
		case "TimeSeriesNQuantOnePlotPerOi":
		case "TimeSeriesOneQuantOneLinePerOi":
    		node = timeseriesChart(responsedata,window,id,visualizationMethod);
    		break;	
		case "MultiOiContour":
    		node = contourChart(responsedata,window,id,visualizationMethod);
    		break;
		case "Sum":	
		case "CalculatedValues":
		case "BackgroundValue":
    		node = singleValueChart(responsedata,window,id,visualizationMethod)
    		break;	
		case "Scatterplot":	
			node = scatterplotChart(responsedata,window,id,visualizationMethod);
    		break;
		case "CorrelationMatrix":
			node = correlationmatrixChart(responsedata,window,id,visualizationMethod);
    		break;
		case "Barchart":
    		node = barChart(responsedata,window,id,visualizationMethod);
			break;
    	default:
    		var node = $("<strong>No interactive visualisation available!</strong>").get(0);
	}	
	return node;
}