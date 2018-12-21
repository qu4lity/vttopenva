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

app.factory('visualizationService',['$rootScope','analysisService', 'parameterService',function($rootScope,analysisService, parameterService){
		var visualizations = []; 
		var visCounter = 0;
		var spinner = [];
		
		function startAnalysis (id) {
			spinner[id] = showSpinner(id);
			return spinner;
		};
		
		function endAnalysis(id) {
			spinner[id].stop();
			spinner[id] = null;
		};
		
		function showSpinner(id) {
			var opts = {
					  lines: 13 // The number of lines to draw
					, length: 28 // The length of each line
					, width: 14 // The line thickness
					, radius: 42 // The radius of the inner circle
					, scale: 1 // Scales overall size of the spinner
					, corners: 1 // Corner roundness (0..1)
					, color: '#000' // #rgb or #rrggbb or array of colors
					, opacity: 0.25 // Opacity of the lines
					, rotate: 0 // The rotation offset
					, direction: 1 // 1: clockwise, -1: counterclockwise
					, speed: 1 // Rounds per second
					, trail: 60 // Afterglow percentage
					, fps: 20 // Frames per second when using setTimeout() as a fallback for CSS
					, zIndex: 2e9 // The z-index (defaults to 2000000000)
					, className: 'spinner' // The CSS class to assign to the spinner
					, top: '50%' // Top position relative to parent
					, left: '50%' // Left position relative to parent
					, shadow: false // Whether to render a shadow
					, hwaccel: false // Whether to use hardware acceleration
					, position: 'absolute' // Element positioning
					}
					var target = document.getElementById(id)
					return new Spinner(opts).spin(target);
		};
		
		return {
			startAnalysis: startAnalysis,
			endAnalysis: endAnalysis,
			add : function(id){
				var template = "./templates/visualizations/visualization.html";	
				var visualisation = { 
										template: template,
										id: id
									};
				visualizations.push(visualisation);
				return template;
			},	

			run : function(id,chartFunction,onClick,tooltip) {
				var selectedObjects = parameterService.getObjectIds();
				var selectedVariables = parameterService.getVariableIds(); 
				var startTime = parameterService.getStartDateTime();
				var endTime = parameterService.getEndDateTime();			
				var timeUnit = parameterService.getTimeUnit();
				var imagetype = parameterService.getImageType();
				
				var selectedVariableObjects = parameterService.getParametersByType("m");
				for (var i = 0; i<selectedVariableObjects.length; i++ ){
					selectedVariables.push(selectedVariableObjects[i].id);
				}
				selectedVariableObjects = parameterService.getParametersByType("i");
				for (var i = 0; i<selectedVariableObjects.length; i++ ){
					selectedVariables.push(selectedVariableObjects[i].id);
				}
				var filters = [];
				var codeNames = ['site','sample_class','plant_species','plant_organ','year','sample_type','ashtype'];
				for (var i = 0; i<codeNames.length; i++ ){
					var codeName = codeNames[i];
					var codeFilters = parameterService.getParametersByType(codeName);
					for (var j=0; j<codeFilters.length; j++) {
						var data = new Object();
						filter = codeName + "=" + codeFilters[j].id;
						filters.push(filter);
					}
				}
				
				var params = {
						"params":[
						    {"oiids": selectedObjects}, 
						    {"varids":selectedVariables},
						    {"ois_filter_list":filters},
						    {"starttime":startTime},
						    {"endtime":endTime},
						    {"timeunit":timeUnit},
						    {"imagetype":imagetype},
						]
					}
				startAnalysis(id);
				analysisService.run(parameterService.getVisualizationMethod(),params).then(function(response) { 
					var window = {width: 640, height:640};
					var position = ((visualizations.length%10)*10)%150;
					window.top = position;
					window.left = position;
					endAnalysis(id);
					if (response == null) {
						return;
					}
		        	if ("error" in response) {
		        		var leadingText  = "DeployR script: ";
		        		var errorMsg = response.error.substring(response.error.indexOf(leadingText) + leadingText.length, response.error.length);
		        		showError("<strong>"+ errorMsg + "</strong>", id,parameterService.getVisualizationTitle(), window);
		        		return;
		        	}

		        	if ("warning" in response){
		        		showError(response.warning, id,parameterService.getVisualizationTitle(), window);
		        	}
		        	if (response.imagetype == "raster") {
		        		showImage(response.image,id,parameterService.getVisualizationTitle(), window);
		        	} else if (response.imagetype == "vector") {
		        		showSvg(response.image,id,parameterService.getVisualizationTitle(), window);
		        	} else if (response.imagetype == "data") {
		        		showLink(showRawdata(response), id,parameterService.getVisualizationTitle(), window);
		        	} else if (response.imagetype == "multi_interactive"){
		        		var size = Object.keys(response).length-1;
		        		for (var  i=1; i< size; i++ ) {
		        			var chartName = "chart_" + i;
		        			showChart(chartFunction(response[chartName],window,id,parameterService.getVisualizationMethod()), id,parameterService.getVisualizationTitle(), window);
		        		}
		        	} else {
		        		showChart(chartFunction(response,window,id,parameterService.getVisualizationMethod()), id,parameterService.getVisualizationTitle(), window);
		        	}
				});
				return;
			},
			show : function(node, id,title, window){
				var a= node.parentNode;
				var isComposed = false;
				while (a && a.parentNode) {
					if (a.getAttribute("class") != null && a.getAttribute("class").indexOf("composed") !== -1) {
						console.log(a.getAttribute("class"));
						isComposed = true;
						break;
					}
				    a = a.parentNode;				    
				}
				
				if (!isComposed) {
					var draggableId = draggable(title, window.top,window.left,id);
					document.getElementById(draggableId).appendChild(node);	
				}
				return;
			},	
			remove : function(){
				visualizations = [];
				return 0;
			}, 
			get: function() {
				return visualizations;
			}
		}
	}]);

//TODO: adding dialog to centerdiv is a hack: clicking dialog seems to bring dialog on top only
//if all the dialogs are under same div

function showError(error,id,title,window){		
	var draggableId = draggable(title + " message", window.top,window.left,"centerdiv");
	$('#' + id).prepend('<strong>' + error +'</strong>');
	document.getElementById(draggableId).appendChild(d3.select("#" + id + "> strong").node());	
	//removeSvgNode(id);
	return;
}



function showImage(imgsrc,id,title,window){		
	var draggableId = draggable(title, window.top,window.left,"centerdiv");
	$('#' + id).prepend('<img style="height: 100%; width: 100%; object-fit: contain" src="' + imgsrc + '" />');
	document.getElementById(draggableId).appendChild(d3.select("#" + id + "> img").node());	
	//removeSvgNode(id);
	return;
}

function showSvg(imgsrc,id,title,window){		
	var draggableId = draggable(title, window.top,window.left,"centerdiv");
	
	d3.xml(imgsrc).mimeType("image/svg+xml").get(function(error, xml) {
		   if (error) throw error;
		   var svg = d3.select('#' + id).node().appendChild(xml.documentElement);
		   svg.setAttribute("id", id + '-svg');
		   svg.setAttribute("width", window.width);
		   svg.setAttribute("height", window.height);
		   var svgZoom = svgPanZoom('#' + id + '-svg' , {
			   center: false,
			   zoomEnabled: true,
			   panEnabled: true,
			   controlIconsEnabled: true,
			   fit: true,
			   minZoom: 0.5,
			   maxZoom:4,
			   zoomScaleSensitivity: 0.5
		   });
		   document.getElementById(draggableId).appendChild(svg);
		   //removeSvgNode(id);
	});
}

function showLink(node,id,title,window){		
	var draggableId = draggable(title, window.top,window.left,"centerdiv");
	document.getElementById(draggableId).appendChild(node);	
	//removeSvgNode(id);
	return;
}

function showChart(node, id,title, window){
	  var draggableId = draggable(title, window.top,window.left,"centerdiv");
	  var svg = node.children[0];
	   svg.setAttribute("width", window.width);
	   svg.setAttribute("height", window.height);
	   var svgZoom = svgPanZoom('#svg-' + id, {
		   center: false,
		   zoomEnabled: true,
		   panEnabled: true,
		   controlIconsEnabled: true,
		   fit: true,
		   minZoom: 0.5,
		   maxZoom:4,
		   zoomScaleSensitivity: 0.5
	   });
	   document.getElementById(draggableId).appendChild(svg);   
	   //removeSvgNode(id);
	return;
}


// this is a hack to remove svgnode where images should be added.
// draggable div does not work correctly if all draggables are not
// under same div, so it was easier to hack this so that all draggables are 
// placed under same parent centerdiv
function removeSvgNode(id) {
	   var addedNode = document.getElementById(id);
	   var parent = addedNode.parentNode;
	   while (parent.firstChild) {
		   parent.removeChild(parent.firstChild);
		}
//	   addedNode.parentNode.RemoveChild(id);
}


function draggable (heading, top, left,parentId) {
	var target = document.getElementById(parentId);
	
	var $result = $("<div>", {title: heading});
	var resultId = $result.uniqueId().attr("id");

	var pos ="" + left +" " + top;
	var $dialog = $result.dialog({
		position: {
			my: 'left top',
			at: 'left',
			of: $('#centerdiv')
		},
		draggable: true,
		appendTo: '#' + parentId,
		height:'auto',
		width:'auto'
	})
	.parent().draggable({
		containment: '#centerdiv' 
	});	

	$dialog.css({"top": top, "left" : left})

	var $parent = $dialog.parent(),
        $button = $parent.find( ".ui-dialog-titlebar-close" );
	
	$button
	  .contents()
	  .filter(function() {
	    return this.nodeType == 3; //Remove TEXT_NODE
	  }).remove();
	
	return resultId;
}




