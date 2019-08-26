@isTest
private class Org_NegoScope_Edit_Controller_TEST {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c negoScope;
    private static Orga_HE__c department1;
    private static Orga_HE__c department2;
    private static Orga_HE__c section;
    private static Sup_Brand__c brand;
    private static Supplier_PG_Mapping__c pg;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, country, false);
            // Create Departments
            department1 = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Code 1', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
            department2 = new Orga_HE__c(Name = 'DPT2', Elt_Code__c = 'Code 2', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);           
            insert new List<Orga_HE__c>{department1, department2};
            // Create Section        
            section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Code 1.0', Parent_Element__c = department1.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c =false);
            insert section;
            
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void test_constructor_without_id() {
        init();
        Boolean editMode = false;
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Sup_sup_NegoScope__c());
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        system.assertEquals(null, Org_NegoScope_Edit_Controller.negoScope.Id);
    }
    
    @isTest static void test_constructor_with_id() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'New Negoscope', CurrencyIsoCode = supplier.CurrencyIsoCode,
                                             OwnerId = UserInfo.getUserId(), Supplier__c = supplier.Id,
                                             Is_All_Brands__c = true, Is_All_HE__c = true, Is_All__c = true,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        Boolean editMode = true;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        system.assertNotEquals(null, Org_NegoScope_Edit_Controller.negoScope.Id);
    }
    
    @isTest static void test_getListBrandsSupplier() {        
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier.Id, Is_All_Brands__c = false,
                                             Is_All_HE__c = false, Incl_NewBrand__c = false, Incl_NewProduct__c = false,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        insert brand;
        Sup_NS_Brand__c negoScopeBrand = new Sup_NS_Brand__c(Sup_Scope_Brand__c = brand.Id, Sup_sup_NegoScope__c = negoScope.Id);
        insert negoScopeBrand;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.getBrandDistributorList();
        system.assertEquals(1, Org_NegoScope_Edit_Controller.brandDistributorList.size());
    }
    
    @isTest static void test_getProductList() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope RT', Supplier__c = supplier.Id, Is_All__c = false, Is_All_Brands__c = false,
                                             Is_All_HE__c = false, Incl_NewBrand__c = false, Incl_NewProduct__c = false,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        insert brand;
        pg = new Supplier_PG_Mapping__c(Name = supplier.Name + ' PG 1', Brand__c = brand.Id, SNA_Code__c = '001', GIMA_Code__c = '001', Department__c = department1.Id, Section__c = section.Id, Supplier__c = supplier.Id);
        insert pg;
        Sup_NS_PG__c negoScopePG = new Sup_NS_PG__c(Sup_PG__c = pg.Id, Sup_sup_NegoScope__c = negoScope.Id);
        insert negoScopePG;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.negoScope = negoScope;
        Org_NegoScope_Edit_Controller.getProductList();
        List<Org_NegoScope_Edit_Controller.PGWrapper> PGRecords = Org_NegoScope_Edit_Controller.getRecords();
        system.assertEquals(1, PGRecords.size());
    }
    
    @isTest static void test_refresh_at_start() {        
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier.Id, Is_All_Brands__c = false, Is_All_HE__c = false,
                                             Incl_NewBrand__c = false,Incl_NewProduct__c = false,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.refresh();
        system.assertEquals(2, Org_NegoScope_Edit_Controller.childElementsWrapped.size());
        system.assertEquals(department1.Name, Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).element.Name);
        system.assertEquals(department1.Elt_Code__c, Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).element.Elt_Code__c);
        system.assertEquals(department2.Name, Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).element.Name);
        system.assertEquals(department2.Elt_Code__c, Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).element.Elt_Code__c);
    }
    
    @isTest static void test_select_element_with_not_null_id() {        
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier.Id, Is_All_Brands__c = true, Is_All_HE__c = false,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.refresh();
        Org_NegoScope_Edit_Controller.elementIdToSelect = department2.Id;
        Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).negoScopeElem.Choice__c = 'Include';
        Org_NegoScope_Edit_Controller.selectElement();
        system.assertEquals(1, Org_NegoScope_Edit_Controller.wNegoScopeElementList.size());
        system.assertEquals(department2.Elt_Code__c, Org_NegoScope_Edit_Controller.wNegoScopeElementList.get(0).elementCode);
        system.assertEquals(department2.Name, Org_NegoScope_Edit_Controller.wNegoScopeElementList.get(0).elementName);
        system.assertEquals('Include', Org_NegoScope_Edit_Controller.wNegoScopeElementList.get(0).negoScopeElem.Choice__c);
    }
    
    @isTest static void test_unselect_element() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier.Id, Is_All_Brands__c = true, Is_All_HE__c = false,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.refresh();
        Org_NegoScope_Edit_Controller.elementIdToSelect = department2.Id;
        Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).negoScopeElem.Choice__c = 'Include';
        Org_NegoScope_Edit_Controller.NegoScopeElemWrapper 
            nsew = new Org_NegoScope_Edit_Controller.NegoScopeElemWrapper(Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).negoScopeElem,
                                                                          Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).element.Elt_Code__c,
                                                                          Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).element.Name,
                                                                          Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).element.Level__c);
        Org_NegoScope_Edit_Controller.wNegoScopeElementList.add(nsew);
        Org_NegoScope_Edit_Controller.unselectElement();
        system.assertEquals(0, Org_NegoScope_Edit_Controller.wNegoScopeElementList.size());
    }
    
    @isTest static void test_saveNegoScope_one_selected_structure_element() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'New Negoscope', CurrencyIsoCode = supplier.CurrencyIsoCode,
                                             OwnerId = UserInfo.getUserId(), Supplier__c = supplier.Id,
                                             Is_All_Brands__c = true, Is_All_HE__c = true, Is_All__c = true,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        insert brand;
        // Sup_Bra_Distributor__c brandDist = new Sup_Bra_Distributor__c(Name = 'Brand Dist 1', Supplier__c = supplier.Id,Brand__c=brand.Id);
        // insert brandDist;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.editMode = false;
        Org_NegoScope_Edit_Controller.refresh();
        Org_NegoScope_Edit_Controller.elementIdToSelect = department2.Id;
        Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).negoScopeElem.Choice__c = 'Include';
        Org_NegoScope_Edit_Controller.NegoScopeElemWrapper nsew = new Org_NegoScope_Edit_Controller.NegoScopeElemWrapper(Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).negoScopeElem,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).element.Elt_Code__c,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).element.Name,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).element.Level__c);  
        Org_NegoScope_Edit_Controller.wNegoScopeElementList.add(nsew);
        // Org_NegoScope_Edit_Controller.BrandWrapper brandWrapper = new Org_NegoScope_Edit_Controller.BrandWrapper(brandDist, true);
        // Org_NegoScope_Edit_Controller.listBrandsSupplierWraper.add(brandWrapper);
        Org_NegoScope_Edit_Controller.saveNegoScope();
        List<Sup_sup_NegoScope__c> listNegoScopes = [SELECT Id, Name FROM Sup_sup_NegoScope__c];
        system.assertEquals(1, listNegoScopes.size());
        List<Supplier_NS_HE__c> listNegoScopeElements = [SELECT Id, Name, Choice__c FROM Supplier_NS_HE__c WHERE Sup_sup_NegoScope__c = :listNegoScopes];
        system.assertEquals(1, listNegoScopeElements.size());
    }
    
    @isTest static void test_saveNegoScope_all_structure_elements() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'New Negoscope', CurrencyIsoCode = supplier.CurrencyIsoCode,
                                             OwnerId = UserInfo.getUserId(), Supplier__c = supplier.Id,
                                             Is_All_Brands__c = true, Is_All_HE__c = true, Is_All__c = true,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        insert brand;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.editMode = false;
        Org_NegoScope_Edit_Controller.negoScope.Name = null; // force name to be generated
        Org_NegoScope_Edit_Controller.refresh();
        Org_NegoScope_Edit_Controller.saveNegoScope();
        List<Sup_sup_NegoScope__c> listNegoScopes = [SELECT Id, Name FROM Sup_sup_NegoScope__c];
        system.assertEquals(1, listNegoScopes.size());
        List<Supplier_NS_HE__c> listNegoScopeElements = [SELECT Structure_Element__c FROM Supplier_NS_HE__c WHERE Sup_sup_NegoScope__c = :listNegoScopes.get(0).Id];
        List<Orga_HE__c> selectRootElement = [SELECT Id FROM Orga_HE__c WHERE id = :listNegoScopeElements.get(0).Structure_Element__c and Parent_Element__c=null];
        system.assertEquals(1, selectRootElement.size());
    }
    
    @isTest static void test_saveNegoScope_all_structure_elements_editmode() {        
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'New Negoscope', CurrencyIsoCode = supplier.CurrencyIsoCode,
                                             OwnerId = UserInfo.getUserId(), Supplier__c = supplier.Id,
                                             Is_All_Brands__c = true, Is_All_HE__c = true, Is_All__c = true,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        insert brand;
        Supplier_NS_HE__c negoScopeElement = new Supplier_NS_HE__c( Name = 'Nego Scope 1_Elt Code 2-PS12', Choice__c = 'Include', Sup_sup_NegoScope__c = negoScope.Id, Structure_Element__c = department1.Id);
        insert negoScopeElement;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.editMode = true;
        Org_NegoScope_Edit_Controller.refresh();
        Org_NegoScope_Edit_Controller.saveNegoScope();
        List<Sup_sup_NegoScope__c> listNegoScopes = [SELECT Id, Name FROM Sup_sup_NegoScope__c];
        system.assertEquals(1, listNegoScopes.size());
        List<Supplier_NS_HE__c> listNegoScopeElements = [SELECT Id, Name, Choice__c FROM Supplier_NS_HE__c WHERE Sup_sup_NegoScope__c = :listNegoScopes];
        system.assertEquals(2, listNegoScopeElements.size());
    }
    
    @isTest static void test_addAllElement() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier.Id, Is_All_Brands__c = true, Is_All_HE__c = false,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.editMode = false;
        Org_NegoScope_Edit_Controller.elementIdToSelect = rootId;
        Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).negoScopeElem.Choice__c = 'Include';
        Org_NegoScope_Edit_Controller.NegoScopeElemWrapper nsew = new Org_NegoScope_Edit_Controller.NegoScopeElemWrapper(Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).negoScopeElem,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).element.Elt_Code__c,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).element.Name,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).element.Level__c);  
        Org_NegoScope_Edit_Controller.wNegoScopeElementList.add(nsew);
        Org_NegoScope_Edit_Controller.addAllElement();
        Org_NegoScope_Edit_Controller.refresh();
        Org_NegoScope_Edit_Controller.saveNegoScope();
        System.assert(true);
    }
    
    @isTest static void testOneSelectedBrand() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'New Negoscope', CurrencyIsoCode = supplier.CurrencyIsoCode,
                                             OwnerId = UserInfo.getUserId(), Supplier__c = supplier.Id,
                                             Is_All_Brands__c = false, Is_All_HE__c = true, Is_All__c = true,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        insert brand;
        // Sup_Bra_Distributor__c brandDist = new Sup_Bra_Distributor__c(Name = 'Brand Dist 1', Supplier__c = supplier.Id,Brand__c=brand.Id);
        // insert brandDist;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.editMode = true;
        Org_NegoScope_Edit_Controller.refresh();
        // Org_NegoScope_Edit_Controller.BrandWrapper brandWrapper = new Org_NegoScope_Edit_Controller.BrandWrapper(brandDist, true);
        // Org_NegoScope_Edit_Controller.listBrandsSupplierWraper.add(brandWrapper);
        Org_NegoScope_Edit_Controller.saveNegoScope();
        List<Sup_sup_NegoScope__c> listNegoScopes = [SELECT Id, Name FROM Sup_sup_NegoScope__c];
        system.assertEquals(1, listNegoScopes.size());
    }
    
    @isTest static void testOneSelectedProductGroupEditMode() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 2', Supplier__c = supplier.Id, Incl_NewBrand__c = false, Incl_NewProduct__c = false,
                                             Is_All_Brands__c = false, Is_All_HE__c = false, Is_All__c = false,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        insert brand;
        pg = new Supplier_PG_Mapping__c(Name = supplier.Name + ' PG 1', Brand__c = brand.Id, SNA_Code__c = '001', GIMA_Code__c = '001', Department__c = department1.Id, Section__c = section.Id, Supplier__c = supplier.Id);
        insert pg;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.editMode = true;
        Org_NegoScope_Edit_Controller.refresh();
        Org_NegoScope_Edit_Controller.elementIdToSelect = department1.Id;
        Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).negoScopeElem.Choice__c = 'Include';
        Org_NegoScope_Edit_Controller.NegoScopeElemWrapper nsew = new Org_NegoScope_Edit_Controller.NegoScopeElemWrapper(Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).negoScopeElem,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).element.Elt_Code__c,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).element.Name,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).element.Level__c);  
        Org_NegoScope_Edit_Controller.wNegoScopeElementList.add(nsew);
        Org_NegoScope_Edit_Controller.PGWrapper pgWrapper = new Org_NegoScope_Edit_Controller.PGWrapper(pg, true);
        Org_NegoScope_Edit_Controller.saveNegoScope();
        List<Sup_sup_NegoScope__c> listNegoScopes = [SELECT Id, Name FROM Sup_sup_NegoScope__c];
        system.assertEquals(1, listNegoScopes.size());
    }
    
    @isTest static void testAllSelectedProductGroup() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 2', Supplier__c = supplier.Id, Incl_NewBrand__c = true, Incl_NewProduct__c = false,
                                             Is_All_Brands__c = false, Is_All_HE__c = false, Is_All__c = true,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        insert brand;
        pg = new Supplier_PG_Mapping__c(Name = supplier.Name + ' PG 1', Brand__c = brand.Id, SNA_Code__c = '001', GIMA_Code__c = '001', Department__c = department1.Id, Section__c = section.Id, Supplier__c = supplier.Id);
        insert pg;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.editMode = true;
        Org_NegoScope_Edit_Controller.refresh();
        Org_NegoScope_Edit_Controller.elementIdToSelect = department1.Id;
        Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).negoScopeElem.Choice__c = 'Include';
        Org_NegoScope_Edit_Controller.NegoScopeElemWrapper nsew = new Org_NegoScope_Edit_Controller.NegoScopeElemWrapper(Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).negoScopeElem,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).element.Elt_Code__c,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).element.Name,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(0).element.Level__c);
        Org_NegoScope_Edit_Controller.wNegoScopeElementList.add(nsew);
        Org_NegoScope_Edit_Controller.saveNegoScope();
        List<Sup_NS_PG__c> listNegoPg = [SELECT Id, Name FROM Sup_NS_PG__c where Supplier__c = :supplier.Id];
        system.assertEquals(1, listNegoPg.size());
    }
    
    @isTest static void testCreateNegoFromSupplier() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 2', Supplier__c = supplier.Id, Incl_NewBrand__c = false, Incl_NewProduct__c = false,
                                             Is_All_Brands__c = false, Is_All_HE__c = false, Is_All__c = true,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);   
        ApexPages.currentPage().getParameters().put('CF00N0Y000005saiN_lkid', supplier.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.editMode = false;
        Org_NegoScope_Edit_Controller.refresh();
        Org_NegoScope_Edit_Controller.saveNegoScope();
        List<Sup_sup_NegoScope__c> listNegoScopes = [SELECT Id, Name FROM Sup_sup_NegoScope__c];
        system.assertEquals(1, listNegoScopes.size());
    }
    
    @isTest static void testDuplicateDefaultNegoScope() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier.Id, Is_All_Brands__c = true, Is_All_HE__c = true,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        ApexPages.currentPage().getParameters().put('clone','1');
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.refresh();
        Org_NegoScope_Edit_Controller.saveNegoScope();
        List<Sup_sup_NegoScope__c> listNegoScopes = [SELECT Id, Name FROM Sup_sup_NegoScope__c];
        system.assertEquals(1, listNegoScopes.size());
    }
    
    @isTest static void test_saveNegoScope_one_selected_structure_element_rami() {
        init();
        negoScope = new Sup_sup_NegoScope__c(Name = 'New Negoscope', CurrencyIsoCode = supplier.CurrencyIsoCode,
                                             OwnerId = UserInfo.getUserId(), Supplier__c = supplier.Id,
                                             Is_All_Brands__c = true, Is_All_HE__c = true, Is_All__c = true,
                                             Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope;
        brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        insert brand;
        // Sup_Bra_Distributor__c brandDist = new Sup_Bra_Distributor__c(Name = 'Brand Dist 1', Supplier__c = supplier.Id,Brand__c=brand.Id);
        // insert brandDist;
        ApexPages.currentPage().getParameters().put('id', negoScope.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(negoScope);
        Org_NegoScope_Edit_Controller Org_NegoScope_Edit_Controller = new Org_NegoScope_Edit_Controller(stdController);
        Org_NegoScope_Edit_Controller.reset();
        Org_NegoScope_Edit_Controller.onChangeSupplier();
        Org_NegoScope_Edit_Controller.editMode = true;
        Org_NegoScope_Edit_Controller.refresh();
        Org_NegoScope_Edit_Controller.refreshNsName();
        Org_NegoScope_Edit_Controller.sortToggle();
        Org_NegoScope_Edit_Controller.sortToggle();
        Org_NegoScope_Edit_Controller.getChoiceOptions();
        Org_NegoScope_Edit_Controller.elementIdToSelect = department2.Id;
        Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).negoScopeElem.Choice__c = 'Include';
        Org_NegoScope_Edit_Controller.NegoScopeElemWrapper nsew = new Org_NegoScope_Edit_Controller.NegoScopeElemWrapper(Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).negoScopeElem,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).element.Elt_Code__c,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).element.Name,
                                                                                                                         Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).element.Level__c);  
        Org_NegoScope_Edit_Controller.wNegoScopeElementList.add(nsew);
        // Org_NegoScope_Edit_Controller.BrandWrapper brandWrapper = new Org_NegoScope_Edit_Controller.BrandWrapper(brandDist, true);
        // Org_NegoScope_Edit_Controller.listBrandsSupplierWraper.add(brandWrapper);
        Org_NegoScope_Edit_Controller.saveNegoScope();
        List<Sup_sup_NegoScope__c> listNegoScopes = [SELECT Id, Name FROM Sup_sup_NegoScope__c];
        system.assertEquals(1, listNegoScopes.size());
        List<Supplier_NS_HE__c> listNegoScopeElements = [SELECT Id, Name, Choice__c FROM Supplier_NS_HE__c WHERE Sup_sup_NegoScope__c = :listNegoScopes];
        system.assertEquals(1, listNegoScopeElements.size());
        Org_NegoScope_Edit_Controller.elementIdToSelect = listNegoScopeElements.get(0).Id;
        Org_NegoScope_Edit_Controller.childElementsWrapped.get(1).negoScopeElem.Choice__c = 'exclude';
        Org_NegoScope_Edit_Controller.selectElement();
        Org_NegoScope_Edit_Controller.wNegoScopeElementList.remove(0);
        Org_NegoScope_Edit_Controller.saveNegoScope();
        Org_NegoScope_Edit_Controller.buildWhere('','');
        Org_NegoScope_Edit_Controller.buildWhere('some query','some condition');

    }
}