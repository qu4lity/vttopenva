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

import org.springframework.data.repository.CrudRepository;
import org.springframework.transaction.annotation.Transactional;

import fi.vtt.openva.dao.PropertyEnum;
import fi.vtt.openva.domain.OitypeProperty;

/**
 * OitypePropertyRepository
 * 
 * @author Markus Ylikerälä, Pekka Siltanen
 *
 */
@Transactional(readOnly = true, timeout=30)
public interface OitypePropertyRepository extends CrudRepository<OitypeProperty, Integer> {

	
	

	/* (non-Javadoc)
	 * @see org.springframework.data.repository.CrudRepository#findAll()
	 */
	List<OitypeProperty> findAll();

	/**
	 * Find by oitype id and propertytype.
	 *
	 * @param oitypeId the oitype id
	 * @param propertyEnum the property enum
	 * @return the list
	 */
	List<OitypeProperty> findByOitypeIdAndPropertytype(int oitypeId, PropertyEnum propertyEnum);

	/**
	 * Find by oitype id.
	 *
	 * @param oitypeId the oitype id
	 * @return the list
	 */
	List<OitypeProperty> findByOitypeId(int oitypeId);

	/**
	 * Find by id.
	 *
	 * @param valueOf the value of
	 * @return the oitype property
	 */
	OitypeProperty findById(Integer valueOf);

	/**
	 * Find by id in.
	 *
	 * @param vars the vars
	 * @return the list
	 */
	List<OitypeProperty> findByIdIn(List<Integer> vars);

	/**
	 * Find by propertytype.
	 *
	 * @param propertyEnum the property enum
	 * @return the list
	 */
	List<OitypeProperty> findByPropertytype(PropertyEnum propertyEnum);
	
}
