/**
* Trigger to handle sales condition exception VAT values for contract
* */
trigger Trg_Nego360_Sale_Condition_Exception on Pol_Sale_Condition_Exception__c (after insert, after update) {

	if (Trigger.isAfter) {
    	if (System.Trigger.isInsert || System.Trigger.isUpdate) {
         	// Map <contract Id, sale condition exception> used to map each contract Id with its related sale condition exception.
         	Map<Id, Pol_Sale_Condition_Exception__c> saleCondExpMap = new Map<Id, Pol_Sale_Condition_Exception__c>();
         	// Fill the map from the current sales conditions exceptions.
         	for(Pol_Sale_Condition_Exception__c condEx : trigger.new) {
          		saleCondExpMap.put(condEx.Contract__c, condEx);
     		}
     		// Creation of a list of contracts for update.
            List<Contract__c> cList = new List<Contract__c>();
			// Loop over the list of contracts which have sales conditions exceptions related to them.
			for(Contract__c contractItem : [SELECT Id, VAT_Rebate_Rate__c, VAT_Service_Rate__c,VAT_Finance_Rate__c, 
                                                 Buying_Payment_Term_Abbrev__c,Services_Payment_Term_Abbrev__c 
                                                 FROM Contract__c
                                                 WHERE Id IN: saleCondExpMap.keySet()]) {
                // Get corresponding sale condition exception of the current contract.
                Pol_Sale_Condition_Exception__c sCondExc = saleCondExpMap.get(contractItem.Id);
                // Assign sale condition exception fields to the current contract fields.
                if (sCondExc != Null) {
       	 			contractItem.VAT_Rebate_Rate__c = sCondExc.VAT_Rebate_Rate__c;
	          	 	contractItem.VAT_Service_Rate__c = sCondExc.VAT_Service_Rate__c;
	        	 	contractItem.VAT_Finance_Rate__c = sCondExc.VAT_Finance_Rate__c;
	          	 	contractItem.Buying_Payment_Term_Abbrev__c = sCondExc.Buying_Payment_Term_Abbrev__c;
	           	 	contractItem.Services_Payment_Term_Abbrev__c = sCondExc.Services_Payment_Term_Abbrev__c;
	           	 	// Add updated contract.
	           	 	cList.add(contractItem);
                }
     		}
     		// Update contracts.
     		if (cList != Null && cList.size() > 0) {
    			update cList;
     		}
        }
 	}
}