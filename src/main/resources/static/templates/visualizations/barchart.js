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
//
// @author Pekka Siltanen

function barChart(responsedata,window,id,visualizationMethod) {
	var dataObject = trimBarChart(responsedata);	
	return d3BarChart(dataObject,id,tooltipBarChartPlot,null);
}


function trimBarChart(data) {
	var mainTitle;
	
	if ("main_title" in data) {
			mainTitle = data.main_title;
	}

	
	var values = [];
	var valuesN = Object.keys(data.values).length;
	for (var i = 0; i< valuesN; i++) {
		var keyName = Object.keys(data.values)[i];
		values.push({"name":keyName,"value":data.values[keyName]});
	}
	
	var dataObject = new Object;
	dataObject["mainTitle"]= mainTitle;
	dataObject["values"] = values;
	return dataObject;
}

function d3BarChart(dataObject, id,tooltipFunction,onClickFunction) {

	var canvasSize = getCanvasSize();	
	var margin = canvasSize.margin;
	var window = canvasSize.window;
    var w = window.width;
    var h = window.height;
	
    var data = dataObject.values;
	var mainTitle = dataObject.mainTitle;
	var xTitle = dataObject.xTitle;
	var yTitle = dataObject.yTitle;
	var subTitle = dataObject.subTitle;

	var x;
	x = d3.scaleBand().rangeRound([0, w- (margin.left + margin.right)], 0.1);
	 
	var y = d3.scaleLinear().range([h -(margin.top+ margin.bottom),0]);	

	var svg = addSvgRoot(id,w,h);
	
	var chart = svg.append("g")
	    			.attr("transform",
	    				  "translate(" + margin.left + "," + margin.top+ ")");

	x.domain(data.map(function(d) { return d.name; }));
//	y.domain(d3.extent(data, function(d) { return parseFloat(d.value); })).nice(); 

	var min = d3.min(data, function(d) { return parseFloat(d.value); });
	var max = d3.max(data, function(d) { return parseFloat(d.value); });
	if (max < 0) {
		y.domain([min, 0]).nice();
	} else if (min > 0) {
		y.domain([0, max]).nice(); 
	} else {
		y.domain([min, max]).nice();
	}

	var bandwidth;
	if (x.bandwidth()> 4) {
		bandwidth = x.bandwidth() -2;
	} else {
		bandwidth = x.bandwidth();
	}
	
	var rect = chart.selectAll(".bar")
	.data(data).enter()
	.append("rect")
	.attr("class", function(d) { return "bar bar--" + (d.value < 0 ? "negative" : "positive"); })
	.attr("y", function(d) {if (d.value < 0) {return y(0);} else {return(y(d.value));}})
	.attr("x", function(d) { return x(d.name); })
	.attr("height", function(d) {return Math.abs(y(d.value) - y(0)); })
	.attr("width", bandwidth)

	var xAxis = d3.axisBottom(x);
	
	if (Math.abs(max - min) < 10) {
		var yAxis = d3.axisLeft(y).ticks(Math.abs(max - min) +1).tickFormat(d3.format("d"));
	} else {
		yAxis = d3.axisLeft(y).ticks(10).tickFormat(d3.format("d"));
	}
	
	chart.append("g")
	.attr("class", "y axis")
	.call(yAxis);

	var xTranslation = y(0) + 5;
	if (data.length > 1) {
		if (data.length > 100) {
			addEmptyXAxis(chart,xAxis,xTranslation);
		} else {
			addXAxis(chart,xAxis,xTranslation, w- (margin.left + margin.right));
		}
	}

	addMainTitle(mainTitle,svg,h,margin,0,"mainTitle");
    addXAxisTitle(chart, w, h, margin, xTitle,"xAxisTitle");     
    addYAxisTitle(chart, w, h, margin, yTitle); 
    addSubXTitle(chart, w, h, margin, subTitle,"xAxisTitle");
	

	var tip = null;

	if (tooltipFunction != null) {
		tip = d3.tip()
		.attr('class', 'd3-tip')
		.offset([-10, 0])
		.html(function(d,i) {	    
			return tooltipFunction(dataObject,i,yTitle);
		})

		svg.call(tip);
	}
	if (tooltipFunction != null) {    
		rect.on('mouseover', tip.show)
		.on('mouseout', tip.hide)
	}

    
    
//	if (onClickFunction != null) {
//	rect.on('click', function(d,i) {
//		onClickFunction(dataObject,i);
//	});
//}    
//
    
	return d3.select("#" + id + "> div").node();
}

function onClickBarChart() {
	
} 

function tooltipBarChartPlot(dataObject,i,yTitle) {
	if (yTitle == null) {
		return dataObject.values[i].name + " - " + dataObject.values[i].value;
	} else {
		return dataObject.values[i].name + " - " + dataObject.values[i].value + " " + yTitle;
	}
	
}
