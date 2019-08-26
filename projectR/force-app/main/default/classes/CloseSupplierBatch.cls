/**
 * Set Supplier Status to Close for all suppliers
 * having Status_EDate__c < TODAY
 * To Schedule: System.schedule('Close Supplier Batch', '0 0 23 1/1 * ? *', new CloseSupplierBatchSchedule(null));
 * */
public with sharing class CloseSupplierBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    public final String query;
    public final Id country;
    
    // Constructor.
    public CloseSupplierBatch(String startedFrom, Id countryId) {        
        this.nb = new NegoptimBatch('Close supplier', NegoptimBatch.BatchType.Stateful, startedFrom);
        country = countryId;
        
        // Declare the query to get suppliers.
        String q = 'SELECT Status__c, Status_EDate__c';
        q += ' FROM Sup_Supplier__c';
        q += ' WHERE Status__c <> \'Close\' ';
        q += ' AND Status_EDate__c < TODAY ';
        if(country != null) {
            q += ' AND Country_origin__c = \'' + country + '\'';
        }
        query = q;
        // push inputs to log
        nb.logParameter('startedFrom', startedFrom);
        nb.logParameter('countryId', countryId);
        nb.logParameter('query', this.query);
    }
    
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    // Execute method.
    public void execute(Database.BatchableContext bc, List<Sup_Supplier__c> scope) {
        List<Sup_Supplier__c> suppliers = new List<Sup_Supplier__c>();
        for (Sup_Supplier__c supplier : scope) {
            supplier.Status__c = 'Close';
            suppliers.add(supplier);
        }
        
        Savepoint sp = Database.setSavepoint();
        try {            
            // check security on update supplier fields
            String[] supplierFields = new String[] { NegoptimHelper.normalizeAPIName('Status__c') };
            if(NegoptimHelper.checkUpdatibility(Sup_Supplier__c.SObjectType, supplierFields)){                    
                List<Database.SaveResult> results = Database.update(suppliers, false);
                nb.logResults(results, suppliers);
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        // Get Country Name.
        String countryName = 'ALL COUNTRIES';
        try {
            if(country != null)
                countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :country LIMIT 1].Name;
        } catch(DmlException e) {
            e.getDMLMessage(0);
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ' - ' + countryName + '/'+ Date.Today();
        customSubject += ' : ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}