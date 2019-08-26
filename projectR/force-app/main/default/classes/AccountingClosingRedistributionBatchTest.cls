/**
 * @Description Test class that verify whether the particular piece of code on AccountingClosingBatch is working properly.
 **/
@isTest
private class AccountingClosingRedistributionBatchTest {
    
    private static final Integer year = TestDataFactory.year;
    private static Sup_Supplier__c supplier;
    private static Orga_BU__c creditCompany;
    private static Orga_BU__c debitedCompany;
    private static Orga_BU__c creditedStoreBU;
    private static Orga_BU__c debitedStoreBU;
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
            List<Orga_BU__c> storeBUs = TestDataFactory.createBUStores(false, country, creditCompany.Id, 1);
            creditedStoreBU = storeBUs.get(0);
            creditedStoreBU.Management_Type__c = 'Affiliated';
            creditedStoreBU.Managed_BU__c = true;
            creditedStoreBU.Related_Client__c = supplier.Id;
            creditedStoreBU.Name = 'AMC';
            creditedStoreBU.Legal_Form__c = creditCompany.Id;
            insert creditedStoreBU;
            // Insert Store BU for Debited company.
            debitedStoreBU = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            debitedStoreBU.Name = 'Monoprix France';
            debitedStoreBU.Legal_Form__c = debitedCompany.Id;
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

    // TO Review: Master_BU__c on Redistrib_head__c should be a Country et non pas un store.  Master BU: Record TypeEQUALSCountry
    // Close accounting for redistributions
    @isTest static void closingAccountingForRedistributions_Success() {
        init();
        // insert redistrib head/redistrib line
        Redistrib_head__c redistrib = new Redistrib_head__c(Master_BU__c = debitedStoreBU.Id, Year__c = year,
                                                            Nego_Discount_Type__c = 'Advertising Fees');
        insert redistrib;
        Redistrib_detail__c redistribDetail1 = new Redistrib_detail__c(Store__c = creditedStoreBU.Id, Redistrib_head__c = redistrib.Id,
                                                                       Redistrib_amnt_HT__c = -1);
        insert redistribDetail1;
        Redistrib_detail__c redistribDetail2 = new Redistrib_detail__c(Store__c = creditedStoreBU.Id, Redistrib_head__c = redistrib.Id,
                                                                       Redistrib_amnt_HT__c = -2);
        insert redistribDetail2;
        Redistrib_detail__c redistribDetail3 = new Redistrib_detail__c(Store__c = creditedStoreBU.Id, Redistrib_head__c = redistrib.Id,
                                                                       Redistrib_amnt_HT__c = -3);
        insert redistribDetail3;
        
        // Accounting Schemes insertions.
        // Accounting Scheme 1.
        Accounting_Scheme__c accountingScheme1 = TestDataFactory.createAccountingScheme(false, debitedStoreBU.Id, creditCompany.Id, debitedCompany.Id, 'Redistribution');
        accountingScheme1.Amount_Type__c = 'HT';
        accountingScheme1.Accounting_Entry_for__c = 'Credited';
        accountingScheme1.Flag_D_or_C__c = 'Credit';
        accountingScheme1.Included_Discount_Types__c = 'Advertising Fees';
        accountingScheme1.Store_Type__c = 'Affiliated';
        accountingScheme1.Managed_BU__c = true;
        accountingScheme1.Accounting_Type__c = 'Product';
        insert accountingScheme1;
        // Accounting Scheme 12.
        Accounting_Scheme__c accountingScheme12 = TestDataFactory.createAccountingScheme(false, debitedStoreBU.Id, creditCompany.Id, debitedCompany.Id, 'Redistribution');
        accountingScheme12.Amount_Type__c = 'HT';
        accountingScheme12.Accounting_Entry_for__c = 'Credited';
        accountingScheme12.Flag_D_or_C__c = 'Debit';
        accountingScheme12.Included_Discount_Types__c = 'Advertising Fees';
        accountingScheme12.Store_Type__c = 'Affiliated';
        accountingScheme12.Managed_BU__c = true;
        accountingScheme12.Accounting_Type__c = 'Product';
        insert accountingScheme12;
        // Accounting Scheme 13.
        Accounting_Scheme__c accountingScheme13 = TestDataFactory.createAccountingScheme(false, debitedStoreBU.Id, creditCompany.Id, debitedCompany.Id, 'Redistribution');
        accountingScheme13.Amount_Type__c = 'HT';
        accountingScheme13.Accounting_Entry_for__c = 'Debited';
        accountingScheme13.Flag_D_or_C__c = 'Credit';
        accountingScheme13.Included_Discount_Types__c = 'Advertising Fees';
        accountingScheme13.Store_Type__c = 'Affiliated';
        accountingScheme13.Managed_BU__c = true;
        accountingScheme13.Accounting_Type__c = 'Product';
        insert accountingScheme13;
        // Accounting Scheme 14.
        Accounting_Scheme__c accountingScheme14 = TestDataFactory.createAccountingScheme(false, debitedStoreBU.Id, creditCompany.Id, debitedCompany.Id, 'Redistribution');
        accountingScheme14.Amount_Type__c = 'HT';
        accountingScheme14.Accounting_Entry_for__c = 'Debited';
        accountingScheme14.Flag_D_or_C__c = 'Debit';
        accountingScheme14.Included_Discount_Types__c = 'Advertising Fees';
        accountingScheme14.Store_Type__c = 'Affiliated';
        accountingScheme14.Managed_BU__c = true;
        accountingScheme14.Accounting_Type__c = 'Product';
        insert accountingScheme14;
        // Accounting Scheme 15.
        Accounting_Scheme__c accountingScheme15 = TestDataFactory.createAccountingScheme(false, debitedStoreBU.Id, creditCompany.Id, debitedCompany.Id, 'Redistribution');
        accountingScheme15.Amount_Type__c = 'HT';
        accountingScheme15.Accounting_Entry_for__c = 'Debited=Credited';
        accountingScheme15.Flag_D_or_C__c = 'Credit';
        accountingScheme15.Included_Discount_Types__c = 'Advertising Fees';
        accountingScheme15.Store_Type__c = 'Affiliated';
        accountingScheme15.Managed_BU__c = true;
        accountingScheme15.Accounting_Type__c = 'Product';
        insert accountingScheme15;
        // Accounting Scheme 16.
        Accounting_Scheme__c accountingScheme16 = TestDataFactory.createAccountingScheme(false, debitedStoreBU.Id, creditCompany.Id, debitedCompany.Id, 'Redistribution');
        accountingScheme16.Amount_Type__c = 'HT';
        accountingScheme16.Accounting_Entry_for__c = 'Debited=Credited';
        accountingScheme16.Flag_D_or_C__c = 'Debit';
        accountingScheme16.Included_Discount_Types__c = 'Advertising Fees';
        accountingScheme16.Store_Type__c = 'Affiliated';
        accountingScheme16.Managed_BU__c = true;
        accountingScheme16.Accounting_Type__c = 'Product';
        insert accountingScheme16;
        
        // Accounting Scheme 2.
        Accounting_Scheme__c accountingScheme2 = TestDataFactory.createAccountingScheme(false, debitedStoreBU.Id, creditCompany.Id, debitedCompany.Id, 'Redistribution');
        accountingScheme2.Amount_Type__c = 'TTC';
        accountingScheme2.Accounting_Entry_for__c = 'Credited';
        accountingScheme2.Flag_D_or_C__c = 'Credit';
        accountingScheme2.Included_Discount_Types__c = 'Advertising Fees';
        accountingScheme2.Store_Type__c = 'Affiliated';
        accountingScheme2.Managed_BU__c = true;
        accountingScheme2.Accounting_Type__c = 'Product';
        insert accountingScheme2;
        
        // Accounting Scheme 3.
        Accounting_Scheme__c accountingScheme3 = TestDataFactory.createAccountingScheme(false, debitedStoreBU.Id, creditCompany.Id, debitedCompany.Id, 'Redistribution');
        accountingScheme3.Amount_Type__c = 'TVA';
        accountingScheme3.Accounting_Entry_for__c = 'Credited';
        accountingScheme3.Flag_D_or_C__c = 'Credit';
        accountingScheme3.Included_Discount_Types__c = 'Advertising Fees';
        accountingScheme3.Store_Type__c = 'Affiliated';
        accountingScheme3.Managed_BU__c = true;
        accountingScheme3.Accounting_Type__c = 'Product';
        insert accountingScheme3;
        
        // Insert Accounting Closing.
        Accounting_Closing__c accountingClosing = TestDataFactory.createAccountingClosing(false, debitedStoreBU.Id);
        accountingClosing.Closing_Date__c = System.today();
        accountingClosing.Redistributions__c = true;
        accountingClosing.Status__c = 'Preview';
        insert accountingClosing;
        
        // case update accounting entry
        // Insert Accounting Entry
        Accounting_Entry__c accountingEntry1 = new Accounting_Entry__c(Entry_Type__c = 'Redistribution', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme1.Id,
                                                                       Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'DISTRIBUTION AUX AYANTS_DROITS',
                                                                       Comment__c = 'A', Amount__c = 3, Amount_signed__c = -3,
                                                                       Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'));
        Accounting_Entry__c accountingEntry12 = new Accounting_Entry__c(Entry_Type__c = 'Redistribution', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme12.Id,
                                                                        Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'DISTRIBUTION AUX AYANTS_DROITS',
                                                                        Comment__c = 'A', Amount__c = 3, Amount_signed__c = -3,
                                                                        Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'));
        Accounting_Entry__c accountingEntry13 = new Accounting_Entry__c(Entry_Type__c = 'Redistribution', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme13.Id,
                                                                        Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'DISTRIBUTION AUX AYANTS_DROITS',
                                                                        Comment__c = 'A', Amount__c = 3, Amount_signed__c = -3,
                                                                        Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'));
        Accounting_Entry__c accountingEntry14 = new Accounting_Entry__c(Entry_Type__c = 'Redistribution', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme14.Id,
                                                                        Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'DISTRIBUTION AUX AYANTS_DROITS',
                                                                        Comment__c = 'A', Amount__c = 3, Amount_signed__c = -3,
                                                                        Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'));
        Accounting_Entry__c accountingEntry15 = new Accounting_Entry__c(Entry_Type__c = 'Redistribution', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme15.Id,
                                                                        Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'DISTRIBUTION AUX AYANTS_DROITS',
                                                                        Comment__c = 'A', Amount__c = 3, Amount_signed__c = -3,
                                                                        Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'));
        Accounting_Entry__c accountingEntry16 = new Accounting_Entry__c(Entry_Type__c = 'Redistribution', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme16.Id,
                                                                        Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'DISTRIBUTION AUX AYANTS_DROITS',
                                                                        Comment__c = 'A', Amount__c = 3, Amount_signed__c = -3,
                                                                        Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'));
        Accounting_Entry__c accountingEntry2 = new Accounting_Entry__c(Entry_Type__c = 'Redistribution', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme2.Id,
                                                                       Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'DISTRIBUTION AUX AYANTS_DROITS',
                                                                       Comment__c = 'A', Amount__c = 3, Amount_signed__c = -3,
                                                                       Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'));
        Accounting_Entry__c accountingEntry3 = new Accounting_Entry__c(Entry_Type__c = 'Redistribution', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme3.Id,
                                                                       Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'DISTRIBUTION AUX AYANTS_DROITS',
                                                                       Comment__c = 'A', Amount__c = 3, Amount_signed__c = -3,
                                                                       Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'));
        insert new List<Accounting_Entry__c> {accountingEntry1, accountingEntry12, accountingEntry13, accountingEntry14, accountingEntry15, accountingEntry16, accountingEntry2, accountingEntry3};
        // accounting entry HT
        redistribDetail1.Accounting_entry_credit_woVAT__c = accountingEntry1.Id;
        redistribDetail1.Accounting_entry_credit_woVAT_D__c = accountingEntry12.Id;
        redistribDetail1.Accounting_entry_debit_woVAT__c = accountingEntry13.Id;
        redistribDetail1.Accounting_entry_debit_woVAT_D__c = accountingEntry14.Id;
        redistribDetail1.Accounting_entry_woVAT__c = accountingEntry15.Id;
        redistribDetail1.Accounting_entry_woVAT_D__c = accountingEntry16.Id;
        
        redistribDetail2.Accounting_entry_credit_woVAT__c = accountingEntry1.Id;
        redistribDetail2.Accounting_entry_credit_woVAT_D__c = accountingEntry12.Id;
        redistribDetail2.Accounting_entry_debit_woVAT__c = accountingEntry13.Id;
        redistribDetail2.Accounting_entry_debit_woVAT_D__c = accountingEntry14.Id;
        redistribDetail2.Accounting_entry_woVAT__c = accountingEntry15.Id;
        redistribDetail2.Accounting_entry_woVAT_D__c = accountingEntry16.Id;
        
        // accounting entry TTC
        redistribDetail1.Accounting_entry_credit_wVAT__c = accountingEntry2.Id;
        redistribDetail2.Accounting_entry_credit_wVAT__c = accountingEntry2.Id;
        // accounting entry TVA
        redistribDetail1.Accounting_entry_credit_VAT__c = accountingEntry3.Id;
        redistribDetail2.Accounting_entry_credit_VAT__c = accountingEntry3.Id;
                
        update new List<Redistrib_detail__c> {redistribDetail1, redistribDetail2};
        
        Test.startTest();
        List<Accounting_Scheme__c> accountingSchemes = [SELECT Id, Business_Unit__c, Business_Unit__r.Name, Amount_Type__c, Payment_Type__c, 
                                                        Credited_Company__c, Credited_Company__r.Name, Debited_Company__c, Debited_Company__r.Name,
                                                        Included_Discount_Types__c, Included_Discount_Type__c, RecordType.DeveloperName, Flag_D_or_C__c, Closing_Accounting_Type__c,
                                                        Include_Free_Invoices__c, Accounting_Entry_for__c, Store_Type__c, Managed_BU__c, Accounting_Type__c
                                                        FROM Accounting_Scheme__c
                                                        WHERE RecordType.DeveloperName = 'Redistribution'];
        Database.executeBatch(new AccountingClosingRedistributionBatch('Test', accountingClosing, accountingSchemes));
        Test.stopTest();
        // Validation Test
        List<Accounting_Entry__c> accountingEntries = [SELECT Id, Name FROM Accounting_Entry__c];
        Accounting_Entry__c accountingEntry1_HTCreditFlagC = [SELECT Id, Name, Amount__c, Amount_signed__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme1.Id LIMIT 1];
        Accounting_Entry__c accountingEntry1_HTCreditFlagD = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme12.Id LIMIT 1];
        Accounting_Entry__c accountingEntry1_HTDebitedFlagC = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme13.Id LIMIT 1];
        Accounting_Entry__c accountingEntry2_TTCCredit = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme2.Id];
        Accounting_Entry__c accountingEntry3_TVACredit = [SELECT Id, Name, Amount__c FROM Accounting_Entry__c WHERE Accounting_Scheme_Line__c =:accountingScheme3.Id];
        
        redistribDetail1 = [SELECT Id, Accounting_entry_credit_woVAT__c, Accounting_entry_debit_woVAT__c, Accounting_entry_woVAT__c, 
                            Accounting_entry_credit_wVAT__c, Accounting_entry_credit_VAT__c, Accounting_entry_credit_woVAT_D__c, 
                            Accounting_entry_debit_woVAT_D__c, Accounting_entry_woVAT_D__c FROM Redistrib_detail__c WHERE Id =:redistribDetail1.Id];
        redistribDetail2 = [SELECT Id, Accounting_entry_credit_woVAT__c, Accounting_entry_credit_wVAT__c, Accounting_entry_credit_VAT__c FROM Redistrib_detail__c WHERE Id =:redistribDetail2.Id];
        redistribDetail3 = [SELECT Id, Accounting_entry_credit_woVAT__c, Accounting_entry_credit_wVAT__c, Accounting_entry_credit_VAT__c FROM Redistrib_detail__c WHERE Id =:redistribDetail3.Id];
        System.assertEquals(accountingEntry1_HTCreditFlagC.Id, redistribDetail1.Accounting_entry_credit_woVAT__c);
        System.assertEquals(accountingEntry1_HTCreditFlagD.Id, redistribDetail1.Accounting_entry_credit_woVAT_D__c);
        System.assertEquals(accountingEntry1_HTDebitedFlagC.Id, redistribDetail1.Accounting_entry_debit_woVAT__c);
        System.assertEquals(accountingEntry2_TTCCredit.Id, redistribDetail2.Accounting_entry_credit_wVAT__c);
        System.assertEquals(accountingEntry3_TVACredit.Id, redistribDetail3.Accounting_entry_credit_VAT__c);
        System.assertEquals(6, accountingEntry1_HTCreditFlagC.Amount__c);
        System.assertEquals(-6, accountingEntry1_HTCreditFlagC.Amount_signed__c);
        System.assertEquals(6, accountingEntry1_HTCreditFlagD.Amount__c);
        System.assertEquals(6, accountingEntry2_TTCCredit.Amount__c);
        System.assertEquals(3, accountingEntry3_TVACredit.Amount__c);
        System.assertEquals(8, accountingEntries.size());
    }
}