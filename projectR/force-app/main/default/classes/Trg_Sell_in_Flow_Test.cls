@isTest
private class Trg_Sell_in_Flow_Test {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Brand__c brand;
    private static Product2 product;
    private static Supplier_PG_Mapping__c pg;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = new Country_List__c(Name = 'SEB', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
            insert region;
            // Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.Country__c = country.Name;
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
            insert country;            
            // Create Supplier
            supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active',
                                           Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default negoscope created on supplier creation
            NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id LIMIT 1];
            // make NS Acc_Country__c = Contract_BU__r.Country__c
            NS.Acc_Country__c = country.Name;
            update NS;
            // Create Department
            department = TestDataFactory.createDepartment(true, rootId);
            // Create Section        
            section = TestDataFactory.createSection(true, department.Id);
            // Create brand
            brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1));
            insert brand;
            // insert product
            product = new Product2(Name = 'P001', ProductCode = 'P001', Category__c = section.Id, Product_MasterSupplier__c = supplier.Id);
            insert product;
            // Create PG
            pg = new Supplier_PG_Mapping__c(Name = supplier.Name + ' PG1', SNA_Code__c = '001', GIMA_Code__c = '001', 
                                            Department__c = department.Id, Section__c = section.Id,  Supplier__c = supplier.Id, 
                                            Brand__c = brand.Id, Product__c = product.Id, CurrencyIsoCode = currencyIsoCode);
            insert pg;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    @isTest static void updateSellinFlowWithCorrectContract() {
        init();
        // create contract
        Contract__c contract = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C123',
                                               Contract_BDate__c = date.newInstance(year, 2, 1), Contract_EDate__c = date.newInstance(year, 6, 1), Duration__c = 5, Contract_BU__c = country.Id,
                                               Contract_Type__c = 'Contract', D_N__c = 'N', Duration_type__c = 'Month', BU_Source__c = country.Id);			
        insert contract;
        // Create sell in flow
        Sell_in_Flow__c sellIn = new Sell_in_Flow__c(BU__c = country.Id, Structure_level__c = section.Id, Mvt_Purch_Product__c = product.Id, 
                                                     Supplier__c = supplier.Id, Invoice_Net_Amount_woTax__c = 100, Footer_Order_Discount__c = 20,
                                                     Invoice_Quantity__c = 5, Unit_Cost__c = 2, Master_BU__c = country.Id,
                                                     Invoice_Date__c = Date.newInstance(year, 3, 1), Order_Date__c = Date.newInstance(year, 3, 10),
                                                     Gross_Price__c = 200, List_price__c = 100, Net_Price__c = 50);
        Sell_in_Flow__c sellIn1 = new Sell_in_Flow__c(BU__c = country.Id, Structure_level__c = section.Id, Mvt_Purch_Product__c = product.Id, 
                                                      Supplier__c = supplier.Id, Invoice_Net_Amount_woTax__c = 100, Footer_Order_Discount__c = 20,
                                                      Invoice_Quantity__c = 5, Unit_Cost__c = 2, Master_BU__c = country.Id,
                                                      Invoice_Date__c = Date.newInstance(year, 2, 1), Order_Date__c = Date.newInstance(year, 3, 10),
                                                      Gross_Price__c = 200, List_price__c = 100, Net_Price__c = 50);
        insert new List<Sell_in_Flow__c> {sellIn, sellIn1};
        Sell_in_Flow__c sellIn2 = new Sell_in_Flow__c(BU__c = country.Id, Structure_level__c = section.Id, Mvt_Purch_Product__c = product.Id, 
                                                      Supplier__c = supplier.Id, Invoice_Net_Amount_woTax__c = 100, Footer_Order_Discount__c = 20,
                                                      Invoice_Quantity__c = 5, Unit_Cost__c = 2, Master_BU__c = country.Id,
                                                      Invoice_Date__c = Date.newInstance(year, 2, 1), Order_Date__c = Date.newInstance(year, 3, 10),
                                                      Gross_Price__c = 200, List_price__c = 100, Net_Price__c = 50);
        insert sellIn2;
        // Validation Test
        sellIn = [SELECT Id, Contract__c, Gross_Price__c, List_price__c, Net_Price__c , Unit_Cost__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        pg = [SELECT Id, Last_Gross_Price__c, Last_List_Price__c, Last_Net_Price__c FROM Supplier_PG_Mapping__c WHERE Id = :pg.Id];
        product = [SELECT Id, Last_Unit_Cost__c FROM Product2 WHERE Id = :product.Id];
        System.assertEquals(contract.Id, sellIn.Contract__c);
        /*System.assertEquals(pg.Last_Gross_Price__c, sellIn.Gross_Price__c);
        System.assertEquals(pg.Last_List_Price__c, sellIn.List_price__c);
        System.assertEquals(pg.Last_Net_Price__c, sellIn.Net_Price__c);
        System.assertEquals(product.Last_Unit_Cost__c, sellIn.Unit_Cost__c);*/
    }
    @isTest static void updateSellinFlowWithTemporaryContract() {
        init();
        // create contract
        Contract__c contract1 = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C123',
                                               Contract_BDate__c = date.newInstance(year, 2, 1), Contract_EDate__c = date.newInstance(year, 6, 1), Duration__c = 5, Contract_BU__c = country.Id,
                                               Contract_Type__c = 'Contract', D_N__c = 'N', Duration_type__c = 'Month', BU_Source__c = country.Id);			
        insert contract1;
        // Create sell in flow
        Sell_in_Flow__c sellIn = new Sell_in_Flow__c(BU__c = null, Structure_level__c = section.Id, Mvt_Purch_Product__c = product.Id, 
                                                     Supplier__c = supplier.Id, Invoice_Net_Amount_woTax__c = 100, Footer_Order_Discount__c = 20,
                                                     Invoice_Quantity__c = 5, Unit_Cost__c = 2, Master_BU__c = country.Id,
                                                     Invoice_Date__c = Date.newInstance(year, 3, 1), Order_Date__c = Date.newInstance(year, 3, 10));
        Test.startTest();
        insert sellIn;
        Test.stopTest();
        // Validation Test
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(contract1.Id, sellIn.Contract__c);
    }
    @isTest static void updateSellinFlowWithCorrectContractRelatedToParentBU() {
        init();
        // Create Legal Form.
        Orga_BU__c legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
        // Create store.
        Orga_BU__c store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', BU_ODate__c = date.newInstance(year, 1, 1),
                                          Country_origin__c = country.Id, Format_Origin__c = 'Supermarket', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert store;
        // create contract
        Contract__c contract1 = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001',
                                                Contract_BDate__c = date.newInstance(year, 2, 1), Contract_EDate__c = date.newInstance(year, 6, 1), Duration__c = 5,
                                                Contract_Type__c = 'Contract', D_N__c = 'N', Duration_type__c = 'Month', Contract_BU__c = country.Id, BU_Source__c = country.Id);			
        insert contract1;
        // Create sell in flow
        Sell_in_Flow__c sellIn = new Sell_in_Flow__c(BU__c = store.Id, Structure_level__c = section.Id, Mvt_Purch_Product__c = product.Id, 
                                                     Supplier__c = supplier.Id, Invoice_Net_Amount_woTax__c = 100, Footer_Order_Discount__c = 20,
                                                     Invoice_Quantity__c = 5, Unit_Cost__c = 2, Master_BU__c = country.Id,
                                                     Invoice_Date__c = Date.newInstance(year, 3, 1), Order_Date__c = Date.newInstance(year, 3, 10));
        Test.startTest();
        insert sellIn;
        Test.stopTest();
        // Validation Test
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(contract1.Id, sellIn.Contract__c);
    }
}