/**
 * Validate negoscope page to prevent adding same product group
 * with the same Nego Scope
 * */
trigger Trg_Org_Supplier_Negoscope_ProductGroup on Sup_NS_PG__c (before insert, before update, before delete, after insert, after delete) {
    
    String errMsg = System.Label.MSG_Product_Group_Alaready_Exist_Negoscope;
    String keyId;    
    if(Trigger.isBefore) {        
        if(System.Trigger.isInsert || System.Trigger.isUpdate) {             
            Map<String, Sup_NS_PG__c> pgNSMap = new Map<String, Sup_NS_PG__c>();
            Map<Id, Sup_NS_PG__c> pgNSIdMap = new Map<Id, Sup_NS_PG__c>();
            Map<Id, Sup_NS_PG__c> pgIdMap = new Map<Id, Sup_NS_PG__c>();            
            for(Sup_NS_PG__c  pgNS : System.Trigger.new){            	
                if(System.Trigger.isInsert || (System.Trigger.isUpdate
                                               &&((pgNS.Sup_PG__c != System.Trigger.oldMap.get(pgNS.Id).Sup_PG__c)
                                                  || pgNS.Sup_sup_NegoScope__c != System.Trigger.oldMap.get(pgNS.Id).Sup_sup_NegoScope__c))) {
                                                      
                                                      keyId = pgNS.Sup_sup_NegoScope__c +''+ pgNS.Sup_PG__c;                   
                                                      // Make sure another new product group isn't also a duplicate 
                                                      if (pgNSMap.containsKey(keyId)){
                                                          pgNS.addError(errMsg);
                                                      }
                                                      else{
                                                          pgNSMap.put(keyId, pgNS);
                                                          pgNSIdMap.put(pgNS.Sup_sup_NegoScope__c, pgNS);
                                                          pgIdMap.put(pgNS.Sup_PG__c, pgNS);
                                                      }
                                                  }
            }
            // Using a single database query, find all the prouct group in 
            // the database that have the same name as any 
            // of the product group  being inserted or updated. 
            for (Sup_NS_PG__c  pgNS : [SELECT Sup_sup_NegoScope__c,Sup_PG__c FROM Sup_NS_PG__c WHERE Sup_PG__c IN :pgIdMap.KeySet() OR Sup_sup_NegoScope__c IN :pgNSIdMap.KeySet()])
            {
                keyId = pgNS.Sup_sup_NegoScope__c +''+ pgNS.Sup_PG__c;
                
                Sup_NS_PG__c  newpgNS = pgNSMap.get(keyId);
                if(newpgNS != null){
                    newpgNS.Sup_PG__c.addError(errMsg);
                }
            }
        }
        
        // Control on NS_PG deleting regarding the corresponding dispatch details.
        // On Before-Delete
        if (Trigger.isDelete){
            // Lists creations: PGs and NSs from NS_PG object.
            Set<Id> PGSet = new Set<Id>();
            Set<Id> NsSet = new Set<Id>();
            for (Sup_NS_PG__c oItem : Trigger.old) {
                PGSet.add(oItem.Sup_PG__c);
                NsSet.add(oItem.Sup_sup_NegoScope__c);
            }
            Map<String, String> nsPGMap = new Map<String, String>();
            // Loop over the dispatch details having the two list as constraint, and over the current list of NS_PGs.
            for (Inv_BUDispatch_Details__c dd : [SELECT PG__c, Discount__r.Product_Scope__c, Discount__r.Product_Scope__r.Name
                                                 FROM Inv_BUDispatch_Details__c
                                                 WHERE PG__c IN :PGSet
                                                 AND Discount__r.Product_Scope__c IN :NsSet])
            {
                nsPGMap.put(dd.PG__c + '' + dd.Discount__r.Product_Scope__c, dd.Discount__r.Product_Scope__r.Name);
            }
            for (Sup_NS_PG__c oItem : Trigger.old) {
                if (nsPGMap.containsKey(oItem.Sup_PG__c + '' + oItem.Sup_sup_NegoScope__c)) {
                    oItem.addError(string.format(Label.MSG_cannot_remove_this_PG_from_negoscope,new String[]{nsPGMap.get(oItem.Sup_PG__c + '' + oItem.Sup_sup_NegoScope__c)}));
                }
            }
        }
    }
    
    if (Trigger.isAfter) {
        // reparenting sell_in on after insert NS_PG
        if (Trigger.isInsert) {
            List<Sup_NS_PG__c> NSPGList = new List<Sup_NS_PG__c>();
            Set<Id> NSPGSet = new Set<Id>();
            for (Sup_NS_PG__c item : trigger.new){
                NSPGSet.add(item.Id);
            }
            if(NSPGSet.size() > 0){
                NSPGList = [SELECT Id, Sup_sup_NegoScope__c, Sup_PG__c, Sup_PG__r.Product__c, Sup_PG__r.Supplier__c
                            FROM Sup_NS_PG__c
                            WHERE Id IN :NSPGSet];
            }
            // TODO: review Called from PromoConditionSynchroBatch: insert PG if not exist
            if(NSPGList.size() > 0 && !System.isBatch()){
                Database.executeBatch(new ReparentingSellinBatch('After Insert Assortment', null, null, null, null, NSPGList, null, null, null, false, null, null));
            }
        }
    }
}