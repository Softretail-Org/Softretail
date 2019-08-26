/**
* No purchases insert in case of close PG status
* No purchases insert in case of close contract status
*/
trigger Trg_Nego360_Purchases_Flow_PG on Purchases_Flow_PG__c (before insert,before update) {
    
    String errMsg = System.Label.MSG_Cannot_Add_Purchase_Linked_Pg;
    String errMsg2 = System.Label.MSG_Cannot_Add_Purchase_Linked_Contract;
    String pgId,conId;	
    if (Trigger.isBefore) {
        if (System.Trigger.isInsert || System.Trigger.isUpdate){
        	 Set<Id> pgIds = new Set<Id>();
        	 Set<Id> conIds = new Set<Id>();
        	 
             for(Purchases_Flow_PG__c pfp : trigger.new) {
             	pgIds.add(pfp.PG__c);
             	conIds.add(pfp.Contrat1__c);     	
             }
             Map<Id, Supplier_PG_Mapping__c> mapPG = new Map<Id, Supplier_PG_Mapping__c>([SELECT  Status__c FROM Supplier_PG_Mapping__c WHERE Id IN :pgIds]);
             Map<Id, Contract__c> mapContract = new Map<Id, Contract__c>([Select Status__c FROM Contract__c WHERE Id IN :conIds]);
             
             for(Purchases_Flow_PG__c pfp : trigger.new) {
         		Supplier_PG_Mapping__c pgObj = mapPG.get(pfp.PG__c);
        		Contract__c conObj = mapContract.get(pfp.Contrat1__c);
  
                    if(pgObj != NULL && pgObj.Status__c == 'Close'){
                        pfp.PG__c.addError(errMsg); 
                    }
                    if(conObj != NULL && conObj.Status__c == 'Closed'){
                        pfp.Contrat1__c.addError(errMsg2); 
                    }
                }
             }
      
        }
    }