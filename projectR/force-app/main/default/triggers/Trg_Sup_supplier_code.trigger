// When a new line item is added to an Sup_supplier_code__c, this trigger set the value of Default__c
// to true, and make all existing records related to the same Supplier__c by Default__c = false.
// + Set Sup_Supplier__c.Default_Supplier_Acc_Code__c = Sup_supplier_code__c.Name
trigger Trg_Sup_supplier_code on Sup_supplier_code__c (before insert) {
    
    // For every Sup_supplier_code__c record, add its associated Supplier__c entry
    // to a set so there are no duplicates.
    Set<Id> supplierIds = new Set<Id>();
    Map<Id, String> newSupplierCodesMap = new Map<Id, String>();
    for (Sup_supplier_code__c item : Trigger.new) {
        // Set Default__c for every new record to true
        item.Default__c = true;
        newSupplierCodesMap.put(item.Supplier__c, item.Name);
        supplierIds.add(item.Supplier__c);
    }
    
    if (supplierIds.size() > 0) {
        // Query the existing Sup_supplier_code__c for their associated Supplier__c
        List<Sup_supplier_code__c> existingSupplierCode = new List<Sup_supplier_code__c>();
        for (Sup_supplier_code__c item : [SELECT Id FROM Sup_supplier_code__c WHERE Supplier__c IN :supplierIds AND Default__c <> false]) {
            item.Default__c = false;
            existingSupplierCode.add(item);
        }
        if (existingSupplierCode.size() > 0) {
            Database.update(existingSupplierCode);
        }
        // Query the Sup_Supplier__c for their associated Supplier__c to set Default_Supplier_Acc_Code__c
        List<Sup_Supplier__c> suppliers = new List<Sup_Supplier__c>();
        for (Sup_Supplier__c item : [SELECT Id FROM Sup_Supplier__c WHERE Id in :supplierIds]) {
            item.Default_Supplier_Acc_Code__c = newSupplierCodesMap.get(item.Id);
            suppliers.add(item);
        }
        if (suppliers.size() > 0) {
            Database.update(suppliers);
        }
    }
}