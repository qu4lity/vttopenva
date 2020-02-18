function showPdfFile(dataObject, width, height) {
	var url = dataObject.file;
//	var node = $("<a class='downloadLink' href='"+ url + "' target='_blank' rel='noopener noreferrer' \>Open pdf file</a>").get(0);
	if (dataObject.width != null && dataObject.height != null) {
		return $("<embed src=" + url + " width='" + dataObject.width + "' height='" + dataObject.height + "' alt='pdf' pluginspage='http://www.adobe.com/products/acrobat/readstep2.html'>").get(0);
	} else {
		return $("<embed src=" + url + " alt='pdf' pluginspage='http://www.adobe.com/products/acrobat/readstep2.html'>").get(0);
	}	
}

function openPdfTab(url) {
	var node = $("<a class='downloadLink' href='"+ url + "' target='_blank' rel='noopener noreferrer' \>Open pdf file</a>").get(0);
	return node;	
}


