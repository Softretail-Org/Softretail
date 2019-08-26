/**
 * Correct the NegoScope (Supplier_Nego_Scope__c) attached to purchases flow PG (Purchases_Flow_PG__c)
 * To make sure the process will work properly in the next integration, the following notes are required when using ETL:
 * 1- Import the suppliers with the property ‘Is_Default_NegoScope__c = true’ to allow creation of default NS for every supplier.
 * 2- Use the corresponding ‘Default NS’ when loading purchases since the field is mandatory and every record should be related to the NS of the same supplier.
 * */
public with sharing class PurchasesNegoScopeBatch implements Database.Batchable<sObject> {
    
    private NegoptimBatch nb;
    public final String query;
    public final Id country;
    public final Integer year;
    
    // Constructor.
    public PurchasesNegoScopeBatch(String startedFrom, Id c, Integer y) {
        nb = new NegoptimBatch('Purchases Flow PG - Negoscope Correction', NegoptimBatch.BatchType.stateless, startedFrom);
        country = c;
        year = y;
        query = 'SELECT Id, Name, PG__c, Supplier_Nego_Scope__c' +
            ' FROM Purchases_Flow_PG__c ' +
            ' WHERE BU__r.Country_origin__c  = \'' + country + '\' AND Year__c = ' + year + '';
        nb.logParameter('country', country);
        nb.logParameter('year', year);
        nb.logParameter('query', query);
    }
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    // Execute method.
    public void execute(Database.BatchableContext BC, List<Purchases_Flow_PG__c> scope) {
        // Put PGs in a Set.
        Set<Id> pgSet = new Set<Id>();
        for (Purchases_Flow_PG__c item : scope) {
            pgSet.add(item.PG__c);
        }
        // Fetch the PGs related NegoScopes.
        List<Sup_NS_PG__c> nspgs = [SELECT Sup_PG__c, Sup_sup_NegoScope__c, Sup_sup_NegoScope__r.Parent_Nego_Scope__c
                                    FROM Sup_NS_PG__c WHERE Sup_PG__c IN :pgSet
                                    AND (NOT Sup_sup_NegoScope__r.Name LIKE '%Default%')]; // THIS IS NOT SAFE 100%, TODO: FIND ANOTHER CRITERIA
        // Map PGs with their parent NegoScopes.
        Map<Id, Id> mapNSPG = new Map<Id, Id>();
        for(Sup_NS_PG__c item : nspgs) {
            if(item.Sup_sup_NegoScope__r.Parent_Nego_Scope__c == null) {
                mapNSPG.put(item.Sup_PG__c, item.Sup_sup_NegoScope__c);
            }
            else {
                mapNSPG.put(item.Sup_PG__c, item.Sup_sup_NegoScope__r.Parent_Nego_Scope__c);
            }
        }
        // Update the Purchases NS if exists.
        List<Purchases_Flow_PG__c> purchasesListToUpdate = new List<Purchases_Flow_PG__c>();
        for(Purchases_Flow_PG__c item : scope) {
            if(mapNSPG.get(item.PG__c) != null && mapNSPG.get(item.PG__c) != item.Supplier_Nego_Scope__c) {
                item.Supplier_Nego_Scope__c = mapNSPG.get(item.PG__c);
                purchasesListToUpdate.add(item);
            }
        }
        try {
        	String[] invoiceFields = new String[] {NegoptimHelper.normalizeAPIName('Supplier_Nego_Scope__c')};
            if(NegoptimHelper.checkUpdatibility(Purchases_Flow_PG__c.SObjectType, invoiceFields)) {
           	 	update purchasesListToUpdate;
            }
        } catch(DMLException e) {
            nb.logError(e);
        }
        nb.saveLog(bc);
    }
    // Finish method.
    public void finish(Database.BatchableContext bc) {

        String countryName = 'N/A';
        try {
        	countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :country LIMIT 1].Name;
        } catch(DmlException e) {
    		e.getDMLMessage(0);
		}
		String customSubject = nb.getBatchName() + ' - ' + countryName + '/'+ year + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}