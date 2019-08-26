/**
 * CASE 1: Validate if a Brand distributor is already linked to a brand.
 * CASE 2: Validate if brand distributor is added to a negoscope on delete.
 * */
trigger Trg_Sup_Bra_Distributor on Sup_Bra_Distributor__c (before insert, before update, before delete) {
    
    if (Trigger.isBefore) {
        // CASE 1: Insert or Update
        if (System.Trigger.isInsert || System.Trigger.isUpdate) {
            String key;
            Set<Id> supplierIds = new Set<Id>();
            Set<Id> brandIds = new Set<Id>();
            Map<String, Sup_Bra_Distributor__c> duplicateMap = new Map<String, Sup_Bra_Distributor__c>();
            for (Sup_Bra_Distributor__c item : System.Trigger.new) {
                supplierIds.add(item.Supplier__c);
                brandIds.add(item.Brand__c);
                key = item.Supplier__c + '' + item.Brand__c;
                // Make sure another new brand distributor corresponding to an existing brand distributor isn't also a duplicate.
                if (duplicateMap.containsKey(key)) {
                    item.addError(string.format(Label.MSG_Distributor_Linked_Brand, new String[]{item.Supplier__c, item.Brand__c}));
                } else {
                    duplicateMap.put(key, item);
                }
            }
            // handle Distributor already linked to brand ( can not add to dist brand to a brand )
            Map<String, Sup_Bra_Distributor__c> existingBDMap = new Map<String, Sup_Bra_Distributor__c>();
            for (Sup_Bra_Distributor__c  item : [SELECT Id, Brand__c, Supplier__c, Brand__r.Name, Supplier__r.Name
                                                 FROM Sup_Bra_Distributor__c
                                                 WHERE Brand__c IN :brandIds
                                                 AND Supplier__c IN :supplierIds])
            {
                // add by key brand and supplier if supplier distributor already exist for a brand
                key = item.Supplier__c + '' + item.Brand__c;
                existingBDMap.put(key, item);
            }
            for (Sup_Bra_Distributor__c item : System.Trigger.new) {
                key = item.Supplier__c + '' + item.Brand__c;
                if(existingBDMap.containsKey(key) && (item.Id == null || (item.Id != null && existingBDMap.get(key).Id != item.Id))) {
                    item.addError(string.format(Label.MSG_Distributor_Linked_Brand,new String[]{existingBDMap.get(key).Supplier__r.Name, existingBDMap.get(key).Brand__r.Name}));
                }
            }
        }
        // CASE 2: DELETE
        if(System.Trigger.isDelete) {
            String key, key2;
            Map<String, Sup_Bra_Distributor__c> brandDistributorMap = new Map<String, Sup_Bra_Distributor__c>();
            Set<Id> supplierIds = new Set<Id>();
            Set<Id> brandIds = new Set<Id>();
            // collect ids
            for(Sup_Bra_Distributor__c item : System.Trigger.old) {
                key = item.Supplier__c + '' + item.Brand__c;
                brandDistributorMap.put(key, item);
                supplierIds.add(item.Supplier__c);
                brandIds.add(item.Brand__c);
            }
            for(Sup_sup_NegoScope__c item : [SELECT Id, Supplier__c, (SELECT Id, Sup_Scope_Brand__c
                                                                      FROM Supplier_Nego_scope_Brands__r
                                                                      WHERE Sup_Scope_Brand__c IN :brandIds)
                                             FROM Sup_sup_NegoScope__c
                                             WHERE Supplier__c IN :supplierIds])
            {
                for(Sup_NS_Brand__c bd : item.Supplier_Nego_scope_Brands__r) {
                    key2 = item.Supplier__c + '' + bd.Sup_Scope_Brand__c;
                    // check if brand dist have a negoscope related
                    if(brandDistributorMap.containsKey(key2))
                        brandDistributorMap.get(key2).addError(System.Label.MSG_Cant_Delete_Brand);
                }
            }
        }
    }
}