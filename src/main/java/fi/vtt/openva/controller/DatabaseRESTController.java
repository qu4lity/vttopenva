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

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.stream.Collectors;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import com.google.gson.Gson;

import fi.vtt.openva.dao.PropertyEnum;
import fi.vtt.openva.domain.Codevalues;
import fi.vtt.openva.domain.Objectofinterest;
import fi.vtt.openva.domain.OiBackgroundpropertyValue;
import fi.vtt.openva.domain.OiRelation;
import fi.vtt.openva.domain.Oitype;
import fi.vtt.openva.domain.OitypeProperty;
import fi.vtt.openva.domain.Visualization;
import fi.vtt.openva.repositories.RepositoryService;


/**
 * DatabaseRESTController
 * 
 * @author Pekka Siltanen, Markus Ylikerälä
 *
 */

@RestController
@RequestMapping("/query")
public class DatabaseRESTController {
	
	private static Logger log = Logger.getLogger(VisualizationRESTController.class);
	@Autowired
	private RepositoryService repositoryService;
	
	/**
	 * Gets the object list.
	 *
	 * @param oiTypeTitle the oi type title
	 * @return the object list
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getObjectList/{oiTypeTitle}", method = RequestMethod.GET)
	public String getObjectList(@PathVariable String oiTypeTitle) throws InterruptedException{
		try{

			Oitype oitype = repositoryService.getOitype(oiTypeTitle);	
			if (oitype == null) {
				throw new InterruptedException ("No OItypes found in database");
			}

			Gson gson = new Gson();
			Objectofinterest[] arr = repositoryService.getObjectOfInterests(oitype);
			List<OI> ois = new ArrayList<OI>();
			for(Objectofinterest oi : arr){
				ois.add(new OI(oi));
			}

			String jsonInString = gson.toJson(ois);	
			return jsonInString;
		}
		catch(Throwable t){
			t.printStackTrace(System.err);
			//System.err.println(t);
			throw new InterruptedException(t.getMessage());			
		}
	}


	/**
	 * Returns a json string of ObjectOfInterests, that have no
	 * parents in object hierarchy.
	 *
	 * @return      json string
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getFirstLevelObjects", method = RequestMethod.GET)
	public String getFirstLevelObjects() throws InterruptedException{
		List<OiRelation> rels =  repositoryService.getFirstLevelRelations();
		List<OiRelation> distinctElements = rels.stream().filter(distinctByKey(p -> p.getObjectofinterestByParentOiId())).collect(Collectors.toList());
		List<OI> ois = new ArrayList<OI>();
		for(OiRelation rel : distinctElements){
			OI oic = new OI(rel.getObjectofinterestByParentOiId());
			ois.add(oic);
		}

		Gson gson = new Gson();
		String jsonInString = gson.toJson(ois);		
		return jsonInString; 
	}

	/**
	 * Returns a json string of ObjectOfInterests, taht are children of 
	 * a ObjectOfInterest whose id given as parameter.
	 *
	 * @param oiId the oi id
	 * @return      json string
	 * @throws InterruptedException the interrupted exception
	 */

	@RequestMapping(value = "/getChildrenByObjectId/{oiId}", method = RequestMethod.GET)
	//@ResponseBody	
	public String getChildrenByObjectId(@PathVariable Integer oiId) throws InterruptedException{

		List<OI> ois = new ArrayList<OI>();
		List<OiRelation> rels =  repositoryService.findByParentId(oiId);
		for(OiRelation rel : rels){
			OI oii = new OI(rel.getObjectofinterestByChildOiId());
			ois.add(oii);
		}

		Gson gson = new Gson();
		String jsonInString = gson.toJson(ois);		
		return jsonInString; 
	}

	/**
	 * Distinct by key.
	 *
	 * @param <T> the generic type
	 * @param keyExtractor the key extractor
	 * @return the predicate
	 */
	private static <T> Predicate<T> distinctByKey(Function<? super T, Object> keyExtractor) 
	{
		Map<Object, Boolean> map = new ConcurrentHashMap<>();
		return t -> map.putIfAbsent(keyExtractor.apply(t), Boolean.TRUE) == null;
	}

	/**
	 * Returns a hierarchical json string of ObjectOfInterest hierarchy.
	 *
	 * @return      json string
	 * @throws InterruptedException the interrupted exception
	 * @see         NOTE: should be used only with small hierarchies
	 */

	@RequestMapping(value = "/getObjectHierarchy", method = RequestMethod.GET)
	public String getObjectHierarchy() throws InterruptedException{
		try{

			List<OiRelation> rels =  repositoryService.getFirstLevelRelations();		
			List<OiRelation> distinctElements = rels.stream().filter(distinctByKey(p -> p.getObjectofinterestByParentOiId())).collect(Collectors.toList());
			List<OI> ois = new ArrayList<OI>();
			for(OiRelation rel : distinctElements){
				OI oi = new OI(rel.getObjectofinterestByParentOiId());
				addOiChildren(oi);
				ois.add(oi);
			}

			Gson gson = new Gson();
			String jsonInString = gson.toJson(ois);		
			return jsonInString;
		}
		catch(Throwable t){
			t.printStackTrace(System.err);
			//System.err.println(t);
			throw new InterruptedException(t.getMessage());			
		}
	}


	/**
	 * Adds the oi children.
	 *
	 * @param oi the oi
	 */
	private void addOiChildren(OI oi) {
		List<OiRelation> rels =  repositoryService.findByParentId(oi.getId());
		for(OiRelation rel : rels){
			OI oii = new OI(rel.getObjectofinterestByChildOiId());
			addOiChildren(oii);
			oi.addChild(oii);
		}
		return ;
	}

	/**
	 * Returns a json string of Variables of given property type, that are linked to 
	 * a ObjectOfInterest whose id given as parameter.
	 *
	 * @param oisId ObjectofInterestId
	 * @param propertyType property type: one of "M","B","I","C"
	 * @return      json string
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getVariablesByOiTypeTitle/{oiTypeTitle}/{propertyId}", method = RequestMethod.GET)
	public String getVariablesByOIType(@PathVariable String oiTypeTitle, @PathVariable String propertyId) throws InterruptedException{

		Oitype oiType = repositoryService.getOitype(oiTypeTitle);
		if (oiType != null) {
			//PropertyEnum propertyEnum = getPropertyEnum(propertyId);
			List<Variable> variables = new ArrayList<Variable>();		
			getProperties(propertyId, variables, oiType.getId());
			Gson gson = new Gson();
			String jsonInString = gson.toJson(variables);
			return jsonInString;
		} else {
			return null;
		}
		


	}

	@RequestMapping(value = "/getMinMaxTime", method = RequestMethod.GET)
	public String getMinMaxTime() throws InterruptedException{

		List<Object> minmax = repositoryService.getMinAndMaxTimeMeasurements();

		Gson gson = new Gson();
		String jsonInString = gson.toJson(minmax);
		return jsonInString;

	}

	/**
	 * Returns a json string of Variables of given property type, that are linked to 
	 * a ObjectOfInterest whose id given as parameter.
	 *
	 * @param oisId ObjectofInterestId
	 * @param propertyId property type: one of "M","B","I"
	 * @return      json string
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getVariables/{oisId}/{propertyType}", method = RequestMethod.GET)
	public String getVariables(@PathVariable Integer oisId, @PathVariable String propertyType) throws InterruptedException{

		Objectofinterest oi = repositoryService.findById(oisId);

		//PropertyEnum propertyEnum = getPropertyEnum(propertyType);
		List<Variable> variables = new ArrayList<Variable>();		
		getProperties(propertyType, variables, oi.getOitype().getId());
		Gson gson = new Gson();
		String jsonInString = gson.toJson(variables);
		return jsonInString;

	}

	/**
	 * Gets the properties.
	 *
	 * @param propertyEnum the property enum
	 * @param variables the variables
	 * @return the properties
	 */
//	private void getProperties(PropertyEnum propertyEnum,List<Variable> variables, Integer oiTypeId) {
	private void getProperties(String propertyEnum,List<Variable> variables, Integer oiTypeId) {
		List<OitypeProperty> oitypeProperties = repositoryService.getOIPropertyTypes();
		for(OitypeProperty oitypeProperty : oitypeProperties){
			//System.err.println(oitypeProperty.getPropertytype());
			//if(propertyEnum == oitypeProperty.getPropertytype() && oiTypeId == oitypeProperty.getOitype().getId()){
			if(propertyEnum.equalsIgnoreCase(oitypeProperty.getPropertytype())  && oiTypeId == oitypeProperty.getOitype().getId()){
				Variable variable = new Variable(oitypeProperty);
				variables.add(variable);
			}
		}
	}

	/**
	 * Gets the property enum.
	 *
	 * @param propertyId the property id
	 * @return the property enum
	 */
	private PropertyEnum getPropertyEnum(String propertyId) {
		PropertyEnum propertyEnum = PropertyEnum.I;
		switch(propertyId){
		case "I":	
		case "i":
			propertyEnum = PropertyEnum.I;
			break;
		case "M":		
		case "m":	
			propertyEnum = PropertyEnum.M;
			break;
		case "B":		
		case "b":	
			propertyEnum = PropertyEnum.B;
			break;
		case "C":		
		case "c":	
			propertyEnum = PropertyEnum.C;
			break;
		}
		return propertyEnum;
	}

	/**
	 * The Class OI.
	 *
	 * Private class for storing the ObjectOfInterest database information used in UI
	 */
	private class OI {
		public String getReportTitle() {
			return reportTitle;
		}

		public void setReportTitle(String reportTitle) {
			this.reportTitle = reportTitle;
		}

		/**
		 * Gets the oi type.
		 *
		 * @return the oi type
		 */
		public String getOiType() {
			return oiType;
		}

		/**
		 * Sets the oi type.
		 *
		 * @param oiType the new oi type
		 */
		public void setOiType(String oiType) {
			this.oiType = oiType;
		}

		/**
		 * Gets the children.
		 *
		 * @return the children
		 */
		public ArrayList<OI> getChildren() {
			return children;
		}

		/**
		 * Sets the children.
		 *
		 * @param children_ the new children
		 */
		public void setChildren(ArrayList<OI> children_) {
			for (OI oi : children_) {
				this.children.add(oi);
			}
		}

		/**
		 * Adds the child.
		 *
		 * @param oi the oi
		 */
		public void addChild(OI oi) {
			if (this.children == null) {
				this.children = new ArrayList<OI>();
			}
			this.children.add(oi);
		}

		/** The id. */
		private int id;

		/** The oi type id. */
		private int oiTypeId;

		/** The oi type. */
		private String oiType;

		/** The text. */
		private String text;

		/** The description. */
		private String description;

		/** The children. */
		private ArrayList<OI> children;

		/** The report title. */
		private String reportTitle;

		/**
		 * Instantiates a new oi.
		 *
		 * @param oi the oi
		 */
		OI(Objectofinterest oi){
			setId(oi.getId());
			setOiTypeId(oi.getOitype().getId());
			setOiTypeTitle(oi.getOitypeTitle());
			setDescription(oi.getDescription());
			setText(oi.getTitle());
			setReportTitle(oi.getReportTitle());
		}

		/**
		 * Gets the description.
		 *
		 * @return the description
		 */
		public String getDescription() {
			return description;
		}

		/**
		 * Sets the description.
		 *
		 * @param description the description to set
		 */
		public void setDescription(String description) {
			this.description = description;
		}

		/**
		 * Gets the oi type title.
		 *
		 * @return the oiTypeTitle
		 */
		public String getOiTypeTitle() {
			return oiType;
		}

		/**
		 * Sets the oi type title.
		 *
		 * @param oiTypeTitle the oiTypeTitle to set
		 */
		public void setOiTypeTitle(String oiTypeTitle) {
			this.oiType = oiTypeTitle;
		}

		/**
		 * Gets the oi type id.
		 *
		 * @return the oiTypeId
		 */
		public int getOiTypeId() {
			return oiTypeId;
		}

		/**
		 * Sets the oi type id.
		 *
		 * @param oiTypeId the oiTypeId to set
		 */
		public void setOiTypeId(int oiTypeId) {
			this.oiTypeId = oiTypeId;
		}

		/**
		 * Gets the text.
		 *
		 * @return the text
		 */
		public String getText() {
			return text;
		}

		/**
		 * Sets the text.
		 *
		 * @param text the text to set
		 */
		public void setText(String text) {
			this.text = text;
		}

		/**
		 * Gets the id.
		 *
		 * @return the id
		 */
		public int getId() {
			return id;
		}

		/**
		 * Sets the id.
		 *
		 * @param id the id to set
		 */
		public void setId(int id) {
			this.id = id;
		}


	}

	/**
	 * The Class Variable.
	 *
	 * Private class for storing the ObjectOfInterest property types database information used in UI
	 */
	private class Variable{

		private int id;
		private String text;
		private String description;
		private String timeunit;

		/**
		 * Instantiates a new variable.
		 *
		 * @param oitypeProperty the oitype property
		 */
		Variable(OitypeProperty oitypeProperty){
			setId(oitypeProperty.getId());
			setDescription(oitypeProperty.getDescription());
			setText(oitypeProperty.getReportTitle());
			setTimeunit(oitypeProperty.getTimeUnit());
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
	}

	/**
	 * Gets the visualisation candidates.
	 *
	 * @param ois the ois
	 * @param vars the vars
	 * @return the visualisation candidates
	 */
	@RequestMapping(value = "/getVisualisationCandidates/{ois}/{vars}/{applicationTitle}", method = RequestMethod.GET)
	public String getVisualisationCandidates(@PathVariable Integer[] ois, @PathVariable Integer[] vars, @PathVariable String applicationTitle){
		for(Integer oi : ois){
			log.info("oi: " + oi);
		}
		for(Integer var : vars){
			log.info("var: " + var);
		}

		try {
			List<Visualization> vizs = repositoryService.getVisualizations(ois, vars);
			List<VisualizationCandidate> result = new ArrayList<VisualizationCandidate>(); 

			Map<String, String> distinct = new TreeMap<String, String>();			

			for(Visualization viz : vizs){
				if(viz.getEngine() == null){
					continue;
				}
				
				if(distinct.get(viz.getMethod()) != null){
					// same visualization already listed
					continue;
				}
				
				if (viz.getApplicationTitle()!=null && !viz.getApplicationTitle().equals(applicationTitle)) {
					continue;
				}

				distinct.put(viz.getMethod(), viz.getMethod());
				result.add(new VisualizationCandidate(viz));
			}

			Gson gson = new Gson();
			String jsonInString = gson.toJson(result);
			return jsonInString;


		}
		catch(Throwable t){
			log.info("Bizarre");
			t.printStackTrace();
		}

		return "";
	}

	/**
	 * The Class VisualizationCandidate (contains visualization-table columns that are needed in UI).
	 */
	private class VisualizationCandidate{
		public String getEngine() {
			return engine;
		}

		public void setEngine(String engine) {
			this.engine = engine;
		}

		/** The id. */
		private int id;

		/** The text. (Obsolote, used in some historical versions)*/
		private String text;

		/** The method, should correspond with the script name that is run in the analysis engine */
		private String method;

		/** The title, short title of the method in user readable format*/
		private String title;

		/** The title, short title of the method in user readable format*/
		private String engine;

		/**
		 * Instantiates a new visualization candidate.
		 *
		 * @param viz the viz
		 */
		VisualizationCandidate(Visualization viz){
			id = viz.getId();
			text = viz.getMethod();	
			method = viz.getMethod();	
			title = viz.getTitle();	
			engine = viz.getEngine();
		}

		/**
		 * Gets the id.
		 *
		 * @return the id
		 */
		public int getId() {
			return id;
		}

		/**
		 * Sets the id.
		 *
		 * @param id the new id
		 */
		public void setId(int id) {
			this.id = id;
		}

		/**
		 * Gets the text.
		 *
		 * @return the text
		 */
		public String getText() {
			return text;
		}

		/**
		 * Sets the text.
		 *
		 * @param text the new text
		 */
		public void setText(String text) {
			this.text = text;
		}

		public String getMethod() {
			return method;
		}

		public void setMethod(String method) {
			this.method = method;
		}

		public String getTitle() {
			return title;
		}

		public void setTitle(String title) {
			this.title = title;
		}
	}	


	/**
	 * Gets the object types.
	 *
	 * @return the object types
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getObjectTypes", method = RequestMethod.GET)
	//@ResponseBody	
	public String getObjectTypes() throws InterruptedException{
		try {
			long start = System.currentTimeMillis();

			ArrayList<OiType> oits = new ArrayList<OiType>();
			Gson gson = new Gson();
			List<Oitype> oitypes = repositoryService.getOitypes();
			for(Oitype oi : oitypes){
				oits.add(new OiType(oi));
			}		
			String jsonInString = gson.toJson(oits);	
			return jsonInString;
		}
		catch(Throwable t){
			t.printStackTrace(System.err);
			//System.err.println(t);
			throw new InterruptedException(t.getMessage());			
		}
	}

	/**
	 * The Class OiType.
	 *
	 * @author ttesip
	 * Private class for storing the ObjectOfInterest type database information used in UI
	 */
	private class OiType{

		/**
		 * Gets the title.
		 *
		 * @return the title
		 */
		public String getTitle() {
			return title;
		}

		/**
		 * Sets the title.
		 *
		 * @param title the new title
		 */
		public void setTitle(String title) {
			this.title = title;
		}

		/** The id. */
		private int id;

		/** The title. */
		private String title;

		/** The report title. */
		private String reportTitle;

		/** The description. */
		private String description;

		/**
		 * Instantiates a new oi type.
		 *
		 * @param oiType the oi type
		 */
		OiType(Oitype oiType){
			setId(oiType.getId());
			setTitle(oiType.getTitle());
			setDescription(oiType.getDescription());
			setReportTitle(oiType.getReportTitle());
		}

		/**
		 * Gets the description.
		 *
		 * @return the description
		 */
		public String getDescription() {
			return description;
		}

		/**
		 * Sets the description.
		 *
		 * @param description the description to set
		 */
		public void setDescription(String description) {
			this.description = description;
		}




		/**
		 * Gets the report title.
		 *
		 * @return the report title
		 */
		public String getReportTitle() {
			return reportTitle;
		}

		/**
		 * Sets the report title.
		 *
		 * @param reportTitle the new report title
		 */
		public void setReportTitle(String reportTitle) {
			this.reportTitle = reportTitle;
		}

		/**
		 * Gets the id.
		 *
		 * @return the id
		 */
		public int getId() {
			return id;
		}

		/**
		 * Sets the id.
		 *
		 * @param id the id to set
		 */
		public void setId(int id) {
			this.id = id;
		}						
	}


	/**
	 * Gets codeValues by code title.
	 *
	 * @return the object types
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getCodeValues/{codeTitle}", method = RequestMethod.GET)
	//@ResponseBody	
	public String getObjectTypes(@PathVariable String codeTitle) throws InterruptedException{
		try {

			ArrayList<Codevalue> cvs = new ArrayList<Codevalue>();
			Gson gson = new Gson();
			List<Codevalues> codevalues = repositoryService.getCodeValues(codeTitle);
			for(Codevalues cv : codevalues){
				cvs.add(new Codevalue(cv));
			}		
			String jsonInString = gson.toJson(cvs);	
			return jsonInString;
		}
		catch(Throwable t){
			t.printStackTrace(System.err);
			//System.err.println(t);
			throw new InterruptedException(t.getMessage());			
		}
	}

	private class Codevalue {
		/** The id. */
		private int id;

		/** The title. */
		private String title;

		private String codeValue;
		private String codesTitle;	

		/**
		 * Gets the id.
		 *
		 * @return the id
		 */
		public int getId() {
			return id;
		}

		/**
		 * Sets the id.
		 *
		 * @param id the id to set
		 */
		public void setId(int id) {
			this.id = id;
		}

		/**
		 * Gets the title.
		 *
		 * @return the title
		 */
		public String getTitle() {
			return title;
		}

		/**
		 * Sets the title.
		 *
		 * @param title the new title
		 */
		public void setTitle(String title) {
			this.title = title;
		}

		/**
		 * Gets the codeValue.
		 *
		 * @return the codeValue
		 */
		public String getCodeValue() {
			return codeValue;
		}

		/**
		 * Sets the codeValue.
		 *
		 * @param val the codeValue to set
		 */
		public void setCodeValue(String val) {
			this.codeValue= val;
		}

		/**
		 * Gets the codeValue.
		 *
		 * @return the codeValue
		 */
		public String getCodesTitle() {
			return codesTitle;
		}

		/**
		 * Sets the codeValue.
		 *
		 * @param val the codeValue to set
		 */
		public void setCodesTitle(String val) {
			this.codesTitle= val;
		}

		/**
		 * Instantiates a new oi type.
		 *
		 * @param oiType the oi type
		 */
		Codevalue(Codevalues codeval){
			setId(codeval.getId());
			setTitle(codeval.getTitle());
			setCodeValue(codeval.getCodeValue());
			setCodesTitle(codeval.getCodesTitle());
		}	

	}	

	
	
	// This is a hack to get Updeep demo working. Must be thougth again how these are modelled in Updeep!!!!!
	/**
	 * Gets unique backgroundvalues by id.
	 *
	 * @return the object types
	 * @throws InterruptedException the interrupted exception
	 */
	@RequestMapping(value = "/getUniqueBackgroundValues/{typePropTitle}", method = RequestMethod.GET)
	//@ResponseBody	
	public String getUniqueBackgroundValues(@PathVariable String typePropTitle) throws InterruptedException{
		try {

			ArrayList<BackgroundValue> cvs = new ArrayList<BackgroundValue>();
			Gson gson = new Gson();
			List<OiBackgroundpropertyValue> univalues = repositoryService.getUniqueCodeValues(typePropTitle);	
			if (univalues.size() == 0 || univalues.get(0).getCodeValue().equals("NULL")) {
				List<OiBackgroundpropertyValue> bgvalues = repositoryService.getUniqueBackgroundValues(typePropTitle);
				for(OiBackgroundpropertyValue cv : bgvalues){
					cvs.add(new BackgroundValue(cv,String.format("%s",cv.getValue().intValue())));
				}
			} else {
				for(OiBackgroundpropertyValue cv : univalues){
					List<Codevalues> codevalues = repositoryService.getCodeValuesByCodeValueAndCodesTitle(cv.getCodeValue(),cv.getOitypePropertyTitle());
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
			throw new InterruptedException(t.getMessage());			
		}
	}
	
	private class BackgroundValue {
		private int id;
		private String propTitle;
		private String codesTitle;
		private String codeValue;

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

		BackgroundValue(OiBackgroundpropertyValue val, String codestitle){
			setId(val.getId());
			// Updeep hack!!!!
			if (!val.getCodeValue().equals("NULL")) {
				setCodeValue(val.getCodeValue());
			} else {
				setCodeValue(codestitle);
			}
			getPropTitle(val.getOitypePropertyTitle());
			setCodesTitle(codestitle);
		}	

	}	
}

