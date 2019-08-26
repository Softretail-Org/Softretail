/**
 * Batchable class used to synchronize contract group with contract.
 **/
public with sharing class GroupContractSynchroBatch implements Database.Batchable<sObject>, Database.stateful {
    
    private NegoptimBatch nb;
    public final String query;
    public String originBUCode;
    public final Id country;
    private Set<Id> cIds;
    private Set<Id> BUIds;
    private Date now;
    private final Boolean doInvoiceGroupScan;
    // case call generateGRC batch on delete contracts
    private Set<Id> contractDeletedSet;
    // case call generateGRC batch on update NS contracts
    private Set<Id> contractUpdatedNSSet;
    
    // Constructor.
    public GroupContractSynchroBatch(String startedFrom, Boolean doScan, List<Id> ids, String groupBUCode) {
        
        this.nb = new NegoptimBatch('GroupContractSynchroBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        // Creation of cIds.
        cIds = new Set<Id>();
        BUIds = new Set<Id>();
        originBUCode = groupBUCode;
        now = date.newinstance(System.now().year(), System.now().month(), System.now().day());
        doInvoiceGroupScan = doScan;
        this.contractDeletedSet = new Set<Id>();
        this.contractUpdatedNSSet = new Set<Id>();
        
        // Declare the query to get contracts.
        String q = 'SELECT Id, Name, Origin_BU__c, Status__c, Supplier__c, Supplier_NegoScope__c, Contract_Number__c, Last_synchro_date__c,';
        q += ' contract_linked__c, Contract_type__c, Start_Date__c, End_date__c, Contract_Year__c, Comment__c,';
        q += ' Supplier__r.Name, Supplier__r.Country_origin__c, Negotiated_TO__c, Contract_Reference_Number__c, Stock_Owner__c,';
        q += ' (Select Id, Name, condition_linked__c, Condition_name__c, Disc_BDate__c, Disc_EDate__c,';
        q += ' Percent__c, Amount__c, Rank__c, Comment__c, Nego_Discount_Type__c, Status__c, Origin_Disc_name__c';
        q += ' FROM Group_Contract_Details__r';
        q += ' WHERE Status__c = \'Validated\' OR Status__c = \'Synchronized\' OR Status__c = \'Deleted\' OR Status__c = \'Synchronized as deleted\')';
        q += ' FROM Contract_Group__c';
        q += ' WHERE (Status__c = \'Validated\' OR Status__c = \'Deleted\' OR Status__c = \'Synchronized as deleted\')';
        q += ' AND Temp_Exclusion__c = False';
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\')';
        }
        if(String.isNotBlank(originBUCode)) {
            q += ' AND Origin_BU__c = \'' + originBUCode + '\'';
        }
        query = q;
        // push inputs to log
        nb.logParameter('startedFrom', startedFrom);
        nb.logParameter('doInvoiceGroupScan', this.doInvoiceGroupScan);
        nb.logParameter('originBUCode', this.originBUCode);
        nb.logParameter('contractGroupIds', ids);
        nb.logParameter('query', this.query);
    }
    
    // Start method implementation.
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    // Execute method implementation.
    public void execute(Database.BatchableContext BC, List<Contract_Group__c> scope) {
        // <code origin, cG Id>
        Set<String> codeBUSet = new Set<String>();
        WrapperGC wGC;
        WrapperGCD wGCD1;
        List<WrapperGC> wGCs = new List<WrapperGC>();
        List<WrapperGCD> wGCDs;
        // Fill the contract group wrapper: Contract Group and List of Contract Group Detail Wrapper.
        for (Contract_Group__c cG : scope) {
            wGC = new WrapperGC();
            wGC.cG = cG;
            wGCDs = new List<WrapperGCD>();
            if (!codeBUSet.contains(cG.Origin_BU__c)) {
                codeBUSet.add(cG.Origin_BU__c);
            }
            // Check if the current contract group has one or more contract group detail.
            if (cG.Group_Contract_Details__r.size() > 0) {
                wGC.haveGCD = True;
                for (Contract_Group_Detail__c cGD : cG.Group_Contract_Details__r) {
                    wGCD1 = new WrapperGCD();
                    wGCD1.cGD = cGD;
                    wGCDs.add(wGCD1);
                }
            } else {
                wGC.haveGCD = False;
            }
            wGC.wGCDs = wGCDs;
            wGCs.add(wGC);
        }
        // <BU code, BU Id>
        Map<String, Id> BUMap = new Map<String, Id>();
        for (Orga_BU__c item : [SELECT Id, BU_Code__c FROM Orga_BU__c WHERE BU_Code__c IN :codeBUSet]) {
            BUMap.put(item.BU_Code__c, item.Id);
            if (item.Id != Null) {
                BUIds.add(item.Id);
            }
        }
        // Used for Contract Group and Contract Group Detail level.
        List<Id> cLinkedValues;
        // Creation of the linked values list on Contract Group level.
        cLinkedValues = new List<Id>();
        // <Contract_Reference_Number__c, String>
        Map<String, Contract__c> cRefNumberMap = new Map<String, Contract__c>();
        for (WrapperGC wItem : wGCs) {
            if(BUMap.containsKey(wItem.cG.Origin_BU__c)) {
                wItem.origin = BUMap.get(wItem.cG.Origin_BU__c);
            } else {
                wItem.errors.add('Group not found. ' + wItem.cG.Origin_BU__c);
                this.nb.logError('Group not found. ' + wItem.cG.Origin_BU__c);
                wItem.isValid = False;
                continue;
            }
            if (wItem.cG.contract_linked__c != Null) {
                // CaseA: contract group is linked => Select the corresponding Contract.
                wItem.isLinked = True;
                if (NegoptimHelper.validateId(wItem.cG.contract_linked__c)) {
                    wItem.isValid = True;
                    cLinkedValues.add(Id.valueOf(wItem.cG.contract_linked__c));
                } else {
                    wItem.isValid = False;
                    wItem.errors.add('Invalid Contract Id.');
                    this.nb.logError('Invalid Contract Id.');
                }
            } else if (wItem.cG.contract_linked__c == null) {
                // CaseB: contract group is not linked => Create a contract based on Contract Group criteria.
                wItem.isLinked = False;
                wItem.isValid = True;
                Contract__c c = new Contract__c(Name = wItem.cG.Name, Contract_Numbder__c = wItem.cG.Contract_Number__c,
                                                Total_TO_Ref__c = wItem.cG.Negotiated_TO__c, Comment__c = wItem.cG.Comment__c,
                                                Contract_BDate__c = wItem.cG.Start_Date__c, Contract_EDate__c = wItem.cG.End_date__c, 
                                                Contract_BU__c = wItem.origin, Contract_Type__c = 'Contract',
                                                TO1__c = wItem.cG.Negotiated_TO__c, Status_Bdate__c = System.now(),
                                                Supplier__c = wItem.cG.Supplier__c, Supplier_Nego_Scope__c = wItem.cG.Supplier_NegoScope__c,
                                                Status__c = 'Signed', tactite_reconduction__c = True,
                                                Linked_contract_group__c = wItem.cG.Id, Integration_date_last__c = System.now(),
                                                Stock_Owner__c = wItem.cG.Stock_Owner__c);    
                c.Duration__c = c.Contract_EDate__c.month() - c.Contract_BDate__c.month() + 1;
                cRefNumberMap.put(wItem.cG.Contract_Reference_Number__c, c);
                if (wItem.cG.contract_type__c == 'Prorogation') {
                    c.D_N__c = 'D';
                } else if (wItem.cG.contract_type__c == 'Contract') {
                    c.D_N__c = 'N';
                }
                if (wItem.cG.Status__c == 'Deleted' || wItem.cG.Status__c == 'Synchronized as deleted') {
                    c.status__c = 'Deleted';                    
                }
                wItem.c = c;
            }
        }
        // This block is only based on the CaseA.
        if (cLinkedValues.size() > 0) {
            // Select the corresponding contracts based on the conract group linked values.
            Map<Id, Contract__c> cMap = new Map<Id, Contract__c>([SELECT Id, Name, Reference_year__c, Contract_Numbder__c, Total_TO_Ref__c, TO1__c, Comment__c,
                                                                  Contract_BDate__c, Contract_EDate__c, Contract_BU__c, Contract_Type__c,
                                                                  Supplier__c, Supplier_Nego_Scope__c, Status__c, Last_Active_Contract__c,
                                                                  Tactite_reconduction__c, Linked_contract_group__c, Integration_date_last__c, Integration_id_last__c,
                                                                  Parent_contract__c, D_N__c, Status_Bdate__c, Stock_Owner__c
                                                                  FROM Contract__c WHERE Id IN :cLinkedValues]);
            // Fill the Contract Group Wrapper: Contract.
            for (WrapperGC wItem : wGCs) {
                if (wItem.isLinked && wItem.isValid) {
                    Contract__c c = cMap.get(wItem.cG.Contract_Linked__c);
                    if (c != null) {
                        c.Name = wItem.cG.Name;
                        c.Contract_Numbder__c = wItem.cG.Contract_Number__c;
                        if (c.TO1__c == c.Total_TO_Ref__c) {
                            c.TO1__c = wItem.cG.Negotiated_TO__c;
                            c.Total_TO_Ref__c = wItem.cG.Negotiated_TO__c;
                        } else {
                            c.Total_TO_Ref__c = wItem.cG.Negotiated_TO__c;
                        }
                        c.Comment__c = wItem.cG.Comment__c;
                        c.Contract_BDate__c = wItem.cG.Start_Date__c;
                        c.Contract_EDate__c = wItem.cG.End_date__c;
                        c.Duration__c = c.Contract_EDate__c.month() - c.Contract_BDate__c.month() + 1;
                        c.Contract_BU__c = wItem.origin;
                        c.Contract_Type__c = 'Contract';
                        c.Supplier__c = wItem.cG.Supplier__c;
                        c.Stock_Owner__c = wItem.cG.Stock_Owner__c;
                        // check if NS updated
                        if(c.Supplier_Nego_Scope__c != null && c.Supplier_Nego_Scope__c != wItem.cG.Supplier_NegoScope__c){
                            this.contractUpdatedNSSet.add(c.Id);
                        }
                        c.Supplier_Nego_Scope__c = wItem.cG.Supplier_NegoScope__c;                        
                        // Status changed from validated to deleted.
                        if (c.Status__c != wItem.cG.Status__c) {
                            c.Status_Bdate__c = System.now();
                        }
                        c.Status__c = 'Signed';
                        c.Tactite_reconduction__c = True;
                        c.Linked_contract_group__c = wItem.cG.Id;
                        c.Integration_date_last__c = System.now();
                        if (wItem.cG.contract_type__c == 'Prorogation') {
                            c.D_N__c = 'D';
                        } else if (wItem.cG.contract_type__c == 'Contract') {
                            c.D_N__c = 'N';
                        }
                        if (wItem.cG.Status__c == 'Deleted' || wItem.cG.Status__c == 'Synchronized as deleted') {
                            c.status__c = 'Deleted';
                            this.contractDeletedSet.add(c.Id);
                        }
                        wItem.c = c;
                	}
                    else {
	                    // There is no contract having an Id equal to the contract linked value of the current contract group. => Nothing to do.
	                    wItem.errors.add('Contract not found.');
	                    this.nb.logError('Contract not found.');
	                    wItem.isValid = False;
                	}
            	}
        	}
    	}
        Map<String, String> mapNumberToLinked = new Map<String, String>();
        for (Contract_Group__c item : [SELECT Contract_Number__c, contract_linked__c
                                       FROM Contract_Group__c
                                       WHERE Status__c <> 'Rejected']) {
                                           mapNumberToLinked.put(item.Contract_Number__c, item.contract_linked__c);
                                       }
        // reference.
        for (Contract_Group__c cG : [SELECT Contract_Reference_Number__c
                                     FROM Contract_Group__c
                                     WHERE Contract_Reference_Number__c IN : cRefNumberMap.keySet()]) {
                                         Contract__c c = cRefNumberMap.get(cG.Contract_Reference_Number__c);
                                         if (c != Null) {
                                             c.Parent_contract__c = mapNumberToLinked.get(cG.Contract_Reference_Number__c);
                                         }
                                     }
        // UPSERT the contracts.
        List<Contract__c> contracts = new List<Contract__c>();
        for (WrapperGC wItem : wGCs) {
            if (wItem.c != Null) {
                contracts.add(wItem.c);
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            
            // check security on update contract group fields
            String[] contractGroupUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Last_synchro_date__c'), NegoptimHelper.normalizeAPIName('Contract_linked__c')};                        
            
            // check security on update condition fields
            String[] conditionUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Condition_Linked__c'), NegoptimHelper.normalizeAPIName('Last_Synchro_Date__c')};
            
            // check security on update contract fields
            String[] contractFields = new String[] { 'Name', NegoptimHelper.normalizeAPIName('Contract_Numbder__c'),
                NegoptimHelper.normalizeAPIName('TO1__c'), NegoptimHelper.normalizeAPIName('Total_TO_Ref__c'),
                NegoptimHelper.normalizeAPIName('Comment__c'), NegoptimHelper.normalizeAPIName('Contract_BDate__c'),
                NegoptimHelper.normalizeAPIName('Contract_EDate__c'), NegoptimHelper.normalizeAPIName('Duration__c'),
                NegoptimHelper.normalizeAPIName('Contract_BU__c'), NegoptimHelper.normalizeAPIName('Contract_Type__c'),
                NegoptimHelper.normalizeAPIName('Supplier__c'), NegoptimHelper.normalizeAPIName('Supplier_Nego_Scope__c'),
                NegoptimHelper.normalizeAPIName('Status_Bdate__c'), NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Tactite_reconduction__c'), NegoptimHelper.normalizeAPIName('Linked_contract_group__c'),
                NegoptimHelper.normalizeAPIName('Integration_date_last__c'), NegoptimHelper.normalizeAPIName('D_N__c'),
                NegoptimHelper.normalizeAPIName('Stock_Owner__c')};

            String[] contractIssueCreateFields = new String[] { NegoptimHelper.normalizeAPIName('Contract_group__c'),
                NegoptimHelper.normalizeAPIName('Condition_line__c'), NegoptimHelper.normalizeAPIName('Issue_Type__c'),
                NegoptimHelper.normalizeAPIName('Reject_Cause__c'), NegoptimHelper.normalizeAPIName('Reject_Detail__c')};

            if(NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractFields)){
                List<Database.UpsertResult> results = Database.upsert(contracts, false);
                for (WrapperGC wItem : wGCs) {
                    for (Integer i = 0; i < contracts.size(); i++) {
                        Database.UpsertResult res = results[i];
                        if (wItem.c != Null) {
                            if (wItem.c.Id == contracts[i].Id) {
                                if (!res.isSuccess()) {
                                    wItem.isValid = False;
                                    for (Database.Error err : res.getErrors()) {
                                        wItem.errors.add('Exception: ' + err.getMessage());
                                        this.nb.logError('Exception: ' + err.getMessage());
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Creation of the linked values list on Contract Group Detail level.
            cLinkedValues = new List<Id>();
            // Fill the Contract Group Wrapper: List of Contract Group Detail Wrapper.
            for (WrapperGC wItem : wGCs) {
                if (!wItem.isValid) {
                    for (WrapperGCD wGCD : wItem.wGCDs) {
                        if (wGCD.cGD.condition_linked__c != Null) {
                            wGCD.isLinked = True;
                            if (NegoptimHelper.validateId(wGCD.cGD.condition_linked__c)) {
                                wGCD.isValid = True;
                                cLinkedValues.add(wGCD.cGD.condition_linked__c);
                            } else {
                                wGCD.isValid = False;
                                wGCD.errors.add('Invalid Condition Id.');
                                this.nb.logError('Invalid Condition Id.');
                            }
                        }
                    }
                }
                // (contract group linked AND contract Id valid) OR contract group not linked
                if ((wItem.isLinked && wItem.isValid && wItem.haveGCD)
                    || (!wItem.isLinked && wItem.haveGCD)) {
                    for (WrapperGCD wGCD : wItem.wGCDs) {
                        if (wGCD.cGD.condition_linked__c != Null) {
                            wGCD.isLinked = True;
                            if (NegoptimHelper.validateId(wGCD.cGD.condition_linked__c)) {
                                wGCD.isValid = True;
                                cLinkedValues.add(wGCD.cGD.condition_linked__c);
                            } else {
                                wGCD.isValid = False;
                                wGCD.errors.add('Invalid Condition Id.');
                                this.nb.logError('Invalid Condition Id.');
                            }
                        } else if (wGCD.cGD.condition_linked__c == Null) {
                            // CaseA2: Contract Group is linked + current Contract Group Detail is not linked.
                            // => Create a Condition based on Contract Group Detail criteria for the existing Contract. (for each iteration)
                            wGCD.isLinked = False;
                            wGCD.isValid = True;
                        }
                    }
                }
                // contract group linked + contract Id invalid
                else if (wItem.isLinked && !wItem.isValid) {
                    //break;
                }
                // contract group not linked
                else if (!wItem.isLinked) {
                    // c'est pas logique d'avoir un contract group not linked aved des details linked. <<< TODO.
                }
            }
            Map<Id, Contract_Discount__c> cMap;
            // This block is only based on the CaseA1.
            if (cLinkedValues.size() > 0) {
                // Select the corresponding conditions based on the Contract Group Detail linked values.
                cMap = new Map<Id, Contract_Discount__c>();
                for (Contract_Discount__c c : [SELECT Id, Commercial_reference__c, Contract_group_reference__c,
                                               Name, Condition_Type__c, Disc_BDate__c, Disc_EDate__c, Product_Scope__c,
                                               BU_Scope__c, Contract__c, Value_per__c, Value_amt__c, Rank__c, comments__c, 
                                               Nego_discount_type__c, Status__c, Status_Bdate__c, Reference_condition__c,
                                               Linked_Condition_Group__c, Provision_base__c, Provision_period__c, Invoice_period__c,
                                               Invoice_base__c
                                               FROM Contract_Discount__c
                                               WHERE Id IN : cLinkedValues]) {
                                                   cMap.put(c.Id, c);
                                               }
            }
            List<WrapperGCD> wDetails1;
            for (WrapperGC wItem : wGCs) {
                wDetails1 = new List<WrapperGCD>();
                for (WrapperGCD wGCD : wItem.wGCDs) {
                    // (contract group is linked + valid + have details OR not linked + have details) AND details is linked + valid.
                    if (((wItem.isLinked && wItem.isValid && wItem.haveGCD) || (!wItem.isLinked && wItem.haveGCD)) && (wGCD.isLinked && wGCD.isValid)) {
                        // Update.
                        Contract_Discount__c cond = cMap.get(wGCD.cGD.Condition_Linked__c);
                        if (cond != Null) {
                            if (wGCD.cGD.Condition_Linked__c == cond.Id) {
                                // check if condition group is Synchronized and NS for contract group is updated
                                if(wGCD.cGD.Status__c == 'Synchronized' && cond.Product_Scope__c == wItem.c.Supplier_Nego_Scope__c) continue;
                                
                                cond.Commercial_reference__c = wGCD.cGD.Origin_Disc_name__c;
                                cond.Value_per__c = wGCD.cGD.Percent__c;
                                cond.Value_amt__c = wGCD.cGD.Amount__c;
                                cond.Disc_BDate__c = wGCD.cGD.Disc_BDate__c;
                                cond.Disc_EDate__c = wGCD.cGD.Disc_EDate__c;
                                cond.Rank__c = wGCD.cGD.Rank__c;
                                cond.comments__c = wGCD.cGD.Comment__c;
                                cond.Nego_discount_type__c = wGCD.cGD.Nego_Discount_Type__c;
                                cond.Condition_Type__c = wGCD.cGD.Condition_name__c;
                                cond.Status_Bdate__c = now;
                                cond.Reference_condition__c = Null;
                                cond.Contract_group_reference__c = wItem.cG.Id;
                                cond.BU_Scope__c = wItem.c.Contract_BU__c;
                                cond.Product_Scope__c = wItem.c.Supplier_Nego_Scope__c;
                                cond.Integration_date_last__c = System.now();
                                cond.Provision_base__c = Null;
                                cond.Invoice_base__c = Null;
                                cond.Provision_period__c = 'Month';
                                cond.Invoice_period__c = 'Month';
                                cond.Linked_Condition_Group__c = wGCD.cGD.Id;                       
                                if (wGCD.cGD.Status__c == 'Validated') {
                                    cond.Status__c = 'Signed';
                                } else if (wGCD.cGD.Status__c == 'Deleted' || wGCD.cGD.Status__c == 'Synchronized as deleted') {
                                    cond.Status__c = 'Deleted';
                                    cond.value_per__c = 0;
                                    cond.Value_amt__c = 0;
                                    /*if (!cIds.contains(wItem.c.Id)) {
                                        cIds.add(wItem.c.Id);
                                    }*/
                                }
                                wGCD.cD = cond;
                                wDetails1.add(wGCD);
                            }
                        } else {
                            // Contract group not linked + details linked.
                            if (wItem.c != Null) {
                                Contract_Discount__c condition = new Contract_Discount__c(
                                            Commercial_reference__c = wGCD.cGD.Origin_Disc_name__c, Value_per__c = wGCD.cGD.Percent__c,
                                            Value_amt__c = wGCD.cGD.Amount__c, Disc_BDate__c = wGCD.cGD.Disc_BDate__c,
                                            Disc_EDate__c = wGCD.cGD.Disc_EDate__c, Rank__c = wGCD.cGD.Rank__c, comments__c = wGCD.cGD.Comment__c,
                                            Nego_discount_type__c = wGCD.cGD.Nego_Discount_Type__c, Condition_Type__c = wGCD.cGD.Condition_name__c,
                                            Status_Bdate__c = now, Reference_condition__c = Null,
                                            Contract_group_reference__c = wItem.cG.Id, BU_Scope__c = wItem.c.Contract_BU__c,
                                            Product_Scope__c = wItem.c.Supplier_Nego_Scope__c, Integration_date_last__c = System.now(),
                                            //Integration_id_last__c
                                            Provision_base__c = Null, Invoice_base__c = Null, Provision_period__c = 'Month', Invoice_period__c = 'Month',
                                            Contract__c = wItem.c.Id, Linked_Condition_Group__c = wGCD.cGD.Id);
                                if (wGCD.cGD.Status__c == 'Validated') {
                                    condition.Status__c = 'Signed';
                                } else if (wGCD.cGD.Status__c == 'Deleted' || wGCD.cGD.Status__c == 'Synchronized as deleted') {
                                    condition.Status__c = 'Deleted';
                                    condition.value_per__c = 0;
                                    condition.Value_amt__c = 0;
                                    /*if (!cIds.contains(wItem.c.Id)) {
                                        cIds.add(wItem.c.Id);
                                    }*/
                                }
                                wGCD.cD = condition;
                                wDetails1.add(wGCD);
                            }
                        }
                    } else if (((wItem.isLinked && wItem.isValid && wItem.haveGCD) || (!wItem.isLinked && wItem.haveGCD)) && (wGCD.isLinked && !wGCD.isValid)) {
                    	// (contract group is linked + valid + have details || (contract group not linked + have details)) AND details linked + not valid.
                    } else if (((wItem.isLinked && wItem.isValid && wItem.haveGCD) || (!wItem.isLinked && wItem.haveGCD)) && !wGCD.isLinked) {
                    	// (contract group is linked + valid + have details || contract not linked + have details) AND details not linked.
                        // Create condition for the existing contract.
                        if (wItem.c != Null) {
                        	if (wItem.c.Id != Null) {
                        		Contract_Discount__c condition = new Contract_Discount__c(
                                            Commercial_reference__c = wGCD.cGD.Origin_Disc_name__c, Value_per__c = wGCD.cGD.Percent__c,
                                            Value_amt__c = wGCD.cGD.Amount__c, Disc_BDate__c = wGCD.cGD.Disc_BDate__c,
                                            Disc_EDate__c = wGCD.cGD.Disc_EDate__c, Rank__c = wGCD.cGD.Rank__c, comments__c = wGCD.cGD.Comment__c,
                                            Nego_discount_type__c = wGCD.cGD.Nego_Discount_Type__c, Condition_Type__c = wGCD.cGD.Condition_name__c,
                                            Status_Bdate__c = now, Reference_condition__c = Null,
                                            Contract_group_reference__c = wItem.cG.Id, BU_Scope__c = wItem.c.Contract_BU__c,
                                            Product_Scope__c = wItem.c.Supplier_Nego_Scope__c, Integration_date_last__c = System.now(),
                                            Provision_base__c = Null, Invoice_base__c = Null, Provision_period__c = 'Month', Invoice_period__c = 'Month',
                                            Contract__c = wItem.c.Id, Linked_Condition_Group__c = wGCD.cGD.Id);
	                            if (wGCD.cGD.Status__c == 'Validated') {
	                                condition.Status__c = 'Signed';
	                            } else if (wGCD.cGD.Status__c == 'Deleted' || wGCD.cGD.Status__c == 'Synchronized as deleted') {
	                                condition.Status__c = 'Deleted';
                                    condition.value_per__c = 0;
                                    condition.Value_amt__c = 0;
	                                /*if (!cIds.contains(wItem.c.Id)) {
	                                    cIds.add(wItem.c.Id);
	                                }*/
	                            }
	                            wGCD.cD = condition;
	                            wDetails1.add(wGCD);
                        	} else {
                        		wGCD.isValid = False;
                                wGCD.errors.add('Linked contract of the reference contract not found.');
                                this.nb.logError('Linked contract of the reference contract not found.');
                        	}
                        }
                    } else if (wItem.isLinked && !wItem.isValid && wItem.haveGCD && !wGCD.isValid) {
                    	// contract group is linked + invalid + have details AND (detail linked + invalid)
                        wDetails1 = wItem.wGCDs;
                    }
                }
                wItem.wGCDs = wDetails1;
            }
            // Upsert the conditions.
            List<Contract_Discount__c> conditions = new List<Contract_Discount__c>();
            for (WrapperGC wItem : wGCs) {
                for (WrapperGCD w : wItem.wGCDs) {
                    if (w.cD != Null) {
                        conditions.add(w.cD);
                    }
                }
            }
            if (conditions != Null && conditions.size() > 0) {
                upsert conditions;
            }
            // Maps creation used to fill fields on Contract Group and Contract Group Detail.
            Map<Contract__c, Contract_Group__c> cGMap = new Map<Contract__c, Contract_Group__c>();
            Map<Contract_Discount__c, Contract_Group_Detail__c> cGDMap = new Map<Contract_Discount__c, Contract_Group_Detail__c>();
            // Update contract linked and last sync date fields.
            List<Contract_Group__c> l1 = new List<Contract_Group__c>();
            List<Contract_Group_Detail__c> l2 = new List<Contract_Group_Detail__c>();
            // Mapping.
            for (WrapperGC wItem1 : wGCs) {
                cGMap.put(wItem1.c, wItem1.cG);
                Contract_Group_Issue__c cGIssue;
                if (!wItem1.isValid) {
                    wItem1.cG.status__c = 'Error during synchro';
                    l1.add(wItem1.cG);
                    cGIssue = new Contract_Group_Issue__c(Contract_group__c = wItem1.cG.Id, Issue_Type__c = 'ERR', Support_By__c = UserInfo.getUserId());
                    for (String err : wItem1.errors) {
                    	cGIssue.Reject_Detail__c += err + '\n';
                    }
                }
                for (WrapperGCD wItem2 : wItem1.wGCDs) {
                    cGDMap.put(wItem2.cD, wItem2.cGD);
                    if (!wItem2.isValid) {
                        wItem2.cGD.status__c = 'Error during synchro';
                        l2.add(wItem2.cGD);
                        if (cGIssue != Null) {
                        	cGIssue.Condition_line__c = wItem2.cGD.Id;
                        } else {
                        	cGIssue = new Contract_Group_Issue__c(Contract_group__c = wItem1.cG.Id, Issue_Type__c = 'ERR', Support_By__c = UserInfo.getUserId());
                        	for (String err : wItem2.errors) {
		                    	cGIssue.Reject_Detail__c += err + '\n';
		                    }
                        }
                    }
                }                
                if (cGIssue != Null) {
                    if(NegoptimHelper.checkCreatibility(Contract_Group_Issue__c.SObjectType, contractIssueCreateFields)) {
                        Database.insert(cGIssue, false);
                    }
                }
            }
            // Update status.
            update l1;
            update l2;
            
            if (NegoptimHelper.checkUpdatibility(Contract_Group__c.SObjectType, contractGroupUpdateFields) && 
                NegoptimHelper.checkUpdatibility(Contract_Group_Detail__c.SObjectType, conditionUpdateFields) &&
                contracts.size() > 0) {
                // Update contract linked and last sync date fields.
                List<Contract_Group__c> cGsToUpdate = new List<Contract_Group__c>();
                List<Contract__c> contractListToLock = new List<Contract__c>();
                for (Contract__c c : cGMap.keySet()) {
                    if (c != Null) {
                        Contract_Group__c item  = cGMap.get(c);
                        if (item != Null) {
                            if (item.Status__c == 'Deleted') {
                                item.Status__c = 'Synchronized as deleted';
                                item.Last_synchro_date__c = System.now();
                                item.Contract_linked__c = c.Id;
                                cGsToUpdate.add(item);
                            }
                            if (item.status__c != 'Error during synchro' && item.status__c != 'Synchronized as deleted') {
                                item.Status__c = 'Synchronized';
                                item.Last_synchro_date__c = System.now();
                                item.Contract_linked__c = c.Id;
                                cGsToUpdate.add(item);
                                contractListToLock.add(c);
                            }
                        }
                    }
                }
                if (cGsToUpdate.size() > 0) {
                    update cGsToUpdate;
                    if (contractListToLock.size() > 0) {
                        // Lock the contracts.
                        Approval.LockResult[] lrList = Approval.lock(contractListToLock, false);
                        // Iterate through each returned result.
                        for(Approval.LockResult lr : lrList) {
                            if (lr.isSuccess()) {
                                // Operation was successful.
                            } else {
                                // Operation failed.               
                                for(Database.Error err : lr.getErrors()) {
                                    this.nb.logError('Contract not locked. ' + err.getStatusCode() + ': ' + err.getMessage() + ' - Contract fields that affected this error: ' + err.getFields());
                                }
                            }
                        }
                    }
                }
                
                // Update condition linked and last sync date fields.
                List<Contract_Group_Detail__c> cGDsToUpdate = new List<Contract_Group_Detail__c>();
                // Map<Contract Discount, Group Contract Detail>
                Map<Id, Contract_Group_Detail__c> cGD2Map = new Map<Id, Contract_Group_Detail__c>();
                List<Contract_Discount__c> contractDiscountListToLock = new List<Contract_Discount__c>();
                
                for (Contract_Discount__c c : cGDMap.keySet()) {
                    if (c != Null) {
                        Contract_Group_Detail__c item  = cGDMap.get(c);
                        if (item.Status__c == 'Deleted') {
                            item.Status__c = 'Synchronized as deleted';
                            item.Condition_Linked__c = c.Id;
                            item.Last_Synchro_Date__c = system.now();
                            cGDsToUpdate.add(item);
                        }
                        if (item.status__c != 'Error during synchro' && item.status__c != 'Synchronized as deleted') {
                            item.Condition_Linked__c = c.Id;
                            item.Last_Synchro_Date__c = system.now();
                            item.Status__c = 'Synchronized';
                            cGDsToUpdate.add(item);
                            contractDiscountListToLock.add(c);
                        }
                    }
                }
                if (cGDsToUpdate.size() > 0) {
                    update cGDsToUpdate;
                    if(contractDiscountListToLock.size() > 0) {
                        Approval.LockResult[] lrList = Approval.lock(contractDiscountListToLock, false);
                        // Iterate through each returned result.
                        for(Approval.LockResult lr : lrList) {
                            if (lr.isSuccess()) {
                                // Operation was successful.
                            } else {
                                // Operation failed.               
                                for(Database.Error err : lr.getErrors()) {
                                    this.nb.logError('Condition not locked. ' + err.getStatusCode() + ': ' + err.getMessage() + ' - Condition fields that affected this error: ' + err.getFields());
                                }
                            }
                        }
                    }
                }
            }
        } catch (DmlException e) {            
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch (Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    
    // Finish method implementation.
    public void finish(Database.BatchableContext BC) {
        if(doInvoiceGroupScan) {
            Database.executeBatch(new GroupInvoiceScanBatch('GroupContractSynchroBatch', doInvoiceGroupScan, null, null));
        }
        if(this.contractDeletedSet.size() > 0 || this.contractUpdatedNSSet.size() > 0) {
            List<Id> contractIds = new List<Id>();
            if(this.contractDeletedSet.size() > 0) contractIds.addAll(new List<Id>(contractDeletedSet));
            if(this.contractUpdatedNSSet.size() > 0) contractIds.addAll(new List<Id>(contractUpdatedNSSet));            
            Database.executeBatch(new GenerateGRCRatesBatch('GroupContractSynchroBatch', null, contractIds, null, null));
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
        
        // Execute Generate Invoices Batch.
        /*if (cIds.size() > 0) {
            for (Id BUId : BUIds) {
                Database.executeBatch(new GenerateInvoicesBatch(BUId, new List<Id>(cIds), Date.today()));
            }
        }*/
    }
    
    private class WrapperGC {        
        private Contract_Group__c cG;
        private Contract__c c;
        private Boolean isLinked;
        private List<WrapperGCD> wGCDs;
        private Boolean haveGCD;
        private Boolean isValid;
        private Id origin;
        private Set<String> errors;
        
        private WrapperGC () {
            wGCDs = new List<WrapperGCD>();
            errors = new Set<String>();
            isLinked = False;
            haveGCD = False;
            isValid = False;
        }
    }
    
    private class WrapperGCD {
        
        private Contract_Group_Detail__c cGD;
        private Contract_Discount__c cD;
        private Boolean isLinked;
        private Boolean isValid;
        private Set<String> errors;
        
        private WrapperGCD () {
        	errors = new Set<String>();
            isLinked = False;
            isValid = False;
        }
    }
}