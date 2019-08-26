/**
 * Called from process builder to
 * run procedure of update dispatch details status
 * */
global class AccountingClosingUpdateAction {

    @InvocableMethod(label='Accounting Closing Update Action' description='Accounting Closing Update Action.')
    public static void runUpdateDispatchStatuses(List<Accounting_Closing__c> accountingClosing) {
        Set<Id> buIds = new Set<Id>();
        Set<Integer> years = new Set<Integer>();
        Integer month;
        for(Accounting_Closing__c item : accountingClosing) { // here we loop on list of one item
            buIds.add(item.Business_Unit__c);
            years.add(item.Closing_Date__c.year());
            // should be one value
            month = item.Closing_Date__c.month();
        }
        // Run the batch to set status of dispatch details to updated
        Database.executeBatch(new SetDispatchDetailsStatusBatch('Accounting Closing Update Action', new List<Id>(buIds),
                                                                new List<Integer>(years), month));
    }
}