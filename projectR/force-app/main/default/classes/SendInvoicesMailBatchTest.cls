@isTest
private class SendInvoicesMailBatchTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region; 
    private static Orga_BU__c country;
    private static Orga_BU__c store;
    private static Orga_BU__c warehouse;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c negoScope;
    private static Supplier_PG_Mapping__c PG;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract__c contract;
    private static Invoice__c invoice;
    private static List<Contract_Discount__c> conditions;
    private static List<Purchases_Flow_PG__c> purchases;
    private static SDOC__SDJob__c sDocJob1;
    private static SDOC__SDJob__c sDocJob2;
    private static SDOC__SDoc__c sDoc1;
    
    
    private static Attachment attach {get; set;}  
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id.
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Get all recortd type ids for Orga_BU__c SObject
            Map<String, Id> buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Orga_BU__c.SObjectType);
            // Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = buRTIds.get('Region');
            insert region;
            // Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = buRTIds.get('Country');
            insert country;
            // Create Legal Form.
            Orga_BU__c legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
            legal.RecordTypeId = buRTIds.get('Legal');
            insert legal;
            // Create Store
            store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
            store.RecordTypeId = buRTIds.get('Store');
            // Create Warehouse.
            warehouse = new Orga_BU__c(Name = 'Warehouse 1', BU_Code__c = 'WH1', Country_origin__c = country.Id, Status__c = 'Open', CurrencyIsoCode = currencyIsoCode);
            warehouse.RecordTypeId = buRTIds.get('Warehouse');
            insert new List<Orga_BU__c>{store, warehouse};
            // Create Department.
            department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = '1', Parent_Element__c = rootId, Level__c = 1,
                                        Status_BDate__c = date.newInstance(year, 1, 1), Status__c = 'Active',
                                        Nego_Type__c = 'Ferme', Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
            insert department;
            // Create Section.
            section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = '1011', Parent_Element__c = department.Id, Level__c = 2,
                                     Status_BDate__c = date.newInstance(year, 1, 1),
                                     Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c =false);
            insert section;
            // Create supplier.
            supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
                                           Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode, Acc_email__c = 'kareem.zok@softretail-lb.com',
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default NegoScope created on supplier creation.
            negoScope = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
            // Create PG.
            PG = new Supplier_PG_Mapping__c(Name = supplier.Name + ' PG1', SNA_Code__c = '001', GIMA_Code__c = '001', Department__c = department.Id, Section__c = section.Id,  Supplier__c = supplier.Id);
            insert PG;
            // Create Policy - Tariff Conditions.
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                       Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                       Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ', VAT_Type__c = 'Rebate');
            insert tariffCondition;
            
            // Create Contract.
            contract = new Contract__c(Name ='Test Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_Numbder__c = 'C111',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract');
            insert contract;
            conditions = new List<Contract_Discount__c>();
            purchases = new List<Purchases_Flow_PG__c>();
            // Create Conditions.
            for (Integer i = 0 ; i < 2 ; i++) {
                Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, i+1, 1),
                                                                          Disc_EDate__c = date.newInstance(year, 2, 15), Value_per__c = 2, Product_Scope__c = negoScope.Id,
                                                                          BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 100, Value_amt__c = 12);
                conditions.add(condition);
            }
            insert conditions;
            // Create Purchases.
            for (Integer i = 0 ; i < 2 ; i++) {
                Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PG.Id, Department__c = department.Id, Section__c = section.Id,
                                                                         Supplier_Nego_Scope__c = negoScope.Id, Contrat1__c = contract.Id, Year__c = year, BU__c = country.Id,
                                                                         TO1__c = 10 + i * 5, TO2__c = 20 + i * 5, TO3__c = 30 + i * 5, TO4__c = 40 + i * 5, TO5__c = 50 + i * 5, TO6__c = 60 + i * 5,
                                                                         TO7__c = 70 + i * 5, TO8__c = 80 + i * 5, TO9__c = 90 + i * 5, TO10__c = 100 + i * 5, TO11__c = 110 + i * 5, TO12__c = 120 + i * 5,
                                                                         DC__c = country.Id);
                purchases.add(purchase);
            }
            insert purchases;
            
            invoice = new Invoice__c(Inv_Date__c = date.newInstance(year, 1, 1), Inv_Status__c = 'Generated', Inv_Supplier__c = supplier.Id, Status_BDate__c = date.newInstance(year, 1, 1),Inv_Business_Unit__c = country.Id, Inv_FiscalYear__c = year);
            insert invoice;
            //create attached pdf     
            
            attach = new Attachment();      
            attach.Name = 'Unit Test Attachment';
            Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
            attach.body = bodyBlob;
            attach.ContentType = 'application/pdf';
            attach.parentId = invoice.Id;
            insert attach;
            //create sdoc record ( generated doc attached to pdf and invoice )
            
            sDoc1 = new SDOC__SDoc__c(
                SDOC__SDTemplate__c = null,
                SDOC__Attachment_Name__c = attach.Name,
                SDOC__Attachment_ID__c = attach.Id ,
                SDOC__Status__c = 'Generated',
                SDOC__ObjectType__c = 'Invoice__c',
                SDOC__ISOCodeObj__c = 'EUR',
                SDOC__ISOCodeCorporate__c = 'EUR',
                SDOC__ObjectID__c = String.valueOf(invoice.Id).substring(0,15),
                SDOC__ObjectID15__c = String.valueOf(invoice.Id).substring(0,15),
                SDOC__ObjectID18__c = (String)invoice.Id
            );
            insert sDoc1;
            // create job doc
            sDocJob1 = new SDOC__SDJob__c(SDOC__SDoc1__c = sDoc1.Id, SDOC__Oid__c = Invoice.Id, SDOC__Apex_Job_ID__c = 'SD1', SDOC__ObjApiName__c = 'Invoice__c', SDOC__Type__c = 'Bulk Job - List View', SDOC__RunAs__c = 'kareem.zok@softretail-lb.com', SDOC__Status__c = 'Completed');
            sDocJob2 = new SDOC__SDJob__c(SDOC__SDoc1__c = sDoc1.Id, SDOC__Oid__c = Invoice.Id, SDOC__Apex_Job_ID__c = 'SD2', SDOC__ObjApiName__c = 'Invoice__c', SDOC__Type__c = 'Bulk Job - List View', SDOC__RunAs__c = 'rami@softretail-lb.com', SDOC__Status__c = 'Completed');
            
            insert new List<SDOC__SDJob__c> {sDocJob1, sDocJob2};
        } catch (Exception ex) { }
    }
    
    static testmethod void testSendInvoiceMailSuccess() {
        
        init();
        Test.startTest();
        SD_MassEmail_InvoiceController meic = new SD_MassEmail_InvoiceController();
        meic.getMassMailList();
        List<Id> listSuppId = new List<id>();
        listSuppId.add(supplier.Id);
        Database.executeBatch(new SendInvoicesMailBatch(meic.mapAttach,listSuppId),200);
        Integer used = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(0,used);
        
    }
    
}