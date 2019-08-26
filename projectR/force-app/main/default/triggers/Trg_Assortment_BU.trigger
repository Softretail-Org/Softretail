trigger Trg_Assortment_BU on Assortment_BU__c(before update, before insert, after insert) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Set<Id> buTargetIdSet = new Set<Id>();
            Set<Id> categoryIdSet = new Set<Id>();
            Set<String> yearSet = new Set<String>();
            Map<String, Decimal> assortmentVersionMap = new Map<String, Decimal>();
            for (Assortment_BU__c item : Trigger.new) {
                // Make default status when clone
                if (item.isClone()) {
                    if (item.Status__c == 'Validated') {
                        item.Status__c = 'Open (in bulding process)';
                    }
                    item.Ext_Id__c = null;
                }
                
                buTargetIdSet.add(item.BU_Target__c);
                categoryIdSet.add(item.Orga_HE__c);
                yearSet.add(item.Year_String__c);
            }
            // Generate Name
            List<Assortment_BU__c> assortmentBUsList = [SELECT Simulation_version__c, RecordTypeId, BU_Target__c, Orga_HE__c, Year_String__c
                                                        FROM Assortment_BU__c
                                                        WHERE BU_Target__c IN :buTargetIdSet
                                                        AND Orga_HE__c IN :categoryIdSet
                                                        AND Year_String__c IN :yearSet
                                                        AND Simulation_version__c <> NULL
                                                        ORDER BY Simulation_version__c DESC];
            if (!assortmentBUsList.isEmpty()) {
                for (Assortment_BU__c item : assortmentBUsList) {
                    String key = item.RecordTypeId + '-' + item.BU_Target__c + '-' + item.Orga_HE__c + '-' + item.Year_String__c;
                    if (!assortmentVersionMap.containsKey(key)) {
                        Decimal lastVersion = item.Simulation_version__c == null ? 0 : item.Simulation_version__c;
                        assortmentVersionMap.put(key, lastVersion);
                    }
                }
            }
            for (Assortment_BU__c item : Trigger.new) {
                String key = item.RecordTypeId + '-' + item.BU_Target__c + '-' + item.Orga_HE__c + '-' + item.Year_String__c;
                if (!assortmentVersionMap.containsKey(key)) {
                    assortmentVersionMap.put(key, 0);
                }
                Decimal lastVersion = assortmentVersionMap.get(key);
                lastVersion++;
                item.Simulation_version__c = lastVersion;
                item.Name = item.Name_Prefix__c + '-V' + lastVersion;
                assortmentVersionMap.put(key, lastVersion);
            }
        }
        if (Trigger.isUpdate) {
            Set<Id> assortmentsIdSet = new Set<Id>();
            Set<Id> categoriesIdSet = new Set<Id>();
            for (Assortment_BU__c item : Trigger.new) {
                if (item.Orga_HE__c != Trigger.oldMap.get(item.Id).Orga_HE__c && item.orga_HE__c != null) {
                    assortmentsIdSet.add(item.Id);
                    categoriesIdSet.add(item.orga_HE__c);
                }
            }
            if (!assortmentsIdSet.isEmpty()) {
                Map<Id, Orga_HE__c> categoriesMap = new Map<Id, Orga_HE__c>([SELECT Elt_Code__c FROM Orga_HE__c WHERE Id IN :categoriesIdSet]);
                
                List<String> conditions = new List<String>();
                for (Id assortmentId : assortmentsIdSet) {
                    String categoryCode = categoriesMap.get(Trigger.newMap.get(assortmentId).Orga_HE__c).Elt_Code__c;
                    
                    String condition = ' (Assortment_BU__c = \'' + assortmentId + '\'';
                    condition += ' AND (NOT Category__r.Path__c LIKE \'%|' + categoryCode + '|%\')';
                    condition += ' AND (NOT Category__r.Path__c LIKE \'' + categoryCode + '|%\')';
                    condition += ' AND (NOT Category__r.Path__c LIKE \'%|' + categoryCode + '\'))';
                    
                    conditions.add(condition);
                    
                }
                String aggregateQuery = 'SELECT Assortment_BU__c assortmentId, count(Id) detailsCount';
                aggregateQuery += ' FROM Assortment_Detail__c';
                aggregateQuery += ' WHERE ' + String.join(conditions, ' OR ');
                aggregateQuery += ' GROUP BY Assortment_BU__c';
                
                for (AggregateResult result : Database.query(aggregateQuery)) {
                    if (Integer.valueOf(String.valueOf(result.get('detailsCount'))) != 0) {
                        Id assortmentId = Id.valueOf(String.valueOf(result.get('assortmentId')));
                        Trigger.newMap.get(assortmentId).addError(Label.Cannot_Change_Assortment_Category_To_Another_Details_Branch);
                    }
                }
            }
        }
    }
    /***
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            List<Assortment_BU__c> assotmentBUs = new List<Assortment_BU__c>();
            for (Assortment_BU__c item : Trigger.new) {
                Assortment_BU__c assortmentBU = new Assortment_BU__c(Id = item.Id, Ext_id__c = item.Id);
                assotmentBUs.add(assortmentBU);
            }
            if (!assotmentBUs.isEmpty()) {
                update assotmentBUs;
            }
        }
    }***/
	if (Trigger.isAfter) {
		if (Trigger.isInsert) {
			Map<String, Id> assortmentRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment_BU__c.SObjectType);
			Set<String> parentsIdSet = new Set<String>();
			List<String> categoryPathList = new List<String>();
			Set<String> categoryIdSet = new Set<String>();
			List<Decimal> yearList = new List<Decimal>();
			List<Assortment_BU__c> assortmentsList = new List<Assortment_BU__c> ();
			for (Assortment_BU__c item : Trigger.new) {
				if (item.Assortment_parent__c != null && item.RecordTypeId == assortmentRTIds.get('Nego')) {
					assortmentsList.add(item);
					parentsIdSet.add(item.Assortment_parent__c);
					categoryIdSet.add(item.Orga_HE__c);
					if (!yearList.contains(item.Year__c)) {
						yearList.add(item.Year__c);
					}
				}
			}
			// Only add Intro products for cloned Nego Assortments to Year + 1
			if (!assortmentsList.isEmpty()) {
				Map<Id, Assortment_BU__c> parentsMap = new Map<Id, Assortment_BU__c> ([SELECT Id, Year__c FROM Assortment_BU__c WHERE Id IN: parentsIdSet]);
				List<Orga_HE__c> categoryList = [SELECT Id, Path__c FROM Orga_HE__c WHERE Id IN: categoryIdSet];
				Map<Id, Orga_HE__c> categoryMap = new Map<Id, Orga_HE__c> (categoryList);
				for (Orga_HE__c item: categoryList) {
					if (!categoryPathList.contains(item.Path__c)) {
						categoryPathList.add(item.Path__c);
					}
				}
				if (!categoryPathList.isEmpty() && !yearList.isEmpty()) {
					String introducedProductsQuery = 'SELECT Id, Category__c, Category__r.Path__c, Market_Introduction_Date__c';
					introducedProductsQuery += ' FROM Product2';
					introducedProductsQuery += ' WHERE isActive = TRUE AND CALENDAR_YEAR(Market_Introduction_Date__c) IN (' + String.join(yearList, ',') + ')';
					introducedProductsQuery += ' AND (';
					for (Integer index = 0; index < categoryPathList.size(); index++) {
						introducedProductsQuery += ' Category__r.Path__c LIKE \'' + categoryPathList.get(index) + '%\'';
						if (index < categoryPathList.size() - 1) introducedProductsQuery += ' OR ';
					}
					introducedProductsQuery += ')';
					List<Product2> listProducts = Database.query(introducedProductsQuery);
					List<Assortment_Detail__c> assortmentDetailsList = new List<Assortment_Detail__c>();
					for (Assortment_BU__c item : assortmentsList) {
						if (item.Assortment_parent__c != null && item.Year__c == parentsMap.get(item.Assortment_parent__c).Year__c + 1) {
							for (Product2 product: listProducts) {
								if (item.Year__c == product.Market_Introduction_Date__c.year() && product.Category__r.Path__c.startsWith(categoryMap.get(item.Orga_HE__c).Path__c)) {
									Assortment_Detail__c assortmentDetail = new Assortment_Detail__c();
									assortmentDetail.Assortment_BU__c = item.Id;
									assortmentDetail.Category__c = product.Category__c;
									assortmentDetail.Product__c = product.Id;
									assortmentDetail.Version__c = null;
									assortmentDetail.Movement_Date__c = Date.today();
									assortmentDetailsList.add(assortmentDetail);
								}
							}
						}
					}
					if (!assortmentDetailsList.isEmpty()) {
						insert assortmentDetailsList;
					}
				}
			}
		}
	}
}