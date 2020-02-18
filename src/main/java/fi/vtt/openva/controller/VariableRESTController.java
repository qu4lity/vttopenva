// OpenVA - Open software platform for visual analytics
//
// Copyright (c) 2018, VTT Technical Research Centre of Finland Ltd
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//    1) Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//    2) Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//    3) Neither the name of the VTT Technical Research Centre of Finland nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package fi.vtt.openva.controller;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import com.google.gson.Gson;
import fi.vtt.openva.domain.Codevalues;
import fi.vtt.openva.domain.Objectofinterest;
import fi.vtt.openva.domain.OiBackgroundpropertyValue;
import fi.vtt.openva.domain.Oitype;
import fi.vtt.openva.domain.OitypeProperty;
import fi.vtt.openva.domain.PropertyGroup;
import fi.vtt.openva.repositories.RepositoryService;


/**
 * VariableRESTController
 * 
@author Pekka Siltanen, Markus Ylikerälä
 *
 */

@RestController
@RequestMapping("/query")
public class VariableRESTController {
	private static Logger log = LogManager.getLogger(VariableRESTController.class);
	@Autowired
	private RepositoryService repositoryService;


	/**
	 * Returns a json string of Variables of given property type, that are linked to 
	 * a ObjectOfInterest whose id given as parameter.
	 *
	 * @param oisId ObjectofInterestId
	 * @param propertyType property type: one of "M","B","I","C"
	 * @return      json string
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getVariablesByOiTypeTitle/{oiTypeTitle}/{propertyType}", method = RequestMethod.GET)
	public String getVariablesByOIType(@PathVariable String oiTypeTitle, @PathVariable String propertyType) throws InterruptedException{

		Oitype oiType = repositoryService.getOitype(oiTypeTitle);
		if (oiType != null) {
			List<Variable> variables = new ArrayList<Variable>();		
			getProperties(propertyType, variables, oiType.getId());
			Gson gson = new Gson();
			return gson.toJson(variables);
		} else {
			return null;
		}
		


	}

	// Note: this is too slow for a big database. Store min/maxtime to application table instead
	@RequestMapping(value = "/getMinMaxTime/{applicationTitle}", method = RequestMethod.GET)
	public String getMinMaxTime(@PathVariable String applicationTitle) throws InterruptedException{

		List<String> minmax = repositoryService.getMinAndMaxTimeMeasurements(applicationTitle);

		Gson gson = new Gson();
		return gson.toJson(minmax);

	}

	
	private class PropGroup {
		public String getType() {
			return type;
		}

		public void setType(String type) {
			this.type = type;
		}

		/** The title. */
		private String title;		
		/** The report title. */
		private String reportTitle;		
		private Integer id;
		private String type;
		
		public String getReportTitle() {
			return reportTitle;
		}

		public void setReportTitle(String reportTitle) {
			this.reportTitle = reportTitle;
		}
		
		
		public String getTitle() {
			return title;
		}

		public void setTitle(String title) {
			this.title = title;
		}
		
		public Integer getId() {
			return this.id;
		}

		public void setId(Integer id) {
			this.id = id;
		}
		
		PropGroup(PropertyGroup pg){
			setTitle(pg.getTitle());
			setReportTitle(pg.getReportTitle());
			setId(pg.getId());
			setType(pg.getGroupType());
		}
	}
	
	@RequestMapping(value = "/getVariableGroups/", method = RequestMethod.GET)
	public String getVariableGroups() throws InterruptedException{
		List<PropertyGroup> propertyGroups = repositoryService.getPropertyGroups();
		List<PropGroup> propGroups = new ArrayList<PropGroup>();	
		
		for(PropertyGroup propertyGroup : propertyGroups) {
			PropGroup pg = new PropGroup(propertyGroup);
			propGroups.add(pg);
		}
		Gson gson = new Gson();
		return gson.toJson(propGroups);
	}

	

	
	/**
	 * Returns a json string of Variables of given group, that are linked to 
	 * a ObjectOfInterest whose id given as parameter.
	 *
	 * @param oisId ObjectofInterestId
	 * @param groupTitle title of a group
	 * @return      json string
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getVariablesByGroup/{oiTypeId}/{groupId}", method = RequestMethod.GET)
	public String getVariablesByGroup(@PathVariable Integer oiTypeId, @PathVariable Integer groupId) throws InterruptedException{
		List<Variable> variables = getPropertiesByGroup(oiTypeId,groupId);
		Gson gson = new Gson();
		String jsonInString = gson.toJson(variables);
		return jsonInString;
	}

	/**
	 * Gets the properties.
	 *
	 * @param groupTitle the group title
	 * @param oiTypeId the object type identifier
	 * @return 
	 * @return the properties
	 */	
	private List<Variable> getPropertiesByGroup(Integer oiTypeId, Integer groupId) {
	List<Variable> variables = new ArrayList<Variable>();	
	List<OitypeProperty> oitypeProperties = repositoryService.getOIPropertyTypesByGroup(groupId);
	for(OitypeProperty oitypeProperty : oitypeProperties) {
		if(oiTypeId == oitypeProperty.getOitype().getId()){
			Variable variable = new Variable(oitypeProperty);
			variables.add(variable);
		}		
	}
	return variables;
}
	
	
		
	/**
	 * Returns a json string of Variables of given group member, that are linked to 
	 * a ObjectOfInterest whose id given as parameter.
	 *
	 * @param oisId ObjectofInterestId
	 * @param propertyId property type: one of "M","B","I"
	 * @return      json string
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getVariables/{oisId}/{propertyType}", method = RequestMethod.GET)
	public String getVariables(@PathVariable Integer oisId, @PathVariable String propertyType) throws InterruptedException{

		Objectofinterest oi = repositoryService.findById(oisId).orElse(null);
		List<Variable> variables = new ArrayList<Variable>();		
		getProperties(propertyType, variables, oi.getOitype().getId());
		Gson gson = new Gson();
		return gson.toJson(variables);

	}

	/**
	 * Gets the properties.
	 *
	 * @param propertyType the property enum
	 * @param variables the variables
	 * @return the properties
	 */
	private void getProperties(String propertyType,List<Variable> variables, Integer oiTypeId) {
		List<OitypeProperty> oitypeProperties = repositoryService.getOIPropertyTypes();
		for(OitypeProperty oitypeProperty : oitypeProperties){
			if(propertyType.equalsIgnoreCase(oitypeProperty.getPropertytype()) && oiTypeId == oitypeProperty.getOitype().getId()){
				Variable variable = new Variable(oitypeProperty);
				variables.add(variable);
			}
		}
	}



	/**
	 * Variable.
	 *
	 * Private class for storing the property types database information used in UI
	 */
	private class Variable{

		private int id;
		private String text;
		private String description;
		private String timeunit;
		private String propertyType;
		private String title;
		List<Variable> variables;

		public List<Variable> getVariables() {
			return variables;
		}

		public void setVariables(List<Variable> variables) {
			this.variables = variables;
		}

		public String getPropertyType() {
			return propertyType;
		}

		public void setPropertyType(String propertyType) {
			this.propertyType = propertyType;
		}

		Variable(OitypeProperty oitypeProperty){
			setId(oitypeProperty.getId());
			setTitle(oitypeProperty.getTitle());
			setDescription(oitypeProperty.getDescription());
			setText(oitypeProperty.getReportTitle());
			setTimeunit(oitypeProperty.getTimeUnit());
			setPropertyType(oitypeProperty.getPropertytype());
		}

		public String getDescription() {
			return description;
		}

		public void setDescription(String description) {
			this.description = description;
		}

		public String getText() {
			return text;
		}

		public void setText(String text) {
			this.text = text;
		}

		public int getId() {
			return id;
		}

		public void setId(int id) {
			this.id = id;
		}	
		
		public String getTimeunit() {
			return timeunit;
		}

		public void setTimeunit(String timeunit) {
			this.timeunit = timeunit;
		}

		public String getTitle() {
			return title;
		}

		public void setTitle(String title) {
			this.title = title;
		}
	}

	/**
	 * Gets codeValues by code title.
	 *
	 * @return the object types
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getCodeValues/{codeTitle}", method = RequestMethod.GET)
	public String getObjectTypes(@PathVariable String codeTitle) throws InterruptedException{
		try {

			ArrayList<Codevalue> cvs = new ArrayList<Codevalue>();
			Gson gson = new Gson();
			List<Codevalues> codevalues = repositoryService.getCodeValues(codeTitle);
			for(Codevalues cv : codevalues){
				cvs.add(new Codevalue(cv));
			}		
			return gson.toJson(cvs);	
		}
		catch(Throwable t){
			t.printStackTrace(System.err);
			//System.err.println(t);
			throw new InterruptedException(t.getMessage());			
		}
	}

	private class Codevalue {
		private int id;
		private String title;
		private String codeValue;
		private String codesTitle;	

		public int getId() {
			return id;
		}

		public void setId(int id) {
			this.id = id;
		}

		public String getTitle() {
			return title;
		}

		public void setTitle(String title) {
			this.title = title;
		}

		public String getCodeValue() {
			return codeValue;
		}

		public void setCodeValue(String val) {
			this.codeValue= val;
		}

		public String getCodesTitle() {
			return codesTitle;
		}

		public void setCodesTitle(String val) {
			this.codesTitle= val;
		}

		Codevalue(Codevalues codeval){
			setId(codeval.getId());
			setTitle(codeval.getTitle());
			setCodeValue(codeval.getCodeValue());
			setCodesTitle(codeval.getCodesTitle());
		}	

	}	

	@RequestMapping(value = "/getBackgroundValues/{typePropIds}", method = RequestMethod.GET)
	public String getBackgroundValues(@PathVariable String typePropIds) throws InterruptedException{
		Gson gson = new Gson();
		String[] ids = typePropIds.split(",");
		ArrayList<BackgroundValue> cvs = new ArrayList<BackgroundValue>();
		for (int i= 0; i<ids.length; i++ ) {
			OitypeProperty oit =repositoryService.getOIPropertyTypeById(Integer.parseInt(ids[i])).orElse(null);
			List<OiBackgroundpropertyValue> bgvs = repositoryService.getBackgroundValuesByOiTypeProperty(oit);
			for (OiBackgroundpropertyValue bgv : bgvs) {
				cvs.add(new BackgroundValue(bgv));
			}

		}
		return gson.toJson(cvs);		
	}
	
	
	/**
	 * Gets unique backgroundvalues by id.
	 *
	 * @return the object types
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getUniqueBackgroundValues/{typeTitle}/{codesTitle}", method = RequestMethod.GET)
	//@ResponseBody	
	public String getUniqueBackgroundValues(@PathVariable String typeTitle,@PathVariable String codesTitle) throws InterruptedException{
		try {

			ArrayList<BackgroundValue> cvs = new ArrayList<BackgroundValue>();
			Gson gson = new Gson();
			 
				
			List<OitypeProperty> oiTypes = repositoryService.getOIPropertyTypesByTitle(typeTitle);
			if (oiTypes.size() != 1) {
				return gson.toJson(cvs);	
			}
			List<OiBackgroundpropertyValue> bgvalues = repositoryService.getUniqueBackgroundValues(oiTypes.get(0).getId());
			
			if (codesTitle.equals("NULL")) {
				for(OiBackgroundpropertyValue cv : bgvalues){
					cvs.add(new BackgroundValue(cv,String.format("%s",cv.getBackgroundValue().intValue())));
				}
			} else {
				for(OiBackgroundpropertyValue cv : bgvalues){
					List<Codevalues> codevalues = repositoryService.getCodeValuesByCodeValueAndCodesTitle(cv.getCodeValue(),codesTitle);
					if (codevalues.size() != 1) {
						continue;
					}
					cvs.add(new BackgroundValue(cv,codevalues.get(0).getTitle()));
				}				
			}
		
			String jsonInString = gson.toJson(cvs);		
			return jsonInString;
		}
		catch(Throwable t){
			t.printStackTrace(System.err);
			//System.err.println(t);
			return "";		
		}
	}
	
	private class BackgroundValue {
		private int id;
		private String propTitle;
		private String codesTitle;
		private String codeValue;
		private Float backgroundValue;
		private String oiTitle;

		public int getId() {
			return id;
		}

		public void setId(int id) {
			this.id = id;
		}
		
		public String getCodeValue() {
			return codeValue;
		}

		public void setCodeValue(String codeValue) {
			this.codeValue = codeValue;
		}
		
		
		public String getPropTitle() {
			return propTitle;
		}

		public void getPropTitle(String val) {
			this.propTitle= val;
		}

		public String getCodesTitle() {
			return codesTitle;
		}

		public void setCodesTitle(String val) {
			this.codesTitle= val;
		}

		public Float getBackgroundValue() {
			return backgroundValue;
		}

		public void setBackgroundValue(Float backgroundValue) {
			this.backgroundValue = backgroundValue;
		}

		public void setPropTitle(String propTitle) {
			this.propTitle = propTitle;
		}


		public String getOiTitle() {
			return oiTitle;
		}

		public void setOiTitle(String oiTitle) {
			this.oiTitle = oiTitle;
		}

		BackgroundValue(OiBackgroundpropertyValue val) {
			setId(val.getId());
			setPropTitle(val.getOitypePropertyTitle());
			setCodesTitle(val.getCodeValue());
			setCodeValue(val.getCodeValue());
			setBackgroundValue(val.getBackgroundValue());
			setOiTitle(val.getOiTitle());
		}

		BackgroundValue(OiBackgroundpropertyValue val, String codestitle){
			setId(val.getId());
			// Updeep hack!!!!
			if (!val.getCodeValue().equals("NULL")) {
				setCodeValue(val.getCodeValue());
			} else {
				setCodeValue(codestitle);
			}
			setPropTitle(val.getOitypePropertyTitle());
			setCodesTitle(codestitle);
		}	

	}	
}
