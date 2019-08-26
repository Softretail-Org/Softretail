public with sharing class Commercial_Plan_Detail_BU_Controller extends NegoptimBaseController {
    
    public String commercialPlanDetailId;
    private Commercial_Plan_Detail__c cpd {get; set;}
    Map<Id, Orga_BU__c> childrenBUMap = new Map<Id, Orga_BU__c>();
    List<CommercialPlanDetailBUWrapper> wCPDBUList = new List<CommercialPlanDetailBUWrapper>();
    
    public Commercial_Plan_Detail_BU_Controller(ApexPages.StandardController stdController) {
        commercialPlanDetailId = stdController.getId();
        try {
            cpd = (Commercial_Plan_Detail__c) stdController.getRecord();
            // load Children BU and Generate lines
            load();
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid Id'));
        }
    }

    public void load() {
        // Get children BU
        for(Orga_BU__c buItem: [SELECT Id, Name, Business_Unit_Type__c,
                                (SELECT Entity_List__r.Id, Entity_List__r.Name, Entity_List__r.BU_Code__c
                                 FROM List_detail1__r)
                                FROM Orga_BU__c
                                WHERE Id IN (SELECT BU_Target__c FROM Commercial_Plan_Detail__c
                                             WHERE Id = :commercialPlanDetailId)])
        {
            for(Orga_BU_List_Detail__c item: buItem.List_detail1__r) {
                childrenBUMap.put(item.Entity_List__r.Id, item.Entity_List__r);
            }
        }
        // Get BU not existing already
        Set<Id> newBUIds = new Set<Id>();
        // Get BU Id of existing Commercial Plan Detail BUs
        Set<Id> BuIds = new Set<Id>();
        List<Commercial_Plan_Detail_BU__c> existingCPDBUList = [SELECT Status__c, BU_Proposed_Volume__c, POS_Corrected_Volume__c,
                                                                BU_Validated_Volume__c, Orga_Business_Unit__c,
                                                                Orga_Business_Unit__r.Name, Orga_Business_Unit__r.BU_Code__c
                                                                FROM Commercial_Plan_Detail_BU__c
                                                                WHERE Commercial_Event_Line__c = :commercialPlanDetailId];
        if(existingCPDBUList.size() > 0) {
            for(Commercial_Plan_Detail_BU__c item : existingCPDBUList) {
                BuIds.add(item.Orga_Business_Unit__c);
                CommercialPlanDetailBUWrapper wCPDBU = new CommercialPlanDetailBUWrapper(item);
                wCPDBUList.add(wCPDBU);
                if(!childrenBUMap.containsKey(item.Orga_Business_Unit__c)) {
                    newBUIds.add(item.Orga_Business_Unit__c);
                }
            }
            for (Id buId : childrenBUMap.keySet()) {
                if (!BuIds.contains(buId)) {
                    newBUIds.add(buId);
                }
            }
        } else {
            newBUIds = childrenBUMap.keySet();
        }
        if(!newBUIds.isEmpty()) {
            for(Id item : newBUIds) {
                Commercial_Plan_Detail_BU__c cpdBU = new Commercial_Plan_Detail_BU__c(Commercial_Event_Line__c = commercialPlanDetailId,
                                                                                      Orga_Business_Unit__c = item, Status__c = 'New');
                CommercialPlanDetailBUWrapper wCPDBU = new CommercialPlanDetailBUWrapper(cpdBU);
                wCPDBU.BUName = childrenBUMap.get(item).Name;
                wCPDBU.BUCode = childrenBUMap.get(item).BU_Code__c;
                wCPDBUList.add(wCPDBU);
            }
        }
    }
    
    public List<CommercialPlanDetailBUWrapper> getCommercialPlanDetailBUList() {
        return wCPDBUList;
    }
    // Button Save Action
    public PageReference save() {
        List<Commercial_Plan_Detail_BU__c> cpdBUList = new List<Commercial_Plan_Detail_BU__c>();
        for(CommercialPlanDetailBUWrapper item : wCPDBUList) {
            cpdBUList.add(item.cpdBU);
        }
        if(!cpdBUList.isEmpty())
            Database.upsert(cpdBUList, false);
        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
    	// TODO: Send Email notification to supplier
		return null;
	}
    
    /**
     * @description destribute the promo detail volume to reach equally on bus
     * */
    public PageReference DistributeEqually() {
        if (wCPDBUList != null && !wCPDBUList.isEmpty()) {
            Decimal[] shares = NegoptimHelper.smartDivision(cpd.Volume_to_Reach__c, wCPDBUList.size(), 0);
            for (CommercialPlanDetailBUWrapper element : wCPDBUList) {
                element.cpdBU.BU_Validated_Volume__c = shares[wCPDBUList.indexOf(element)];
            }
        }
        return null;
    }
    
    /* Supplier Wrapper Class */
    public class CommercialPlanDetailBUWrapper {
        public Commercial_Plan_Detail_BU__c cpdBU {get; set;}
        public String BUName {get; set;}
        public String BUCode {get; set;}
        
        public CommercialPlanDetailBUWrapper(Commercial_Plan_Detail_BU__c c) {
            cpdBU = c;
            if(cpdBU.Id != null && cpdBU.Orga_Business_Unit__c != null) {
                BUName = cpdBU.Orga_Business_Unit__r.Name;
                BUCode = cpdBU.Orga_Business_Unit__r.BU_Code__c;
            }
        }
    }
}