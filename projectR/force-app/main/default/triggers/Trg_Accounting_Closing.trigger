/*
 * Excecute accounting closing batch [on After-Insert trigger].
 * Update status accounting entries related to accounting closing updated status [on Before-Update trigger].
 * Lock accounting closing if status ='Sent to SAP'
 * Delete accounting entries related to accounting closing deleted [on Before-Delete trigger].
 */ 
trigger Trg_Accounting_Closing on Accounting_Closing__c (before insert, before update, before delete, after insert, after update) {
    if (Trigger.isBefore) {
        Set<Id> accountingClosingSet = new Set<Id>();
        Set<Id> accountingClosingPreviewSet = new Set<Id>();
        Set<Id> accountingClosingSentToSAPSet = new Set<Id>();
        List<Accounting_Entry__c> accountingEntries = new List<Accounting_Entry__c>();
        if (Trigger.isUpdate) {
            for(Accounting_Closing__c item : Trigger.New) {
                if(item.Status__c == 'Sent_to_Accounting' && Trigger.OldMap.get(item.Id).Status__c == 'Preview'){
                    accountingClosingSentToSAPSet.add(item.Id);
                }
                if(item.Status__c == 'Preview' && Trigger.OldMap.get(item.Id).Status__c == 'Sent_to_Accounting'){
                    accountingClosingPreviewSet.add(item.Id);
                }
                if(item.Status__c == Trigger.OldMap.get(item.Id).Status__c &&
                   (item.Business_Unit__c != Trigger.OldMap.get(item.Id).Business_Unit__c ||
                    item.Closing_Date__c != Trigger.OldMap.get(item.Id).Closing_Date__c ||
                    item.Invoices__c != Trigger.OldMap.get(item.Id).Invoices__c ||
                    item.Payments__c != Trigger.OldMap.get(item.Id).Payments__c ||
                    item.Redistributions__c != Trigger.OldMap.get(item.Id).Redistributions__c)){
                        if(item.Status__c == 'Preview'){
                            item.addError(Label.MSG_Delete_Accounting_Closing_Line);
                        }
                    }
            }
            // Update accounting entry sent to SAP
            if(accountingClosingSentToSAPSet != null && accountingClosingSentToSAPSet.size() > 0){
                for(Accounting_Entry__c item : [SELECT Id, Name, Status__c FROM Accounting_Entry__c WHERE Accounting_Closing__c IN :accountingClosingSentToSAPSet]){
                    if(item.Status__c != 'Extract'){
                        item.Status__c = 'Extract';
                        accountingEntries.add(item);
                    }
                }
            }
            // Update accounting entry preview
            if(accountingClosingPreviewSet != null && accountingClosingPreviewSet.size() > 0){
                for(Accounting_Entry__c item : [SELECT Id, Name, Status__c FROM Accounting_Entry__c WHERE Accounting_Closing__c IN :accountingClosingPreviewSet]){
                    if(item.Status__c != 'Preview'){
                        item.Status__c = 'Preview';
                        accountingEntries.add(item);
                    }
                }
            }
            if(accountingEntries != null && accountingEntries.size() > 0){
                update accountingEntries;
            }
        }
        if (Trigger.isDelete) {
            for(Accounting_Closing__c item : Trigger.Old) {
                if(item.Status__c == 'Preview'){
                    accountingClosingSet.add(item.Id);
                }
            }
            // Delete accounting entry
            if(accountingClosingSet != null && accountingClosingSet.size() > 0){
                accountingEntries = [SELECT Id FROM Accounting_Entry__c WHERE Accounting_Closing__c IN :accountingClosingSet];
                if(accountingEntries != null && accountingEntries.size() > 0){
                    delete accountingEntries;
                }
            }
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            Set<Id> accountingClosingSet = new Set<Id>();
            Map<Id, Accounting_Closing__c> invoicesBUMap = new Map<Id, Accounting_Closing__c>();
            Map<Id, Accounting_Closing__c> paymentsBUMap = new Map<Id, Accounting_Closing__c>();
            Map<Id, Accounting_Closing__c> redistributionsBUMap = new Map<Id, Accounting_Closing__c>();
            for(Accounting_Closing__c item : Trigger.New) {
                accountingClosingSet.add(item.Id);
                // Fill business unit for invoices
                if(!invoicesBUMap.containsKey(item.Business_Unit__c) && item.Invoices__c != null && item.Invoices__c == true){
                    invoicesBUMap.put(item.Business_Unit__c, item);
                }
                // Fill business unit for payments
                if(!paymentsBUMap.containsKey(item.Business_Unit__c) && item.Payments__c != null && item.Payments__c == true){
                    paymentsBUMap.put(item.Business_Unit__c, item);
                }
                // Fill business unit for redistribution
                if(!redistributionsBUMap.containsKey(item.Business_Unit__c) && item.Redistributions__c != null && item.Redistributions__c == true){
                    redistributionsBUMap.put(item.Business_Unit__c, item);
                }
            }
            List<Accounting_Scheme__c> accountingSchemes = [SELECT Id, Business_Unit__c, Business_Unit__r.Name, Amount_Type__c, Payment_Type__c, 
                                                            Credited_Company__c, Credited_Company__r.Name, Debited_Company__c, Debited_Company__r.Name,
                                                            Included_Discount_Types__c, Included_Discount_Type__c, RecordType.DeveloperName, Flag_D_or_C__c, Closing_Accounting_Type__c,
                                                            Include_Free_Invoices__c, Accounting_Entry_for__c, Store_Type__c, Managed_BU__c, Accounting_Type__c
                                                            FROM Accounting_Scheme__c
                                                            WHERE (RecordType.DeveloperName = 'Invoices' AND Business_Unit__c IN :invoicesBUMap.keySet())
                                                            OR (RecordType.DeveloperName = 'Payments' AND Business_Unit__c IN :paymentsBUMap.keySet())
                                                            OR (RecordType.DeveloperName = 'Redistribution' AND Business_Unit__c IN :redistributionsBUMap.keySet())];
            
            if(!System.isBatch()) {
                // Execute accounting closing batch
                for(Accounting_Closing__c item : Trigger.New) {
                    // accounting closing invoices
                    if(!invoicesBUMap.isEmpty() && !Test.isRunningTest()) {
                        Database.executeBatch(new AccountingClosingInvoiceBatch('After Insert Accounting Closing', item, accountingSchemes));
                    }
                    // accounting closing payments
                    if(!paymentsBUMap.isEmpty() && !Test.isRunningTest()) {
                        Database.executeBatch(new AccountingClosingPaymentBatch('After Insert Accounting Closing', item, accountingSchemes));
                    }
                    // accounting closing redistributions
                    if(!redistributionsBUMap.isEmpty() && !Test.isRunningTest()) {
                        Database.executeBatch(new AccountingClosingRedistributionBatch('After Insert Accounting Closing', item, accountingSchemes));
                    }
                    // Call Dispatching Based On Redistribution Model
                    if(!Test.isRunningTest()) {
                        Database.executeBatch(new BaseRedistributionModelBatch('After Insert Accounting Closing', null, null, null, item.Closing_Date__c, null));
                    }
                }
            }
        }
        if (Trigger.isInsert || Trigger.isUpdate) {
            List<Accounting_Closing__c> accountingClosingLocked = new List<Accounting_Closing__c>();
            for(Accounting_Closing__c item : Trigger.New) {
                if(item.Status__c == 'Sent_to_Accounting'){
                    accountingClosingLocked.add(item);
                }
            }
            if(accountingClosingLocked.size() > 0){
                Approval.LockResult[] results = Approval.lock(accountingClosingLocked, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Approval.LockResult result = results.get(i);
                    Accounting_Closing__c accountingClosing = accountingClosingLocked.get(i);
                    if (!result.isSuccess()){
                        String errorMessage = accountingClosing.Name + ' : ';
                        Database.Error[] errs = result.getErrors();
                        for (Database.Error err : errs){
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        accountingClosing.addError(errorMessage);
                    }
                }
            }
        }
    }
}