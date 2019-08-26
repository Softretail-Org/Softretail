public class Trg_Exec_Invoice_Handler {
    
    // Before insert.
    public static void OnBeforeInsert(List<Invoice__c> newInvoices) {
    	generateInvoiceNumber(newInvoices);
        assignStockOwner(newInvoices);
    }
    // Before update.
    public static void OnBeforeUpdate(List<Invoice__c> newInvoices) {
    	generateInvoiceNumber(newInvoices);
    	// Set Autonum__c to null when Invoice_Number__c is null
        for (Invoice__c item : newInvoices) {
            if (item.Invoice_Number__c == null) item.Autonum__c = null;
        }
    }
    // After update.
    public static void OnAfterUpdate(List<Invoice__c> newInvoices, Map<Id, Invoice__c> oldInvoiceMap) {
        // Push into list only invoices with updated values or status changed
        // TODO: filter also when value is changed
        List<Invoice__c> invoicesWithValueModified = new List<Invoice__c>();
        for (Invoice__c item : newInvoices) {
            if (/*item.Inv_value__c != oldInvoiceMap.get(item.Id).Inv_value__c ||*/ item.Inv_Status__c != oldInvoiceMap.get(item.Id).Inv_Status__c) {
                invoicesWithValueModified.add(item);
            }
        }
        if(invoicesWithValueModified.size() > 0)
            reCalculateAlreadyInvoiced(invoicesWithValueModified, oldInvoiceMap);
    }
    // Before delete.
    public static void OnBeforeDelete(List<Invoice__c> oldInvoices) {
        // TODO: SHOULD BE MOVED TO AFTER DELETION BUT WE NEED A WAY TO CONSERVE THE DATA FIRST.
    	reCalculateAlreadyInvoiced(oldInvoices, null);
    }
    // Invoice number Generation based on Invoice_Number_Prefix__c.
    private static void generateInvoiceNumber(List<Invoice__c> newInvoices) {
        List<Invoice__c> currentInvoices = newInvoices.clone(); // because newInvoices list is read-only
        Integer diffDate;
        // Loop over new invoices to find the number prefixes.
        Integer j = currentInvoices.size() - 1, count = 0, max;
        // filter only records with status = 'Printed' and have no invoice number
        for(Integer i = j; i >= 0; i--) {
            if(currentInvoices.get(i).Inv_Status__c != 'Printed' || currentInvoices.get(i).Invoice_Number__c != null)
                currentInvoices.remove(i);
        }
        Map<String, Integer> invoicesNumberPrefixMap = new Map<String, Integer>();
        // Push distinct prefixes in a map.
        for(Invoice__c inv : currentInvoices) {
            String key = inv.Invoice_Number_Prefix__c;
            // TODO: handle the case when no prefix
            if(key != null && !String.isEmpty(key) && !invoicesNumberPrefixMap.containsKey(key)) {
                invoicesNumberPrefixMap.put(key, 1);
            }
        }
        // Loop over prefixes to find the correponding max counter.
        for(String s : invoicesNumberPrefixMap.keySet()) {
            String query = 'SELECT Invoice_Number__c, Autonum__c FROM Invoice__c WHERE Invoice_Number_Prefix__c = \'' + String.escapeSingleQuotes(s) + '\' AND Autonum__c <> null ORDER BY Autonum__c DESC LIMIT 1';
            List<Invoice__c> invoices = Database.query(query);
            if(!invoices.isEmpty() && invoices.get(0).Invoice_Number__c != null) {
                max = Integer.valueOf(String.valueOf(invoices.get(0).Autonum__c));
                invoicesNumberPrefixMap.put(s, max + 1);
            }
        }
        for(Invoice__c inv : currentInvoices) {
            // Set an auto invoice number based on the max for each prefix.
            if(inv.Invoice_Number__c == null && inv.Doc_type__c == 'Invoice') {
                count = invoicesNumberPrefixMap.get(inv.Invoice_Number_Prefix__c);
                inv.Invoice_Number__c = inv.Invoice_Number_Prefix__c + string.valueof(count).leftPad(6, '0');
                inv.Autonum__c = count;
                // Increment the counter and update related value in the map.
                count++;
                invoicesNumberPrefixMap.put(inv.Invoice_Number_Prefix__c, count);
            }
            diffDate = 30; // default 30 days
            if(inv.Inv_Date__c != null && inv.Inv_DueDate__c != null) {
                diffDate = inv.Inv_Date__c.daysBetween(inv.Inv_DueDate__c);
            }
            // Set Dates for records not inserted from invoice group
            if(inv.Linked_Invoice_group__c == null) {
                if(GlobalSettingsManager.loadGlobalSettings().allowUpdatingPrintDateOnPrint) { // Used in SEB
                    inv.Inv_PrintedDate__c = inv.Inv_Date__c;
                } else {
                    inv.Inv_PrintedDate__c = System.today();
                }
                if(GlobalSettingsManager.loadGlobalSettings().allowUpdatingInvoiceDateOnPrint) { // Used in MPX
                    inv.Inv_Date__c = System.today();
                    inv.Inv_DueDate__c = inv.Inv_Date__c.addDays(diffDate);
                }
            }
        }
    }
        
    // Re-calculate the Already Invoiced of the condition when deleting an Invoice.
    private static void reCalculateAlreadyInvoiced(List<Invoice__c> oldInvoices, Map<Id, Invoice__c> oldInvoiceMap) {
        // Flag to check if is in insert or update mode
        Boolean isInsertOrUpdateMode = oldInvoiceMap != null;
        // Load map of currencies with exchange rate
        Map<String, Double> currencies = NegoptimHelper.getCurrencyMap();
        // Get the sum of affected conditions to substract from the already invoice value
        Map<Id, List<AggregateResult>> conditionInvoiceDetailsMap = new Map<Id, List<AggregateResult>>();
        for(AggregateResult item : [SELECT Discount__c Id, Invoice__r.Inv_Status__c status, SUM(Invoice_Value__c) Total_Invoice_Value
                                    FROM Invoice_Detail__c
                                    WHERE Invoice__c IN :oldInvoices
                                    AND Discount__c != null
                                    GROUP BY Discount__c, Invoice__r.Inv_Status__c])
        {
            Id conditionId = (Id)item.get('Id');
            if(conditionInvoiceDetailsMap.containsKey(conditionId)) {
                conditionInvoiceDetailsMap.get(conditionId).add(item);
            } else {
                conditionInvoiceDetailsMap.put(conditionId, new List<AggregateResult>{item});
            }
        }
        // Load Already_Invoiced__c and Already_Invoiced_Edited__c for all affected conditions by id
        List<Contract_Discount__c> conditions = [SELECT Id, CurrencyIsoCode, Already_Invoiced__c, Already_Invoiced_Edited__c
                                                 FROM Contract_Discount__c
                                                 WHERE Id = :conditionInvoiceDetailsMap.keySet()];
        Decimal alreadyInvoiced = 0;
        // Get corresponding total invoice line value for each condition to substract from the original value.
        for(Contract_Discount__c condition : conditions) {
            Decimal conversionRate = currencies.get(condition.CurrencyIsoCode);
            for(AggregateResult ar : conditionInvoiceDetailsMap.get(condition.Id)) {
                if(ar.get('Total_Invoice_Value') != null) {
                    alreadyInvoiced = (Decimal.valueOf(String.valueOf(ar.get('Total_Invoice_Value'))) * conversionRate).setScale(2);
                }
                if(!isInsertOrUpdateMode) {
                    condition.Already_Invoiced__c = (condition.Already_Invoiced__c != null) ? condition.Already_Invoiced__c - alreadyInvoiced : 0;
                }
                if(ar.get('status') == 'Printed') { // calculate Already_Invoiced_Edited__c only when invoice is in status printed
                    if(isInsertOrUpdateMode) {
                        condition.Already_Invoiced_Edited__c = (condition.Already_Invoiced_Edited__c != null) ? condition.Already_Invoiced_Edited__c + alreadyInvoiced : alreadyInvoiced;
                    } else {
                        condition.Already_Invoiced_Edited__c = (condition.Already_Invoiced_Edited__c != null) ? condition.Already_Invoiced_Edited__c - alreadyInvoiced : 0;
                    }
                }
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            update conditions;
        } catch (Exception e) {
            // Rollback everything in case of error.
            Database.rollback(sp);
        }
    }
    /**
     * Assign stock owner BU to invoices 
     * @param List<Invoice__c>.
     * On Before Insert
     **/
    private static void assignStockOwner(List<Invoice__c> newInvoices) {
        Set<Id> contractIdSet = new Set<Id>();
        for (Invoice__c item : newInvoices) {
            if(item.Stock_Owner__c == null && item.Inv_Contract__c != null) {
                contractIdSet.add(item.Inv_Contract__c);
            }
        }
        if(!contractIdSet.isEmpty()) {
            Map<Id, Contract__c> contractsMap =  new Map<Id, Contract__c>([SELECT Id, Stock_Owner__c 
                                                                           FROM Contract__c
                                                                           WHERE Id IN :contractIdSet]);
            for (Invoice__c item : newInvoices) {
                if(item.Stock_Owner__c == null && item.Inv_Contract__c != null) {
                    item.Stock_Owner__c = contractsMap.get(item.Inv_Contract__c).Stock_Owner__c;
                }
            }
        }
    }
}