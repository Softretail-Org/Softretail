/**
* Batchable class used to generate email for Invoices to suppliers.
* Loop over invoices
* */
global with sharing class SendInvoicesMailBatch implements Database.Batchable<SObject> {
    
    global final String query;
    global final Map<Id, Attachment> mapAttachHandle;
    
    global SendInvoicesMailBatch(Map<Id, Attachment> mapAttach,List<Id> suppId) {
        mapAttachHandle = mapAttach;
        List<Id> attachIdlist = new List<Id>();
        // we add the map into list to use it in query
        for(Id attachId : mapAttach.keySet()) {
            attachIdlist.add(attachId);
        }
        String q = 'SELECT Name, Inv_Supplier__r.Id, Inv_Supplier__r.Name,';
        q += ' Inv_Supplier__r.Acc_email__c, CreatedBy.name,';
        q += ' (SELECT Id FROM Attachments WHERE Id IN (\'' + String.join(attachIdlist, '\',\'') +'\'))';
        q += ' From Invoice__c';
        q += ' WHERE Inv_Supplier__r.Id IN (\'' + String.join(suppId, '\',\'') +'\')';
        query = q;
    }
    
    // Start
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }  
    
    // Execute
    global void execute(Database.BatchableContext bc, List<Invoice__C> scope) {
        try {
            List<Messaging.SingleEmailMessage> messagesList = new List<Messaging.SingleEmailMessage>();
            List<String> emailList  = new List<String>();
            for(Invoice__c invoiceObj : scope) {
                for(Attachment attachObj : invoiceObj.Attachments) {
                    Attachment attach = mapAttachHandle.get(attachObj.Id);
                    if(attach != NULL  && invoiceObj.Inv_Supplier__r.Acc_email__c != NULL) {                        
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        emailList = new List<String>();
                        emailList.add(invoiceObj.Inv_Supplier__r.Acc_email__c);
                        message.toAddresses = emailList; 
                        //@todo : find solution to send email with template , 
                        //custom object without passing contact id as setTargetObjectId                                                
                        //message.setTemplateID(template.Id); 
                        //message.setSaveAsActivity(false);
                        //message.setTargetObjectId(c.Id);
                        //message.setWhatId(emailMergeObj.supplierId);
                        //message.setWhatId( [select id from Account limit 1].id );
                        String body;
                        message.subject = 'Invoice '+ invoiceObj.Name;
                        body = 'Good morning supplier ' + invoiceObj.Inv_Supplier__r.Name +', <br/>';
                        body+= 'Please find attached invoice '+ attach.Name +' as pdf <br/>';
                        body+= 'Kind regards,<br>';
                        body+= invoiceObj.CreatedBy.name+'<br>';                        
                        message.htmlBody = body;                        
                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                        efa.setFileName(attach.Name);
                        efa.setBody(attach.Body);
                        message.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                        messagesList.add(message);                        
                    }
                }
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messagesList);            
            if (results[0].success) {
            }
        }catch (Exception e) {
            // Report errors here
            System.abortJob(bc.getJobId());
        }
    }
    
    // Finish
    global void finish(Database.BatchableContext bc) {
        // Get the Job
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                          FROM AsyncApexJob
                          WHERE Id = :bc.getJobId()];        
        // Send an email to the Apex job's submitter
        // notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
        mail.setSubject('Invoices email : ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +
                              ' batches with '+ a.NumberOfErrors + ' failures.' +
                              '\r\n' );
        Integer used = Limits.getEmailInvocations();
        Integer emailLimit = Limits.getLimitEmailInvocations();
        if(used >= emailLimit) {
            //print email text instead of email it.
        }
        else{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        }
    }
}