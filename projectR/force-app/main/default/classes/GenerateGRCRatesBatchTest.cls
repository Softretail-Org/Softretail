@isTest
private class GenerateGRCRatesBatchTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c store;
    private static Orga_HE__c department;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
            insert region;
            // Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
            insert country;
            // Create Legal Form.
            Orga_BU__c legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
            legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
	        insert legal;
            // Create Store
            store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
            store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
            insert store;
            // Create Department
            department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Code 1', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1), Purchases_DB_Upper_Starting_Point__c = true);
            insert department;
            
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    // Generate GRC contract for simple data
    static testmethod void calculateGRCContract() {
        init();
        Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = true);
        insert supplier;
        Sup_sup_NegoScope__c negoScope = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create Sections
        Orga_HE__c section1 = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Code 1.1', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = true);
        Orga_HE__c section2 = new Orga_HE__c(Name = 'SEC2', Elt_Code__c = 'Code 1.2', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = true);
        Orga_HE__c section3 = new Orga_HE__c(Name = 'SEC3', Elt_Code__c = 'Code 1.3', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = true);
        List<Orga_HE__c> sections = new List<Orga_HE__c>{section1,section2,section3};
        insert sections;
        List<Supplier_NS_HE__c> negoscopeElements = new List<Supplier_NS_HE__c>();
        for (Orga_HE__c item : sections) {
            Supplier_NS_HE__c NSElement = new Supplier_NS_HE__c(Structure_Element__c = item.Id, Choice__c = 'Include', Sup_sup_NegoScope__c = negoScope.id);
            negoscopeElements.add(NSElement);
        }
        insert negoscopeElements;
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_Numbder__c = 'C001',
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        // Create Policy - Tariff conditions
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(0).getValue();
        Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                                        Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                                        Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ', Index__c = 'Index1');
        insert tariffCondition;
        // Create condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 2.5, Product_Scope__c = negoScope.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id, Value_amt__c = 12, Valid__c = true);
        insert condition;
        
        Test.startTest();
        Database.executeBatch(new GenerateGRCRatesBatch('GenerateGRCRatesBatchTest', country.Id, new List<Id>{contract.Id}, Date.today(), false));
        Test.stopTest();
        
        Integer countGRCHead = [SELECT COUNT() FROM GRC__c];
        System.assertEquals(1, countGRCHead);
        Integer countGRCDetails = [SELECT COUNT() FROM GRC_Contract__c];
        System.assertEquals(3, countGRCDetails);
    }
    // Generate GRC contract for contract without conditions
    static testmethod void test_contractWithoutConditions() {
        init();
        Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = true);
        insert supplier;
        Sup_sup_NegoScope__c negoScope = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create Sections
        Orga_HE__c section1 = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Code 1.1', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = true);
        Orga_HE__c section2 = new Orga_HE__c(Name = 'SEC2', Elt_Code__c = 'Code 1.2', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = true);
        Orga_HE__c section3 = new Orga_HE__c(Name = 'SEC3', Elt_Code__c = 'Code 1.3', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = true);
        List<Orga_HE__c> sections = new List<Orga_HE__c>{section1,section2,section3};
        insert sections;
        List<Supplier_NS_HE__c> negoscopeElements = new List<Supplier_NS_HE__c>();
        for (Orga_HE__c item : sections) {
            Supplier_NS_HE__c NSElement = new Supplier_NS_HE__c(Structure_Element__c = item.Id, Choice__c = 'Include', Sup_sup_NegoScope__c = negoScope.id);
            negoscopeElements.add(NSElement);
        }
        insert negoscopeElements;
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_Numbder__c = 'C001',
                                               Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                               Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        Test.startTest();
        Database.executeBatch(new GenerateGRCRatesBatch('GenerateGRCRatesBatchTest', country.Id, new List<Id>{contract.Id}, Date.today(), false));
        Test.stopTest();
        
        Integer countGRCHead = [SELECT COUNT() FROM GRC__c];
        System.assertEquals(1, countGRCHead);
        Integer countGRCDetails = [SELECT COUNT() FROM GRC_Contract__c];
        System.assertEquals(3, countGRCDetails);
    }
}