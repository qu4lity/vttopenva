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

//@author Pekka Siltanen


(function () {
	'use strict';

	angular.module('app')
	.controller('objectselectionController', ['$scope',"metadataService","parameterService","configurationService", function ($scope,metadataService,parameterService,configurationService) {
		$scope.data = {
				oi:  []
		};


		var conf = configurationService.getConfigurationInfo();
		if (conf.oiSelectionUi==='list') {
			metadataService.getObjectList(conf.oiSelectionType).then(function(response) { 
				var data = [];
				$.each(response, function(i, item) {
					data.push(addDataItem(item,0))
				});
				$scope.data.oi = data;
				console.log(JSON.stringify($scope.data.oi));
			})
		} else {
			metadataService.getObjectHierarchy().then(function(response) { 
				var data = [];
				$.each(response, function(i, item) {
					data.push(addDataItem(item,0))
				});
				$scope.data.oi = data;
				console.log(JSON.stringify($scope.data.oi));
			})
		}




		$scope.remove = function (scope) {
			scope.remove();
		};

		$scope.toggle = function (scope) {
			scope.toggle();
		};


		$scope.collapseAll = function () {
			$scope.$broadcast('angular-ui-tree:collapse-all');
		};

		$scope.expandAll = function () {
			$scope.$broadcast('angular-ui-tree:expand-all');
		};

		$scope.selectOI = function (selected) {
			var node = selected.$nodeScope.$modelValue;
			parameterService.addSelectedOi(node);
		};


		$scope.selectAll = function (selected) {
			var nodes = selected.$parentNodesScope.$modelValue;
			$.each(nodes, function(i, node) {
				if (node.selectType != "all") {
					parameterService.addSelectedOi(node);	
				}
			});
		}
	}]);


}());





function addDataItem(item, level) {
	var nodes = [];
	var dataItem; 
	level+=1;
	if (item.children !== null && item.children !== undefined && item.children.length > 5) {
		var allItem = {"id": " ", "title": "Select all", "type":item.children[0].oiType, "nodes": [], nodeType: "oi", selectType:"all"}; 
		nodes.push(allItem);
	}
	$.each(item.children, function(i, child_) {
		var child = addDataItem(child_,level);
		nodes.push(child);
	});
	if (item.children == null) {
		dataItem = {"id": item.id, "title": item.reportTitle.substring(0, 24), "type": item.oiType, "nodes": nodes, nodeType: "oi", selectType:"this" }; 
	} else {
		dataItem = {"id": item.id, "title": item.reportTitle.substring(0, 24), "type": item.oiType, "nodes": nodes, nodeType: "oi", selectType:"parent" }; 	
	}	
	return dataItem;
}

function compare(a,b) {
	if (a.text < b.text)
		return -1;
	if (a.text > b.text)
		return 1;
	return 0;
}
