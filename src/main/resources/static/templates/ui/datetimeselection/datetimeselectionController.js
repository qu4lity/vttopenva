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
	.controller('datetimeselectionController', ['$scope',"metadataService","parameterService", function ($scope,metadataService,parameterService) {

		$('#datetimepicker').datetimepicker({
			format:'Y-m-d H:i:s'
		});

//		metadataService.getMaxMinDateTime().then(function(response) { 
//			
//			console.log(JSON.stringify(response));
			parameterService.setStartDateTime("2017-04-14 09:31:52.0");		
			parameterService.setEndDateTime("2017-05-29 08:13:31.0");
			
			jQuery(function(){
				
				 jQuery('#date_timepicker_start').datetimepicker({
				  format:'Y-m-d H:i:s',
				  defaultDate: parameterService.getStartDateTime(),
				  onShow:function( ct ){
				   this.setOptions({
				    maxDate:jQuery('#date_timepicker_end').val()?jQuery('#date_timepicker_end').val():false
				   })
				  },
				  timepicker:true,
				  onClose:function(dp,$input){
					  parameterService.setStartDateTime($input.val())
					  }
				 });

				 jQuery('#date_timepicker_end').datetimepicker({
				  format:'Y-m-d H:i:s',
				  defaultDate: parameterService.getEndDateTime(),
				  onShow:function( ct ){
				   this.setOptions({
				    minDate:jQuery('#date_timepicker_start').val()?jQuery('#date_timepicker_start').val():false
				   })
				  },
				  timepicker:true,
				  onClose:function(dp,$input){
					  parameterService.setEndDateTime($input.val())
					  }
				 });
				 jQuery('#date_timepicker_start').val("2017-04-14 09:31:52.0");
				 jQuery('#date_timepicker_end').val("2017-05-29 08:13:31.0");
				});
			
//		})
		

	}]);
}());


