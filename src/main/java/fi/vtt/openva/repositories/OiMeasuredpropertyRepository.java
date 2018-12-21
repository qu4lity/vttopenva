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
import java.util.ArrayList;
import java.util.List;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import fi.vtt.openva.domain.OiMeasuredproperty;

/**
 * OiMeasuredpropertyRepository
 * 
 * @author Markus Ylikerälä
 *
 */
@Transactional(readOnly = true, timeout=30)
public interface OiMeasuredpropertyRepository extends CrudRepository<OiMeasuredproperty, Integer> {
	
	/**
	 * Find by vars and ois and start date and end date.
	 *
	 * @param varIds the var ids
	 * @param oiIds the oi ids
	 * @param starttime the starttime
	 * @param endtime the endtime
	 * @return the list
	 */
    @Query("select x.oiMeasuredproperty.oitypePropertyTitle, x.oiMeasuredproperty.oiTitle, x.measurementValue, x.measurementTime from OiMeasuredpropertyValue x"
            + " where x.measurementTime >= :starttime AND x.measurementTime<= :endtime AND x.oiMeasuredproperty.id in (select id from OiMeasuredproperty y"
            + " where y.oitypeProperty.id in(:varIds) AND y.objectofinterest.id in(:oiIds))" +
              " group by x.oiMeasuredproperty.oitypePropertyTitle, x.oiMeasuredproperty.oiTitle, x.measurementValue, x.measurementTime order by x.measurementTime") 
    List<Object> findByVarsAndOisAndStartDateAndEndDate(@Param("varIds") ArrayList<Integer> varIds, @Param("oiIds") ArrayList<Integer> oiIds,
            @Param("starttime") LocalDateTime starttime, @Param("endtime") LocalDateTime endtime);
    
    @Query("select x.oiMeasuredproperty.oitypePropertyTitle, x.oiMeasuredproperty.oiTitle, x.measurementValue, x.measurementTime from OiMeasuredpropertyValue x"
            + " where x.measurementTime >= :starttime AND x.measurementTime<= :endtime AND x.oiMeasuredproperty.id in (select id from OiMeasuredproperty y"
            + " where y.oitypeProperty.id in(:varIds) AND y.objectofinterest.id in(:oiIds))" +
              " group by x.oiMeasuredproperty.oitypePropertyTitle, x.oiMeasuredproperty.oiTitle, x.measurementValue, x.measurementTime order by x.measurementTime") 
    List<Object> findFirst10ByVarsAndOisAndStartDateAndEndDate(@Param("varIds") ArrayList<Integer> varIds, @Param("oiIds") ArrayList<Integer> oiIds,
            @Param("starttime") LocalDateTime starttime, @Param("endtime") LocalDateTime endtime,  Pageable pageable);
	
	
	@Query("select min(x.measurementTime), max(x.measurementTime) from OiMeasuredpropertyValue x")	
	List<Object> findMinAndMaxTime();
	
	List<Object> findFirst10ByOrderByTimeCreated();
}
