// d3.legend.js 
// (C) 2012 ziggy.jonsson.nyc@gmail.com
// MIT licence

// https://gist.github.com/ZJONSSON/3918369
// edited by Pekka Siltanen

(function() {
d3.simpleLegend = function(g) {
  g.each(function() {
    var g= d3.select(this),
    	svg = d3.select(g.property("nearestViewportElement")),
        legendPadding = g.attr("data-style-padding") || 5,
        lb = g.selectAll(".legend-box").data([true]);


    var rect = lb.enter().append("rect").classed("legend-box",true);
    
    var licreate = g.selectAll(".legend-items")
        	.data(["g"])
        	.enter()
        	.append("g")
        	.attr("class", "legend-items");
    var li = g.selectAll(".legend-items");

    
    // lines are shown as lines in legend, others as circle
    var items = {};
    var lineItems = {};
    
    svg.selectAll("[data-legend]").each(function() {
        var self = d3.select(this);
        var nodeName = self.node().nodeName;
        if (nodeName ==="line" || nodeName ==="path") {
        	lineItems[self.attr("data-legend")] = {
        			key: self.attr("data-legend"),
        			pos : self.attr("data-legend-pos") || this.getBBox().y, 
        			classes: self.node().classList.toString()
        	} 
        } else {
        	items[self.attr("data-legend")] = {
        			key: self.attr("data-legend"),
        			pos : self.attr("data-legend-pos") || this.getBBox().y,
        			color : self.attr("data-legend-color") != undefined ? self.attr("data-legend-color") : self.style("fill") != 'none' ? self.style("fill") : self.style("stroke") 

        	} 		
        }
        
      })

    items = d3.entries(items).sort(function(a,b) { return a.value.pos-b.value.pos})

    
    li.selectAll("text")
        .data(items).enter()
        .append("text")
        .attr("y",function(d,i) { return i+"em"})
        .attr("x","1em")
        .text(function(d) {console.log(d.value.key) ;return d.value.key})
    
    li.selectAll("circle")
        .data(items)
        .enter().append("circle")
        .attr("cy",function(d,i) { return i-0.25+"em"})
        .attr("cx",0)
        .attr("r","0.4em")
        .style("fill",function(d) { console.log(d.value.color);return d.value.color})  
     
   lineItems = d3.entries(lineItems).sort(function(a,b) { return a.value.pos-b.value.pos})     
        
   li.selectAll("text")
        .data(lineItems).enter()
        .append("text")
        .attr("y",function(d,i) { return i+"em"})
        .attr("x","40")
        .text(function(d) {console.log(d.value.key) ;return d.value.key})    
        
    li.selectAll("line")
        .data(lineItems)
        .enter().append("line")
        .attr("x1",0)
        .attr("x2",30)
        .attr("y1",function(d,i) { return i-0.25+"em"})
        .attr("y2",function(d,i) { return i-0.25+"em"})
        .attr("class",function(d) { console.log(d.value.classes) ;return d.value.classes})   
    
    // Reposition and resize the box
 
        
//    var lbbox = li[0][0].getBBox() 
    var lbbox = li.node().getBBox();
//    var rect = lb.select("rect");
    rect.attr("x",(lbbox.x-legendPadding))
        .attr("y",(lbbox.y-legendPadding))
        .attr("height",(lbbox.height+2*legendPadding))
        .attr("width",(lbbox.width+2*legendPadding))
  })
  return g
}
})()