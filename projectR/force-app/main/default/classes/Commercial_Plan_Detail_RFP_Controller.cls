public with sharing class Commercial_Plan_Detail_RFP_Controller extends NegoptimBaseController {
    // ApexPages.StandardSetController must be instantiated
    // for standard list controllers
    Public Integer size {get; set;} 
    Public Integer noOfRecords {get; set;} 
    public List<SelectOption> paginationSizeOptions {get; set;}
    
    public String commercialPlanDetailId;
    public Commercial_Plan_Detail__c cpd {get; set;}
    Set<Id> initialLoadSuppliersIds = new Set<Id>();
    Set<Id> suppliersIds = new Set<Id>();
    Set<SupplierWrapper> allSupplierSet = new Set<SupplierWrapper>();
    List<Sup_Supplier__c> selectedSuppliers = new List<Sup_Supplier__c>();
    
    public Commercial_Plan_Detail_RFP_Controller(ApexPages.StandardController stdController) {
        commercialPlanDetailId = stdController.getId();
        size = 10;
        noOfRecords = [SELECT COUNT() FROM Sup_Supplier__c WHERE Status__c = 'Active'];
        paginationSizeOptions = new List<SelectOption>();
        paginationSizeOptions.add(new SelectOption('5','5'));
        paginationSizeOptions.add(new SelectOption('10','10'));
        paginationSizeOptions.add(new SelectOption('20','20'));
        paginationSizeOptions.add(new SelectOption('50','50'));
        paginationSizeOptions.add(new SelectOption('100','100'));
        try {
            cpd = [SELECT Id, Name, Event_Name__c, Event_Code__c, Event_Start_Date__c, Event_End_Date__c,
                   Unit_Need__c
                   FROM Commercial_Plan_Detail__c WHERE Id = :commercialPlanDetailId];
            // load existing selection
            load();
            
        } catch(Exception e) {
            System.debug(e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid Id'));
        }
    }
    
    public ApexPages.StandardSetController setCtrlr {
        get {
            if(setCtrlr == null) {
                setCtrlr = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id, Name, Code__c, Country_origin__c
                                                                                         FROM Sup_Supplier__c
                                                                                         WHERE Status__c = 'Active'
                                                                                         LIMIT 10000]));
                setCtrlr.setPageSize(10);
            }
            return setCtrlr;
        }
        set;
    }
    //Changes the size of pagination
    public PageReference refreshPageSize() {
        setCtrlr.setPageSize(size);
        return null;
    }
    // Initialize setCtrlr and return a list of records
    public List<SupplierWrapper> getSuppliers() {
        List<SupplierWrapper> suppliersList = new List<SupplierWrapper>();
        for(Sup_Supplier__c item : (List<Sup_Supplier__c>) setCtrlr.getRecords()) {
            Boolean isSelected = suppliersIds.contains(item.Id);
            suppliersList.add(new SupplierWrapper(item, isSelected));
        }
        allSupplierSet.addAll(suppliersList);
        return suppliersList;
    }
    
    public PageReference processSelection() {
        selectedSuppliers.clear();
        //suppliersIds.clear();
        for(SupplierWrapper item : allSupplierSet) {
            if(item.selected == true) {
                selectedSuppliers.add(item.supplier);
                ////suppliersIds.add(item.supplier.Id);
                if(!suppliersIds.contains(item.supplier.Id)) {
                    suppliersIds.add(item.supplier.Id);
                }
            } else if(suppliersIds.contains(item.supplier.Id)) {
                suppliersIds.remove(item.supplier.Id);
            }
        }
        return null;
    }
    
    public List<Sup_Supplier__c> getSelectedSuppliers() {
        if(selectedSuppliers.size() > 0)
            return selectedSuppliers;
        else
            return null;
    }
    
    public void load() {
        for(Commercial_Plan_Detail_RFP__c item : [SELECT Supplier__c FROM Commercial_Plan_Detail_RFP__c
                                                  WHERE Commercial_Event_Line__c = :commercialPlanDetailId])
        {
            initialLoadSuppliersIds.add(item.Supplier__c);
            suppliersIds.add(item.Supplier__c);
        }
    }
    // Button Save Action
    public PageReference save() {
        this.processSelection();
        List<Commercial_Plan_Detail_RFP__c> RFPList = new List<Commercial_Plan_Detail_RFP__c>();
        for(Id item : suppliersIds) {
            if(!initialLoadSuppliersIds.contains(item)) {
                Commercial_Plan_Detail_RFP__c rfp = new Commercial_Plan_Detail_RFP__c(Commercial_Event_Line__c = cpd.Id, Need__c = cpd.Unit_Need__c,
                                                                                      Supplier__c = item);
                RFPList.add(rfp);
                initialLoadSuppliersIds.add(item);
            }
        }
        if(RFPList.size() > 0)
            Database.insert(RFPList, false);
        // Delete dettached relations
        Set<Id> relationsToremove = new Set<Id>();
        for(Id item : initialLoadSuppliersIds) {
            if(!suppliersIds.contains(item)) {
                relationsToremove.add(item);
            }
        }
        if(relationsToremove.size() > 0) {
            if (checkDeletibility(Commercial_Plan_Detail_RFP__c.SObjectType)) {
                Delete [SELECT Id FROM Commercial_Plan_Detail_RFP__c
                        WHERE Commercial_Event_Line__c = :commercialPlanDetailId
                        AND Supplier__c IN :relationsToremove];
            }
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
        // TODO: Send Email notification to supplier
        return null;
    }
    
    /* Supplier Wrapper Class */
    public class SupplierWrapper {
        public Sup_Supplier__c supplier {get; set;}
        public Boolean selected {get; set;}
        
        public SupplierWrapper(Sup_Supplier__c sup, Boolean sel) {
            supplier = sup;
            selected = sel;
        }
    }
}