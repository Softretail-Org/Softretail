/**
 * @author ULiT
 * @description Handler for the trigger Trg_Assortment_Detail
 * */
public class Trg_Assortment_Detail_Handler {

    /* Assortment Wrapper Class */
    public class AssortmentWrapper {
        public Map<Id, Assortment_BU__c> allAssortmentBUMap {get; set;}
        public Map<Id, Assortment_BU__c> assortmentBUMap {get; set;}
        public List<Assortment_Detail__c> assortmentDetails {get; set;}
        public AssortmentWrapper(List<Assortment_Detail__c> newAssortmentDetails) {
            this.assortmentDetails  = new List<Assortment_Detail__c>();
            getNotConsolidateRecords(newAssortmentDetails);
        }
        
        // get not consolidate assortment details
        public void getNotConsolidateRecords(List<Assortment_Detail__c> newAssortmentDetails) {
            Set<Id> assortmentBUIdSet = new Set<Id>();
            for (Assortment_Detail__c item : newAssortmentDetails) {
                assortmentBUIdSet.add(item.Assortment_BU__c);
            }
            this.assortmentBUMap = new Map<Id, Assortment_BU__c>();
            this.allAssortmentBUMap = new Map<Id, Assortment_BU__c>([SELECT Id, Name, Status__c, Orga_HE__c, Orga_HE__r.Path__c, Orga_HE__r.Elt_Code__c, BU_Target__c, Ass_BDate__c, Ass_EDate__c,
                                                                BU_Source__r.SiteOfSales_Number__c, BU_Source__r.SiteOfSales_Number_N1__c, BU_Source__r.SiteOfSales_Number_P1__c, BU_Source__r.SiteOfSales_Number_P2__c,
                                                                Assortment_Parent_Objective__c, Assortment_Parent_Objective__r.RecordType.DeveloperName,
                                                                BU_Source__c, BU_Target__r.Country_origin__c, Year__c, RecordType.DeveloperName
                                                                FROM Assortment_BU__c
                                                                WHERE Id IN :assortmentBUIdSet]);
            for (Assortment_Detail__c item : newAssortmentDetails) {
                Assortment_BU__c assortmentBU = this.allAssortmentBUMap.get(item.Assortment_BU__c);
                if (assortmentBU.RecordType.DeveloperName != 'Conso') {
                    this.assortmentDetails.add(item);
                    this.assortmentBUMap.put(assortmentBU.Id, assortmentBU);
                }
            }
        }
    }
    
    public static void OnBeforeInsert(List<Assortment_Detail__c> newAssortmentDetails) {
        AssortmentWrapper assortmentWrapper = new AssortmentWrapper(newAssortmentDetails);
        linkToRefCorp(assortmentWrapper);
    }
    
    public static void OnBeforeUpdate(List<Assortment_Detail__c> newAssortmentDetails, Map<Id, Assortment_Detail__c> oldAssortmentDetailMap) {
        AssortmentWrapper assortmentWrapper = new AssortmentWrapper(newAssortmentDetails);
        // called on before update because we can't change status in on after update
        updateAssortmentDetails(assortmentWrapper, oldAssortmentDetailMap);
    }
    
    public static void OnBeforeInsertOrUpdate(List<Assortment_Detail__c> newAssortmentDetails, Map<Id, Assortment_Detail__c> oldAssortmentDetailMap) {
        AssortmentWrapper assortmentWrapper = new AssortmentWrapper(newAssortmentDetails);
        validateCategory(assortmentWrapper, oldAssortmentDetailMap);
        checkDuplicate(assortmentWrapper, oldAssortmentDetailMap);
        populateFields(assortmentWrapper, newAssortmentDetails, oldAssortmentDetailMap);
        updateAssortmentStratAndClientClusters(assortmentWrapper, oldAssortmentDetailMap);
        updateAssortmentClientStatus(assortmentWrapper, oldAssortmentDetailMap);
    }
    
    public static void OnAfterInsertOrUpdate(List<Assortment_Detail__c> newAssortmentDetails, Map<Id, Assortment_Detail__c> oldAssortmentDetailMap) {
        AssortmentWrapper assortmentWrapper = new AssortmentWrapper(newAssortmentDetails);
        insertPGs(assortmentWrapper, oldAssortmentDetailMap);
        generateAssortmentDetailSequencesAndMatrix(assortmentWrapper, oldAssortmentDetailMap);
        consolidateAssortmentDetails(assortmentWrapper, oldAssortmentDetailMap);
    }
    
    /**
     * @description validates if the assortment detail category is a sub-cateogry of the assortment bu's category
     * @param newAssortmentDetails a list of new assortment details to insert
     * @param oldAssortmentDetailMap a map of the old assortment details values (case update)
     * on Before Insert or Update
	*/
    private static void validateCategory(AssortmentWrapper assortmentWrapper, Map<Id, Assortment_Detail__c> oldAssortmentDetailMap) {
        Set<Id> categoriesIdSet = new Set<Id>();
        Map<Id, Assortment_Detail__c> newAssortmentDetailsMap = new Map<Id, Assortment_Detail__c>();
                
        for (Assortment_Detail__c item : assortmentWrapper.assortmentDetails) {
            if (oldAssortmentDetailMap == null || (oldAssortmentDetailMap.get(item.Id) != null && item.Category__c != oldAssortmentDetailMap.get(item.Id).Category__c)) {
                categoriesIdSet.add(item.Category__c);
                newAssortmentDetailsMap.put(item.Id, item);
            }
        }
        if (!newAssortmentDetailsMap.isEmpty()) {
            Map<Id, Orga_HE__c> categoriesMap = new Map<Id, Orga_HE__c>([SELECT Path__c FROM Orga_HE__c WHERE Id IN :categoriesIdSet]);        
            for (Assortment_Detail__c item : newAssortmentDetailsMap.values()) {                    
                if (assortmentWrapper.assortmentBUMap != null && assortmentWrapper.assortmentBUMap.containsKey(item.Assortment_BU__c) && item.Category__c != null
                    && categoriesMap.get(item.Category__c).Path__c != null
                    && assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).Orga_HE__c != null
                    && !categoriesMap.get(item.Category__c).Path__c.contains('|' + assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).Orga_HE__r.Elt_Code__c + '|')
                    && !categoriesMap.get(item.Category__c).Path__c.contains(assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).Orga_HE__r.Elt_Code__c + '|')
                    && !categoriesMap.get(item.Category__c).Path__c.contains('|' + assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).Orga_HE__r.Elt_Code__c))
                {
                    newAssortmentDetailsMap.get(item.Id).addError('Assortment Detail Category is not a sub-category of the Assortment Category.');
                }
            }
        }
    }
    
    /**
     * @description creates history lines in case Status__c = 'Validated' and specific fields have changed OR in case Product__c changed (CASE SWITCH),
     * history creation process:
     * 1- assortment detail is cloned and the clone is given a new version and inserted
     * 2- the status of the detail is set to 'In preparation' and saved
     * on Before update because we can't change status after update (fields are read only)
	*/
    private static void updateAssortmentDetails(AssortmentWrapper assortmentWrapper, Map<Id, Assortment_Detail__c> oldAssortmentDetailMap) {
        // fake save list
        // add history for updating assortment details
        Map<Id, Assortment_Detail__c> assotmentDetailsHistoryMap = new Map<Id, Assortment_Detail__c>();
        List<Assortment_Detail__c> assotmentDetailsUpdated = new List<Assortment_Detail__c>();
        Map<String, Integer> oldAssotmentDetailsMap = new Map<String, Integer>();
        Set<Id> assortmentBUSet = new Set<Id>();
        Set<Id> categorySet = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        set<Id> referenceProductSet = new Set<Id>();
        Set<Id> newProductSet = new Set<Id>(); // new product Id set for switch
        Set<Id> lastHistorySet = new Set<Id>();
        
        for (Assortment_Detail__c item : assortmentWrapper.assortmentDetails) {
            // change assortment detail status from null to In preparation
            if (item.Status__c == null && hasChanged(item, oldAssortmentDetailMap.get(item.Id))) {
                item.Status__c = 'In Preparation';
            }
            // add history for updating assortment details
            if (assortmentWrapper.assortmentBUMap.containsKey(item.Assortment_BU__c) && oldAssortmentDetailMap != null && oldAssortmentDetailMap.get(item.Id) != null) {
                if (item.Status__c == 'Validated' && item.Status__c.equals(oldAssortmentDetailMap.get(item.Id).Status__c) &&
                    item.Version__c == null && item.Movement_Date__c != null && item.Client_Status__c != null &&
                    (item.Record_Date__c != oldAssortmentDetailMap.get(item.Id).Record_Date__c ||
                     item.Movement_Date__c != oldAssortmentDetailMap.get(item.Id).Movement_Date__c ||
                     item.Corp_Status__c != oldAssortmentDetailMap.get(item.Id).Corp_Status__c ||
                     item.Corp_Clust1__c != oldAssortmentDetailMap.get(item.Id).Corp_Clust1__c ||
                     item.Corp_Clust2__c != oldAssortmentDetailMap.get(item.Id).Corp_Clust2__c ||
                     item.Corp_Clust3__c != oldAssortmentDetailMap.get(item.Id).Corp_Clust3__c ||
                     item.Corp_Clust4__c != oldAssortmentDetailMap.get(item.Id).Corp_Clust4__c ||
                     item.Corp_Clust5__c != oldAssortmentDetailMap.get(item.Id).Corp_Clust5__c ||
                     item.Corp_Clust6__c != oldAssortmentDetailMap.get(item.Id).Corp_Clust6__c ||
                     item.Client_Status__c != oldAssortmentDetailMap.get(item.Id).Client_Status__c ||
                     item.Client_Ass__c != oldAssortmentDetailMap.get(item.Id).Client_Ass__c ||
                     item.Client_Clust1__c != oldAssortmentDetailMap.get(item.Id).Client_Clust1__c ||
                     item.Client_Clust2__c != oldAssortmentDetailMap.get(item.Id).Client_Clust2__c ||
                     item.Client_Clust3__c != oldAssortmentDetailMap.get(item.Id).Client_Clust3__c ||
                     item.Client_Clust4__c != oldAssortmentDetailMap.get(item.Id).Client_Clust4__c ||
                     item.Client_Clust5__c != oldAssortmentDetailMap.get(item.Id).Client_Clust5__c ||
                     item.Client_Clust6__c != oldAssortmentDetailMap.get(item.Id).Client_Clust6__c ||
                     item.Key_Note__c != oldAssortmentDetailMap.get(item.Id).Key_Note__c ||
                     item.New_Corp_WD_MarketBased__c != oldAssortmentDetailMap.get(item.Id).New_Corp_WD_MarketBased__c ||
                     item.New_Corp_Unit_Cost__c != oldAssortmentDetailMap.get(item.Id).New_Corp_Unit_Cost__c ||
                     item.New_Corp_Quantity_YE__c != oldAssortmentDetailMap.get(item.Id).New_Corp_Quantity_YE__c ||
                     item.Reg_Unit_Cost__c != oldAssortmentDetailMap.get(item.Id).Reg_Unit_Cost__c ||
                     item.New_Client_WD_MarketBased__c != oldAssortmentDetailMap.get(item.Id).New_Client_WD_MarketBased__c ||
                     item.New_Client_Unit_Cost__c != oldAssortmentDetailMap.get(item.Id).New_Client_Unit_Cost__c ||
                     item.New_Client_Quantity_YE__c != oldAssortmentDetailMap.get(item.Id).New_Client_Quantity_YE__c ||
                     item.New_Client_PCB__c != oldAssortmentDetailMap.get(item.Id).New_Client_PCB__c ||
                     item.Release_Date__c != oldAssortmentDetailMap.get(item.Id).Release_Date__c ||
                     item.Key_Note_for_Supply__c != oldAssortmentDetailMap.get(item.Id).Key_Note_for_Supply__c))
                {
                    if(!assortmentBUSet.contains(item.Assortment_BU__c)) {
                        assortmentBUSet.add(item.Assortment_BU__c);
                    }
                    if(!categorySet.contains(item.Category__c)) {
                        categorySet.add(item.Category__c);
                    }
                    if(!productSet.contains(item.Product__c)) {
                        productSet.add(item.Product__c);
                    }
                    item.Status__c = 'In preparation';
                    assotmentDetailsUpdated.add(item);
                }
                if (item.Product__c != oldAssortmentDetailMap.get(item.Id).Product__c) {
                    if(!assortmentBUSet.contains(item.Assortment_BU__c)) {
                        assortmentBUSet.add(item.Assortment_BU__c);
                    }
                    if(!categorySet.contains(oldAssortmentDetailMap.get(item.Id).Category__c)) {
                        categorySet.add(oldAssortmentDetailMap.get(item.Id).Category__c);
                    }
                    if(!productSet.contains(oldAssortmentDetailMap.get(item.Id).Product__c)) {
                        productSet.add(oldAssortmentDetailMap.get(item.Id).Product__c);
                    }
                    item.Client_Status__c = 'New';
                    item.Status__c = 'In preparation';
                    assotmentDetailsUpdated.add(item);
                    newProductSet.add(item.Product__c);
                }
                if (item.Status__c == 'Validated' && item.Status__c != oldAssortmentDetailMap.get(item.Id).Status__c && item.Version__c == null) {
                    // get last history
                    if(item.Last_History__c != null && !lastHistorySet.contains(item.Last_History__c)) {
                        lastHistorySet.add(item.Last_History__c);
                    }
                }
            }
        }
        // add history for updating assortment details
        if(!productSet.isEmpty()) {
            List<AggregateResult> results = [SELECT Assortment_BU__c, Category__c, Product__c, MAX(Version__c) LastVersion
                                             FROM Assortment_Detail__c
                                             WHERE Assortment_BU__c IN :assortmentBUSet AND Category__c IN :categorySet
                                             AND Product__c IN :productSet AND Version__c <> NULL
                                             GROUP BY Assortment_BU__c, Category__c, Product__c];
            for(AggregateResult item :results) {
                Id assortmentBUId = (Id) item.get('Assortment_BU__c');
                Id categoryId = (Id) item.get('Category__c');
                Id productId = (Id) item.get('Product__c');
                Integer lastVersion = Integer.valueOf(item.get('LastVersion'));
                String key = assortmentBUId + '' + categoryId + '' + productId;
                oldAssotmentDetailsMap.put(key, lastVersion);
            }
            for (Assortment_Detail__c item : assotmentDetailsUpdated) {
                // update version for old assortment detail
                Assortment_Detail__c oldAssortmentDetail = oldAssortmentDetailMap.get(item.Id).clone(false);
                String key = item.Assortment_BU__c + '' + item.Category__c + '' + oldAssortmentDetailMap.get(item.Id).Product__c;
                Integer lastVersion = oldAssotmentDetailsMap.containsKey(key) ? oldAssotmentDetailsMap.get(key) : 0;
                if (newProductSet.contains(item.Product__c)) {
                    oldAssortmentDetail.Client_Status__c = 'Delete';
                    oldAssortmentDetail.Status__c = 'Validated';
                    oldAssortmentDetail.Movement_Date__c = Date.today();
                }
                oldAssortmentDetail.Version__c = lastVersion + 1;
                oldAssortmentDetail.Ext_Id__c = null;
                assotmentDetailsHistoryMap.put(item.Id, oldAssortmentDetail);
                // get last history
                if(item.Last_History__c != null && !lastHistorySet.contains(item.Last_History__c)) {
                    lastHistorySet.add(item.Last_History__c);
                }
            }
            // insert history
            if(!assotmentDetailsHistoryMap.isEmpty()) {
                // check security on update Assortment_Detail__c
                String[] assortmentDetailFields = new String[] {NegoptimHelper.normalizeAPIName('Client_Status__c'), NegoptimHelper.normalizeAPIName('Status__c'),
                    NegoptimHelper.normalizeAPIName('Movement_Date__c'), NegoptimHelper.normalizeAPIName('Version__c'), NegoptimHelper.normalizeAPIName('Ext_Id__c')};
                if(NegoptimHelper.checkCreatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields)) {
                    insert assotmentDetailsHistoryMap.values();
                }
                for (Assortment_Detail__c item : assotmentDetailsUpdated) {
                    Assortment_Detail__c lastAssortmentDetail = assotmentDetailsHistoryMap.get(item.Id);
                    if(lastAssortmentDetail != null) item.Last_History__c = lastAssortmentDetail.Id;                    
                }
            }
        }
        // update history
        if(!lastHistorySet.isEmpty()) {
            List<Assortment_Detail__c> lastHistoryAssortmentDetails = new List<Assortment_Detail__c>();
            for(Assortment_Detail__c item : [SELECT Status__c FROM Assortment_Detail__c WHERE Id IN :lastHistorySet]) {
                item.Status__c = 'Previously Validated';
                lastHistoryAssortmentDetails.add(item);
            }
            // check security on update Assortment_Detail__c
            String[] assortmentDetailFields = new String[] {NegoptimHelper.normalizeAPIName('Client_Status__c'), NegoptimHelper.normalizeAPIName('Status__c')};
            if(NegoptimHelper.checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields)) {
                update lastHistoryAssortmentDetails;
            }
        }
    }
    
    private static boolean hasChanged(Assortment_Detail__c newDetail, Assortment_Detail__c oldDetail) {
        Map<String, Object> newValues = newDetail.getPopulatedFieldsAsMap();
        Map<String, Object> oldValues = oldDetail.getPopulatedFieldsAsMap();
        for(String key: newValues.keySet()) {
            if(newValues.get(key) != oldValues.get(key)) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @description change strat position (Ass_BU_Cluster__c) based on Client_Clust(i)__c fields,
     * than it calculates and assigns the KPIs and other calculated fields using AssortmentUtility.assignKPI
     * On Before Insert or Update
     * @description changes the values of Client_clust(i)__c depending on the value of Ass_BU_Cluster__c
     * if Client_Status__c is 'New' then change Client_Ass__c to true
     * On Before Insert
	*/  
    public static void updateAssortmentStratAndClientClusters(AssortmentWrapper assortmentWrapper, Map<Id, Assortment_Detail__c> oldAssortmentDetailsMap) {
        List<Assortment_Detail__c> updatedAssortmentDetailsClientClusterList = new List<Assortment_Detail__c>();
        List<Assortment_Detail__c> updatedAssortmentDetailsStratList = new List<Assortment_Detail__c>();
        Set<Id> categoriesIdSet = new Set<Id>();
        Map<Id, Map<Id, Map<Integer, Orga_BU__c>>> assortmentBUClustersMap;        
        Set<Id> assortmentClustersIdSet = new Set<Id>();
        Map<Id, Orga_BU__c> clustersMap;
        
        for (Assortment_Detail__c item : assortmentWrapper.assortmentDetails) {
            for (Integer i = 1; i <= 6; i++) {
                if ((item.Id == null && item.get('Client_Clust' + i + '__c') != null && item.get('Client_Clust' + i + '__c') == true)
                    || (item.Id != null && oldAssortmentDetailsMap != null && oldAssortmentDetailsMap.get(item.Id) != null &&
                        item.get('Client_Clust' + i + '__c') != oldAssortmentDetailsMap.get(item.Id).get('Client_Clust' + i + '__c'))
                   || item.Force_Update__c)
                {
                    if (item.Category__c != null && !categoriesIdSet.contains(item.Category__c)) {
                        categoriesIdSet.add(item.Category__c);
                    }
                    updatedAssortmentDetailsClientClusterList.add(item);
                    break;
                }
            }
            
            if ((item.Id == null && item.Ass_BU_Cluster__c != null)
                || (item.Id != null && oldAssortmentDetailsMap != null && oldAssortmentDetailsMap.get(item.Id) != null && item.Ass_BU_Cluster__c != oldAssortmentDetailsMap.get(item.Id).Ass_BU_Cluster__c))
            {
                updatedAssortmentDetailsStratList.add(item);
                if (!assortmentClustersIdSet.contains(item.Ass_BU_Cluster__c)) {
                    assortmentClustersIdSet.add(item.Ass_BU_Cluster__c);
                }
                if (item.Category__c != null && !categoriesIdSet.contains(item.Category__c)) {
                    categoriesIdSet.add(item.Category__c);
                }
                if (item.Id == null && item.Ass_BU_Cluster__c != null && item.Client_Status__c == 'New') {
                    item.Client_Ass__c = true;
                }
            }
        }
        
        if (!updatedAssortmentDetailsClientClusterList.isEmpty() || !updatedAssortmentDetailsStratList.isEmpty()) {
            Map<Id, Orga_HE__c> categoriesMap = new Map<Id, Orga_HE__c>([SELECT Path__c FROM Orga_HE__c WHERE Id IN :categoriesIdSet]);
            
            List<Assortment_Detail__c> allUpdatedAssortmentDetailsList = new List<Assortment_Detail__c>();
            allUpdatedAssortmentDetailsList.addAll(updatedAssortmentDetailsClientClusterList);
            allUpdatedAssortmentDetailsList.addAll(updatedAssortmentDetailsStratList);
            
            for (Assortment_Detail__c item : allUpdatedAssortmentDetailsList) {
                if (assortmentWrapper.assortmentBUMap.containsKey(item.Assortment_BU__c)) {
                    item.Assortment_BU__r = assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c);
                    item.Category__r = categoriesMap.get(item.Category__c);
                }
            }
            assortmentBUClustersMap = AssortmentUtility.getAssortmentBUClustersMap(allUpdatedAssortmentDetailsList);
        }
        
        if (!updatedAssortmentDetailsStratList.isEmpty()) {
            clustersMap = new Map<Id, Orga_BU__c> ([SELECT Id, Assortment_Strat__c FROM Orga_BU__c WHERE Id IN :assortmentClustersIdSet]);
            for (Assortment_Detail__c item : updatedAssortmentDetailsStratList) {
                Id buTargetId = assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).BU_Target__c;
                if (assortmentBUClustersMap.containsKey(buTargetId) && assortmentBUClustersMap.get(buTargetId).containsKey(item.Category__c)) {
                    List<Orga_BU__c> clusters = assortmentBUClustersMap.get(buTargetId).get(item.Category__c).values();
                    Integer stratIndex = item.Ass_BU_Cluster__c != null ? Integer.valueOf(clustersMap.get(item.Ass_BU_Cluster__c).Assortment_Strat__c.right(1)) : 6;
                    for (Integer i = clusters.size(); i >= stratIndex + 1; i--) {
                        item.put('Client_Clust' + i + '__c', true);
                    }
                    for (Integer i = 1; i <= stratIndex; i++) {
                        item.put('Client_Clust' + i + '__c', false);
                    }
                    AssortmentUtility.assignKPI(item, clusters);
                }
            }
        }
        if (!updatedAssortmentDetailsClientClusterList.isEmpty()) {
            for (Assortment_Detail__c item : updatedAssortmentDetailsClientClusterList) {
                if (assortmentWrapper.assortmentBUMap.containsKey(item.Assortment_BU__c)) {
                    Id key = assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).BU_Target__c;
                    item.Ass_BU_Cluster__c = null;
                    if(assortmentBUClustersMap.get(key) != null) {
                        Map<Integer, Orga_BU__c> clusters = assortmentBUClustersMap.get(key).get(item.Category__c);
                        if (clusters == null || clusters.isEmpty()) return;
                        for (Integer i = 1; i < 6; i++) {
                            if ((Boolean) item.get('Client_Clust' + i + '__c') && clusters.containsKey(i - 1)) {
                                item.Ass_BU_Cluster__c = clusters.get(i - 1).Id;
                                break;
                            }
                        }
                        AssortmentUtility.assignKPI(item, clusters.values());
                    }
                }
            }
        }
    }
    
    /**
     * @description manage Client_Status__c when client_Clusti__c/ Ass_BU_Cluster__c changes
     * if the new number of selected clusters is greater than the old number of selected clusters, then change client status to increase
     * if the new number of selected clusters is smaller than the old number of selected clusters, then change client status to decrease
     * if the new number of selected clusters is 0, then change client status to delete
     * in the case of force update, if the new number of selected clusters is equal to the old number of selected clusters, then change client status to old client status 
     * 
	*/
    public static void updateAssortmentClientStatus(AssortmentWrapper assortmentWrapper, Map<Id, Assortment_Detail__c> oldAssortmentDetailsMap) {
        Map<Id, Assortment_Detail__c> changedAssortmentDetailsMap = new Map<Id, Assortment_Detail__c>();
        // Client_Status__c values to exclude from change
        List<String> clientStatusToExclude = new List<String> {'Opportunity', 'Delete', 'Probably deleted'};
        for (Assortment_Detail__c item : assortmentWrapper.assortmentDetails) {
            Boolean hasChanged = false;
            for (Integer i = 1; i <= 6; i++) {
                if (item.Id != null && oldAssortmentDetailsMap != null && oldAssortmentDetailsMap.get(item.Id) != null
                    && item.get('Client_Clust' + i + '__c') != oldAssortmentDetailsMap.get(item.Id).get('Client_Clust' + i + '__c'))
                {
                    hasChanged = true;
                    break;
                }
            }
            
            if (hasChanged || item.Force_Update__c) {
                changedAssortmentDetailsMap.put(item.Id, item);
            }
        }
        Map<Id, Assortment_Detail__c> assortmentDetailsMap = new Map<Id, Assortment_Detail__c> ([SELECT Last_History__r.Client_Status__c, Last_History__r.Client_Clust1__c,
                                                                                                 Last_History__r.Client_Clust2__c, Last_History__r.Client_Clust3__c, Last_History__r.Client_Clust4__c,
                                                                                                 Last_History__r.Client_Clust5__c, Last_History__r.Client_Clust6__c,
                                                                                                 Ref_Client_Assortment__r.Client_Status__c, Ref_Client_Assortment__r.Client_Clust1__c,
                                                                                                 Ref_Client_Assortment__r.Client_Clust2__c, Ref_Client_Assortment__r.Client_Clust3__c, Ref_Client_Assortment__r.Client_Clust4__c,
                                                                                                 Ref_Client_Assortment__r.Client_Clust5__c, Ref_Client_Assortment__r.Client_Clust6__c
                                                                                                 FROM Assortment_Detail__c
                                                                                                 WHERE Id IN :changedAssortmentDetailsMap.KeySet()]);
        for (Id key : changedAssortmentDetailsMap.keySet()) {
            Assortment_Detail__c assortmentDetail = assortmentDetailsMap.get(key);
            Assortment_Detail__c lastHistory = String.isNotBlank(assortmentDetail.Last_History__c) ? assortmentDetail.Last_History__r : assortmentDetail.Ref_Client_Assortment__r;
            Boolean hasLastHistory = String.isNotBlank(assortmentDetail.Last_History__c) || String.isNotBlank(assortmentDetail.Ref_Client_Assortment__c);
            String lastValidClientStatus;
            Integer lastValidStratCount = 0;
            String currentClientStatus = changedAssortmentDetailsMap.get(key).Client_Status__c;
            Integer currentStratCount = 0;
            for (Integer i = 1; i < 6; i++) {
                if (oldAssortmentDetailsMap.get(key).Status__c == 'Validated') {
                    if (oldAssortmentDetailsMap.get(key).get('Client_Clust' + i + '__c') != null
                        && oldAssortmentDetailsMap.get(key).get('Client_Clust' + i + '__c') == true)
                    {
                        lastValidStratCount++;
                    }
                } else if (hasLastHistory) {
                    if (lastHistory.get('Client_Clust' + i + '__c') != null
                        && lastHistory.get('Client_Clust' + i + '__c') == true)
                    {
                        lastValidStratCount++;
                    }
                }
                if (changedAssortmentDetailsMap.get(key).get('Client_Clust' + i + '__c') != null
                    && changedAssortmentDetailsMap.get(key).get('Client_Clust' + i + '__c') == true)
                {
                    currentStratCount++;
                }
            }
            
            if (oldAssortmentDetailsMap.get(key).Status__c == 'Validated') {
                lastValidClientStatus = oldAssortmentDetailsMap.get(key).Client_Status__c;
            } else if (changedAssortmentDetailsMap.get(key).Last_History__c != null) {
                lastValidClientStatus = assortmentDetailsMap.get(key).Last_History__r.Client_Status__c;
            }            

            if (lastValidClientStatus == null) {
                if (currentStratCount == 0) {
                    changedAssortmentDetailsMap.get(key).Client_Status__c = '';
                    changedAssortmentDetailsMap.get(key).Client_Ass__c = false;
                } else if (String.isBlank(oldAssortmentDetailsMap.get(key).Client_Status__c) && String.isBlank(currentClientStatus)){
                    changedAssortmentDetailsMap.get(key).Client_Status__c = 'New';
                    changedAssortmentDetailsMap.get(key).Client_Ass__c = true;
                }
            } else {
                changedAssortmentDetailsMap.get(key).Client_Ass__c = false;
                if (currentStratCount == 0) {
                    changedAssortmentDetailsMap.get(key).Client_Status__c = 'Delete';
                } else if (!clientStatusToExclude.contains(currentClientStatus) && !clientStatusToExclude.contains(lastValidClientStatus)) {
                    if (currentStratCount > lastValidStratCount) {
                        changedAssortmentDetailsMap.get(key).Client_Status__c = 'Increase';
                    } else if (currentStratCount < lastValidStratCount) {
                        changedAssortmentDetailsMap.get(key).Client_Status__c = 'Decrease';
                    } else {
                        changedAssortmentDetailsMap.get(key).Client_Status__c = lastValidClientStatus;
                    }
                }
            }
        }
    }
    
    /**
     * @description Inserts a Supplier_PG_Mapping__c if it doesn't already exists when an assortment detail is validated
     * Supplier_PG_Mapping__c matching criteria: Supplier, Product
     * On After Insert or Update
	*/
    private static void insertPGs(AssortmentWrapper assortmentWrapper, Map<Id, Assortment_Detail__c> oldAssortmentDetailMap) {
        // list of PGs to insert
        List<Supplier_PG_Mapping__c> PGList = new List<Supplier_PG_Mapping__c>();
        // Ids of validated assortment details
        Set<Id> validatedAssortmentDetailsIdSet = new Set<Id>();
        // Ids of the Products of validated assortment details
        Set<Id> productIdSet = new Set<Id>();
        // Ids of the clients related to the assortment of the validated assortment details
        Set<Id> clientIdSet = new Set<Id>();
        // productId => assortmentDetailId: to be able to add error message to the correct assortment detail record
        Map<Id, Id> productToAssortmentDetailsMap = new Map<Id, Id>();
        // loop and get the product Ids, category Ids, and Ids of validated assortment details only
        for (Assortment_Detail__c item : assortmentWrapper.assortmentDetails) {
            if ((oldAssortmentDetailMap == null || (oldAssortmentDetailMap.get(item.id) != null && oldAssortmentDetailMap.get(item.id).Status__c != item.Status__c)) && item.Status__c == 'Validated')
                validatedAssortmentDetailsIdSet.add(item.Id);
        }
        if(!validatedAssortmentDetailsIdSet.isEmpty()) {
            // query nessacery fields to create a new PG
            List<Assortment_Detail__c> assortmentDetailList = [SELECT Category__c, Product__c, Product__r.Name, Product__r.ProductCode,
                                                               Product__r.Brand__c, Product__r.Category__c, Product__r.Category__r.Parent_Element__c,
                                                               Assortment_BU__r.BU_Target__c,
                                                               Assortment_BU__r.BU_Target__r.Related_Client__c,
                                                               Assortment_BU__r.BU_Target__r.Related_Client__r.Code__c
                                                               FROM Assortment_Detail__c
                                                               WHERE Id IN :validatedAssortmentDetailsIdSet AND Assortment_BU__r.RecordType.DeveloperName <> 'Conso'];
            if(!assortmentDetailList.isEmpty()) {
                for (Assortment_Detail__c item : assortmentDetailList) {
                    clientIdSet.add(item.Assortment_BU__r.BU_Target__r.Related_Client__c);
                    productIdSet.add(item.Product__c);
                }
                Set<String> keySet = new Set<String>();
                // make sure the client doesn't have a PG for specific product
                for (AggregateResult result : [SELECT Supplier__c supId, Product__c productId, Count(Id) countPgs
                                               FROM Supplier_PG_Mapping__c
                                               WHERE Supplier__c IN :clientIdSet AND Product__c IN :productIdSet
                                               GROUP BY Supplier__c, Product__c])
                {
                    String key = (Id)result.get('supId') + ':' + (Id)result.get('productId');
                    keySet.add(key);
                }
                // Create new PG records
                for (Assortment_Detail__c item : assortmentDetailList) {
                    String key = item.Assortment_BU__r.BU_Target__r.Related_Client__c + ':' + item.Product__c;
                    if (!keySet.contains(key)) {
                        PGList.add(new Supplier_PG_Mapping__c(Supplier__c = item.Assortment_BU__r.BU_Target__r.Related_Client__c,
                                                              Name = item.Product__r.Name,
                                                              Product__c = item.Product__c,
                                                              Brand__c = item.Product__r.Brand__c,
                                                              Department__c = item.Product__r.Category__r.Parent_Element__c,
                                                              Section__c = item.Product__r.Category__c,
                                                              SNA_Code__c = item.Assortment_BU__r.BU_Target__r.Related_Client__r.Code__c + item.Product__r.ProductCode,
                                                              GIMA_Code__c = item.Assortment_BU__r.BU_Target__r.Related_Client__r.Code__c + item.Product__r.ProductCode,
                                                              BU__c = item.Assortment_BU__r.BU_Target__c));
                        productToAssortmentDetailsMap.put(item.Product__c, item.Id);
                        keySet.add(key);
                    }
                }
                // insert PG List
                if (!PGList.isEmpty()) {
                    String errorMessage = '';
                    List<Database.SaveResult> results = Database.insert(PGList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Supplier_PG_Mapping__c pg = PGList.get(i);
                        if (!result.isSuccess()) {
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                Id assortmentId = productToAssortmentDetailsMap.get(pg.Product__c);
                                trigger.NewMap.get(assortmentId).addError(err.getStatusCode() 
                                                                          + (err.getFields().isEmpty() ? '' : ': ' + err.getFields()[0]) 
                                                                          + ' - ' + err.getMessage());
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
     * @description generate assortment details sequences and SF Planning
     * executes GenerateAssortmentDetailSequencesBatch and GenerateAssortmentSFPlanningBatch on records that are validated
     * On After Insert or Update
     * */
    private static void generateAssortmentDetailSequencesAndMatrix(AssortmentWrapper assortmentWrapper, Map<Id, Assortment_Detail__c> oldAssortmentDetailMap) {
        Set<Id> assortmentIdSet = new Set<Id>();
        List<Assortment_Detail__c> assortmentDetails = new List<Assortment_Detail__c>();
        for (Assortment_Detail__c item : assortmentWrapper.assortmentDetails) {
            if (item.Movement_Date__c != null && item.Client_Status__c != null && item.Status__c == 'Validated' && item.Version__c == null && 
                (oldAssortmentDetailMap == null || (oldAssortmentDetailMap.get(item.Id) != null && item.Status__c != oldAssortmentDetailMap.get(item.Id).Status__c)))
            {
                assortmentDetails.add(item);
                assortmentIdSet.add(item.Assortment_BU__c);
            }
        }
        if (!assortmentIdSet.isEmpty() && !assortmentDetails.isEmpty() && !System.isBatch()) {
            List<Assortment_Detail__c> validAssortmentDetails = new List<Assortment_Detail__c>();
            for (Assortment_Detail__c item : assortmentDetails) {
                if (assortmentWrapper.assortmentBUMap.containsKey(item.Assortment_BU__c)) {
                    String recordType = assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).RecordType.DeveloperName;
                    if(recordType == 'Nego' || recordType == 'Target') {
                        validAssortmentDetails.add(item);
                    }
                }
            }
            if(!validAssortmentDetails.isEmpty()) {
                // call batch GenerateAssortmentDetailSequencesBatch
                Database.executeBatch(new GenerateAssortmentDetailSequencesBatch('Trg_Assortment_Detail_Handler', (new Map<Id, Assortment_Detail__c>(validAssortmentDetails)).keySet()));
                // call batch GenerateAssortmentSFPlanningBatch
                Database.executeBatch(new GenerateAssortmentSFPlanningBatch('Trg_Assortment_Detail_Handler', (new Map<Id, Assortment_Detail__c>(validAssortmentDetails)).keySet()));
            }
        }
    }

    /**
     * @description check duplicate details records
     * duplication criteria: Assortment_BU__c, Product__c, Version__c
     * On Before Insert or Update
     * */
    private static void checkDuplicate(AssortmentWrapper assortmentWrapper, Map<Id,Assortment_Detail__c> oldAssortmentDetailsMap) {
        Set<Id> productsIdset = new Set<Id>();
        Set<Id> assortmentsIdSet = new Set<Id>();
        Map<String, Assortment_Detail__c> productAssortmentDetailMap = new Map<String, Assortment_Detail__c>();
        for (Assortment_Detail__c item : assortmentWrapper.assortmentDetails) {
            if ((item.Id == null ||
                 (item.Id != null && oldAssortmentDetailsMap.get(item.Id) != null && (item.Product__c != oldAssortmentDetailsMap.get(item.Id).Product__c || item.Version__c != oldAssortmentDetailsMap.get(item.Id).Version__c)))
                && item.Version__c == null)
            {
                String key = item.Assortment_BU__c + '' + item.Product__c;
                if (!productAssortmentDetailMap.containsKey(key)) {
                    productAssortmentDetailMap.put(key, item);
                } else {
                    item.adderror(Label.MSG_Product_already_exist_in_List);
                }
                assortmentsIdSet.add(item.Assortment_BU__c);
                productsIdset.add(item.Product__c);
            }
        }
        if (!productsIdset.isEmpty()) {
            // put in Map<Id Assortment + Id product>
            for (Assortment_Detail__c item : [SELECT Assortment_BU__c, Product__c
                                              FROM Assortment_Detail__c
                                              WHERE Product__c IN :productsIdset
                                              AND Assortment_BU__c IN :assortmentsIdSet
                                              AND Version__c = null])
            {
                String key = item.Assortment_BU__c + '' + item.Product__c;
                if (productAssortmentDetailMap.containsKey(key)) {
                    productAssortmentDetailMap.get(key).adderror(Label.MSG_Product_already_exist_in_assortment);
                }
            }
        }
    }
    
    /**
     * @description: Fill Category__c from product category on insert if NULL or on update if product changed
     * generates and fill Ext_Id__c on insert or on update if product changed
     * On Before Insert or Update
     * */
    private static void populateFields(AssortmentWrapper assortmentWrapper, List<Assortment_Detail__c> newAssortmentDetails, Map<Id, Assortment_Detail__c> oldAssortmentDetailsMap) {
        Map<Id, List<Assortment_Detail__c>> productAssortmentDetailMap = new Map<Id, List<Assortment_Detail__c>>();
        for (Assortment_Detail__c item : newAssortmentDetails) {
            if (item.Id != null // in case update, always update Ext_Id__c
                || (item.Id == null && String.isBlank(item.Ext_id__c)) // in case insert and Ext_Id__c is empty, populate Ext_Id__c
                || item.Category__c == null // always populate category__c if empty
                || (item.Id != null && item.Product__c != oldAssortmentDetailsMap.get(item.Id).Product__c)) // update category if product changed
            {
                if(!productAssortmentDetailMap.containsKey(item.Product__c))
                    productAssortmentDetailMap.put(item.Product__c, new List<Assortment_Detail__c>());
                productAssortmentDetailMap.get(item.Product__c).add(item);
            }
        }
        if (!productAssortmentDetailMap.isEmpty()) {
            for (Product2 product : [SELECT Id, Ext_id__c, Category__c FROM Product2 WHERE Id IN : productAssortmentDetailMap.keySet()]) {
                for (Assortment_Detail__c item : productAssortmentDetailMap.get(product.Id)) {
                    // populate category
                    if (item.Category__c == null || item.Id != null && item.Product__c != oldAssortmentDetailsMap.get(item.Id).Product__c) {
                        item.Category__c = product.Category__c;
                    }
                    // populate external id
                    if (product.Ext_id__c == null) {
                        item.addError(Label.MSG_Product_Ext_Id_Is_Null);
                    } else if (item.Id != null || (item.Id == null && String.isBlank(item.Ext_id__c))) {
                        String version = item.Version__c != null ? String.valueOf((Integer)item.Version__c) : '';
                        item.Ext_id__c = assortmentWrapper.allAssortmentBUMap.get(item.Assortment_BU__c).Name + '-' + product.Ext_id__c + '-V' + version;
                    }
                }
            }
        }
    }
    
    /**
     * Fill Ref_Corp_Assortment__c on insert
     * On Before Insert
     * */
    private static void linkToRefCorp(AssortmentWrapper assortmentWrapper) {
        Set<Id> objectiveAssortmentSet = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        Map<String, Assortment_Detail__c> budgetAssortmentDetailKeyMap = new Map<String, Assortment_Detail__c>();
        
        for (Assortment_Detail__c item: assortmentWrapper.assortmentDetails) {
            productSet.add(item.Product__c);
        }
        // Load Objective Assortment IDs
        for (Assortment_Detail__c item: assortmentWrapper.assortmentDetails) {
            if(assortmentWrapper.assortmentBUMap.containsKey(item.Assortment_BU__c) && assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).Assortment_Parent_Objective__c != null &&
               assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).Assortment_Parent_Objective__r.RecordType.DeveloperName == 'Budget')
            {
                objectiveAssortmentSet.add(assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).Assortment_Parent_Objective__c);
            }
        }
        for (Assortment_Detail__c item : [SELECT Id, Assortment_BU__c, Product__c 
                                          FROM Assortment_Detail__c 
                                          WHERE Product__c IN :productSet
                                          AND Assortment_BU__c IN :objectiveAssortmentSet
                                          AND Version__c = null])
        {
            String key = item.Assortment_BU__c + '' + item.Product__c;
            budgetAssortmentDetailKeyMap.put(Key, item);
        }
        if (!objectiveAssortmentSet.isEmpty() && !productSet.isEmpty()) {
            for (Assortment_Detail__c item : assortmentWrapper.assortmentDetails) {
                String key = assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).Assortment_Parent_Objective__c + '' + item.Product__c;
                item.Ref_Corp_Assortment__c = budgetAssortmentDetailKeyMap.containsKey(key) ? budgetAssortmentDetailKeyMap.get(key).Id : null;
            }
        }
    }
    
    private static void consolidateAssortmentDetails(AssortmentWrapper assortmentWrapper, Map<Id, Assortment_Detail__c> oldAssortmentDetailsMap) {
        List<Assortment_Detail__c> updatedAssortmentDetails = new List<Assortment_Detail__c>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Id> countryOriginSet = new Set<Id>();
        Set<Id> buSourceSet = new Set<Id>();
        List<String> assortmentDetailsCalculateFields = new List<String>{'Fact_WD_MarketBased__c','L4L_Client_ND_ClientBased__c','L4L_Client_ND_MarketBased__c','L4L_Client_ProductNumber__c',
            'L4L_Client_WD_ClientBased__c','L4L_Client_WD_MarketBased__c','New_Client_ND_ClientBased__c','New_Client_ND_MarketBased__c','New_Client_ProductNumber__c',
            'New_Client_Quantity_SEQ__c','New_Client_Quantity_YE__c','New_Client_WD_ClientBased__c','New_Client_WD_MarketBased__c','New_Corp_ND_ClientBased__c',
            'New_Corp_ND_MarketBased__c','New_Corp_Quantity_YE__c','New_Corp_WD_ClientBased__c','New_Corp_WD_MarketBased__c','New_Client_Unit_Cost__c','New_Corp_Unit_Cost__c'};
        
        for (Assortment_Detail__c item : assortmentWrapper.assortmentDetails) {
            if (item.Id != null && oldAssortmentDetailsMap != null && oldAssortmentDetailsMap.get(item.Id) != null && item.Status__c == 'Validated' && item.Version__c == null) {
                for(String field : assortmentDetailsCalculateFields) {
                    Decimal newValue = item.get(field) != null ? Decimal.valueOf(String.valueOf(item.get(field))) : null;
                    Decimal oldValue = oldAssortmentDetailsMap.get(item.Id).get(field) != null ? Decimal.valueOf(String.valueOf(oldAssortmentDetailsMap.get(item.Id).get(field))) : null;
                    if(newValue != oldValue) {
                        updatedAssortmentDetails.add(item);
                    }
                }
            }
        }
        if (!updatedAssortmentDetails.isEmpty()) {
            for (Assortment_Detail__c item : updatedAssortmentDetails) {
                if(assortmentWrapper.assortmentBUMap.containsKey(item.Assortment_BU__c)) {
                    if(item.Year__c != null && !yearSet.contains(Integer.valueOf(item.Year__c))) {
                        yearSet.add(Integer.valueOf(item.Year__c));
                    }
                    if(assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).BU_Target__r.Country_origin__c != null && !countryOriginSet.contains(assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).BU_Target__r.Country_origin__c)) {
                        countryOriginSet.add(assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).BU_Target__r.Country_origin__c);
                    }
                    if(assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).BU_Source__c != null && !buSourceSet.contains(assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).BU_Source__c)) {
                        buSourceSet.add(assortmentWrapper.assortmentBUMap.get(item.Assortment_BU__c).BU_Source__c);
                    }
                }
            }
            if(!System.isBatch() && !yearSet.isEmpty() && !buSourceSet.isEmpty() && !countryOriginSet.isEmpty()) {
                // call batch ConsolidateAssortmentBatch
                Database.executeBatch(new ConsolidateAssortmentBatch('Trg_Assortment_Detail_Handler', countryOriginSet, yearSet, buSourceSet));
            }
        }
    }
}