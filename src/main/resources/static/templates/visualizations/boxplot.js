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

function boxPlotChart(responsedata,window,id) {
	 return d3BoxPlot(responsedata,trimBoxplot,window,id,null,null);
}

function trimBoxplot(data){

	var nPlots;
	var plotNames;
	var outlierArray;
	var groupArray;
	var yTitle;
	var title;
	
	// DeployR returns an array if more the one name, otherwise character
	if (Array.isArray(data.bp_names)) {
		nPlots = data.bp_names.length;
		plotNames = data.bp_names;
	} else {
		plotNames = [data.bp_names];
		nPlots = 1;
	}
	outlierArray = data.bp_out;
	groupArray = data.bp_group;
	title = data.title; 
	yTitle = data.y_title;
	
	var lw = data.bp_stats[0];
	var lh = data.bp_stats[1];
	var uw = data.bp_stats[4];
	var uh = data.bp_stats[3];
	var med = data.bp_stats[2];
	

	
	var values = [];
	for (i= 0; i<nPlots;i++) {
		values.push({"name":plotNames[i],"lower_whisker":lw[i],"lower_hinge":lh[i],"upper_hinge":uh[i],"upper_whisker":uw[i],"median":med[i]}); 
	}
	

	var dataObject = new Object;
	dataObject["values"]= values;
	dataObject["title"] =  title
	dataObject["yTitle"] =  yTitle;
	dataObject["outliers"]= null;
	if (groupArray != null && outlierArray!= null && groupArray != "NULL" && outlierArray!= "NULL") {
		var outliers = [];
		for (j = 0; j < nPlots; j++) {
			for (i= 0; i<groupArray.length;i++) {
				if (groupArray[i] == j+1) {
					outliers.push({"name":plotNames[j],"value":outlierArray[i]}); 
				}
			}
			
		}
		dataObject["outliers"]= outliers;
	}

	
	return dataObject;
}


function onClickBoxPlot(dataObject,i) {
	alert("Median " + dataObject.values[i].median + " Lower whisker: " + dataObject.values[i].lower_whisker + " Upper whisker: " + 
					dataObject.values[i].upper_whisker + " Lower hinge: " + dataObject.values[i].lower_hinge + " Upper hinge: " + dataObject.values[i].upper_hinge);
}

function tooltipBoxPlot(dataObject,i) {
	return "<span style='color:red'>" + "Median " + dataObject.values[i].median + " Lower whisker: " + dataObject.values[i].lower_whisker + " Upper whisker: " + dataObject.values[i].upper_whisker + 
	"<br/> Lower hinge: " + dataObject.values[i].lower_hinge + " Upper hinge: " + dataObject.values[i].upper_hinge + "</span>";
}

function d3BoxPlot(response, trimBoxplot, window,id,onClickFunction , tooltipFunction) {
	
	if ("error" in response) {
		console.log(response);
		return(response);
	}
	
	if ("error" in response) {
		console.log(dataObject.error);
		return;
	}
	var canvasSize = getCanvasSize();
	
	var margin = canvasSize.margin;
	var window = canvasSize.window;
	var legendMargin = canvasSize.legendMargin;
    var w = window.width;
    var h = window.height;
    
    
	dataObject = trimBoxplot(response);
	var data = dataObject.values;
	var outliers = dataObject.outliers;
	var title = dataObject.title;
	var yTitle = dataObject.yTitle;
	
	
	
//	var margin = {top: 100, right: 20, bottom: 100, left: 80};
//    var w = window.width;
//    var h = window.height;
//    var totalh = h + margin.top + margin.bottom;
//    var totalw = w + margin.left + margin.right;
    


	var x = d3.scaleBand().rangeRound([0, w - (margin.left+margin.right)], 0.1);	
	var y = d3.scaleLinear().range([h - (margin.top + margin.bottom), 0]);


	
	var min = d3.min(data, function(d) {return parseFloat(d.lower_whisker); });
    var max = d3.max(data, function(d) { return parseFloat(d.upper_whisker); });
	
	if (outliers != null) {
		var outlierMin = d3.min(outliers, function(d) {return parseFloat(d.value); });
    	var outlierMax = d3.max(outliers, function(d) { return parseFloat(d.value); });
    	if (outlierMin < min) {
    		min = outlierMin
    	}
    	if (outlierMax > max) {
    		max = outlierMax
    	}
	}
    if (min == max) {
    	var d = Math.abs(min/2);
    	min = min - d;
    	max = max + d;
    }
    
    
    var padding = (max-min)/20;
    min -= padding;
    max += padding;

	y.domain([min, max]); 
	x.domain(data.map(function(d) { return d.name; }));
	
	var svg = addSvgRoot(id,w,h);
	
    addMainTitle(title,svg,w,margin,0,"mainTitle");	
	
    var chart = svg.append("g")
    			 .attr("transform","translate(" + margin.left + "," + margin.top + ")");
		
	addCenterLines(chart,data,x,y);
	addRects(chart,data,x,y);
		
	if (outliers != null) {
		addOutliers(chart,outliers,x,y);
	}

				
		if (onClickFunction != null) {
			rect.on('click', function(d,i) {
				onClickFunction(dataObject,i);
			});
		}    
		var tip = null;

		if (tooltipFunction != null) {
			tip = d3.tip()
			.attr('class', 'd3-tip')
			.offset([-10, 0])
			.html(function(d,i) {	    
				return tooltipFunction(dataObject,i);
			})

			chart.call(tip);  
			rect.on('mouseover', tip.show)
			.on('mouseout', tip.hide)
		}
		
		addWhiskerLines(chart,data,x,y);
		addMedianLines(chart,data,x,y);		
					
		
		var xAxis = d3.axisBottom(x);
		var xAxis2 = d3.axisTop(x).ticks(0);
		var yAxis = d3.axisLeft(y).ticks(10);
		var yAxis2 = d3.axisRight(y).ticks(0);	
		
		chart.append("g")
		.attr("class", "yAxis")
		.call(yAxis);

		// make right side axis
		var xrightTrans =  w - (margin.right + margin.left);
		chart.append("g")
		.attr("class", "yAxis")
		.attr("transform", "translate( " + xrightTrans + ", 0 )")
		.call(yAxis2)
		
		var xTranslation = y(min);
		chart.append("g")
		.attr("class", "xAxis")
		.attr("transform", "translate(0," + xTranslation + ")")
		.call(xAxis)   
		.selectAll("text")
		.style("text-anchor", "end")
		.attr("class", "xAxisTitle")
		.attr("dx", "-.8em")
		.attr("dy", "-.15em")
		.attr("transform", "rotate(-90)" );
			
		var xup = chart.append("g")
		.attr("class", "xAxis")
		.call(xAxis2);
		
		xup.selectAll("text").remove();
		
		var scale = y.domain();
		var scalez = xAxis.tickSize();
		var minX = x.domain()[0];
		var minY = y.domain()[0];
		var maxX = x.domain()[1];
		var maxY = y.domain()[1];			

		addYAxisTitle(chart, w, h, margin, yTitle); 
		return d3.select("#" + id + "> div").node();
}


function addCenterLines(chart,data,x,y) {
	chart.selectAll("center-line")
	.data(data).enter()
	.append("line")
	.attr("class", "center-line")
	.attr("x1", function(d) { return x(d.name) + x.bandwidth()/2; })
	.attr("x2", function(d) { return x(d.name) + x.bandwidth()/2; })
	.attr("y1", function(d) { return y(d.lower_whisker); })
	.attr("y2", function(d) { return y(d.upper_whisker); })
}

function addRects(chart,data,x,y) {
	var rect = chart.selectAll(".bar")
	.data(data).enter()
	.append("rect")
	.attr("class", "bar bar--positive")
	.attr("x", function(d) { return x(d.name) + x.bandwidth()/4; })
	.attr("y", function(d) { return y(d.upper_hinge); })
	.attr("height", function(d) {console.log(d); return Math.abs(y(d.upper_hinge) - y(d.lower_hinge)); })
	.attr("width", x.bandwidth()/2);
}

function addOutliers(chart,outliers,x,y) {
	var points = chart.selectAll(".outlier-point")
	.data(outliers)
	.enter()
	.append("circle")
	.attr("class", "outlier-point")
	.attr("cx", function(d) { return x(d.name) + x.bandwidth()/2; })
	.attr("cy", function(d) { 
		return y(d.value);
		})
	.attr("r", 3)
}

function addWhiskerLines(chart,data,x,y) {
	chart.selectAll("none")
	.data(data).enter()
	.append("line")
	.attr("class", "whisker-line")
	.attr("x1", function(d) { return x(d.name) + 0.375*x.bandwidth(); })
	.attr("x2", function(d) { return x(d.name) + 0.625*x.bandwidth(); })
	.attr("y1", function(d) { return y(d.lower_whisker); })
	.attr("y2", function(d) { return y(d.lower_whisker); })
	
chart.selectAll("none")
	.data(data).enter()
	.append("line")
	.attr("class", "whisker-line")
	.attr("x1", function(d) { return x(d.name) + 0.375*x.bandwidth(); })
	.attr("x2", function(d) { return x(d.name) + 0.625*x.bandwidth(); })
	.attr("y1", function(d) { return y(d.upper_whisker); })
	.attr("y2", function(d) { return y(d.upper_whisker); })
}

function addMedianLines(chart,data,x,y) {
	chart.selectAll("none")
	.data(data).enter()
	.append("line")
	.attr("class", "median-line")
	.attr("x1", function(d) { return x(d.name) + 0.25*x.bandwidth(); })
	.attr("x2", function(d) { return x(d.name) + 0.75*x.bandwidth(); })
	.attr("y1", function(d) { return y(d.median); })
	.attr("y2", function(d) { return y(d.median); })
}





