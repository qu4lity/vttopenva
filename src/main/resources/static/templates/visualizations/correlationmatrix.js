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
		
		function trimForCorrMat(response){
		    var data = new Object;
		    data["corr"]= response.correlations;
		    data["title"] =  response.title;
		    data["vars"] =  response.variableNames;
		    data["varids"] =  response.variableids;
		    data["oiids"] =  response.oiids;
		     
		    return data;
		}
		
		
		function correlationmatrixChart(response,window,id,visualizationMethod) {
			
			var data =  trimForCorrMat(response);
			var canvasSize = getCanvasSize();
			
			var margin = canvasSize.margin;
			var window = canvasSize.window;
		    var w = window.width;
		    var h = window.height;
			var legendMargin = canvasSize.legendMargin;
			var rightMargin = canvasSize.legendMargin.right + 10;
			
			
			var mainTitle = data.title;
		     
			var svg = addSvgRoot(id,w,h);
		 
			addMainTitle(mainTitle,svg,h,margin,0,"mainTitle");
		 
			var matrixw = w - (margin.left + margin.right);
			var matrixh = h - (margin.top + margin.bottom);
		    
			// correlation matrix should be rectangular
			if (matrixh> matrixw) {
			    matrixh = matrixw;
			}
			if (matrixw > matrixh) {
			    matrixw = matrixh;
			}	
				
		    var corrplot = svg.append("g")
		    .attr("id", "corrplot")
		    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
		 
		//  no. data points
		    var nvar = data.vars.length;
		 
		    var rectSize = (matrixw)/nvar;
		 
		    var corXscale = d3.scaleBand().domain(d3.range(nvar)).range([0, matrixw]);
		    var corYscale = d3.scaleBand().domain(d3.range(nvar)).range([matrixw, 0]);
		    var corZscale = d3.scaleLinear().domain([-1, 0, 1]).range(["crimson", "white", "darkslateblue",]);
		 
		//  create list with correlations
		    var corr = [];
		    var corr_left_corner = [];
		    var corr_right_corner = [];	    
		    for (var i in data.corr) {
		        for (var j in data.corr[i]){
		            corr.push({row:i, col:j, value:data.corr[i][j]});  
		            if (i < j) {corr_right_corner.push({row:i, col:j, value:data.corr[i][j]});}
		            if (i >= j) {corr_left_corner.push({row:i, col:j, value:data.corr[i][j]});}
		        }
		    }
		 
		    var cells = corrplot.append("g")
		    .attr("id", "cells")
		    .selectAll("empty")
		    .data(corr)
		    .enter()
		    .append("rect")
		    .attr("class", "cell")
		    .attr("x", function(d) { return corXscale(d.col);})
		    .attr("y", function(d) { return corYscale(d.row);})
		    .attr("width", corXscale.bandwidth())
		    .attr("height", corYscale.bandwidth())
		    .attr("fill","none")
		    .attr("stroke", "black")
		    .attr("stroke-width", 1);
		 
		    var circles = corrplot.append("g")
		    .attr("id", "corrplot_circles")
		    .selectAll("empty")
		    .data(corr_right_corner)
		    .enter()
		    .append("circle")
		    .attr("class", "points")
		    .attr("cx", function(d) { return corXscale(d.col) + corXscale.bandwidth()/2})
		    .attr("cy", function(d) { return corYscale(d.row) + corYscale.bandwidth()/2})
		    .attr("r", function(d) { return (corXscale.bandwidth() - 2)*d.value/2})
		    .attr("stroke", "black")
		    .attr("stroke-width", 1)
		    .attr("fill", function(d) { 
	        	if (d.col <= d.row) {
	        		return ("WHITE")
	        	} else {
			    	if (d.value == "?") {return "WHITE" } 
			    	else {return corZscale(d.value)};}
	        	})
		    	.attr("stroke", "black")
		    	.attr("stroke-width", 1);	
		    
		    var fontsize ="14";
		     if(data.corr.length > 4 && data.corr.length < 8) {
		    	 fontsize ="12";
		     } 
		     else if(data.corr.length > 7 && data.corr.length < 10) {
		    	 fontsize ="10";
		     } 
		     else if(data.corr.length > 10) {
		    	 fontsize ="8";
		     } 
		     
		      corrplot.selectAll("empty")
		        .data(corr_left_corner)
		        .enter()
		        .append("text")
		        .attr("id", "corrtext")
		        .text(function(d) {
		        	if (d.col == d.row) {
		        		return data.vars[d.col]
		        	} else {
			        	if (d.value == "?") {return "?" } 
			        	else {return d3.format(".2f")(d.value)}			        	
		        	}
		        })
		        .attr("x", function(d) { 
		            return d.col*rectSize + rectSize/2;
		        })
		        .attr("y", function(d) { 
		            return (nvar - d.row -1)*rectSize + rectSize/2;
		        })
		        .attr("fill", function(d) { 
		        	if (d.col == d.row) {
		        		return "red"
		        	} else {
			        	return "black";		        	
		        	}
		        })
		        .attr("dominant-baseline", "middle")
		        .attr("text-anchor", "middle")
		        .attr("font-size",fontsize);		

		 
		    var tip = d3.tip()
		      .attr('class', 'd3-tip')
		      .offset([-10, 0])
		      .html(function(d) {
		          return "<span style='color:red'>" + d3.format(".2f")(d.value) + "</span>";
		      })
		 
		      svg.call(tip);
		 
		    // transparent cells on top for mouse events
		    corrplot.append("g")
		    .attr("id", "cells2")
		    .selectAll("empty")
		    .data(corr)
		    .enter()
		    .append("rect")
		    .attr("class", "cell")
		    .attr("x", function(d) { return corXscale(d.col);})
		    .attr("y", function(d) { return corYscale(d.row);})
		    .attr("width", corXscale.bandwidth())
		    .attr("height", corYscale.bandwidth())
		    .attr("fill", "fff")
		    .attr("fill-opacity", 0)
		    .attr("stroke", "none")
		    .attr("stroke-width", 2)
		    .on("mouseover", function(d) {
		        d3.select(this)
		        .attr("stroke", "red");
		        var row = d.row;
		        var col = d.col;
		        if (nvar > 15) {
		            tip.show(d);
		            corrplot.append("text")
		                    .attr("class", "corrlabel")
		                    .attr("x", rectSize/2 + corXscale(col))
		                    .attr("y", h - margin.bottom * 0.8)
		                    .text(data.vars[col])
		                    .attr("dominant-baseline", "middle")
		                    .attr("text-anchor", "middle");
		              return corrplot.append("text")              
		                             .attr("class", "corrlabel")
		                             .attr("y", rectSize/2 +  corYscale(row))
		                             .attr("x", -margin.left * 0.9)
		                             .text(data.vars[row])
		                             .attr("dominant-baseline", "middle")
		                             .attr("text-anchor", "end");
		        }           
		    }).on("mouseout", function() {
		        if (nvar > 15) {
		            d3.selectAll("text.corrlabel").remove();
		            d3.selectAll("text#corrtext").remove();
		            tip.hide()
		        }
		        return d3.select(this).attr("stroke", "none");
		    }).on("click", function(d) {
		        var variationIds = [];
		        variationIds.push(data.varids[d.col]);
		        variationIds.push(data.varids[d.row]);
		        
//				parameterService.setVisualizationMethod("Scatterplot");
//				visualizationService.add("scatterplot" +"-"+ Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 5));
		    }); 
		 
		    corrplot.append("rect")
		    .attr("height", matrixh)
		    .attr("width",matrixh)
		    .attr("fill", "none")
		    .attr("stroke", "black")
		    .attr("stroke-width", 1)
		    .attr("pointer-events", "none");
		 
		 
		 
		    var yLegend = h - margin.bottom*0.7;
		    svg.append("g")
		      .attr("class", "legendLinear")
		      .attr("transform", "translate(20," + yLegend  +")");
		 
		    var legendLinear = d3.legendColor()
		      .shapeWidth(22)
		      .cells(20)
		      .orient('horizontal')
		      .scale(corZscale)
		       
		      svg.select(".legendLinear")
		      .call(legendLinear);
		    	d3.select("div#legend").style("opacity", 1);
		    
		    	return d3.select("#" + id + "> div").node();
		}

		function onClickCorrelationMatrix(dataObject,i) {
			return;	
		}

		function tooltipCorrelationMatrix(dataObject,i) {
			return "CorrelationMatrix tooltip";
		}		







