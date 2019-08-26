/**
 * Unit Test class used to closing accounting batch.
**/ 
@isTest
private class AccountingClosingInvoiceBatchTest {
    
    private static final Integer year = TestDataFactory.year;
    private static Sup_Supplier__c supplier;
    private static Orga_BU__c creditCompany;
    private static Orga_BU__c debitedCompany;
    private static List<Orga_BU__c> creditedStoreBU;
    private static List<Orga_BU__c> debitedStoreBU;
    private static Contract__c contract;
    private static Contract_Discount__c condition;
    
    static void init() {
        try {
            // Insert Country.
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'SEB FRANCE', 'FR');
            // Insert Region.
            Orga_BU__c region = TestDataFactory.createBURegion(false, 'EU');
            insert region;
            // Insert Country.
            Orga_BU__c country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
            // Insert supplier.
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Get the default negoscope created on supplier creation.
            Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Insert Credit Company BU.
            creditCompany = TestDataFactory.createBULegal(true, myCountry);
            // Insert Debited Company BU.
            debitedCompany = TestDataFactory.createBULegal(true, myCountry);
            // Insert Store BU for Credited company.
            creditedStoreBU = TestDataFactory.createBUStores(false, country, creditCompany.Id, 1);
            creditedStoreBU.get(0).Management_Type__c = 'Affiliated';
            creditedStoreBU.get(0).Managed_BU__c = true;
            creditedStoreBU.get(0).Related_Client__c = supplier.Id;
            creditedStoreBU.get(0).Name = 'AMC';
            insert creditedStoreBU;
            // Insert Store BU for Debited company.
            debitedStoreBU = TestDataFactory.createBUStores(false, country, debitedCompany.Id, 1);
            debitedStoreBU.get(0).Name = 'Monoprix France';
            insert debitedStoreBU;
            // Insert Policy - Tariff conditions.
            Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 1, 1);
            // Insert contract.
            contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            // Insert condition.
            condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }    
    
    // Close accounting for invoices
    @isTest static void closingAccountingInvoice_Success() {
        init();
        // Insert invoice.
        Invoice__c invoice = TestDataFactory.createInvoice(false, contract, System.Today(), System.Today().addMonths(2));
        invoice.Inv_Business_Unit__c = creditedStoreBU[0].Id;
        insert invoice;
        // Create invoices details.
        List<Invoice_Detail__c> invoiceDetails = new List<Invoice_Detail__c>(), invoiceDetails1 = new List<Invoice_Detail__c>();        
        for (Integer i = 1; i < = 50; i++) {
            Invoice_Detail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition);
            invoiceDetail.Invoice_detail_nego_disc_type__c = 'Advertising Fees';
            invoiceDetail.Inv_VAT_Percent__c = 10;
            invoiceDetail.Invoice_Value__c = 1;
            invoiceDetail.Inv_VAT_Value_Ext__c = 1;
            invoiceDetail.Inv_Detail_Value_w_VAT_Ext__c = 1;
            invoiceDetails1.add(invoiceDetail);
        }
        invoiceDetails.addAll(invoiceDetails1);
        for (Integer i = 1; i < = 10; i++) {
            Invoice_Detail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition);
            invoiceDetail.Invoice_detail_nego_disc_type__c = 'Advertising Fees';
            invoiceDetail.Inv_VAT_Percent__c = 10;
            invoiceDetail.Invoice_Value__c = 1;
            invoiceDetail.Inv_VAT_Value_Ext__c = 1;
            invoiceDetail.Inv_Detail_Value_w_VAT_Ext__c = 1;
            invoiceDetails.add(invoiceDetail);
        }
        for (Integer i = 1; i < = 10; i++) {
            Invoice_Detail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition);
            invoiceDetail.Invoice_detail_nego_disc_type__c = 'Rebates';
            invoiceDetail.Inv_VAT_Percent__c = 10;
            invoiceDetail.Invoice_Value__c = 1;
            invoiceDetail.Inv_VAT_Value_Ext__c = 1;
            invoiceDetail.Inv_Detail_Value_w_VAT_Ext__c = 1;
            invoiceDetails.add(invoiceDetail);
        }
        for (Integer i = 1; i < = 5; i++) {
            Invoice_Detail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition);
            invoiceDetail.Invoice_detail_nego_disc_type__c = null;
            invoiceDetail.Inv_VAT_Percent__c = 10;
            invoiceDetail.Invoice_Value__c = 1;
            invoiceDetail.Inv_VAT_Value_Ext__c = 1;
            invoiceDetail.Inv_Detail_Value_w_VAT_Ext__c = 1;
            invoiceDetails.add(invoiceDetail);
        }
        insert invoiceDetails;
        
        // Insert Schemes.
		// Accounting Scheme 1
		Accounting_Scheme__c accountingScheme1 = TestDataFactory.createAccountingScheme(false, creditedStoreBU[0].Id, creditCompany.Id, debitedCompany.Id, 'Invoices');
		accountingScheme1.Amount_Type__c = 'HT';
		accountingScheme1.Included_Discount_Types__c = 'Advertising Fees';
		accountingScheme1.Accounting_Type__c = 'Product';
        // Accounting Scheme 2
        Accounting_Scheme__c accountingScheme12 = TestDataFactory.createAccountingScheme(false, creditedStoreBU[0].Id, creditCompany.Id, debitedCompany.Id, 'Invoices');
		accountingScheme12.Amount_Type__c = 'TTC';
		accountingScheme12.Included_Discount_Types__c = 'Advertising Fees';
		accountingScheme12.Accounting_Type__c = 'Product';
        // Accounting Scheme 3
        Accounting_Scheme__c accountingScheme13 = TestDataFactory.createAccountingScheme(false, creditedStoreBU[0].Id, creditCompany.Id, debitedCompany.Id, 'Invoices');
		accountingScheme13.Amount_Type__c = 'TVA';
		accountingScheme13.Included_Discount_Types__c = 'Advertising Fees';
		accountingScheme13.Accounting_Type__c = 'Product';
        // Accounting Scheme 4
        Accounting_Scheme__c accountingScheme2 = TestDataFactory.createAccountingScheme(false, creditedStoreBU[0].Id, creditCompany.Id, debitedCompany.Id, 'Invoices');
        accountingScheme2.Amount_Type__c = 'TTC';
        accountingScheme2.Included_Discount_Types__c = 'Advertising Fees;Rebates';
        accountingScheme2.Accounting_Type__c = 'Product';
        // Accounting Scheme 5
        Accounting_Scheme__c accountingScheme3 = TestDataFactory.createAccountingScheme(false, creditedStoreBU[0].Id, creditCompany.Id, debitedCompany.Id, 'Invoices');
        accountingScheme3.Amount_Type__c = 'TVA';
        accountingScheme3.Included_Discount_Types__c = 'Rebates';
        accountingScheme3.Accounting_Type__c = 'Product';
        accountingScheme3.Include_Free_Invoices__c = true;
        insert new List<Accounting_Scheme__c> {accountingScheme1, accountingScheme12, accountingScheme13, accountingScheme2, accountingScheme3};
            
        // Insert Accounting Closing.
        Accounting_Closing__c accountingClosing = TestDataFactory.createAccountingClosing(false, creditedStoreBU[0].Id);
        accountingClosing.Closing_Date__c = System.today();
        accountingClosing.Invoices__c = true;
        accountingClosing.Status__c = 'Preview';
        insert accountingClosing;
        
        // Insert Accounting Entry
        Accounting_Entry__c accountingEntry1 = new Accounting_Entry__c(Entry_Type__c = 'Invoice', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme1.Id,
                                                                       Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'JV / Campagne ' + invoice.Inv_FiscalYear__c,
                                                                       Comment__c = invoice.Inv_FiscalYear__c + 'HT', VAT_rate__c = 10, Amount__c = 50, Amount_signed__c = 50,
                                                                       Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'), Reference_year__c = invoice.Inv_FiscalYear__c);
        
        Accounting_Entry__c accountingEntry12 = new Accounting_Entry__c(Entry_Type__c = 'Invoice', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme12.Id,
                                                                        Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'JV / Campagne ' + invoice.Inv_FiscalYear__c,
                                                                        Comment__c = invoice.Inv_FiscalYear__c + 'HT', VAT_rate__c = 10, Amount__c = 50, Amount_signed__c = 50,
                                                                        Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'), Reference_year__c = invoice.Inv_FiscalYear__c);
        
        Accounting_Entry__c accountingEntry13 = new Accounting_Entry__c(Entry_Type__c = 'Invoice', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme13.Id,
                                                                        Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'JV / Campagne ' + invoice.Inv_FiscalYear__c,
                                                                        Comment__c = invoice.Inv_FiscalYear__c + 'HT', VAT_rate__c = 10, Amount__c = 50, Amount_signed__c = 50,
                                                                        Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'), Reference_year__c = invoice.Inv_FiscalYear__c);
        insert new List<Accounting_Entry__c>{accountingEntry1,accountingEntry12,accountingEntry13};
        for(Invoice_Detail__c item : invoiceDetails1) {
            item.Accounting_entry_woVAT__c = accountingEntry1.Id;
            item.Accounting_entry_wVAT__c = accountingEntry12.Id;
            item.Accounting_entry_VAT__c = accountingEntry13.Id;
        }
        update invoiceDetails1;
        
        Test.startTest();
        List<Accounting_Scheme__c> accountingSchemes = [SELECT Id, Business_Unit__c, Business_Unit__r.Name, Amount_Type__c, Payment_Type__c, 
                                                        Credited_Company__c, Credited_Company__r.Name, Debited_Company__c, Debited_Company__r.Name,
                                                        Included_Discount_Types__c, Included_Discount_Type__c, RecordType.DeveloperName, Flag_D_or_C__c, Closing_Accounting_Type__c,
                                                        Include_Free_Invoices__c, Accounting_Entry_for__c, Store_Type__c, Managed_BU__c, Accounting_Type__c
                                                        FROM Accounting_Scheme__c
                                                        WHERE RecordType.DeveloperName = 'Invoices'];
        Database.executeBatch(new AccountingClosingInvoiceBatch('Test', accountingClosing, accountingSchemes));
        Test.stopTest();
        // Validation Test
        List<Accounting_Entry__c> accountingEntries = [SELECT Id, Name FROM Accounting_Entry__c];
        Accounting_Entry__c accountingEntry1_HT = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme1.Id];
        ////Accounting_Entry__c accountingEntry1_TTC = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme12.Id];
        ////Accounting_Entry__c accountingEntry1_TVA = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme13.Id];
        Accounting_Entry__c accountingEntry2_TTC = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme2.Id];
        Accounting_Entry__c accountingEntry3_TVA = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme3.Id];
        System.assertEquals(60, accountingEntry1_HT.Amount__c);
        ////System.assertEquals(50, accountingEntry1_TTC.Amount__c);
        ////System.assertEquals(50, accountingEntry1_TVA.Amount__c);
        System.assertEquals(10, accountingEntry2_TTC.Amount__c);
        System.assertEquals(15, accountingEntry3_TVA.Amount__c);
        System.assertEquals(5, accountingEntries.size());
    }
}