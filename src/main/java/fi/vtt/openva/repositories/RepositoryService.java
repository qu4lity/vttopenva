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
import java.util.Optional;

import org.springframework.transaction.annotation.Transactional;

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
 * RepositoryService
 * 
 * @author Markus Ylikerälä
 *
 */


@Transactional(readOnly = true, timeout=120)
public interface RepositoryService {
	Application getApplication(String title);
	List<OiBackgroundpropertyValue> getBackgroundValuesByOiTypeProperty(OitypeProperty oitp);
	
	List<OiBackgroundpropertyValue> getBackgroundValuesByOiTypePropertyAndCodeValues(OitypeProperty oitp,
			List<String> codevalues);

	List<OiBackgroundpropertyValue> getBackgroundValuesOiTypePropertyAndBackgroundValues(OitypeProperty oitp,
			List<Float> values);
	
	List<Codevalues> getCodeValues(String codeTitle);
	List<Codevalues> getCodeValuesByCodeValueAndCodesTitle(String codeValue, String codesTitle);
	
	Oitype getOitype(String string);
	
	
	List<Oitype> getOitypes();
	Objectofinterest[] getObjectOfInterests(Oitype oitype);
	Optional<Objectofinterest> findById(Integer id);
	List<Objectofinterest> findAll();
	List<OitypeProperty> getOIPropertyTypes(int oitypeId);
 	List<OitypeProperty> getOIPropertyTypes();
	List<Object> getRawData(String varids, String oiids, String startdate, String enddate);
	List<Visualization> getVisualizations(Integer[] ois, Integer[] vars);
	String getVisualizationEngine(String method) throws Exception;
	List<OiRelation> getFirstLevelRelations();
	List<OiRelation> findByParentId(int id);
	List<String> getMinAndMaxTimeMeasurements(String applicationTitle);
	List<Object> getTop10();

	List<OiBackgroundpropertyValue> getUniqueCodeValues(String typePropTitle);
	

	List<OiBackgroundpropertyValue> getUniqueBackgroundValues(int i);
	List<PropertyGroup> getPropertyGroups();	
	List<OitypeProperty> getOIPropertyTypesByGroup(Integer groupId);
	List<OitypeProperty> getFilteredCodedOiTypeProperties(List<String> titles);
	List<OitypeProperty> getFilteredNonCodedOiTypeProperties(List<String> titles);


	Optional<OitypeProperty> getOIPropertyTypeById(int id);

	List<OitypeProperty> getOIPropertyTypesByTitle(String title);
	List<Visualization> getVisualizations(Integer[] ois, Integer[] vars, String[] filters);
}
