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

function contourChart(responsedata,window,id,visualizationMethod) {
	var dataObject = trimForContourplot(responsedata);
	return d3Contourplot(dataObject,trimForContourplot,window,id,null,null);
}

function onClickContour(dataObject,i) {
	return;	
}

function tooltipContour(dataObject,i) {
	return "Contour tooltip";
}


function trimForContourplot(response){	
	var dataObject = new Object;

	dataObject["main_title"] = (response.main_title == null || response.main_title=="NA") ? null : response.main_title;
	dataObject["x_title"] = (response.x_title == null || response.x_title=="NA") ? null : response.x_title;
	dataObject["y_title"] = (response.y_title == null || response.y_title=="NA") ? null : response.y_title;
	dataObject["sub_title"] = (response.sub_title == null || response.sub_title=="NA") ? null : response.sub_title;
	dataObject["legend_title"] = (response.legend_title == null || response.legend_title=="NA") ? null : response.legend_title;
	dataObject["days"] = (response.days == null || response.days=="NA") ? null : response.days;
	dataObject["hours"] = (response.hours == null || response.hours=="NA") ? null : response.hours;
	var hourData = (response.hour_data == null || response.hour_data=="NA") ? null : response.hour_data;
	
	
	var min = Infinity;
	var max = -Infinity;
	hourData.forEach(function(sub) {
		sub.forEach(function(d,i,hourData) {
			if (!isNaN(parseFloat(d)) && isFinite(d)){
				if (parseFloat(d) < min) {
					min = parseFloat(d);
				}
				if (parseFloat(d) > max) {
					max = parseFloat(d);
				}
			}
		});
	});
	
//	min = min - (max-min)/9;
	
	hourData.forEach(function(sub,i,hourData) {
		sub.forEach(function(d,i,hourData) {
			if (d== null || isNaN(parseFloat(d))){
				sub[i] = min;
			} else {
				sub[i] = parseFloat(d);
			}
		});
	});
	
//	var test = new Array(dataObject.hours.length);
//	
//	var k = 0;
//	for (var i=0; i<dataObject.hours.length; ++i) {
//		 var tmp = new Array(dataObject.days.length);
//		  for (var j=0; j<dataObject.days.length; ++j) {
//		    tmp[j] = hourData[k];
//		    k++;
//		  }
//		  test[dataObject.hours.length - 1 - i] = tmp;
//		}
	
	var hourvals = [];
//	for (var i=0; i<dataObject.hours.length; i++) {
//		  for (var j=0; j<dataObject.days.length; j++) {
//			  hourvals.push(hourData[j + (dataObject.hours.length - i-1)*dataObject.days.length]);
//		  }
//	}
	hourData.forEach(function(sub) {
		sub.forEach(function(d) {
			hourvals.push(d);
		});
	});
	dataObject.hourData = hourvals;
	return dataObject;
}

function ownScale (xScale,yScale) {
    return d3.geoTransform({
        point: function(x, y) {
        	this.stream.point( x*xScale, y*yScale);
        }
    });
    }

var ownScale = d3.geoTransform({
	  point: function(x, y) {
	    this.stream.point(x, -y);
	  }
	});

function d3Contourplot(dataObject, trimForContourplot, window,id,onClickFunction, tooltipFunction){
	
//	try{
		var canvasSize = getCanvasSize();
		
		var margin = canvasSize.margin;
		var window = canvasSize.window;
	    var w = window.width;
	    var h = window.height;
		var legendMargin = canvasSize.legendMargin;
	    	    
		var xTitle = dataObject.x_title;
		var yTitle = dataObject.y_title;		
		var mainTitle = dataObject.main_title;

		var rightMargin = canvasSize.legendMargin.right + 10;

		var parseDate = d3.timeParse("%Y-%m-%d");
		var parseDateTime = d3.timeParse("%Y-%m-%d %H:%M:%S");
		
		
		var xAxisData = dataObject.days;
		xAxisData.forEach(function(d,i,xAxisData) {
			xAxisData[i] = parseDate(d);
		});
		

		
		var x = d3.scaleTime().range([0, w- (margin.left + rightMargin)]);
		x.domain(d3.extent(xAxisData, function(d) { return d; }));
		
		var y = d3.scaleLinear().range([h -(margin.top+ margin.bottom), 0]);
		var ymin = d3.min(dataObject.hours, function(d) { return  d; });
		var ymax = d3.max(dataObject.hours, function(d) { return  d; });
		y.domain([d3.min(dataObject.hours, function(d) { return parseFloat(d); }), d3.max(dataObject.hours, function(d) { return  parseFloat(d); })]);
		
		
		
		var svg = addSvgRoot(id,w,h);		

		var g = svg.append("g")
	    .attr("transform",
	          "translate(" + margin.left + "," + margin.top + ")");
		
		var graphWidth = w - margin.left -rightMargin;
		var graphHeight = h- margin.top - margin.bottom;
		 var xax = g.append("g")
		 	.attr("transform", "translate(0," + graphHeight + ")")
		 	.call(d3.axisBottom(x)
		 			.tickFormat(d3.timeFormat("%Y-%m-%d")))
		 
		 xax.selectAll("text")
		    .attr("y", 0)
		    .attr("x", 9)
		    .attr("dy", ".35em")
		    .attr("transform", "rotate(90)")
		    .style("text-anchor", "start");
		    
		  g.append("g").call(d3.axisLeft(y));
		  
		  var levels = 8;
		  
		  var max = d3.max(dataObject.hourData, function(d) { return parseFloat(d); });  	
		  var min = d3.min(dataObject.hourData, function(d) { return parseFloat(d); });  
		  
		  var colorScale = d3.scaleQuantize()
	        			      .domain([0 , max])
	        			      .range(blueScale8);
		    
		  var contours = d3.contours()
		    .size([dataObject.days.length, dataObject.hours.length])
		    .thresholds(levels)
		    (dataObject.hourData)
		    
		  for (var i =0 ; i< contours.length; i++) {
			  var contourPoly = contours[i].coordinates;
			  for (var j=0; j < contourPoly.length; j++) {
				  var contour = contourPoly[j];
				  for (var k = 0; k< contour.length; k++) {
					  var coordinates = contour[k]; 
					  for (var l = 0; l< coordinates.length; l++) {
						  	coordinates[l][0] = coordinates[l][0]*graphWidth/dataObject.days.length;
						  	coordinates[l][1] = coordinates[l][1]*graphHeight/dataObject.hours.length;
					  }
				  }
			  }
		  }
	  
		  
		   g.selectAll("path")
		     .data(contours)
		    .enter().append("path")
		    .attr("d", d3.geoPath(d3.geoIdentity()))
		    .attr("fill", function(d) { 
		    	return colorScale(d.value); 
		    	});
		
			addMainTitle(dataObject.main_title,svg,h,margin,0,"mainTitle");
		    addXAxisTitle(g, w, h, margin, dataObject.x_title,"xAxisTitle");     
		    addYAxisTitle(g, w, h, margin, dataObject.y_title); 
		    addSubXTitle(g, w, h, margin, dataObject.subTitle,"xAxisTitle");
		    		    
		    addColorLegend(svg, w, h, margin, legendMargin,colorScale ,dataObject.legendTitle);
		    	
			 return d3.select("#" + id + "> div").node();
//	}
//	catch(e){
//		alert("BIZARRE: " + e);
//	}
}


