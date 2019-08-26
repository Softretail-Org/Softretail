@isTest
public class Trg_Assortment_BU_Test {
	static List<Orga_HE__c> heList1;
	static List<Orga_HE__c> heList2;
	private static Assortment_BU__c assortment1;
	private static Assortment_BU__c assortment2;
	private static List <Assortment_Detail__c> assortmentDetailsList;
	private static List<Product2> products;
	private static Orga_BU__c buSource;
	private static Orga_BU__c buTarget;

	static void init() {
		Orga_BU__c region = TestDataFactory.CreateBURegion(true, 'region');
		Country_List__c countryList = TestDataFactory.createCountry(true, 'France', 'FR');
		Orga_BU__c country = TestDataFactory.createBUCountry(true, countryList, region.Id);
		Sup_Supplier__c client = TestDataFactory.createSupplier(true, country, false);
		buSource = TestDataFactory.createBUBanner(false, country);
		buSource.IsMasterBU__c = true;
		buTarget = TestDataFactory.createBUBanner(false, country);
		buTarget.Mission__c = 'Offer';
		buTarget.IsMasterBU__c = false;
		buTarget.Related_Client__c = client.Id;
		insert new List<Orga_BU__c> {buSource, buTarget};
		Orga_BU__c cluster = TestDataFactory.createBUAssortCluster(true, buTarget.Id, 'Strat0');
		List<Orga_HE__c> categoriesList = new List<Orga_HE__c>();
		Map<String, Product2> productsMap = new Map <String, Product2>();
		//init Orga HEs
		heList1 = TestDataFactory.createElementHierarchy(4, 1);
		heList2 = TestDataFactory.createElementHierarchy(4, 1);
		products = new List<Product2>();
		for (Integer i = 0; i < 4; i++) {
			products.add(TestDataFactory.createProduct(false, heList1[4].Id, null));
			products.add(TestDataFactory.createProduct(false, heList2[4].Id, null));
		}
		insert products;
		assortment1 = TestDataFactory.createAssortmentBU(false, buSource, buTarget, heList1[1]);
		assortment2 = TestDataFactory.createAssortmentBU(false, buSource, buTarget, heList2[1]);
		insert new List<Assortment_BU__c> {assortment1, assortment2};
		assortmentDetailsList = new List<Assortment_Detail__c>();
		for (Product2 product : products) {
			assortmentDetailsList.add(TestDataFactory.createAssortmentDetail(false, assortment1.Id, product, cluster.Id));
			assortmentDetailsList.add(TestDataFactory.createAssortmentDetail(false, assortment2.Id, product, cluster.Id));
		}
		insert assortmentDetailsList;
	}

	@isTest
	static void case1_before_Update() {
		init();
		assortment1.Orga_HE__c = heList2[1].Id;
		Boolean expectedExceptionThrown;
		Test.startTest();
		try {
			update assortment1;
		} catch (Exception ex) {
			expectedExceptionThrown = ex.getMessage().contains(Label.Cannot_Change_Assortment_Category_To_Another_Details_Branch);
		}
		test.stopTest();
		System.assert (expectedExceptionThrown);
	}

	@isTest
	static void case2_before_Update_Mass() {
		init();
		assortment1.Orga_HE__c = heList2[1].Id;
		assortment2.Orga_HE__c = heList1[1].Id;
		Test.startTest();
		List<Database.SaveResult> results = Database.update(new List<Assortment_BU__c> {assortment1, assortment2}, false);
		test.stopTest();
		for (Database.SaveResult result : results) {
			System.assert (result.getErrors().get(0).getMessage().contains(Label.Cannot_Change_Assortment_Category_To_Another_Details_Branch));
		}
	}

	@isTest
	static void case3_UpdateAssortmentDetailsStatuSingle_Success() {
		init();
		Test.startTest();
        assortment1 = [SELECT Id FROM Assortment_BU__c WHERE Id = :assortment1.Id];
		assortment1.Status__c = 'Validated';
		update assortment1;
		Test.stopTest();
		//assortmentDetailsList contains Assortment_Detail__c of assortment1 and assortment2
		System.assertEquals(assortmentDetailsList.size()/2, [SELECT COUNT() FROM Assortment_Detail__c WHERE Status__c = 'Validated' AND Assortment_BU__c = : assortment1.Id]);
	}
	@isTest
	static void case4_UpdateAssortmentDetailsStatusMass_Success() {
		init();
        Test.startTest();
        assortment1 = [SELECT Id FROM Assortment_BU__c WHERE Id = :assortment1.Id];
		assortment1.Status__c = 'Validated';
        assortment2 = [SELECT Id FROM Assortment_BU__c WHERE Id = :assortment2.Id];
		assortment2.Status__c = 'Validated';
		update new List<Assortment_BU__c> {assortment1, assortment2};
		Test.stopTest();
		//assortmentDetailsList contains Assortment_Detail__c of assortment1 and assortment2
		System.assertEquals(assortmentDetailsList.size()/2, [SELECT COUNT() FROM Assortment_Detail__c WHERE Status__c = 'Validated' AND Assortment_BU__c = : assortment1.Id]);
		System.assertEquals(assortmentDetailsList.size()/2, [SELECT COUNT() FROM Assortment_Detail__c WHERE Status__c = 'Validated' AND Assortment_BU__c = : assortment2.Id]);
	}

	@isTest
	static void case5_GenerateName_Success() {
		init();
		Test.startTest();
		Assortment_BU__c clone = assortment1.clone(false,false,false,false);
		insert clone;
		clone = [SELECT Simulation_version__c, Name, Name_Prefix__c FROM Assortment_BU__c WHERE Id = :clone.Id];
		Test.stopTest();
		System.assertEquals(2, clone.Simulation_version__c);
		System.assertEquals(clone.Name_Prefix__c + '-V' + clone.Simulation_version__c, clone.Name);
	}

	@isTest
	static void case6_GenerateName_Mass_Success() {
		init();
		Test.startTest();
		Integer numberOfRecords = 50;
		List<Assortment_BU__c> clones = new List<Assortment_BU__c>();
		for (Integer i = 0; i < numberOfRecords; i++) {
			clones.add(assortment1.clone(false,false,false,false));
		}
		insert clones;
		Set<Id> assortmentBUsIdSet = new Set<Id>();
		for (Assortment_BU__c item : clones) {
			assortmentBUsIdSet.add(item.Id);
		}
		clones = [SELECT Simulation_version__c, Name, Name_Prefix__c FROM Assortment_BU__c WHERE Id = :assortmentBUsIdSet];
		Test.stopTest();
		System.assertEquals(numberOfRecords, clones.size());
		for (Integer i = 0; i < numberOfRecords; i++) {
			System.assertEquals(i + 2, clones.get(i).Simulation_version__c);
			System.assertEquals(clones.get(i).Name_Prefix__c + '-V' + clones.get(i).Simulation_version__c, clones.get(i).Name);
		}
	}
	@isTest
	static void case7_Add_Inno_Products_To_Cloned_Nego_Mass_Success() {
		init();
		Test.startTest();
		Integer numberOfRecords = 5;
		Assortment_BU__c AssortmentBU = TestDataFactory.createAssortmentBU(false, buSource, buTarget, heList1[1]);
		AssortmentBU.Status__c = 'Validated';
		List<Product2> assortmentBUProductList = new List<Product2>();
		List<Assortment_Detail__c> assortmentBUAssortmentDetailsList = new List<Assortment_Detail__c>();
		for (Integer index = 0; index < numberOfRecords; index++) {
			Product2 product = TestDataFactory.createProduct(false, heList1[4].Id, null);
			product.Market_Introduction_Date__c = Date.newInstance(AssortmentBU.Year__c.intValue(), 1, 1);
			assortmentBUProductList.add(product);
		}
		insert AssortmentBU;
		insert assortmentBUProductList;
		for (Product2 item : assortmentBUProductList) {
			Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortmentDetail(false, AssortmentBU.Id, item, null);
			assortmentDetail.Status__c = 'Validated';
			assortmentBUAssortmentDetailsList.add(assortmentDetail);
		}
		insert assortmentBUAssortmentDetailsList;
		List<Product2> innoProductList = new List<Product2>();
		List<Assortment_BU__c> clonedAssortmentsList = new List<Assortment_BU__c>();
		for (Integer index = 0; index < numberOfRecords; index++) {
			Product2 product = TestDataFactory.createProduct(false, heList1[4].Id, null);
			product.Market_Introduction_Date__c = Date.newInstance(AssortmentBU.Year__c.intValue() + 1, 1, 1);
			innoProductList.add(product);
		}

		for (Integer index = 0; index < numberOfRecords; index++) {
			Assortment_BU__c assortment = AssortmentBU.clone(false);
			assortment.Year__c = AssortmentBU.Year__c + 1;
			assortment.Ass_BDate__c = Date.newInstance(AssortmentBU.Year__c.intValue() + 1, 1, 1);
			assortment.Ass_EDate__c = Date.newInstance(AssortmentBU.Year__c.intValue() + 1, 12, 31);
			assortment.Assortment_parent__c = AssortmentBU.Id;
			clonedAssortmentsList.add(assortment);
		}
		insert innoProductList;
		insert clonedAssortmentsList;
		Set<Id> clonedAssortmentIds = new Set<Id>();
		for (Assortment_BU__c assortment: clonedAssortmentsList) {
			clonedAssortmentIds.add(assortment.Id);
		}
		Test.stopTest();
		Integer sumOfClonedNegoAssortmentDetails = [SELECT COUNT() FROM Assortment_Detail__c WHERE Assortment_BU__c IN :clonedAssortmentIds];
		System.assertEquals((assortmentBUProductList.size() + innoProductList.size()) * numberOfRecords, sumOfClonedNegoAssortmentDetails);
	}
}