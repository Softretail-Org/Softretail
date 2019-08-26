/**
 * Validate negoscope page to prevent adding same  he  
 */
 
trigger Trg_Org_Supplier_Negoscope_HE on Supplier_NS_HE__c (before insert) {
	String errMsg = System.Label.MSG_HE_Alaready_Exist_Negoscope;
	String concatenateKey;
	if (Trigger.isBefore) {
		if (System.Trigger.isInsert) {
			Map<String, Supplier_NS_HE__c>  SEMap = new Map<String, Supplier_NS_HE__c>();
	        Map<String, Supplier_NS_HE__c>  NSMap = new Map<String, Supplier_NS_HE__c>();
	        Map<String, Supplier_NS_HE__c>  SENSMap = new Map<String, Supplier_NS_HE__c>();
		    for (Supplier_NS_HE__c  item : System.Trigger.new) {
		    	concatenateKey = item.Structure_Element__c + '' + item.Sup_sup_NegoScope__c;
            	// Make sure another new HE isn't also a duplicate.
                if (SENSMap.containsKey(concatenateKey)) {
                    item.addError(errMsg);
                } else {
       		       	SENSMap.put(concatenateKey, item);
       		       	SEMap.put(item.Structure_Element__c, item);
       		       	NSMap.put(item.Sup_sup_NegoScope__c, item);
                }
        	}
	        // Using a single database query, find all the prouct group in
	        // the database that have the same name as any
	        // of the product group  being inserted or updated.
	        for (Supplier_NS_HE__c  item : [SELECT Structure_Element__c, Sup_sup_NegoScope__c FROM Supplier_NS_HE__c
	        								WHERE Structure_Element__c IN : SEMap.KeySet() OR Sup_sup_NegoScope__c IN : NSMap.KeySet()]) {
				concatenateKey = item.Structure_Element__c + '' + item.Sup_sup_NegoScope__c;
            	Supplier_NS_HE__c newElt = SENSMap.get(concatenateKey);
            	if(newElt != null) {
				  	newElt.Structure_Element__c.addError(errMsg);
					newElt.Sup_sup_NegoScope__c.addError(errMsg);
				}
	        }
        }
	}
}