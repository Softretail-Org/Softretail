/**
 * Test class methods that verify whether the particular piece of code on SellinToPurchaseBatch is working properly.
 **/
@isTest
private class SellinToPurchaseBatchTest {
    
    private static final Integer year = TestDataFactory.year;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Orga_HE__c section;
    private static Product2 product;
    private static Supplier_PG_Mapping__c PG;
    private static Contract__c contract;
    
    static void init() {
        try {
	    	// Insert Country List.
	        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
	    	// Insert Region.
	        Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
	    	// Insert Country.
	        country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Insert supplier.
	    	supplier = TestDataFactory.createSupplier(true, country, true);
            // Get the default negoscope created on supplier creation.
	    	NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Make NS Acc_Country__c = Contract_BU__r.Country__c
            NS.Acc_Country__c = country.Name;
            update NS;
            // Get Root Element Id.
			Id rootId = NegoptimHelper.getRootId();
            // Insert Department.
			Orga_HE__c department = TestDataFactory.createDepartment(true, rootId);
            // Insert Section.
			section = TestDataFactory.createSection(true, department.Id);
            // Insert Brand.
            Sup_Brand__c brand = TestDataFactory.createBrand(true, supplier.Id);
            // Insert Product.
            product = TestDataFactory.createProduct(true, section.Id, supplier.Id);
            // Insert PG.
	    	PG = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            PG.Brand__c = brand.Id;
            PG.Product__c = product.Id;
            insert PG;
            // Insert Contract.
    		contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 2, 1), date.newInstance(year, 6, 1));
            // Insert SellInFlows.
            Sell_in_Flow__c sellIn1 = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 2, 1));
            sellIn1.Invoice_Net_Amount_woTax__c = 100;
            sellIn1.Footer_Order_Discount__c = 20;
            sellIn1.Invoice_Gross_Amount_woTax__c = 100;
            sellIn1.Invoice_Quantity__c = 5;
            sellIn1.Unit_Cost__c = 2;
            sellIn1.Contract__c = contract.Id;
            sellIn1.Order_Date__c = Date.newInstance(year, 2, 10);            
            Sell_in_Flow__c sellIn2 = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 3, 10));
            sellIn2.Invoice_Net_Amount_woTax__c = 200;
            sellIn2.Footer_Order_Discount__c = 10;
            sellIn2.Invoice_Gross_Amount_woTax__c = 200;
            sellIn2.Invoice_Quantity__c = 10;
            sellIn2.Unit_Cost__c = 2;
            sellIn2.Contract__c = contract.Id;
            sellIn2.Order_Date__c = Date.newInstance(year, 3, 1);            
            insert new List<Sell_in_Flow__c>{sellIn1, sellIn2};                
        } catch (Exception ex) {
        	System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void uTest1_test_copy() {
        init();
        Test.startTest();
        Database.executeBatch(new SellinToPurchaseBatch('Test', null , null, new List<Id>{supplier.Id}, null, null, year, null));
        Test.stopTest();
        Purchases_Flow_PG__c purchase = [SELECT TO2__c, TO3__c, YTD_TO__c, Qty2__c, Qty3__c, YTD_QTY__c,
                                         Sales_Cost_M1__c, Sales_Cost_M2__c, Sales_Cost_M3__c,
                                         Front_Margin_M2__c, Front_Margin_M3__c, PG__c FROM Purchases_Flow_PG__c LIMIT 1];
        // Assertions.
        system.assertEquals(80, purchase.TO2__c);
        system.assertEquals(180, purchase.TO3__c);
        system.assertEquals(260, purchase.YTD_TO__c);
        system.assertEquals(5, purchase.Qty2__c);
        system.assertEquals(10, purchase.Qty3__c);
        system.assertEquals(15, purchase.YTD_QTY__c);
        system.assertEquals(null, purchase.Sales_Cost_M1__c);
        system.assertEquals(10, purchase.Sales_Cost_M2__c);
        system.assertEquals(20, purchase.Sales_Cost_M3__c);
        system.assertEquals(1, [SELECT COUNT() FROM Purchases_Flow_PG__c]);
    }
    @isTest static void uTest2_test_update1() {
        init();
        // Insert Purchase.
        String fieldName;
        Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, PG, country.Id);
        for (Integer i = 1 ; i <= 12 ; i++) {
        	fieldName = 'TO' + i + '__c';
        	purchase.put(fieldName, 200);
        }
        purchase.Sequence__c = 2;
        purchase.Contrat1__c = contract.Id;
        insert purchase;
        // Insert SellInFlows.
        Sell_in_Flow__c sellIn1 = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 1, 1));
        sellIn1.Invoice_Net_Amount_woTax__c = 50;
        sellIn1.Footer_Order_Discount__c = 10;
        sellIn1.Invoice_Gross_Amount_woTax__c = 50;
        sellIn1.Invoice_Quantity__c = 15;
        sellIn1.Unit_Cost__c = 2;
        sellIn1.Contract__c = contract.Id;
        sellIn1.Order_Date__c = Date.newInstance(year, 1, 10);
        Sell_in_Flow__c sellIn2 = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 2, 1));
        sellIn2.Invoice_Net_Amount_woTax__c = 400;
        sellIn2.Footer_Order_Discount__c = 40;
        sellIn2.Invoice_Gross_Amount_woTax__c = 400;
        sellIn2.Invoice_Quantity__c = 55;
        sellIn2.Unit_Cost__c = 2;
        sellIn2.Contract__c = contract.Id;
        sellIn2.Order_Date__c = Date.newInstance(year, 2, 10);
        insert new List<Sell_in_Flow__c>{sellIn1, sellIn2};
        Test.startTest();
        Database.executeBatch(new SellinToPurchaseBatch('Test', null , new List<Id>{country.Id}, new List<Id>{supplier.Id}, null, new List<Integer>{2}, year, null));
        Test.stopTest();
        // Assertions.
        purchase = [SELECT TO1__c, TO2__c, TO3__c, YTD_TO__c, Qty1__c, Qty2__c, Qty3__c, YTD_QTY__c,
                    Sales_Cost_M1__c, Sales_Cost_M2__c, Sales_Cost_M3__c,
                    Front_Margin_M1__c, Front_Margin_M2__c, Front_Margin_M3__c, PG__c
                    FROM Purchases_Flow_PG__c WHERE Id = :purchase.Id];
        system.assertEquals(320+200, purchase.TO2__c);
        system.assertEquals(2520+200, purchase.YTD_TO__c);
        system.assertEquals(60, purchase.Qty2__c);
        system.assertEquals(10+110, purchase.Sales_Cost_M2__c);
        system.assertEquals(1, [SELECT COUNT() FROM Purchases_Flow_PG__c]);
    }
    
    @isTest static void uTest3_test_update2() {
        init();
        // Insert purchase.
        String str1;
        String str2;
        String str3;
        Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, PG, country.Id);
        for (Integer i = 1 ; i <= 12 ; i++) {
        	str1 = 'TO' + i + '__c';
        	str2 = 'Qty' + i + '__c';
        	str3 = 'Front_Margin_M' + i + '__c';
        	purchase.put(str1, 200);
        	purchase.put(str2, 10);
        	purchase.put(str3, 1);
        }
        purchase.Sequence__c = 2;
        purchase.Contrat1__c = contract.Id;
        insert purchase;
        List<Sell_in_Flow__c> sellinList = new List<Sell_in_Flow__c>();
        for (Integer i = 1; i <= 12; i++) {
            Sell_in_Flow__c sellIn = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, i, 1));
            sellIn.Invoice_Net_Amount_woTax__c = i*10;
            sellIn.Footer_Order_Discount__c = i;
            sellIn.Invoice_Gross_Amount_woTax__c = i*100;
            sellIn.Invoice_Quantity__c = i;
            sellIn.Unit_Cost__c = 1;
	        sellIn.Contract__c = contract.Id;
	        sellIn.Order_Date__c = Date.newInstance(year, i, 10);
            sellinList.add(sellIn);
        }
        insert sellinList;
        Test.startTest();
        Database.executeBatch(new SellinToPurchaseBatch('Test', null , new List<Id>{country.Id}, new List<Id>{supplier.Id}, null, null, year, null));
        Test.stopTest();
        // Assertions.
        purchase = [SELECT TO1__c, TO2__c, TO3__c, TO4__c, TO5__c, TO6__c, TO7__c, TO8__c, TO9__c, TO10__c, TO11__c, TO12__c, YTD_TO__c,
                    Qty1__c, Qty2__c, Qty3__c, Qty4__c, Qty5__c, Qty6__c, Qty7__c, Qty8__c, Qty9__c, Qty10__c, Qty11__c, Qty12__c, YTD_QTY__c,
                    Sales_Cost_M1__c, Sales_Cost_M2__c, Sales_Cost_M3__c, Sales_Cost_M4__c, Sales_Cost_M5__c, Sales_Cost_M6__c, Sales_Cost_M12__c,
                    Front_Margin_M1__c, Front_Margin_M2__c, Front_Margin_M3__c, Front_Margin_M4__c, Front_Margin_M5__c, Front_Margin_M6__c,
                    Front_Margin_M7__c, Front_Margin_M8__c, Front_Margin_M9__c, Front_Margin_M10__c, Front_Margin_M11__c, Front_Margin_M12__c, PG__c
                    FROM Purchases_Flow_PG__c WHERE Id = :purchase.Id];
        system.assertEquals(9+200, purchase.TO1__c);
        system.assertEquals(80+16+200, purchase.TO2__c);
        system.assertEquals(5+2+10, purchase.Qty2__c);
        system.assertEquals(1, purchase.Sales_Cost_M1__c);
        system.assertEquals(10+2, purchase.Sales_Cost_M2__c);
        system.assertEquals(12, purchase.Sales_Cost_M12__c);
        system.assertEquals(1, [SELECT COUNT() FROM Purchases_Flow_PG__c]);
    }
}