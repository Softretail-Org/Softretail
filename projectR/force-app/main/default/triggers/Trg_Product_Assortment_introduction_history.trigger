trigger Trg_Product_Assortment_introduction_history on Product_Assortment_Introduction_History__c (after insert, after update) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Set<Id> buTargetSet_inno = new Set<Id>();
            Set<Id> productIdSet_inno = new Set<Id>();
            Set<Id> BUAssortmentSet = new Set<Id>();
            Set<Id> buTargetSet_stop = new Set<Id>();
            Set<Id> productIdSet_stop = new Set<Id>();
            Id rootId = NegoptimHelper.getRootId();
            HierarchyElementTree het = new HierarchyElementTree(new Set<Id> {rootId});
            Map<String, Product_Assortment_Introduction_History__c> assortmentBUProductIntroMap = new Map<String, Product_Assortment_Introduction_History__c>();
            // assortment details list inserted
            List<Assortment_Detail__c> assortmentDetails = new List<Assortment_Detail__c>();            
            //Map<BU target Id, Assotment_BU__c list>
            Map<Id, List<Assortment_BU__c>> assortmentBUMap = new Map<Id, List<Assortment_BU__c>>();
            //Map<product Id, product list>
            Map<Id, Product2> productMap = new Map<Id, Product2>();
            Map<String, Id> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(Product_Assortment_Introduction_History__c.SObjectType);
            for (Product_Assortment_Introduction_History__c item : Trigger.new) {
                if((Trigger.oldMap == null || (Trigger.oldMap != null && (item.Load_Status__c != Trigger.oldMap.get(item.Id).Load_Status__c))) && item.Load_Status__c == 'Yes') {
                    if (item.RecordTypeId == recordTypeMap.get('Inno')) {
                        buTargetSet_inno.add(item.BU_Target__c);
                        productIdSet_inno.add(item.Product__c);
                    }
                    if (item.RecordTypeId == recordTypeMap.get('Stop')) {
                        buTargetSet_stop.add(item.BU_Target__c);
                        productIdSet_stop.add(item.Product__c);
                        assortmentBUProductIntroMap.put(item.BU_Target__c + '' + item.Product__c, item);
                    }
                }
            }
            // for Inno products
            if(!buTargetSet_inno.isEmpty() && !productIdSet_inno.isEmpty()) {
                for(Assortment_BU__c item : [SELECT Id, Name, BU_source__c, Orga_HE__c, BU_Target__c, Assortment_type__c, Ass_BDate__c, Assortment__c
                                             FROM Assortment_BU__c 
                                             WHERE BU_Target__c IN :buTargetSet_inno AND Status__c <> 'Closed' AND Ass_EDate__c >= :Date.today()
                                             AND RecordType.DeveloperName <> 'Conso'])
                {
                    if(!assortmentBUMap.containsKey(item.BU_Target__c)) {
                        assortmentBUMap.put(item.BU_Target__c, new List<Assortment_BU__c>{item});
                    } else {
                        assortmentBUMap.get(item.BU_Target__c).add(item);
                    }
                }
                productMap = new Map<Id, Product2>([SELECT Id, Name, Category__c FROM Product2 WHERE Id IN :productIdSet_inno]);
                if(!assortmentBUMap.isEmpty()) {
                    for (Product_Assortment_Introduction_History__c item : Trigger.new) {
                        if((Trigger.oldMap == null || (Trigger.oldMap != null && (item.Load_Status__c != Trigger.oldMap.get(item.Id).Load_Status__c))) && item.Load_Status__c == 'Yes') {
                            List<Assortment_BU__c> assortmentBUList = assortmentBUMap.get(item.BU_Target__c);
                            Product2 product = productMap.get(item.Product__c);
                            if(assortmentBUList != null && !assortmentBUList.isEmpty()) {
                                for(Assortment_BU__c assortmentBU : assortmentBUList) {
                                    if(item.Load_Rules__c == 'Any current & next assortment') {
                                        //
                                    } else if(item.Load_Rules__c == 'Only nego assortment') {
                                        if(assortmentBU.Assortment_type__c != 'Out' || assortmentBU.Assortment__c != 'Deal') continue;
                                    } else if(item.Load_Rules__c == 'Only next assortment') {
                                        if(assortmentBU.Ass_BDate__c <= System.today()) continue;
                                    }
                                    // skip if product category isn't child of assortment category
                                    Id assortmentBUCategory = assortmentBU.Orga_HE__c == null ? rootId : assortmentBU.Orga_HE__c;
                                    if (het.isAncestor(assortmentBUCategory, product.Category__c)) {
                                        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                                                         Product__c = item.Product__c,
                                                                                                         Category__c = product.Category__c,
                                                                                                         Ass_BU_Cluster__c = item.BU_Assortment__c,
                                                                                                         Client_Status__c = item.BU_Assortment__c != null ? 'New' : null);
                                        assortmentDetails.add(assortmentDetail);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // for Stop products
            if (!buTargetSet_stop.isEmpty() && !productIdSet_stop.isEmpty()) {
                Map<Id, Assortment_Detail__c> assortmentDetailMap = new Map<Id, Assortment_Detail__c>();
                for (Assortment_Detail__c item : [SELECT Assortment_BU__r.Assortment_type__c, Assortment_BU__r.Ass_BDate__c,
                                                  Assortment_BU__r.BU_Target__c, Assortment_BU__r.Assortment__c, Product__c, Client_Status__c/*, Application_Date__c*/
                                                  FROM Assortment_Detail__c
                                                  WHERE Assortment_BU__r.BU_Target__c IN :buTargetSet_stop
                                                  AND Assortment_BU__r.Status__c <> 'Closed'
                                                  AND Assortment_BU__r.RecordType.DeveloperName <> 'Conso'
                                                  AND Product__c IN :productIdSet_stop]) 
                {
                    String key = item.Assortment_BU__r.BU_Target__c + '' + item.Product__c;
                    Product_Assortment_Introduction_History__c productIntro = assortmentBUProductIntroMap.get(key);
                    if(productIntro == null) continue;
                    if(productIntro.Load_Rules__c == 'Only nego assortment') {
                        if(item.Assortment_BU__r.Assortment_type__c != 'Out' || item.Assortment_BU__r.Assortment__c != 'Deal') continue;
                    } else if(productIntro.Load_Rules__c == 'Only next assortment') {
                        if(item.assortment_BU__r.Ass_BDate__c <= System.today()) continue;
                    }
                    item.Client_Status__c = 'Delete';
                    assortmentDetails.add(item);
                }
            }
            if (!assortmentDetails.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(assortmentDetails, false);
                String errorMessage = '';
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results.get(i);
                    Assortment_Detail__c assortmentDetail = assortmentDetails.get(i);
                    if (!result.isSuccess()) {
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '(Product Id :' + assortmentDetail.Product__c + ') \n';
                        }
                    }
                }
                if(String.isNotBlank(errorMessage)) {
                    for (Product_Assortment_Introduction_History__c item : Trigger.new) {
                        trigger.NewMap.get(item.Id).addError(errorMessage);
                    }
                }
            }
        }
    }
}