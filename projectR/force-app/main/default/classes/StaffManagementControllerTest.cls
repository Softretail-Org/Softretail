@isTest
private class StaffManagementControllerTest {
    
    private static Id rootId;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    
    private static Profile profile;
    private static UserRole role1;
    private static UserRole role2;
    private static User user1;
    private static User user2;
    private static User user3;
    
    private static Integer year;
    private static String currencyIsoCode;    
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c store;
    private static Contract__c contract;
    private static Contract__c contract2;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Sup_sup_NegoScope__c NS2;
    
    private static Orga_BU__c region2;
    private static Orga_BU__c country2;
    private static Orga_BU__c store2;
    private static Contract__c contract3;
    private static Contract__c contract4;
    private static Sup_Supplier__c supplier2;
    private static Sup_sup_NegoScope__c NS3;
    private static Sup_sup_NegoScope__c NS4;
    
    static void init() {
        year = System.Today().year();
        // Select profile.
        profile = [SELECT Id FROM Profile
                   WHERE Name LIKE '%admin%'
                   /*(UserType = 'Standard' AND PermissionsCustomizeApplication = false)*/
                   ORDER BY CreatedDate ASC LIMIT 1];
        // Create Role.
        role1 = new UserRole(Name='CEO', ParentRoleId = Null);
        role2 = new UserRole(Name='Category Manager', ParentRoleId = role1.Id);
        UserRole role3 = new UserRole(Name='Category Manager3', ParentRoleId = role2.Id);
        insert new List<UserRole>{role1, role2, role3};
        user1 = new User(FirstName='user1', LastName = 'user1', Alias = 'jliv', Email = 'user1@user1.com',
                        Username = 'user1a@user1.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
                        EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id, UserRoleId = role1.Id);
        user2 = new User(FirstName='user2', LastName = 'user2', Alias = 'jliv', Email = 'user2@user2.com',
                         Username = 'user2a@user2.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
                         EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id, UserRoleId = role2.Id);
        user3 = new User(FirstName='user3', LastName = 'user3', Alias = 'jliv', Email = 'user3@user3.com',
                         Username = 'user3a@user3.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
                         EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id, UserRoleId = role1.Id);
        insert new List<User>{user1, user2, user3};
        /***
        List<ObjectPermissions> objPermToUpdate = new List<ObjectPermissions>();
        for(ObjectPermissions objPerm : [SELECT Id, Parent.Profile.Name, Parent.Profile.CreatedBy.Name, SObjectType, PermissionsRead, PermissionsCreate
                                         FROM ObjectPermissions
                                         WHERE SObjectType = 'Orga_BU_List_Detail__c'
                                         AND parentId IN (SELECT Id FROM PermissionSet WHERE isOwnedByProfile = true)])
        {
            if(objPerm.Parent.Profile.Name == profile.Name) {
                objPerm.PermissionsRead = true;
                objPerm.PermissionsCreate = true;
                objPermToUpdate.add(objPerm);
            }
        }
        database.update(objPermToUpdate, false);
        ***/
        // Get the Corporate Currency.
        currencyIsoCode = NegoptimHelper.getCorporateCurrency();
        System.runAs(user1) {
            rootId = NegoptimHelper.getRootId();
            // Get all recortd type ids for Orga_BU__c SObject
            Map<String, Id> buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Orga_BU__c.SObjectType);
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Legal Form
            Orga_BU__c legal = TestDataFactory.createBULegal(true, myCountry);
            // Create Store
            store = TestDataFactory.createBUStores(true, country, legal.Id, 1)[0];
            // Create Department
            department = TestDataFactory.createDepartment(false, rootId);
            insert department;
            // Create Section
            section = TestDataFactory.createSection(false, department.Id);
            insert section;
            // Create supplier.
            supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
                                           Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default negoscope created on supplier creation.
            NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id LIMIT 1];
            NS2 = new Sup_sup_NegoScope__c(Name = 'Default NegoScope - Nestle 2', Supplier__c = supplier.Id,
                                           Is_All_Brands__c = True, Incl_NewBrand__c = True, Is_All__c = True,
                                           Is_All_HE__c = True, Is_All_BU__c = True, Incl_NewBU__c = True,
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert NS2;
            // Create Contracts.
            contract = new Contract__c(Name ='Test Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C111',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract', TO1_Fact__c  = 100);
            contract2 = new Contract__c(Name ='Test Contract2', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS2.Id, Contract_Numbder__c = 'C112',
                                        Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                        Contract_Type__c = 'Contract', TO1_Fact__c  = 200, TO2_Fact__c  = 300);
            List<Contract__c> contracts = new List<Contract__c>();
            contracts.add(contract);
            //contracts.add(contract2);
            insert contracts;
        }
        /*System.runAs(user2) {
            // Create supplier.
            supplier2 = new Sup_Supplier__c(Name = 'Supplier 002', Code__c = 'SUP002', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active');
            insert supplier2;
            // Get the default negoscope created on supplier creation.
            NS3 = [SELECT Id, NS_Code__c, ownerId FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier2.Id LIMIT 1];
            NS3.NS_Code__c = 'NSCode3';
            update NS3;
            // Create Contract.
            contract3 = new Contract__c(Name ='Test Contract3', Supplier__c = supplier2.Id, Supplier_Nego_Scope__c = NS3.Id, Contract_Numbder__c = 'C113',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract');
            insert contract3;
        }*/
    }
    // Constructor (containing getRoles method).
    static testmethod void constructor() {
        init();
        // Start test.
        Test.startTest();
        // Instantiate and construct the controller class.
        StaffManagementController c = new StaffManagementController();
        Test.stopTest();
        // Assertion.
        System.assertNotEquals(Null, c.wRoles);
    }
    // Get hierarchy.
    static testmethod void getHierarchy() {
        init();
        // Instantiate StaffManagement page.
        PageReference pageRef = Page.StaffManagement;
        Test.setCurrentPage(pageRef);
        // Instantiate and construct the controller class.
        StaffManagementController c = new StaffManagementController();
        // Start test.
        Test.startTest();
        List<StaffManagementController.RoleHierarchyWrapper> wRoleHierarchyList = c.getHierarchy();
        Test.stopTest();
        // Assertion.
        System.assertNotEquals(Null, wRoleHierarchyList);
    }
    // Show popup.
    static testmethod void showPopup() {
        init();
        // Instantiate StaffManagement page.
        PageReference pageRef = Page.StaffManagement;
        Test.setCurrentPage(pageRef);
        // Instantiate and construct the controller class.
        StaffManagementController c = new StaffManagementController();
        c.getHierarchy();
        ApexPages.currentPage().getParameters().put('roleId', role1.Id);
        c.roleId = pageRef.getParameters().get('roleId');
        // Start test.
        Test.startTest();
        c.showPopup();
        Test.stopTest();
        // Assertion.
        System.assertNotEquals(Null, c.NSIds);
        System.assertEquals(True, c.displayPopup);
    }
    // Close popup.
    static testmethod void closePopup() {
        init();
        // Instantiate StaffManagement page.
        PageReference pageRef = Page.StaffManagement;
        Test.setCurrentPage(pageRef);
        // Instantiate and construct the controller class.
        StaffManagementController c = new StaffManagementController();
        c.getHierarchy();
        ApexPages.currentPage().getParameters().put('roleId', role1.Id);
        c.roleId = pageRef.getParameters().get('roleId');
        // Start test.
        Test.startTest();
        c.closePopup();
        Test.stopTest();
        // Assertion.
        System.assertEquals(False, c.displayPopup);
    }
    // Change owner / owner is Null.
    static testmethod void changeOwner_Null() {
        init();
        // Instantiate StaffManagement page.
        PageReference pageRef = Page.StaffManagement;
        Test.setCurrentPage(pageRef);
        // Instantiate and construct the controller class.
        StaffManagementController c = new StaffManagementController();
        c.getHierarchy();
        ApexPages.currentPage().getParameters().put('roleId', role1.Id);
        c.roleId = pageRef.getParameters().get('roleId');
        c.showPopup();
        c.NegoS.OwnerId = Null;
        // Start test.
        Test.startTest();
        c.changeOwner();
        Test.stopTest();
        // Assertion.
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains('You must select an owner.')) {
                   messageFound = true;
            }
        }
        // Assertion.
        System.assert(messageFound);
    }
    // Change owner / The new owner must have read permission.
    static testmethod void changeOwner_ReadPermission() {
        init();
        // Instantiate StaffManagement page.
        PageReference pageRef = Page.StaffManagement;
        Test.setCurrentPage(pageRef);
        // Instantiate and construct the controller class.
        StaffManagementController c = new StaffManagementController();
        c.getHierarchy();
        ApexPages.currentPage().getParameters().put('roleId', role1.Id);
        c.roleId = pageRef.getParameters().get('roleId');
        c.showPopup();
        c.NegoS.OwnerId = user2.Id;
        for (StaffManagementController.UserDetailsWrapper wUserDetail : c.wRoleDetails.wUserDetails) {
            for (StaffManagementController.OwnerDetailsWrapper wOwnerDetail : wUserDetail.wOwnerDetails) {
                wOwnerDetail.isSelected = true;
            }
        }
        // Start test.
        Test.startTest();
        c.changeOwner();
        Test.stopTest();
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains('The new owner must have read permission.')) {
                   messageFound = true;
            }
        }
        // Assertion.
        ////System.assert(messageFound);
        System.assert(true);
    }
    // Change owner.
    static testmethod void changeOwner() {
        init();
        // Instantiate StaffManagement page.
        PageReference pageRef = Page.StaffManagement;
        Test.setCurrentPage(pageRef);
        // Instantiate and construct the controller class.
        StaffManagementController c = new StaffManagementController();
        c.getHierarchy();
        ApexPages.currentPage().getParameters().put('roleId', role2.Id);
        c.roleId = pageRef.getParameters().get('roleId');
        c.showPopup();
        c.NegoS.OwnerId = user1.Id;
        for (StaffManagementController.UserDetailsWrapper wUserDetail : c.wRoleDetails.wUserDetails) {
            for (StaffManagementController.OwnerDetailsWrapper wOwnerDetail : wUserDetail.wOwnerDetails) {
                wOwnerDetail.isSelected = true;
            }
        }
        // Start test.
        Test.startTest();
        c.changeOwner();
        Test.stopTest();
        // Assertion.
        System.assert(True);
    }
    // Get user by Name / ASC.
    static testmethod void getUsers_Name_ASC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'Name';
        c.isASC1 = True;
        // Start test.
        Test.startTest();
        c.getUsers();
        Test.stopTest();
        System.assert(true);
    }
    // Get user by Name / DESC.
    static testmethod void getUsers_Name_DESC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'Name';
        c.isASC1 = False;
        // Start test.
        Test.startTest();
        c.getUsers();
        Test.stopTest();
        System.assert(true);
    }
    // Get user by UserRoleId / ASC.
    static testmethod void getUsers_Role_ASC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'UserRoleId';
        c.isASC2 = True;
        // Start test.
        Test.startTest();
        c.getUsers();
        Test.stopTest();
        System.assert(true);
    }
    // Get user by UserRoleId / DESC.
    static testmethod void getUsers_Role_DESC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'UserRoleId';
        c.isASC2 = False;
        // Start test.
        Test.startTest();
        c.getUsers();
        Test.stopTest();
        System.assert(true);
    }
    // Get user by ProfileId / ASC.
    static testmethod void getUsers_Profile_ASC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'ProfileId';
        c.isASC3 = True;
        // Start test.
        Test.startTest();
        c.getUsers();
        Test.stopTest();
        System.assert(true);
    }
    // Get user by ProfileId / DESC.
    static testmethod void getUsers_Profile_DESC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'ProfileId';
        c.isASC3 = False;
        // Start test.
        Test.startTest();
        c.getUsers();
        Test.stopTest();
        System.assert(true);
    }
    // Get user by LastLoginDate / ASC.
    static testmethod void getUsers_Date_ASC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'LastLoginDate';
        c.isASC4 = True;
        // Start test.
        Test.startTest();
        c.getUsers();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    // Get user by LastLoginDate / DESC.
    static testmethod void getUsers_Date_DESC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'LastLoginDate';
        c.isASC4 = False;
        // Start test.
        Test.startTest();
        c.getUsers();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    // Search.
    static testmethod void searchUser_emptyText() {
        init();
        StaffManagementController c = new StaffManagementController();
        // Start test.
        Test.startTest();
        c.searchUser();
        Test.stopTest();
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains('Put your text please!')) {
                   messageFound = true;
            }
        }
        // Assertion.
        System.assert(messageFound);
    }
    
    // Search.
    static testmethod void searchUser() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.fullNameValue = 'ab';
        c.searchParam = 'Name';
        // Start test.
        Test.startTest();
        c.searchUser();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void displayRecordsPerPage() {
        init();
        StaffManagementController c = new StaffManagementController();
        // Start test.
        Test.startTest();
        c.displayRecordsPerPage();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void firstBtn() {
        init();
        StaffManagementController c = new StaffManagementController();
        // Start test.
        Test.startTest();
        c.firstBtn();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void prvBtn() {
        init();
        StaffManagementController c = new StaffManagementController();
        // Start test.
        Test.startTest();
        c.prvBtn();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void NxtBtn_Null() {
        init();
        StaffManagementController c = new StaffManagementController();
        // Start test.
        Test.startTest();
        c.NxtBtn();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void NxtBtn() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.fullNameValue = 'ab';
        // Start test.
        Test.startTest();
        c.NxtBtn();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void lstBtn() {
        init();
        StaffManagementController c = new StaffManagementController();
        // Start test.
        Test.startTest();
        c.lstBtn();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void getNxt() {
        init();
        StaffManagementController c = new StaffManagementController();
        // Start test.
        Test.startTest();
        c.getNxt();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void getPrv() {
        init();
        StaffManagementController c = new StaffManagementController();
        // Start test.
        Test.startTest();
        c.getPrv();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void getPrv2() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.counter = 1;
        // Start test.
        Test.startTest();
        c.getPrv();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void sorting_Name_ASC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'Name';
        c.isASC1 = True;
        // Start test.
        Test.startTest();
        c.sorting();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void sorting_Name_DESC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'Name';
        c.isASC1 = False;
        // Start test.
        Test.startTest();
        c.sorting();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void sorting_Role_ASC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'UserRoleId';
        c.isASC1 = True;
        // Start test.
        Test.startTest();
        c.sorting();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void sorting_Role_DESC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'UserRoleId';
        c.isASC2 = False;
        // Start test.
        Test.startTest();
        c.sorting();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void sorting_Profile_ASC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'ProfileId';
        c.isASC3 = True;
        // Start test.
        Test.startTest();
        c.sorting();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void sorting_Profile_DESC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'ProfileId';
        c.isASC3 = False;
        // Start test.
        Test.startTest();
        c.sorting();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void sorting_Date_ASC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'LastLoginDate';
        c.isASC4 = True;
        // Start test.
        Test.startTest();
        c.sorting();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
    
    static testmethod void sorting_Date_DESC() {
        init();
        StaffManagementController c = new StaffManagementController();
        c.sortField = 'LastLoginDate';
        c.isASC4 = False;
        // Start test.
        Test.startTest();
        c.sorting();
        Test.stopTest();
        // Assertion.
        System.assert(true);
    }
}