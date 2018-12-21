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
// @author Pekka Siltanen, Kari Rainio

function timeseriesChart(responsedata,window,id,visualizationMethod) {
	switch (visualizationMethod) {
		case "TimeSeriesOneQuantOneLine":
		case "TimeSeriesOneQuantOnePlotPerOi":	
		case "TimeSeriesNQuantOnePlotPerOi":	
			return TimeSeriesOneQuantOneLine(responsedata,id,false,onClickTimeSeries, tooltipTimeSeries);
//		case "TimeSeriesOneQuantOnePlotPerOi":
//			return TimeSeriesOneQuantOnePlotPerOi(responsedata,id,false,onClickTimeSeries, tooltipTimeSeries);
		case "TimeSeriesNominalBinary":
			return timeSeriesNominalBinaryChart(responsedata,id,true,window,onClickTimeSeries, tooltipTimeSeries);			
		case "TimeSeriesOneQuantNOis":
			return timeSeriesOneQuantNOisChart(responsedata,id,false,onClickTimeSeries, tooltipTimeSeries);	
//		case "TimeSeriesNQuantOnePlotPerOi":
//			return TimeSeriesNQuantOnePlotPerOi(responsedata,id,false,onClickTimeSeries, tooltipTimeSeries);
		case "TimeSeriesOneQuantOneLinePerOi":
			return timeSeriesOneQuantOneLinePerOi(responsedata,id,false,onClickTimeSeries, tooltipTimeSeries);
		case "TimeSeriesNominalBinary":
			return timeSeriesNominalBinary(responsedata,id,false,onClickTimeSeries, tooltipTimeSeries);
	default:
		return visualizationMethod.toLowerCase();
	}
}


function trimForBasicTimeseries(response) {
	
	if ("error" in response) {
		console.log(response);
		return(response);
	}
	
	return makeTsDataObject(response);
}


function trimForimeSeriesOneQuantOnePlotPerOi(response) {
	
	if ("error" in response) {
		console.log(response);
		return(response);
	}
	
	var dataObjects = [];
	
	for (var i = 0; i< response.data.length; i++) {
		dataObjects.push(makeTsDataObject(response.data[i]))
	}
	return dataObjects;
}

function makeTsDataObject(data) {
	var limits = [];
	var mainTitle;
	var xTitle;
	var yTitle;
	var subTitle;
	
	mainTitle = data.main_title;
	xTitle = data.x_title;
	yTitle = data.y_title;
	subTitle = data.sub_title;
	
	var values = [];
	var valuesN = data.values.length;
	var smooth = false;
	if ("smooth" in data && data.smooth!=null && data.smooth.length > 0) {
		smooth = true;
	}
	for (i = 0; i< valuesN; i++) {
		if (smooth) {
			values.push({"date":data.timestamps[i],"value":data.values[i], "smooth": data.smooth[i]});
		} else {
			values.push({"date":data.timestamps[i],"value":data.values[i]});
		}
	}

	var dataObject = new Object;
	dataObject["mainTitle"]= mainTitle;
	dataObject["xTitle"] =  xTitle
	dataObject["yTitle"] =  yTitle
	dataObject["subTitle"] =  subTitle;
	dataObject["values"] = values;
	
	dataObject["lowerlimit"] = (data.lowerlimit == null || data.lowerlimit=="NA") ? null : data.lowerlimit;
	dataObject["upperlimit"] = (data.upperlimit == null || data.upperlimit=="NA") ? null : data.upperlimit;
	dataObject["alarm_lowerlimit"] = (data.alarm_lowerlimit == null || data.alarm_lowerlimit=="NA") ? null : data.alarm_lowerlimit;
	dataObject["alarm_upperlimit"] = (data.alarm_upperlimit == null || data.alarm_upperlimit=="NA") ? null : data.alarm_upperlimit;
	dataObject["outlier_upperlimit"]  = (data.outlier_upperlimit == null || data.outlier_upperlimit=="NA") ? null : data.outlier_upperlimit;
	dataObject["outlier_lowerlimit"] = (data.outlier_lowerlimit == null || data.outlier_lowerlimit=="NA") ? null : data.outlier_lowerlimit;
	dataObject["alarm_level"] = (data.alarm_level == null || data.alarm_level=="NA") ? null : data.alarm_level;
	dataObject["goalvalue"]= (data.goalvalue == null || data.goalvalue=="NA") ? null : data.goalvalue;
	dataObject["referencevalue"] = (data.referencevalue == null || data.referencevalue=="NA") ? null : data.referencevalue;
	dataObject["mean"] = (data.mean == null || data.mean=="NA") ? null : data.mean;
	dataObject["objectTitle"] = (data.oiTitle == null || data.oiTitle=="NA") ? null : data.oiTitle;
	return dataObject;
}


function TimeSeriesNQuantOnePlotPerOi(response,id,points,onClickTimeSeries, tooltipTimeSeries) {	
	var canvasSize = getCanvasSize();
	
	var margin = canvasSize.margin;
	var window = canvasSize.window;
	var legendMargin = canvasSize.legendMargin;
    var w = window.width;
    var h = window.height;
	var svg = addSvgRoot(id,w,h);

	var size = Object.keys(response).length;
    var chartHeight = (h -(margin.top + margin.bottom))/(size-1);
    var top =0;
	for (var  i=1; i< size; i++ ) {
		var chartName = "chart_" + i;
	    var dataObject = trimForBasicTimeseries(response[chartName]);
		var canvasSize = getCanvasSize();
		var legendMargin = canvasSize.legendMargin;
	    
		var xTitle = dataObject.xTitle;
		var yTitle = dataObject.yTitle;
		
		var mainTitle = dataObject.mainTitle;
		addSingleTimeSeries(svg,dataObject,w,chartHeight,margin,top,mainTitle,xTitle,yTitle,"mainTitle","xAxisTitle",null,null);
		top += chartHeight + margin.top;
		var svgId = "svg" + id;		
		var xTrans = w - legendMargin.right;
		var yTrans = legendMargin.top;
		var legend = svg.append("g")
		    .attr("class","legend")
		    .attr("transform","translate(" + xTrans +"," + yTrans +")")
		    .style("font-size","12px")
		    .call(d3.simpleLegend);
		    
		if (!points) {
			hideAll(svgId, "ts-point");	
		 }	
	}
	
	 return d3.select("#" + id + "> div").node();
//	return d3.select("#" + id).node();
}

// Single time series
function TimeSeriesOneQuantOneLine(response,id,points,onClickTimeSeries, tooltipTimeSeries) {	
	
	var dataObject = trimForBasicTimeseries(response);
	
	var canvasSize = getCanvasSize();
	
	var margin = canvasSize.margin;
	var window = canvasSize.window;
	var legendMargin = canvasSize.legendMargin;
    var w = window.width;
    var h = window.height;
    
    
	var xTitle = dataObject.xTitle;
	var yTitle = dataObject.yTitle;
	
	var mainTitle = dataObject.mainTitle;
	var svg = addSvgRoot(id,w,h);
	
	addSingleTimeSeries(svg,dataObject,w,h,margin,0,mainTitle,xTitle,yTitle,"mainTitle","xAxisTitle",null,null);
	var svgId = "svg" + id;		
	var xTrans = w - legendMargin.right;
	var yTrans = legendMargin.top;
	var legend = svg.append("g")
	    .attr("class","legend")
	    .attr("transform","translate(" + xTrans +"," + yTrans +")")
	    .style("font-size","12px")
	    .call(d3.simpleLegend);
	    
	if (!points) {
		hideAll(svgId, "ts-point");	
	 }	
	
	 return d3.select("#" + id + "> div").node();
}

function addSingleTimeSeries(svg,dataObject,w,h,margin,top,mainTitle,xTitle,yTitle,subTitle,mainTitleStyle,xTitleStyle,color,pathLegendText) {	
	
	addMainTitle(mainTitle,svg,w,margin,top,mainTitleStyle);
	
	// set the ranges
	var x = d3.scaleTime().range([0, w- (margin.left + margin.right)]);
	var y = d3.scaleLinear().range([h -(margin.top+ margin.bottom), 0]);
	// parse the date / time
	var parseTime;
	if (dataObject.values[0].date.length === 10 ) {
		parseTime = d3.timeParse("%Y-%m-%d");
	} else {
		parseTime = d3.timeParse("%Y-%m-%d %H:%M:%S");
	}

	var data = dataObject.values;
	data.forEach(function(d) {
	     d.date = parseTime(d.date);
	});

	var topPosition = top +margin.top; 
	
	var g = svg.append("g")
	    .attr("transform",
	          "translate(" + margin.left + "," + topPosition+ ")");
	
	  // Scale the range of the data
	 x.domain(d3.extent(data, function(d) { return d.date; }));
	 
	 
	 var upperlimits = [dataObject["upperlimit"],dataObject["alarm_upperlimit"],dataObject["outlier_upperlimit"],d3.max(data, function(d){return d.value; })];
	 var lowerlimits = [dataObject["lowerlimit"],dataObject["alarm_lowerlimit"],dataObject["outlier_lowerlimit"],d3.min(data, function(d){return d.value; })];
	 
	 var minY = Math.min.apply(Math,lowerlimits.filter(Boolean)); // filters null values
	 var maxY = Math.max.apply(Math,upperlimits.filter(Boolean));
	 //var minY = Math.min(d3.min(dataObject["limits"], function(d) { return  d.value; }),d3.min(data, function(d) { return  parseFloat(d.value); }));
	 //var maxY = Math.max(d3.max(dataObject["limits"], function(d) { return  d.value; }),d3.max(data, function(d) { return  parseFloat(d.value); }));
	 y.domain([minY, maxY]);

	 addTimeseriesPath(g,x,y,data,color,pathLegendText);
	 if ("smooth" in data[0]) {
		addTimeseriesSmoothed(g,x,y,data,color);
	 } 
	 addTimeseriesPoints(g,x,y,data);
	 
	  var graphWidth = w- margin.left - margin.right;
	  var graphHeight = h- margin.top - margin.bottom;
	  
	 var xax = g.append("g").attr("transform", "translate(0," + graphHeight + ")").call(d3.axisBottom(x).tickFormat(d3.timeFormat("%Y-%m-%d")));
	 xax.selectAll("text")
	    .attr("y", 0)
	    .attr("x", 9)
	    .attr("dy", ".35em")
	    .attr("transform", "rotate(90)")
	    .style("text-anchor", "start");;
	    
	  g.append("g").call(d3.axisLeft(y));	  
	  g.append("g").attr("class", "yAxis").attr("transform", "translate( " + graphWidth + ", 0 )").call(d3.axisRight(y).ticks(0))
	  g.append("g").attr("class", "xAxis").call(d3.axisTop(x).ticks(0));

	  addXAxisTitle(g, w, h, margin, xTitle,xTitleStyle);
	  addYAxisTitle(g, w, h, margin, yTitle); 
	  addSubXTitle(g, w, h, margin, subTitle,xTitleStyle);  

	  if (dataObject.referencevalue != null) {
		  addLine(g,x,y,x.invert(0),x.invert(w - margin.left - margin.right),dataObject.referencevalue,dataObject.referencevalue,"ts-referencevalue", "Reference" );
	  }
	  if (dataObject.alarm_lowerlimit != null) {
		  addLine(g,x,y,x.invert(0),x.invert(w - margin.left - margin.right),dataObject.alarm_lowerlimit,dataObject.alarm_lowerlimit,"ts-alarm_lowerlimit", "Alarm");
	  }
	  if (dataObject.alarm_upperlimit != null) {
		  addLine(g,x,y,x.invert(0),x.invert(w - margin.left - margin.right),dataObject.alarm_upperlimit,dataObject.alarm_upperlimit,"ts-alarm_upperlimit", "Alarm");
	  }
	  if (dataObject.lowerlimit != null) {
		  addLine(g,x,y,x.invert(0),x.invert(w - margin.left - margin.right),dataObject.lowerlimit,dataObject.lowerlimit,"ts-lowerlimit", "Limit");
	  }
	  if (dataObject.upperlimit != null) {
		  addLine(g,x,y,x.invert(0),x.invert(w - margin.left - margin.right),dataObject.upperlimit,dataObject.upperlimit,"ts-upperlimit", "Limit");
	  }
	  if (dataObject.mean != null) {
		  addLine(g,x,y,x.invert(0),x.invert(w - margin.left - margin.right),dataObject.mean,dataObject.mean,"ts-mean", "Mean");
	  }
}

function addTimeseriesPath(g,x,y,data,color,legendText) {
	var line = d3.line()
	.x(function(d) {
		var test = x(d.date);
		return x(d.date); 
		})
	.y(function(d) { 
		var test = y(d.value);
		return y(d.value); 
	});
	
	var linestyle;
    if (color == null) {
    	linestyle = "ts-line";
    } else {
    	linestyle = "ts-line-" + color;
    }
	  
	var path = g.append("path")
      .datum(data)
      .attr("class", linestyle)
      .attr("d", line)
      .attr("fill","none");
	
	if (legendText != null) {
		path.attr("data-legend",legendText);
	}
}

function addTimeseriesSmoothed(g,x,y,data,color) {

	var line = d3.line()     
    .x(function(d) { return x(d.date); })
    .y(function(d) { return y(d.smooth); })
	var linestyle;
    if (color == null) {
    	linestyle = "ts-smooth-line";
    } else {
    	linestyle = "ts-smooth-line-" + color;
    }
	g.append("path")
      .datum(data)
      .attr("class", linestyle)
      .attr("d", line)
      .attr("fill","none");
}

function addTimeseriesPoints(g,x,y,data) {
	g.selectAll("empty")
		 .data(data)
		 .enter()
		 .append("circle")
		.attr("class", "ts-point")
		.attr("cx", function(d) { return x(d.date)})
		.attr("cy", function(d) { return y(d.value);})	
	    .on("mouseover", function(d) {
	        d3.select(this).attr("fill", "white");
	        return tip.show(d.date.toString() + ", " + d.value.toString(), this);  
	    }).on("mouseout", function() {
	         d3.select(this).attr("fill", "black");
	        return tip.hide();
	    });
	
    var tip = d3.tip()
    .attr('class', 'd3-tip')
    .offset([-10, 0])
    .html(function(d) {
        console.log(d);
        return "<span style='color:black'>" + d + "</span>";
    })
 
    g.call(tip);
}

function TimeSeriesOneQuantOnePlotPerOi(response,window,id,points,onClickTimeSeries, tooltipTimeSeries) {
	var dataObjects = trimForimeSeriesOneQuantOnePlotPerOi(response);
	var canvasSize = getCanvasSize();
	
	var margin = canvasSize.smallTopMargin;
	var window = canvasSize.window;
	var legendMargin = canvasSize.legendMargin;
	
	
    var w = window.width;    
    var h = window.height;
    
    var svg = addSvgElement(id,w,h);
    
	var topPosition = 0;
    for (var i =0; i<dataObjects.length; i++ ) {
    	var xTitle = dataObjects[i].xTitle;
    	var yTitle = dataObjects[i].yTitle;
    	var mainTitle = dataObjects[i].mainTitle;
    	var subTitle = dataObjects[i].subTitle;
    	addSingleTimeSeries(svg,dataObjects[i],w,h/dataObjects.length,margin,topPosition,mainTitle,xTitle,yTitle,subTitle,"smallMainTitle","xAxisSmallTitle",null,null);
    	topPosition += w/dataObjects.length;
    }
	var svgId = "svg" + id;		

	var xTrans = w - legendMargin.right;
	var yTrans = legendMargin.top;
	var legend = svg.append("g")
	    .attr("class","legend")
	    .attr("transform","translate(" + xTrans +"," + yTrans +")")
	    .style("font-size","12px")
	    .call(d3.simpleLegend);
	    
	if (!points) {
		hideAll(svgId, "ts-point");	
	 }	
	
	 return d3.select("#" + id + "> div").node();
}

function timeSeriesNominalBinaryChart(dataObject,id,points, onClickTimeSeries, tooltipTimeSeries) {	
	var node =  TimeSeriesNQuantOnePlotPerOi(dataObject,id,points,onClickTimeSeries, tooltipTimeSeries);
	return node;
}

function timeSeriesOneQuantNOisChart(response,window,onClick, tooltip) {
	var dataObjects = trimForimeSeriesOneQuantOnePlotPerOi(response); // not tested!!!!!
	var canvasSize = getCanvasSize();
	
	var margin = canvasSize.smallTopMargin;
	var window = canvasSize.window;
	var legendMargin = canvasSize.legendMargin;
	
	
    var w = window.width;    
    var h = window.height;
    
    var svg = addSvgRoot(id,w,h);
    
	return d3.select("#" + id + "> div").node();
}

function timeSeriesOneQuantOneLinePerOi(response,id,points, onClickTimeSeries, tooltipTimeSeries) {
	var canvasSize = getCanvasSize();
	
	var margin = canvasSize.margin;
	var window = canvasSize.window;
	var legendMargin = canvasSize.legendMargin;
    var w = window.width;
    var h = window.height;
    
    var svg = addSvgRoot(id,w,h);
	var size = Object.keys(response).length -1;
    
	var colors = ["red","black","blue", "green", "orange", "yellow"];
	var svgId = "svg-" + id;	
	svg.append("foreignObject")
	  .attr("x", 0)
	  .attr("y", 0)
	  .attr("width", 120)
	  .attr("height", 24)
	  .append("xhtml:body")
	  .html("<form><input type=checkbox id=checkPoints checked />Show Points</form>")
	  .on("change", function(d, i){
		  if (svg.select("#checkPoints").property('checked')) {
			  //console.log("#checkPoints: ON");
			  showAll(svgId, "ts-point");
		  } else {
			  //console.log("#checkPoints: OFF");
			  hideAll(svgId, "ts-point");
		  }
	  });
	svg.append("foreignObject")
	  .attr("x", 0)
	  .attr("y", 24)
	  .attr("width", 120)
	  .attr("height", 24)
	  .append("xhtml:body")
	  .html("<form><input type=checkbox id=checkSmooths checked />Show Smooths</form>")
	  .on("change", function(d, i){
		  if (svg.select("#checkSmooths").property('checked')) {
			  //console.log("#checkSmooths: ON");
			  showAll(svgId, "ts-smooth-line");
			  for (var  i=0; i< colors.length; i++ ) {
				  showAll(svgId, "ts-smooth-line-"+colors[i]);
			  }
		  } else {
			  //console.log("#checkSmooths: OFF");
			  hideAll(svgId, "ts-smooth-line");
			  for (var  i=0; i< colors.length; i++ ) {
				  hideAll(svgId, "ts-smooth-line-"+colors[i]);
			  }
		  }
	  });
	
	
	for (var  i=1; i<= size; i++ ) {
		var chartName = "chart_" + i;
	    var dataObject = trimForBasicTimeseries(response[chartName]);
	    
		var xTitle = dataObject.xTitle;
		var yTitle = dataObject.yTitle;
		var mainTitle = dataObject.mainTitle;
		dataObject["mean"] = null;
		
		if (i==1) {
			addSingleTimeSeries(svg,dataObject,w,h,margin,0,mainTitle,xTitle,yTitle,dataObject.subTitle,"mainTitle","xAxisTitle",colors[(i-1)%colors.length],dataObject.objectTitle);
		} else {
			  // hack to draw lines only once
			  dataObject.referencevalue = null
			  dataObject.alarm_lowerlimit = null;
			  dataObject.alarm_upperlimit = null;
			  dataObject.lowerlimit = null;
			  dataObject.upperlimit = null;
			  dataObject.mean = null;
			addSingleTimeSeries(svg,dataObject,w,h,margin,0,null,null,null,null,"mainTitle","xAxisTitle",colors[(i-1)%colors.length],dataObject.objectTitle);
		}
	
		   
	}
	var xTrans = w - legendMargin.right;
	var yTrans = legendMargin.top;
	var legend = svg.append("g")
	    .attr("class","legend")
	    .attr("transform","translate(" + xTrans +"," + yTrans +")")
	    .style("font-size","12px")
	    .call(d3.simpleLegend);
    
	return d3.select("#" + id + "> div").node();
}


function onClickTimeSeries(dataObject,i) {
	return;	
}

function tooltipTimeSeries(dataObject,i) {
	return "TimeSeries tooltip";
}

