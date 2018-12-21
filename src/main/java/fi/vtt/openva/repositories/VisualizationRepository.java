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

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import fi.vtt.openva.domain.Visualization;

/**
 * VisualizationRepository.
 *
 * @author Markus Ylikerälä, Pekka Siltanen
 */

@Transactional(readOnly = true, timeout=30)
public interface VisualizationRepository extends CrudRepository<Visualization, Integer> {

	/**
	 * Find by oismin and property min by order by method asc.
	 *
	 * @param numOis the num ois
	 * @param numProp the num prop
	 * @return the list
	 */
	//ORDER BY x.method ASC

	@Query("SELECT x FROM Visualization x WHERE x.oismin <= :numOis AND x.propertymin <= :numProp AND (x.propertymax IS NULL OR :numProp <= x.propertymax) ORDER BY x.title")
	List<Visualization> findByOisminAndPropertyMinByOrderByMethodAsc(@Param("numOis") int numOis, @Param("numProp") int numProp);

	@Query("SELECT x FROM Visualization x WHERE x.oismin <= :numOis AND (x.oismax IS NULL OR :numOis <= x.oismax) AND x.propertymin <= :numProp AND (x.propertymax IS NULL OR :numProp <= x.propertymax) ORDER BY x.title")
	List<Visualization> findByOisLenAndPropertyLenByOrderByMethodAsc(@Param("numOis") int numOis, @Param("numProp") int numProp);
	/**
	 * Find by method.
	 *
	 * @param method the method
	 * @return the list
	 */
	@Query("SELECT x FROM Visualization x WHERE LOWER(x.method) = LOWER(:method)")
	List<Visualization> findByMethod(@Param("method") String method);
	
	List<Visualization> findAll();


	List<Visualization> findAllByOrderByTitleAsc();

	
}
