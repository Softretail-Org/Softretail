/**
 * @author ULiT
 * @date 24-may-2019
 * */
@isTest
public class CancelPromoControllerTest {

    private static Orga_BU__c country;
    private static Orga_BU__c groupBU;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract;
    private static Commercial_Plan__c commercialPlan;
    
    static ApexPages.StandardController stdController;
    static CancelPromoController controller;
    
    static void init() {
        try {
            // Insert Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Insert Region.
            Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
            // Insert Country.
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Insert group BU.
            groupBU = TestDataFactory.createGroupBU(false, 'EMC');
            groupBU.Country_Zone_origin__c = region.Id;
            insert groupBU;
            // Insert Supplier.
            Sup_Supplier__c supplier = TestDataFactory.createSupplier(true, country, true);
	        // Get the default negoscope created on supplier creation.
	    	NS = TestDataFactory.getNSs(supplier.Id)[0];
		    // Insert contract.
	    	contract = TestDataFactory.createContract(false, NS, System.Today().addMonths(-4), System.Today().addMonths(-2));
        	contract.Total_Marketing_Events_Justified__c = 0;
        	contract.Last_Active_Contract__c = TRUE;
            insert contract;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    @isTest
    static void Case1_CancelPromo_success() {
        init();
        // Get Root Element Id.
        Id rootId = NegoptimHelper.getRootId();
        //Insert Category
        Orga_HE__c department1 = TestDataFactory.createDepartment(true, rootId);
        Orga_HE__c section1 = TestDataFactory.createSection(true, department1.Id);
        List<Commercial_Plan_Detail__c> commercialPlanDetailsList = new List<Commercial_Plan_Detail__c>();
        List<Product2> productList = new List<Product2>();
        Sup_Supplier__c supplier = TestDataFactory.createSupplier(false, country, true);
        
        Integer nbOfRecords = 50;
        // Insert CommercialPlan.
        commercialPlan = TestDataFactory.createCommercialPlan(false, System.Today().addMonths(-5), System.Today().addMonths(-4));
        commercialPlan.Name = 'Sales Floor Event';
        commercialPlan.BU_Target__c = country.Id;
        insert commercialPlan;
        //Insert Products
        for (Integer i = 0; i < nbOfRecords; i++) {
            productList.add(TestDataFactory.createProduct(false, section1.Id, supplier.Id));
        }
        insert productList;
        // Insert CommercialPlan Details.
        for (Integer i = 0; i < nbOfRecords; i++) {
            Commercial_Plan_Detail__c commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
            commercialPlanDetail.Regular_Purchase_Price__c = 1000;
            commercialPlanDetail.Regular_Sales_Price__c = 1000;
            commercialPlanDetail.Promo_Purchase_Price__c = 1000;
            commercialPlanDetail.Promo_Sales_Price__c = 1000;
            commercialPlanDetail.Contribution_Unit_Amount__c = 1000;
            commercialPlanDetail.Product__c = productList[i].Id;
            commercialPlanDetailsList.add(commercialPlanDetail);
        }
        insert commercialPlanDetailsList;
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', commercialPlan.Id);
        stdController = new ApexPages.StandardController(commercialPlan);
        controller = new CancelPromoController(stdController);
        controller.cancelPromo();
        Test.stopTest();
        
        Commercial_Plan__c newComercialPlan = [SELECT Id, Name, Status__c , Commercial_Animation_Plan_Parent__c,
                                               (SELECT Regular_Purchase_Price__c, Regular_Sales_Price__c, Promo_Purchase_Price__c, Promo_Sales_Price__c, Contribution_Unit_Amount__c, Commercial_Event__c
                                                FROM Marketing_Event_Detail__r) 
                                               FROM Commercial_Plan__c 
                                               WHERE Commercial_Animation_Plan_Parent__c = :commercialPlan.Id];

        System.assertEquals(newComercialPlan.Commercial_Animation_Plan_Parent__c, commercialPlan.Id);
        System.assert(newComercialPlan.Name.Contains(' (' + Label.Cancel + ')'));
        System.assertEquals(newComercialPlan.Status__c, 'In preparation');
        System.assertEquals(newComercialPlan.Marketing_Event_Detail__r.size(), 50);
        for (Integer i = 0; i < nbOfRecords; i++) {
            System.assertEquals(newComercialPlan.Id, newComercialPlan.Marketing_Event_Detail__r[i].Commercial_Event__c);
            System.assertEquals(0, commercialPlanDetailsList[i].Regular_Purchase_Price__c + newComercialPlan.Marketing_Event_Detail__r[i].Regular_Purchase_Price__c);
            System.assertEquals(0, commercialPlanDetailsList[i].Regular_Sales_Price__c + newComercialPlan.Marketing_Event_Detail__r[i].Regular_Sales_Price__c);
            System.assertEquals(0, commercialPlanDetailsList[i].Promo_Purchase_Price__c + newComercialPlan.Marketing_Event_Detail__r[i].Promo_Purchase_Price__c);
            System.assertEquals(0, commercialPlanDetailsList[i].Promo_Sales_Price__c + newComercialPlan.Marketing_Event_Detail__r[i].Promo_Sales_Price__c);
            System.assertEquals(0, commercialPlanDetailsList[i].Contribution_Unit_Amount__c + newComercialPlan.Marketing_Event_Detail__r[i].Contribution_Unit_Amount__c);
        }
    }
}