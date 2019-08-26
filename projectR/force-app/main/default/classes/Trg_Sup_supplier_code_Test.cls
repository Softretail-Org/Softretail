@isTest
private class Trg_Sup_supplier_code_Test {

    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Supplier__c supplier;
    
    static public void init() {
        try {
            year = System.Today().year();
            // Root Element Id.
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Get all recortd type ids for Orga_BU__c SObject
            Map<String, Id> buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Orga_BU__c.SObjectType);
            // Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = buRTIds.get('Region');
            insert region;
            // Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = buRTIds.get('Country');
            insert country;
            // Create Department.
            department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Code 1', Parent_Element__c = rootId, Level__c = 1,
                                        Status_BDate__c = date.newInstance(year, 1, 1),
                                        Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
            insert department;
            // Create Section.
            section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Code 1.0', Parent_Element__c = department.Id, Level__c = 2,
                                     Status_BDate__c = date.newInstance(year, 1, 1),
                                     Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c =false);
            insert section;
            // Create supplier.
            supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
                                           Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    static testmethod void createSupplier_Code_Success() {
        init();
        Sup_supplier_code__c sc = new Sup_supplier_code__c(Supplier__c = supplier.Id, Type__c = 'Accounting', Name = 'TEST001',
                                                           Supplier_Name__c = supplier.Name + '001', Status__c = 'Active', Default__c = false,
                                                           Status_BDate__c = Date.today());
        insert sc;
        Sup_supplier_code__c newSC = [SELECT Default__c FROM Sup_supplier_code__c WHERE Id = :sc.Id];
        System.assertEquals(true, newSC.Default__c);
        Sup_Supplier__c supplierUpdated = [SELECT Default_Supplier_Acc_Code__c FROM Sup_Supplier__c WHERE Id = :supplier.Id];
        System.assertEquals('TEST001', supplierUpdated.Default_Supplier_Acc_Code__c);
    }
}