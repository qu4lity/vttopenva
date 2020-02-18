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

app.factory('parameterService',['metadataService', function(metadataService){
	
		var selectedParameters = [];	
		var selectedOis = [];
		var selectedVars = [];
		var visualizations = []; 
		
	
		var startDateTime;
		var endDateTime;
		var timeUnit = "hour";
		var imageType =["raster"];
		var visualizationMethod;		
		var visualizationTitle;		
		
		var selectedVisualization;
		
		function setSpecialVisualizations(viz) {
			visualizations = viz;
		}
		function getSpecialVisualizations() {
			return visualizations;
		}
		
		
		function addSelectedParameter(param) {
			if (!containsParameter(param,selectedParameters)) {
				selectedParameters.push(param);
			}
			return selectedParameters;
		}
		
		function removeSelectedParameter(param) {
			for(var i = selectedParameters.length - 1; i >= 0; i--) {
			    if(selectedParameters[i].id === param.id && selectedParameters[i].type === param.type) {
			    	selectedParameters.splice(i, 1);
			    }
			}
			return selectedParameters;
		}
		
		function getParameters() {
			return selectedParameters;
		}
		
		function getParametersByType(type) {
			var params = [];
			for(var i = selectedParameters.length - 1; i >= 0; i--) {
			    if(selectedParameters[i].type === type) {
			    	params.push(selectedParameters[i]);
			    }
			}
			return params;
		}
		
		function clearParameters(type) {
			if (type === 'all') {
				selectedParameters = [];
			} else {
				for(var i = selectedParameters.length - 1; i >= 0; i--) {
				    if(selectedParameters[i].type === type) {
				    	selectedParameters.splice(i, 1);
				    }
				}
			}

		}
		
		function containsParameter(obj, list) {
		    var i;
		    for (i = 0; i < list.length; i++) {
		        if (list[i].id === obj.id && list[i].type === obj.type ) {
		            return true;
		        }
		    }
		    return false;
		}
		
		
		function addSelectedOi(oi) {
			if (!containsObject(oi,selectedOis)) {
				selectedOis.push(oi);
			}
			return selectedOis;
		}
		function removeSelectedOi(oi) {
			for(var i = selectedOis.length - 1; i >= 0; i--) {
			    if(selectedOis[i] === oi) {
			    	selectedOis.splice(i, 1);
			    }
			}
			return selectedOis;
		}
		
		function addSelectedVar(vari) {
			if (!containsObject(vari,selectedVars)) {
				selectedVars.push(vari);
			}
			return selectedVars;
		}
		function removeSelectedVar(vari) {
			for(var i = selectedVars.length - 1; i >= 0; i--) {
			    if(selectedVars[i] === vari) {
			    	selectedVars.splice(i, 1);
			    }
			}
			return selectedVars;
		}
		
		function getVariables() {
			return selectedVars;
		}
		
		function getObjects() {
			return selectedOis;
		}
	
		function setVariableIds(varids) {
			for(var i = 0; i< varids.length; i++) {
				var newObject = {id:varids[i]};
				addSelectedVar(newObject)
			}
		}
		
		function getVariableIds() {
			var selectedVarIds = [];
			for(var i = selectedVars.length - 1; i >= 0; i--) {
				selectedVarIds.push(selectedVars[i].id);
			}
			return selectedVarIds;
		}
		
		function setObjectIds(oids) {
			for(var i = 0; i< oids.length; i++) {
				var newObject = {id:oids[i]};
				addSelectedOi(newObject)
			}
		}
		
		function getObjectIds() {
			var selectedOiIds = [];
			for(var i = 0; i< selectedOis.length; i++) {
				selectedOiIds.push(selectedOis[i].id);
			}
			return selectedOiIds;
		}
		
		function clearVariables() {
			selectedVars = [];
		}
		
		function clearObjects() {
			selectedOis = [];
		}
		
		function setStartDateTime(time) {
			startDateTime = time;
		}
		
		function setEndDateTime(time) {
			endDateTime = time;
		}
		
		function getStartDateTime() {
			if (startDateTime == "") {
				return "null";
			} else {
				return startDateTime;
			}
		}
		
		function getEndDateTime() {
			if (endDateTime == "") {
				return "null";
			} else {
				return endDateTime;
			}
		}
		
		
		function getTimeUnit() {
			if (timeUnit == null) {
			    return "null";
			}
			return timeUnit ;
		}
		function setTimeUnit(tu) {
			timeUnit = tu;
		}
		
		function getImageType() {
			if (imageType == null) {
			    return "[]";
			}
			return imageType ;
		}
		function setImageType(imagetype) {
			imageType = imagetype;
		}
		
		function getVisualizationMethod() {
			return visualizationMethod ;
		}
		function setVisualizationMethod(method) {
			visualizationMethod = method;
		}
		
		function getVisualizationTitle() {
			return visualizationTitle;
		}
		function setVisualizationTitle(title) {
			visualizationTitle = title;
		}
		
		function getSelectedImageType() {
			return imageType ;
		}
		function setSelectedImageType(imagetype) {
			imageType = imagetype;
		}
		
		function setSelectedVisualization(viz) {
			$timeout(function() {
				selectedVisualization = viz;
			}, 0, true);	
		}
		function getSelectedVisualization() {
			return selectedVisualization ;
		}
		
		function getAllSelected() {
			var params = new Object();
			
			params.startTime = getStartDateTime();
			params.endTime = getEndDateTime();			
			params.timeUnit = getTimeUnit();
			params.imagetype = getSelectedImageType();
			
			if (getSelectedVisualization() != null) {
				var supportedImageFormats = getSelectedVisualization().formats;
				// use default image format if selected format not supported for selected visualization
				if (!supportedImageFormats.includes(params.imagetype)) {
					params.imagetype = supportedImageFormats[0];
				}
			} 
			
			params.selectedObjects = [];
			//var selectedObjects = getParametersByType("oi");
			var selectedObjects = getObjects();
			for (var i = 0; i<selectedObjects.length; i++ ){
				params.selectedObjects.push(selectedObjects[i].id);
			}
			
			
			
			params.selectedVariables = [];
			var selectedVariables = getParametersByType("m");
			for (i = 0; i<selectedVariables.length; i++ ){
				params.selectedVariables.push(selectedVariables[i].id);
			}
			selectedVariables = getParametersByType("b");
			for (i = 0; i<selectedVariables.length; i++ ){
				params.selectedVariables.push(selectedVariables[i].id);
			}
			selectedVariables = getParametersByType("i");
			for (i = 0; i<selectedVariables.length; i++ ){
				params.selectedVariables.push(selectedVariables[i].id);
			}
				
			return params;
		}
		
		
		return {
			addSelectedParameter: addSelectedParameter,
			removeSelectedParameter: removeSelectedParameter,
			getParameters: getParameters,
			getParametersByType: getParametersByType,
			clearParameters: clearParameters,
			
			getObjects : getObjects,
			getVariables : getVariables,
			getObjectIds : getObjectIds,
			setObjectIds: setObjectIds,
			getVariableIds : getVariableIds,
			setVariableIds : setVariableIds,
			addSelectedOi: addSelectedOi,
			removeSelectedOi: removeSelectedOi,
			addSelectedVar: addSelectedVar,
			removeSelectedVar: removeSelectedVar,
			clearVariables: clearVariables,
			clearObjects : clearObjects,
			setStartDateTime: setStartDateTime,
			setEndDateTime: setEndDateTime,
			getStartDateTime: getStartDateTime,
			getEndDateTime: getEndDateTime,
			getTimeUnit: getTimeUnit,
			setTimeUnit: setTimeUnit,
			getImageType: getImageType,
			setImageType: setImageType,
			getVisualizationMethod: getVisualizationMethod,
			setVisualizationMethod: setVisualizationMethod,
			getVisualizationTitle: getVisualizationTitle,
			setVisualizationTitle: setVisualizationTitle,
			setSpecialVisualizations: setSpecialVisualizations,
			getSpecialVisualizations: getSpecialVisualizations,
			
			getAllSelected: getAllSelected
		}
	}]);

function containsObject(obj, list) {
    var i;
    for (i = 0; i < list.length; i++) {
        if (list[i].id === obj.id) {
            return true;
        }
    }
    return false;
}