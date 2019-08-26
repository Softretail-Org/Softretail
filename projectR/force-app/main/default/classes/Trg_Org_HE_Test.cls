/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers relaated to Product structure (HE)
 */
@isTest
private class Trg_Org_HE_Test {
	
    private static Id rootId;
    private static Integer year;
    private static Orga_HE__c department1;
    private static Orga_HE__c department2;
    private static Orga_HE__c department3;
    private static Orga_HE__c section1;
    private static Orga_HE__c section2;
    private static Orga_HE__c section11;
    private static Orga_HE__c section12;
    
    // initial function to declare and create objects
    static void init() {
        try {
            year = System.Today().year();
            // root Element
            rootId = NegoptimHelper.getRootId();            
            // Create Department
            department1 = TestDataFactory.createDepartment(false, rootId);
            department1.Name = 'DPT1'; department1.Elt_Code__c = 'DPT Code 1';
            insert department1;
            // Create Department2
            department2 = TestDataFactory.createDepartment(false, rootId);
            department2.Name = 'DPT2'; department2.Elt_Code__c = 'DPT Code 2';
            insert department2;
            // Create Department3
            department3 = TestDataFactory.createDepartment(false, rootId);
            department3.Name = 'DPT3'; department3.Elt_Code__c = 'DPT Code 3';
            insert department3;
            // Create Section
            section1 = TestDataFactory.createSection(false, department1.Id);
            section1.Name = 'SEC1'; section1.Elt_Code__c = 'SEC Code 1';
            insert section1;
            // Create Section
            section2 = TestDataFactory.createSection(false, department2.Id);
            section2.Name = 'SEC2'; section2.Elt_Code__c = 'SEC Code 2';
            insert section2;
            // Create Section Child
            section11 = TestDataFactory.createSection(false, section1.Id);
            section11.Name = 'SEC11'; 
            section11.Elt_Code__c = 'Sec11';
            insert section11;
            section12 = TestDataFactory.createSection(false, section1.Id);
            section12.Name = 'SEC12'; 
            section12.Elt_Code__c = 'Sec12';
            insert section12;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Test validation  on deletion of root : Root element can not be deleted  
    @isTest static void test_deleteRootElement() {
        init();
        Orga_HE__c selectRoot = [SELECT id FROM Orga_HE__c WHERE id = :rootId];
        Test.startTest();
        Database.DeleteResult result = Database.delete(selectRoot, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Can_Not_Delete_Root_Element, result.getErrors()[0].getMessage());
    }
    
    // Test delete HE with child will not be accepted
    @isTest static void testDeleteHeWithChild(){
        init();
        Test.startTest();
        database.DeleteResult result = database.delete(department1, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Cannot_Delete_Record, result.getErrors()[0].getMessage());
    }
    
    // Test validation on element : code duplication
    @isTest static void test_checkElementCodeDuplication() {
        init();
        Orga_HE__c newElement = new Orga_HE__c(Name = 'New Element', Elt_Code__c = 'DPT Code 2', Parent_Element__c = department1.Id, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1));
        Test.startTest();
        Database.SaveResult result = Database.insert(newElement, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Code_Value, result.getErrors()[0].getMessage());
    }
    
    // Test validation another element added with name duplication   
    @isTest static void test_checkAnotherElementNameDuplication() {
        init();
        Orga_HE__c newElement1 = new Orga_HE__c(Name = 'Element 1', Elt_Code__c = 'New Code 1', Parent_Element__c = department1.Id, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1));
        Orga_HE__c newElement2 = new Orga_HE__c(Name = 'Element 1', Elt_Code__c = 'New Code 2', Parent_Element__c = department1.Id, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1));
        List<Orga_HE__c> lstElement = new List<Orga_HE__c>();
        lstElement.add(newElement1);
        lstElement.add(newElement2);
        Test.startTest();
        Database.SaveResult[] results = Database.insert(lstElement, false);
        Test.stopTest();
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                System.assert(!result.isSuccess());
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Name, result.getErrors()[0].getMessage());
            }
        }
    }
    
    // Test validation another element added with code duplication
    @isTest static void test_checkAnotherElementCodeDuplication() {
        init();
        Orga_HE__c newElement1 = new Orga_HE__c(Name = 'Element 1', Elt_Code__c = 'New Code 1', Parent_Element__c = department1.Id, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1));
        Orga_HE__c newElement2 = new Orga_HE__c(Name = 'Element 2', Elt_Code__c = 'New Code 1', Parent_Element__c = department1.Id, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1));
        List<Orga_HE__c> lstElement = new List<Orga_HE__c>();
        lstElement.add(newElement1);
        lstElement.add(newElement2);
        Test.startTest();
        Database.SaveResult[] results = Database.insert(lstElement, false);
        Test.stopTest();
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                System.assert(!result.isSuccess());
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Code_Value, result.getErrors()[0].getMessage()); 
            }
        }
    }
    
    // Test validation on HE update : Cannot move element to another parent level
    @isTest static void test_updateHeParentFail() {
        init();
        Orga_HE__c departmentChild = new Orga_HE__c(Name = 'DPT3-1', Elt_Code__c = 'DPT3-1', Parent_Element__c = department3.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), 
                                                    Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
        insert departmentChild;
        section2.Parent_Element__c = departmentChild.Id;
        Test.startTest();
        Database.SaveResult result = Database.update(section2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Chose_Identical_Parent_Element_Level, result.getErrors()[0].getMessage());
    }
    
    // Test validation on root element : check if root element exist
    @isTest static void test_checkRootNodeExist() {
        init();
        Orga_HE__c root2 = new Orga_HE__c(Name = 'ROOT2', Elt_Code__c = 'ROOT2', Parent_Element__c = null, Level__c = 0, Status_BDate__c = date.newInstance(year, 1, 1));
        Test.startTest();
        Database.SaveResult result = Database.insert(root2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Root_Level, result.getErrors()[0].getMessage());
    }
    
    // Test validation on root element : check if root element exist on bulk 
    @isTest static void test_checkMultiRootNodeExist() {
        init();
        List<Orga_HE__c> listRoot = new List<Orga_HE__c>();
        
        for(Integer i = 0; i <= 5; i++){
            Orga_HE__c root2 = new Orga_HE__c(Name = 'ROOT' + i, Elt_Code__c = 'ROOT' + i, Parent_Element__c = null, Level__c = 0, Status_BDate__c = date.newInstance(year, 1, 1));
            listRoot.add(root2);
        }
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(listRoot, false);
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            if (!result.isSuccess()) {
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Root_Level, result.getErrors()[0].getMessage());
            }
        }
    }
    //test Fill Path Field before insert
    @isTest 
    static void test_Fill_Path() {
        init();
        Orga_HE__c newElement1 = new Orga_HE__c(Name = 'Element 1', Elt_Code__c = 'New_Code_1', Parent_Element__c = department1.Id , Level__c = 2);
        Orga_HE__c newElement2 = new Orga_HE__c(Name = 'Element 2', Elt_Code__c = 'New_Code_2', Parent_Element__c = section1.Id , Level__c = 3);
        List<Orga_HE__c> lstElement = new List<Orga_HE__c>{newElement1, newElement2};
            Test.startTest();
        insert lstElement;        
        Test.stopTest();
        Orga_HE__c dep1 = [Select id, path__c from orga_he__c where id =: department1.Id];
        Orga_HE__c elt1 = [Select id, path__c, Elt_Code__c from orga_he__c where id =: newElement1.Id];
        Orga_HE__c sec1 = [Select id, path__c from orga_he__c where id =: section1.Id];
        Orga_HE__c elt2 = [Select id, path__c, Elt_Code__c from orga_he__c where id =: newElement2.Id];
        System.assert(elt1.Path__c != null);
        System.assertEquals(elt1.Path__c, dep1.Path__c + '|' + elt1.Elt_Code__c);
        System.assert(elt2.Path__c != null);
        System.assertEquals(elt2.Path__c, sec1.Path__c + '|' + elt2.Elt_Code__c);
    }
    //test Update Childs Paths After Update
    @isTest 
    static void test_Update_Path() {
        init();
        Orga_HE__c root = [Select id, path__c from orga_he__c where id =: rootId];
        //change Paths
        root.Elt_Code__c = 'Root_Code';
        department1.Elt_Code__c = 'Dept1';
        department3.Elt_Code__c = 'Dept3';
        section1.Elt_Code__c = 'Sec1';
        //add elements to list
        List<Orga_HE__c> listToUpdate =  new List<Orga_HE__c>{root, department1,department3,section1};
            //update list
            Test.startTest();
        update listToUpdate;        
        Test.stopTest();
        //assertion
        Map<id,Orga_HE__c> OrgaHeMap = new Map<id,Orga_HE__c>([Select id, path__c, Elt_Code__c, Parent_element__r.Path__c from orga_he__c]);
        System.assertEquals(OrgaHeMap.get(department1.Id).Path__c, 'Root_Code|Dept1');
        System.assertEquals(OrgaHeMap.get(department2.Id).Path__c, 'Root_Code|DPT Code 2');
        System.assertEquals(OrgaHeMap.get(department3.Id).Path__c, 'Root_Code|Dept3');
        System.assertEquals(OrgaHeMap.get(section1.Id).Path__c, 'Root_Code|Dept1|Sec1'); 
        System.assertEquals(OrgaHeMap.get(section11.Id).Path__c, 'Root_Code|Dept1|Sec1|Sec11'); 
        System.assertEquals(OrgaHeMap.get(section12.Id).Path__c, 'Root_Code|Dept1|Sec1|Sec12'); 
    }
    
}