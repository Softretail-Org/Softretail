/**
 * @Description Test class that verify whether the particular piece of code on AccountingClosingBatch is working properly.
 **/
@isTest
private class AccountingClosingPaymentBatchTest {
    
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
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'SEBFRANCE', 'FR');
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
    
    // Close accounting for payments
    @isTest static void closingAccountingForPayments_Success() {
        init();
        // Insert invoice.
        Invoice__c invoice = TestDataFactory.createInvoice(false, contract, System.Today(), System.Today().addMonths(2));
        invoice.Inv_Business_Unit__c = creditedStoreBU[0].Id;
        insert invoice;
        // Insert Invoice Group.
        Invoice_Group__c invoiceGroup = TestDataFactory.createInvoiceGroup(false, supplier.Id, System.Today(), System.Today().addMonths(2));
        insert invoiceGroup;
        // Insert Paiment Group.
        Invoice_Payment_Group__c paymentGroup = TestDataFactory.createPaymentGroup(false, invoiceGroup.Id);
        insert paymentGroup;
        // Insert Invoice Paiments.
        Invoice_Paiement__c invoicePayment = TestDataFactory.createInvoicePaiment(false, supplier.Id, paymentGroup.Id, creditedStoreBU[0].Id);
        invoicePayment.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(Invoice_Paiement__c.SObjectType).get('Standard');
        invoicePayment.Due_Date__c = System.Today().addMonths(2);
        invoicePayment.Payment_Date__c = System.Today();
        invoicePayment.Value_Date__c = System.Today();
        invoicePayment.Payment_type__c = 'Cheque';
        insert invoicePayment;
        
        // Insert invoice details.
        // Detail 1.
        Invoice_Detail__c invoiceDetail1 = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition);
        invoiceDetail1.Invoice_detail_nego_disc_type__c = 'Advertising Fees';
        // Detail 2.
        Invoice_Detail__c invoiceDetail12 = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition);
        invoiceDetail12.Invoice_detail_nego_disc_type__c = 'Advertising Fees';
        // Detail 3.
        Invoice_Detail__c invoiceDetail13 = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition);
        invoiceDetail13.Invoice_detail_nego_disc_type__c = 'Advertising Fees';
        // Detail 4.
        Invoice_Detail__c invoiceDetail2 = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition);
        invoiceDetail2.Invoice_detail_nego_disc_type__c = 'Rebates';
        // Detail 5.
        Invoice_Detail__c invoiceDetail3 = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition);
        invoiceDetail3.Invoice_detail_nego_disc_type__c = 'Rebates';
        // Detail 6.
        Invoice_Detail__c invoiceDetail4 = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition);
        invoiceDetail4.Invoice_detail_nego_disc_type__c = null;
        insert new List<Invoice_Detail__c> {invoiceDetail1, invoiceDetail12, invoiceDetail13, invoiceDetail2, invoiceDetail3, invoiceDetail4};   
            
        // Insert Invoice Paiment Details.
        // Invoice Paiment 1.
        Invoice_Paiement_Detail__c invoicePaymentDetail1 = TestDataFactory.createInvoicePaimentDetail(false, invoiceDetail1.Id, invoicePayment.Id);
        invoicePaymentDetail1.Matching_Amount__c = 1;
        // Invoice Paiment 2.
        Invoice_Paiement_Detail__c invoicePaymentDetail12 = TestDataFactory.createInvoicePaimentDetail(false, invoiceDetail12.Id, invoicePayment.Id);
        invoicePaymentDetail12.Matching_Amount__c = 2;
        // Invoice Paiment 3.
        Invoice_Paiement_Detail__c invoicePaymentDetail13 = TestDataFactory.createInvoicePaimentDetail(false, invoiceDetail13.Id, invoicePayment.Id);
        invoicePaymentDetail13.Matching_Amount__c = 3;
        // Invoice Paiment 4.
        Invoice_Paiement_Detail__c invoicePaymentDetail2 = TestDataFactory.createInvoicePaimentDetail(false, invoiceDetail2.Id, invoicePayment.Id);
        invoicePaymentDetail2.Matching_Amount__c = 4;
        // Invoice Paiment 5.
        Invoice_Paiement_Detail__c invoicePaymentDetail3 = TestDataFactory.createInvoicePaimentDetail(false, invoiceDetail3.Id, invoicePayment.Id);
        invoicePaymentDetail3.Matching_Amount__c = 5;
        // Invoice Paiment 6.
        Invoice_Paiement_Detail__c invoicePaymentDetail4 = TestDataFactory.createInvoicePaimentDetail(false, invoiceDetail4.Id, invoicePayment.Id);
        invoicePaymentDetail4.Matching_Amount__c = 5;
        insert new List<Invoice_Paiement_Detail__c>{invoicePaymentDetail1, invoicePaymentDetail12, invoicePaymentDetail13, invoicePaymentDetail2, invoicePaymentDetail3, invoicePaymentDetail4};
            
        // Accounting Schemes insertions.
        // Accounting Scheme 1.
        Accounting_Scheme__c accountingScheme1 = TestDataFactory.createAccountingScheme(false, creditedStoreBU[0].Id, creditCompany.Id, debitedCompany.Id, 'Payments');
        accountingScheme1.Flag_D_or_C__c = 'Credit';
        accountingScheme1.Payment_Type__c = 'Cheque';
        accountingScheme1.Included_Discount_Types__c = 'Advertising Fees';
        accountingScheme1.Accounting_Type__c = 'Product';
        insert accountingScheme1;
        // Accounting Scheme 2.
        Accounting_Scheme__c accountingScheme12 = TestDataFactory.createAccountingScheme(false, creditedStoreBU[0].Id, creditCompany.Id, debitedCompany.Id, 'Payments');
        accountingScheme12.Flag_D_or_C__c = 'Debit';
        accountingScheme12.Payment_Type__c = 'Cheque';
        accountingScheme12.Included_Discount_Types__c = 'Advertising Fees';
        accountingScheme12.Accounting_Type__c = 'Product';
        insert accountingScheme12;
        // Accounting Scheme 2.
        Accounting_Scheme__c accountingScheme2 = TestDataFactory.createAccountingScheme(false, creditedStoreBU[0].Id, creditCompany.Id, debitedCompany.Id, 'Payments');
        accountingScheme2.Flag_D_or_C__c = 'Credit';
        accountingScheme2.Payment_Type__c = 'Cheque';
        accountingScheme2.Included_Discount_Types__c = 'Advertising Fees;Rebates';
        accountingScheme2.Accounting_Type__c = 'Product';
        insert accountingScheme2;
        // Accounting Scheme 3.
        Accounting_Scheme__c accountingScheme3 = TestDataFactory.createAccountingScheme(false, creditedStoreBU[0].Id, creditCompany.Id, debitedCompany.Id, 'Payments');
        accountingScheme3.Flag_D_or_C__c = 'Debit';
        accountingScheme3.Payment_Type__c = 'Cheque';
        accountingScheme3.Included_Discount_Types__c = 'Rebates';
        accountingScheme3.Accounting_Type__c = 'Product';
        accountingScheme3.Include_Free_Invoices__c = true;
        insert accountingScheme3;
        // Insert Accounting Closing.
        Accounting_Closing__c accountingClosing = TestDataFactory.createAccountingClosing(false, creditedStoreBU[0].Id);
        accountingClosing.Closing_Date__c = System.today();
        accountingClosing.Payments__c = true;
        accountingClosing.Status__c = 'Preview';
        insert accountingClosing;
        
        // case update accounting entry
        // Insert Accounting Entry
        Accounting_Entry__c accountingEntry1 = new Accounting_Entry__c(Entry_Type__c = 'Payment', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme1.Id,
                                                                       Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = '',
                                                                       Comment__c = '', Amount__c = 6, Amount_signed__c = 6,
                                                                       Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'));
        Accounting_Entry__c accountingEntry12 = new Accounting_Entry__c(Entry_Type__c = 'Payment', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme12.Id,
                                                                        Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = '',
                                                                        Comment__c = '', Amount__c = 6, Amount_signed__c = 6,
                                                                        Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract')); 
        insert new List<Accounting_Entry__c> {accountingEntry1, accountingEntry12};
            
        invoicePaymentDetail1.Accounting_Entry_credit__c = accountingEntry1.Id;
        invoicePaymentDetail1.Accounting_Entry_debit__c = accountingEntry12.Id;
        
        invoicePaymentDetail12.Accounting_Entry_credit__c = accountingEntry1.Id;
        invoicePaymentDetail12.Accounting_Entry_debit__c = accountingEntry12.Id;
        
        invoicePaymentDetail13.Accounting_Entry_credit__c = accountingEntry1.Id;
        invoicePaymentDetail13.Accounting_Entry_debit__c = accountingEntry12.Id;
        update new List<Invoice_Paiement_Detail__c> {invoicePaymentDetail1, invoicePaymentDetail12, invoicePaymentDetail13};
        
        // Start test.
        Test.startTest();
        List<Accounting_Scheme__c> accountingSchemes = [SELECT Id, Business_Unit__c, Business_Unit__r.Name, Amount_Type__c, Payment_Type__c, 
                                                        Credited_Company__c, Credited_Company__r.Name, Debited_Company__c, Debited_Company__r.Name,
                                                        Included_Discount_Types__c, Included_Discount_Type__c, RecordType.DeveloperName, Flag_D_or_C__c, Closing_Accounting_Type__c,
                                                        Include_Free_Invoices__c, Accounting_Entry_for__c, Store_Type__c, Managed_BU__c, Accounting_Type__c
                                                        FROM Accounting_Scheme__c
                                                        WHERE RecordType.DeveloperName = 'Payments'];
        Database.executeBatch(new AccountingClosingPaymentBatch('Test', accountingClosing, accountingSchemes));
        Test.stopTest();
        // Assertions.
        List<Accounting_Entry__c> accountingEntries = [SELECT Id, Name FROM Accounting_Entry__c];
        Accounting_Entry__c accountingEntry1_Credit = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme1.Id];
        Accounting_Entry__c accountingEntry1_Debit = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme12.Id];
        Accounting_Entry__c accountingEntry2_Credit = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme2.Id];
        Accounting_Entry__c accountingEntry3_Debit = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme3.Id];
        invoicePaymentDetail1 = [SELECT Id, Accounting_Entry_credit__c, Accounting_Entry_debit__c FROM Invoice_Paiement_Detail__c WHERE Id =:invoicePaymentDetail1.Id];
        invoicePaymentDetail2 = [SELECT Id, Accounting_Entry_credit__c, Accounting_Entry_debit__c FROM Invoice_Paiement_Detail__c WHERE Id =:invoicePaymentDetail2.Id];
        invoicePaymentDetail3 = [SELECT Id, Accounting_Entry_credit__c, Accounting_Entry_debit__c FROM Invoice_Paiement_Detail__c WHERE Id =:invoicePaymentDetail3.Id];
        System.assertEquals(accountingEntry1_Credit.Id, invoicePaymentDetail1.Accounting_Entry_credit__c);
        System.assertEquals(accountingEntry1_Debit.Id, invoicePaymentDetail1.Accounting_Entry_debit__c);
        System.assertEquals(accountingEntry2_Credit.Id, invoicePaymentDetail2.Accounting_Entry_credit__c);
        System.assertEquals(accountingEntry3_Debit.Id, invoicePaymentDetail3.Accounting_Entry_debit__c);
        System.assertEquals(6, accountingEntry1_Credit.Amount__c);
        System.assertEquals(9, accountingEntry2_Credit.Amount__c);
        System.assertEquals(14, accountingEntry3_Debit.Amount__c);
        System.assertEquals(4, accountingEntries.size());
    }
}