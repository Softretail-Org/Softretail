/**
 * Batchable class used to insert penalties conditions.
 **/ 
public with sharing class PenaltiesScanSynchroBatch implements Database.Batchable<sObject>, Database.stateful {
    
    private NegoptimBatch nb;
    public final String query;
    public static Map<String, String> penaltyFieldNameLabels;
    // Creation list of Contract Ids.
    private Set<Id> contractIdSet;
    private Set<Id> conditionIdSet;
    
    // Constructor.
    public PenaltiesScanSynchroBatch(String startedFrom, List<Id> ids) {
        this.nb = new NegoptimBatch('PenaltiesScanSynchroBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.contractIdSet = new Set<Id>();
        this.conditionIdSet = new Set<Id>();
        String q = 'SELECT Id, Name, Comment__c, Condition_Name__c, Error_desc__c, NS_Code__c, NS__c,';
        q += ' NS_Code_Prefix__c, Last_synchro_date__c, Month__c, Penalty_Number__c, Penalty_Date__c,';
        q += ' Penalty_Value__c, Section__c, Section_Code__c, Service_Rate_Fact__c, Status__c, Supplier__c,';
        q += ' Supplier_code__c, Supplier_Email__c, Supplier_Name__c, Year__c, Action_done__c, Condition_Linked__c, Invoice_Detail_Linked__c';        
        q += ' FROM Supply_Penalty__c';
        q += ' WHERE Status__c = \'New\'';
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\')';
        }
        query = q;
        // push inputs to log
        nb.logParameter('supplyPenaltyIds', ids);
        nb.logParameter('query', this.query);
    }
    // Start method implementation.
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    // Execute method implementation.
    public void execute(Database.BatchableContext BC, List<Supply_Penalty__c> scope) {
        /* 1. Prepare Declaration. */
        Set<String> supplierCodeSet = new Set<String>();
        Set<String> sectionCodeSet = new Set<String>();
        Set<String> sectionNameSet = new Set<String>();
        Set<String> conditionNameSet = new Set<String>();
        Set<String> negoScopeCodeSet = new Set<String>();
        Set<String> negoScopeCodePrefixSet = new Set<String>();
        // Collect NS Ids in a Set
        Set<Id> NSIds = new Set<Id>();        
        // List Contract Penalties to update
        List<Supply_Penalty__c> penalties = new List<Supply_Penalty__c>();
        // List of wrapper contract penalty
        List<WrapperPenalty> wPenaltyList = new List<WrapperPenalty>();
        // List of new Conditions
        List<Contract_Discount__c> contractConditionList = new List<Contract_Discount__c>();
        // List of new invoices
        List<Invoice__c> invoiceList = new List<Invoice__c>();
        // List of new invoice lines
        List<Invoice_Detail__c> invoiceLineList = new List<Invoice_Detail__c>();  
        // Map<supplier code, supplier (database)>
        Map<String, Sup_Supplier__c> suppliersMap = new Map<String, Sup_Supplier__c>();
        // Map<section code, section (database)>
        Map<String, Orga_HE__c> sectionsMap = new Map<String, Orga_HE__c>(); 
        // Map<NS Code prefix + NS Code, Sup_sup_NegoScope__c>.
        Map<String, Sup_sup_NegoScope__c> NegoScopeMap = new Map<String, Sup_sup_NegoScope__c>();
        // Map<key, List NS (database)>. The key is a concatenation of supplier Id and section code.
        Map<String, List<Id>> sectionMainNSMap = new Map<String, List<Id>>();
        // Map<key, List NS Id>. The key is a concatenation of supplier Id and section code.
        Map<String, List<Id>> sectionNsHEMap = new Map<String, List<Id>>();
        // Map<condition name, Tarrif condition (database)>
        Map<String, Pol_Com_Condition__c> tarrifConditionsMap = new Map<String, Pol_Com_Condition__c>();
        // Map<complex key, List<Contract__c>>. The key is a concatenation of supplier Id and NegoScope Id.
        Map<String, List<Contract__c>> contractMap = new Map<String, List<Contract__c>>();
        // Map<code BU, Id BU>
        Map<String, Id> codeBUMap = new Map<String, Id>();
        
        // Describe all fields for Supply_Penalty__c.
        penaltyFieldNameLabels = NegoptimHelper.GetMandatoryFieldLabels(Supply_Penalty__c.SObjectType);

        Savepoint sp = Database.setSavepoint();
        try {
            // check security on read supply penalty fields
            String[] penaltyAccessFields = new String[] { 'Id', 'Name', NegoptimHelper.normalizeAPIName('Comment__c'),
                NegoptimHelper.normalizeAPIName('Condition_Name__c'), NegoptimHelper.normalizeAPIName('Error_desc__c'), 
                NegoptimHelper.normalizeAPIName('Last_synchro_date__c'), NegoptimHelper.normalizeAPIName('Month__c'),
                NegoptimHelper.normalizeAPIName('Penalty_Number__c'), NegoptimHelper.normalizeAPIName('Penalty_Date__c'),
                NegoptimHelper.normalizeAPIName('Penalty_Value__c'), NegoptimHelper.normalizeAPIName('Section__c'),
                NegoptimHelper.normalizeAPIName('Section_Code__c'), NegoptimHelper.normalizeAPIName('Service_Rate_Fact__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Supplier__c'),
                NegoptimHelper.normalizeAPIName('Supplier_code__c'), NegoptimHelper.normalizeAPIName('Supplier_Email__c'),
                NegoptimHelper.normalizeAPIName('Supplier_Name__c'), NegoptimHelper.normalizeAPIName('Year__c'),
                NegoptimHelper.normalizeAPIName('Action_done__c'), NegoptimHelper.normalizeAPIName('Condition_Linked__c'),
                NegoptimHelper.normalizeAPIName('NS_Code__c'), NegoptimHelper.normalizeAPIName('NS__c'),
                NegoptimHelper.normalizeAPIName('NS_Code_Prefix__c')};
            
            // check security on read supplier fields
            String[] supplierAccessFields = new String[] { 'Id', 'Name', 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Code__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Country_origin__c')};
            
            // check security on read section fields
            String[] sectionAccessFields = new String[] { 'Id', 'Name', NegoptimHelper.normalizeAPIName('Elt_Code__c'),
                NegoptimHelper.normalizeAPIName('Dispatch_Inv_Hierarchy_Starting_Point__c')};
            
            // check security on read NS fields
            String[] negoScopeAccessFields = new String[] { 'Id', 'Name', 'CurrencyIsoCode', 
                NegoptimHelper.normalizeAPIName('NS_Code_Prefix__c'), NegoptimHelper.normalizeAPIName('NS_Code__c'), NegoptimHelper.normalizeAPIName('Supplier__c'),
                NegoptimHelper.normalizeAPIName('NS_Section_main__c'), NegoptimHelper.normalizeAPIName('Parent_Nego_Scope__c')};
            
            // check security on read supplier HE fields
            String[] supplierNsHEAccessFields = new String[] { 'Id', 'Name',
                NegoptimHelper.normalizeAPIName('Structure_Element__c'), NegoptimHelper.normalizeAPIName('Sup_sup_NegoScope__c')};
            
            // check security on read policy tariff conditions fields
            String[] tarrifConditionAccessFields = new String[] { 'Id', 'Name',
                NegoptimHelper.normalizeAPIName('Nego_Discount_Type__c'), NegoptimHelper.normalizeAPIName('Acc_Document_Type__c'),
                NegoptimHelper.normalizeAPIName('VAT_Type__c')};
            
            // check security on read contract fields
            String[] contractAccessFields = new String[] { 'Id', 'Name',
                NegoptimHelper.normalizeAPIName('Contract_Numbder__c'), NegoptimHelper.normalizeAPIName('Supplier__c'),
                NegoptimHelper.normalizeAPIName('Supplier_Nego_Scope__c'), NegoptimHelper.normalizeAPIName('Contract_BDate__c'),
                NegoptimHelper.normalizeAPIName('Contract_EDate__c'), NegoptimHelper.normalizeAPIName('Total_to__c'),
                NegoptimHelper.normalizeAPIName('Contract_Type__c')};
            
            /* 2. Prepare Load Data. */
            for(Supply_Penalty__c item : scope) {
                // Fill supplier code set.
                if(item.Supplier_code__c != null && !supplierCodeSet.contains(item.Supplier_code__c)) {
                    supplierCodeSet.add(item.Supplier_code__c);
                }
                // Fill section code set.
                if(item.Section_Code__c != null && !sectionCodeSet.contains(item.Section_Code__c)) {
                    sectionCodeSet.add(item.Section_Code__c);
                }
                // Fill condition name set.
                if(item.Condition_Name__c != null && !conditionNameSet.contains(item.Condition_Name__c)) {
                    conditionNameSet.add(item.Condition_Name__c);
                }
                // Fill nego scope code set.
                if(item.NS_Code__c != null && !negoScopeCodeSet.contains(item.NS_Code__c)) {
                    negoScopeCodeSet.add(item.NS_Code__c);
                }
                // Fill nego scope code prefix set.
                if(item.NS_Code_Prefix__c != null && !negoScopeCodePrefixSet.contains(item.NS_Code_Prefix__c)) {
                    negoScopeCodePrefixSet.add(item.NS_Code_Prefix__c);
                }
            }
            
            // Get suppliers.
            List<Sup_Supplier__c> suppliers = new List<Sup_Supplier__c>();
            if(supplierCodeSet.size() > 0 && NegoptimHelper.checkAccessibility(Sup_Supplier__c.SObjectType, supplierAccessFields)) {
                suppliers = [SELECT Id, Name, CurrencyIsoCode, Code__c, Country_origin__c
                             FROM Sup_Supplier__c
                             WHERE Status__c = 'Active'
                             AND Code__c IN :supplierCodeSet];
                for(Sup_Supplier__c item : suppliers) {
                    suppliersMap.put(item.Code__c, item);
                }
            }
            
            // Get sections.
            List<Orga_HE__c> sections = new List<Orga_HE__c>();
            if(sectionCodeSet.size() > 0 && NegoptimHelper.checkAccessibility(Orga_HE__c.SObjectType, sectionAccessFields)) {
                sections = [SELECT Id, Name, Elt_Code__c
                            FROM Orga_HE__c
                            WHERE Status__c = 'Active'
                            AND Elt_Code__c IN :sectionCodeSet
                            AND Dispatch_Inv_Hierarchy_Starting_Point__c = True];
                for (Orga_HE__c item : sections) {
                    sectionsMap.put(item.Elt_Code__c, item);
                    sectionNameSet.add(item.Name);
                }
            }
            
            // Get NS based on the (nego scope code) or (section code and the suppliers).
            if((negoScopeCodeSet.size() > 0 || (suppliers.size() > 0 && sectionNameSet.size() > 0)) &&
               NegoptimHelper.checkAccessibility(Sup_Supplier__c.SObjectType, supplierAccessFields) &&
               NegoptimHelper.checkAccessibility(Orga_HE__c.SObjectType, sectionAccessFields) &&
               NegoptimHelper.checkAccessibility(Sup_sup_NegoScope__c.SObjectType, negoScopeAccessFields))
            {
                for (Sup_sup_NegoScope__c item : [SELECT Id, Name, NS_Code__c, Supplier__c, NS_Section_main__c,
                                                  NS_Code_Prefix__c, Parent_Nego_Scope__c, CurrencyIsoCode
                                                  FROM Sup_sup_NegoScope__c
                                                  WHERE (NS_Code__c IN :negoScopeCodeSet
                                                         OR (Supplier__c IN :suppliers
                                                             AND NS_Section_main__c LIKE :sectionNameSet))
                                                  AND NS_Code_Prefix__c IN :negoScopeCodePrefixSet]) 
                {
                    if(!negoScopeCodeSet.contains(item.NS_Code__c)) {
                        String key = item.NS_Code_Prefix__c + '' + item.Supplier__c + '' + item.NS_Section_main__c;
                        if(sectionMainNSMap.containsKey(key)) {
                            sectionMainNSMap.get(key).add(item.Id);
                        } else {
                            sectionMainNSMap.put(key, new List<Id>{ item.Id });
                        }
                        // Get NS Ids
                        if (item.Parent_Nego_Scope__c == null) {
                            NSIds.add(item.Id);
                        } else {
                            NSIds.add(item.Parent_Nego_Scope__c);
                        }
                    }
                    NegoScopeMap.put(item.NS_Code_Prefix__c + '' + item.NS_Code__c, item);
                }
            }
            
            // Get NS HE based on the section code and the suppliers.
            if(suppliers.size() > 0 && sections.size() > 0 &&
               NegoptimHelper.checkAccessibility(Sup_Supplier__c.SObjectType, supplierAccessFields) &&
               NegoptimHelper.checkAccessibility(Orga_HE__c.SObjectType, sectionAccessFields) &&
               NegoptimHelper.checkAccessibility(Supplier_NS_HE__c.SObjectType, supplierNsHEAccessFields))
            {
                for (Supplier_NS_HE__c item : [SELECT Id, Name, Structure_Element__c, Sup_sup_NegoScope__c,
                                               Sup_sup_NegoScope__r.NS_Code_Prefix__c, Sup_sup_NegoScope__r.Parent_Nego_Scope__c,
                                               Sup_sup_NegoScope__r.Supplier__c, Structure_Element__r.Elt_Code__c
                                               FROM Supplier_NS_HE__c
                                               WHERE Sup_sup_NegoScope__r.Supplier__c IN :suppliers
                                               AND Structure_Element__c IN :sections])
                {
                    String key = item.Sup_sup_NegoScope__r.NS_Code_Prefix__c + '' + item.Sup_sup_NegoScope__r.Supplier__c + '' + item.Structure_Element__r.Elt_Code__c;
                    if(sectionNsHEMap.containsKey(key)) {
                        sectionNsHEMap.get(key).add(item.Sup_sup_NegoScope__c);
                    } else {
                        sectionNsHEMap.put(key, new List<Id>{ item.Sup_sup_NegoScope__c });
                    }
                    // Get NS Ids
                    if (item.Sup_sup_NegoScope__r.Parent_Nego_Scope__c == null) {
                        NSIds.add(item.Sup_sup_NegoScope__c);
                    } else {
                        NSIds.add(item.Sup_sup_NegoScope__r.Parent_Nego_Scope__c);
                    }
                }
            }
                        
            // Get all Policy Tariff conditions.
            if(NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, tarrifConditionAccessFields)) {
                for (Pol_Com_Condition__c item : [SELECT Id, Name, Nego_Discount_Type__c, Acc_Document_Type__c, VAT_Type__c
                                                  FROM Pol_Com_Condition__c
                                                  WHERE Name IN :conditionNameSet]) 
                {
                    tarrifConditionsMap.put(item.Name, item);
                }
            }
            
            // Get contracts based on suppliers and NS.
            if((negoScopeCodeSet.size() > 0 || (suppliers.size() > 0 && NSIds.size() > 0)) &&
               NegoptimHelper.checkAccessibility(Sup_Supplier__c.SObjectType, supplierAccessFields) &&
               NegoptimHelper.checkAccessibility(Sup_sup_NegoScope__c.SObjectType, negoScopeAccessFields) &&
               NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractAccessFields))
            {
                for (Contract__c item : [SELECT Id, Name, Contract_Numbder__c, Supplier__c, Supplier_Nego_Scope__c, 
                                         Supplier_Nego_Scope__r.NS_Code__c, Contract_BDate__c, Contract_EDate__c, Total_to__c
                                         FROM Contract__c
                                         WHERE ((Supplier_Nego_Scope__r.NS_Code__c IN :negoScopeCodeSet)
                                                OR (Supplier__c IN :suppliers AND Supplier_Nego_Scope__c IN :NSIds))
                                         AND Supplier_Nego_Scope__r.NS_Code_Prefix__c IN :negoScopeCodePrefixSet
                                         AND Contract_Type__c = 'Contract'
                                         ORDER BY Total_to__c DESC])
                {
                    String key = item.Supplier__c + '' + item.Supplier_Nego_Scope__c;
                    if(contractMap.containsKey(key)) {
                        contractMap.get(key).add(item);
                    } else {
                        contractMap.put(key, new List<Contract__c> {item});
                    }
                }
            }
            
            // Get all BU countries related to negoScopeCodePrefixSet
            if((negoScopeCodePrefixSet.size() > 0) &&
               NegoptimHelper.checkAccessibility(Orga_BU__c.SObjectType, new String[] {'Id', NegoptimHelper.normalizeAPIName('BU_Code__c')}))
            {
                for (Orga_BU__c item: [SELECT Id, BU_Code__c FROM Orga_BU__c
                                       WHERE RecordType.DeveloperName = 'Country'
                                       AND BU_Code__c IN :negoScopeCodePrefixSet])
                {
                    codeBUMap.put(item.BU_Code__c, item.Id);
                }
            }
            
            if(NegoptimHelper.checkAccessibility(Supply_Penalty__c.SObjectType, penaltyAccessFields) &&
               NegoptimHelper.checkAccessibility(Sup_Supplier__c.SObjectType, supplierAccessFields) &&
               NegoptimHelper.checkAccessibility(Orga_HE__c.SObjectType, sectionAccessFields) &&
               NegoptimHelper.checkAccessibility(Sup_sup_NegoScope__c.SObjectType, negoScopeAccessFields) &&
               NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, tarrifConditionAccessFields) &&
               NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractAccessFields))
            {
                /* 3. Prepare Process. */
                for(Supply_Penalty__c item : scope) {
                    WrapperPenalty wline = new WrapperPenalty(item);
                    // Check Mandatory fields
                    wline.checkMandatoryFields();
                    if(!wline.isValid) {
                        // Error
                    }
                    // Get Supplier
                    if(item.Supplier_code__c != null && suppliersMap.containsKey(item.Supplier_code__c)) {
                        wline.supplier = suppliersMap.get(item.Supplier_code__c);
                        wline.penalty.Supplier__c = wline.supplier.Id;
                        wline.penalty.Supplier_Name__c = wline.supplier.Name;
                    }
                    // Get NS
                    if(item.NS_Code__c != null && NegoScopeMap.containsKey(item.NS_Code_Prefix__c + '' + item.NS_Code__c)) {
                        wline.negoScope = NegoScopeMap.get(item.NS_Code_Prefix__c + '' + item.NS_Code__c);
                        wline.penalty.NS__c = wline.negoScope.Id;
                    }
                    // Get Section
                    if(item.Section_Code__c != null && sectionsMap.containsKey(item.Section_Code__c)) {
                        wline.section = sectionsMap.get(item.Section_Code__c);
                        wline.penalty.Section__c = wline.section.Id;
                    }
                    // Get Tarrif Condition
                    if(item.Condition_Name__c != null && tarrifConditionsMap.containsKey(item.Condition_Name__c)) {
                        wline.tarrifCondition = tarrifConditionsMap.get(item.Condition_Name__c);
                    }
                    if(wline.supplier == null || wline.tarrifCondition == null || (wline.negoScope == null && item.NS_Code__c != null) || (wline.section == null && item.Section_Code__c != null)) {
                        if(wline.supplier == null && item.Supplier_code__c != null) wline.actionToDoMessage += string.format(Label.MSG_SupplierNotExist, new String[]{ item.Supplier_code__c }) + '\n';
                        if(wline.tarrifCondition == null && item.Condition_Name__c != null) wline.actionToDoMessage += string.format(Label.MSG_ConditionNotExist, new String[]{ item.Condition_Name__c }) + '\n';
                        if(wline.negoScope == null && item.NS_Code__c != null) wline.actionToDoMessage += string.format(Label.MSG_NSCodeNotExist, new String[]{ item.NS_Code__c }) + '\n';
                        if(wline.section == null && item.Section_Code__c != null) wline.actionToDoMessage += string.format(Label.MSG_SectionNotExist, new String[]{ item.Section_Code__c }) + '\n';
                        wline.isValid = false;
                    }
                    if(wline.negoScope != null && wline.supplier != null && wline.negoScope.Supplier__c != wline.supplier.Id) {
                        wline.actionToDoMessage += string.format(Label.MSG_NS_Not_Related_Supplier, new String[]{ item.NS_Code__c }) + '\n';
                        wline.isValid = false;
                    }
                    if(wline.isValid) {
                        List<Id> NSIdList;
                        Contract__c refContract = null;
                        if(wline.negoScope == null) {
                            // Get from Main NS
                            if(sectionMainNSMap.containsKey(item.NS_Code_Prefix__c + '' + wline.supplier.Id + '' + wline.section.Name)) {
                                NSIdList = sectionMainNSMap.get(item.NS_Code_Prefix__c + '' + wline.supplier.Id + '' + wline.section.Name);
                            }
                            // Get from relation NS HE
                            else if(sectionNsHEMap.containsKey(item.NS_Code_Prefix__c + '' + wline.supplier.Id + '' + wline.section.Elt_Code__c)) {
                                NSIdList = sectionNsHEMap.get(item.NS_Code_Prefix__c + '' + wline.supplier.Id + '' + wline.section.Elt_Code__c);
                            }
                        } else {
                            NSIdList = new List<Id> { wline.negoScope.Id };
                        }
                        // If NS not found for the scope, line is Rejected
                        if(NSIdList != null && NSIdList.size() > 0) {
                            refContract = wline.findContract(NSIdList, contractMap);
                            wline.contract = refContract;
                        } else {
                            wline.actionToDoMessage += Label.MSG_NSNotExist + '\n';
                        }
                        if(refContract == null) wline.actionToDoMessage += Label.MSG_ContractNotExist + '\n';
                    }
                    if(wline.isValid) {
                        if(wline.contract != null) {
                            wline.generateContractLine(codeBUMap.get(wline.penalty.NS_Code_Prefix__c));
                            wline.actionDoneMessage += string.format(Label.MSG_ContractExist, new String[]{ wline.contract.Name }) + '\n';
                            wline.penalty.status__c = 'Synchronized';
                        }
                        else {
                            // Generate invoice without condition
                            wline.generateInvoiceLine(codeBUMap.get(wline.penalty.NS_Code_Prefix__c));
                            wline.actionDoneMessage += Label.MSG_InvoiceLineGenerated + '\n';
                            wline.penalty.status__c = 'Synchronized without Contract';
                        }
                    }
                    else {
                        wline.penalty.status__c = 'Rejected'; 
                    }
                    wline.penalty.Error_desc__c = wline.errorDescMessage + wline.actionToDoMessage;
                    wline.penalty.Action_done__c = wline.actionDoneMessage;
                    wline.penalty.Last_synchro_date__c = System.now();
                    wPenaltyList.add(wline);
                }
            }
            
            // check security on update penalty fields
            String[] penaltyUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Error_desc__c'), NegoptimHelper.normalizeAPIName('Action_done__c'),
                NegoptimHelper.normalizeAPIName('Last_synchro_date__c'), NegoptimHelper.normalizeAPIName('Condition_Linked__c')};
            
            String[] invoiceCreateFields = new String[] { 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Inv_Date__c'),
                NegoptimHelper.normalizeAPIName('Inv_DueDate__c'), NegoptimHelper.normalizeAPIName('Inv_Business_Unit__c'),
                NegoptimHelper.normalizeAPIName('Sequence_Number__c'), NegoptimHelper.normalizeAPIName('Status_BDate__c'),
                NegoptimHelper.normalizeAPIName('Inv_FiscalYear__c'), NegoptimHelper.normalizeAPIName('Inv_Comment__c'),
                NegoptimHelper.normalizeAPIName('Acc_Document_Type__c')};
            
            String[] invoiceDetailCreateFields = new String[] { 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Inv_Detail_BU__c'),
                NegoptimHelper.normalizeAPIName('Inv_Detail_Condition__c'), NegoptimHelper.normalizeAPIName('Invoice_Value__c'),
                NegoptimHelper.normalizeAPIName('Inv_Detail_Comment__c'), NegoptimHelper.normalizeAPIName('Invoice_detail_nego_disc_type__c'),
                NegoptimHelper.normalizeAPIName('Inv_VAT_Percent__c') };
            
            String[] conditionCreateFields = new String[] { 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Contract__c'),
                NegoptimHelper.normalizeAPIName('Condition_Type__c'), NegoptimHelper.normalizeAPIName('Nego_Discount_Type__c'),
                NegoptimHelper.normalizeAPIName('is_duplicable__c'), NegoptimHelper.normalizeAPIName('Disc_BDate__c'),
                NegoptimHelper.normalizeAPIName('Disc_EDate__c'), NegoptimHelper.normalizeAPIName('Product_Scope__c'),
                NegoptimHelper.normalizeAPIName('BU_Scope__c'), NegoptimHelper.normalizeAPIName('commercial_reference__c'),
                NegoptimHelper.normalizeAPIName('Value_amt__c'), NegoptimHelper.normalizeAPIName('Valid__c'),
                NegoptimHelper.normalizeAPIName('comments__c'), NegoptimHelper.normalizeAPIName('Invoice_period__c'),
                NegoptimHelper.normalizeAPIName('first_invoice_date__c')};
            
            // check security on read policy sales conditions fields
            String[] salesConditionAccessFields = new String[] { 'Id', 'Name',
                NegoptimHelper.normalizeAPIName('VAT_Rebate_Rate__c'), NegoptimHelper.normalizeAPIName('VAT_Service_Rate__c'),
                NegoptimHelper.normalizeAPIName('VAT_Finance_Rate__c'), NegoptimHelper.normalizeAPIName('Status_BDate__c'),
                NegoptimHelper.normalizeAPIName('Master_BU__c'), NegoptimHelper.normalizeAPIName('Buying_Payment_Term_Abbrev__c'),
                NegoptimHelper.normalizeAPIName('Services_Payment_Term_Abbrev__c')};
            
            if(NegoptimHelper.checkUpdatibility(Supply_Penalty__c.SObjectType, penaltyUpdateFields) &&
               NegoptimHelper.checkCreatibility(Invoice__c.SObjectType, invoiceCreateFields) &&
               NegoptimHelper.checkCreatibility(Invoice_Detail__c.SObjectType, invoiceDetailCreateFields) &&
               NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionCreateFields) &&
               NegoptimHelper.checkAccessibility(Pol_Sale_Condition__c.SObjectType, salesConditionAccessFields))
            {
                // Map between Contract Discount and Penalty
                Map<Integer, Supply_Penalty__c> conditionMap = new Map<Integer, Supply_Penalty__c>();
                // Map between invoiceKey and invoice
                Map<String, Invoice__c> invoiceMap = new Map<String, Invoice__c>();
                // Map between invoice line and Penalty
                Map<Integer, Supply_Penalty__c> invoiceLineMap = new Map<Integer, Supply_Penalty__c>();
                // List of countries for suppliers for penalty records having no contracts
                List<Id> countries = new List<Id>();
                // List of years for penalty records having no contracts
                List<Integer> years = new List<Integer>();
                integer indexCond = 0, indexInvLine = 0;
                for (WrapperPenalty item : wPenaltyList) {
                    penalties.add(item.penalty);
                    if(item.condition != null) {
                        contractConditionList.add(item.condition);
                        conditionMap.put(indexCond, item.penalty);
                        indexCond++;
                    }
                    if(item.invoiceDetail != null) {
                        if(!invoiceMap.containsKey(item.invoiceKey)) {
                            Id buId = codeBUMap.containsKey(item.penalty.NS_Code_Prefix__c) ? codeBUMap.get(item.penalty.NS_Code_Prefix__c) : item.supplier.Country_origin__c;
                            Invoice__c invoice = new Invoice__c(Inv_Date__c = item.firstInvoiceDate, Inv_DueDate__c = item.firstInvoiceDate.addDays(30), Inv_Supplier__c = item.supplier.Id,
                                                                Inv_Business_Unit__c = buId, Sequence_Number__c = item.month, Inv_FiscalYear__c = item.year,
                                                                Status_BDate__c = item.firstInvoiceDate, CurrencyIsoCode = item.supplier.CurrencyIsoCode,
                                                                Inv_Comment__c = item.comment, Acc_Document_Type__c = item.tarrifCondition.Acc_Document_Type__c);
                            ////invoice.recalculateFormulas();
                            invoiceMap.put(item.invoiceKey, invoice);
                        }
                        invoiceLineList.add(item.invoiceDetail);
                        invoiceLineMap.put(indexInvLine, item.penalty);
                        indexInvLine++;
                        // fill countries list
                        countries.add(item.supplier.Country_origin__c);
                        // fill year list
                        years.add(item.year);
                    }
                }
                // insert free invoices
                if(invoiceMap != null && invoiceMap.size() > 0) {
                    // fetch VAT from Sales conditions corresponding to the countries of suppliers and years in the records
                    // Get Pol_Sale_Condition__c for all contract
                    Map<String, Pol_Sale_Condition__c> salesConditionsMap = new Map<String, Pol_Sale_Condition__c>();
                    for(Pol_Sale_Condition__c item : [SELECT Id, VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c,
                                                      Status_BDate__c, Master_BU__c, Buying_Payment_Term_Abbrev__c, Services_Payment_Term_Abbrev__c
                                                      FROM Pol_Sale_Condition__c
                                                      WHERE CALENDAR_YEAR(Status_BDate__c) IN :years
                                                      AND Master_BU__c IN :countries])
                    {
                        salesConditionsMap.put(item.Status_BDate__c.Year() + '' + item.Master_BU__c, item);
                    }
                    // insert invoices head
                    List<Database.SaveResult> results = Database.insert(invoiceMap.values(), false);
                    nb.logResults(results, invoiceMap.values());
                    
                    // Load inserted invoices to get the formula Is_Foreign_Supplier__c
                    Map<Id, Invoice__c> insertedInvoicesMap = new Map<Id, Invoice__c>([SELECT Is_Foreign_Supplier__c FROM Invoice__c WHERE Id IN :invoiceMap.values()]);
                    for (WrapperPenalty item : wPenaltyList) {
                        if(item.invoiceDetail != null && invoiceMap.containsKey(item.invoiceKey)) {
                            item.invoiceDetail.Invoice__c = invoiceMap.get(item.invoiceKey).Id;
                            Boolean isForeignSupplier = insertedInvoicesMap.get(item.invoiceDetail.Invoice__c).Is_Foreign_Supplier__c;
                            // Get invoice VAT
                            Decimal vatPercent = 0;
                            if(salesConditionsMap.containsKey(item.year + '' + item.supplier.Country_origin__c) && !isForeignSupplier) {
                                String vatType = item.tarrifCondition.VAT_Type__c;
                                Pol_Sale_Condition__c salesCondition = salesConditionsMap.get(item.year + '' + item.supplier.Country_origin__c);
                                if (vatType == 'Service') {
                                    vatPercent = salesCondition.VAT_Service_Rate__c != null ? salesCondition.VAT_Service_Rate__c : vatPercent;
                                }
                                else if (vatType == 'Rebate') {
                                    vatPercent = salesCondition.VAT_Rebate_Rate__c != null ? salesCondition.VAT_Rebate_Rate__c : vatPercent;
                                }
                            }
                            item.invoiceDetail.Inv_VAT_Percent__c = vatPercent;
                        }
                    }
                    // insert invoice lines
                    results = Database.insert(invoiceLineList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Invoice_Detail__c invoiceDetail = invoiceLineList.get(i);
                        Supply_Penalty__c penalty = invoiceLineMap.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = result.Id != null ? invoiceDetail.Name + '(' + result.Id + ') : ' : String.valueOf(invoiceDetail);
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors){
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            penalty.Error_desc__c += errorMessage;
                            penalty.Status__c = 'Error during synchro';
                        }
                        else {
                            penalty.Invoice_Detail_Linked__c = invoiceDetail.Id;
                        }
                    }
                }
                // insert new conditions
                if(contractConditionList != null && contractConditionList.size() > 0) {
                    List<Database.SaveResult> results = Database.insert(contractConditionList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Contract_Discount__c condition = contractConditionList.get(i);
                        Supply_Penalty__c penalty = conditionMap.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = result.Id != null ? condition.Name + '(' + result.Id + ') : ' : String.valueOf(condition);
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors){
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            penalty.Error_desc__c += errorMessage;
                            penalty.Status__c = 'Error during synchro';
                        }
                        else{
                            penalty.Condition_Linked__c = condition.Id;
                            penalty.Action_done__c += string.format(Label.MSG_Penalty_Linked, new String[]{ penalty.Name }) + '\n';
                            if(!contractIdSet.contains(condition.Contract__c)) {
                                contractIdSet.add(condition.Contract__c);
                            }
                            if(!conditionIdSet.contains(condition.Id)) {
                                conditionIdSet.add(condition.Id);
                            }
                        }
                    }
                }
                // update penalties
                if(penalties != null && penalties.size() > 0){
                    List<Database.SaveResult> results = Database.update(penalties, false);
                    nb.logResults(results, penalties);
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    // Finish method implementation.
    public void finish(Database.BatchableContext BC) {
        // Execute Generate Invoices Batch.
        if (contractIdSet.size() > 0) {
            Database.executeBatch(new GenerateInvoicesBatch('PenaltiesScanSynchroBatch', null, new List<Id>(contractIdSet), new List<Id>(conditionIdSet), Date.Today()), 150);
        }
        // Send Email.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    /* Wrapper Class for Contract Penalty Line */
    public class WrapperPenalty {
        
        Supply_Penalty__c penalty {get; set;}
        Sup_sup_NegoScope__c negoScope {get; set;}
        Orga_HE__c section {get; set;}
        Sup_Supplier__c supplier {get; set;}
        Contract__c contract {get; set;}
        Pol_Com_Condition__c tarrifCondition {get; set;}
        Contract_Discount__c condition {get; set;}
        Invoice_Detail__c invoiceDetail {get; set;}
        Boolean isValid {get; set;}
        String errorDescMessage {get; set;}
        String actionToDoMessage {get; set;}
        String actionDoneMessage {get; set;}
        
        // new fields
        String comment {
            get {
                String s = '';
                if(penalty.Service_Rate_Fact__c != null)
                    s += penalty.Service_Rate_Fact__c + ' - ';
                return s + penalty.Comment__c;
            }
            set;
        }
        Integer year {
            get {
                return Integer.valueOf(penalty.Year__c);
            }
            set;
        }
        Integer month {
            get {
                return Integer.valueOf(penalty.Month__c);
            }
            set;
        }
        Date firstInvoiceDate {
            get {
                return Date.today() > NegoptimHelper.getLastDayOfMonth(year, month) ? NegoptimHelper.getLastDayOfMonth(year, month) : Date.today();
            }
            set;
        }
        String invoiceKey {
            get {
                return supplier.Id + '' + year + month + penalty.Condition_Name__c;
            }
            set;
        }
        // constructor
        public WrapperPenalty(Supply_Penalty__c p) {
            penalty = p;
            isValid = true;
            errorDescMessage = '';
            actionToDoMessage = '';
            actionDoneMessage = '';
        }
        // Check Mandatory Fields
        public void checkMandatoryFields() {
            if(penalty.Supplier_code__c == null || penalty.Condition_Name__c == null ||
               penalty.Year__c == null || penalty.Month__c == null)
            {
                if(penalty.Supplier_code__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ penaltyFieldNameLabels.get('Supplier_code__c') }) + '\n';
                if(penalty.Condition_Name__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ penaltyFieldNameLabels.get('Condition_Name__c') }) + '\n';               
                if(penalty.Year__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ penaltyFieldNameLabels.get('Year__c') }) + '\n';                
                if(penalty.Month__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ penaltyFieldNameLabels.get('Month__c') }) + '\n';               
                this.isValid = false;
            }
        }
        // Get the contract based to nego scope and with max total_to
        public Contract__c findContract(List<Id> NSs, Map<String, List<Contract__c>> contractMap) { 
            Contract__c refContract = null;
            Decimal TotalTo;
            if(NSs != null && NSs.size() > 0) {
                // CASE: multiple contract on same NS
                if(NSs.size() == 1) {
                    String key = supplier.Id + '' +  NSs.get(0);
                    List<Contract__c> nsContracts = contractMap.get(key);
                    if(nsContracts != null && nsContracts.size() > 0) {
                        for(Contract__c con : nsContracts) {                            
                            if((con.Contract_BDate__c.year() <= year && con.Contract_BDate__c.month() <= month) &&
                               (con.Contract_EDate__c.year() >= year && con.Contract_EDate__c.month() >= month))
                            {
                                refContract = con;
                                break;
                            }
                        }
                    }
                }
                // CASE: multiple NS with multi contracts
                else if(NSs.size() > 1) {
                    for(Id Ns : NSs) {
                        String key = supplier.Id + '' + Ns;
                        List<Contract__c> nsContracts = contractMap.get(key);
                        if(nsContracts != null && nsContracts.size() > 0) {
                            for(Contract__c con : nsContracts) {
                                if((con.Contract_BDate__c.year() <= year && con.Contract_BDate__c.month() <= month) &&
                                   (con.Contract_EDate__c.year() >= year && con.Contract_EDate__c.month() >= month))
                                {
                                    if((TotalTo == null) || (TotalTo != null && con.Total_to__c >= TotalTo)) {
                                        refContract = con;
                                        TotalTo = con.Total_to__c;
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            return refContract;
        }
        // Create new condition based on contract penalty
        public void generateContractLine(Id buId) {
            Contract_Discount__c newCondition = new Contract_Discount__c(Contract__c = contract.Id, Condition_Type__c = tarrifCondition.Id,
                                                                         Nego_Discount_Type__c = tarrifCondition.Nego_Discount_Type__c, 
                                                                         CurrencyIsoCode = supplier.CurrencyIsoCode, is_duplicable__c = false,
                                                                         Disc_BDate__c = Date.newInstance(year, month, 1), 
                                                                         Disc_EDate__c = NegoptimHelper.getLastDayOfMonth(year, month),
                                                                         Product_Scope__c = contract.Supplier_Nego_Scope__c,
                                                                         commercial_reference__c = String.valueOf(penalty.Penalty_Number__c),
                                                                         Value_amt__c = penalty.Penalty_Value__c, Valid__c = true,
                                                                         comments__c = comment, Invoice_period__c = 'Year', first_invoice_date__c = firstInvoiceDate,
                                                                         Payment_Condition__c = 'Net', Payment_Days__c = '30');
            // if bu country not found => take bu of supplier
            newCondition.BU_Scope__c = buId == null ? supplier.Country_origin__c : buId;
            String fieldName = 'Value_amt_disp_M' + month + '__c';
            newCondition.put(fieldName, penalty.Penalty_Value__c);
            this.condition = newCondition;
        }
        // Generate new invoice line in case no contract found
        public void generateInvoiceLine(Id buId) {
            invoiceDetail = new Invoice_Detail__c(Inv_Detail_Condition__c = tarrifCondition.Id,
                                                  Invoice_Value__c = penalty.Penalty_Value__c, Inv_Detail_Comment__c = comment,
                                                  Invoice_detail_nego_disc_type__c = tarrifCondition.Nego_Discount_Type__c,
                                                  CurrencyIsoCode = supplier.CurrencyIsoCode, Inv_VAT_Percent__c = 0);
            // if bu country not found => take bu of supplier
            invoiceDetail.Inv_Detail_BU__c = buId == null ? supplier.Country_origin__c : buId;
        }
    }
}