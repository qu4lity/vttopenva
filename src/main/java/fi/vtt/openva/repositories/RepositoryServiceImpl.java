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
package fi.vtt.openva.repositories;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import fi.vtt.openva.domain.Application;
import fi.vtt.openva.domain.Codevalues;
import fi.vtt.openva.domain.Objectofinterest;
import fi.vtt.openva.domain.OiBackgroundpropertyValue;
import fi.vtt.openva.domain.OiRelation;
import fi.vtt.openva.domain.Oitype;
import fi.vtt.openva.domain.OitypeProperty;
import fi.vtt.openva.domain.PropertyGroup;
import fi.vtt.openva.domain.Visualization;


/**
 * RepositoryServiceImpl.
 *
 * @author Markus Ylikerälä, Pekka Siltanen
 */
@Service
public class RepositoryServiceImpl implements RepositoryService {
	
	private static Logger log = Logger.getLogger(RepositoryServiceImpl.class);

	@Autowired
	private ApplicationRepository applicationRepository;
	
	@Autowired
	private OiMeasuredpropertyRepository oiMeasuredpropertyRepository;
	
	@Autowired
	private OitypeRepository oitypeRepository;
	
	@Autowired
	private OitypePropertyRepository oitypePropertyRepository;		
	
	@Autowired
	private VisualizationRepository visualizationRepository;
	
	@Autowired
	private OiRelationRepository relationRepository;
	
	@Autowired
	private ObjectofinterestRepository objectOfInterestRepository;

	@Autowired
	private CodevaluesRepository codevaluesRepository;
	
	@Autowired
	private PropertyGroupRepository propertyGroupRepository;
	
	@Autowired
	private OiBackgroundpropertyValueRepository backgroundvaluesRepository;

	@Autowired
	private StoredSelectionsRepository storedSelectionsRepository;
	
	@Autowired
	private StoredObjectofinterestRepository storedObjectofinterestRepository;
	
	@Autowired
	private StoredOitypePropertyRepository storedOitypePropertyRepository;
	
	@Autowired
	private StoredFilterRepository storedFilterRepository;
	
	public RepositoryServiceImpl() {
		log.info("\nvisualizationRepository.RepositoryServiceImpl Constructor");
	}
	
	public Application getApplication(String title){
		return applicationRepository.findByTitle(title);
	}


	public Oitype getOitype(String name){
		return oitypeRepository.findByTitle(name);
	}

	public Objectofinterest[] getObjectOfInterests(Oitype type) {
		Set<Objectofinterest> result = type.getObjectofinterests(); 	
		return result.toArray(new Objectofinterest[result.size()]); 
	}

	@Override
	public List<OitypeProperty> getOIPropertyTypes(int oitypeId) {
		return oitypePropertyRepository.findByOitypeId(oitypeId);

	}

	@Override
	public Optional<OitypeProperty> getOIPropertyTypeById(int id) {
		return oitypePropertyRepository.findById(id);

	}
	
	@Override
	public List<OitypeProperty> getOIPropertyTypes() {
		return oitypePropertyRepository.findAll();
	}

	@Override
	public List<Visualization> getVisualizations(Integer[] ois, Integer[] vars, String[] filters) {

		boolean relation = false;		
		boolean multitype = false;
		List<Visualization> result = new ArrayList<Visualization>();
		if (ois[0] == 0 && vars[0] == 0 || vars[0] == -1) {
			return visualizationRepository.findAllByOrderByTitleAsc();
		}
			
		// first object id must be parent if the object ids are in hierarchy
		List<OiRelation> rels =  findByParentId(ois[0]);
		if (rels != null) {
			// next check if at least one of the children is selected
			for(OiRelation rel : rels){
				if(Arrays.asList(ois).contains(rel.getObjectofinterestByChildOiId().getId())) {
					relation = true;
					break;
				}
			}
		}

		int oismin = ((ois[0]==-1)) ? 0:ois.length;
		int varsmin = vars.length;
		List<Visualization> visualizations;
		if(filters.length > 0) {
			visualizations = visualizationRepository.findByPropertyMinByOrderByMethodAsc(varsmin);
		} else {
			visualizations = visualizationRepository.findByOisminAndPropertyMinByOrderByMethodAsc(oismin, varsmin);
		}
		List<OitypeProperty> oitypeProperties = oitypePropertyRepository.findByIdIn(Arrays.asList(vars));
		String oitypetitle	= oitypeProperties.get(0).getOitypeTitle();	
		
		for(OitypeProperty proptype : oitypeProperties){
			if (!proptype.getOitypeTitle().equals(oitypetitle)) {
				multitype = true;
			}
		}


				
		if (relation) {
			// remove those that do nott have ONE_PLUS_RELATION in oisType
			Iterator<Visualization> iter = visualizations.iterator();
			while (iter.hasNext()) {
				Visualization visualization = iter.next();
				if (visualization.getOitypecount().equalsIgnoreCase("ONE_PLUS_RELATION")) {
					iter.remove();
				}
			}
		}

		Iterator<Visualization> iter = visualizations.iterator();
		while (iter.hasNext()) {
			Visualization visualization = iter.next();
			if (visualization.getOitypecount().equalsIgnoreCase("ONE")) {
				if (multitype) {
					iter.remove(); // remove because all ois should be of same type
				} else if (!oitypetitle.equals(visualization.getOitypetitle())) {
					iter.remove(); // remove because all oi is of different type than visualization requires
				}
			}
			if (visualization.getOitypeProperty() != null) {
				if (!checkOiTypePropertyValue(visualization,filters)) {
					iter.remove(); // remove because all oitypepropertyvalue not found in filters
				}
			}
		}
		// TODO: add test for oitype titles with oitypecount different than one. Question: how do we describe several visualizations of different oitype? List of oitypetitles in visualizationtable? 
		

		for(Visualization visualization : visualizations){
			checkDatatype(oitypeProperties, result, visualization);
		}
		return result;			
	}

	private boolean checkOiTypePropertyValue(Visualization visualization, String[] filters) {
		String oityprop =  visualization.getOitypeProperty();
		String oitypropval =  visualization.getOitypePropertyValue();
		

		
		for (int i= 0; i< filters.length; i++) {
			String[] parts = filters[i].split("=");
			if (parts.length != 2) {
				return false;
			}
			String prop = parts[0]; 
			String val = parts[1];
			if (prop.equals(oityprop)) {
				List<Codevalues> vals = codevaluesRepository.findByCodeValueAndCodesTitle(val, prop);
				if (vals.size() != 1) {
					return false;
				}
				String codevalue = vals.get(0).getTitle();
				if (oityprop.equals(prop) && oitypropval.equals(codevalue)) {
					return true;
				}
			}
		}
		return false;
	}
	
	


	/**
	 * Check datatype.
	 *
	 * @param oitypeProperties the oitype properties
	 * @param result the result
	 * @param visualization the visualization
	 */
	private void checkDatatype(List<OitypeProperty> oitypeProperties, List<Visualization> result,
			Visualization visualization) {
		boolean approve = false;
		if (visualization.getDatatype() == null) {
			approve = true;
		} else {
			switch(visualization.getDatatype()){	
			case "QUANT_INTEGER":
			case "quant_integer":				
				approve = approveDataQuantType(oitypeProperties,"quant","integer");
				break;
			case "nom_quant":	
			case "NOM_QUANT":
				approve = approveDataType(oitypeProperties, "nom","quant");
			default:
				approve = approveDataType(oitypeProperties, visualization);
				
				break;		
		}
		}
		if(approve){
			approve = approveQuantType(oitypeProperties, visualization);
		}
		if(approve){
			checkPropertytype(oitypeProperties, result, visualization);
		}
		
		
	}
	
	


	/**
	 * Check propertytype.
	 *
	 * @param oitypeProperties the oitype properties
	 * @param result the result
	 * @param visualization the visualization
	 */
	private void checkPropertytype(List<OitypeProperty> oitypeProperties, List<Visualization> result,
			Visualization visualization) {
		boolean approve = false;
		
		if (oitypeProperties.size() > 1 && oitypeProperties.stream().anyMatch(o -> o.getPropertytype().equals("C"))) {
			// combining of calculated and stored variables not supported yet
			return;
		}
		if(visualization.getPropertytype() == null){
			result.add(visualization);
			System.err.println("visualization.getPropertytype() == null thus accept: " + visualization);
			return;
		}
		
		if (!oitypeProperties.get(0).getPropertytype().equalsIgnoreCase("C") && !oitypeProperties.get(0).getPropertytype().equalsIgnoreCase("CI") && !visualization.getMethod().equals("CalculatedValues")) {
			// this check only for measurements, indicators and background data
			switch(visualization.getPropertytype()){			
				case "TS":
				case "ts":
				case "NOTS":
				case "nots":					
					approve = approveTsOrNotsVisualization(oitypeProperties, visualization);
					break;
				case "TS_AND_NOTS":
				case "ts_and_nots":					
					approve = approveTsAndNotsVisualization(oitypeProperties, visualization);
					break;
				default:
					approve = true;
					break;			
			}
		} else if(visualization.getMethod().equals("CalculatedValues") && (oitypeProperties.get(0).getPropertytype().equalsIgnoreCase("C") || oitypeProperties.get(0).getPropertytype().equalsIgnoreCase("CI"))) {
			approve = true;
		} 
		for(OitypeProperty oitypeProperty : oitypeProperties){			
			if(oitypeProperty.getPropertytype().equalsIgnoreCase(visualization.getPropertytype())){
				approve = true;
				break;
			}
		}

		// approve DailyCount only for timeseries
		if(visualization.getMethod().equals("DailyCount") && (oitypeProperties.get(0).getPropertytype().equalsIgnoreCase("C") || oitypeProperties.get(0).getPropertytype().equalsIgnoreCase("CI"))) {
			approve = false;
		} else if(visualization.getMethod().equals("DailyCount")) {
			approve = true;
		}
		if(approve){					
			result.add(visualization);
		}
	}
	
	@Override
	public List<Visualization> getVisualizations(Integer[] ois, Integer[] vars) {

		boolean relation = false;
		
		if (ois[0] == 0 && vars[0] == 0) {
			return visualizationRepository.findAllByOrderByTitleAsc();
		}
		
		// first object id must be parent if the object ids are in hierarchy
		List<OiRelation> rels =  findByParentId(ois[0]);
		if (rels != null) {
			// next check if at least one of the children is selected
			for(OiRelation rel : rels){
				if(Arrays.asList(ois).contains(rel.getObjectofinterestByChildOiId().getId())) {
					relation = true;
					break;
				}
			}
		}


		List<Visualization> visualizations = visualizationRepository.findByOisLenAndPropertyLenByOrderByMethodAsc(ois.length, vars.length);	

		if (relation) {
			// remove those that dot have ONE_PLUS_RELATION in oisType
			Iterator<Visualization> iter = visualizations.iterator();
			while (iter.hasNext()) {
				Visualization visualization = iter.next();
				if (visualization.getOitypecount().equalsIgnoreCase("ONE_PLUS_RELATION")) {
					iter.remove();
				}			
			}
		}


		List<OitypeProperty> oitypeProperties = oitypePropertyRepository.findByIdIn(Arrays.asList(vars));
		//System.err.println("FOOViOitypeProperties:>" + oitypeProperties + "<");

		List<Visualization> result = new ArrayList<Visualization>();

		for(Visualization visualization : visualizations){
	
			checkDatatype(oitypeProperties, result, visualization);
		}

		return result;			
	}

	
	/**
	 * Approve ts or nots visulization.
	 *
	 * @param oitypeProperties the oitype properties
	 * @param visualization the visualization
	 * @return true, if successful
	 */
	private boolean approveTsOrNotsVisualization(List<OitypeProperty> oitypeProperties, Visualization visualization) {	
		if(visualization.getPropertytype()== null){
			System.err.println("visualization.getVariabletype() == null thus accept: " + visualization);
			return true;
		}
		
		for(OitypeProperty oitypeProperty : oitypeProperties){			
			if(oitypeProperty.getVariabletype().equalsIgnoreCase(visualization.getPropertytype()) == false){
				return false;
			}
		}
		return true;		
	}
	
	/**
	 * Approve ts and nots visualization.
	 *
	 * @param oitypeProperties the oitype properties
	 * @param visualization the visualization
	 * @return true, if successful
	 */
	private boolean approveTsAndNotsVisualization(List<OitypeProperty> oitypeProperties, Visualization visualization) {
		Map<String, String> tst = new HashMap<String, String>();
		
		if(visualization.getPropertytype() == null){
			System.err.println("visualization.getVariabletype() == null thus accept: " + visualization);
			return true;
		}
		
		for(OitypeProperty oitypeProperty : oitypeProperties){			
			tst.put(oitypeProperty.getVariabletype(), oitypeProperty.getVariabletype());
		}
		if(tst.keySet().size() == 2){
			return true;
		}
		return false;		
	}

	private boolean approveQuantType(List<OitypeProperty> oitypeProperties, Visualization visualization) {
		if(visualization.getQuanttype() == null) {
			return true;
		}
		for(OitypeProperty oitypeProperty : oitypeProperties){
			if(!oitypeProperty.getQuanttype().equalsIgnoreCase(visualization.getQuanttype())){
				return false;
			}
		}
		return true;
	}


	/**
	 * Approve quant or nom visualization. Approve if all OitypeProperties have same datatype as Visualization
	 *
	 * @param oitypeProperties the oitype properties
	 * @param visualization the visualization
	 * @return true, if successful
	 */
	private boolean approveDataType(List<OitypeProperty> oitypeProperties, Visualization visualization) {
		for(OitypeProperty oitypeProperty : oitypeProperties){
			if(!oitypeProperty.getDatatype().equalsIgnoreCase(visualization.getDatatype())){
				return false;
			}
		}
		return true;
	}
	
	private boolean approveDataType(List<OitypeProperty> oitypeProperties, String datatype1, String datatype2) {
		for(OitypeProperty oitypeProperty : oitypeProperties){
			if(!(oitypeProperty.getDatatype().equalsIgnoreCase(datatype1) || oitypeProperty.getDatatype().equalsIgnoreCase(datatype2))){
				return false;
			}
		}
		return true;
	}
	
	/**
	 * Approve quant or nom visualization.
	 *
	 * @param oitypeProperties the oitype properties
	 * @param visualization the visualization
	 * @return true, if successful
	 */
	private boolean approveQuantOrNomVisualization(List<OitypeProperty> oitypeProperties, Visualization visualization) {
		for(OitypeProperty oitypeProperty : oitypeProperties){
			if(oitypeProperty.getDatatype().equalsIgnoreCase(visualization.getDatatype()) == false){
				return false;
			}
		}
		return true;
	}
	
	/**
	 * Approve quant int combination. Approve if propertytype of all OitypeProperties are of type QUANT and all datatypes of type INTEGER
	 *
	 * @param oitypeProperties the oitype properties
	 * @return true, if successful
	 */
	private boolean approveDataQuantType(List<OitypeProperty> oitypeProperties, String datatype, String quanttype ) {

		for(OitypeProperty oitypeProperty : oitypeProperties){
			if(oitypeProperty.getDatatype().equalsIgnoreCase(datatype) == false || oitypeProperty.getQuanttype().equalsIgnoreCase(quanttype) ==  false){
				return false;
			}
		}
		return true;
	}
		
	
	/**
	 * Approve quant int visualization.
	 *
	 * @param oitypeProperties the oitype properties
	 * @param visualization the visualization
	 * @return true, if successful
	 */
	private boolean approveQuantIntVisualization(List<OitypeProperty> oitypeProperties, Visualization visualization) {
		for(OitypeProperty oitypeProperty : oitypeProperties){
			if(oitypeProperty.getDatatype().equalsIgnoreCase("QUANT") == false || oitypeProperty.getQuanttype().equalsIgnoreCase("integer") ==  false){
				return false;
			}
		}
		return true;
	}


	@Override
	public List<Object> getRawData(String varids, String oiids, String startdate, String enddate) {		
		ArrayList<Integer> varidInts = stringOfInts2ArrOfInts(varids);
		ArrayList<Integer> oidInts = stringOfInts2ArrOfInts(oiids);	

		DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
		LocalDateTime starttime = LocalDateTime.parse(startdate, formatter);
		LocalDateTime endtime = LocalDateTime.parse(enddate, formatter);

		return oiMeasuredpropertyRepository.findFirst10ByVarsAndOisAndStartDateAndEndDate(varidInts, oidInts, starttime, endtime,new PageRequest(0,10));
	}
	
	@Override
	public List<String> getMinAndMaxTimeMeasurements(String applicationTitle) {
		Application app = applicationRepository.findByTitle(applicationTitle);
		List<String> res = new ArrayList<String>();
		res.add(app.getMinTime().toString());
		res.add(app.getMaxTime().toString());	
		return res;
	}

	@Override
	public List<Object> getTop10() {
		return oiMeasuredpropertyRepository.findFirst10ByOrderByTimeCreated();
	}

	
	/**
	 * String of ints 2 arr of ints.
	 *
	 * @param varids the varids
	 * @return the array list
	 */
	private ArrayList<Integer> stringOfInts2ArrOfInts(String varids) {
		List<String> varidlist = Arrays.asList(varids.split("\\s*,\\s*"));
		ArrayList<Integer> varidInts = new ArrayList<Integer>();
		for(String s : varidlist){
			varidInts.add(Integer.valueOf(s));
		}
		return varidInts;
	}
	
	@Override
	public String getVisualizationEngine(String method) throws Exception {
		List<Visualization> vizs =  visualizationRepository.findByMethod(method);
		if (vizs.size() == 0) {
			throw new Exception("No visualization method found");
		}
		if (vizs.size() == 1) {
			return vizs.get(0).getEngine();
		} else {
			String engine = vizs.get(0).getEngine();
			for (Visualization viz: vizs) {
				if (!engine.equals(viz.getEngine())) {
					throw new Exception("Different engines for same method");
				}
			}
			return engine;
		}
	}

	@Override
	public List<OiRelation> getFirstLevelRelations() {
		return relationRepository.findFirstLevel();
	}
	
	@Override
	public List<OiRelation> findByParentId(int id) {
		long start = System.currentTimeMillis();
		List<OiRelation> rels = relationRepository.findByParentId(id);
		long end = System.currentTimeMillis();
		//System.err.println(LocalDateTime.now() + " Elapsed: " + (end - start) + "ms #" + (end - start)/1000 + "s\n");
		
		
		return rels;
	}

	@Override
	public List<Oitype> getOitypes() {
		return oitypeRepository.findAll();

	}

	@Override
	public Optional<Objectofinterest> findById(Integer id) {
		return objectOfInterestRepository.findById(id);
	}
	
	@Override
	public List<Objectofinterest> findAll() {
		return objectOfInterestRepository.findAll();
	}
	

	@Override
	public List<Codevalues> getCodeValues(String codeTitle) {
		
		return codevaluesRepository.findByCodesTitle(codeTitle);
	}

	@Override
	public List<OiBackgroundpropertyValue> getUniqueCodeValues(String typePropTitle) {
		return backgroundvaluesRepository.findUniqueCodeValues(typePropTitle);
	}
	
//	@Override
//	public List<OiBackgroundpropertyValue> getBackgroundValuesByOiTypePropertyAndCodeValues1(OitypeProperty oitp,List<String> codevalues) {
//		return backgroundvaluesRepository.findByOitypePropertyAndCodeValueIn(oitp,codevalues);
//	}
	

	@Override
	public List<Codevalues> getCodeValuesByCodeValueAndCodesTitle(String codeValue, String codesTitle) {
		 return codevaluesRepository.findByCodeValueAndCodesTitle(codeValue,codesTitle);
	}



	@Override
	public List<OiBackgroundpropertyValue> getUniqueBackgroundValues(int id) {
		return backgroundvaluesRepository.findUniqueBackgroundValues(id);
	}

	@Override
	public List<PropertyGroup> getPropertyGroups() {
		return  propertyGroupRepository.findAll();
	}

	@Override
	public List<OitypeProperty> getOIPropertyTypesByGroup(Integer groupId) {
		return oitypePropertyRepository.findByPropertyGroup(groupId);
	}
	
	@Override
	public List<OitypeProperty> getOIPropertyTypesByTitle(String title) {
		return oitypePropertyRepository.findByTitle(title);
	}


	@Override
	public List<OitypeProperty> getFilteredCodedOiTypeProperties(List<String> titles) {
		return oitypePropertyRepository.findByTitleInAndCodesIdIsNotNull(titles);
	}

	@Override
	public List<OitypeProperty> getFilteredNonCodedOiTypeProperties(List<String> titles) {
		return oitypePropertyRepository.findByTitleInAndCodesIdIsNull(titles);
	}

	@Override
	public List<OiBackgroundpropertyValue> getBackgroundValuesByOiTypeProperty(OitypeProperty oitp) {
		return backgroundvaluesRepository.findByOitypeProperty(oitp);
	}

	@Override
	public List<OiBackgroundpropertyValue> getBackgroundValuesByOiTypePropertyAndCodeValues(OitypeProperty oitp,
			List<String> codevalues) {
		return backgroundvaluesRepository.findByOitypePropertyAndCodeValueIn(oitp,codevalues);
	}

	@Override
	public List<OiBackgroundpropertyValue> getBackgroundValuesOiTypePropertyAndBackgroundValues(OitypeProperty oitp,
			List<Float> values) {
		return backgroundvaluesRepository.findByOitypePropertyAndBackgroundValueIn(oitp,values);
	}




}
