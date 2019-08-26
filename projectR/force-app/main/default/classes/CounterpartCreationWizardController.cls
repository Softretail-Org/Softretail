/**
* @author ULiT
* @date 26-feb-2019
* @description 
* page link parameters:
* - sid: supplier Id
* - nsid: nego scope Id
* - cid: contract Id
* - cdid: contract discount Id
*/
public with sharing class CounterpartCreationWizardController extends NegoptimBaseController {
    
    private Date startDate; // used to reference in contract query only
    private ApexPages.StandardController stdCtrl; // used for cancel
    
    public Id supplierId {get; set;}
    public Id negoscopeId {get; set;}
    public Id contractId {get; set;}
    public Id conditionId {get; set;}
    public Id redirectId {get; set;}
    public Boolean startedFromSupplier {get; set;}
    public Boolean startedFromNegoscope {get; set;}
    public Boolean startedFromContract {get; set;}
    public Boolean startedFromCondition {get; set;}
    
    public String supplierName {get; set;}
    public String supplierCode {get; set;}
    
    public String negoscopeCode {get; set;}
    
    public String currencyIsoCode {get; set;}
    
    public Integer step {get; set;}
    public String stepTitle {get {return stepsMap.get(this.step);} set;}
    
    public Contract__c contract {get; set;}
    public Contract_Discount__c contractDiscount {get; set;}
    public Boolean editMode {get; set;}
    
    public Boolean showNextButton {
        get {
            return this.step > 1 && this.step < 4 && !this.noNS;
        }
        set;}
    public Boolean showPreviousButton {get; set;}
    public Boolean showContractList {get; set;}
    public Boolean showNSForm {get; set;}
    public Boolean showContractDiscountList {get; set;}
    
    public Boolean skipContractSelection {get; set;}
    public Boolean noNS {get; set;}
    public Boolean skipContractDiscountSelection {get; set;}
    
    public List<ContractWrapper> contractWrappersList {get; set;}
    public List<SelectOption> nsOptionList {get; set;}
    public List<ContractDiscountWrapper> contractDiscountWrappersList {get; set;}
    public Map<String, List<Integer>> productIndexesMap {get; set;}
    
    public Contract_discount_counterparty_detail__c instance {get; set;}
    
    private Map<Integer, String> stepsMap = new Map<Integer, String>{1 => Label.CounterParty_Step_1_Of_4_Select_Supplier_Event_Start_End_Date,
        															 2 => Label.CounterParty_Step_2_Of_4_Select_Ns_Contract,
        															 3 => Label.CounterParty_Step_3_Of_4_Select_Condition,
        															 4 => Label.CounterParty_Step_4_Of_4_Enter_Contribution_Information};
    
    public CounterpartCreationWizardController(ApexPages.StandardController stdCtrl) {
        this.stdCtrl = stdCtrl;
        this.currencyIsoCode = UserInfo.getDefaultCurrency();
        step = 1;
        showPreviousButton = false;
        editMode = true;
        showContractList = false;
        showNSForm = false;
        showContractDiscountList = false;
        skipContractSelection = false;
        skipContractDiscountSelection = false;
        this.noNS = false;
        this.instance = (Contract_discount_counterparty_detail__c) stdCtrl.getRecord();
        
        String sid = ApexPages.currentPage().getParameters().get('sid');
        String nsid = ApexPages.currentPage().getParameters().get('nsid');
        String cid = ApexPages.currentPage().getParameters().get('cid');
        String cdid = ApexPages.currentPage().getParameters().get('cdid');
        
        // From Supplier
        if (String.isNotBlank(sid)) {
            this.supplierId = sid;
            this.startedFromSupplier = true;
            this.loadSupplier();
            this.redirectId = sid;
        }
        // From NegoScope
        if (String.isNotBlank(nsid)) {
            this.negoscopeId = nsid;
            this.startedFromNegoscope = true;
            this.loadNegoscope();
            this.redirectId = nsid;
        }
        // From Contract
        if (String.isNotBlank(cid)) {
            this.contractId = cid;
            this.startedFromContract = true;
            this.loadContract();
            this.redirectId = cid;
        }
        // From Condition
        if (String.isNotBlank(cdid)) {
            this.conditionId = cdid;
            this.startedFromCondition = true;
            this.loadCondition();
            this.redirectId = cdid;
        }
        this.init();
        this.contractWrappersList = new List<ContractWrapper>();
        this.nsOptionList = new List<SelectOption>();
        this.contractDiscountWrappersList = new List<ContractDiscountWrapper>();

        this.productIndexesMap = new Map<String, List<Integer>>{'Products_1_10' => new List<Integer>(),
            'Products_11_20' => new List<Integer>(),
            'Products_21_30' => new List<Integer>()};
        Integer k = 0, l = 0;
        for (String key : productIndexesMap.keySet()) {
            for (Integer i = k + 1; i <= k + 5; i++) {
                productIndexesMap.get(key).add(i);
                l = i+5;
                productIndexesMap.get(key).add(l);
            }
            k = l;
        }
    }
    
    private void init() {
        if (this.startedFromSupplier == true || this.startedFromNegoscope == true
            || this.startedFromContract == true || this.startedFromCondition == true)
        {
            this.editMode = false;
        }
    }
    
    public void loadSupplier() {
        if (this.supplierId != null) {
            try {
                Sup_Supplier__c supplier = [SELECT Id, Name, Code__c FROM Sup_Supplier__c WHERE Id = :this.supplierId];
                this.supplierName = supplier.Name;
                this.supplierCode = supplier.Code__c;
                
                this.instance.Supplier__c = supplier.Id;
            } catch (QueryException ex) { }
        }
    }
    
    public void loadNegoscope() {
        if (this.negoscopeId != null) {
            try {
                Sup_sup_NegoScope__c negoscope = [SELECT Id, NS_Code__c, Supplier__c, Supplier__r.Name, Supplier__r.Code__c
                                                  FROM Sup_Sup_NegoScope__c
                                                  WHERE Id = :this.negoscopeId];
                this.supplierId = negoscope.Supplier__c;
                this.supplierName = negoscope.Supplier__r.Name;
                this.supplierCode = negoscope.Supplier__r.Code__c;
                this.negoscopeCode = negoscope.NS_Code__c;
                
                this.instance.Supplier__c = negoscope.Supplier__c;
                this.instance.Nego_Scope__c = negoscope.Id;
            } catch (QueryException ex) { }
        }
    }
    
    public void loadContract() {
        if (this.contractId != null) {
            try {
                contract = [SELECT Id, Contract_Numbder__c, Supplier__c, Supplier__r.Name, Supplier__r.Code__c, Supplier_Nego_Scope__c,
                            Supplier_Nego_Scope__r.NS_Code__c
                            FROM Contract__c
                            WHERE Id = :this.contractId];
                
                this.supplierName = contract.Supplier__r.Name;
                this.supplierCode = contract.Supplier__r.Code__c;
                this.negoscopeCode = contract.Supplier_Nego_Scope__r.NS_Code__c;
                
                step = 2;
                
                this.instance.Supplier__c = contract.Supplier__c;
                this.instance.Nego_Scope__c = contract.Supplier_Nego_Scope__c;
                this.instance.Contract__c = contract.Id;
            } catch (QueryException ex) { }
        }
    }
    
    public void loadCondition() {
        if (this.conditionId != null) {
            try {
                contractDiscount = [SELECT Name, Condition_Type__r.Condition_Code__c, Condition_Type__r.Name,
                                    Nego_Discount_Type__c, Value_per__c, Value_amt__c, Base_TO_Nego__c, YTD_Nego__c,
                                    Contract__c, Contract__r.Supplier__c, Contract__r.Supplier__r.Name,
                                    Contract__r.Supplier_Nego_Scope__c, Condition_Type__r.Proof_Counterparty_Requested__c
                                    FROM Contract_Discount__c
                                    WHERE Id = :this.conditionId
                                    AND Condition_Type__r.Proof_Counterparty_Requested__c = TRUE];
                step = 4;
                
                supplierName = contractDiscount.Contract__r.Supplier__r.Name;
                this.instance.Supplier__c = contractDiscount.Contract__r.Supplier__c;
                this.instance.Nego_Scope__c = contractDiscount.Contract__r.Supplier_Nego_Scope__c;
                this.instance.Contract__c = contractDiscount.Contract__c;
                this.instance.Contract_discount__c = contractDiscount.Id;
            } catch (QueryException ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Condition_CANNOT_Have_Counterpart));
            }
        }
    }
    
    public void reset() {
        this.contract = null;
        this.contractDiscount = null;
        this.instance.Nego_Scope__c = null;
        this.instance.Contract__c = null;
        this.instance.Contract_Discount__c = null;
        
        this.skipContractSelection = false;
        this.skipContractDiscountSelection = false;
        
        this.loadSupplier();
        this.loadNegoscope();
        this.loadContract();
        this.loadCondition();
    }
    
    // direction: true => forward, false: backward
    private void process(Boolean direction) {
        switch on this.step {
            when 1 { // Supplier selection
                this.reset();
                this.instance.Supplier__c = this.supplierId;
                this.contractWrappersList.clear();
                this.startDate = this.instance.Start_Date__c;
                String contractQuery = '';
                contractQuery += ' SELECT Name, Contract_Numbder__c, Contract_BDate__c, Contract_EDate__c, NS_Code__c,';
                contractQuery += ' Supplier__r.Code__c, Supplier_Nego_Scope__r.NS_Code__c, Supplier_Nego_Scope__r.Name';
                contractQuery += ' FROM Contract__c';
                contractQuery += ' WHERE Contract_BDate__c <= :startDate';
                contractQuery += ' AND Contract_EDate__c >= :startDate';
                contractQuery += ' AND Supplier__c = :supplierId';
                if (String.isNotBlank(this.negoscopeId)) {
                    contractQuery += ' AND Supplier_Nego_Scope__c = :negoscopeId';
                }
                contractQuery += ' ORDER BY Supplier_Nego_Scope__c';
                for (Contract__c contract : Database.query(contractQuery))
                    this.contractWrappersList.add(new ContractWrapper(contract));
                
                // No contract found
                if (this.contractWrappersList.isEmpty()) {
                    ////this.reset();
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.No_Contract_For_Supplier));
                    this.nsOptionList.clear();
                    for (Sup_Sup_NegoScope__c ns : [SELECT Name, NS_Code_Prefix__c
                                                    FROM Sup_Sup_NegoScope__c
                                                    WHERE Supplier__c = :this.supplierId])
                        this.nsOptionList.add(new SelectOption(ns.id, ns.Name));
                    // No NS found
                    if (this.nsOptionList.isEmpty()) {
                        this.noNS = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.No_NS_for_Supplier));
                        return;
                    }
                    this.skipContractSelection = true;
                    this.showNSForm = true;
                } else {
                    this.supplierCode = contractWrappersList[0].contract.Supplier__r.Code__c;
                    this.negoscopeCode = contractWrappersList[0].contract.Supplier_Nego_Scope__r.NS_Code__c;
                    contractWrappersList[0].isSelected = true;
                    this.showContractList = true;
                }
            }
            when 2 { // NS/Contract selection
                contractDiscountWrappersList.clear();
                if (this.showContractList) {
                    for (ContractWrapper cw : this.contractWrappersList)
                        if (cw.isSelected) {
                            this.instance.Nego_Scope__c = cw.contract.Supplier_Nego_Scope__c;
                            this.instance.Contract__c = cw.contract.Id;
                            this.contract = cw.contract;
                        }
                    this.showContractList = false;
                }
                // Skip to Negoscope step selection
                if (this.showNSForm) {
                    this.instance.Nego_Scope__c = this.negoscopeId;
                    this.showNSForm = false;
                    this.step++;
                    return;
                }
                // prepare for step 3
                if (!this.showNSForm) {
                    for (Contract_Discount__c contractDiscount : [SELECT Name, Condition_Type__r.Condition_Code__c, Condition_Type__r.Name,
                                                                  Nego_Discount_Type__c, Value_per__c, Value_amt__c, Base_TO_Nego__c, YTD_Nego__c
                                                                  FROM Contract_Discount__c
                                                                  WHERE Contract__c = :this.instance.Contract__c
                                                                  AND Condition_Type__r.Proof_Counterparty_Requested__c = TRUE])
                        contractDiscountWrappersList.add(new ContractDiscountWrapper(contractDiscount));
                    if (!contractDiscountWrappersList.isEmpty()) {
                        contractDiscountWrappersList[0].isSelected = true;
                        this.showContractDiscountList = true;
                    } else {
                        this.skipContractDiscountSelection = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.No_Condition_to_Justify));
                        this.step++;
                        return;
                    }
                }
            }
            when 3 { // Contract condition selection
                for (ContractDiscountWrapper cdw : contractDiscountWrappersList) {
                    if (cdw.isSelected) {
                        this.instance.Contract_Discount__c = cdw.contractDiscount.Id;
                        this.contractDiscount = cdw.contractDiscount;
                    }
                }
                this.showContractDiscountList = false;
            }
        }
    }
    
    public void next() {
        if (this.instance.Start_Date__c <= this.instance.End_Date__c) {
            this.showPreviousButton = true;
            this.process(true);
            this.step++;
            this.editMode = false;
        } else {
            this.editMode = true;
            this.instance.End_Date__c.addError(Label.EndDate_Greater_StartDate);
        }
        this.init();
    }
    
    public void previous() {
        showContractList = false;
        if (this.skipContractSelection) {
            this.step--;
            showNSForm = false;            
        }
        if (this.skipContractDiscountSelection) {
            this.step--;
        }
        showContractDiscountList = false;
        this.noNS = false;
        if (this.step - 2 <= 0) {
            this.step = 1;
            this.editMode = true;
            this.showPreviousButton = false;
        } else {
            this.step -= 2;
            this.process(false);
            this.step++;
        }
        this.init();
    }
    
    public PageReference save() {
        try {
            String[] fields = new String[] {NegoptimHelper.normalizeAPIName('Event_Support__c'),
                NegoptimHelper.normalizeAPIName('Start_Date__c'), NegoptimHelper.normalizeAPIName('End_Date__c'),
                NegoptimHelper.normalizeAPIName('Nego_Scope__c'), NegoptimHelper.normalizeAPIName('Contract__c'),
                NegoptimHelper.normalizeAPIName('Contract_discount__c'), NegoptimHelper.normalizeAPIName('Supplier__c'),
                NegoptimHelper.normalizeAPIName('Applicable_Rate_Manual__c'), NegoptimHelper.normalizeAPIName('Contribution_Unit_Quantity__c'),
                NegoptimHelper.normalizeAPIName('Contribution_Unit_Amount__c')};
            if(NegoptimHelper.checkAccessibility(Contract_discount_counterparty_detail__c.SObjectType, fields) &&
               NegoptimHelper.checkCreatibility(Contract_discount_counterparty_detail__c.SObjectType, fields))
            {
                insert this.instance;
                PageReference pageRef = new PageReference('/' + this.instance.Id);
                pageRef.setRedirect(true);
                return pageRef;
            }
        } catch (DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }
    
    public PageReference cancel() {
        if(redirectId != null)
            return new PageReference('/'+redirectId);
        else
            return this.stdCtrl.cancel();
    }
    
    @remoteAction
    public static String findSuppliers(String searchTerm) {
        String searchTermLike = '%' + searchTerm + '%';
        List<Sup_Supplier__c> listSuppliers = [SELECT Id, Name, Code__c FROM Sup_Supplier__c
                                               WHERE Name LIKE :searchTermLike
                                               OR Code__c LIKE :searchTermLike];
        return JSON.serialize(listSuppliers);
    }
    
    public class ContractWrapper {
        public Contract__c contract {get; set;}
        public Boolean isSelected {get; set;}
        
        public ContractWrapper(Contract__c contract) {
            this.contract = contract;
        }
    }
    
    public class ContractDiscountWrapper {
        public Contract_Discount__c contractDiscount {get; set;}
        public Boolean isSelected {get; set;}
        
        public ContractDiscountWrapper(Contract_Discount__c contractDiscount) {
            this.contractDiscount = contractDiscount;
        }
    }
}