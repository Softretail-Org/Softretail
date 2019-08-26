/**
 * Objectif 0: envoyer ces taux au système ERP pour calculer les prix et marges des produits
 * Objectif 1: controler les contrats et l'evolution des nego par rayon
 * */
public with sharing class GenerateGRCRatesBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    public final String query;
    public final Id country;
    public final List<Id> contractIds;
    public final Date theDate;
    
    public GenerateGRCRatesBatch(String startedFrom, Id countryId, List<Id> cId, Date d, Boolean lastActiveContract) {
        this.nb = new NegoptimBatch('Generate GRC Rates Batch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.country = countryId;
        this.contractIds = cId;
        // Set today as default date if d is null
        this.theDate = d == null ? Date.today() : d;
        
        String q = 'SELECT Id, Name, Supplier__c, Supplier_Nego_Scope__c, Contract_BU__c,';
        q += ' (SELECT Id, Contract__c, Product_Scope__c, Product_Scope__r.Parent_Nego_Scope__c,';
        q += ' Contract__r.Contract_BU__c, Contract__r.Supplier__c';
        q += ' FROM Contract_Discounts__r';
        q += ' WHERE Valid__c = true';
        if(d != null) {
            q += ' AND Disc_BDate__c <= :theDate';
            q += ' AND Disc_EDate__c >= :theDate';
        }
        q += ' AND Index__c <> null';
        q += ' )';
        q += ' FROM Contract__c';
        q += ' WHERE Contract_Type__c = \'Contract\' ';
        if(country != null) {
            q += ' AND Contract_BU__c = \'' + country + '\' ';
        }
        if(contractIds != null && contractIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(contractIds, '\',\'') +'\')';
        }
        else {
            q += ' AND Reference_Year__c = ' + theDate.year() + '';
        }
        if(lastActiveContract != null && lastActiveContract) {
            q += ' AND Last_Active_Contract__c = true';
        }
        query = q;
        // push inputs to log
        nb.logParameter('countryId', this.country);
        nb.logParameter('contractIds', this.contractIds);
        nb.logParameter('selectedDate', this.theDate);
        nb.logParameter('lastActiveContract', lastActiveContract);
        nb.logParameter('query', this.query);
    }
    // start
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // execute
    public void execute(Database.BatchableContext bc, List<Contract__c> scope) {
        // Map every NS Id with its parent NS Id if exist
        Map<Id, Id> negoscopeParentsMap = new Map<Id, Id>();
        // Map of contracts with related supplier
        Map<Id, Id> contractSupplierMap = new Map<Id, Id>();
        // Map of contracts with related BU
        Map<Id, Id> contractBUMap = new Map<Id, Id>();
        // List of all condition Ids
        List<Id> allConditionIdList = new List<Id>();
        // Set of all NS Ids
        Set<Id> allNSIdSet = new Set<Id>();
        // List of contractsWithoutConditions
        List<Contract__c> contractsWithoutConditions = new List<Contract__c>();
        
        Savepoint sp = Database.setSavepoint();
        try {
            for(Contract__c contract : scope) {
                if(contract.Contract_Discounts__r.size() > 0) {
                    for(Contract_Discount__c item : contract.Contract_Discounts__r) {
                        if(!allNSIdSet.contains(item.Product_Scope__c)) {
                            allNSIdSet.add(item.Product_Scope__c);
                        }
                        if(item.Product_Scope__r.Parent_Nego_Scope__c != null) {
                            negoscopeParentsMap.put(item.Product_Scope__c, item.Product_Scope__r.Parent_Nego_Scope__c);
                            if(!allNSIdSet.contains(item.Product_Scope__r.Parent_Nego_Scope__c)) {
                                allNSIdSet.add(item.Product_Scope__r.Parent_Nego_Scope__c);
                            }
                        }
                        allConditionIdList.add(item.Id);
                    }
                } else {
                    if(!allNSIdSet.contains(contract.Supplier_Nego_Scope__c)) {
                        allNSIdSet.add(contract.Supplier_Nego_Scope__c);
                    }
                    contractsWithoutConditions.add(contract);
                }
                // Fill the map of contract with supplier
                if(!contractSupplierMap.containsKey(contract.Id)) {
                    contractSupplierMap.put(contract.Id, contract.Supplier__c);
                }
                // Fill the map of contract with BU
                if(!contractBUMap.containsKey(contract.Id)) {
                    contractBUMap.put(contract.Id, contract.Contract_BU__c);
                }
            }
            
            // Get related HE list for all NS
            List<Supplier_NS_HE__c> NSHEList = [SELECT Sup_sup_NegoScope__c, Structure_Element__c, Choice__c, Structure_Element__r.Elt_Code__c,
                                                Structure_Element__r.Level__c, Structure_Element__r.Parent_Element__c
                                                FROM Supplier_NS_HE__c
                                                WHERE Sup_sup_NegoScope__c IN :allNSIdSet];
            Map<Id, WrapperNegoScope> wNegoScopeMap = new Map<Id, WrapperNegoScope>();
            Set<String> parentCodes = new Set<String>();
            List<Orga_HE__c> hes = new List<Orga_HE__c>();
            Boolean includeAllElements = false;
            for(Supplier_NS_HE__c item : NSHEList) {
                if(wNegoScopeMap.containsKey(item.Sup_sup_NegoScope__c)) {
                    wNegoScopeMap.get(item.Sup_sup_NegoScope__c).relatedHEList.add(new WrapperHE(item.Structure_Element__r, item.Choice__c));
                }
                else {
                    WrapperNegoScope wNegoScope = new WrapperNegoScope(item.Sup_sup_NegoScope__c);
                    wNegoScope.relatedHEList.add(new WrapperHE(item.Structure_Element__r, item.Choice__c));
                    wNegoScopeMap.put(item.Sup_sup_NegoScope__c, wNegoScope);
                }
                // TODO: push only one time the parent ex: if push 1 and do not push 10
                if(item.Structure_Element__r.Level__c == 0) {
                    includeAllElements = true;
                }
                else {
                    if(item.Choice__c == 'Include') {
                        String code = item.Structure_Element__r.Elt_Code__c + '%';
                        parentCodes.add(code);
                    }
                }
            }
            
            // Get the sections from their parents codes
            if(includeAllElements) {
                hes = [SELECT Id, Name, Elt_Code__c, Parent_Element__c FROM Orga_HE__c
                       WHERE Dispatch_Inv_Hierarchy_Starting_Point__c = true
                       ORDER BY Elt_Code__c, Parent_Element__c ASC];
            }
            else {
                hes = [SELECT Id, Name, Elt_Code__c, Parent_Element__c FROM Orga_HE__c WHERE Elt_Code__c LIKE :parentCodes
                       AND Dispatch_Inv_Hierarchy_Starting_Point__c = true
                       ORDER BY Elt_Code__c, Parent_Element__c ASC];
            }
            for(WrapperNegoScope item : wNegoScopeMap.values()) {
                item.getRelatedSections(hes);
            }
            
            // Calculate the SUM(Value_per_fact2__c) for the list of conditions grouped
            AggregateResult[] groupedResults = [SELECT SUM(Value_per_fact2__c) rate, Contract__c Contract__c, Product_Scope__c Product_Scope__c,
                                                Nego_Discount_Type__c Nego_Discount_Type__c, Condition_Type__r.Index__c Index__c
                                                FROM Contract_Discount__c
                                                WHERE Id IN :allConditionIdList
                                                GROUP BY Product_Scope__c, Contract__c, Nego_Discount_Type__c, Condition_Type__r.Index__c];
            Decimal rate;
            Map<String, WrapperRow> wRowMap = new Map<String, WrapperRow>();
            for (AggregateResult ar : groupedResults) {
                rate = (Decimal) ar.get('rate');
                // TODO: DO NOT IGNORE IN UPDATE CASE
                if(rate == 0) {
                    ////continue;
                }
                WrapperRow wRow = new WrapperRow((Id) ar.get('Contract__c'), (Id) ar.get('Product_Scope__c'),
                                                 (String) ar.get('Index__c'), (String) ar.get('Nego_Discount_Type__c'));
                wRow.parentNS = negoscopeParentsMap.get(wRow.NSId);
                if(wRowMap.containsKey(wRow.key)) {
                    wRowMap.get(wRow.key).index = wRow.index;
                    wRowMap.get(wRow.key).conditionType = wRow.conditionType;
                    wRowMap.get(wRow.key).setIndexValue(rate);
                }
                else {
                    wRow.setIndexValue(rate);
                    wRowMap.put(wRow.key, wRow);
                }
            }
            for(Contract__c item : contractsWithoutConditions) {
                WrapperRow wRow = new WrapperRow(item.Id, item.Supplier_Nego_Scope__c);
                wRowMap.put(wRow.key, wRow);
            }
            List<GRC_Contract__c> grcContractList = new List<GRC_Contract__c>();
            // Calculate the rates for sub NS
            for(WrapperRow item : wRowMap.values()) {
                if(wRowMap.containsKey(item.parentKey)) {
                    item.indexValue1 += wRowMap.get(item.parentKey).indexValue1;
                    item.indexValue2 += wRowMap.get(item.parentKey).indexValue2;
                    item.indexValue3a += wRowMap.get(item.parentKey).indexValue3a;
                    item.indexValue3b += wRowMap.get(item.parentKey).indexValue3b;
                    item.indexValue4 += wRowMap.get(item.parentKey).indexValue4;
                }
                item.supplierId = contractSupplierMap.get(item.contractId);
                if(wNegoScopeMap.containsKey(item.NSId)) {
                    item.sections = wNegoScopeMap.get(item.NSId).relatedSections;
                }
                grcContractList.addAll(item.mapToGRC());
            }
            
            // Get existing GRC head + their GRC Contracts
            List<GRC__c> grcHeadList = [SELECT Id, GRC_Master_BU__c, GRC_Category__c, GRC_BU__c, GRC_Period_Num__c,
                                        (SELECT Id, GRC__c, NS__c, Contract__c, Orga_HE__c, Supplier__c,
                                         Discount_N__c, Rebates_N__c, Fees_N__c, Others_N__c, Net4_N__c
                                         FROM GRC_Contracts__r
                                         WHERE NS__c IN :allNSIdSet
                                         AND Contract__c IN :contractSupplierMap.keySet()
                                         AND Supplier__c IN :contractSupplierMap.values())
                                        FROM GRC__c
                                        WHERE GRC_Master_BU__c IN :contractBUMap.values()
                                        AND GRC_Period__c = 'Year'];
            // Map GRC Master BU with GRC Id to check if exist for GRC details
            Map<Id, Id> buGRCMap = new Map<Id, Id>();
            // Map GRC Contract to a complex key of NS__c/Contract__c/Orga_HE__c 
            Map<String, GRC_Contract__c> grcContractMap = new Map<String, GRC_Contract__c>();
            for(GRC__c grc : grcHeadList) {
                buGRCMap.put(grc.GRC_Master_BU__c, grc.Id);
                for(GRC_Contract__c item : grc.GRC_Contracts__r) {
                    String key = '' + item.NS__c + item.Contract__c + item.Orga_HE__c;
                    grcContractMap.put(key, item);
                }
            }
                        
            // check security on upsert GRC fields
            String[] grcFields = new String[] { NegoptimHelper.normalizeAPIName('GRC_Master_BU__c'),
                NegoptimHelper.normalizeAPIName('GRC_Category__c'), NegoptimHelper.normalizeAPIName('GRC_BU__c'),
                NegoptimHelper.normalizeAPIName('GRC_Period__c'), NegoptimHelper.normalizeAPIName('GRC_Period_Num__c')};
            
            if(NegoptimHelper.checkCreatibility(GRC__c.SObjectType, grcFields) &&
               NegoptimHelper.checkUpdatibility(GRC__c.SObjectType, grcFields))
            {
                Id rootElement = NegoptimHelper.getRootId();
                // Assign GRC head to the children
                for(GRC_Contract__c item : grcContractList) {
                    if(buGRCMap.containsKey(contractBUMap.get(item.Contract__c))) {
                        item.GRC__c = buGRCMap.get(contractBUMap.get(item.Contract__c));
                    }
                    else {
                        GRC__c grc = new GRC__c(GRC_Master_BU__c = contractBUMap.get(item.Contract__c), GRC_Category__c = rootElement,
                                                GRC_BU__c = null, GRC_Period__c = 'Year', GRC_Period_Num__c = theDate.year());
                        grcHeadList.add(grc);
                        buGRCMap.put(contractBUMap.get(item.Contract__c), null);
                    }
                }
                if(grcHeadList != null && grcHeadList.size() > 0){
                    upsert grcHeadList;
                }
            }
            // List GRC Contracts to upsert
            List<GRC_Contract__c> grcContractToUpsertList = new List<GRC_Contract__c>();
            // TODO: push chidren with non existing head to new list
            String key;
            Boolean isModified;
           
            // check security on update GRC Contract fields
            String[] grcContractFields = new String[] { NegoptimHelper.normalizeAPIName('Discount_N_1__c'),
                NegoptimHelper.normalizeAPIName('Discount_N__c'), NegoptimHelper.normalizeAPIName('Rebates_N_1__c'),
                NegoptimHelper.normalizeAPIName('Rebates_N__c'), NegoptimHelper.normalizeAPIName('Fees_N_1__c'),
                NegoptimHelper.normalizeAPIName('Fees_N__c'), NegoptimHelper.normalizeAPIName('Others_N_1__c'),
                NegoptimHelper.normalizeAPIName('Others_N__c'), NegoptimHelper.normalizeAPIName('Net4_N_1__c'),
                NegoptimHelper.normalizeAPIName('Net4_N__c')};
            // check security on insert GRC Contract fields
            String[] grcContractCreateFields = new String[] { NegoptimHelper.normalizeAPIName('GRC__c')};
            grcContractCreateFields.addAll(grcContractFields);
            
            if(NegoptimHelper.checkCreatibility(GRC_Contract__c.SObjectType, grcContractCreateFields) && 
               NegoptimHelper.checkUpdatibility(GRC_Contract__c.SObjectType, grcContractFields))
            {
                for(GRC_Contract__c item : grcContractList) {
                    isModified = true;
                    key = '' + item.NS__c + item.Contract__c + item.Orga_HE__c;
                    if(grcContractMap.containsKey(key)) {
                        isModified = false;
                        GRC_Contract__c oldGRCContract = grcContractMap.get(key);
                        if(item.Discount_N__c != oldGRCContract.Discount_N__c) {
                            oldGRCContract.Discount_N_1__c = oldGRCContract.Discount_N__c;
                            oldGRCContract.Discount_N__c = item.Discount_N__c;
                            isModified = true;
                        }
                        if(item.Rebates_N__c != oldGRCContract.Rebates_N__c) {
                            oldGRCContract.Rebates_N_1__c = oldGRCContract.Rebates_N__c;
                            oldGRCContract.Rebates_N__c = item.Rebates_N__c;
                            isModified = true;
                        }
                        if(item.Fees_N__c != oldGRCContract.Fees_N__c) {
                            oldGRCContract.Fees_N_1__c = oldGRCContract.Fees_N__c;
                            oldGRCContract.Fees_N__c = item.Fees_N__c;
                            isModified = true;
                        }
                        if(item.Others_N__c != oldGRCContract.Others_N__c) {
                            oldGRCContract.Others_N_1__c = oldGRCContract.Others_N__c;
                            oldGRCContract.Others_N__c = item.Others_N__c;
                            isModified = true;
                        }
                        if(item.Net4_N__c != oldGRCContract.Net4_N__c) {
                            oldGRCContract.Net4_N_1__c = oldGRCContract.Net4_N__c;
                            oldGRCContract.Net4_N__c = item.Net4_N__c;
                            isModified = true;
                        }
                        // Deep clone
                        item = oldGRCContract.clone(true, true, false, false);
                    }
                    if(item.GRC__c == null) {
                        for(GRC__c head : grcHeadList) {
                            if(head.GRC_Master_BU__c == contractBUMap.get(item.Contract__c)) {
                                item.GRC__c = head.Id;
                            }
                        }
                    }
                    if(isModified)
                        grcContractToUpsertList.add(item);
                }
                if(grcContractToUpsertList != null && grcContractToUpsertList.size() > 0){
                    upsert grcContractToUpsertList;
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError(e);
        } catch (Exception e) {
            // Roll everything back in case of error.
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }
    // finish
    public void finish(Database.BatchableContext bc) {
        String countryName = 'N/A';
        try {
            if(country != null)
                countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :country LIMIT 1].Name;
        } catch(DmlException e) {
            nb.logError(e);
        }
        String customSubject = nb.getBatchName() + ' - ' + countryName + '/'+ theDate + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    /* Wrapper class */
    public class WrapperRow {
        public Id contractId {get;set;}
        public Id NSId {get;set;}
        public String index {get;set;}
        public String conditionType {get;set;}
        public Id parentNS {get;set;}
        Decimal indexValue1 {get;set;}
        Decimal indexValue2 {get;set;}
        Decimal indexValue3a {get;set;}
        Decimal indexValue3b {get;set;}
        Decimal indexValue4 {get;set;}
        
        public Id supplierId {get;set;}
        public Set<Id> sections {get;set;}
        
        public String parentKey {
            get {
                return parentNS != null ? contractId + '' + parentNS : null;
            }
            set;
        }
        public String key {
            get {
                return contractId + '' + NSId;
            }
            set;
        }
        public Boolean isNull {
            get {
                return indexValue1 + indexValue2 + indexValue3a + indexValue3b + indexValue4 == 0;
            }
            set;
        }
        public WrapperRow(Id cId, Id ns, String ndx, String cType) {
            this.contractId = cId;
            this.NSId = ns;
            this.index = ndx;
            this.conditionType = cType;
            this.indexValue1 = 0;
            this.indexValue2 = 0;
            this.indexValue3a = 0;
            this.indexValue3b = 0;
            this.indexValue4 = 0;
        }
        public WrapperRow(Id cId, Id ns) {
            this(cId, ns, null, null);
        }
        public void setIndexValue(Decimal rate) {
            if(index == 'Index1') {
                indexValue1 += rate;
            }
            if(index == 'Index2') {
                indexValue2 += rate;
            }
            if(index == 'Index3') {
                if(conditionType != 'Others') {
                    indexValue3a += rate;
                }
                if(conditionType == 'Others') {
                    indexValue3b += rate;
                }
            }
            if(index == 'Index4') {
                indexValue4 += rate;
            }
        }
        // Generate GRC_Contract__c records
        public List<GRC_Contract__c> mapToGRC() {
            List<GRC_Contract__c> grcList = new List<GRC_Contract__c>();
            if(sections != null && sections.size() > 0) {
                for(Id item : sections) {
                    GRC_Contract__c grc = new GRC_Contract__c(NS__c = NSId, Contract__c = contractId, Orga_HE__c = item, Supplier__c = supplierId);
                    grc.Discount_N__c = indexValue1.setScale(2);
                    grc.Rebates_N__c = indexValue2.setScale(2);
                    grc.Fees_N__c = indexValue3a.setScale(2);
                    grc.Others_N__c = indexValue3b.setScale(2);
                    grc.Net4_N__c = indexValue4.setScale(2);
                    grcList.add(grc);
                }
            }
            return grcList;
        }
    }
    /* Wrapper class for NegoScope */
    public class WrapperNegoScope {
        public Id NSId {get;set;}
        public List<WrapperHE> relatedHEList {get;set;}
        public Set<Id> relatedSections {get;set;}
        
        public WrapperNegoScope(Id ns) {
            this.NSId = ns;
            this.relatedHEList = new List<WrapperHE>();
            this.relatedSections = new Set<Id>();
        }
        
        public void getRelatedSections(List<Orga_HE__c> availableSections) {
            List<Id> sectionIds = new List<Id>();
            // if the root is included => push all
            if(relatedHEList.size() == 1 && relatedHEList.get(0).he.Parent_Element__c == null && relatedHEList.get(0).isIncluded) {
                for(Orga_HE__c item : availableSections) {
                    relatedSections.add(item.Id);
                }
            }
            else {
                for(WrapperHE item : relatedHEList) {
                    for(Orga_HE__c section : availableSections) {
                        if(section.Elt_Code__c.startsWith(item.he.Elt_Code__c)) {
                            item.children.add(section.Id);
                        }
                    }
                    // add included sections
                    if(item.isIncluded) {
                        relatedSections.addAll(item.children);
                    }
                }
                // remove excluded sections
                for(WrapperHE item : relatedHEList) {
                    if(!item.isIncluded) {
                        relatedSections.removeAll(item.children);
                    }
                }
            }
        }
    }    
    /* Wrapper class for HE */
    public class WrapperHE {
        public Orga_HE__c he {get;set;}
        public String choice {get;set;}
        public List<Id> children {get;set;}
        public Boolean isIncluded {
            get {
                if(choice == 'Include')
                    return true;
                return false;
            }
            set;
        }
        
        public WrapperHE(Orga_HE__c h, String c) {
            this.he = h;
            this.choice = c;
            this.children = new List<Id>();
        }
    }
}