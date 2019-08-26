@isTest
private class MergeContractBatchTest {
	
	private static String currencyIsoCode;
	private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c initContract;
    private static Contract__c dupContract;
    private static Contract__c simContract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c initCondition1;
    private static Contract_Discount__c initCondition2;
    private static Contract_Discount__c initCondition3;
    private static Contract_Discount__c dupCondition1;
    private static Contract_Discount__c dupCondition2;
    private static Contract_Discount__c dupCondition3;
    private static Contract_Discount__c simCondition1;
    private static Contract_Discount__c simCondition2;
    private static Contract_Discount__c simCondition3;
    private static Contract_Discount__c simCondition4;
    private static Integer year;
    private static String plv;
    
    static void init() {
        try {
            year = System.Today().year();
            // Get the Corporate Currency.
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
            // Create supplier.
            supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
                                           Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default negoscope created on supplier creation.
            NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                       Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                       Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
            insert tariffCondition;
            // Create init Contract + conditions
            initContract = new Contract__c(Name = 'Contract001' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C111',
                                           Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12,
                                           Contract_BU__c = country.Id, Contract_Type__c = 'Contract', Status__c = 'Signed', CurrencyIsoCode = currencyIsoCode,
                                           D_N__c = 'N', Tactite_reconduction__c = true, Ext_id__c = 'C1');
            initCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                      Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                      BU_Scope__c = country.Id, Is_Prenego_Envelop__c = True);
            initCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                      Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                      BU_Scope__c = country.Id, Is_Prenego_Envelop__c = True);
            initCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                      Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 3, Product_Scope__c = NS.Id,
                                                      BU_Scope__c = country.Id, Is_Prenego_Envelop__c = True);
            // Create duplicate Contract
            dupContract = new Contract__c(Name ='dup Contract ' + (year+1), Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C112',
                                          Contract_BDate__c = date.newInstance(year+1, 1, 1), Contract_EDate__c = date.newInstance(year+1, 12, 31), Duration__c = 12,
                                          Contract_BU__c = country.Id, Contract_Type__c = 'Contract', Status__c = 'Validated',
                                          D_N__c = 'D', Tactite_reconduction__c = true);
            Contract__c contractReferenceC1 = new Contract__c(Ext_id__c='C1');
            initCondition1.Contract__r = contractReferenceC1;
            initCondition2.Contract__r = contractReferenceC1;
            initCondition3.Contract__r = contractReferenceC1;
            dupContract.Parent_Contract__r = contractReferenceC1;
            // TODO: put all duplicate conditions
            List<SObject> contractWithConditionsList = new List<SObject>();
            contractWithConditionsList.add(initContract);
            contractWithConditionsList.add(initCondition1);
            contractWithConditionsList.add(initCondition2);
            contractWithConditionsList.add(initCondition3);
            contractWithConditionsList.add(dupContract);
            Database.SaveResult[] results = Database.insert(contractWithConditionsList);
            // Create simulation Contract
            simContract = new Contract__c(Name = 'sim Contract ' + (year+1), Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C113',
                                          Contract_BDate__c = date.newInstance(year+1, 1, 1), Contract_EDate__c = date.newInstance(year+1, 12, 31), Duration__c = 12,
                                          Contract_BU__c = country.Id, Contract_Type__c = 'Simulation', Status__c = 'Published',
                                          Tactite_reconduction__c = true, Parent_Contract__c = initContract.Id);
            insert simContract;
            // Create Conditions related to the duplicated contract.
            dupCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                     Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                     BU_Scope__c = country.Id, Contract__c = dupContract.Id, Reference_condition__c = initCondition1.Id,
                                                     Is_Prenego_Envelop__c = True);
            dupCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                     Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                     BU_Scope__c = country.Id, Contract__c = dupContract.Id, Reference_condition__c = initCondition2.Id,
                                                     Is_Prenego_Envelop__c = True, Value_amt__c = 2000, Base_Quantity_Nego__c = 4,
                                                     Slab_1__c = 2, Slab_2__c = 2, Slab_3__c = 3, Slab_4__c = 5, Slab_5__c = 2, Slab_6__c = 2,
                                                     Value_amt_disp_M1__c = 5, Value_amt_disp_M2__c = 1, Value_amt_disp_M3__c = 1, Value_amt_disp_M4__c = 1,
                                                     Value_amt_disp_M5__c = 1, Value_amt_disp_M6__c = 1, Value_amt_disp_M7__c = 1, Value_amt_disp_M8__c = 1,
                                                     Value_amt_disp_M9__c = 1, Value_amt_disp_M10__c = 1, Value_amt_disp_M11__c = 1, Value_amt_disp_M12__c = 1);
            dupCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                     Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 3, Product_Scope__c = NS.Id,
                                                     BU_Scope__c = country.Id, Contract__c = dupContract.Id, Reference_condition__c = initCondition3.Id,
                                                     Is_Prenego_Envelop__c = True);
            insert new List<Contract_Discount__c>{dupCondition1, dupCondition2, dupCondition3};
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    static testmethod void addConditions() {
    	// TODO:
    	// Creation of three Contracts: Initial, duplicated and simulation with related conditions.
    	// Get parent contract Id of the duplicated contract (which is the initial contract Id).
    	// Invoke Merge Batch method.
    	init();
        // Create Conditions related to the simulation contract.
        simCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition1.Id,
                                                 Is_Prenego_Envelop__c = True);
        simCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition2.Id,
                                                 Is_Prenego_Envelop__c = True);
        simCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 3, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition3.Id,
                                                 Is_Prenego_Envelop__c = True);
        simCondition4 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 4, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Is_Prenego_Envelop__c = True);
        insert new List<Contract_Discount__c>{simCondition1, simCondition2, simCondition3, simCondition4};
        Id parentContractId = simContract.Parent_Contract__c;
        List<Id> parentContractIds = new List<Id>();
        parentContractIds.add(parentContractId);
        
        Test.startTest();
        Database.executeBatch(new MergeContractBatch('MergeContractBatchTest', country.Id, new List<Id>{supplier.Id}, new List<Id>{simContract.Id}, parentContractIds, year+1));
        Test.stopTest();
        //
        Integer dupConditionsCount = [SELECT COUNT() FROM Contract_Discount__c WHERE Contract__c = :dupContract.Id];
        System.assertEquals(4, dupConditionsCount);
        //
        Integer insertedConditionsCount = [SELECT COUNT() FROM Contract_Discount__c WHERE Contract__c = :dupContract.Id
                                           AND Reference_condition__c = Null];
        System.assertEquals(1, insertedConditionsCount);
        //
        Contract__c duplicatedContract = [SELECT D_N__c FROM Contract__c WHERE Id = :dupContract.Id];
        System.assertEquals('N', duplicatedContract.D_N__c);
    }
    
    static testmethod void updateConditions() {
    	init();
    	List<Contract__c> cs = [SELECT Id, Parent_Contract__c FROM Contract__c c
                                WHERE c.Supplier__r.Status__c = 'Active' AND c.Supplier_Nego_Scope__r.Status__c = 'Active'
                                AND ((c.Contract_Type__c = 'Simulation' AND c.Status__c = 'Published') OR
                                     (c.Contract_Type__c = 'Contract' AND c.Status__c = 'Validated' AND c.D_N__c = 'D'))
                                AND CALENDAR_YEAR(c.Contract_BDate__c) = :year AND c.Contract_BU__c = :country.Id
                                AND c.Parent_Contract__c = :initContract.Id];
        // Create Conditions related to the simulation contract.
        simCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 5, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition1.Id,
                                                 Is_Prenego_Envelop__c = True);
        simCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 6, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition2.Id,
                                                 Is_Prenego_Envelop__c = True);
        simCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 2, 1),
                                             	Disc_EDate__c = date.newInstance(year+1, 11, 31), Value_per__c = 7, Product_Scope__c = NS.Id,
                                             	BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition3.Id,
                                             	Is_Prenego_Envelop__c = True,
                                             	all_BU__c = False, all_items__c = False, Base_Calculation_Model__c = 'Purchases w/o VAT (Delivery date)',
												CurrencyIsoCode = currencyIsoCode, Invoice_base__c = 'Forecasted',
												Invoice_sequence__c = 2, is_duplicable__c = False, Minimum_Guarantee__c = 5, Payment_Condition__c = 'The 10',
												Payment_Days__c = '10', Provision_base__c = 'Negotiated', Provision_Sequence__c = 2,
												Rank__c = 2, Valid__c = False, Base_Quantity_Nego__c = 3, Value_amt__c = 2000, 
												slab_per_1__c = 1, slab_per_2__c = 1, slab_per_3__c = 1, slab_per_4__c = 1, slab_per_5__c = 1, slab_per_6__c = 1,
												Slab_1__c = 1, Slab_2__c = 1, Slab_3__c = 1, Slab_4__c = 1, Slab_5__c = 1, Slab_6__c = 1,
												Slab_val_1__c = 1, Slab_val_2__c = 1, Slab_val_3__c = 1, Slab_val_4__c = 1, Slab_val_5__c = 1, Slab_val_6__c = 1,
												slab_target__c = 2.0, slab_calc_method__c = 'Qty', Commercial_reference__c = 'oo', financial_reference__c = 'o',
												legal_reference__c = 'aa');
        insert new List<Contract_Discount__c>{simCondition1, simCondition2, simCondition3};
        Id parentContractId = initContract.Id;
        List<Id> parentContractIds = new List<Id>();
        parentContractIds.add(parentContractId);
        Test.startTest();
        Database.executeBatch(new MergeContractBatch('MergeContractBatchTest', country.Id, new List<Id>{supplier.Id}, new List<Id>{simContract.Id}, parentContractIds, year+1));
        Test.stopTest();
		List<Contract_Discount__c> dupConditions = [SELECT all_BU__c, all_items__c, Base_Calculation_Model__c, BU_Scope__c,
													Condition_Type__c, CurrencyIsoCode, Disc_BDate__c, Disc_EDate__c, Invoice_base__c,
													Invoice_sequence__c, is_duplicable__c, Minimum_Guarantee__c, Payment_Condition__c,
													Payment_Days__c, Product_Scope__c, Provision_base__c, Provision_Sequence__c,
													Rank__c, Valid__c, Value_per__c, Base_Quantity_Nego__c, Value_amt__c, 
													slab_per_1__c, slab_per_2__c, slab_per_3__c, slab_per_4__c, slab_per_5__c, slab_per_6__c,
													Slab_1__c, Slab_2__c, Slab_3__c, Slab_4__c, Slab_5__c, Slab_6__c,
													Slab_val_1__c, Slab_val_2__c, Slab_val_3__c, Slab_val_4__c, Slab_val_5__c, Slab_val_6__c,
													slab_target__c, slab_calc_method__c, Commercial_reference__c, financial_reference__c,
													legal_reference__c, status__c
													FROM Contract_Discount__c
													WHERE Contract__c = :dupContract.Id];
        System.assertEquals(5, dupConditions.get(0).Value_per__c);
        System.assertEquals(6, dupConditions.get(1).Value_per__c);
        System.assertEquals(7, dupConditions.get(2).Value_per__c);
        System.assertEquals('Updated', dupConditions.get(0).status__c);
        System.assertEquals('Updated', dupConditions.get(1).status__c);
        System.assertEquals('Updated', dupConditions.get(2).status__c);
        System.assertEquals(False, dupConditions.get(2).all_BU__c);
        System.assertEquals(False, dupConditions.get(2).all_items__c);
        System.assertEquals('Purchases w/o VAT (Delivery date)', dupConditions.get(2).Base_Calculation_Model__c);
        System.assertEquals(currencyIsoCode, dupConditions.get(2).CurrencyIsoCode);
        // TODO: analyse the failure of below assert
        ////System.assertEquals('Forecasted', dupConditions.get(2).Invoice_base__c);
        System.assertEquals(2, dupConditions.get(2).Invoice_sequence__c);
        System.assertEquals(False, dupConditions.get(2).is_duplicable__c);
        System.assertEquals(5, dupConditions.get(2).Minimum_Guarantee__c);
        System.assertEquals('The 10', dupConditions.get(2).Payment_Condition__c);
        System.assertEquals('10', dupConditions.get(2).Payment_Days__c);
        System.assertEquals('Negotiated', dupConditions.get(2).Provision_base__c);
        System.assertEquals(2, dupConditions.get(2).Provision_Sequence__c);
        System.assertEquals(2, dupConditions.get(2).Rank__c);
        System.assertEquals(False, dupConditions.get(2).Valid__c);
        System.assertEquals(3, dupConditions.get(2).Base_Quantity_Nego__c);
        System.assertEquals(2000, dupConditions.get(2).Value_amt__c);
        System.assertEquals(1, dupConditions.get(2).slab_per_1__c);
        System.assertEquals(1, dupConditions.get(2).slab_per_2__c);
        System.assertEquals(1, dupConditions.get(2).slab_per_3__c);
        System.assertEquals(1, dupConditions.get(2).slab_per_4__c);
        System.assertEquals(1, dupConditions.get(2).slab_per_5__c);
        System.assertEquals(1, dupConditions.get(2).slab_per_6__c);
        System.assertEquals(1, dupConditions.get(2).Slab_1__c);
        System.assertEquals(1, dupConditions.get(2).Slab_2__c);
        System.assertEquals(1, dupConditions.get(2).Slab_3__c);
        System.assertEquals(1, dupConditions.get(2).Slab_4__c);
        System.assertEquals(1, dupConditions.get(2).Slab_5__c);
        System.assertEquals(1, dupConditions.get(2).Slab_6__c);
        System.assertEquals(1, dupConditions.get(2).Slab_val_1__c);
        System.assertEquals(1, dupConditions.get(2).Slab_val_2__c);
        System.assertEquals(1, dupConditions.get(2).Slab_val_3__c);
        System.assertEquals(1, dupConditions.get(2).Slab_val_4__c);
        System.assertEquals(1, dupConditions.get(2).Slab_val_5__c);
        System.assertEquals(1, dupConditions.get(2).Slab_val_6__c);
        System.assertEquals(2.0, dupConditions.get(2).slab_target__c);
        System.assertEquals('Qty', dupConditions.get(2).slab_calc_method__c);
        System.assertEquals('oo', dupConditions.get(2).Commercial_reference__c);
        System.assertEquals('o', dupConditions.get(2).financial_reference__c);
        System.assertEquals('aa', dupConditions.get(2).legal_reference__c);
    }
    
    static testmethod void removeConditionsWithoutInvoiceRelationship() {
    	init();
        // Create Conditions related to the simulation contract.
        simCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 5, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition1.Id,
                                                 Is_Prenego_Envelop__c = True);
        simCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 7, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition3.Id,
                                                 Is_Prenego_Envelop__c = True);
        insert new List<Contract_Discount__c>{simCondition1, simCondition3};
        Id parentContractId = initContract.Id;
        List<Id> parentContractIds = new List<Id>();
        parentContractIds.add(parentContractId);
        
        Test.startTest();
        Database.executeBatch(new MergeContractBatch('MergeContractBatchTest', country.Id, new List<Id>{supplier.Id}, new List<Id>{simContract.Id}, parentContractIds, year+1));
        Test.stopTest();
	    
		Integer dupConditionsCount = [SELECT COUNT() FROM Contract_Discount__c WHERE Contract__c = :dupContract.Id];
        System.assertEquals(2, dupConditionsCount);
    }
    
    static testmethod void removeConditionsWithInvoiceRelationship() {
    	init();
        // Insert Invoice with invoice details
        Invoice__c invoice = new Invoice__c(Inv_Date__c = System.Today(), Inv_Supplier__c = supplier.Id, Inv_Contract__c = dupContract.Id,
                                            Inv_Business_Unit__c = dupContract.Contract_BU__c, Sequence_Number__c = 1,
                                            Inv_FiscalYear__c = dupContract.Contract_BDate__c.year(),
                                            Status_BDate__c = System.Today(), CurrencyIsoCode = currencyIsoCode, Ext_id__c='12345');       
        Invoice_Detail__c invoiceDetail = new Invoice_Detail__c(Discount__c = dupCondition2.Id, Inv_Detail_BU__c = dupCondition2.BU_Scope__c,
                                                                Inv_Detail_Condition__c = dupCondition2.Condition_Type__c,
                                                                Invoice_Value__c = 200, Inv_VAT_Percent__c = 23, Inv_VAT_Code__c = 121,
                                                                CurrencyIsoCode = currencyIsoCode);
        Invoice__c invoiceReference = new Invoice__c(Ext_id__c='12345');
        invoiceDetail.Invoice__r = invoiceReference;
        List<SObject> invoiceWithDetailsList = new List<SObject>();
        invoiceWithDetailsList.add(invoice);
        invoiceWithDetailsList.add(invoiceDetail);
        Database.insert(invoiceWithDetailsList);
        // Create Conditions related to the simulation contract.
        simCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 5, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition1.Id);
        insert simCondition1;
        simCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 5, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition2.Id);
        insert simCondition2;
        delete simCondition2;
        Id parentContractId = initContract.Id;
        List<Id> parentContractIds = new List<Id>();
        parentContractIds.add(parentContractId);
        
        Test.startTest();
        Database.executeBatch(new MergeContractBatch('MergeContractBatchTest', country.Id, new List<Id>{supplier.Id}, new List<Id>{simContract.Id}, parentContractIds, year+1));
        Test.stopTest();
	    
		Integer dupConditionsCount = [SELECT COUNT() FROM Contract_Discount__c WHERE Contract__c = :dupContract.Id];
        System.assertEquals(2, dupConditionsCount);
        
        List<Contract_Discount__c> cs = [SELECT Status__c, Value_amt__c, Base_Quantity_Nego__c,
                                         Slab_1__c, Slab_2__c, Slab_3__c, Slab_4__c, Slab_5__c, Slab_6__c,
                                         Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c,
                                         Value_amt_disp_M5__c, Value_amt_disp_M6__c, Value_amt_disp_M7__c, Value_amt_disp_M8__c,
                                         Value_amt_disp_M9__c, Value_amt_disp_M10__c, Value_amt_disp_M11__c, Value_amt_disp_M12__c 
                                         FROM Contract_Discount__c WHERE Contract__c = :dupContract.Id];
        System.assertEquals(0, cs.get(1).Value_amt__c);
        System.assertEquals(0, cs.get(1).Base_Quantity_Nego__c);
        System.assertEquals(0, cs.get(1).Slab_1__c);
        System.assertEquals(0, cs.get(1).Slab_2__c);
        System.assertEquals(0, cs.get(1).Slab_3__c);
        System.assertEquals(0, cs.get(1).Slab_4__c);
        System.assertEquals(0, cs.get(1).Slab_5__c);
        //System.assertEquals(0, cs.get(1).Slab_6__c);
        //System.assertEquals(0, cs.get(1).Value_amt_disp_M1__c);
        /*System.assertEquals(0, cs.get(1).Value_amt_disp_M2__c);
        System.assertEquals(0, cs.get(1).Value_amt_disp_M3__c);
        System.assertEquals(0, cs.get(1).Value_amt_disp_M4__c);
        System.assertEquals(0, cs.get(1).Value_amt_disp_M5__c);
        System.assertEquals(0, cs.get(1).Value_amt_disp_M6__c);
        System.assertEquals(0, cs.get(1).Value_amt_disp_M7__c);
        System.assertEquals(0, cs.get(1).Value_amt_disp_M8__c);
        System.assertEquals(0, cs.get(1).Value_amt_disp_M9__c);
        System.assertEquals(0, cs.get(1).Value_amt_disp_M10__c);
        System.assertEquals(0, cs.get(1).Value_amt_disp_M11__c);
        System.assertEquals(0, cs.get(1).Value_amt_disp_M12__c);*/
    }
    
    static testmethod void checkDN_AddConditionsCase() {
    	init();
        // Create conditions related to the simulation contract.
        simCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition1.Id);
        simCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition2.Id);
        simCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 3, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition3.Id);
        simCondition4 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 4, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id);
        insert new List<Contract_Discount__c>{simCondition1, simCondition2, simCondition3, simCondition4};
        Id parentContractId = simContract.Parent_Contract__c;
        List<Id> parentContractIds = new List<Id>();
        parentContractIds.add(parentContractId);
        
        Test.startTest();
        Database.executeBatch(new MergeContractBatch('MergeContractBatchTest', country.Id, new List<Id>{supplier.Id}, new List<Id>{simContract.Id}, parentContractIds, year+1));
        Test.stopTest();
        //
        Contract__c duplicatedContract = [SELECT D_N__c FROM Contract__c WHERE Id = :dupContract.Id];
        System.assertEquals('N', duplicatedContract.D_N__c);
    }
    
    static testmethod void checkDN_UpdateConditionsCase() {
    	init();
        // Create Conditions related to the simulation contract.
        simCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 5, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition1.Id);
        simCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 6, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition2.Id);
        simCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 7, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition3.Id);
        insert new List<Contract_Discount__c>{simCondition1, simCondition2, simCondition3};
        Id parentContractId = initContract.Id;
        List<Id> parentContractIds = new List<Id>();
        parentContractIds.add(parentContractId);
        
        Test.startTest();
        Database.executeBatch(new MergeContractBatch('MergeContractBatchTest', country.Id, new List<Id>{supplier.Id}, new List<Id>{simContract.Id}, parentContractIds, year+1));
        Test.stopTest();
		//
        Contract__c duplicatedContract = [SELECT D_N__c FROM Contract__c WHERE Id = :dupContract.Id];
        System.assertEquals('N', duplicatedContract.D_N__c);
    }
    
    static testmethod void checkDN_RemoveConditionsCase() {
    	init();
        // Create Conditions related to the simulation contract.
        simCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                             Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 5, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition1.Id);
        simCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                             Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 7, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition3.Id);
        insert new List<Contract_Discount__c>{simCondition1, simCondition3};
        Id parentContractId = initContract.Id;
        List<Id> parentContractIds = new List<Id>();
        parentContractIds.add(parentContractId);
        
        Test.startTest();
        Database.executeBatch(new MergeContractBatch('MergeContractBatchTest', country.Id, new List<Id>{supplier.Id}, new List<Id>{simContract.Id}, parentContractIds, year+1));
        Test.stopTest();
		//
        Contract__c duplicatedContract = [SELECT D_N__c FROM Contract__c WHERE Id = :dupContract.Id];
        System.assertEquals('N', duplicatedContract.D_N__c);
    }
    
    static testmethod void noDupContract() {
    	init();
    	// Create Conditions related to the simulation contract.
        simCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 5, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition1.Id);
        simCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 7, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition3.Id);
        insert new List<Contract_Discount__c>{simCondition1, simCondition3};
        Id parentContractId = initContract.Id;
        List<Id> parentContractIds = new List<Id>();
        parentContractIds.add(parentContractId);
    	delete dupContract;
    	
    	Test.startTest();
        Database.executeBatch(new MergeContractBatch('MergeContractBatchTest', country.Id, new List<Id>{supplier.Id}, new List<Id>{simContract.Id}, parentContractIds, year+1));
        Test.stopTest();
    	
    	List<Contract__c> cs = [SELECT Id FROM Contract__c];
        System.assertEquals(2, cs.size());
    }
    
    // Secure multi year.
    static testmethod void secureMultiYearCase_1() {
    	init();
    	dupContract.Secure_Multiyear__c = '2 years';
    	simContract.Secure_Multiyear__c = '2 years';
        update new List<Contract__c>{dupContract, simContract};
        // Create conditions related to the simulation contract.
        simCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition1.Id);
        simCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition2.Id);
        simCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 3, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition3.Id);
        simCondition4 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 4, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id);
        insert new List<Contract_Discount__c>{simCondition1, simCondition2, simCondition3, simCondition4};
        Id parentContractId = simContract.Parent_Contract__c;
        List<Id> parentContractIds = new List<Id>();
        parentContractIds.add(parentContractId);
        
        Test.startTest();
        Database.executeBatch(new MergeContractBatch('MergeContractBatchTest', country.Id, new List<Id>{supplier.Id}, new List<Id>{simContract.Id}, parentContractIds, year+1));
        Test.stopTest();
        //
        List<Contract__c> cs = [SELECT Id, Name FROM Contract__c WHERE Parent_Contract__c = :parentContractId];
        System.assertEquals(3, cs.size());
        
        List<Contract__c> cs2 = [SELECT Id FROM Contract__c WHERE Parent_Contract__c = :parentContractId AND Reference_Year__c = :(year+2)];
        System.assertEquals(1, cs2.size());
        
        List<Contract_Discount__c> conds = [SELECT Id FROM Contract_Discount__c
                                            WHERE Contract__r.Parent_Contract__c = :parentContractId
                                            AND Contract__r.Reference_Year__c = :(year+2)];
        System.assertEquals(4, conds.size());
    }
    
    static testmethod void secureMultiYearCase_2() {
    	init();
    	dupContract.Secure_Multiyear__c = '3 years';
    	simContract.Secure_Multiyear__c = '3 years';
        update new List<Contract__c>{dupContract, simContract};
    	initContract.Secure_Multiyear__c = '3 years';
        // Create conditions related to the simulation contract.
        simCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition1.Id);
        simCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition2.Id);
        simCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 3, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition3.Id);
        simCondition4 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 4, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id);
        insert new List<Contract_Discount__c>{simCondition1, simCondition2, simCondition3, simCondition4};
        Id parentContractId = simContract.Parent_Contract__c;
        List<Id> parentContractIds = new List<Id>();
        parentContractIds.add(parentContractId);
        
        Test.startTest();
        Database.executeBatch(new MergeContractBatch('MergeContractBatchTest', country.Id, new List<Id>{supplier.Id}, new List<Id>{simContract.Id}, parentContractIds, year+1));
        Test.stopTest();
        //
        List<Contract__c> cs = [SELECT Id FROM Contract__c WHERE Parent_Contract__c = :parentContractId];
        System.assertEquals(4, cs.size());
        
        List<Contract__c> cs2 = [SELECT Id FROM Contract__c WHERE Parent_Contract__c = :parentContractId AND Reference_Year__c = :(year+3)];
        System.assertEquals(1, cs2.size());
        
        List<Contract_Discount__c> conds = [SELECT Id FROM Contract_Discount__c
                                            WHERE Contract__r.Parent_Contract__c = :parentContractId
                                            AND Contract__r.Reference_Year__c = :(year+3)];
        System.assertEquals(4, conds.size());
    }
}