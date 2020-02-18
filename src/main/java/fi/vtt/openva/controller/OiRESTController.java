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
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.stream.Collectors;

import org.apache.logging.log4j.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import com.google.gson.Gson;
import fi.vtt.openva.domain.Objectofinterest;
import fi.vtt.openva.domain.OiRelation;
import fi.vtt.openva.domain.Oitype;
import fi.vtt.openva.repositories.RepositoryService;


/**
 * OiRESTController
 * 
 * @author Pekka Siltanen, Markus Yliker�l�
 *
 */

@RestController
@RequestMapping("/query")
public class OiRESTController {
	
	private static Logger log = LogManager.getLogger(OiRESTController.class);
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
	 * Returns a json string of ObjectOfInterests, that are children of 
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

		public String getOiType() {
			return oiType;
		}

		public void setOiType(String oiType) {
			this.oiType = oiType;
		}

		public ArrayList<OI> getChildren() {
			return children;
		}

		public void setChildren(ArrayList<OI> children_) {
			for (OI oi : children_) {
				this.children.add(oi);
			}
		}

		public void addChild(OI oi) {
			if (this.children == null) {
				this.children = new ArrayList<OI>();
			}
			this.children.add(oi);
		}

		private int id;
		private int oiTypeId;
		private String oiType;
		private String text;
		private String description;
		private ArrayList<OI> children;
		private String reportTitle;


		OI(Objectofinterest oi){
			setId(oi.getId());
			setOiTypeId(oi.getOitype().getId());
			setOiTypeTitle(oi.getOitypeTitle());
			setDescription(oi.getDescription());
			setText(oi.getTitle());
			setReportTitle(oi.getReportTitle());
		}

		public String getDescription() {
			return description;
		}

		public void setDescription(String description) {
			this.description = description;
		}
		
		public String getOiTypeTitle() {
			return oiType;
		}

		public void setOiTypeTitle(String oiTypeTitle) {
			this.oiType = oiTypeTitle;
		}

		public int getOiTypeId() {
			return oiTypeId;
		}

		public void setOiTypeId(int oiTypeId) {
			this.oiTypeId = oiTypeId;
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
	 * OiType.
	 * Private class for storing the ObjectOfInterest type database information used in UI
	 */
	private class OiType{

		public String getTitle() {
			return title;
		}
		
		public void setTitle(String title) {
			this.title = title;
		}

		private int id;
		private String title;
		private String reportTitle;
		private String description;

		OiType(Oitype oiType){
			setId(oiType.getId());
			setTitle(oiType.getTitle());
			setDescription(oiType.getDescription());
			setReportTitle(oiType.getReportTitle());
		}

		public String getDescription() {
			return description;
		}

		public void setDescription(String description) {
			this.description = description;
		}

		public String getReportTitle() {
			return reportTitle;
		}

		public void setReportTitle(String reportTitle) {
			this.reportTitle = reportTitle;
		}

		public int getId() {
			return id;
		}

		public void setId(int id) {
			this.id = id;
		}						
	}

}

