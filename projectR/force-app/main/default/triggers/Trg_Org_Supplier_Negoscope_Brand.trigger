/**
 * Validate negoscope page to prevent adding same brand
 * with the same Nego Scope
 * */
trigger Trg_Org_Supplier_Negoscope_Brand on Sup_NS_Brand__c (before insert, before update) {
    
    String errMsg = System.Label.MSG_Brand_Alaready_Exist_Negoscope;
    String keyId;
    if (Trigger.isBefore) {  
        if (System.Trigger.isInsert || System.Trigger.isUpdate) {
            Map<String, Sup_NS_Brand__c> brandNSMap = new Map<String, Sup_NS_Brand__c>();
            Map<Id, Sup_NS_Brand__c> brandNSIdMap = new Map<Id, Sup_NS_Brand__c>();
            Map<Id, Sup_NS_Brand__c> brandIdMap = new Map<Id, Sup_NS_Brand__c>();
             
            
             for (Sup_NS_Brand__c  brandNS : System.Trigger.new)
            {
            	 keyId = brandNS.Sup_sup_NegoScope__c +''+ brandNS.Sup_Scope_Brand__c;
            
                if (System.Trigger.isInsert || (System.Trigger.isUpdate &&
                                                ((brandNS.Sup_Scope_Brand__c != System.Trigger.oldMap.get(brandNS.Id).Sup_Scope_Brand__c) || brandNS.Sup_sup_NegoScope__c != System.Trigger.oldMap.get(brandNS.Id).Sup_sup_NegoScope__c ))) {    
                    // Make sure another new brand isn't also a duplicate 
                    if (brandNSMap.containsKey(keyId))
                    {
                        brandNS.addError(errMsg);
                    }
                    else
                    {                      	
           		       brandNSMap.put(keyId, brandNS);
           		       brandNSIdMap.put(brandNS.Sup_sup_NegoScope__c, brandNS);
           		       brandIdMap.put(brandNS.Sup_Scope_Brand__c, brandNS);
                    } 
                }
            }  
            
            // Using a single database query, find all the brands in 
            // the database that have the same name as any 
            // of the brands being inserted or updated. 
           for (Sup_NS_Brand__c brandNS : [SELECT Sup_sup_NegoScope__c,Sup_Scope_Brand__c FROM Sup_NS_Brand__c where  Sup_sup_NegoScope__c IN :brandNSIdMap.KeySet() OR  Sup_Scope_Brand__c IN :brandIdMap.KeySet()]) {
            	
                keyId = brandNS.Sup_sup_NegoScope__c + '' + brandNS.Sup_Scope_Brand__c;
          
                Sup_NS_Brand__c  newbrandNS = brandNSMap.get(keyId);
				if(newbrandNS!=null) {
					  newbrandNS.Sup_Scope_Brand__c.addError(errMsg);
					
				}                
            }  
            
        }
    }
}