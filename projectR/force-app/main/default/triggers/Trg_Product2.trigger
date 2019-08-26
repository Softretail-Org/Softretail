/**
 * Trigger Product2
 * TODO: ROLLBACK everthing in case of failure and put in logs
 * */
trigger Trg_Product2 on Product2 (before update, after insert, after update, before delete) {
    
    if (Trigger.isBefore) {
        // Set of Section Ids.
        Set<Id> categorySet = new Set<Id>();
        Set<Product2> productSet = new Set<Product2>();
        // Map<Product Id, PG> based on the following business rule: The combination of 'Supplier' and 'Product' must be unique.
        Map<Id, List<Supplier_PG_Mapping__c>> productPGsMap = new Map<Id, List<Supplier_PG_Mapping__c>>();
        List<Supplier_PG_Mapping__c> PGsToUpdate = new List<Supplier_PG_Mapping__c>();
        
        /**if (Trigger.isInsert) {
            Id unitNeedRecordTypeId = NegoptimHelper.getObjectRecordTypeId(Product2.getSObjectType(), 'Unit_Need');
            for (Product2 item : System.Trigger.new) {
                if (item.RecordTypeId == unitNeedRecordTypeId) {
                    item.Ext_id__c = null;
                }
            }
        }**/
        // check allowed profile access to manage Record type(Product)
        Id productRecordTypeId = NegoptimHelper.getObjectRecordTypeId(Product2.getSObjectType(), 'Product');
        Id userProfileId = UserInfo.getProfileId();
        List<String> allowedProfiles = GlobalSettingsManager.loadGlobalSettings().allowedProfilesToManageProducts;
        Boolean readOnlyUser = allowedProfiles == null || allowedProfiles.isEmpty() || !allowedProfiles.contains(userProfileId);
        if (Trigger.isUpdate) {
            Set<Id> stopedProductsIdSet = new Set<Id>();
            // Iterate over all products which are on update mode in order to fill the set of products.
            for (Product2 item : System.Trigger.new) {
                if (item.RecordTypeId == productRecordTypeId && readOnlyUser) {
                    item.addError(string.format(Label.MSG_Insufficient_Permissions_To_Update_Product, new String[]{item.Name}));
                    continue;
                }
                if (item.Category__c != System.Trigger.oldMap.get(item.Id).Category__c) {
                    productSet.add(item);
                    categorySet.add(item.Category__c);
                }
                if (System.Trigger.oldMap.get(item.Id).Market_End_of_Life_Date__c == null && item.Market_End_of_Life_Date__c != null) {
                    stopedProductsIdSet.add(item.id);
                }
            }
            if(!stopedProductsIdSet.isEmpty()) {
                List<Product_Assortment_Introduction_History__c> productAssortments = new List<Product_Assortment_Introduction_History__c>();
                Id stopRecordTypeId = NegoptimHelper.getObjectRecordTypeId(Product_Assortment_Introduction_History__c.getSObjectType(), 'Stop');
                // to filter out duplicate BUs
                Set<String> BUProductKeySet = new Set<String>();
                for (Assortment_Detail__c detail: [SELECT Assortment_BU__r.BU_Target__c, Assortment_BU__r.BU_Target__r.Related_Client__c, Product__c, Ass_BU_Cluster__c
                                                   FROM Assortment_Detail__c
                                                   WHERE Client_Status__c <> NULL AND Client_Status__c <> 'Delete'
                                                   AND Version__c = NULL
                                                   AND Assortment_BU__r.BU_Target__r.Related_Client__r.Status__c = 'Active'
                                                   AND Assortment_BU__r.BU_Target__r.Status__c = 'Open'
                                                   AND Assortment_BU__r.BU_Target__r.RecordType.DeveloperName = 'Banner'
                                                   AND Assortment_BU__r.RecordType.DeveloperName <> 'Conso'
                                                   AND Product__c IN :stopedProductsIdSet])
                {
                    // create one history per Assortment_BU per Product
                    String key = detail.Assortment_BU__r.BU_Target__c + '' + detail.Product__c;
                    if (!BUProductKeySet.contains(key)) {
                        Product_Assortment_Introduction_History__c productAssortment = new Product_Assortment_Introduction_History__c();
                        productAssortment.Product__c = detail.Product__c;
                        productAssortment.BU_Target__c = detail.Assortment_BU__r.BU_Target__c;
                        productAssortment.Client__c = detail.Assortment_BU__r.BU_Target__r.Related_Client__c;
                        productAssortment.recordTypeId = stopRecordTypeId;
                        productAssortments.add(productAssortment);
                        BUProductKeySet.add(key);
                    }
                }
                if(!productAssortments.isEmpty()) {
                    String errorMessage = '';
                    List<Database.SaveResult> results = Database.insert(productAssortments, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Product_Assortment_Introduction_History__c productAssortment = productAssortments.get(i);
                        if (!result.isSuccess()) {
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                trigger.NewMap.get(productAssortment.Product__c).addError(err.getStatusCode() + ' - ' + err.getMessage() + '(' + productAssortment.Product__c + ')');
                            }
                        }
                    }
                }
            }
            // In case where the set of productSet is not empty.
            if (!productSet.isEmpty()) {
                // Select all related PG, iterate & fill the map.
                for (Supplier_PG_Mapping__c item : [SELECT Id, Name, Section__c, Department__c, Product__c
                                                    FROM Supplier_PG_Mapping__c
                                                    WHERE Product__c IN :productSet])
                {
                    if (productPGsMap.containsKey(item.Product__c)) {
                        productPGsMap.get(item.Product__c).add(item);
                    } else {
                        productPGsMap.put(item.Product__c, new List<Supplier_PG_Mapping__c>{item});
                    }
                }
                if (!productPGsMap.isEmpty()) {
                    // Get parent category
                    Map<Id, Orga_HE__c> classificationsMap = new Map<Id, Orga_HE__c>([SELECT Id, Parent_Element__c, level__c
                                                                                      FROM Orga_HE__c
                                                                                      WHERE Id IN :categorySet]);
                    // update section & department fields on the PG level.
                    for (Product2 item : productSet) {
                        if (productPGsMap.containsKey(item.Id)) {
                            for (Supplier_PG_Mapping__c pg : productPGsMap.get(item.Id)) {
                                if (item.Category__c != null) {
                                    pg.Department__c = classificationsMap.get(item.Category__c).Parent_Element__c;
                                    pg.Section__c = item.Category__c;
                                    PGsToUpdate.add(pg);
                                }
                            }
                        }
                    }
                    // PGs Id list used to call it with reset dispatch details batch
                    Set<Id> PGsIdSet = new Set<Id>();
                    String errorMessage = '';
                    if (!PGsToUpdate.isEmpty()) {
                        List<Database.SaveResult> results = Database.update(PGsToUpdate, false);
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.SaveResult result = results.get(i);
                            Supplier_PG_Mapping__c pg = PGsToUpdate.get(i);
                            if (!result.isSuccess()) {
                                errorMessage += pg.Name + '(' + pg.Id + ') : ';
                                Database.Error[] errors = result.getErrors();
                                for (Database.Error err : errors) {
                                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                    trigger.NewMap.get(pg.Product__c).addError(err.getStatusCode() + ' - ' + err.getMessage() + '(' + pg.Id + ')');
                                }
                            } else {
                                PGsIdSet.add(pg.Id);
                            }
                        }
                        
                        if (!PGsIdSet.isEmpty()) {
                            // update purchase flow PG
                            List<Purchases_Flow_PG__c> purchasesFlowPGs = [SELECT Id, PG__r.Department__c, PG__r.Section__c, PG__r.Product__c
                                                                           FROM Purchases_Flow_PG__c
                                                                           WHERE PG__c IN :PGsIdSet
                                                                           AND Year__c = :Date.today().year()];
                            if (!purchasesFlowPGs.isEmpty()) {
                                for (Purchases_Flow_PG__c item : purchasesFlowPGs) {
                                    item.Department__c = item.PG__r.Department__c;
                                    item.Section__c = item.PG__r.Section__c;
                                }
                                List<Database.SaveResult> purchaseResults = Database.update(purchasesFlowPGs, false);
                                for (Integer i = 0; i < purchaseResults.size(); i++) {
                                    Database.SaveResult result = purchaseResults.get(i);
                                    Purchases_Flow_PG__c pfpg = purchasesFlowPGs.get(i);
                                    if (!result.isSuccess()) {
                                        errorMessage += pfpg.Name + '(' + pfpg.Id + ') : ';
                                        Database.Error[] errors = result.getErrors();
                                        for (Database.Error err : errors) {
                                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                            trigger.NewMap.get(pfpg.PG__r.Product__c).addError(err.getStatusCode() + ' - ' + err.getMessage() + '(' + pfpg.Id + ')');
                                        }
                                    }
                                }
                            }
                            if (!System.isBatch()) {
                                // Call Reset Dispatch Details Batch for the list of PGsIdSet
                                Database.executeBatch(new CancelDispatchingBatch('Trg_Product2', new List<Id>(PGsIdSet)));
                            }
                        }
                        /***                        
                        // Case a PG fail on update we need to create a Task (call an Action) and assign to Integration user
                        if (String.isNotBlank(errorMessage)) {
                            Task newTask = new Task(Description = errorMessage,
                                                    Priority = 'Normal',
                                                    Status = 'Not Started',
                                                    Subject = 'Failure in update PGs/Monthly Purchases',
                                                    CallType = 'Outbound',
                                                    IsReminderSet = true,
                                                    ReminderDateTime = System.now(),
                                                    OwnerID = UserInfo.getUserId());
                            Database.insert(newTask, false);
                        }***/
                    }
                }
            }
        }
        
        if (Trigger.isDelete) {
            Set<Id> productIdSet = System.Trigger.oldMap.keySet();
            for (Product2 item : System.Trigger.old) {
                if (item.RecordTypeId == productRecordTypeId && readOnlyUser) {
                    item.addError(string.format(Label.MSG_Insufficient_Permissions_To_Delete_Product, new String[]{item.Name }));
                    productIdSet.remove(item.Id);
                }
            }
            
            // Check if Product has related Commercial_Plan_Detail__c
            List<AggregateResult> arList = [SELECT Product__c pId, COUNT(Id) c
                                            FROM Commercial_Plan_Detail__c
                                            WHERE Product__c IN :productIdSet
                                            GROUP BY Product__c];
            for (AggregateResult item : arList) {
                Id pId = (Id)item.get('pId');
                if (Integer.valueOf(item.get('c')) > 0) {
                    System.Trigger.oldMap.get(pId).addError(string.format(Label.MSG_Cannot_Delete_Product_Linked_To_Commercial_Plan_Detail, new String[]{System.Trigger.oldMap.get(pId).Name }));
                    productIdSet.remove(pId);
                }
            }
            if (!productIdSet.isEmpty()) {
                // Check if Product has related Assortment_Detail__c
                arList = [SELECT Product__c pId, COUNT(Id) c
                          FROM Assortment_Detail__c
                          WHERE Product__c IN :productIdSet
                          GROUP BY Product__c];
                for (AggregateResult item : arList) {
                    Id pId = (Id)item.get('pId');
                    if (Integer.valueOf(item.get('c')) > 0) {
                        System.Trigger.oldMap.get(pId).addError(string.format(Label.MSG_Cannot_Delete_Product_Linked_To_Assortment_Detail, new String[]{System.Trigger.oldMap.get(pId).Name }));
                        productIdSet.remove(pId);
                    }
                }
                if (!productIdSet.isEmpty()) {
                    // delete list of related Product_Assortment_Introduction_History__c
                    delete [SELECT Id FROM Product_Assortment_Introduction_History__c WHERE Product__c IN :productIdSet];
                }
            }
        }
    }
    
    if (Trigger.isAfter) {
        // Set of referenced Product Ids
        Set<Id> referenceProductsIdSet = new Set<Id>();
        // Set of Product Ids that are no longer referenced
        Set<Id> unreferenceProductsIdSet = new Set<Id>();
        // Set of referenced Product Ids of type switch
        Set<Id> switchProductsIdSet = new Set<Id>();
        // List of referenced Products
        List<Product2> referenceProducts = new List<Product2>();
        // Map referenced product Id the product referencing it
        Map<Id, Product2> referenceIdToProductMap = new Map<Id, Product2>();
        if(Trigger.isInsert) {
            // Initialisation of Product_Assortment_introduction_history__c
            List<Product_Assortment_Introduction_History__c> productAssortments = new List<Product_Assortment_Introduction_History__c>();
            List<Orga_BU__c> targetBUs = [SELECT Id, Related_Client__c FROM Orga_BU__c
                                          WHERE Status__c = 'Open' AND Related_Client__c <> NULL AND Related_Client__r.Status__c = 'Active'
                                          AND RecordType.DeveloperName = 'Banner' AND IsMasterBU__c <> TRUE AND Layer_Nego_Conso__c <> TRUE];
            Map<String, Id> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(Product_Assortment_Introduction_History__c.SObjectType);
            for (Product2 item : System.Trigger.new) {
                // if item is referencing a product add the id of the referenced product to referenceProductsIdSet
                if (item.reference_product__c != null) {
                    referenceProductsIdSet.add(item.reference_product__c);
                    referenceIdToProductMap.put(item.Reference_Product__c, item);
                    // isSwitch or none are selected, then add to switchProductsIdSet to update Product_Reference_Type to switch in reference Products
                    if (item.isSwitch__c || (!item.isSwitch__c && !item.isRenovation__c)) {
                        switchProductsIdSet.add(item.Reference_Product__c);
                    }
                }
                for (Orga_BU__c bu : targetBUs) {
                    Product_Assortment_Introduction_History__c productAssortment = new Product_Assortment_Introduction_History__c();
                    productAssortment.RecordTypeId = recordTypeMap.get('Inno');
                    productAssortment.Product__c = item.Id;
                    productAssortment.BU_Target__c = bu.Id;
                    productAssortment.Client__c = bu.Related_Client__c;
                    productAssortments.add(productAssortment);
                }
            }
            if(!productAssortments.isEmpty()) {
                List<Database.SaveResult> results = Database.insert(productAssortments, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    Product_Assortment_Introduction_History__c productAssortment = productAssortments.get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            trigger.NewMap.get(productAssortment.Product__c).addError(err.getStatusCode() + ' - ' + err.getMessage() + '(' + productAssortment.Product__c + ')');
                        }
                    }
                }
            }
            if (!referenceProductsIdSet.isEmpty()) {
                for (Product2 item : [SELECT Product_Reference_Type__c From Product2 WHERE Id IN :referenceProductsIdSet]) {
                    if (item.Product_Reference_Type__c == null) {
                        item.Product_Reference_Type__c = switchProductsIdSet.contains(item.Id) ? 'Switch' : 'Reno';
                        referenceProducts.add(item);
                    } else {
                        // add error
                        referenceIdToProductMap.get(item.Id).addError('Invalid Reference Product');
                    }
                }
                try {
                    update referenceProducts;
                } catch (DMLException ex) {
                    System.debug('Exception: field=' + ex.getDmlFields(0) + ': ' + ex.getDMLMessage(0) + 'line - ' + ex.getLineNumber());
                }
            }
        }
        
        if (Trigger.isUpdate) {
            referenceIdToProductMap.clear();
            for (Product2 item : System.Trigger.new) {
                if (item.Reference_Product__c != System.Trigger.oldMap.get(item.Id).Reference_Product__c) {
                    if (item.Reference_Product__c != null) {
                        referenceProductsIdSet.add(item.Reference_Product__c);
                        referenceIdToProductMap.put(item.Reference_Product__c, item);
                        // isSwitch or none are selected, then add to switchProductsIdSet to update Product_Reference_Type to switch in reference Products
                        if (item.isSwitch__c || (!item.isSwitch__c && !item.isRenovation__c)) {
                            switchProductsIdSet.add(item.Reference_Product__c);
                        }
                    }
                    if (System.Trigger.oldMap.get(item.Id).Reference_Product__c != null 
                        && !referenceProductsIdSet.contains(System.Trigger.oldMap.get(item.Id).Reference_Product__c))
                        unreferenceProductsIdSet.add(System.Trigger.oldMap.get(item.Id).Reference_Product__c);
                }
            }
            if (!referenceProductsIdSet.isEmpty()) {
                for (Product2 item : [SELECT Product_Reference_Type__c From Product2 WHERE Id IN :referenceProductsIdSet]) {
                    if (item.Product_Reference_Type__c == null) {
                        item.Product_Reference_Type__c = switchProductsIdSet.contains(item.Id) ? 'Switch' : 'Reno';
                        referenceProducts.add(item);
                    } else {
                        referenceIdToProductMap.get(item.id).addError('Invalid Reference Product');
                    }
                }
            }
            if (!unreferenceProductsIdSet.isEmpty()) {
                for (Product2 item : [SELECT Product_Reference_Type__c From Product2 WHERE Id IN :unreferenceProductsIdSet]) {
                    item.Product_Reference_Type__c = null;
                    referenceProducts.add(item);
                }
            }
            if (!referenceProducts.isEmpty()) {
                try {
                    update referenceProducts;
                } catch (DMLException ex) {
                    System.debug('Ex: field=' + ex.getDmlFields(0) + ': ' + ex.getDMLMessage(0) + 'line - ' + ex.getLineNumber());
                }
            }
        }
    }
}