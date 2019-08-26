public with sharing class UnitNeedMergeLWCController {
	public static Id productRecordtype = NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, 'Product');
	public static Id unitNeedRecordtype = NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, 'Unit_Need');
	public String formatedExcelDate {
		get {
			return NegoptimDate.formatDate(system.now(), 'EEEEE, d MMMMM yyyy HH:mm');
		}
		private set;
	}
	@AuraEnabled(cacheable = true)
	public static String getTableColumns(String objectName, list <String> fieldsName, list <String> editablefieldsName) {
		List <LabelDescriptionWrapper> labelList = new List <LabelDescriptionWrapper> ();
		if (Schema.getGlobalDescribe().containsKey(ObjectName)) {
			sObject sObj = Schema.getGlobalDescribe().get(ObjectName).newSObject();
			//get all the labels for Opportunity fields and put them in a map, keyed to the field api name
			Map <String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap();
			for (String item: fieldsName) {
				String FName = item;
				if (FName.contains('__r')) {
					FName = FName.split('\\.')[0].replace('__r', '__c');
				}
				if (fieldMap.containsKey(FName)) {
					Boolean Editable = editablefieldsName.contains(item) ? true : false;
					labelList.add(new LabelDescriptionWrapper(fieldMap.get(FName).getDescribe().getLabel(), item, fieldMap.get(FName).getDescribe().getType().name()));
				}
			}
		}
		return JSON.serialize(labelList);
	}
	@AuraEnabled(cacheable = true)
	public static String fetchUnitNeedRecords(String SearchTerm, String unitNeedIds, Integer LimitSize, Integer offset) {
		System.debug('fetchUnitNeedRecords:');
		System.debug('SearchTerm:' + SearchTerm);
		System.debug('unitNeedIds:' + unitNeedIds);
		System.debug('LimitSize:' + LimitSize);
		System.debug('offset:' + offset);
		String query = 'SELECT Name, Category__c, Category__r.Name, Category__r.Elt_Code__c, ' +
		               ' Average_Weekly_Sales_Hyper__c, Retail_Price_Reco__c, recordTypeId, recordType.DeveloperName, Long_Name_Hierarchy__c';
		query += ' FROM Product2 where recordType.DeveloperName LIKE \'Unit_Need\'' +
		         ' AND Category__c <> NULL ';
		if (String.isNotEmpty(SearchTerm)) {
			SearchTerm = '%' + String.escapeSingleQuotes(SearchTerm) + '%';
			query += ' AND (Category__r.Name LIKE \'' + String.escapeSingleQuotes(SearchTerm) + '\'';
			query += ' OR Name LIKE \'' + String.escapeSingleQuotes(SearchTerm) + '\')';
		}
		if (String.isNotEmpty(unitNeedIds)) {
			String unitNeedIdsString = '\'' + String.join(unitNeedIds.split(';'), '\',\'') + '\'';
			query += ' AND Id IN (' + unitNeedIdsString + ') ';
		}
		query += ' ORDER BY Category__r.Name ASC, CreatedDate DESC';
		query += ' LIMIT ' + LimitSize + ' ';
		query += ' OFFSET ' + offset + ' ';
		System.debug('fetchUnitNeedRecords>>>>>>>>Database.query(query):' + Database.query(query));
		return JSON.serialize(Database.query(query));

	}
	@AuraEnabled(cacheable = true)
	public static String fetchUnitNeedRecordsCount(String SearchTerm, String unitNeedIds) {
		String query = 'SELECT COUNT() FROM Product2' +
		               ' WHERE recordType.DeveloperName LIKE \'Unit_Need\'' +
		               ' AND Category__c <> NULL ';
		if (String.isNotEmpty(SearchTerm)) {
			SearchTerm = '%' + String.escapeSingleQuotes(SearchTerm) + '%';
			query += ' AND (Category__r.Name LIKE \'' + String.escapeSingleQuotes(SearchTerm) + '\'';
			query += ' OR Name LIKE \'' + String.escapeSingleQuotes(SearchTerm) + '\')';
		}
		if (String.isNotEmpty(unitNeedIds)) {
			String unitNeedIdsString = '\'' + String.join(unitNeedIds.split(';'), '\',\'') + '\'';
			query += ' AND Id IN (' + unitNeedIdsString + ') ';
		}
		return JSON.serialize(Database.countQuery(query));
	}
	public static List <Product2> fetchUnitNeedRecordsByIds(Set <Id> unitNeedIdsSet) {
		List <Product2> uniteNeedList = [SELECT Name, Category__c, Category__r.Name, Category__r.Elt_Code__c, Average_Weekly_Sales_Hyper__c, Retail_Price_Reco__c, recordTypeId, recordType.DeveloperName, Long_Name_Hierarchy__c
		                                 FROM Product2
		                                 WHERE recordType.DeveloperName LIKE 'Unit_Need'
		                                 AND Category__c <> NULL
		                                 AND Id IN: unitNeedIdsSet
		];
		return uniteNeedList;
	}
	@AuraEnabled(cacheable = true)
	public static String fetchProductRecords(String SearchTerm, String SearchedCategories, Integer LimitSize, Integer offset) {
		System.debug('fetchProductRecords:');
		System.debug('SearchTerm:' + SearchTerm);
		System.debug('LimitSize:' + LimitSize);
		System.debug('offset:' + offset);
		System.debug('SearchedCategories:' + SearchedCategories);
		
		String query = 'SELECT ProductCode, Name, Category__c, Category__r.Name, Product_EAN__c, Status__c';

		query += ' FROM Product2 WHERE recordType.DeveloperName like \'Product\' AND UN_origin__c = Null ';
		query += ' AND Category__c <> NULL AND ProductCode <> NULL';
		if (String.isNotEmpty(SearchedCategories)) {
			String CategoryIdString = '\'' + String.join(SearchedCategories.split(';'), '\',\'') + '\'';
			System.debug('::::::CategoryIdString' + CategoryIdString);
			query += ' AND Category__c IN (' + CategoryIdString + ') ';
		}
		if (String.isNotEmpty(SearchTerm)) {
			SearchTerm = '%' + String.escapeSingleQuotes(SearchTerm) + '%';
			query += ' AND (Category__r.Name LIKE \'' + SearchTerm + '\'';
			query += ' OR Product_EAN__c LIKE \'' + SearchTerm + '\'';
			query += ' OR ProductCode LIKE \'' + SearchTerm + '\'';
			query += ' OR Status__c LIKE \'' + SearchTerm + '\'';
			query += ' OR Name LIKE \'' + SearchTerm + '\')';
		}
		query += ' ORDER BY Category__r.Name ASC';
		query += ' LIMIT ' + LimitSize + ' ';
		query += ' OFFSET ' + offset + ' ';
		System.debug('Query::::::::::::::::::>>>>>>>' + query);
		return JSON.serialize(Database.query(query));
	}
	@AuraEnabled(cacheable = true)
	public static String fetchProductRecordsCount(String SearchTerm, String SearchedCategories) {
		String query = 'SELECT COUNT() ';
		query += ' FROM Product2 WHERE recordType.DeveloperName like \'Product\' AND UN_origin__c = Null ';
		query += ' AND Category__c <> NULL AND ProductCode <> NULL';
		if (String.isNotEmpty(SearchedCategories)) {
			String CategoryIdString = '\'' + String.join(SearchedCategories.split(';'), '\',\'') + '\'';
			query += ' AND Category__c IN (' + CategoryIdString + ') ';
		}
		if (String.isNotEmpty(SearchTerm)) {
			SearchTerm = '%' + String.escapeSingleQuotes(SearchTerm) + '%';
			query += ' AND (Category__r.Name LIKE \'' + SearchTerm + '\'';
			query += ' OR Product_EAN__c LIKE \'' + SearchTerm + '\'';
			query += ' OR ProductCode LIKE \'' + SearchTerm + '\'';
			query += ' OR Status__c LIKE \'' + SearchTerm + '\'';
			query += ' OR Name LIKE \'' + SearchTerm + '\')';
		}
		return JSON.serialize(Database.countQuery(query));

	}
	public static List <Product2> fetchProductRecordsByProductCode(Set <String> ProductCodeSet) {
		List <Product2> productList = [SELECT ProductCode, Name, Category__c, Category__r.Name, Product_EAN__c, Status__c, isActive, Animation__c, Attribute1_code__c, Attribute1_name__c, Attribute2_code__c, Attribute2_name__c, Attribute3_code__c, Attribute3_name__c, Brand__c, Commercial_Name__c, Depth__c, Ext_id__c, Height__c, Length_Unit__c, Long_Name__c, Market__c, Packaging__c, ProductCode2__c, Product_MasterSupplier__c, UC__c, UV__c, UVC_Pack__c, Weight__c, Weight_UC__c, Width__c, Long_Name_Hierarchy__c, RecordTypeId
		                               FROM Product2
		                               WHERE recordType.DeveloperName like 'Product'
		                               AND UN_origin__c = Null
		                                                  AND Category__c <> NULL
		                                                  AND ProductCode <> Null
		                                                  AND ProductCode IN: ProductCodeSet
		];
		return productList;
	}
	@AuraEnabled(cacheable = true)
	public static String fetchProductsProductCodeRecordsByProductCodeSearchTerm(String SearchTerm) {
		String query = 'SELECT ProductCode ';
		query +='FROM Product2 ';
		query +='WHERE recordType.DeveloperName like \'Product\' ';
		query +='AND UN_origin__c = Null ';
		query +='AND Category__c <> NULL ';
		query +='AND ProductCode <> Null ';
		query +='AND ProductCode like \'%' + SearchTerm + '%\'';
		List <Product2> productList = Database.query(query);
		return JSON.serialize(productList);
	}

	public class LabelDescriptionWrapper {
		@AuraEnabled
		public String label;
		@AuraEnabled
		public String fieldName;
		@AuraEnabled
		public String type;
		public LabelDescriptionWrapper(String labelTemp, String fieldNameTemp, String typeTemp) {
			label = labelTemp;
			fieldName = fieldNameTemp;
			type = typeTemp;
		}
	}
	@AuraEnabled
	public static String saveUnitNeed(String data) {
		Map<String, Map<String, MergeReportWrapper> > reportMap;
		reportMap = new Map<String, Map<String, MergeReportWrapper> >();
		Boolean isSuccess = true;
		String errorMessage = '';
		Map <Id, ValidationWrapper> wrapperMap = new Map <Id, ValidationWrapper> ();
		List <Product2> uniteNeedProductList = (List <Product2> ) JSON.deserialize(data, List <Product2> .class);
		Set <String> ProductCodeSet = new Set <String> ();
		Set <Id> unitNeedIdSet = new Set <Id> ();
		for (Product2 item: uniteNeedProductList) {
			ProductCodeSet.add(item.ProductCode);
			unitNeedIdSet.add(item.Id);
		}
		List <Product2> listProducts = fetchProductRecordsByProductCode(ProductCodeSet);
		Map <String, List <Product2> > unProductsMap = new Map <String, List <Product2> > ();
		for (Product2 item: listProducts) {
			if (!unProductsMap.containsKey(item.ProductCode)) {
				unProductsMap.put(item.ProductCode, new List <Product2> ());
			}
			unProductsMap.get(item.ProductCode).add(item);
		}
		List <Product2> listUniteNeed = fetchUnitNeedRecordsByIds(unitNeedIdSet);
		Map <Id, Product2> unitNeedsMap = new Map <Id, Product2> (listUniteNeed);
		Map <Id, Product2> unToUpdateList = new Map <Id, Product2> ();
		Map <Id, Product2> productsToDelete = new Map <Id, Product2> ();
		List <Product2> originalUnsList = listUniteNeed.deepClone(true, true, true);
		for (Product2 item: uniteNeedProductList) {
			Product2 unToUpdate = unitNeedsMap.get(item.Id);
			List <Product2> linkedProducts = unProductsMap.get(item.ProductCode);
			if (String.isNotBlank(item.ProductCode) && unToUpdate != null) {
				ValidationWrapper wp = validateMerge(reportMap, unitNeedsMap.get(item.Id).Name, item.Id, unToUpdate, linkedProducts, item.ProductCode);
				wrapperMap.put(item.Id, wp);
				System.debug(wp.isValid);
				if (wp.isValid) {
					//Update Unit Need
					Product2 productToDelete = unProductsMap.get(item.ProductCode).get(0);
					Product2 tmpProduct = unToUpdate;
					mergeProducts(unToUpdate, productToDelete);
					unToUpdateList.put(unToUpdate.Id, unToUpdate);
					productsToDelete.put(productToDelete.Id, productToDelete);
				}else {
					isSuccess = false;
					errorMessage += wp.comment;
				}
			}
		}
		Savepoint sp = Database.setSavepoint();
		try {
			delete productsToDelete.values(); // delete the merged products
			update unToUpdateList.values(); // update unit Needs informations
		} catch (DMLException ex) {
			Database.rollback(sp); // rollback the deletion and the update in case of any exception
			for (Integer i = 0; i <ex.getNumDml(); i++) {
				String recordName = '';
				String recordType = '';
				String errorMsg = '';
				if (unToUpdateList.containsKey(ex.getDmlId(i))) {
					recordName = unToUpdateList.get(ex.getDmlId(i)).Name;
					recordType = 'Unit Need';
				} else if (productsToDelete.containsKey(ex.getDmlId(i))) {
					recordName = productsToDelete.get(ex.getDmlId(i)).Name;
					recordType = 'Product';
				}
				if (StatusCode.ENTITY_IS_DELETED == ex.getDmlType(i)) {
					errorMsg = Label.MSG_ENTITY_IS_DELETED;
				} else if (StatusCode.ENTITY_IS_LOCKED == ex.getDmlType(i)) {
					errorMsg = Label.MSG_ENTITY_IS_LOCKED;
				} else if (StatusCode.ENTITY_IS_ARCHIVED == ex.getDmlType(i)) {
					errorMsg = Label.MSG_ENTITY_IS_ARCHIVED;
				} else {
					errorMsg = ex.getDmlMessage(i);
				}
				errorMessage += errorMsg != '' ? errorMsg + '\n' : '';
			}
			isSuccess = false;
		} catch (exception ex) {
			Database.rollback(sp); // rollback the deletion and the update in case of any exception
			isSuccess = false;
			errorMessage += ex.getMessage();
		}
		if(isSuccess && errorMessage == '') {
			sendEmail(reportMap);
		}
		return JSON.serialize(new SaveResultWrapper(isSuccess, errorMessage, wrapperMap.values()));
	}
	private static void mergeProducts(Product2 unToUpdate, Product2 productToMerge) {
		unToUpdate.UN_Origin__c = unToUpdate.Name;
		unToUpdate.IsActive = productToMerge.IsActive;
		unToUpdate.ProductCode = productToMerge.ProductCode;
		unToUpdate.Name = productToMerge.Name;
		unToUpdate.Animation__c = productToMerge.Animation__c;
		unToUpdate.Attribute1_code__c = productToMerge.Attribute1_code__c;
		unToUpdate.Attribute1_name__c = productToMerge.Attribute1_name__c;
		unToUpdate.Attribute2_code__c = productToMerge.Attribute2_code__c;
		unToUpdate.Attribute2_name__c = productToMerge.Attribute2_name__c;
		unToUpdate.Attribute3_code__c = productToMerge.Attribute3_code__c;
		unToUpdate.Attribute3_name__c = productToMerge.Attribute3_name__c;
		unToUpdate.Brand__c = productToMerge.Brand__c;
		unToUpdate.Commercial_Name__c = productToMerge.Commercial_Name__c;
		unToUpdate.Depth__c = productToMerge.Depth__c;
		unToUpdate.Ext_id__c = productToMerge.Ext_id__c;
		unToUpdate.Height__c = productToMerge.Height__c;
		unToUpdate.Length_Unit__c = productToMerge.Length_Unit__c;
		unToUpdate.Long_Name__c = productToMerge.Long_Name__c;
		unToUpdate.Market__c = productToMerge.Market__c;
		unToUpdate.Packaging__c = productToMerge.Packaging__c;
		unToUpdate.ProductCode2__c = productToMerge.ProductCode2__c;
		unToUpdate.Product_EAN__c = productToMerge.Product_EAN__c;
		unToUpdate.Product_MasterSupplier__c = productToMerge.Product_MasterSupplier__c;
		unToUpdate.Status__c = productToMerge.Status__c;
		unToUpdate.UC__c = productToMerge.UC__c;
		unToUpdate.UV__c = productToMerge.UV__c;
		unToUpdate.UVC_Pack__c = productToMerge.UVC_Pack__c;
		unToUpdate.Weight__c = productToMerge.Weight__c;
		unToUpdate.Weight_UC__c = productToMerge.Weight_UC__c;
		unToUpdate.Width__c = productToMerge.Width__c;
		unToUpdate.RecordTypeId = productToMerge.RecordTypeId;
	}
	private static ValidationWrapper validateMerge(Map<String, Map<String, MergeReportWrapper> > reportMap, String uniteNeedName, Id unitNeedId, Product2 unToUpdate, List <Product2> linkedProducts, String unProductCode) {
		boolean isValid = false;
		String status, comment, linkedProductName, linkedProductCategory;
		if (linkedProducts == null || linkedProducts.isEmpty()) { //a product code not found
			status = Label.MSG_Failed;
			comment = Label.MSG_Product_Not_Found;
			linkedProductName = '';
			linkedProductCategory = '';
		} else if (linkedProducts.size()> 1) { //Multiple Products with same Product Code
			status = Label.MSG_Failed;
			comment = Label.MSG_Duplicated_Product_Code;
			linkedProductName =  linkedProducts.get(0).Name;
			linkedProductCategory = linkedProducts.get(0).Long_Name_Hierarchy__c;
		} else
		if (!linkedProducts.get(0).Category__c.equals(unToUpdate.Category__c)) { //code product refer to a product on another classification
			status = Label.MSG_Failed;
			comment = Label.MSG_Code_Product_On_Wrong_Product_Classification;
			linkedProductName =  linkedProducts.get(0).Name;
			linkedProductCategory = linkedProducts.get(0).Long_Name_Hierarchy__c;
		} else if (linkedProducts.get(0).Category__c.equals(unToUpdate.Category__c)) { // product is valid and can be merged
			isValid = true;
			status = Label.MSG_Success;
			comment = Label.MSG_Success;
			linkedProductName =  linkedProducts.get(0).Name;
			linkedProductCategory = linkedProducts.get(0).Long_Name_Hierarchy__c;
		}
		//add the status to the reports map
		if(reportMap.get(status) == null )
			reportMap.put(status, new Map<String, MergeReportWrapper>());
		reportMap.get(status).put(unitNeedId,new MergeReportWrapper(unitNeedId, unToUpdate.Name, unToUpdate.Long_Name_Hierarchy__c, unProductCode, linkedProductName, linkedProductCategory, status, comment));
		return new ValidationWrapper(unProductCode, uniteNeedName, unitNeedId, isValid, status, comment);
	}
	@AuraEnabled
	public static String validateUniteNeedlink(String uniteNeedId, String productCode) {
		Product2 unitNeed = [Select Id, Name, Category__c From Product2 WHERE Id =: uniteNeedId];
		List <Product2> productList = [Select Id, Category__c From Product2 WHERE productCode =: productCode AND RecordType.DeveloperName = 'Product'];
		Boolean isValid = false;
		String status, comment;
		if (productList.size() == 0) { //a product code not found
			status = Label.MSG_Failed;
			comment = Label.MSG_Product_Not_Found;
		} else
		if (productList.size()> 1) { //Multiple Products with same Product Code
			status = Label.MSG_Failed;
			comment = Label.MSG_Duplicated_Product_Code;
		} else
		if (!productList.get(0).Category__c.equals(unitNeed.Category__c)) { //code product refer to a product on another classification
			status = Label.MSG_Failed;
			comment = Label.MSG_Code_Product_On_Wrong_Product_Classification;
		} else
		if (productList.get(0).Category__c.equals(unitNeed.Category__c)) {
			isValid = true;
			status = Label.MSG_Success;
			comment = Label.MSG_Success;
		}
		return JSON.serialize(new ValidationWrapper(productCode, unitNeed.Name, uniteNeedId, isValid, status, comment));
	}
	class ValidationWrapper {
		public String Id;
		public String ProductCode;
		public String uniteNeedName;
		public String uniteNeedId;
		public boolean isValid;
		public String status;
		public String comment;
		public ValidationWrapper(String ProductCode, String uniteNeedName, String uniteNeedId, boolean isValid, String status, String comment) {
			this.Id = uniteNeedId;
			this.ProductCode = ProductCode;
			this.uniteNeedName = uniteNeedName;
			this.uniteNeedId = uniteNeedId;
			this.isValid = isValid;
			this.status = status;
			this.comment = comment;
		}
	}
	class SaveResultWrapper {
		public Boolean isSuccess;
		public String errorMessage;
		List <ValidationWrapper> validationWrappersList;
		public SaveResultWrapper(Boolean isSuccess,String errorMessage, List <ValidationWrapper> validationWrappersList) {
			this.isSuccess = isSuccess;
			this.errorMessage = errorMessage;
			this.validationWrappersList = validationWrappersList;
		}
	}
	private static void sendEmail(Map<String, Map<String, MergeReportWrapper> > reportMap) {
		String formatedExcelDate = NegoptimDate.formatDate(system.now(), 'EEEEE, d MMMMM yyyy HH:mm');
		System.debug('send Email to : ' + UserInfo.getUserEmail());
		String[] toList = new String [] {UserInfo.getUserEmail()};
		PageReference pageRef = Page.UnitNeedProductMergeExcel;
		pageRef.getParameters().put('reportMapJson', JSON.serialize(reportMap));
		pageRef.setRedirect(true);
		blob excelBlob = pageRef.getContent();
		List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
		Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
		email_att.setBody(excelBlob);
		email_att.setContentType('application/vnd.ms-excel');
		email_att.setFileName(Label.LBL_Excel_Name + ' - ' + formatedExcelDate + '.xls');
		email_att.setinline(false);
		emailAttachments.add(email_att);
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setSenderDisplayName('NegOptim');
		email.setToAddresses(toList);
		email.setFileAttachments(emailAttachments);
		email.setSubject(Label.LBL_Merge_Products_Report);
		email.setHtmlBody(Label.LBL_Email_Body_Content);
		email.setPlainTextBody('');
		try {
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
		} catch (System.EmailException ex) {
			System.debug('Exception: ' + ex);
		}
	}
	public with sharing Class MergeReportWrapper {
		public String unId {get; set;}// unit need ID
		public String unName {get; set;}// unit need Name
		public String unCategory {get; set;}// unit need classification
		public String linkedProductCode {get; set;}// linked product code
		public String linkedProductName {get; set;}//linked product name
		public String linkedProductCategory {get; set;}//linked product classification
		public String status {get; set;}// status of the merge
		public String note {get; set;}// failure cause (if it exists)
		//Constructor
		public MergeReportWrapper(String unId, String unName, String unCategory, String linkedProductCode, String linkedProductName, String linkedProductCategory, String status, String note){
			this.unId = unId;
			this.unName = unName;
			this.unCategory = unCategory;
			this.linkedProductCode = linkedProductCode;
			this.linkedProductName = linkedProductName;
			this.linkedProductCategory = linkedProductCategory;
			this.status = status;
			this.note = note;
		}
	}
}