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

function singleValueChart(response,window,id,visualizationMethod) {
	if ("error" in response) {
		return(responsedata);
	}
	var dataObject = trimForSum(response);	
	return d3SumChart(dataObject,id,null,tooltipSum);
	
}

function trimForSum(data){
	var dataObject = new Object;

	dataObject["variableName"] = data.variable;
	dataObject["mainTitle"]  = data.main_title;
	dataObject["calculatedValue"]  = data.calculated_value;
	dataObject["xTitle"]  = data.x_title;
	dataObject["yTitle"]  = data.y_title;

	
	return dataObject;
}

function d3SumChart(dataObject,id, onClickFunction, tooltipFunction) {
	
	var canvasSize = getCanvasSize();	
	var margin = canvasSize.margin;
	var window = canvasSize.window;
    var w = window.width;
    var h = window.height;
	var legendMargin = canvasSize.legendMargin;
    
	var values = dataObject.values;	

	var x = d3.scaleBand().rangeRound([0, w- (margin.left + margin.right)], 0.1);
	var y = d3.scaleLinear().range([h -(margin.top+ margin.bottom),0]);	

	var svg = addSvgRoot(id,w,h);

	var chart = svg.append("g")
	.attr('class', 'bar-chart')
	.attr("transform","translate(" + margin.left + "," + margin.top + ")");

	var data = [];
	//data.push({name:dataObject.variableName, value:dataObject.calculatedValue});
	data.push({name:"", value:dataObject.calculatedValue});
	x.domain(data.map(function(d) { return d.name; }));
	y.domain([0,Math.ceil(dataObject.calculatedValue)]).nice(); 
	
	var xTranslation = y(0);
	var xAxis = d3.axisBottom(x);
	//addXAxis(chart,xAxis,xTranslation, w- (margin.left + margin.right));
	
	var yTranslation = x(0);
	var yAxis = d3.axisLeft(y).ticks(10).tickFormat(d3.format("d"));
	addYAxis(chart,yAxis,yTranslation, h- (margin.top + margin.bottom));
	
	addMainTitle(dataObject.mainTitle,svg,h,margin,0,"mainTitle");
    addXAxisTitle(chart, w, h, margin, dataObject.xTitle,"xAxisTitle");     
    addYAxisTitle(chart, w, h, margin, dataObject.yTitle); 
    addSubXTitle(chart, w, h, margin, dataObject.subTitle,"xAxisTitle");
    
	var rect = chart.selectAll(".bar")
	.data(data).enter()
	.append("rect")
	.attr("class", function(d) { return "bar bar--" + (d.value < 0 ? "negative" : "positive"); })
	.attr("y", function(d) {if (d.value < 0) {return y(0);} else {return(y(d.value));}})
	.attr("x", function(d) { return x(d.name); })
	.attr("height", function(d) {return Math.abs(y(d.value) - y(0)); })
	.attr("width", x.bandwidth())
	
	var xMin = x.range()[0];
	var xMax = x.range()[1];
	var yMax = y.range()[0];
	var yMin = y.range()[1];

	//.attr("y", (y(0) - y(dataObject.calculatedValue) + margin.top)/2 )
	
	chart
	.append("text")
	.attr("y", (yMax - yMin + margin.top)/2)
	.attr("x", (xMax - xMin)/2)
	.text(dataObject.calculatedValue)
    .attr("font-family", "Arial Black")
    .attr("font-size", "20px")
    .attr("fill", "white")
    .style("text-anchor", "middle")
	
//	var text =  chart
//				.selectAll("text")
//				.data(data)
//				.enter()
//				.append("text")
//                .attr("x", function(d, i){
//                    return (y(d.value)/2)
//                })
//                .attr("y", function(d, i){
//                    return (x(d.name))
//                })
//                .attr("font-family", "Arial Black")
//                .attr("font-size", "20px")
//                .attr("fill", "white")
//                .text(function(d, i){return d.value;});

	var tip = null;

	if (tooltipFunction != null) {
		tip = d3.tip()
		.attr('class', 'd3-tip')
		.offset([-10, 0])
		.html(function(d,i) {	    
			return tooltipFunction(dataObject.calculatedValue, dataObject.yTitle);
		})

		svg.call(tip);
	}
	if (tooltipFunction != null) {    
		rect.on('mouseover', tip.show)
		.on('mouseout', tip.hide)
	}
	
	return d3.select("#" + id + "> div").node();

}

function onClickSum(dataObject,i) {
	var message = "<div>" + dataObject.columnNames[i] + ": " + d3.format(".2f")(dataObject.amounts[i]) + "</div>";
	$(message).dialog();
}

function tooltipSum(value, unit) {
	return "<span>" + value + " " + unit + "</span>";
}
