/**
 * @description Re-calculate the AlreadyInvoiced of the condition when deleting an Trg_Exec_Invoice_Detail
 * [after insert-update-delete]
 * */
trigger Trg_Exec_Invoice_Detail on Invoice_Detail__c (after insert, after update, after delete) {
    
    if(!System.isBatch()) {
        Set<Id> conditionSet = new Set<Id>();
        if(Trigger.isInsert || Trigger.isUpdate) {
            for(Invoice_Detail__c item : Trigger.New) {
                
                // Check if invoice detail is inserted or updated
                if (item.Discount__c != null && (Trigger.OldMap == null || (Trigger.OldMap != null && item.Invoice_Value__c != Trigger.OldMap.get(item.Id).Invoice_Value__c))) {
                    conditionSet.add(item.Discount__c);
                }
                // Check if condition for invoice detail is updated
                if(Trigger.isUpdate && item.Discount__c != Trigger.OldMap.get(item.Id).Discount__c && Trigger.OldMap.get(item.Id).Discount__c != null){
                    conditionSet.add(Trigger.OldMap.get(item.Id).Discount__c);
                }
            }
        }
        if(Trigger.isDelete) {
            // Check if invoice detail is deleted
            for(Invoice_Detail__c item : Trigger.OldMap.values()) {
                if (item.Discount__c != null) {
                    conditionSet.add(item.Discount__c);
                }
            }
        }
        
        // Load map of currencies with exchange rate
        Map<String, Double> currencies = NegoptimHelper.getCurrencyMap();
        
        // Get the affected conditions to substract from the already invoice value
        Map<Id, Contract_Discount__c> conditionMap = new Map<Id, Contract_Discount__c>();
        if(conditionSet.size() > 0){
            conditionMap = new Map<Id, Contract_Discount__c>([SELECT Id, CurrencyIsoCode, Invoice_base__c, Already_Invoiced__c, Already_Invoiced_Edited__c
                                                              FROM Contract_Discount__c WHERE Id = :conditionSet]);
        }
        // Case insert, update or delete invoice detail
        Decimal conversionRate = 0;
        Contract_Discount__c refCondition = null, oldCondition = null; Invoice_Detail__c oldItem = null;
        if(Trigger.isInsert || Trigger.isUpdate) {
            for(Invoice_Detail__c item : Trigger.New) {
                Boolean isPrinted = item.Invoice_Number__c != null;

                refCondition = null; oldCondition = null; oldItem = null;
                // Get old invoice detail
                if(Trigger.isUpdate) {
                    oldItem = Trigger.OldMap.get(item.Id);
                }
                if(item.Discount__c != null && conditionMap.containsKey(item.Discount__c)) {
                    refCondition = conditionMap.get(item.Discount__c);
                    conversionRate = currencies.get(refCondition.CurrencyIsoCode);
                    if(refCondition.Already_Invoiced__c == null) refCondition.Already_Invoiced__c = 0;
                    if(refCondition.Already_Invoiced_Edited__c == null && isPrinted) refCondition.Already_Invoiced_Edited__c = 0;
                }
                // If insert new invoice detail
                if(oldItem == null && refCondition != null) {
                    refCondition.Already_Invoiced__c += (item.Invoice_Value__c * conversionRate).setScale(2);
                    if(isPrinted) {
                        refCondition.Already_Invoiced_Edited__c += (item.Invoice_Value__c * conversionRate).setScale(2);
                    }
                }
                // If update invoice detail
                if(oldItem != null){
                    if(refCondition != null) {
                        if(item.Discount__c != oldItem.Discount__c) {
                            refCondition.Already_Invoiced__c += (item.Invoice_Value__c * conversionRate).setScale(2);
                            if(isPrinted) {
                                refCondition.Already_Invoiced_Edited__c += (item.Invoice_Value__c * conversionRate).setScale(2);
                            }
                        }
                        else if(item.Invoice_Value__c != oldItem.Invoice_Value__c) {
                            refCondition.Already_Invoiced__c += ((item.Invoice_Value__c * conversionRate).setScale(2) - (oldItem.Invoice_Value__c * conversionRate).setScale(2));
                            if(isPrinted) {
                                refCondition.Already_Invoiced_Edited__c += ((item.Invoice_Value__c * conversionRate).setScale(2) - (oldItem.Invoice_Value__c * conversionRate).setScale(2));
                            }
                        }
                    }
                    // Update already invoiced for old condition
                    if(item.Discount__c != oldItem.Discount__c && oldItem.Discount__c != null){
                        if(conditionMap.containsKey(oldItem.Discount__c)) {
                            oldCondition = conditionMap.get(oldItem.Discount__c);
                            conversionRate = currencies.get(oldCondition.CurrencyIsoCode);
                            oldCondition.Already_Invoiced__c -= (oldItem.Invoice_Value__c * conversionRate).setScale(2);
                            if(isPrinted) {
                                oldCondition.Already_Invoiced_Edited__c -= (oldItem.Invoice_Value__c * conversionRate).setScale(2);
                            }
                        }
                    }
                }
            }
        }
        if(Trigger.isDelete) {
            // Case delete invoice detail
            for(Invoice_Detail__c item : Trigger.OldMap.values()) {
                Boolean isPrinted = item.Invoice_Number__c != null;
                refCondition = null;
                if(item.Discount__c != null && conditionMap.containsKey(item.Discount__c)) {
                    refCondition = conditionMap.get(item.Discount__c);
                    conversionRate = currencies.get(refCondition.CurrencyIsoCode);
                    if(refCondition.Already_Invoiced__c == null) refCondition.Already_Invoiced__c = 0;
                    if(isPrinted) {
                        if(refCondition.Already_Invoiced_Edited__c == null) refCondition.Already_Invoiced_Edited__c = 0;
                    }
                }
                // If delete invoice detail
                if(refCondition != null) {
                    refCondition.Already_Invoiced__c -= (item.Invoice_Value__c * conversionRate).setScale(2);
                    if(isPrinted) {
                        refCondition.Already_Invoiced_Edited__c -= (item.Invoice_Value__c * conversionRate).setScale(2);
                    }
                }
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            if(conditionMap.size() > 0) update conditionMap.values(); 
        } catch (Exception e) {
            // Rollback everything in case of error.
            Database.rollback(sp);
        }
    }
}