/**
  * Set contract field for purchases when contract field is null.
  */

public class PurchasesContractBatch implements Database.Batchable<sObject>, Database.stateful {
	
	private NegoptimBatch nb;
	public final String query;
	public final Id country;
	public final Integer year;
	
	// Constructor.
   	public PurchasesContractBatch(String startedFrom, Id c, Integer y) {
   		nb = new NegoptimBatch('Purchases Flow PG - Contract Correction', NegoptimBatch.BatchType.stateful, startedFrom);
   		country = c;
   		year = y;
   		query = 'SELECT Id, Name, Supplier_Nego_Scope__c, Contrat1__c FROM Purchases_Flow_PG__c ' +
   				'WHERE BU__r.Country_origin__c = \'' + country + '\' AND Year__c = ' + year + ' AND Contrat1__c = NULL';
        nb.logParameter('country', country);
        nb.logParameter('year', year);
        nb.logParameter('query', query);
   	}
	// Start method implementation.
   	public Database.QueryLocator start(Database.BatchableContext BC) {
      	return Database.getQueryLocator(query);
   	}
	// Execute method implementation.
   	public void execute(Database.BatchableContext BC, List<Purchases_Flow_PG__c> scope) {
 		// Fill list of NS.
 		List<Id> NSs = new List<Id>();
 		for (Purchases_Flow_PG__c purchase : scope) {
 			NSs.add(purchase.Supplier_Nego_Scope__c);
 		}
 		// Mapping between NS and Contract Ids.
 		Map<Id, Id> contractMap = new Map<Id, Id>();
 		for (Contract__c c : [SELECT Id, Name, Supplier_Nego_Scope__c FROM Contract__c WHERE Supplier_Nego_Scope__c IN : NSs]) {
 			contractMap.put(c.Supplier_Nego_Scope__c, c.Id);
 		}
 		// Checking and allocation.
 		for (Purchases_Flow_PG__c purchase : scope) {
 			if (contractMap.containsKey(purchase.Supplier_Nego_Scope__c)) {
 				purchase.Contrat1__c = contractMap.get(purchase.Supplier_Nego_Scope__c);
 			}
 		}
 		// Update contract field of purchases.
 		try {
 			update scope;
 		} catch(DMLException e) {
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }
	// Finish method implementation.
   	public void finish(Database.BatchableContext BC) {
        
        String countryName = 'N/A';
        try {
        	countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :country LIMIT 1].Name;
        } catch(DmlException e) {
    		e.getDMLMessage(0);
            nb.logError(e);
		}
		String customSubject = nb.getBatchName() + ' - ' + countryName + '/'+ year + ': ' + nb.getAsyncApexJob(bc).Status;
		nb.sendEmail(bc, null, customSubject);
   	/*
   		SetContractForPurchasesBatch batchInst = new SetContractForPurchasesBatch(country, year);
		String cronStr = '0 0,30 * * * *';
		System.schedule('Process Job', cronStr, batchInst);
   	*/
    }
}