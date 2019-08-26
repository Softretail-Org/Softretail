/**
 * @Description Class used in unit test to create common data
 **/
@isTest
public class TestDataFactory {

    // Declaration of private static variable in order to use access them via a method from the Unit Test classes.
    private static Integer randomNumber;
    // Declaration of public static variable in order to use them directly from the Unit Test classes.
    public static final Integer year = System.Today().year();
    public static final Integer month = System.Today().month();
    public static final String currencyIsoCode = NegoptimHelper.getCorporateCurrency();
    public static final Map<String, Id> buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Orga_BU__c.SObjectType);
    public static final Map<String, Id> commercialPlanRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Commercial_Plan__c.SObjectType);
    public static final Map<String, Id> productAssortmentIntroRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Product_Assortment_Introduction_History__c.SObjectType);
    public static final Map<String, Id> assortmentRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment_BU__c.SObjectType);
    public static final Map<String, Id> productRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Product2.SObjectType);
    
    // Method to increment randomNumber
    private static Integer getRandomNumber() {
        if (randomNumber == null)
            randomNumber = (Integer)(Math.random()*9999);
        return randomNumber++;
    }
    /**
     * Single creations.
     *******************/
     
    /* BUSINESS UNIT */
    // Country List creation.
    public static Country_List__c createCountry(Boolean doInsert, String name, String code) {
        Country_List__c myCountry = new Country_List__c(Name = name, Country_Code__c = code);
        if (doInsert) insert myCountry;
        System.assert(true);
        return myCountry;
    }
    // Region creation.
    public static Orga_BU__c createBURegion(Boolean doInsert, String name) {
        Orga_BU__c region = new Orga_BU__c(Name = name, BU_Code__c = name, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
        region.RecordTypeId = buRTIds.get('Region');
        if (doInsert) insert region;
        System.assert(true);
        return region;
    }
    // Group creation.
   	public static Orga_BU__c createGroupBU(Boolean doInsert, String name) {
   		String rdm = String.valueOf(getRandomNumber());
   		Orga_BU__c groupBU = new Orga_BU__c(Name = 'Group ' + rdm, BU_Code__c = 'G' + rdm, ISO_Country_Code__c = 'LBN',
        								BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', CurrencyIsoCode = currencyIsoCode);
   		groupBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Group');
       	if (doInsert) insert groupBU;
       	System.assert(true);
       	return groupBU;
   	}
   	// List BU creation.
    public static Orga_BU__c createBUList(Boolean doInsert, Id countryId) {
    	String rdm = String.valueOf(getRandomNumber());
        Orga_BU__c listBU = new Orga_BU__c(Name = rdm, BU_Code__c = rdm, Country_origin__c = countryId, BU_ODate__c = date.newInstance(year, 1, 1),
        					Status__c = 'Open', CurrencyIsoCode = currencyIsoCode);
        listBU.RecordTypeId = buRTIds.get('List');
        if (doInsert) insert listBU;
        System.assert(true);
        return listBU;
    }
    // Country creation.
    public static Orga_BU__c createBUCountry(Boolean doInsert, Country_List__c c, Id regionId) {
        Orga_BU__c country = new Orga_BU__c(Name = c.Name, BU_Code__c = c.Country_Code__c + getRandomNumber(), ISO_Country_Code__c = c.Country_Code__c,
										Country__c = c.Name, Country_Zone_origin__c = regionId, Status__c = 'Open',
										BU_ODate__c = date.newInstance(year, 1, 1), CurrencyIsoCode = currencyIsoCode);
        country.RecordTypeId = buRTIds.get('Country');
        if (doInsert) insert country;
        System.assert(true);
        return country;
    }
    // Legal creation.
    public static Orga_BU__c createBULegal(Boolean doInsert, Country_List__c c) {
        Orga_BU__c legal = new Orga_BU__c(Name = 'Legal ' + c.Name, BU_Code__c = 'L' + c.Country_Code__c, Country__c = c.Name,
  										Status__c = 'Open', BU_ODate__c = date.newInstance(year, 1, 1));
        legal.RecordTypeId = buRTIds.get('Legal');
        if (doInsert) insert legal;
        System.assert(true);
        return legal;
    }
    // Banner creation.
    public static Orga_BU__c createBUBanner(Boolean doInsert, Orga_BU__c country) {
    	String rdm = String.valueOf(getRandomNumber());
        Orga_BU__c banner = new Orga_BU__c(Name = 'Banner ' + rdm, BU_Code__c = 'B' + rdm, Country__c = country.Name, Country_origin__c = country.Id,
        								Status__c = 'Open', Format_Origin__c = 'Supermarket', BU_ODate__c = date.newInstance(year, 1, 1),
        								CurrencyIsoCode = currencyIsoCode);
        banner.RecordTypeId = buRTIds.get('Banner');
        if (doInsert) insert banner;
        System.assert(true);
        return banner;
    }
    // Assortment Cluster creation.
    public static Orga_BU__c createBUAssortCluster(Boolean doInsert, Id countryId, String strat) {
    	String rdm = String.valueOf(getRandomNumber());
        Orga_BU__c assort = new Orga_BU__c(Name = 'Assort Cluster' + rdm, BU_Code__c = rdm, Country_origin__c = countryId,
                                           Status__c = 'Open', Assortment_Strat__c = strat);
        assort.RecordTypeId = buRTIds.get('Assortment_Cluster');
        if (doInsert) insert assort;
        System.assert(true);
        return assort;
    }
    // Warehouse creation.
   	public static Orga_BU__c createWarehouseBU(Boolean doInsert, Id countryId) {
        String rdm = String.valueOf(getRandomNumber());
   		Orga_BU__c warehouse = new Orga_BU__c(Name = 'Warehouse' + rdm, BU_Code__c = rdm, Country_origin__c = countryId, Status__c = 'Open',
            								BU_ODate__c = date.newInstance(year, 1, 1), CurrencyIsoCode = currencyIsoCode);
   		warehouse.RecordTypeId = buRTIds.get('Warehouse');
       	if (doInsert) insert warehouse;
       	System.assert(true);
       	return warehouse;
   	}
    
   	/* HIERARCHY ELEMENT + BRAND + PRODUCT + SELL IN */
    // Department creation.
    public static Orga_HE__c createDepartment(Boolean doInsert, Id parentId) {
        String rdm = String.valueOf(getRandomNumber());
        Orga_HE__c department = new Orga_HE__c(Name = 'DPT ' + rdm, Elt_Code__c = 'D' + rdm, Parent_Element__c = parentId, Level__c = 1,
                                               Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true,
                                               Status_BDate__c = date.newInstance(year, 1, 1), Status__c = 'Active');
        if (doInsert) insert department;
        System.assert(true);
        return department;
    }
    // Section creation.
    public static Orga_HE__c createSection(Boolean doInsert, Id parentId) {
        String rdm = String.valueOf(getRandomNumber());
        Orga_HE__c section = new Orga_HE__c(Name = 'SEC ' + rdm, Elt_Code__c = 'S' + rdm, Parent_Element__c = parentId, Level__c = 2,
                                            Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c = false,
                                            Status_BDate__c = date.newInstance(year, 1, 1), Status__c = 'Active', Set_Product_link_level__c = true);
        if (doInsert) insert section;
        System.assert(true);
        return section;
    }
    // Brand creation.
    public static Sup_Brand__c createBrand(Boolean doInsert, Id supplierId) {
        String rdm = String.valueOf(getRandomNumber());
        String name = 'BRAND ' + rdm;
        Sup_Brand__c brand = new Sup_Brand__c(Name = name, Brand_Owner__c = supplierId, Status_BDate__c = date.newInstance(year, 1, 1));
        if (doInsert) insert brand;
        System.assert(true);
        return brand;
    }
    // Product creation.
    public static Product2 createProduct(Boolean doInsert, Id sectionId, Id supplierId) {
    	String rdm = String.valueOf(getRandomNumber());
        Product2 product = new Product2(Name = 'PRD ' + rdm, ProductCode = 'P' + rdm, Product_EAN__c = '10000' + rdm,
                                        Category__c = sectionId, Product_MasterSupplier__c = supplierId, IsActive = true,
                                        Ext_Id__c = '10000' + rdm + '_' + 'P' + rdm);
        if (doInsert) insert product;
        System.assert(true);
        return product;
    }
    // Sell_in_flow creation.
    public static Sell_in_Flow__c createSellinFlow(Boolean doInsert, Sup_sup_NegoScope__c NS, Orga_HE__c section, Product2 product, Date invoiceDate) {
        Sell_in_Flow__c sellIn = new Sell_in_Flow__c(BU__c = NS.Supplier__r.Country_origin__c, Master_BU__c = NS.Supplier__r.Country_origin__c, 
        								Supplier__c = NS.Supplier__c, Structure_level__c = section.Id, Mvt_Purch_Product__c = product.Id,
        								Invoice_Date__c = invoiceDate, Order_Date__c = invoiceDate, Invoice_Net_Amount_woTax__c = 100,
                                        Footer_Order_Discount__c = 20, Invoice_Quantity__c = 5, Unit_Cost__c = 2, Gross_Price__c = 200,
                                        List_price__c = 100, Net_Price__c = 50);
        if (doInsert) Database.insert(sellIn);
        System.assert(true);
        return sellIn;
    }
    
    /* SUPPLIER + NEGOSCOPE */
    // Supplier creation.
    public static Sup_Supplier__c createSupplier(Boolean doInsert, Orga_BU__c country, Boolean withNS) {
    	String rdm = String.valueOf(getRandomNumber());
        Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'SUP ' + rdm, Code__c = rdm, Country_origin__c = country.Id, Acc_Country__c = country.Name,
        								Is_Default_NegoScope__c = withNS, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false,
        								Status__c = 'Active', CurrencyIsoCode = currencyIsoCode);
        if (doInsert) insert supplier;
        System.assert(true);
        return supplier;
    }
    // Get the list of NS related to the supplier passed by parameter.
	public static List<Sup_sup_NegoScope__c> getNSs(Id SupplierId) {
		System.assert(true);
		return [SELECT Id, Supplier__c, Supplier__r.Name, Supplier__r.Code__c, Supplier__r.Country_origin__c, OwnerId FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplierId];
 	}
 	// NS creation.
 	public static Sup_sup_NegoScope__c createNS(Boolean doInsert, Id SupplierId) {
		String rdm = String.valueOf(getRandomNumber());
		Sup_sup_NegoScope__c NS = new Sup_sup_NegoScope__c(Name = 'NS' + rdm, Supplier__c = supplierId, Status__c = 'Active',
                                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
 		if (doInsert) insert NS;
 		System.assert(true);
        return NS;
 	}
 	
 	// NS Brand creation.
 	public static Sup_NS_Brand__c createNSBrand(Boolean doInsert, Sup_sup_NegoScope__c NS, Id brandId) {
		Sup_NS_Brand__c NSBrand = new Sup_NS_Brand__c(Sup_Scope_Brand__c = brandId, Supplier__c = NS.Supplier__c, Sup_sup_NegoScope__c = NS.Id);
 		if (doInsert) insert NSBrand;
 		System.assert(true);
        return NSBrand;
 	}
 	
 	// NS HE creation.
 	public static Supplier_NS_HE__c createNSHE(Boolean doInsert, Sup_sup_NegoScope__c NS, Id sectionId) {
 		Supplier_NS_HE__c NSHE = new Supplier_NS_HE__c(Sup_sup_NegoScope__c = NS.Id, Structure_Element__c = sectionId);
 		if (doInsert) insert NSHE;
 		System.assert(true);
        return NSHE;
 	}
 	
 	// NS PG creation.
 	public static Sup_NS_PG__c createNSPG(Boolean doInsert, Sup_sup_NegoScope__c NS, Id PGId) {
 		Sup_NS_PG__c NSPG = new Sup_NS_PG__c(Sup_PG__c = PGId, Supplier__c = NS.Supplier__c, Sup_sup_NegoScope__c = NS.Id);
 		if (doInsert) insert NSPG;
 		System.assert(true);
        return NSPG;
 	} 
 	
    /* CONTRACT + CONDITION */
    // Contract creation.
    public static Contract__c createContract(Boolean doInsert, Sup_sup_NegoScope__c NS, Date beginDate, Date endDate) {
        String rdm = String.valueOf(getRandomNumber());
        Contract__c contract = new Contract__c(Name = NS.Supplier__r.Name + ' - Contract ' + year, Supplier__c = NS.Supplier__c,
                                               Supplier_Nego_Scope__c = NS.Id, Contract_BU__c = NS.Supplier__r.Country_origin__c,
                                               BU_Source__c = NS.Supplier__r.Country_origin__c, Contract_BDate__c = beginDate,
                                               Contract_EDate__c = endDate, Duration__c = beginDate.monthsBetween(endDate) + 1,
                                               Contract_Type__c = 'Contract', Status__c = 'Signed', Ext_id__c = rdm, D_N__c = 'N',
                                               Duration_type__c = 'Month', Contract_Numbder__c = 'c' + rdm);
        if (doInsert) Database.insert(contract);
		System.assert(true);
        return contract;
    }
    public static Contract__c createContract(Boolean doInsert, Orga_BU__c country, Sup_Supplier__c supplier, Sup_sup_NegoScope__c NS) {
        String rdm = String.valueOf(getRandomNumber());
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id,
                                               Supplier_Nego_Scope__c = NS.Id, Contract_BU__c = country.Id,
                                               BU_Source__c = country.Id, Contract_BDate__c = Date.newInstance(year, 1, 1),
                                               Contract_EDate__c = Date.newInstance(year, 12, 31), Duration__c = 12,
                                               Contract_Type__c = 'Contract', Status__c = 'Signed', Ext_id__c = rdm, D_N__c = 'N',
                                               Duration_type__c = 'Month', Contract_Numbder__c = 'c' + rdm);
        if (doInsert) Database.insert(contract);
        System.assert(true);
        return contract;
    }
	// Tarrif Condition creation.
    public static Pol_Com_Condition__c createTariffCondition(Boolean doInsert, Integer pickListValue, Integer indexValue) {
    	String rdm = String.valueOf(getRandomNumber());
    	// Get field describe.
    	Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        // Get the picklist value.
        String plv = fieldResult.getPicklistValues().get(pickListValue).getValue();
        // Create an instance of Tarrif Condition.
        Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Index__c = 'Index' + indexValue,
        								Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = rdm,
        								Abrev__c = 'TC', Gen_Name_com__c = 'TC', Name_Com__c = 'TC', Name_Fi__c = 'TC', Name_Leg__c = 'TC',
        								Gen_Name_Fi__c = 'TC', Gen_Name_Leg__c = 'TC', VAT_Type__c = 'Rebate', Acc_Document_Type__c = 'Credit Note Request');
        // Do insertion.
        if (doInsert) insert tariffCondition;
        System.assert(true);
        return tariffCondition;
    }
 	// Condition creation.
 	public static Contract_Discount__c createCondition(Boolean doInsert, Pol_Com_Condition__c tariffCondition, Contract__c contract, Date beginDate, Date endDate) {
    	Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
    									Contract__c = contract.Id, Product_Scope__c = contract.Supplier_Nego_Scope__c, BU_Scope__c = contract.BU_Source__c,
    									Disc_BDate__c = beginDate, Disc_EDate__c = endDate, CurrencyIsoCode = currencyIsoCode);
    	if (doInsert) Database.insert(condition);
    	System.assert(true);
        return condition;
    }
    // Pol Sale Condition creation.
    public static Pol_Sale_Condition__c createPolSaleCondition(Boolean doInsert, Id countryId) {
    	String rdm = String.valueOf(getRandomNumber());
    	Pol_Sale_Condition__c saleCond = new Pol_Sale_Condition__c(Name='Sale Condition ' + rdm, Master_BU__c = countryId, Status_BDate__c = date.newInstance(year, 1, 1));
    	if (doInsert) Database.insert(saleCond);
    	System.assert(true);
       	return saleCond;
    }
    // Group Contract creation.
    public static Contract_Group__c createContractGroup(Boolean doInsert, Sup_sup_NegoScope__c NS, Date beginDate, Date endDate, String name) {
    	String rdm = String.valueOf(getRandomNumber());
        Contract_Group__c contractGroup = new Contract_Group__c(Name = name + ' - ' + rdm + ' - ' + year, Contract_Number__c = rdm,
        								Origin_Supplier_Code__c = NS.Supplier__r.Code__c, Supplier__c = NS.Supplier__c, Supplier_NegoScope__c = NS.Id,
        								Start_Date__c = beginDate, End_date__c = endDate, Contract_Year__c = year, Origin_Supplier__c = 'Supplier',
                                        Contract_type__c = 'Contract', Header_Integration_Status__c = 'New', Last_Integration_Date__c = System.Today(),
                                        Status__c = 'New');
        if (doInsert) Database.insert(contractGroup);
        System.assert(true);
        return contractGroup;
    }
    // Group Contract Detail creation.
    public static Contract_Group_Detail__c createConditionGroup(Boolean doInsert, Contract_Group__c contractGroup, Pol_Com_Condition__c tariffCondition) {
        Contract_Group_Detail__c conditionGroup = new Contract_Group_Detail__c(Contract_List_Group__c = contractGroup.Id, Disc_BDate__c = contractGroup.Start_Date__c,
        								Disc_EDate__c = contractGroup.End_date__c, Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c,
        								Condition_name__c = tariffCondition.Id, Origin_Disc_Code__c = 'DC', Origin_Disc_Code2__c = 'DC',
        								Origin_Disc_name__c = 'Rebate', Order_Number__c = 1, Line_Integration_Status__c = 'New',
                                       	Amount__c = 100, Percent__c = 10, Status__c = 'New', Last_Integration_date__c = System.Today());        
        if (doInsert) Database.insert(conditionGroup);
        System.assert(true);
        return conditionGroup;
    }
    
    /* PRODUCT GROUP + PURCHASE */
    // Supplier PG Mapping creation.
    public static Supplier_PG_Mapping__c createPG(Boolean doInsert, Id supplierId, Id departmentId, Id sectionId) {
    	String rdm = String.valueOf(getRandomNumber());
    	Supplier_PG_Mapping__c PG = new Supplier_PG_Mapping__c(Supplier__c = supplierId, Department__c = departmentId, Section__c = sectionId,
										Name = 'PG' + rdm, SNA_Code__c = rdm, GIMA_Code__c = rdm, CurrencyIsoCode = currencyIsoCode);
	    if (doInsert) Database.insert(PG);
	    System.assert(true);
       	return PG;
    }
    // Purchase Flow PG creation.
    public static Purchases_Flow_PG__c createPurchase(Boolean doInsert, Supplier_PG_Mapping__c PG, Id BUId) {
    	Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(PG__c = PG.Id, Supplier_Nego_Scope__c = PG.Nego_Scope__c,
    									Department__c = PG.Department__c, Section__c = PG.Section__c, Supplier__c = PG.Supplier__c,
    									BU__c = BUId, Year__c = year, CurrencyIsoCode = currencyIsoCode);
	    if (doInsert) Database.insert(purchase);
	    System.assert(true);
       	return purchase;
    }
    // Create an instance of Sup_sup_NegoScope__c
    public static Sup_sup_NegoScope__c createNegoScope(Boolean doInsert, Sup_Supplier__c supplier, String name) {
        Sup_sup_NegoScope__c negoScope = new Sup_sup_NegoScope__c(Supplier__c = supplier.id, Name = name,
                                                                  Acc_Address_External_Synchro__c = false,
                                                                  Admin_Address_External_Synchro__c = false);
		if (doInsert) insert negoScope;
        return negoScope;
    }
    
    /* INVOICE + PAIEMENT */
    // Invoice creation.
	public static Invoice__c createInvoice(Boolean doInsert, Contract__c contract, Date beginDate, Date endDate) {
        String rdm = String.valueOf(getRandomNumber());
        String invNum = 'Inv' + rdm;
        Invoice__c invoice = new Invoice__c(Inv_Business_Unit__c = contract.Supplier__r.Country_origin__c,
    									Inv_Contract__c = contract.Id, Inv_Supplier__c = contract.Supplier__c,
			        					Inv_Date__c = beginDate, Inv_DueDate__c = endDate, Invoice_Number__c = invNum,
				                     	Inv_Status__c = 'Printed', Inv_FiscalYear__c = System.Today().year(),
				                        Sequence_Date__c = 'Month', Sequence_Number__c = System.Today().month(), origin__c = 'Group',
				                        Status_BDate__c = System.Today(), Inv_PrintedDate__c = System.Today().addDays(-1));
        if (doInsert) Database.insert(invoice);
        System.assert(true);
        return invoice;
    }
    // Invoice Detail creation.
    public static Invoice_Detail__c createInvoiceDetail(Boolean doInsert, Id invoiceId, Contract_Discount__c condition) {
        String rdm = String.valueOf(getRandomNumber());
    	String invDetailComment = 'Comment ' + rdm;
        Invoice_Detail__c invDetail = new Invoice_Detail__c(Invoice__c = invoiceId, Discount__c = condition.Id, 
    									Inv_Detail_Condition__c = condition.Condition_Type__c, Inv_Detail_Comment__c = invDetailComment,
        								CurrencyIsoCode = currencyIsoCode);
        if (doInsert) Database.insert(invDetail);
        System.assert(true);
        return invDetail;
    }
    // Accounting Scheme creation.
    public static Accounting_Scheme__c createAccountingScheme(Boolean doInsert, Id BUId, Id creditedCompanyId, Id debitedcompanyId, String recordTypeName) {
    	Accounting_Scheme__c accountingScheme = new Accounting_Scheme__c(Business_Unit__c = BUId, Credited_Company__c = creditedCompanyId, Debited_Company__c = debitedcompanyId);
        accountingScheme.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Accounting_Scheme__c.SObjectType, recordTypeName);
        if (doInsert) Database.insert(accountingScheme);
        System.assert(true);
        return accountingScheme;
    }
	// Accounting Closing creation.
    public static Accounting_Closing__c createAccountingClosing(Boolean doInsert, Id creditedCompanyId) {
    	Accounting_Closing__c accountingClosing = new Accounting_Closing__c(Business_Unit__c = creditedCompanyId, Closing_Date__c = System.today(),
										Invoices__c = true, Payments__c = false, Redistributions__c = false, Status__c = 'Preview');
        if (doInsert) Database.insert(accountingClosing);
        System.assert(true);
        return accountingClosing;
    }
    // Accounting Entry creation.
    public static Accounting_Entry__c createAccountingEntry(Boolean doInsert, Id accountingClosingId, Id accountingSchemeId, Id creditCompanyId, Id debitedCompanyId) {
		Accounting_Entry__c accountingEntry = new Accounting_Entry__c(Entry_Type__c = 'Invoice', Accounting_Closing__c = accountingClosingId,
                                          Accounting_Scheme_Line__c = accountingSchemeId, Credited_Company__c = creditCompanyId, Debited_Company__c = debitedCompanyId,
                                          Entry_Label__c = 'JV ' + ' / Campagne ' + year, Comment__c = '', VAT_rate__c = null); 
        if (doInsert) Database.insert(accountingEntry);
        System.assert(true);
        return accountingEntry;
    }
    
    // Invoice Group creation.
    public static Invoice_Group__c createInvoiceGroup(Boolean doInsert, Id supplierId, Date beginDate, Date endDate) {
        String rdm = String.valueOf(getRandomNumber());
    	String invNum = 'Inv' + rdm;
    	Invoice_Group__c invGroup = new Invoice_Group__c(Supplier__c = supplierId, Invoice_Date__c = beginDate, Invoice_Due_Date__c = endDate,
    									Status__c = 'Validated', Invoice_Number__c = invNum, Document_type__c = 'A', Invoice_Year__c = System.Today().year());
		if (doInsert) Database.insert(invGroup);
		System.assert(true);
       	return invGroup;
    }
    // Paiment Group creation.
    public static Invoice_Payment_Group__c createPaymentGroup(Boolean doInsert, Id invoiceGroupId) {
        String rdm = String.valueOf(getRandomNumber());
		String invNum = 'Inv' + rdm;
    	Invoice_Payment_Group__c paymentGroup = new Invoice_Payment_Group__c(Invoice_Reference__c = invoiceGroupId, Invoice_Number__c = invNum, Status__c = 'Validated');
		if (doInsert) Database.insert(paymentGroup);
		System.assert(true);
       	return paymentGroup;
    }
    // Invoice Paiment creation.
    public static Invoice_Paiement__c createInvoicePaiment(Boolean doInsert, Id supplierId, Id paymentGroupId, Id creditedStoreId) {
        String rdm = String.valueOf(getRandomNumber());
		String comm = 'Comment ' + rdm;
		Invoice_Paiement__c invoicePaiement = new Invoice_Paiement__c(Supplier__c = supplierId, Linked_Payment_Group__c = paymentGroupId,
										Payment_BU__c = creditedStoreId, Comment__c = comm, Origin__c = 'Group', Payment_type__c = 'Cheque');
       	if (doInsert) Database.insert(invoicePaiement);
       	System.assert(true);
       	return invoicePaiement;
    }
    // Invoice Paiment Detail creation.
    public static Invoice_Paiement_Detail__c createInvoicePaimentDetail(Boolean doInsert, Id invDetailId, Id invoicePaymentId) {
		Invoice_Paiement_Detail__c invoicePaiementDetail = new Invoice_Paiement_Detail__c(Invoice_Line__c = invDetailId, Paiement__c = invoicePaymentId);
       	if (doInsert) Database.insert(invoicePaiementDetail);
       	System.assert(true);
       	return invoicePaiementDetail;
    }
    
    /* COMMERCIAL PLAN */
    // Commercial Plan creation.
    public static Commercial_Plan__c createCommercialPlan(Boolean doInsert, Date beginDate, Date endDate) {
    	String rdm = String.valueOf(getRandomNumber());
        Commercial_Plan__c commercialPlan = new Commercial_Plan__c(Name = 'Comm' + rdm, Start_Date__c = beginDate, End_Date__c = endDate,
                                                                   Event_Type__c = 'Collection', Event_Support__c = 'Front path', Status__c = 'In Preparation',
                                                                   CurrencyIsoCode = currencyIsoCode);
        commercialPlan.RecordTypeId = commercialPlanRTIds.get('Sales_Floor_Event');
        if (doInsert) Database.insert(commercialPlan);
       	System.assert(true);
       	return commercialPlan;
    }
    // Commercial Plan Detail creation.
    public static Commercial_Plan_Detail__c createCommercialPlanDetail(Boolean doInsert, Id commercialPlanId, Sup_sup_NegoScope__c NS) {
        Commercial_Plan_Detail__c commercialPlanDetail = new Commercial_Plan_Detail__c(Commercial_Event__c = commercialPlanId, Nego_Scope__c = NS.Id,
                                                                                       Supplier__c = NS.Supplier__c, Contribution_Unit_Quantity__c = 1, Contribution_Unit_Amount__c = 1,
                                                                                       Statut__c = 'In process of validation', Temp_Contract_Reference__c = 'Temp Ref Contract...',
                                                                                       CurrencyIsoCode = currencyIsoCode);
   		if (doInsert) Database.insert(commercialPlanDetail);
   		System.assert(true);
        return commercialPlanDetail;
    }
    // Commercial Plan Task.
    public static Commercial_Plan_Task__c createCommercialPlanTask(Boolean doInsert, Id BUId) {
    	Commercial_Plan_Task__c task = new Commercial_Plan_Task__c(BU__c = BUId, Event_Type__c = 'Web',
        								Level__c = 'Regular', Status__c = 'In process of building');
       	if (doInsert) Database.insert(task);
   		System.assert(true);
        return task;
    }
    // Commercial Plan Task List
    public static Commercial_Plan_Task_List__c createCommercialPlanTaskList(Boolean doInsert, Id taskId) {
    	Commercial_Plan_Task_List__c todo = new Commercial_Plan_Task_List__c(Critical_to_continue__c = true, Duration_nb_day__c = 1,
        								Step__c = 'S1', Commercial_Plan_Task__c = taskId);
    	if (doInsert) Database.insert(todo);
   		System.assert(true);
        return todo;
    }
    
    /* INVOICE BU DISPATCH */
    public static Inv_BUDispatch__c createInvoiceDispatch(Boolean doInsert, Id countryId, Integer sequenceNumber) {
		Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequenceNumber, Inv_Fiscal_Year__c = year, Inv_BU__c = countryId);
    	if (doInsert) Database.insert(dispatchHead);
   		System.assert(true);
        return dispatchHead;
    }
    
    public static Inv_BUDispatch_Details__c createInvoiceDispatchDetail(Boolean doInsert, Id dispatchHeadId, Supplier_PG_Mapping__c PG, Contract_Discount__c condition, Id storeId, Integer sequenceNumber) {
		Inv_BUDispatch_Details__c dispatchDetail = new Inv_BUDispatch_Details__c(Inv_DispatchHead__c = dispatchHeadId, Supplier__c = PG.supplier__c,
    								Contract__c = condition.Contract__c, Discount__c = condition.Id, Inv_BUDispatch__c = storeId, 
									Hierarchy_level_dispatch__c = PG.Section__c, PG__c = PG.Id, Status__c = 'New', Sequence__c = sequenceNumber);
        if (doInsert) Database.insert(dispatchDetail);
   		System.assert(true);
        return dispatchDetail;
    }
    
    /* SETTINGS + OTHERS */
    // Batch creation.
    public static Batch__c createBatch(Boolean doInsert) {
        Batch__c batch = new Batch__c(Name = 'Batch', Batch_Counter__c = 1, Entity_Code__c = 'X001', Movement_Type__c = 'FA', Ext_id__c = 'X001',
        								Processing_date__c = '05-11-2017', Processing_hour__c = '20:15', Records_Count__c = 10001);
        if (doInsert) Database.insert(batch);
        System.assert(true);
        return batch;
    }
    // Negoptim Custom Settings creation.
    public static NegoptimCustomSettings__c createNegoptimCustomSettings(Boolean doInsert) {
        NegoptimCustomSettings__c negoCustomSettings = new NegoptimCustomSettings__c(Name = 'NegoptimSettings', CSV_Delimiter__c = ',',
                                                                                     Group_Code_BU_for_Integration__c = 'AMC',
                                                                                     Allowed_profiles_to_manage_Products__c = UserInfo.getProfileId());
        if (doInsert) Database.insert(negoCustomSettings);
        System.assert(true);
        return negoCustomSettings;
    }
    // Document creation.
    public static Document createDocument(Boolean doInsert, Id folderId, String content) {
    	Document document = new Document(Name = NegoptimHelper.DOCUMENT_SETTINGS_NAME, FolderId = folderId, Body = Blob.valueof(content));
        if (doInsert) insert document;
        System.assert(true);
        return document;
    }
    
    /**
     * Multiple & complex creations.
     *******************************/
     
    /* BUSINESS UNITS */
    // List of stores creation.
	public static List<Orga_BU__c> createBUStores(Boolean doInsert, Orga_BU__c country, Id legalId, Integer nbr) {
        List<Orga_BU__c> stores = new List<Orga_BU__c>();
        for(Integer i = 0; i < nbr; i++) {
            Orga_BU__c store = new Orga_BU__c(Name = 'Store ' + i, BU_Code__c = 'Store ' + i, Country_origin__c = country.Id,
            								Country_Zone_origin__c = country.Country_Zone_origin__c, Country__c = country.Name,
                                          	Legal_Form__c = legalId, Status__c = 'Open', BU_ODate__c = date.newInstance(year, 1, 1),
                                          	CurrencyIsoCode = currencyIsoCode);
            store.RecordTypeId = buRTIds.get('Store');
            stores.add(store);
        }
        if (doInsert) insert stores;
        System.assert(true);
        return stores;
    }
    // List of warehouses creation.
    public static List<Orga_BU__c> createBUWarehouses(Boolean doInsert, Orga_BU__c country, String n, Integer nbr) {
        List<Orga_BU__c> warehouses = new List<Orga_BU__c>();
        for(Integer i = 0; i < nbr; i++) {
            Orga_BU__c warehouse = new Orga_BU__c(Name = 'WareH ' + i, BU_Code__c = 'WareH ' + i, Country_origin__c = country.Id, Status__c = 'Open',
            								BU_ODate__c = date.newInstance(year, 1, 1), CurrencyIsoCode = currencyIsoCode);
            warehouse.RecordTypeId = buRTIds.get('Warehouse');
            warehouses.add(warehouse);
        }
        if (doInsert) insert warehouses;
        System.assert(true);
        return warehouses;
    }
    
    /* SUPPLIERS */
    // List of suppliers creation.
    public static List<Sup_Supplier__c> createSuppliers(Boolean doInsert, Orga_BU__c country, Boolean withNS, Integer nb) {
    	String rdm = String.valueOf(getRandomNumber());
        List<Sup_Supplier__c> suppliers = new List<Sup_Supplier__c>();
        for (Integer i = 0; i < nb; i++) {
        	suppliers.add(new Sup_Supplier__c(Name = rdm + i, Code__c = rdm + i, Country_origin__c = country.Id, Acc_Country__c = country.Name,
        									Is_Default_NegoScope__c = withNS, Status__c = 'Active', Acc_Address_External_Synchro__c = false,
            								Admin_Address_External_Synchro__c = false, CurrencyIsoCode = currencyIsoCode));
        }
        if (doInsert) insert suppliers;
        System.assert(true);
        return suppliers;
    }
    
    /* CONTRACTS + CONDITIONS */
    // List of tarrif conditions creation.
    public static List<Pol_Com_Condition__c> createTariffConditions(Boolean doInsert, Integer ndx, Integer nbr) {
    	String rdm = String.valueOf(getRandomNumber());
        List<Pol_Com_Condition__c> tariffConditions = new List<Pol_Com_Condition__c>();
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        for(Integer i = 0; i < nbr; i++) {
            String plv = fieldResult.getPicklistValues().get(i).getValue();
			Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Index__c = 'Index' + ndx,
        									Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'T' + rdm, Abrev__c = 'TC', Gen_Name_com__c = 'TC',
        									Name_Com__c = 'TC', Name_Fi__c = 'TC', Name_Leg__c = 'TC', Gen_Name_Fi__c = 'TC', Gen_Name_Leg__c = 'TC',
        									VAT_Type__c = 'Rebate', Acc_Document_Type__c = 'Credit Note Request');
            tariffConditions.add(tariffCondition);
        }
        if (doInsert) insert tariffConditions;
        System.assert(true);
        return tariffConditions;
    }
    // Create contract with one or more condition(s). // TODO: Add Begin and End Dates.
    public static List<SObject> createContractWithConditions(Boolean doInsert, Sup_Supplier__c supplier, Id NSId, Pol_Com_Condition__c tariffCondition, Integer nbrOfConditions) {
        String rdm = String.valueOf(getRandomNumber());
        List<SObject> contractWithConditions = new List<SObject>();
        String extCode = 'c' + rdm;
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Contract_BU__c = supplier.Country_origin__c,
        								Supplier_Nego_Scope__c = NSId, Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                               			Duration__c = 12, Contract_Type__c = 'Contract', Ext_id__c = extCode);
        contractWithConditions.add(contract);
        if (nbrOfConditions > 0) {
            Contract__c contractReference = new Contract__c(Ext_id__c = extCode);
            for (Integer i = 1; i < nbrOfConditions; i++) {
                Decimal percentage = Math.round(Math.random()*i / (i+1));
                Decimal amount = Math.round(Math.random()*9999 * i);
                Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c,
                								Condition_Type__c = tariffCondition.Id, Disc_BDate__c = contract.Contract_BDate__c,
                								Disc_EDate__c = contract.Contract_EDate__c, Product_Scope__c = contract.Supplier_Nego_Scope__c,
                                              	BU_Scope__c = contract.Contract_BU__c, Value_per__c = percentage, Value_amt__c = amount,
                                              	Is_Prenego_Envelop__c = true);
                condition.Contract__r = contractReference;
                contractWithConditions.add(condition);
            }
        }
        if (doInsert) Database.insert(contractWithConditions);
        System.assert(true);
        return contractWithConditions;
    }
    
    /* PRODUCT GROUPS + PURCHASES */
    // List of Supplier PG Mapping creation.
    public static List<Supplier_PG_Mapping__c> createPGs(Boolean doInsert, Id supplierId, Id departmentId, Id sectionId, Integer nb) {
		String rdm = String.valueOf(getRandomNumber());
		List<Supplier_PG_Mapping__c> PGs = new List<Supplier_PG_Mapping__c>();
		for (Integer i = 1; i <= nb; i++) {
	        Supplier_PG_Mapping__c PG = new Supplier_PG_Mapping__c(Name = 'PG' + rdm, Supplier__c = supplierId, Department__c = departmentId,
	        								Section__c = sectionId, SNA_Code__c = rdm + i, GIMA_Code__c = rdm + i, CurrencyIsoCode = currencyIsoCode);
	        PGs.add(PG);
	    }
	    if (doInsert) Database.insert(PGs);
	    System.assert(true);
       	return PGs;
    }
    // List of Purchase Flow PG creation.
    public static List<Purchases_Flow_PG__c> createPurchases(Boolean doInsert, List<Supplier_PG_Mapping__c> PGs, Contract__c contract, Id storeId, Integer nb) {
		List<Purchases_Flow_PG__c> purchases = new List<Purchases_Flow_PG__c>();
		for (Integer i = 0; i < nb; i++) {
	        Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = contract.Supplier__c, PG__c = PGs.get(i).Id, Supplier_Nego_Scope__c = PGs.get(i).Nego_Scope__c,
        									Department__c = PGs.get(i).Department__c, Section__c = PGs.get(i).Section__c,
        									Contrat1__c = contract.Id, BU__c = storeId, Year__c = year, CurrencyIsoCode = currencyIsoCode);
	        purchases.add(purchase);
	    }
	    if (doInsert) Database.insert(purchases);
	    System.assert(true);
       	return purchases;
    }
    
    /**
     * @description creates an Element Heirarchy Tree starting from the root
     * Note: the method executes (2 + depth) DMLs
     * @param depth the pepth of the tree
     * @param elementsPerLevel how many elements per level
	*/
    public static List<Orga_HE__c> createElementHierarchy(Integer depth, Integer elementsPerLevel) {
        Id rootId = NegoptimHelper.getRootId();
        Orga_HE__c root = [SELECT Id, Level__c FROM Orga_HE__c WHERE Id = :rootId];
        Integer currentLevel = 1;
        List<Orga_HE__c> tempList = new List<Orga_HE__c>();
        List<Orga_HE__c> orgaHEList = new List<Orga_HE__c> {root};
        
        for (currentLevel = 1; currentLevel <= depth; currentLevel++) {
            for (Orga_HE__c parent : orgaHEList) {
                if (parent.Level__c == currentLevel - 1) {
                    for (Integer index = 0; index < elementsPerLevel; index++) {
                        Orga_HE__c element = createDepartment(false, parent.Id);
                        element.Level__c = currentLevel;
                        element.Set_Product_link_level__c = true;
                        tempList.add(element);
                    }
                }
            }
            insert tempList;
            orgaHEList.addAll(tempList);
            tempList.clear();
        }
        return orgaHEList;
    }
    
    // Create assortment BU with default record type = Nego
    public static Assortment_BU__c createAssortmentBU(Boolean doInsert, Orga_BU__c buSource, Orga_BU__c buTarget, Orga_HE__c category) {
        String rdm = String.valueOf(getRandomNumber());
        Assortment_BU__c assortment = new Assortment_BU__c(Name = rdm, Assortment_type__c = 'Out', BU_Source__c = buSource.Id, BU_Target__c = buTarget.Id,
                                                           Orga_HE__c = category.Id, Assortment__c = 'Deal', Status__c = 'Open (in bulding process)',
                                                           CurrencyIsoCode = currencyIsoCode, Ass_BDate__c = Date.newInstance(year, 1, 1),
                                                           Ass_EDate__c = Date.newInstance(year, 12, 31), Year__c = year);
        assortment.RecordTypeId = assortmentRTIds.get('Nego');
        if (doInsert) {
            insert assortment;
        }
        return assortment;
    }
    
    // Assortment Detail creation.
    public static Assortment_Detail__c createAssortmentDetail(Boolean doInsert, Id assortmentBUId, Product2 product, Id clusterId) {
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBUId, Product__c = product.Id, Category__c = product.Category__c,
                                                                         Movement_Date__c = Date.today(), Record_date__c = Date.today(), Client_Status__c = 'New',
                                                                         Ass_BU_Cluster__c = clusterId, Status__c = 'In preparation');
        if (doInsert) Database.insert(assortmentDetail);
        System.assert(true);
        return assortmentDetail;
    }
    
    // Assortment Detail Sequence creation.
    public static Assortment_Detail_Sequence__c createAssortmentDetailSequence(Boolean doInsert, Id assortmentDetailId) {
        Assortment_Detail_Sequence__c assortmentDetailSequence = new Assortment_Detail_Sequence__c(Assortment_Detail__c = assortmentDetailId, Year__c = year, Sequence__c = month);
        if (doInsert) Database.insert(assortmentDetailSequence);
        System.assert(true);
        return assortmentDetailSequence;
    }
    
    // Assortment Matrix review creation.
    public static Assortment_Matrix_review__c createAssortmentMatrixReview(Boolean doInsert, Id masterBUId, Id targetBUId, Id productId, String matrixName) {
        Assortment_Matrix_review__c assortmentMatrixReview = new Assortment_Matrix_review__c(BU_Source__c = masterBUId, BU_Target__c = targetBUId,  Produit__c = productId,
                                                                                             Sequence__c = month, Year__c = year, Name__c = matrixName);
        if (doInsert) Database.insert(assortmentMatrixReview);
        System.assert(true);
        return assortmentMatrixReview;
    }
    
    // Market Data Collection Head creation.
    public static Market_Data_Collection_Head__c createMarketDataCollectionHead(Boolean doInsert, Id masterBUId, Orga_BU__c targetBU, Orga_HE__c category, Sup_Supplier__c client) {
        Market_Data_Collection_Head__c marketHead = new Market_Data_Collection_Head__c(Ext_BU_Name__c = targetBU.Name, Orga_BU__c = targetBU.Id,
                                                                                       Ext_Category_Name__c = category.Name, Orga_HE__c = category.Id,
                                                                                       Ext_Client_Name__c = client.Name, Client__c = client.Id, Master_BU__c = masterBUId,
                                                                                       Flow_Type__c = 'Nielsen', Movement_Date__c = System.today(),
                                                                                       Origin_Type__c = 'CSV', Status__c = 'New', SEQ__c = month, Year__c = year);
        if (doInsert) Database.insert(marketHead);
        System.assert(true);
        return marketHead;
    }
    
    // Market Data Collection Detail creation.
    public static Market_Data_Collection_Detail__c createMarketDataCollectionDetail(Boolean doInsert, Id marketHeadId, Orga_BU__c targetBU, Orga_HE__c category, Product2 product, Sup_Brand__c brand) {
        Market_Data_Collection_Detail__c marketDetail = new Market_Data_Collection_Detail__c(Market_Data_Collection_Head__c = marketHeadId, Orga_BU__c = targetBU.Id, Ext_BU_Name__c = targetBU.Name,
                                                                                             Ext_Category_Name__c = category.Name, Orga_HE__c = category.Id, Ext_Product_EAN__c = product.Product_EAN__c,
                                                                                             Ext_Product_Name__c = product.Name, Product__c = product.Id, Ext_Brand_Name__c = brand.Name, Ext_Packaging__c = 'CONDITIONNEMENT',
                                                                                             //SEQ
                                                                                             SellIn_Quantity_SEQ__c = 0, SellOut_wTax_SEQ__c = 0, ND_1_SEQ__c = 0, WD_1_SEQ__c = 0, ND_2_SEQ__c = 0, WD_2_SEQ__c = 0,
                                                                                             Average_Retail_Price_SEQ__c = 0, Avg_Weekly_Sales_Ext_ClientBased__c = 0,
                                                                                             //YTD
                                                                                             SellOut_wTax_YTD__c = 0, ND_1_YTD__c = 0, WD_1_YTD__c = 0, ND_2_YTD__c = 0, WD_2_YTD__c = 0, Average_Retail_Price_YTD__c = 0,
                                                                                             //12M
                                                                                             SellOut_wTax_12M__c = 0, ND_1_12M__c = 0, WD_1_12M__c = 0, ND_2_12M__c = 0, WD_2_12M__c = 0, Average_Retail_Price_12M__c = 0,
                                                                                             Status__c = 'New', Sequence_Type__c = 'Month', SEQ__c = month, Year__c = year);
        if (doInsert) Database.insert(marketDetail);
        System.assert(true);
        return marketDetail;
    }
    
    // Market Review creation.
    public static Market_review__c createMarketReview(Boolean doInsert, Id masterBUId, String formatorigin, Id categoryId) {
        Market_review__c marketReview = new Market_review__c(Market__c = masterBUId, Channel__c = formatorigin, Orga_HE__c = categoryId, Year__c = year);
        if (doInsert) Database.insert(marketReview);
        System.assert(true);
        return marketReview;
    }
    
    // Market Review Detail BU creation.
    public static Market_Review_Detail_BU__c createMarketReviewDetailBU(Boolean doInsert, Id marketReviewId, Id targetBUId, Id productId) {
        Market_Review_Detail_BU__c marketReviewDetailBU = new Market_Review_Detail_BU__c(Market_review__c = marketReviewId, Orga_BU__c = targetBUId, Product__c = productId);
        if (doInsert) Database.insert(marketReviewDetailBU);
        System.assert(true);
        return marketReviewDetailBU;
    }
}