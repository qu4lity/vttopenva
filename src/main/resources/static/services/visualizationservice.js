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

app.factory('visualizationService',['analysisService', 'parameterService','$timeout',function(analysisService, parameterService,$timeout){
		var visualizations = []; 
		var spinner = [];
		
		function startSpinner (id) {
			spinner[id] = showSpinner(id);
			return spinner;
		}
		
		function endSpinner(id) {
			spinner[id].stop();
			spinner[id] = null;
		}
		
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
		}
		
		function add(id){
			var template = "./templates/visualizations/visualization.html";	
			var visualisation = { 
									template: template,
									id: id
								};
			visualizations.push(visualisation);
			return template;
		}
		
		function addOpeningVisualizations() {
//			parameterService.setVisualizationMethod("SailingBar");
//			add("-opening-start1");
//			$timeout(function(){ 
//				parameterService.setVisualizationMethod("FuelOilBar");
//				add("-opening-start2");
//				$timeout(function(){ 
//					parameterService.setVisualizationMethod("AuxBar");
//					add("opening--start3");
//					$timeout( function(){ 
//						parameterService.clearVariables();
//						parameterService.clearObjects();
//					}, 2500);
//				}, 2500);
//			}, 2500);
		}
		
		function runAnalysis(id,chartFunction,onClick,tooltip,params) {
			startSpinner(id);
			analysisService.run(parameterService.getVisualizationMethod(),params).then(function(response) { 
				var window = {width: 640, height:640};
				var position = ((visualizations.length%10)*10)%150;
				window.top = position;
				window.left = position;
				endSpinner(id);
				if (response == null) {
					return;
				}
				if ("error" in response) {
					showError("<strong>"+ response.error + "</strong>", id,parameterService.getVisualizationTitle(), window);
					return;
				}

				if ("warning" in response){
					showError("<strong>"+response.warning+ "</strong>" , id, parameterService.getVisualizationTitle(), window);
				}
				if (response.imagetype == "raster") {
					if (response.width != null && response.height != null) {
						showImage(response.image,id,parameterService.getVisualizationTitle(), window, response.width + 50, response.height + 90);
					} else {
						showImage(response.image,id,parameterService.getVisualizationTitle(), window,null,null);
					}	 
				} else if (response.imagetype == "vector") {
					showSvg(response.image,id,parameterService.getVisualizationTitle(), window);
				} else if (response.imagetype == "data") {
					showNode(showRawdata(response),response.filename,parameterService.getVisualizationTitle(), window, response.width, response.height);
				} else if (response.imagetype == "pdf") {
//					if (response.width != null && response.height != null) {
//						showNode(showPdfFile(response),response.file,parameterService.getVisualizationTitle(), window, parseInt(response.width) + 50, parseInt(response.height) + 70);
//					} else {
//						showNode(showPdfFile(response),response.file,parameterService.getVisualizationTitle(), window, null, null);
//					}      
					showNode(showLink(response.file),response.file,parameterService.getVisualizationTitle(), window, null, null);
				} else if (response.imagetype == "multi_pdf") {
//					var size = Object.keys(response).length-1;
//					for (var  i=1; i< size; i++ ) {
//						var fileName = "file_" + i;
//						if (response.width != null && response.height != null) {
//							showNode(showPdfFile(response[chartName]),response[chartName].file,parameterService.getVisualizationTitle(), window, response.width + 50, response.height + 70);
//						} else {
//							showNode(showPdfFile(response),response.file,parameterService.getVisualizationTitle(), window, null, null);
//						} 
//					}
				} else if (response.imagetype == "multi_interactive"){
//					var size = Object.keys(response).length-1;
//					for (var i=1; i< size; i++ ) {
//						var chartName = "chart_" + i;
//						showChart(chartFunction(response[chartName],window,id,parameterService.getVisualizationMethod()), id,parameterService.getVisualizationTitle(), window);
//					}
				} else if (response.imagetype == "interactive"){
					showChart(chartFunction(response,window,id,parameterService.getVisualizationMethod()), id,parameterService.getVisualizationTitle(), window);
				} else {
					showError("<strong>Imagetype " + response.imagetype + " not supported</strong>" , id, parameterService.getVisualizationTitle(), window);
				}
			});
			return;
		}
		
		function run(id,chartFunction,onClick,tooltip) {
			var par = parameterService.getAllSelected();				
			var params = {
					"params":[
					    {"oiids": par.selectedObjects}, 
					    {"varids": par.selectedVariables},
					    {"starttime":par.startTime},
					    {"endtime":par.endTime},
					    {"timeunit":par.timeUnit},
					    {"imagetype":par.imagetype},
					]
				}
			
			runAnalysis(id,chartFunction,onClick,tooltip,params);
			return;
		}
		
		return {
			startSpinner: startSpinner,
			endSpinner: startSpinner,
			addOpeningVisualizations: addOpeningVisualizations,
			add : add,	

			run : run,
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
	return;
}

function showImage(imgsrc,id,title,window,width,height){		
	var draggableId = draggable(title, window.top,window.left,"centerdiv",width,height);
	$('#' + id).prepend('<img style="height: 100%; width: 100%; object-fit: contain" src="' + imgsrc + '" />');
	document.getElementById(draggableId).appendChild(d3.select("#" + id + "> img").node());	
	return;
}

function showNode(node,src,title,window,width,height){		
	var draggableId = draggable(title, window.top,window.left,"centerdiv",width,height);
	document.getElementById(draggableId).appendChild(node);	
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

function showLink(url){		
	var node = $("<a class='downloadLink' href='"+ url + "' target='_blank'\>Open file</a>").get(0);
	return node;	
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
//this is a really old legacy jQuery code that will be removed as soon as I have time
function draggable (heading, top, left,parentId,width,height) {
//	var target = document.getElementById(parentId);
//	var pos ="" + left +" " + top;	

	if (width == null || height == null) {
		width = "auto";
		height = "auto";
	}
	
	var $result = $("<div>", {title: heading});
	var resultId = $result.uniqueId().attr("id");

	var $dialog = $result.dialog({
		position: {
			my: 'left top',
			at: 'left',
			of: $('#centerdiv')
		},
		// hack trying to stop jumping to top 
		dragStop: function(event, ui) {
		        var iObj = ui.offset;
		        if (iObj.top < 0) {
		        	event.target.offsetParent.style.top = "0px";
		        }
		    },
		draggable: true,
		appendTo: '#' + parentId,
		height:height,
		width:width,
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




