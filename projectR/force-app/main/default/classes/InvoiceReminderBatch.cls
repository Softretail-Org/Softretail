/*
* Check invoice passed due date and not totally paid.
* Insert invoice reminder and send email to supplier.
*/ 
public with sharing class InvoiceReminderBatch implements Database.Batchable<SObject> {
    
    private NegoptimBatch nb;
    public final String query;
    public final String level;
    public final Date dueDate;
    public final String reminderText;
    
    // Constructor
    public InvoiceReminderBatch(String startedFrom, List<Id> ids, List<Id> reminderBUIds, Integer reminderLevel, Integer reminderValue, String reminderDescription) {
        
        this.nb = new NegoptimBatch('Invoice Reminder Batch', NegoptimBatch.BatchType.Stateless, startedFrom);
        dueDate = System.today() - reminderValue;
        String q = 'SELECT Id, Name, Inv_DueDate__c, Rest_to_paid__c, Reminded__c';
        q += ' FROM Invoice__c';
        q += ' WHERE Rest_to_paid__c > 0 AND Recovery_rate__c >= 0 AND Recovery_rate__c < 1';
        q += ' AND Inv_DueDate__c <= :dueDate';
        q += ' AND Inv_value__c > 0 AND Inv_Status__c IN (\'Printed\',\'Sent to supplier\',\'Sent to accounting\')';
        if(reminderLevel > 0){
            if(reminderLevel == 1){
                q += ' AND (Reminded__c = NULL)';
            }
            else if(reminderLevel == 2){
                q += ' AND (Reminded__c = \'1\')';
            }
            else if(reminderLevel == 3){
                q += ' AND (Reminded__c = \'2\')';
            }
            level = String.valueOf(reminderLevel);
            reminderText = reminderDescription;
        }
        else{
            q += ' AND (Reminded__c = NULL)';
        }
        
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\')';
        }
        if(reminderBUIds != null) {
            q += ' AND Inv_Business_Unit__c IN (\'' + String.join(reminderBUIds, '\',\'') +'\')';
        }
        query = q;
        // push inputs to log
        nb.logParameter('invoiceIds', ids);
        nb.logParameter('reminderBUIds', reminderBUIds);
        nb.logParameter('reminderLevel', reminderLevel);
        nb.logParameter('reminderValue', reminderValue);
        nb.logParameter('reminderDescription', reminderDescription);
        nb.logParameter('query', this.query);
    }
    
    // Start
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    // Execute
    public void execute(Database.BatchableContext bc, List<Invoice__c> scope) {
        // List of new invoice reminders
        List<Invoice_Reminder__c> invoiceReminders = new List<Invoice_Reminder__c>();       
        for (Invoice__c item : scope) {
            item.Reminded__c = level;
            Invoice_Reminder__c reminder = new Invoice_Reminder__c(Invoice__c = item.Id, Reminder__c = level, Email_Text__c = reminderText);
            invoiceReminders.add(reminder);
        }
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on insert invoice reminder fields
            String[] invoiceReminderFields = new String[] { NegoptimHelper.normalizeAPIName('Invoice__c'),
                NegoptimHelper.normalizeAPIName('Reminder__c'), NegoptimHelper.normalizeAPIName('Email_Text__c')};          
            
            // check security on update invoice fields
            String[] invoiceFields = new String[] { NegoptimHelper.normalizeAPIName('Reminded__c') };          
            
            if(NegoptimHelper.checkCreatibility(Invoice_Reminder__c.SObjectType, invoiceReminderFields) &&
               NegoptimHelper.checkUpdatibility(Invoice__c.SObjectType, invoiceFields))
            {
                if(invoiceReminders != null && invoiceReminders.size() > 0){
                    List<Database.SaveResult> results = Database.insert(invoiceReminders, false);
                    nb.logResults(results, invoiceReminders);
                }
                List<Database.SaveResult> results = Database.update(scope, false);
                nb.logResults(results, scope);
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.saveLog(bc);
    }
    
    // Finish
    public void finish(Database.BatchableContext bc) {        
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}