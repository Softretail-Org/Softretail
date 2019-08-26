/**
 * Trigger that update Value_Dispatch_Mx__c where x
 * is the corresponding Sequence__c
 * */
trigger Trg_Org_FixMonthlyDispatch on Inv_BUDispatch_Details__c (before update) {
    
    Set<Id> conditionsIdSet = new Set<Id>();
    Set<Decimal> sequenceSet = new Set<Decimal>();
    // Map dispatch details with a complex key
    Map<String, Inv_BUDispatch_Details__c> dispatchDetailsMap = new Map<String, Inv_BUDispatch_Details__c>();
    // Map conditions id to invoice details id
    Map<String, Id> invoiceDetailsMap = new Map<String, Id>();
    
    for (Inv_BUDispatch_Details__c item : Trigger.New) {
        Integer sequence = Integer.valueOf(item.Sequence__c);
        if (item.Status__c != System.Trigger.oldMap.get(item.Id).Status__c && sequence > 0 && sequence <= 12) {
        	if (item.Status__c == 'Sent to Accounting') {
	            // TODO: check if properly working in unmanaged package
	            String fieldName = 'Value_Dispatch_M' + sequence + '__c';
                if(item.get(fieldName) == null)
                    item.put(fieldName, item.New_Dispatch_Value__c);
                // set Base_SellIn_MX__c
	            String baseSellinfieldName = 'Base_SellIn_M' + sequence + '__c';                
                if(item.get(baseSellinfieldName) == null)
                    item.put(baseSellinfieldName, item.New_Dispatch_SellIn__c);
	        }
	        // check if it is linked to invoice detail or not
	        if (item.Status__c == 'Validated') {
	            String fieldName = 'Invoice_Ref_M' + sequence + '__c';
	            if(item.get(fieldName) == null) {
	                conditionsIdSet.add(item.Discount__c);
	                sequenceSet.add(sequence);
	                dispatchDetailsMap.put(item.Discount__c + '-' + sequence, item);
	            }
	        }
        }
    }
    if(dispatchDetailsMap.size() > 0) {
        // Load corresponding Invoices details
        for(Invoice_Detail__c item : [SELECT id, Discount__c, Invoice__r.Sequence_Number__c
                                      FROM Invoice_Detail__c
                                      WHERE Discount__c IN :conditionsIdSet
                                      AND Invoice__r.Sequence_Number__c IN :sequenceSet])
        {
            invoiceDetailsMap.put(item.Discount__c + '-' + Integer.valueOf(item.Invoice__r.Sequence_Number__c), item.id);    
        }
        for (Inv_BUDispatch_Details__c item : Trigger.New) {
            Integer sequence = Integer.valueOf(item.Sequence__c);
            String key = item.Discount__c + '-' + sequence;
            String fieldName = 'Invoice_Ref_M' + sequence + '__c';
            if(invoiceDetailsMap.containsKey(key)) {
                item.put(fieldName, invoiceDetailsMap.get(key));
            }
        }
    }
}