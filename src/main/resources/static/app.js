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

var $stateProviderRef = null;

var app = angular.module('app', ['ui.router','ui.tree','ngCookies','tooltips',"ui.bootstrap"]) // TODO: check if ngCookies is used

app.config([
	'$stateProvider', '$urlRouterProvider','$httpProvider', function($stateProvider, $urlRouterProvider,$httpProvider) {
		$urlRouterProvider.otherwise('/');
		$httpProvider.defaults.headers.common["X-Requested-With"] = 'XMLHttpRequest';
		$stateProvider
		.state('home', {
			url: '/',
			views: {
				'': {
					templateUrl: './templates/main.html'
				},
				'navigation@home': {
					templateUrl: './templates/ui/navigation/navigation.html'
				},
				'visualizationArea@home': {
					templateUrl: './templates/ui/visualizationarea/visualizationArea.html',
					controller: 'visualizationAreaController'
				},
				'datetimeselection@home': {
					templateUrl: './templates/ui/datetimeselection/datetimeselection.html',
					controller: 'datetimeselectionController'
				},
				'datetimehorizontal@home': {
					templateUrl: './templates/ui/datetimeselection/datetimeselection_horizontal.html',
					controller: 'datetimeselectionController'
				},
				'imagetypeselection@home': {
					templateUrl: './templates/ui/imagetypeselection/imagetypeselection.html',
					controller: 'imagetypeselectionController'
				},
				'timeunitselection@home': {
					templateUrl: './templates/ui/timeunitselection/timeunitselection.html',
					controller: 'timeunitselectionController'
				},
				'objectvariableaggregator@home': {
					templateUrl: './templates/ui/parameterselection/objectVariableAggregator.html',
					},
				'variableselection@home': {
					templateUrl: './templates/ui/parameterselection/variableselection.html',
					controller: 'variableselectionController'
				},
				'objectselection@home': {
					templateUrl: './templates/ui/parameterselection/objectselection.html',
					controller: 'objectselectionController'
				},
				'additionalInput@home': {
					templateUrl: "./templates/ui/visualizationselection/additionalInput.html",
					controller: 'additionalInputController'
				},
				'visualizationselectionaggregator@home': {
					templateUrl: './templates/ui/visualizationselection/visualizationSelectionAggregator.html',
				},	
				'selectedObjects@home': {
					templateUrl: './templates/ui/visualizationselection/selectedObjects.html',
					controller: 'selectedObjectsController'
				},
				'selectedVariables@home': {
					templateUrl: './templates/ui/visualizationselection/selectedVariables.html',
					controller: 'selectedVariablesController'
				},
				'visualizations@home': {
					templateUrl: './templates/ui/visualizationselection/visualizations.html',
					controller: 'visualizationsController'
				},
				'visualization@home': {
					templateUrl: "./templates/visualisation.html"
				},
				'visualization@home': {
					templateUrl: "./templates/visualizations/visualization.html"
				},
			}
		});
		$stateProviderRef = $stateProvider;
	}]);








	







