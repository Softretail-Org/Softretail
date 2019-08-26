/**
 * update Ext_id_c on after insert.
 * */ 
trigger Trg_Accounting_Entry on Accounting_Entry__c (after insert) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            List<Accounting_Entry__c> accountingEntryList = new List<Accounting_Entry__c>();
            for(Accounting_Entry__c item : Trigger.new) {
                accountingEntryList.add(new Accounting_Entry__c(Id = item.Id, Ext_id__c = item.Name));
            }
            // update Accounting Entry.
            if(accountingEntryList != null && accountingEntryList.size() > 0) {
                List<Database.SaveResult> results = Database.update(accountingEntryList, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    Accounting_Entry__c accountingEntry = accountingEntryList.get(i);
                    if (!result.isSuccess()){
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors){
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        accountingEntry.addError(errorMessage);
                    }
                }
            }
        }
    }
}