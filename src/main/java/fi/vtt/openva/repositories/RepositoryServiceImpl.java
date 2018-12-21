package fi.vtt.openva.repositories;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import fi.vtt.openva.dao.PropertyEnum;
import fi.vtt.openva.dao.VisOisEnum;
import fi.vtt.openva.domain.Codevalues;
import fi.vtt.openva.domain.Objectofinterest;
import fi.vtt.openva.domain.OiBackgroundpropertyValue;
import fi.vtt.openva.domain.OiRelation;
import fi.vtt.openva.domain.Oitype;
import fi.vtt.openva.domain.OitypeProperty;
import fi.vtt.openva.domain.Visualization;

//OpenVA - Open software platform for visual analytics
//
//Copyright (c) 2018, VTT Technical Research Centre of Finland Ltd
//All rights reserved.
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//
// 1) Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2) Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3) Neither the name of the VTT Technical Research Centre of Finland nor the
//    names of its contributors may be used to endorse or promote products
//    derived from this software without specific prior written permission.
//
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


/**
 * RepositoryServiceImpl.
 *
 * @author Markus Ylikerälä, Pekka Siltanen
 */
@Service
public class RepositoryServiceImpl implements RepositoryService {
	
	/** The log. */
	private static Logger log = Logger.getLogger(RepositoryServiceImpl.class);

	/** The oi measuredproperty repository. */
	@Autowired
	private OiMeasuredpropertyRepository oiMeasuredpropertyRepository;
	
	/** The oitype repository. */
	@Autowired
	private OitypeRepository oitypeRepository;
	
	/** The oitype property repository. */
	@Autowired
	private OitypePropertyRepository oitypePropertyRepository;		
	
	/** The visualization repository. */
	@Autowired
	private VisualizationRepository visualizationRepository;
	
	/** The relation repository. */
	@Autowired
	private OiRelationRepository relationRepository;
	
	/** The objectOfInterest repository. */
	@Autowired
	private ObjectofinterestRepository objectOfInterestRepository;

	/** The CodevaluesRepository repository. */
	@Autowired
	private CodevaluesRepository codevaluesRepository;
	
	/** The CodevaluesRepository repository. */
	@Autowired
	private OiBackgroundpropertyValueRepository backgroundvaluesRepository;
	
	/**
	 * Instantiates a new repository service impl.
	 */
	public RepositoryServiceImpl() {
		log.info("\nvisualizationRepository.RepositoryServiceImpl Constructor");
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.repositories.RepositoryService#getOitype(java.lang.String)
	 */
	public Oitype getOitype(String name){
		log.info("\nRepositoryServiceImpl.getOitype Constructor");
		return oitypeRepository.findByTitle(name);

	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.repositories.RepositoryService#getObjectOfInterests(fi.vtt.openva.domain.Oitype)
	 */
	public Objectofinterest[] getObjectOfInterests(Oitype type) {
		Set<Objectofinterest> result = type.getObjectofinterests(); 	
		
		log.info("\nRepositoryServiceImpl.getObjectOfInterests BEGIN");
		return result.toArray(new Objectofinterest[result.size()]); 
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.repositories.RepositoryService#getOIPropertyTypes(int, fi.vtt.openva.dao.PropertyEnum)
	 */
	@Override
	public List<OitypeProperty> getOIPropertyTypes(int oitypeId, PropertyEnum propertyEnum) {
		log.info("\nRepositoryServiceImpl.getOIPropertyTypes BEGIN");
		return oitypePropertyRepository.findByOitypeId(oitypeId);

	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.repositories.RepositoryService#getOIPropertyTypes()
	 */
	@Override
	public List<OitypeProperty> getOIPropertyTypes() {
		log.info("\nRepositoryServiceImpl.getOIPropertyTypes BEGIN");
		return oitypePropertyRepository.findAll();
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.repositories.RepositoryService#getVisualizations(java.lang.String[], java.lang.String[])
	 */
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
				if (visualization.getOistype().equals("ONE_PLUS_RELATION")) {
					iter.remove();
				}			
			}
		}


		List<OitypeProperty> oitypeProperties = oitypePropertyRepository.findByIdIn(Arrays.asList(vars));
		//System.err.println("FOOViOitypeProperties:>" + oitypeProperties + "<");

		List<Visualization> result = new ArrayList<Visualization>();
		List<Visualization> result2 = new ArrayList<Visualization>();
		for(Visualization visualization : visualizations){
			System.err.println("Visualization ? >" + visualization + "<");
			checkDatatype(oitypeProperties, result, visualization);
		}

		return result;			
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
		
		// background property visualizations do no work yet, so it is a hack to disapprove all background property visualizations
		for(OitypeProperty oitypeProperty : oitypeProperties){			
			if(oitypeProperty.getPropertytype().equals("b") == true){
				if (oitypeProperties.size() ==1 && visualization.getMethod().equals("BackgroundValue")) {
					result.add(visualization);
					return;
				} else {
					return;
				}
			}
		}
		
		
		if(visualization.getVariabletype() == null){
			result.add(visualization);
			return;
		}
		if (oitypeProperties.size() > 1 && oitypeProperties.stream().anyMatch(o -> o.getPropertytype().equals(PropertyEnum.C))) {
			// combining of calculated and stored variables not supported yet
			return;
		}
		
		
		if (!oitypeProperties.get(0).getPropertytype().equalsIgnoreCase("c") && !oitypeProperties.get(0).getPropertytype().equalsIgnoreCase("ci") &&!visualization.getMethod().equals("CalculatedValues")) {
			switch(visualization.getVariabletype()){			
				case "TS":
				case "NOTS":
					approve = approveTsOrNotsVisualization(oitypeProperties, visualization);
					break;
				case "TS_AND_NOTS":
					approve = approveTsAndNotsVisualization(oitypeProperties, visualization);
					break;
				default:
					approve = true;
					break;			
			}
		}
		 else if (!oitypeProperties.get(0).getPropertytype().equalsIgnoreCase("c") && !oitypeProperties.get(0).getPropertytype().equalsIgnoreCase("ci")) { 
			approve = false;
		}
		else if (visualization.getMethod().equals("CalculatedValues")) {
			approve = true;
		} 
		if(approve){			
			result.add(visualization);
		}
	}
	
	/**
	 * Approve ts or nots visulization.
	 *
	 * @param oitypeProperties the oitype properties
	 * @param visualization the visualization
	 * @return true, if successful
	 */
	private boolean approveTsOrNotsVisualization(List<OitypeProperty> oitypeProperties, Visualization visualization) {	
		for(OitypeProperty oitypeProperty : oitypeProperties){			
			if(oitypeProperty.getVariabletype().equalsIgnoreCase(visualization.getVariabletype()) == false){
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
		for(OitypeProperty oitypeProperty : oitypeProperties){			
			tst.put(oitypeProperty.getVariabletype(), oitypeProperty.getVariabletype());
		}
		if(tst.keySet().size() == 2){
			return true;
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
		switch(visualization.getDatatype()){			
			case "QUANT":
			case "NOM":
				approve = approveQuantOrNomVisualization(oitypeProperties, visualization);
				break;
			case "QUANT_INTEGER":
				approve = approveQuantIntVisualization(oitypeProperties, visualization);
				break;
			default:
				break;			
		}
		if(approve){
			checkPropertytype(oitypeProperties, result, visualization);
		}
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
		


	

	/* (non-Javadoc)
	 * @see fi.vtt.openva.repositories.RepositoryService#getFrequencies(java.lang.Integer)
	 */
	@Override
	public String getFrequencies(Integer varids) {
		// TODO Auto-generated method stub

		//		public String getFrequencies(Integer varId) {
		//		try {
		//			JsonArray jsonArray = new JsonArray();
		//			
		//			Query query = entityManager.createQuery("select x.measurementValue, count(x) from " + OiMeasuredpropertyValue.class.getSimpleName() + " x where x.oiMeasuredproperty.id in (select id from " + OiMeasuredproperty.class.getSimpleName() +" y where y.oitypeProperty.id= :varId) group by x.measurementValue order by x.measurementValue");
		//			query.setParameter("varId", varId);
		//			List<Object[]>  result = query.getResultList();	
		//			if (result != null) {
		//				for (Object[] a: result){
		//					JsonObject jObj = new JsonObject();
		//					Float val = (Float) a[0];
		//					Long freq = (Long) a[1];
		//					jObj.add("val", new JsonPrimitive(val));
		//					jObj.add("freq", new JsonPrimitive(freq));
		//					jsonArray.add(jObj);
		//				}
		//			}
		//			return result != null && result.isEmpty() == false ? jsonArray.toString() : null;  	
		//		}
		//		catch(Exception e) {
		//			e.printStackTrace();
		//			return null;
		//		}
		//	}

		return null;
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.repositories.RepositoryService#getRawData(java.lang.String, java.lang.String, java.lang.String, java.lang.String)
	 */
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
	public List<Object> getMinAndMaxTimeMeasurements() {
		return oiMeasuredpropertyRepository.findMinAndMaxTime();
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
	
	/**
	 * String of ints 2 arr of ints.
	 *
	 * @param varids the varids
	 * @return the array list
	 */
	private ArrayList<Integer> stringOfInts2ArrOfInts(String[] varids) {
		
		ArrayList<Integer> varidInts = new ArrayList<Integer>();
		for(String s : varids){
			varidInts.add(Integer.valueOf(s));
		}
		return varidInts;
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.repositories.RepositoryService#getVisualizationEngine(java.lang.String)
	 */
	@Override
	public String getVisualizationEngine(String method) throws Exception {
		List<Visualization> vizs =  visualizationRepository.findByMethod(method);
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

	/* (non-Javadoc)
	 * @see fi.vtt.openva.repositories.RepositoryService#getFirstLevelRelations()
	 */
	@Override
	public List<OiRelation> getFirstLevelRelations() {
		return relationRepository.findFirstLevel();
	}
	
	/* (non-Javadoc)
	 * @see fi.vtt.openva.repositories.RepositoryService#findByParentId(int)
	 */
	@Override
	public List<OiRelation> findByParentId(int id) {
		long start = System.currentTimeMillis();
		List<OiRelation> rels = relationRepository.findByParentId(id);
		long end = System.currentTimeMillis();
		//System.err.println(LocalDateTime.now() + " Elapsed: " + (end - start) + "ms #" + (end - start)/1000 + "s\n");
		
		
		return rels;
	}

	/* (non-Javadoc)
	 * @see fi.vtt.openva.repositories.RepositoryService#getOitypes()
	 */
	@Override
	public List<Oitype> getOitypes() {
		return oitypeRepository.findAll();

	}

	@Override
	public Objectofinterest findById(Integer id) {
		return objectOfInterestRepository.findById(id);
	}

	@Override
	public List<Codevalues> getCodeValues(String codeTitle) {
		
		return codevaluesRepository.findByCodesTitle(codeTitle);
	}

	@Override
	public List<OiBackgroundpropertyValue> getUniqueCodeValues(String typePropTitle) {
		return backgroundvaluesRepository.findUniqueCodeValues(typePropTitle);
	}

	@Override
	public List<Codevalues> getCodeValuesByCodeValueAndCodesTitle(String codeValue, String codesTitle) {
		 return codevaluesRepository.findByCodeValueAndCodesTitle(codeValue,codesTitle);
	}

	@Override
	public List<OiBackgroundpropertyValue> getUniqueBackgroundValues(String typePropTitle) {
		return backgroundvaluesRepository.findUniqueBackgroundValues(typePropTitle);
	}

}
