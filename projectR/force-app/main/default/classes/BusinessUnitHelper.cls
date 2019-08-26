/**
 * -- Proof Of Concept --
 * Helper class for Business Units
 * TODO: Add inner Wrapper Class
 * TODO: Check if Singleton is required or make the control by hand
 * */
public class BusinessUnitHelper {
    
    // private static variable referencing the class
    private static BusinessUnitHelper instance = null;

    public Set<Id> BUIdsSet;
    public Integer mode; // 1: parent_w_children or 2: child_w_parents
    public List<Orga_BU__c> BUList {get;private set;}

    // Constructor - Apply Singleton D.P.
    private BusinessUnitHelper(Set<Id> ids, Integer m) {
        this.BUIdsSet = ids;
        this.mode = m;
        // load parent with related children
        if(this.mode == 1) {
            this.BUList = [SELECT Id, Name, CurrencyIsoCode, Business_Unit_Type__c, RecordTypeId, RecordType.DeveloperName,
                           (SELECT Entity_List__r.Id, Entity_List__r.Name, Entity_List__r.CurrencyIsoCode, Entity_List__r.Business_Unit_Type__c,
                            Entity_List__r.RecordTypeId, Entity_List__r.RecordType.DeveloperName
                            FROM List_detail1__r
                            WHERE Entity_List__r.Status__c = 'Open')
                           FROM Orga_BU__c
                           WHERE RecordType.DeveloperName IN ('Store', 'Web', 'Warehouse', 'Country', 'List', 'Group', 'Banner', 'Assortment_Cluster')
                           AND Status__c = 'Open'
                           AND Id IN :this.BUIdsSet
                           LIMIT 1000];
        }
        // load child with related parents
        if(this.mode == 2) {
            // TODO
        }
    }
        
    public static BusinessUnitHelper getInstance(Set<Id> ids, Integer m) {
        if (instance != null) return instance;
        // Create the single instance now
        instance = new BusinessUnitHelper(ids, m);
        return instance;
    }
    
    /**
     * Return Map of key = parent with value = Set of children BU Ids
     * if no children, value = itself
     * */
    public Map<Id, Set<Id>> getBUChildrenIdsMap() {
        Map<Id, Set<Id>> BUIdsMap = new Map<Id, Set<Id>>();
        for(Orga_BU__c item : this.BUList) {
            if(!BUIdsMap.containsKey(item.Id)) {
                BUIdsMap.put(item.Id, new Set<Id>());
            }
            if(item.List_detail1__r.size() > 0) {
                // Cases of Business_Unit_Type__c = 'Country' or 'List' or 'Group'
                for(Orga_BU_List_Detail__c BUDetail : item.List_detail1__r) {
                    BUIdsMap.get(item.Id).add(BUDetail.Entity_List__r.Id);
                }
            } else {
                // Cases of Business_Unit_Type__c = 'Store' or 'Web' or 'Warehouse' or 'Banner'
                // put same Id if BU haven't children
                BUIdsMap.get(item.Id).add(item.Id);
            }
        }
        return BUIdsMap;
    }
    /**
     * Return Map of key = BU Id with value = BU object
     * for all returned records
     * @param withDepth: include children
     * */
    public Map<Id, Orga_BU__c> getBUMap(Boolean withDepth) {
        Map<Id, Orga_BU__c> BUMap = new Map<Id, Orga_BU__c>(this.BUList);
        if(withDepth) {
            for(Orga_BU__c item : BUMap.values()) {
                if(item.List_detail1__r.size() > 0) {
                    for(Orga_BU_List_Detail__c BUDetail : item.List_detail1__r) {
                        Orga_BU__c bu = new Orga_BU__c(Id = BUDetail.Entity_List__r.Id, Name = BUDetail.Entity_List__r.Name,
                                                       CurrencyIsoCode = BUDetail.Entity_List__r.CurrencyIsoCode,
                                                       RecordTypeId = BUDetail.Entity_List__r.RecordTypeId);
                        /**NOT WRITABLE** Business_Unit_Type__c = BUDetail.Entity_List__r.Business_Unit_Type__c**/
                        BUMap.put(bu.Id, bu);
                    }
                }
            }
        }
        return BUMap;
    }
    /**
     * Return Map of key = BU Id with value = Record Type Developer Name
     * for all returned records
     * @param withDepth: include children
     * */
    public Map<Id, String> getBURecordTypeNameMap(Boolean withDepth) {
        Map<Id, String> BURTMap = new Map<Id, String>();
        for(Orga_BU__c item : this.BUList) {
            if(!BURTMap.containsKey(item.Id)) {
                BURTMap.put(item.Id, item.RecordType.DeveloperName);
            }
            if(withDepth && item.List_detail1__r.size() > 0) {
                for(Orga_BU_List_Detail__c BUDetail : item.List_detail1__r) {
                    BURTMap.put(BUDetail.Entity_List__r.Id, BUDetail.Entity_List__r.RecordType.DeveloperName);
                }
            }
        }
        return BURTMap;
    }
    /**
     * Get BU linked to external Id list
     **/
    public Map<String, Orga_BU__c> getBUByExtIds(Set<String> extIds, String recordType) {
        Map<String, Orga_BU__c> buMap = new Map<String, Orga_BU__c>();
        this.BUList = [SELECT Id, Name, Ext_id__c
                       FROM Orga_BU__c
                       WHERE RecordType.DeveloperName = :recordType
                       AND Status__c = 'Open'
                       AND Ext_id__c IN :extIds];
        for(Orga_BU__c item : this.BUList) {
            if(!buMap.containsKey(item.Ext_id__c)) {
                buMap.put(item.Ext_id__c, item);
            }
        }
        return buMap;
    }
}