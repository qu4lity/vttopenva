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
//
// @author Pekka Siltanen

function getCanvasSize() {
	var margin = {top: 100, right: 40, bottom: 100, left: 80};
	var smallTopMargin = {top: 50, right: 40, bottom: 70, left: 80};
	var window = {width: 640, height:640};	
	var legendMargin = {top: 115, right: 100}
    
    return {margin: margin, window: window, legendMargin: legendMargin, smallTopMargin: smallTopMargin};
}

// http://colorbrewer2.org/#type=sequential&scheme=BuGn&n=3
var blueScale3 = ["#deebf7","#9ecae1","#3182bd"];
var blueScale4 = ["#eff3ff","#bdd7e7","#6baed6","#2171b5"];
var blueScale5 = ["#eff3ff","#bdd7e7","#6baed6","#3182bd","#08519c"];
var blueScale6=  ["#eff3ff","#c6dbef","#9ecae1","#6baed6","#3182bd","#08519c"];
var blueScale7 = ["#eff3ff","#c6dbef","#9ecae1","#6baed6","#4292c6","#2171b5","#084594"];
var blueScale8 = ["#f7fbff","#deebf7","#c6dbef","#9ecae1","#6baed6","#4292c6","#2171b5","#084594"]
var blueScale9 = ["#f7fbff","#deebf7","#c6dbef","#9ecae1","#6baed6","#4292c6","#2171b5","#08519c","#08306b"];


function addSvgElement(id,w,h) {
	var style = "height:auto !important;min-height:" + h +"px;width:auto !important;min-width:"+ w +"px";
	d3.select("#" + id + " > div > #svgcontainer")
	.attr("style", style);

	var svg =  d3.select("#" + id + " > div > #svgcontainer")
				 .append("svg")
				 .attr("height", "100%")
				 .attr("width", "100%")
				 .attr('viewBox','0 0 '+ h +' '+ w)
				  .attr('preserveAspectRatio','xMinYMin');
	return svg;
}

function addSvgRoot(id,w,h) {

	var svg =  d3.select("#" + id + " > #svgcontainer")
				 .append("svg")
				 .attr("id","svg-" + id)
				 .attr("height", "100%")
				 .attr("width", "100%")
				 .attr('viewBox','0 0 '+ h +' '+ w)
				  .attr('preserveAspectRatio','xMinYMin');
	return svg;
}


function addXAxisTitle(graph, w, h, margin, xTitle, style) {
	if (xTitle == null) return;
	graph.append("text")
	.attr("class", style)
	.attr("x", (w - margin.left - margin.right)/ 2)
	.attr("y", h -margin.top - margin.bottom * 0.3)
	.text(xTitle)
	.attr("dominant-baseline", "middle")
	.attr("text-anchor", "middle")
}

function addSubXTitle(graph, w, h, margin, xTitle,style) {
	if (xTitle == null) return;
	graph.append("text")
	.attr("class", style)
	.attr("x", (w - margin.left - margin.right)/ 2)
	.attr("y", h -margin.top - margin.bottom * 0.1)
	.text(xTitle)
	.attr("dominant-baseline", "middle")
	.attr("text-anchor", "middle")
}

function addYAxisTitle(graph, w, h, margin, yTitle) { 
	if (yTitle == null) return;
	graph.append("text")
	.attr("class", "yAxisTitle")
	.attr("x", -margin.left)
	.attr("y", (h - margin.top - margin.bottom)/ 2)
	.text(yTitle)
	.attr("dominant-baseline", "middle")
	.attr("text-anchor", "middle")
	.attr("transform", "rotate(270," + (-margin.left*0.5) + "," + (h - margin.top - margin.bottom)/ 2 + ")")
}

function addColorLegend(svg, w, h, margin, legendMargin, colorScale ,legendTitle) { 
	
	svg.append("text")
	.attr("class", "legendTitle")
	.attr("x", w - legendMargin.right)
	.attr("y", legendMargin.top - 20)
	.text(legendTitle)
	
    var colorLegend = d3.legendColor()
    .labelFormat(d3.format(".0f"))
    .scale(colorScale)
    .shapePadding(5)
    .shapeWidth(20)
    .shapeHeight(20)
    .labelOffset(12);

	var xTrans = w - legendMargin.right;
	var yTrans = legendMargin.top;    
  
	svg.append("g")
	.attr("transform","translate(" + xTrans +"," + yTrans +")")
	.call(colorLegend);
}

function addMainTitle(mainTitle,svg,totalw,margin,top,style) {
	if (mainTitle == null) return;
	var splittedMainTitle = mainTitle.split(/[\r\n]+/);
	
	var topPosition = top + margin.top/10;
	
	var mainText = svg.append("text")
	.attr("class",style)
	.attr("transform","translate(" + totalw / 2 +","+ topPosition +")")

	var dy;
	if (style == "mainTitle") {
		dy = 20;
	} else {
		dy = 10;
	}
	var first = true;
	for (var i = 0; i< splittedMainTitle.length; i++) {
		if (splittedMainTitle[i] != null && splittedMainTitle[i]!="") {
			if (first) {
				d=dy/2;
				first = false;
			} else {
				d=dy;
			}
			mainText.append('tspan')
			.attr('x', 0)
			.attr('dy', d)
			.text(splittedMainTitle[i])
			.attr("text-anchor", "middle")
		}
	}
}

function showAll(id, elemClass){
	 d3.select("#" + id).selectAll("." + elemClass).attr("visibility", "visible");
}
function hideAll(id, elemClass){
	d3.select("#" + id).selectAll("." + elemClass).attr("visibility", "hidden");
}

function addLine(chart,x,y,x1,x2,y1,y2,elemClass,legendText) {
	
	var line = chart
			.append("line")
			.attr("class", elemClass)
			.attr("x1", function(){ return x(x1)})
			.attr("x2", function(){ return x(x2)})
			.attr("y1", function(){ return y(y1)})
			.attr("y2", function(){ return y(y2)});
	if (legendText != null) {
		line.attr("data-legend",legendText);
	}

	return line
}

function addEmptyXAxis(chart,xAxis,xTranslation) {
	chart.append("g")
	.attr("class", "x axis")
	.attr("transform", "translate(0," + xTranslation + ")")
	.call(xAxis);
}

function add45RotatedXAxis(chart,xAxis,xTranslation) {
	chart.append("g")
	.attr("class", "x axis")
	.attr("transform", "translate(0," + xTranslation + ")")
	.call(xAxis)
	.selectAll("text")
	.style("text-anchor", "end")
	.attr("dx", "-.8em")
	.attr("dy", "-.15em")
	.attr("transform", "rotate(-45)" );
}

function addXAxis(chart,xAxis,yTranslation,xLength) {
	var xaxis = chart.append("g")
	.attr("class", "x axis")
	.attr("transform", "translate(0," + yTranslation + ")")
	.call(xAxis)
	.selectAll("text")
	.style("text-anchor", "end")
	.attr("class", "x-axis-text")
	.attr("dx", "-0.1em")
	.attr("dy", "1.5em");
	
	if (xLength == null)
		return;
	var labels = chart.selectAll(".x-axis-text");
	var maxTextWidth = d3.max(labels.nodes(), n => n.getComputedTextLength());
	if (maxTextWidth >= xLength/labels.length) {
		xaxis.attr("transform", "rotate(-45)" );
	}	
}

function addXAxisNumericScale(chart,xAxis,yTranslation) {
	var xaxis = chart.append("g")
	.attr("class", "x axis")
	.attr("transform", "translate(0," + yTranslation + ")")
	.call(xAxis)
}

function addYAxis(chart,yAxis,xTranslation) {
	var xaxis = chart.append("g")
	.attr("class", "y axis")
	.attr("transform", "translate(" + xTranslation + ",0)")
	.call(yAxis)
	.selectAll("text")
	.style("text-anchor", "end")
	.attr("class", "x-axis-text")
	.attr("dx", "-0.1em")
	.attr("dy", "1.5em");	
}

