@isTest
private class ConditionsListTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;    
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c negoScope;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Brand__c brand;
    private static Supplier_PG_Mapping__c pg;
    private static Orga_BU__c store;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition1;
    
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
            // Create Supplier
            supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active',
                                           Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default NegoScope created on supplier creation
            negoScope = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id LIMIT 1];
            // Create Department
            department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Code 1', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
            insert department;
            // Create Section
            section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Code 1.0', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c =false);
            insert section;
            // Create Brand that automatically related to NS due to trigger
            brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1));
            insert brand;
            // Create PG that automatically related to NS due to trigger
            pg = new Supplier_PG_Mapping__c(Name = supplier.Name + ' PG 1', Brand__c = brand.Id, SNA_Code__c = '001', GIMA_Code__c = '001', Department__c = department.Id, Section__c = section.Id,  Supplier__c = supplier.Id);
            insert pg;
            // Create BU
            store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', CurrencyIsoCode = currencyIsoCode);
            store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
            insert store;
            // Create Contract
            contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_Numbder__c = 'C001',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract');
            insert contract;
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                       Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                       Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
            insert tariffCondition;            
            // Create Condition
            condition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                  Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 1, Product_Scope__c = negoScope.Id,
                                                  BU_Scope__c = country.Id, Contract__c = contract.Id);
            insert condition1;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static ConditionsList initiator() {
        init();
        ConditionsList controller = new ConditionsList();
        try {
            // Create NegoScope
            Sup_sup_NegoScope__c negoScopeChild = new Sup_sup_NegoScope__c(Name = 'Nego Scope Child', Supplier__c = supplier.Id, Is_All_Brands__c = true, Is_All_HE__c = true, Is_All__c = true, Parent_Nego_Scope__c = negoScope.Id);
            insert negoScopeChild;
            // Assign brand to negoscope
            ////Sup_NS_Brand__c negoScopeBrand = new Sup_NS_Brand__c(Sup_Scope_Brand__c = brand.Id, Sup_sup_NegoScope__c = negoScope.Id);
            ////insert negoScopeBrand;
            // Create negoScope Element
            Supplier_NS_HE__c negoScopeElement = new Supplier_NS_HE__c( Name = 'Nego Scope 1_Elt Code 2-PS12', Choice__c = 'Include', Sup_sup_NegoScope__c = negoScope.Id, Structure_Element__c = section.Id);
            insert negoScopeElement;
            // Create Sup_NS_PG__c
            ////Sup_NS_PG__c negoScopePG = new Sup_NS_PG__c(Sup_PG__c = pg.Id, Sup_sup_NegoScope__c = negoScope.Id);
            ////insert negoScopePG;
            
            controller.selectedSupplierId = supplier.Id;
            controller.condIndexno = 0;
            controller.NSIndexno = 0;
            controller.SearchContract();
            controller.runSearch();
            controller.currentWrapperDiscount = new ConditionsList.WrapperDiscountList();
            controller.currentWrapperDiscount.discount = condition1;
            controller.currentWrapperDiscount.toInsert = FALSE;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
        return controller;
    }
    
    static testMethod void test_constructor() {
        Integer currentYear = Integer.valueOf(Date.today().year());
        ConditionsList controller = new ConditionsList();
        System.assertEquals(currentYear, controller.selectedNegoYear);
    }
    
    static testMethod void test_generateInvoice() {
        ConditionsList controller = initiator();
        controller.generateInvoice();
        System.assertEquals(1, controller.wDiscList.size());
    }
    
    static testMethod void test_findSupplier() {
        init();
        Sup_Supplier__c supplier2 = new Sup_Supplier__c(Name = 'abc D11D efg', Code__c = 'XXX');
        insert supplier2;
        ConditionsList controller = new ConditionsList();
        List<Sup_Supplier__c> sup = (List<Sup_Supplier__c>)JSON.deserialize(ConditionsList.findSupplier('D11D'), List<Sup_Supplier__c>.class);
        
        System.assertEquals(1, sup.size());
    }
    
    static testMethod void test_getListYears() {
        ConditionsList controller = new ConditionsList();        
        System.assertEquals(6, controller.getListYears().size());
    }
    
    static testMethod void test_SaveMultipleDiscounts() {
        ConditionsList controller = initiator();
        controller.SaveMultipleDiscounts();
        System.assertEquals(1, controller.wDiscList.size());
    }
    
    static testMethod void test_DeleteMultipleDiscounts() {
        ConditionsList controller = initiator();
        controller.wDiscList[0].isSelected = true;
        controller.DeleteMultipleDiscounts();
        System.assertEquals(1, controller.wDiscList.size());
    }
    
    static testMethod void test_fillProductScopeLst() {
        ConditionsList controller = initiator();
        controller.fillProductScopeLst();
        System.assertEquals(2, controller.wNSLst.size());
    }
    
    static testMethod void test_chooseProductScope() {
        ConditionsList controller = initiator();
        controller.fillProductScopeLst();
        controller.chooseProductScope();
        System.assertEquals(2, controller.wNSLst.size());
    }
    
    static testMethod void test_showPopup() {
        ConditionsList controller = initiator();
        controller.showPopup();
        controller.showPopup2();
        controller.showPopup3();
        controller.showPopup4();
        controller.showPopup5();
        controller.showPopup6();
        Boolean popup =  controller.displayPopup && controller.displayPopup2 && controller.displayPopup3 && controller.displayPopup4 && controller.displayPopup5 && controller.displayPopup6;
        System.assertEquals(true, popup);
    }
    
    static testMethod void test_closePopup() {
        ConditionsList controller = initiator();
        controller.popupName = 'distributeAmountPopup';
        controller.closePopup();
        controller.popupName = 'commentPopup';
        controller.closePopup();
        controller.popupName = 'slabPopup';
        controller.closePopup();
        controller.closePopup2();
        controller.fillProductScopeLst();
        controller.closePopup3();
        controller.closePopup4();
        controller.closePopup5();
        controller.closePopup6();
        Boolean popup =  controller.displayPopup || controller.displayPopup2 || controller.displayPopup3 || controller.displayPopup4 || controller.displayPopup5 || controller.displayPopup6;
        System.assertEquals(false, popup);
    }
    
    static testMethod void test_addNewNS() {
        ConditionsList controller = initiator();
        controller.fillProductScopeLst();
        controller.addNewNS();
        System.assertEquals(3, controller.wNSLst.size());
    }
    
    static testMethod void test_SaveOneDiscount() {
        ConditionsList controller = initiator();
        controller.SaveOneDiscount();
        System.assert(true);
    }
    
    static testMethod void test_getprefixCond() {
        ConditionsList controller = initiator();
        System.assertEquals(controller.getprefixCond(), controller.getprefixCond());
    }
    
    static testMethod void test_loadDispatchDetails() {
        ConditionsList controller = initiator();
        controller.loadDispatchDetails(0);
        System.assertEquals(0, controller.wDiscList[0].distpatchDetailList.size());
    }
    
    static testMethod void test_others() {
        ConditionsList controller = initiator();
        controller.calculateYTD();
        controller.dispatching();
        System.assert(true);
    }
 
   static testMethod void test_autoDistributeCurrentTomonth() {
        ConditionsList controller = initiator();
        controller.loadDispatchDetails(0);
        Purchases_Flow_PG__c purchaseFlow1 = new Purchases_Flow_PG__c(CurrencyIsoCode = currencyIsoCode, Supplier__c = supplier.Id, BU__c = country.Id, PG__c = pg.Id, Year__c = year, Supplier_Nego_Scope__c = negoScope.Id, TO1__c = 100, TO2__c = 200, TO3__c = 250, TO4__c = 10, TO5__c = 150,TO6__c = 100, TO7__c = 130, TO8__c = 50, TO9__c = 10, TO10__c = 190, TO11__c = 150, TO12__c = 20);
     	insert new List<Purchases_Flow_PG__c> {purchaseFlow1};
        controller.option = 'Purchases of the month';
        controller.updateAutoDistribute();
        System.assert(true);
    } 
    static testMethod void test_autoDistributeEqual() {

        ConditionsList controller = initiator();
        controller.loadDispatchDetails(0);
        Purchases_Flow_PG__c purchaseFlow1 = new Purchases_Flow_PG__c(CurrencyIsoCode = currencyIsoCode, Supplier__c = supplier.Id, BU__c = country.Id, PG__c = pg.Id, Year__c = year, Supplier_Nego_Scope__c = negoScope.Id, TO1__c = 100, TO2__c = 200, TO3__c = 250, TO4__c = 10, TO5__c = 150,TO6__c = 100, TO7__c = 130, TO8__c = 50, TO9__c = 10, TO10__c = 190, TO11__c = 150, TO12__c = 20);
     	insert new List<Purchases_Flow_PG__c> {purchaseFlow1};
        controller.option = 'Equally';
        controller.updateAutoDistribute();
        System.assert(true);
    }

}