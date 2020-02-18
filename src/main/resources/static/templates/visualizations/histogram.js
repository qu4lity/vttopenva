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

function histogramChart(responsedata,window,id,visualizationMethod) {
	if ("error" in responsedata) {
		return(responsedata);
	}
	var dataObject = trimHistogram(responsedata);	
//	return d3HistogramChart(dataObject,id,onClickHistogram,tooltipHistogram);
	return d3HistogramChart(dataObject,id,null,null);
	
}

function trimHistogram(data, title, labelTitle, valueTitle){

	var dataObject = new Object;
	dataObject.mainTitle = data.main_title;
	dataObject.xTitle = data.x_title;
	dataObject.yTitle = data.y_title;
	dataObject.subTitle = data.sub_title;
	dataObject.upperLimit = data.upperlimit;
	dataObject.lowerLimit = data.lowerlimit;
	dataObject.alarmUpperlimit = data.alarm_upperlimit;
	dataObject.alarmLowerLimit = data.alarm_lowerlimit;
	dataObject.mean = data.mean;
	dataObject.sum = data.sum;
	dataObject.std = data.std;
	dataObject.min = data.min;
	dataObject.max = data.max;	
	
	var values = [];
	var breaks = data.matrix.breaks;
	var counts = data.matrix.counts;

	for (var i = 0; i< counts.length; i++) {
		values.push({"count":counts[i], "breakStart":breaks[i],"breakEnd":breaks[i+1]})
	}
	dataObject["values"]= values;
	return dataObject;
}

function d3HistogramChart(dataObject,id,tooltipFunction, onClickFunction) {
	var canvasSize = getCanvasSize();	
	var margin = canvasSize.margin;
	var window = canvasSize.window;
    var w = window.width;
    var h = window.height;
	var legendMargin = canvasSize.legendMargin;
    
	var values = dataObject.values;	

	var x = d3.scaleLinear().range([0, w -(margin.left + margin.right)]);
	var y = d3.scaleLinear().range([h -(margin.top+ margin.bottom),0]);	

	var svg = addSvgRoot(id,w,h);

	var chart = svg.append("g")
	.attr('class', 'bar-chart')
	.attr("transform","translate(" + margin.left + "," + margin.top + ")");

	var tip = null;

	if (tooltipFunction != null) {
		tip = d3.tip()
		.attr('class', 'd3-tip')
		.offset([-10, 0])
		.html(function(d,i) {	    
			return tooltipFunction(dataObject,i);
		})
		svg.call(tip);
	}

	x.domain([values[0].breakStart, values[values.length-1].breakEnd]).nice(); 
	var max = d3.max(values, function(d) { return parseFloat(d.count); });
	y.domain([0,max]).nice(); 

	
	var rect = chart.selectAll(".bar-histogram")
	.data(values)
	 .enter()
	.append("rect")
	.attr("class", function(d) { return "bar-histogram"; })
	.attr("y", function(d) {return(y(d.count))})
	.attr("x", function(d) { return x(d.breakStart); })
	.attr("height", function(d) {return( y(0) - y(d.count));})
	.attr("width", function(d) { return x(d.breakEnd - d.breakStart);})

	if (onClickFunction != null) {
		rect.on('click', function(d,i) {
			onClickFunction(dataObject,i);
		});
	}    

	if (tooltipFunction != null) {    
		rect.on('mouseover', tip.show)
		.on('mouseout', tip.hide)
	}

	var xTranslation = y(0);
	var xAxis = d3.axisBottom(x);
	addXAxis(chart,xAxis,xTranslation, w- (margin.left + margin.right));
	addMainTitle(dataObject.mainTitle,svg,h,margin,0,"mainTitle");
    addXAxisTitle(chart, w, h, margin, dataObject.xTitle,"xAxisTitle");     
    addYAxisTitle(chart, w, h, margin, dataObject.yTitle); 
    addSubXTitle(chart, w, h, margin, dataObject.subTitle,"xAxisTitle");
    
    if (dataObject.mean != null) {
        addLine(chart,x,y,dataObject.mean,dataObject.mean,y.invert(0),y.invert(h -(margin.top+ margin.bottom)),"bar-meanline",null);
    }

    var legendText;
    for (var key in dataObject) {
        if (dataObject.hasOwnProperty(key)) {
				 switch (key) {
				 	case "alarmUpperLimit":
				 	case "alarmLowerlimit":
				 		legendText = "Alarm";
				 		break;
				 	case "upperLimit":
				 	case "lowerlimit":
				 		legendText = "Alarm";
				 		break;
				 	case "std":
				 		legendText = "Std";
				 		break;
				 	case "mean":	
				 		legendText = "Mean";
				 		break;
				 	case "min":
				 		legendText = "Min";
				 		break;
				 	case "max":	
				 		legendText = "Max";
				 		break;
				 	default:
				 		continue;
				 }
				 if (x(dataObject[key]) != null && x(dataObject[key]) > 0 && x(dataObject[key]) < w- (margin.left + margin.right)) {
					 addLine(chart,x,y,dataObject[key],dataObject[key],y.invert(0),y.invert(h -(margin.top+ margin.bottom)),"line-hist-" + key, legendText);
				 }
        }
    }
    

 
//	var textTranslation = 20; 
//
//	
	var yAxis = d3.axisLeft(y).ticks(10).tickFormat(d3.format("d"));
	chart.append("g")
	.attr("class", "y axis")
	.call(yAxis);
	
	var xTrans = w - legendMargin.right;
	var yTrans = legendMargin.top;
	var legend = svg.append("g")
	    .attr("class","legend")
	    .attr("transform","translate(" + xTrans +"," + yTrans +")")
	    .style("font-size","12px")
	    .call(d3.simpleLegend);
		
	return d3.select("#" + id + "> div").node();

}

function onClickHistogram(dataObject,i) {
	var message = "<div>" + dataObject.columnNames[i] + ": " + d3.format(".2f")(dataObject.amounts[i]) + "</div>";
	$(message).dialog();
}

function tooltipHistogram(dataObject,i) {
	return "<span style='color:red'>" + dataObject.columnNames[i] + ": " + d3.format(".2f")(dataObject.amounts[i]) + "</span>";
}
