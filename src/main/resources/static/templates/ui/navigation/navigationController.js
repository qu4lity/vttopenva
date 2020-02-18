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
	.controller('navigationController', ["$scope","visualizationService","parameterService","configurationService","$window", function ($scope, visualizationService,parameterService,configurationService,$window) {
//		var self = this;
		$scope.initDone = false;

		this.logout = function() {
			$window.location.href = '/logout'
		}
		
		this.init = function(){
			
		}

	    angular.element(document).ready(function () {	    
	    	configurationService.updateStartEndTime().then(function(){
	    		var conf = configurationService.getConfigurationInfo();
	    		var startTime = moment(conf.endTime,"YYYY-MM-DD H:m:s").subtract(conf.initTimeRange,"seconds").format("YYYY-MM-DD HH:mm:ss")
	    		startTime = conf.startTime;
	    		
	    		parameterService.setEndDateTime(conf.endTime);	    	
		    	parameterService.setStartDateTime(startTime);
		    	visualizationService.addOpeningVisualizations();
		    	$scope.initDone = true;
	    	});
	    });
		
	}]);
	

}());

