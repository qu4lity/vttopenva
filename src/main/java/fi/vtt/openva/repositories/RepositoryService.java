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

import java.util.List;

import org.springframework.transaction.annotation.Transactional;

import fi.vtt.openva.dao.PropertyEnum;
import fi.vtt.openva.domain.Codevalues;
import fi.vtt.openva.domain.Objectofinterest;
import fi.vtt.openva.domain.OiBackgroundpropertyValue;
import fi.vtt.openva.domain.OiRelation;
import fi.vtt.openva.domain.Oitype;
import fi.vtt.openva.domain.OitypeProperty;
import fi.vtt.openva.domain.Visualization;

/**
 * RepositoryService
 * 
 * @author Markus Ylikerälä
 *
 */

// TODO: Auto-generated Javadoc
/**
 * The Interface RepositoryService.
 *
 * @author Markus Ylikerälä
 */
@Transactional(readOnly = true, timeout=120)
public interface RepositoryService {

	/**
	 * Gets the oitype.
	 *
	 * @param string the title of the Oitype
	 * @return the oitype
	 */
	Oitype getOitype(String string);
	
	/**
	 * Gets the oitypes.
	 *
	 * @return the oitypes
	 */
	List<Oitype> getOitypes();

	/**
	 * Gets the object of interests.
	 *
	 * @param oitype the oitype
	 * @return the object of interests
	 */
	Objectofinterest[] getObjectOfInterests(Oitype oitype);

	/**
	 * Gets the object of interests.
	 *
	 * @param oitype the oitype
	 * @return the object of interests
	 */
	Objectofinterest findById(Integer id);

	/**
	 * Gets the OI property types.
	 *
	 * @param oitypeId the oitype id
	 * @param propertyEnum the property enum
	 * @return the OI property types
	 */
	List<OitypeProperty> getOIPropertyTypes(int oitypeId, PropertyEnum propertyEnum);
	 
 	/**
 	 * Gets the OI property types.
 	 *
 	 * @return the OI property types
 	 */
 	List<OitypeProperty> getOIPropertyTypes();
	

	/**
	 * Gets the frequencies.
	 *
	 * @param varids the varids
	 * @return the frequencies
	 */
	String getFrequencies(Integer varids);

	/**
	 * Gets the raw data.
	 *
	 * @param varids the varids
	 * @param oiids the oiids
	 * @param startdate the startdate
	 * @param enddate the enddate
	 * @return the raw data
	 */
	List<Object> getRawData(String varids, String oiids, String startdate, String enddate);

	/**
	 * Gets the visualizations.
	 *
	 * @param ois the ois
	 * @param vars the vars
	 * @return the visualizations
	 */
	List<Visualization> getVisualizations(Integer[] ois, Integer[] vars);

	/**
	 * Gets the visualization engine.
	 *
	 * @param method the method
	 * @return the visualization engine
	 * @throws Exception the exception
	 */
	String getVisualizationEngine(String method) throws Exception;
	
	
	/**
	 * Gets the first level relations.
	 *
	 * @return the first level relations
	 */
	List<OiRelation> getFirstLevelRelations();

	/**
	 * Find by parent id.
	 *
	 * @param id the id
	 * @return the list
	 */
	List<OiRelation> findByParentId(int id);

	List<Object> getMinAndMaxTimeMeasurements();

	List<Object> getTop10();

	List<Codevalues> getCodeValues(String codeTitle);

	List<OiBackgroundpropertyValue> getUniqueCodeValues(String typePropTitle);

	List<Codevalues> getCodeValuesByCodeValueAndCodesTitle(String codeValue, String codesTitle);

	List<OiBackgroundpropertyValue> getUniqueBackgroundValues(String typePropTitle);
	
}
