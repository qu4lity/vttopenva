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

function trimForScatterplot(response){
	
    if ("error" in response) {
        console.log(response);
        return(response);
    }   
    var data = new Object;    
     
    var xCoords = [];
    var yCoords = [];
    var meta = [];
    var objectids = [];
    var taskids = [];
    
    var dataMatrix = response.matrix;
    for (i in dataMatrix) {
        if (dataMatrix[i].length == 2) {
            // data frame may have missing values!!!!
            xCoords.push(parseFloat(dataMatrix[i][0]));
            yCoords.push(parseFloat(dataMatrix[i][1]));
        }
    }
     
    data["xCoords"] =  xCoords;
    data["yCoords"] =  yCoords;  
    for (var key in response) {
    	addProperty(key,data,response[key]);
    }
    
    
    return data;
}

function addProperty(key,data,value) {
	if (value != null && value!="NA" && key !="image" && key!="matrix") {
		data[key] = value;
	}
}



function minLimit(min,lowerLimit, alarmLowerLimit) {
	if (lowerLimit == null && alarmLowerLimit == null) {
		return min;
	}

	if (lowerLimit == null) {
		return Math.min(min,alarmLowerLimit)
	}

	if (alarmLowerLimit == null) {
		return Math.min(min,lowerLimit)
	}	

	return Math.min(min,lowerLimit,alarmLowerLimit)
}

function maxLimit(max,upperLimit, alarmUpperLimit) {
	if (upperLimit == null && alarmUpperLimit == null) {
		return max;
	}

	if (upperLimit == null) {
		return Math.max(max,alarmUpperLimit)
	}

	if (alarmUpperLimit == null) {
		return Math.max(max,upperLimit)
	}	

	return Math.max(max,upperLimit,alarmUpperLimit)
}


function scatterplotChart(responsedata,window,id) {
	responsedata = trimForScatterplot(responsedata);
	
	var canvasSize = getCanvasSize();	
	var margin = canvasSize.margin;
	var window = canvasSize.window;
    var w = window.width;
    var h = window.height;
	
    var mainTitle = responsedata.title;
 
    var xCoords = responsedata.xCoords;
    var yCoords = responsedata.yCoords;
    var xTitle = responsedata.xTitle;
    var yTitle = responsedata.yTitle;
 
 
    var slope = parseFloat(responsedata.slope);
    var intercept = parseFloat(responsedata.intercept);
     
    var color = "black";
 
    var innerPad = 5;
 
    var data = []
    for (i in xCoords) {
        data.push({x:parseFloat(xCoords[i]), y:parseFloat(yCoords[i])});                
    }
    
    var xExt = d3.extent(xCoords);
    var xMin = minLimit(xExt[0],responsedata.xLowerLimit, responsedata.xAlarmLowerLimit); 
    var xMax = maxLimit(xExt[1],responsedata.xUpperLimit, responsedata.xAlarmUpperLimit); 
    var yExt = d3.extent(yCoords);
    var yMin = minLimit(yExt[0],responsedata.yLowerLimit, responsedata.yAlarmLowerLimit); 
    var yMax = maxLimit(yExt[1],responsedata.yUpperLimit, responsedata.yAlarmUpperLimit); 
    var yPadding = (yMax-yMin)*0.02;
    var xPadding = (xMax-xMin)*0.02;
    
	var svg2 = addSvgRoot(id,w,h);
    
    addMainTitle(mainTitle,svg2,w,margin,0,"mainTitle");

    var scatterplot = svg2.append("g")
    .attr("id", "scatterplot")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
 
//  this is a clipath for clipping the regression line
//  i.e showing only the part of the line that is within the graph
    addClipPath(scatterplot, w - (margin.left + margin.right),h -(margin.top + margin.bottom),xPadding,yPadding);
 
    var xScale, yScale;
    d3.selectAll("circle.points").remove();
    d3.selectAll("text.axes").remove();
    d3.selectAll("line.axes").remove();
     
    
    xScale = d3.scaleLinear().domain([xMin,xMax]).range([0, w - (margin.left + margin.right)]);
    yScale = d3.scaleLinear().domain([yMin,yMax]).range([h -(margin.top + margin.bottom), 0]);
        
      
    
    addXAxisTitle(scatterplot, w, h, margin, xTitle,"xAxisTitle");   
    addYAxisTitle(scatterplot, w, h, margin, yTitle); 
 
    addMainRect(scatterplot, w - (margin.left + margin.right),h -(margin.top + margin.bottom), xScale(xPadding),h  -(margin.top + margin.bottom)- yScale(yPadding));
//    xticks = xScale.ticks(5);
//    yticks = yScale.ticks(5);
 
 //   addXAxes(scatterplot,xticks,xScale,h,margin);
    addXAxisNumericScale(scatterplot,d3.axisBottom(xScale),yScale(0 - yPadding));
	addYAxis(scatterplot,d3.axisLeft(yScale), xScale(0 - xPadding));
   // addYAxes(scatterplot,yticks,yScale,w,margin);
    

//    addXGridlines(scatterplot,xticks,xScale,h,margin);  
//    addYGridlines(scatterplot,yticks,yScale,w,margin);
 
 
     
    var points = scatterplot.selectAll("empty")
    .data(d3.range(xCoords.length))
    .enter()
    .append("circle")
    .attr("class", "points")
    .attr("cx", function(d) { return xScale(xCoords[d]);})
    .attr("cy", function(d) { return yScale(yCoords[d]);})
    .attr("r", 3)
    .attr("stroke", "black")
    .attr("stroke-width", 1)
    .attr("fill", color) 
    .attr("pointer-events", "all") 
    .on("mouseover", function(d) {
        d3.select(this).attr("fill", "white");
        return tip.show(d,this);  
    }).on("mouseout", function() {
         d3.select(this).attr("fill", color);
        return tip.hide();
    });
 
    var maxWidth = xScale.invert(w - (margin.right + margin.left));
     
    // this adds a regression line y = slope*x + intercept  
     if (intercept != null && slope != null) {
    	 var x0 = xScale.invert(0);
    	 addLine(scatterplot,xScale,yScale,x0,maxWidth,intercept,intercept + slope*maxWidth,"line-sc-regression",null);
    }
    
    // add an alarm lowerlimit line
    if (responsedata.xAlarmLowerLimit != null) {
    	 addLine(scatterplot,xScale,yScale,responsedata.xAlarmLowerLimit,responsedata.xAlarmLowerLimit,yMax + yPadding ,yMin - yPadding,"line-sc-alarmLowerlimit",null);
    }
  
    if (responsedata.xLowerLimit != null) {
    	addLine(scatterplot,xScale,yScale,responsedata.xLowerLimit,responsedata.xLowerLimit,yMax + yPadding,yMin- yPadding,"line-sc-lowerLimit",null);
    } 
    
    if (responsedata.xAlarmUpperLimit != null) {
    	addLine(scatterplot,xScale,yScale,responsedata.xAlarmUpperLimit,responsedata.xAlarmUpperLimit,yMax + yPadding,yMin - yPadding,"line-sc-alarmUpperLimit",null);
    }
  
    if (responsedata.xUpperLimit != null) {
    	addLine(scatterplot,xScale,yScale,responsedata.xUpperLimit,responsedata.xUpperLimit,yMax + yPadding,yMin- yPadding,"line-sc-upperLimit",null);
    } 
   
    if (responsedata.yAlarmLowerLimit != null) {
    	addLine(scatterplot,xScale,yScale,xMin - xPadding,xMax + xPadding,responsedata.yAlarmLowerLimit,responsedata.yAlarmLowerLimit,"line-sc-alarmLowerLimit",null);
    }
  
    if (responsedata.yLowerLimit != null) {
    	addLine(scatterplot,xScale,yScale,xMin - xPadding,xMax + xPadding,responsedata.yLowerLimit,responsedata.yLowerLimit,"line-sc-lowerLimit",null);
    }
    
    if (responsedata.yAlarmUpperLimit != null) {
    	addLine(scatterplot,xScale,yScale,xMin - xPadding,xMax + xPadding,responsedata.yAlarmUpperLimit,responsedata.yAlarmUpperLimit,"line-sc-alarmUpperLimit",null);
    }
    if (responsedata.yUpperLimit != null) {
    	addLine(scatterplot,xScale,yScale,xMin - xPadding,xMax+ xPadding,responsedata.yUpperLimit,responsedata.yUpperLimit,"line-sc-upperLimit",null);
    }

//  var brush = d3.brush()
//  svg2.append('g')
//     .attr('class', 'brush')
//     .call(brush); 
//    brush.on('brush', function() {
//        var extent = brush.extent();
//        points.classed("selected", function(d) {    
//                d3.select(this).attr("fill", "black")
//          });
//    }).on("end", function() {
//         if (!d3.event.sourceEvent) return; // Only transition after input.
//         if (!d3.event.selection) return; // Ignore empty selections.
//           
//        var extent = d3.event.selection;
//         
//         
//        var minx = xScale2.invert(extent[0][0] - margin.left) ;
//        var maxx = xScale2.invert(extent[1][0] - margin.left) ;
//        var miny = yScale2.invert(extent[1][1] - margin.top)  ;
//        var maxy = yScale2.invert(extent[0][1] - margin.top) ;
//         
//        console.log(minx + " " + maxx + " " + miny + " " + maxy);
//        var oiIds = [];
//        var taskIds = [];
//        points.classed("selected", function(d) {    
//            is_brushed = minx <= data[d].x && data[d].x <= maxx && 
//                         miny <= data[d].y && data[d].y <= maxy ;
//            if (is_brushed) {
//                d3.select(this).attr("fill", "white")
//                console.log(" objectid " + data[d].objectid + " taskid " + data[d].taskid);
//                taskIds.push(data[d].taskid);   
//            }
//          });
//        makeOiList(taskIds);
//    });
     
    var tip = d3.tip()
    .attr('class', 'd3-tip')
    .offset([-10, 0])
    .html(function(d) {
        console.log(d);
        return "<span style='color:black'>" + xCoords[d] + " " + yCoords[d] + "</span>";
    })
 
    svg2.call(tip);
    var tempt = d3.select("#" + id + "> div").node();
	return d3.select("#" + id + "> div").node();
	
};

//function addXAxes(chart, xticks,xScale,h,margin) {
//	chart.selectAll("empty")
//    .data(xticks)
//    .enter()
//    .append("text")
//    .attr("class", "axes")
//    .text(function(d) { return d3.format("d")(d);})  // this shows the value in integer
//    .attr("x", function(d) { return xScale(d);})
//    .attr("y", h + margin.bottom * 0.3)
//    .attr("dominant-baseline", "middle")
//    .attr("text-anchor", "middle");
//}
    
function addXGridlines(graph,xticks,xScale,h,margin) {
	graph.selectAll("empty")
	.data(xticks)
	.enter()
	.append("line")
	.attr("class", "axes")
	.attr("x1", function(d) { return xScale(d);})
	.attr("x2", function(d) {return xScale(d);})
	.attr("y1", 0)
	.attr("y2", h)
	.attr("stroke", "LightGrey")
	.attr("stroke-width", 1);
}



//function addYAxes(chart, yticks,yScale,w,margin) {
//	chart.selectAll("empty")
//	.data(yticks)
//	.enter()
//	.append("text")
//	.attr("class", "axes")
//	.text(function(d) { return d3.format("d")(d);})
//	.attr("x", -margin.left * 0.1)
//	.attr("y", function(d) {return yScale(d);})
//	.attr("dominant-baseline", "middle")
//	.attr("text-anchor", "end");
//}

function addYGridlines(graph,yticks,yScale,w,margin) {
	graph.selectAll("empty")
	.data(yticks)
	.enter()
	.append("line")
	.attr("class", "axes")
	.attr("y1", function(d) { return yScale(d);})
	.attr("y2", function(d) { return yScale(d);})
	.attr("x1", 0)
	.attr("x2", w)
	.attr("stroke", "LightGrey")
	.attr("stroke-width", 1);
}



//function addSCLine(scatterplot,xscale,yscale,x0,x1,y0,y1,color) {
//    scatterplot
//    .append("g")
//    .attr("clip-path", "url(#clip)")
//    .append("line")
//    .attr("stroke", color)
//    .attr("stroke-width", 1)
//    .attr("x1",  xscale(x0))
//    .attr("x2", xscale(x1))
//    .attr("y1", yscale(y0))
//    .attr("y2", yscale(y1))
//    .attr("clip-path", "url(#mainrect)") 
//}



//this is a clipath for clipping the regression line
//i.e showing only the part of the line that is within the graph
function addClipPath(graph,w,h,xPadding,yPadding) {
	graph.append("svg:clipPath")
	.attr("id", "clip")
	.append("svg:rect")
	.attr("height", h)
	.attr("width", w)
	.attr("fill", d3.rgb(255,255,255))
	.attr("stroke", "black")
	.attr("stroke-width", 1)
	.attr("pointer-events", "none")
	.attr("transform", "translate(" + -xPadding +"," + -yPadding + ")");;  
}


function addMainRect(graph,w,h,xPadding,yPadding) {
	graph.append("rect")
	.attr("class","mainrect")
	.attr("height", h + 2*yPadding)
	.attr("width", w + 2*xPadding)
	.attr("fill", "none")
	.attr("stroke", "black")
	.attr("stroke-width", 1)
	.attr("pointer-events", "none")
	.attr("transform", "translate(" + -xPadding +"," + -yPadding + ")");
}






