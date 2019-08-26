/* (A) MAF1.6 Update Format list detail when store creation [After-Insert trigger.]
 * The current BUs are: Country or List.
 * Add BU list detail (as detail (child) record on the current BU, as parent record on Store OR Web Or DC).
 *
 ** (B) MAF1.5 Update Country list detail when store / Web / DC creation [on After-Update trigger]
 * The current BUs are: Store, Web or DC. If country origin in a store is related to a country,
 * then a detail record (entity or child) is inserted/updated in the list detail of the corresponding country,
 * and a parent record is inserted/updated in the list parent of the corresponding store.
 *
 ** (C) MAF15.5 Update Country detail list when status begin open [on After-Update trigger]
 * The current BU is: Country. When the current BU's status is open, so all children BUs should be related to the current BU.
 *
 ** (D) MAF21.2 List can't be close if active contract (before update) [on Before-Update trigger]
 * The current BUs are: Country or List. If the current BU is in relation with a contract, contract discount or invoice, 
 * so the status of the current BU can not be closed.
 *
 ** (E) MAF16.2 Close Country will close all linked Stores / DC / Web / List
 * The current BU is: Country. When the current status is closed, so all related BU's status (store, dc, web, list)
 * will be also closed.
 *
 ** (F) MAF17.1 Country can change his allocation country zone if no contract as been defined to its country zone
 * The current BU is: Country. If a contract is related to a region BU and a country BU is related also to the same region BU,
 * then there is no possibility to move the region BU of the corresponding country BU.
 */
 
public class Trg_Org_Orga_BU_Handler {
	
    static final String STORE_RECORD_TYPE_NAME_CONST = 'Store';
	static final String WEB_RECORD_TYPE_NAME_CONST = 'Web';
	static final String WAREHOUSE_RECORD_TYPE_NAME_CONST = 'Warehouse';
	static final String COUNTRY_RECORD_TYPE_NAME_CONST = 'Country';
	static final String LIST_RECORD_TYPE_NAME_CONST = 'List';
    static final String ASSORTMENT_RECORD_TYPE_NAME_CONST = 'Assortment_Cluster';
    static final String LEGALFORM_RECORD_TYPE_NAME_CONST = 'Legal';
    static final String BANNER_RECORD_TYPE_NAME_CONST = 'Banner';
    static final String OPEN_STATUS_VALUE_CONST = 'Open';
    static final String CLOSED_STATUS_VALUE_CONST = 'Closed';
    
    // Action(s) on Before-Insert trigger.
    public static void OnBeforeInsert(List<Orga_BU__c> listOfNewBU) {
        // Check if Country origin BU is Closed
        checkValidationRulesBeforeInsert(listOfNewBU);
    }
    // Action(s) on After-Insert trigger.
    public static void OnAfterInsert(List<Orga_BU__c> listOfNewBU) {
        // (A) Add BU list detail on country BU AND/OR on list BU, and add BU list detail on store BU, web BU Or dc BU.
        addBUListDetail(listOfNewBU);
    }
    // Actions on After-Update trigger.
    public static void OnAfterUpdate(List<Orga_BU__c> listOfNewBU, Map<ID, Orga_BU__c> listOfOldBUMap) {
        // (B) Modify list detail according to the country origin.
        modifyBUListDetail(listOfNewBU, listOfOldBUMap);
        // (C) Add BU List detail when the country status is modified to "Open".
        addBUListDetailWhenStatusEqualOpen(listOfNewBU, listOfOldBUMap);
        // (E) When the status is equal to "Closed" in a BU Country, all related BU (store, dc, web, list) will be also closed.
        closedBUEvent(listOfNewBU, listOfOldBUMap);
        // update assortment details based on BU (cluster/IsMasterBU) and updating SiteOfSales_Number_N1__c OR Weighted_Distribution_Manual_N1__c
        recalculateAssortmentDetails(listOfNewBU, listOfOldBUMap);
    }
    // Actions on Before-Update trigger.
    public static void OnBeforeUpdate(List<Orga_BU__c> listOfNewBU, Map<Id, Orga_BU__c> listOfOldBUMap) {
        // (D) Cannot "Closed" Country BU or List BU if there is relation with the corresponding Country BU.
        // (F) Cannot detach a country zone origin (Region) in which a contract is related to it.
        checkValidationRulesBeforeUpdate(listOfNewBU, listOfOldBUMap);
    }
    public static void OnBeforeInsertOrUpdate(List<Orga_BU__c> listOfNewBU, Map<ID, Orga_BU__c> listOfOldBUMap) {
        // Check if Country origin BU is Closed
        updateReferenceCountryBU(listOfNewBU, listOfOldBUMap);
    }
    // set country reference for Store and Legal BU
    private static void updateReferenceCountryBU(List<Orga_BU__c> listOfNewBU, Map<ID, Orga_BU__c> listOfOldBUMap){
        Set<String> refCountrySet = new Set<String>();
        Set<String> refCountryNameSet = new Set<String>();
        Map<String, String> refCountryCodeMap = new Map<String, String>();
        String recordTypeName;
        // Define and create a map to hold record type name with the related Orga BU.
        Set<Orga_BU__c> orgaBUSet = new Set<Orga_BU__c>();
        // Record type name and BU mapping.
        Map<Id, String> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Orga_BU__c.SObjectType);
        for (Orga_BU__c currentBU : listOfNewBU) {
            recordTypeName = recordTypeMap.get(currentBU.recordtypeid);
            if (currentBU.Country__c != null &&
                (recordTypeName == STORE_RECORD_TYPE_NAME_CONST || recordTypeName == LEGALFORM_RECORD_TYPE_NAME_CONST)) {
                    refCountrySet.add(currentBU.Country__c);
                    orgaBUSet.add(currentBU);
                }
        }
        // fetch countries
        for(Country_List__c country : [SELECT Name, Country_Code__c
                                       FROM Country_List__c
                                       WHERE Name LIKE :refCountrySet
                                       OR Country_Code__c LIKE :refCountrySet])
        {
            refCountryNameSet.add(country.Name.toUpperCase());
            refCountryCodeMap.put(country.Country_Code__c.toUpperCase(), country.Name);
        }
        for(Orga_BU__c currentBU : listOfNewBU) {
            if(orgaBUSet.contains(currentBU) &&
               (currentBU.Id == NULL ||
                (currentBU.Id != NULL && (currentBU.Country__c != listOfOldBUMap.get(currentBU.Id).Country__c)))) {
                    if(refCountryNameSet.contains(currentBU.Country__c.toUpperCase())) {
                        // Do nothings
                    }
                    else if(refCountryCodeMap.containsKey(currentBU.Country__c.toUpperCase())) {
                        currentBU.Country__c = refCountryCodeMap.get(currentBU.Country__c.toUpperCase());
                    }
                    else {
                        currentBU.Country__c.addError('Ref Country not exist.');
                    }
                }
        }
    }
    // Check if Country origin BU is Closed
    private static void checkValidationRulesBeforeInsert(List<Orga_BU__c> listOfNewBU){
        // Define and create a map to hold record type name with the related Orga BU.
        Map<Orga_BU__c, String> recordTypeNameMap = new Map<Orga_BU__c, String>();
        // Define record type name variable.
        String recordTypeName;
        // Define Map country origin of the current BUs.
        Map<Id, List<Orga_BU__c>> countryOriginMap = new Map<Id, List<Orga_BU__c>>();
        // Record type name and BU mapping.
        Map<Id, String> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Orga_BU__c.SObjectType);
        for (Orga_BU__c currentBU : listOfNewBU) {
            recordTypeName = recordTypeMap.get(currentBU.recordtypeid);
            recordTypeNameMap.put(currentBU, recordTypeName);
            if((recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST || recordTypeName == STORE_RECORD_TYPE_NAME_CONST
                || recordTypeName == WEB_RECORD_TYPE_NAME_CONST) && currentBU.Country_origin__c != NULL) {
                    if(countryOriginMap.containsKey(currentBU.Country_origin__c))
                        countryOriginMap.get(currentBU.Country_origin__c).add(currentBU);
                    else countryOriginMap.put(currentBU.Country_origin__c, new List<Orga_BU__c>{currentBU});
                }
        }
        List<Orga_BU__c> countryOriginList = [Select Id, Status__c, Country_origin__c
                                              From Orga_BU__c
                                              Where Id IN:countryOriginMap.keySet()
                                              AND Status__c =:CLOSED_STATUS_VALUE_CONST];
        if(countryOriginList != NULL && countryOriginList.size()>0){
            for(Orga_BU__c countryBU :countryOriginList){
                for(Orga_BU__c itemBU :countryOriginMap.get(countryBU.Id)){
                    itemBU.Country_origin__c.addError('Error: Connot insert '+ itemBU.Name +'. Country origin is closed.');
                }          
            }
        }
    }
    // (A) Add BU list detail on country BU AND/OR on list BU, and add BU list detail on store BU, web BU Or dc BU.
    private static void addBUListDetail(List<Orga_BU__c> listOfNewBU) {
        Map<Id, Orga_BU__c> buMap = new Map<Id, Orga_BU__c>();
        // Define entity variable.
        Boolean isLinkedToList = false, isLinkedToAssortment = false;
        // Define country origin set.
        Set<Id> countryOriginSet = new Set<Id>();
        // Define format origin set.
        Set<String> formatOriginSet = new Set<String>();
        // Define Assortment Strat set.
        Set<String> assortmentStratSet = new Set<String>();
        // Define a list of the List BU.
        List<Orga_BU__c> listBUs;
        // Define a list of the BU List Details.
        List<Orga_BU_List_Detail__c> BUListDetails = new List<Orga_BU_List_Detail__c>();
        // Record type name and BU mapping.
        Map<Id, String> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Orga_BU__c.SObjectType);
        // Define record type name variable.
        String recordTypeName;
        for (Orga_BU__c item : listOfNewBU) {
            buMap.put(item.Id, item);
            recordTypeName = recordTypeMap.get(item.recordtypeid);
			// Check if the current BU is a store.
            if (recordTypeName == STORE_RECORD_TYPE_NAME_CONST) {
                // check if the store linked to assortment
                if(item.Assortment_Strat__c != null){
                    isLinkedToAssortment = true;
                    assortmentStratSet.add(item.Assortment_Strat__c);
                }
            }
            // Check if the current BU is a Store, Warehouse or Banner.
            if (recordTypeName == STORE_RECORD_TYPE_NAME_CONST || recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST || recordTypeName == BANNER_RECORD_TYPE_NAME_CONST) {
                isLinkedToList = true;
                if(item.Country_origin__c != null){
                    countryOriginSet.add(item.Country_origin__c);
                }
                if (item.Format_Origin__c != null) {
                    formatOriginSet.addAll(item.Format_Origin__c.split(';'));
                }
            }
            // Adding BU List Detail to the Country BU.
            // When the current BU is a store, web, warehouse or banner, so we are concerned to the Country BU
            // Check if there are existing Country BU for the same country origin
            if(item.Country_origin__c != null && (recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST || recordTypeName == STORE_RECORD_TYPE_NAME_CONST
                                                       || recordTypeName == WEB_RECORD_TYPE_NAME_CONST || recordTypeName == BANNER_RECORD_TYPE_NAME_CONST
                                                       || recordTypeName == ASSORTMENT_RECORD_TYPE_NAME_CONST))
            {
                // Create BU list detail.
                Orga_BU_List_Detail__c BUListDetail = new Orga_BU_List_Detail__c(Entity__c = item.Country_origin__c, Entity_List__c = item.Id);
                // Fill the list of the BU list detail for insertion.
                BUListDetails.add(BUListDetail);
            }
        }
        // Adding BU List Type Detail to the List BU.
        if (isLinkedToList && countryOriginSet.size() > 0 && formatOriginSet.size() > 0) {
            Map<String, List<Orga_BU__c>> buListMap = new Map<String, List<Orga_BU__c>>();
            // Get all List BU for the same country origin and country format of the current Store BU.
            listBUs = Database.query(buildQuery(countryOriginSet, formatOriginSet));
            if(listBUs != null && listBUs.size() > 0) {
                for(Orga_BU__c item : listBUs) {
                    String key = item.Country_origin__c + '' + getSortedFormatOrigin(item.Format_Origin__c);
                    if(!buListMap.containsKey(key)) {
                        buListMap.put(key, new List<Orga_BU__c>{item});
                    }
                    else {
                        buListMap.get(key).add(item);
                    }
                }
                // Check if there are existing List BU for the same country origin and country format.
                for (Id buId : buMap.keySet()) {
                    Orga_BU__c currentBU = buMap.get(buId);
                    if(currentBU.Country_origin__c != null && currentBU.Format_Origin__c != null){
                        String key = currentBU.Country_origin__c + '' + getSortedFormatOrigin(currentBU.Format_Origin__c);
                        if(buListMap.containsKey(key)){
                            for(Orga_BU__c item : buListMap.get(key)) {
                                // Create BU list detail.
                                Orga_BU_List_Detail__c BUListDetail = new Orga_BU_List_Detail__c(Entity__c = item.Id, Entity_List__c = buId);
                                // Fill the list of the BU list detail for insertion.
                                BUListDetails.add(BUListDetail);
                            }
                        }
                    }
                }
            }
        }
        // Adding BU Assortment Type List to the List BU.
        if (isLinkedToAssortment && countryOriginSet.size() > 0 && assortmentStratSet.size() > 0) {
            Map<String, List<Orga_BU__c>> buListMap = new Map<String, List<Orga_BU__c>>();
            // Get all List BU linking all the store with Ass_cluster__c = S(i)
            // to the BU with same country_origin & where record_type = 'Assortment cluster' & Ass_cluster = 'S(i)'
            listBUs = [SELECT Id, Country_origin__c, Assortment_Strat__c 
                       FROM Orga_BU__c WHERE Country_origin__c IN :countryOriginSet
                       AND Assortment_Strat__c IN :assortmentStratSet
                       AND RecordType.DeveloperName = :ASSORTMENT_RECORD_TYPE_NAME_CONST];
            if(listBUs != null && listBUs.size() > 0) {
                for(Orga_BU__c item : listBUs) {
                    String key = item.Country_origin__c + '' + item.Assortment_Strat__c;
                    if(!buListMap.containsKey(key)) {
                        buListMap.put(key, new List<Orga_BU__c>{item});
                    }
                    else {
                        buListMap.get(key).add(item);
                    }
                }
                // Check if there are existing List BU for the same country origin and assotment.
                for (Id buId : buMap.keySet()) {
                    Orga_BU__c currentBU = buMap.get(buId);
                    if(currentBU.Country_origin__c != null && currentBU.Assortment_Strat__c != null){
                        String key = currentBU.Country_origin__c + '' + currentBU.Assortment_Strat__c;
                        if(buListMap.containsKey(key)){
                            for(Orga_BU__c item : buListMap.get(key)) {
                                // Create BU list detail.
                                Orga_BU_List_Detail__c BUListDetail = new Orga_BU_List_Detail__c(Entity__c = item.Id, Entity_List__c = buId);
                                BUListDetail.Ass_Clust__c = currentBU.Assortment_Strat__c;
                                // Fill the list of the BU list detail for insertion.
                                BUListDetails.add(BUListDetail);
                            }
                        }
                    }
                }
            }
        }
        if (BUListDetails != null && BUListDetails.size() > 0) {
            // Check governor limits.
            if (BUListDetails.size() + Limits.getDMLRows() > Limits.getLimitDMLRows()) {
                for (Id buId : buMap.keySet()) {
                    Orga_BU__c currentBU = buMap.get(buId);
                    currentBU.addError('You are attempting to insert the addresses of too many BU List Details at once. Please try again with fewer BU List Details.');
                }
            } else {
                try {
                    String[] buListDetailFields = new String[] {NegoptimHelper.normalizeAPIName('Ass_Clust__c'), NegoptimHelper.normalizeAPIName('Entity__c'),
                        NegoptimHelper.normalizeAPIName('Entity_List__c')};
                    if(NegoptimHelper.checkCreatibility(Orga_BU_List_Detail__c.SObjectType, buListDetailFields)){
                        insert BUListDetails;
                    }
                }
                catch(Exception e) {
                    for (Id buId : buMap.keySet()) {
                        Orga_BU__c currentBU = buMap.get(buId);
                        currentBU.addError(e.getDmlMessage(0));
                    }
                }
            }
        }
    }
    // (B) Modify list detail according to the country origin.
    private static void modifyBUListDetail(List<Orga_BU__c> listOfNewBU, Map<ID, Orga_BU__c> listOfOldBUMap) {
        Map<Id, Orga_BU__c> buMap = new Map<Id, Orga_BU__c>();
        Map<Id, Orga_BU__c> oldBUMap = new Map<Id, Orga_BU__c>();
        // Define entity variable.
        Boolean isDeletedLinkedCountry = false, isDeletedLinkedList = false, isDeletedLinkedAssortment = false,
            isLinkedToList = false, isLinkedToAssortment = false;
        // Define country origin of the current BUs.
        Set<Id> countryOriginSet = new Set<Id>();
         // Define old country origin of the current BUs.
        Set<Id> oldCountryOriginSet = new Set<Id>();
        // Define format origin of the current BUs.
        Set<String> formatOriginSet = new Set<String>();
        // Define old format origin of the current BUs.
        Set<String> oldFormatOriginSet = new Set<String>();
        // Define Assortment Strat of the current Store BUs.
        Set<String> assortmentStratSet = new Set<String>(); 
        // Define old Assortment Strat of the current Store BUs.
        Set<String> oldAssortmentStratSet = new Set<String>(); 
        // Define a list of the List BU.
        Set<Id> updatedBUSet = new Set<Id>();  
        List<Orga_BU__c> listBUs;
        List<Orga_BU_List_Detail__c> BUListDetails = new List<Orga_BU_List_Detail__c>();
        List<Orga_BU_List_Detail__c> BUListToDelete = new List<Orga_BU_List_Detail__c>();
        // Record type name and BU mapping.
        Map<Id, String> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Orga_BU__c.SObjectType);
        // Define record type name variable.
        String recordTypeName;
        for (Orga_BU__c item : listOfNewBU) {
            buMap.put(item.Id, item);
            oldBUMap.put(item.Id, listOfOldBUMap.get(item.Id));
            recordTypeName = recordTypeMap.get(item.recordtypeid); 
            Id oldCountryOrigin = listOfOldBUMap.get(item.Id).Country_origin__c;
            String oldFormatOrigin = listOfOldBUMap.get(item.Id).Format_Origin__c;
            String oldAssortmentStrat = listOfOldBUMap.get(item.Id).Assortment_Strat__c;
            // Check if the current BU is a Store.
            if (recordTypeName == STORE_RECORD_TYPE_NAME_CONST) {
                // When the current BU is a Store, so we are concerned to the List BU.
                if(item.Assortment_Strat__c != null && oldAssortmentStrat != null && item.Assortment_Strat__c != oldAssortmentStrat){                    
                    oldAssortmentStratSet.add(oldAssortmentStrat);
                    assortmentStratSet.add(item.Assortment_Strat__c);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedAssortment = true;
                    isLinkedToAssortment = true;
                }
                else if(item.Assortment_Strat__c != null && oldAssortmentStrat == null){
                    assortmentStratSet.add(item.Assortment_Strat__c);
                    isLinkedToAssortment = true;
                }
                else if(item.Assortment_Strat__c == null && oldAssortmentStrat != null){
                    oldAssortmentStratSet.add(oldAssortmentStrat);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedAssortment = true;
                }
            }
            // Check if the current BU is a Warehouse.
            if (recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST || recordTypeName == STORE_RECORD_TYPE_NAME_CONST || recordTypeName == BANNER_RECORD_TYPE_NAME_CONST) {
                if(item.Country_origin__c != null && item.Country_origin__c != oldCountryOrigin){
                    oldCountryOriginSet.add(oldCountryOrigin);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedList = true;
                    isDeletedLinkedCountry = true;
                    isLinkedToList = true;
                }
                if (item.Format_Origin__c != null && !equalFormatOrigin(item.Format_Origin__c, oldFormatOrigin)) {
                    oldFormatOriginSet.add(oldFormatOrigin);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedList = true;
                    isLinkedToList = true;
                }
            }
            // Check if the current BU is a Web.
            if (recordTypeName == WEB_RECORD_TYPE_NAME_CONST) {
                if(item.Country_origin__c != null && item.Country_origin__c != oldCountryOrigin){
                    oldCountryOriginSet.add(oldCountryOrigin);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedCountry = true;
                }
            }
            if(isLinkedToList || isLinkedToAssortment){
                if(item.Country_origin__c != null){
                    countryOriginSet.add(item.Country_origin__c);
                }
                if (item.Format_Origin__c != null){
                    formatOriginSet.addAll(item.Format_Origin__c.split(';'));
                }
            }            
            if (recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST || recordTypeName == STORE_RECORD_TYPE_NAME_CONST
                || recordTypeName == WEB_RECORD_TYPE_NAME_CONST || recordTypeName == BANNER_RECORD_TYPE_NAME_CONST) {
                    if(item.Country_origin__c != null && item.Country_origin__c != oldCountryOrigin){
                        // Create BU list detail.
                        Orga_BU_List_Detail__c BUListDetail = new Orga_BU_List_Detail__c(Entity__c = item.Country_origin__c, Entity_List__c = item.Id);
                        // Fill the list of the BU list detail for insertion.
                        BUListDetails.add(BUListDetail);
                    }
                }
        }
        if (isDeletedLinkedList && (oldCountryOriginSet.size() > 0 || oldFormatOriginSet.size() > 0)) {
            List<Orga_BU_List_Detail__c> oldListBUDetailToDelete = [SELECT Id FROM Orga_BU_List_Detail__c
                                                                    WHERE Entity__c IN (SELECT Id FROM Orga_BU__c 
                                                                                        WHERE (Country_origin__c IN :oldCountryOriginSet OR Format_Origin__c IN :oldFormatOriginSet)
                                                                                        AND RecordType.DeveloperName =: LIST_RECORD_TYPE_NAME_CONST)
                                                                    AND Entity_List__c IN :updatedBUSet];
            BUListToDelete.addAll(oldListBUDetailToDelete);
        }
        if (isDeletedLinkedCountry && oldCountryOriginSet.size() > 0) {
            List<Orga_BU_List_Detail__c> oldListBUDetailToDelete = [SELECT Id FROM Orga_BU_List_Detail__c
                                                                    WHERE Entity__c =: oldCountryOriginSet 
                                                                    AND Entity_List__c IN :updatedBUSet];
            BUListToDelete.addAll(oldListBUDetailToDelete);
        }
        if (isDeletedLinkedAssortment && (oldCountryOriginSet.size() > 0 || oldAssortmentStratSet.size() > 0)) {
            List<Orga_BU_List_Detail__c> oldListBUDetailToDelete = [SELECT Id FROM Orga_BU_List_Detail__c 
                                                                    WHERE Entity__c IN (SELECT Id FROM Orga_BU__c 
                                                                                        WHERE (Country_origin__c IN :oldCountryOriginSet OR Assortment_Strat__c IN :oldAssortmentStratSet)
                                                                                        AND RecordType.DeveloperName =: ASSORTMENT_RECORD_TYPE_NAME_CONST) 
                                                                    AND Entity_List__c IN :updatedBUSet];
            BUListToDelete.addAll(oldListBUDetailToDelete);
        }
        if (BUListToDelete != null && BUListToDelete.size() > 0) {
            if (BUListToDelete.size() + Limits.getDMLRows() > Limits.getLimitDMLRows()) {
                for (Orga_BU__c currentBU: listOfNewBU) {
                    currentBU.addError('You are attempting to delete the addresses of too many BU List Details at once. Please try again with fewer BU List Details.');
                }
            }
            else {
                try {
                    if (Orga_BU_List_Detail__c.sObjectType.getDescribe().isDeletable()) {
                        delete BUListToDelete;
                    }
                }
                catch(DmlException e){
                    for (Orga_BU__c currentBU: listOfNewBU) {
                        currentBU.addError(e.getDmlMessage(0));
                    }
                }
            }
        }
        // Adding BU List Detail to the List BU.
        if (isLinkedToList && countryOriginSet.size() > 0 && formatOriginSet.size() > 0) {
            Map<String, List<Orga_BU__c>> buListMap = new Map<String, List<Orga_BU__c>>();
            // Get all List BU for the same country origin and country format of the current Store BU.
            listBUs = Database.query(buildQuery(countryOriginSet, formatOriginSet));
            if(listBUs != null && listBUs.size() > 0) {
                for(Orga_BU__c item : listBUs) {
                    String key = item.Country_origin__c + '' + getSortedFormatOrigin(item.Format_Origin__c);
                    if(!buListMap.containsKey(key)) {
                        buListMap.put(key, new List<Orga_BU__c>{item});
                    }
                    else {
                        buListMap.get(key).add(item);
                    }
                }
                // Check if there are existing List BU for the same country origin and format origin.
                for (Id buId : buMap.keySet()) {
                    Orga_BU__c currentBU = buMap.get(buId);
                    Orga_BU__c oldBU = oldBUMap.get(buId);
                    if(currentBU.Country_origin__c != null && currentBU.Format_Origin__c != null &&
                       (currentBU.Country_origin__c != oldBU.Country_origin__c || !equalFormatOrigin(currentBU.Format_Origin__c, oldBU.Format_Origin__c))
                       && (recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST || recordTypeName == STORE_RECORD_TYPE_NAME_CONST
                                                       || recordTypeName == WEB_RECORD_TYPE_NAME_CONST || recordTypeName == BANNER_RECORD_TYPE_NAME_CONST
                                                       || recordTypeName == ASSORTMENT_RECORD_TYPE_NAME_CONST))
                    {
                        String key = currentBU.Country_origin__c + '' + getSortedFormatOrigin(currentBU.Format_Origin__c);
                        if(buListMap.containsKey(key)){
                            for(Orga_BU__c item : buListMap.get(key)) {
                                if(item.Id != buId){
                                    // Create BU list detail.
                                    Orga_BU_List_Detail__c BUListDetail = new Orga_BU_List_Detail__c(Entity__c = item.Id, Entity_List__c = buId);
                                    // Fill the list of the BU list detail for insertion.
                                    BUListDetails.add(BUListDetail);
                                }
                            }
                        }
                    }
                }
            }
        }
        // Adding BU Assortment Type List to the List BU.
        if (isLinkedToAssortment && countryOriginSet.size() > 0 && assortmentStratSet.size() > 0) {
            Map<String, List<Orga_BU__c>> buListMap = new Map<String, List<Orga_BU__c>>();
            // Get all List BU linking all the store with Ass_cluster__c = S(i)
            // to the BU with same country_origin & where record_type = 'Assortment cluster' & Ass_cluster = 'S(i)'
            listBUs = [SELECT Id, Country_origin__c, Assortment_Strat__c 
                       FROM Orga_BU__c WHERE Country_origin__c IN :countryOriginSet
                       AND Assortment_Strat__c IN :assortmentStratSet
                       AND RecordType.DeveloperName = :ASSORTMENT_RECORD_TYPE_NAME_CONST];
            if(listBUs != null && listBUs.size() > 0) {
                for(Orga_BU__c item : listBUs) {
                    String key = item.Country_origin__c + '' + item.Assortment_Strat__c;
                    if(!buListMap.containsKey(key)) {
                        buListMap.put(key, new List<Orga_BU__c>{item});
                    }
                    else {
                        buListMap.get(key).add(item);
                    }
                }
                // Check if there are existing List BU for the same country origin and assortment.
                for (Id buId : buMap.keySet()) {
                    Orga_BU__c currentBU = buMap.get(buId);
                    Orga_BU__c oldBU = oldBUMap.get(buId);
                    if(currentBU.Country_origin__c != null && currentBU.Assortment_Strat__c != null && 
                       (currentBU.Country_origin__c != oldBU.Country_origin__c || currentBU.Assortment_Strat__c != oldBU.Assortment_Strat__c))
                    {
                        String key = currentBU.Country_origin__c + '' + currentBU.Assortment_Strat__c;
                        if(buListMap.containsKey(key)){
                            for(Orga_BU__c item : buListMap.get(key)) {
                                // Create BU list detail.
                                Orga_BU_List_Detail__c BUListDetail = new Orga_BU_List_Detail__c(Entity__c = item.Id, Entity_List__c = buId);
                                // Fill the list of the BU list detail for insertion.
                                BUListDetails.add(BUListDetail);
                            }
                        }
                    }
                }
            }            
        }
        if (BUListDetails != null && BUListDetails.size() > 0) {
            // Check governor limits.
            if (BUListDetails.size() + Limits.getDMLRows() > Limits.getLimitDMLRows()) {
                for (Id buId : buMap.keySet()) {
                    Orga_BU__c currentBU = buMap.get(buId);
                    currentBU.addError('You are attempting to insert the addresses of too many BU List Details at once. Please try again with fewer BU List Details.');
                }
            }
            else {
                try {
                    // Insert the BU list detail list records related to the List BU.
                    String[] buListDetailFields = new String[] {NegoptimHelper.normalizeAPIName('Ass_Clust__c'), NegoptimHelper.normalizeAPIName('Entity__c'),
                        NegoptimHelper.normalizeAPIName('Entity_List__c')};
                    if(NegoptimHelper.checkCreatibility(Orga_BU_List_Detail__c.SObjectType, buListDetailFields)){
                        insert BUListDetails;
                    }
                }
                catch(DmlException e){
                    for (Id buId : buMap.keySet()) {
                        Orga_BU__c currentBU = buMap.get(buId);
                        currentBU.addError(e.getDmlMessage(0));
                    }                
                }
            }
        }
    }    
    // Add BU List Detail record in the current country BU when the country BU status is equal to "Open" (If the BU List Detail does not exist).
    private static void addBUListDetailWhenStatusEqualOpen(List<Orga_BU__c> listOfNewBU, Map<ID, Orga_BU__c> listOfOldBUMap) {
        // Define a list of the List BU.
        List<Orga_BU__c> listBUs;
        Orga_BU_List_Detail__c BUListDetail;
        List<Orga_BU_List_Detail__c> BUListDetails = new List<Orga_BU_List_Detail__c>(); 
        List<String> recordTypeList = new List<String>{STORE_RECORD_TYPE_NAME_CONST, WEB_RECORD_TYPE_NAME_CONST, WAREHOUSE_RECORD_TYPE_NAME_CONST, BANNER_RECORD_TYPE_NAME_CONST};
        Set<Id> BUIdSet = new Set<Id>();
        for (Orga_BU__c item : listOfNewBU) {
            if (item.Status__c == OPEN_STATUS_VALUE_CONST && (item.Status__c != listOfOldBUMap.get(item.Id).Status__c)) {
                BUIdSet.add(item.Id);
            }
        }
        if(BUIdSet.size() > 0) {
            for (Orga_BU__c item : [SELECT Id, Country_origin__c FROM Orga_BU__c
                                    WHERE RecordType.DeveloperName IN :recordTypeList
                                    AND Country_origin__c <> NULL
                                    AND Country_origin__c IN :BUIdSet
                                    AND Id NOT IN (SELECT Entity_List__c FROM Orga_BU_List_Detail__c WHERE Entity__c IN :BUIdSet)]) {
                BUListDetail = new Orga_BU_List_Detail__c(Entity__c = item.Country_origin__c, Entity_List__c = item.Id);
                BUListDetails.add(BUListDetail);
            }
        }
        // Check governor limits.
        if(BUListDetails.size() > 0){
            if (BUListDetails.size() + Limits.getDMLRows() > Limits.getLimitDMLRows()) {
                for (Orga_BU__c orgaBU : listOfNewBU) {
                    orgaBU.addError('You are attempting to insert the addresses of too many BU children at once. Please try again with fewer BU children.');
                }
            } else {
                try {
                    String[] buListDetailFields = new String[] {NegoptimHelper.normalizeAPIName('Entity__c'), NegoptimHelper.normalizeAPIName('Entity_List__c')};
                    if(NegoptimHelper.checkCreatibility(Orga_BU_List_Detail__c.SObjectType, buListDetailFields)){
                        insert BUListDetails;
                    }
                }
                catch(DmlException e){
                    for (Orga_BU__c BU : listOfNewBU) {
                        BU.addError(e.getDmlMessage(0));
                    }
                }
            }
        }
    }
    private static void closedBUEvent(List<Orga_BU__c> listOfNewBU, Map<Id, Orga_BU__c> listOfOldBUMap) {
         // (E) When the current status is closed, so all related BU's status (store, dc, web, list) will be also closed.
        // Define and create a map to hold record type name with the related Orga BU.
        // 1. Declaration
        // Map<BU Id, Orga_BU__c(database)>
        Map<Id, Orga_BU__c> closedCountryBUMap = new Map<Id, Orga_BU__c>();
        Boolean isClosedCountryBU = False;
        List<String> recordTypeList = new List<String>{STORE_RECORD_TYPE_NAME_CONST, WEB_RECORD_TYPE_NAME_CONST, WAREHOUSE_RECORD_TYPE_NAME_CONST, LIST_RECORD_TYPE_NAME_CONST, BANNER_RECORD_TYPE_NAME_CONST};
        // Map<RecordTypeId, Developer_Name>
        Map<Id, String> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Orga_BU__c.SObjectType);
        // Define record type name variable.
        String recordTypeName;
        // 2. Load Data
        // Mapping Record type name and BU mapping.
        for (Orga_BU__c currentBU : listOfNewBU) {
            recordTypeName = recordTypeMap.get(currentBU.recordtypeid);
            // Check if the current BU is a country.
            if (recordTypeName == COUNTRY_RECORD_TYPE_NAME_CONST) {
                if (currentBU.Status__c != listOfOldBUMap.get(currentBU.Id).Status__c &&
                    currentBU.Status__c == CLOSED_STATUS_VALUE_CONST) {
                        isClosedCountryBU = true;
                        // Add the current BUs in the corresponding list.
                        closedCountryBUMap.put(currentBU.Id, currentBU);
                    }
            }
        }
        if (isClosedCountryBU){
            // (F) When the Status is equal to "Closed" in a BU Country, all related BU (store, dc, web, list) will be also closed.
            // List of BU which are related to the current Country BU.
            List<Orga_BU__c> listOfRelatedBU =[SELECT Id, Name
                                               FROM Orga_BU__c
                                               WHERE RecordType.DeveloperName IN :recordTypeList
                                               AND Country_origin__c <> NULL
                                               AND Country_origin__c IN :closedCountryBUMap.keySet()];
            if (listOfRelatedBU != NULL && listOfRelatedBU.size() > 0) {
                for(Orga_BU__c item : listOfRelatedBU) {
                    item.Status__c = CLOSED_STATUS_VALUE_CONST;
                }
                if (listOfRelatedBU.size() + Limits.getDMLRows() > Limits.getLimitDMLRows()) {
                    for (Orga_BU__c orgaBU : listOfNewBU) {
                        orgaBU.addError('You are attempting to update the addresses of too many related BU at once. Please try again with fewer related BU.');
                    }
                }
                else {
                    try {
                        String[] buFields = new String[] {NegoptimHelper.normalizeAPIName('Status__c')};
                            if(NegoptimHelper.checkUpdatibility(Orga_BU__c.SObjectType, buFields)){
                                update listOfRelatedBU;
                            }
                    }
                    catch(DmlException e) {
                        for (Orga_BU__c currentBU : listOfNewBU) {
                            currentBU.addError(e.getDmlMessage(0));
                        }
                    }
                }
            }           
        }
    }
    private static void checkValidationRulesBeforeUpdate(List<Orga_BU__c> listOfNewBU, Map<Id, Orga_BU__c> listOfOldBUMap){
        // 1. Declaration
        // Map<BU Id, Orga_BU__c(database)>
        Map<Id, Orga_BU__c> closedCountryBUMap = new Map<Id, Orga_BU__c>();
        // Map Between Country origin Id And Closed List BU
        Map<Id, List<Orga_BU__c>> closedListBUMap = new Map<Id, List<Orga_BU__c>>();
        // Map Between Old Country Zone origin Id And changed BU Country_Zone_origin__c 
        Map<Id, List<Orga_BU__c>> countryZoneOriginMap = new Map<Id, List<Orga_BU__c>>();
        Boolean isClosedCountryBU = False, isClosedListBU = False, isChangedCountryZoneOriginBU = False;
        // Map<RecordTypeId, Developer_Name>
        Map<Id, String> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Orga_BU__c.SObjectType);
        // Define record type name variable.
        String recordTypeName;
        // 2. Load Data
        // Mapping Record type name and BU mapping.
        for (Orga_BU__c currentBU : listOfNewBU) {
            recordTypeName = recordTypeMap.get(currentBU.recordtypeid);
            // Check if the current BU is a country.
            if (recordTypeName == COUNTRY_RECORD_TYPE_NAME_CONST) {
                if (currentBU.Status__c != listOfOldBUMap.get(currentBU.Id).Status__c &&
                    currentBU.Status__c == CLOSED_STATUS_VALUE_CONST) {
                        isClosedCountryBU = true;
                        // Add the current BUs in the corresponding list.
                        closedCountryBUMap.put(currentBU.Id, currentBU);
                    }
                if (currentBU.Country_Zone_origin__c != listOfOldBUMap.get(currentBU.Id).Country_Zone_origin__c) {
                    isChangedCountryZoneOriginBU = true;
                    // Add the current BUs in the corresponding list.
                    if(countryZoneOriginMap.containsKey(listOfOldBUMap.get(currentBU.Id).Country_Zone_origin__c))
                        countryZoneOriginMap.get(listOfOldBUMap.get(currentBU.Id).Country_Zone_origin__c).add(currentBU);
                    else countryZoneOriginMap.put(listOfOldBUMap.get(currentBU.Id).Country_Zone_origin__c, new List<Orga_BU__c>{currentBU});
                }
            }else if(recordTypeName == LIST_RECORD_TYPE_NAME_CONST &&
                     currentBU.Status__c != listOfOldBUMap.get(currentBU.Id).Status__c &&
                     currentBU.Status__c == CLOSED_STATUS_VALUE_CONST) {
                         isClosedListBU = true;
                         // Add the current BUs in the corresponding list.
                         if(closedListBUMap.containsKey(currentBU.Country_origin__c))
                             closedListBUMap.get(currentBU.Country_origin__c).add(currentBU);
                         else closedListBUMap.put(currentBU.Country_origin__c,new List<Orga_BU__c>{currentBU});
                     }
        }
        if (isClosedCountryBU){
            // Check existing Contract__c related to closed BU
            List<Contract__c> listOfContract = [SELECT Id, Contract_BU__c
                                                FROM Contract__c
                                                WHERE Contract_BU__c IN :closedCountryBUMap.keySet()];
            if (listOfContract != NULL && listOfContract.size() > 0) {
                for(Contract__c item : listOfContract){
                    closedCountryBUMap.get(item.Contract_BU__c).Status__c.addError(System.Label.MSG_BU_Cannot_Choose_CloseStatus_ContractRelation);
                }
            }
            // Check existing Contract_Discount__c related to closed BU
            List<Contract_Discount__c> listOfContractDiscount = [SELECT Id, BU_Scope__c 
                                                                 FROM Contract_Discount__c 
                                                                 WHERE BU_Scope__c IN :closedCountryBUMap.keySet()];
            if (listOfContractDiscount != NULL && listOfContractDiscount.size() > 0) {
                for(Contract_Discount__c item : listOfContractDiscount){
                    closedCountryBUMap.get(item.BU_Scope__c).Status__c.addError(System.Label.MSG_BU_Cannot_Choose_CloseStatus_ContractDetailsRelation);
                }
            }
            // Check existing Invoice__c related to closed BU
            List<Invoice__c> listOfInvoice = [SELECT Id, Inv_Business_Unit__c
                                              FROM Invoice__c
                                              WHERE Inv_Business_Unit__c IN :closedCountryBUMap.keySet()];
            if (listOfInvoice != NULL && listOfInvoice.size() > 0) {
                for(Invoice__c item : listOfInvoice) {
                    closedCountryBUMap.get(item.Inv_Business_Unit__c).Status__c.addError(System.Label.MSG_BU_Cannot_Choose_CloseStatus_InvoiceRelation);
                }
            }
        }
        if (isClosedListBU) {
            // Check if existing Contract_c related to Closed List BU
            List<AggregateResult> listOfContract = [SELECT Contract_BU__r.Id
                                                    FROM Contract__c
                                                    WHERE Contract_BU__c IN :closedListBUMap.keySet()
                                                    Group By Contract_BU__r.Id];
            if (listOfContract != NULL && listOfContract.size() > 0) {
                for(AggregateResult item :listOfContract) {
                    for(Orga_BU__c listBU :closedListBUMap.get((ID)item.get('Id'))){
                        listBU.Status__c.addError(System.Label.MSG_BU_Cannot_Choose_CloseStatus_ContractRelation);
                    }
                }
            }
			// Check if existing Contract_Discount__c related to Closed List BU
            List<AggregateResult> listOfContractDiscount = [SELECT BU_Scope__r.Id
                                                            FROM Contract_Discount__c
                                                            WHERE BU_Scope__c IN :closedListBUMap.keySet()
                                                            Group By BU_Scope__r.Id];
            if (listOfContractDiscount != NULL && listOfContractDiscount.size() > 0) {
                for(AggregateResult item :listOfContractDiscount) {
                    for(Orga_BU__c listBU :closedListBUMap.get((ID)item.get('Id'))){
                        listBU.Status__c.addError(System.Label.MSG_BU_Cannot_Choose_CloseStatus_ContractDetailsRelation);
                    }
                }
            }
			// Check if existing Contract_Discount__c related to Closed List BU
            List<AggregateResult> listOfInvoice = [SELECT Inv_Business_Unit__r.Id
                                                   FROM Invoice__c
                                                   WHERE Inv_Business_Unit__c IN :closedListBUMap.keySet()
                                                   Group By Inv_Business_Unit__r.Id];
            if (listOfInvoice != NULL && listOfInvoice.size() > 0) {
                for(AggregateResult item : listOfInvoice) {
                    for(Orga_BU__c listBU :closedListBUMap.get((ID)item.get('Id'))){
                        listBU.Status__c.addError(System.Label.MSG_BU_Cannot_Choose_CloseStatus_InvoiceRelation);
                    }
                }
            }
        }
        if (isChangedCountryZoneOriginBU) {
            // (F) Cannot detach a country zone origin (Region) in which a contract is related to it.
            List<AggregateResult> listOfContract = [SELECT Contract_BU__r.Id
                                                    FROM Contract__c
                                                    WHERE Contract_BU__c IN :countryZoneOriginMap.keySet()
                                                    AND Contract_BU__c <> NULL
                                                    Group By Contract_BU__r.Id];
            if (listOfContract != NULL && listOfContract.size() > 0) {
                for(AggregateResult item : listOfContract) {
                    for(Orga_BU__c itemBU :countryZoneOriginMap.get((ID)item.get('Id'))){
                        itemBU.Country_Zone_origin__c.addError(System.Label.MSG_Cannot_Detach_Country_Zone_Origin);
                    }
                }
            }
        }
    }
    // Check if 2 Format Origin are equals
    private static Boolean equalFormatOrigin(String newFormatOrigin, String oldFormatOrigin) {
        if (newFormatOrigin == null || oldFormatOrigin == null)
            return false;
        Set<String> newFormatOriginSet = new Set<String>(newFormatOrigin.split(';'));
        Set<String> oldFormatOriginSet = new Set<String>(oldFormatOrigin.split(';'));
        return newFormatOriginSet.containsAll(oldFormatOriginSet) && oldFormatOriginSet.containsAll(newFormatOriginSet);
    }
    private static String buildQuery(Set<Id> countriesSet, Set<String> formatOriginsSet) {
        List<Id> countriesList = new List<Id>(countriesSet);
        List<String> formatOriginsList = new List<String>(formatOriginsSet);
        String query = 'SELECT Id, Country_origin__c, Format_Origin__c';
        query += ' FROM Orga_BU__c';
        query += ' WHERE Country_origin__c IN (\'' + String.join(countriesList, '\',\'')+ '\')';
        query += ' AND Format_Origin__c INCLUDES (\'' + String.join(formatOriginsList, '\',\'')+ '\')';
        query += ' AND RecordType.DeveloperName = \'' + LIST_RECORD_TYPE_NAME_CONST + '\'';
        return query;
    }
    private static String getSortedFormatOrigin(String formatOrigin) {
        if (formatOrigin == null) return null;
        List<String> sortedList = formatOrigin.split(';');
        sortedList.sort();
        return String.join(sortedList, ';');
    }
    // Re-calculate WD(ClientBased,MarketBased)/ND/L4L
    // On After Update
    private static void recalculateAssortmentDetails(List<Orga_BU__c> newBUs, Map<Id, Orga_BU__c> oldBUMap) {
        Set<Id> buTargetSet = new Set<Id>();
        Set<Id> buSourceSet = new Set<Id>();
        List<Assortment_Detail__c> assortmentDetails = new List<Assortment_Detail__c>();
        // Record type name and BU mapping.
        Map<Id, String> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Orga_BU__c.SObjectType);
        String recordTypeName;
        for (Orga_BU__c item : newBUs) {
            recordTypeName = recordTypeMap.get(item.RecordTypeId);
            if(item.SiteOfSales_Number_N1__c != oldBUMap.get(item.Id).SiteOfSales_Number_N1__c || item.Weighted_Distribution_Manual_N1__c != oldBUMap.get(item.Id).Weighted_Distribution_Manual_N1__c) {
                if (recordTypeName == ASSORTMENT_RECORD_TYPE_NAME_CONST && item.Country_origin__c != null && item.Mission__c != null /*&& item.Mission__c.contains('Offer')*/) {
                    buTargetSet.add(item.Country_origin__c);
                }
                if(item.IsMasterBU__c == true) buSourceSet.add(item.Id);
            }
        }
        if(!System.isBatch() && (!buTargetSet.isEmpty() || !buSourceSet.isEmpty())) {
            Database.executeBatch(new RecalculateAssortmentDetailBatch('Trg_Org_Orga_BU_Handler', new List<Id>(buSourceSet), new List<Id>(buTargetSet), null, true, false));
        }
    }
}