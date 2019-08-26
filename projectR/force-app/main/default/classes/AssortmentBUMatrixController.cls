/**
 * @author ULiT
 * @date 11/6/2018
 * @description Custom controller that uses the standard Assortment_BU__c controller
 * and includes the Assortment BU Matrix logic for the corresponding view.
 * It provides the following initial functionalities:
 * 1- Display all assortment details for all assortment head + Filter.
 * 2- Display the assorment details for a single assortment head + Filter.
 * 3- GOAL: Optimising the ASSORTMENT of PRODUCTS you plan to stock &
 * then ARRANGING those products on the shelves for MAXIMUM impact.
 **/
 
public with sharing class AssortmentBUMatrixController extends NegoptimBaseController {
    
    private static final String DEFAULT_STRING = 'DEFAULT';
    private final Integer DEFAULT_PAGE_SIZE = 50;
    
    public GridSettingsManager gridSettingsManager {get; set;}
    public List<String> dynamicFields {get; set;}
    public Boolean readOnlyUser {get; set;}
    public String gridFields_serialized {get; set;}
    public List<String> totalFields {get; set;} // total fields ordered as loaded
    public String totalFields_serialized {get; set;}
    public String fieldsToCountList_serialized {get; set;}
    public String fieldsToSumList_serialized {get; set;}
    public String picklistValuesMap_serialized {get; set;}
    
    public String recordId {get; set;} // Assortment BU Id: used in excel methods
    private String assortmentBUName; // Assortment BU Name: used in excel methods
    public Boolean readOnly {get; set;}
    
    public List<SelectOption> clientStatusesPickList {get; set;}
    
    Map<Id, AssortmentDetailWrapper> assortmentDetailWrapperMap {get; set;} // categoryId => all assortment details under that category
    
    public Product2 product {get;set;} // to filter categories -- todo remove when we use categoryLookup
    public Boolean isStopProducts {get; set;}
    public String productReferenceType {get; set;}
    public String productSearch {get; set;} // search key word to filter products
    public String clientStatus {get; set;} // filter to client_status
    public String typeURL {get; set;} // used in excel methods and in View
    public Boolean hasDetails {get; set;} // indicates if the assortment bu has details
    
    public Boolean popupGenerateExcel {get; set;}
    public String emailTo {get; set;}
    public String emailCc {get; set;}
    public String emailBcc {get; set;}
    public String emailSubject {get; set;}
    public String emailBody {get; set;}
    public String xmlheader {get { return '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>'; } }

    public Boolean isShowHistory {get; set;} // flag to filter history detail records or not
    public Boolean includeStores {get; set;}
    public Boolean includeAllStatus {get; set;}
    public Boolean hideBlankStatus {get; set;}
    
    // popup switchProduct fields
    public Boolean popupSwitchProduct {get; set;}
    public Id assortmentDetailId {get; set;}
    public Id assortmentDetailCategory {get; set;}
    public String productName {get; set;}
    public List<SwitchProductWrapper> switchProductsList {get; set;}
    public Boolean singleProductAction {get; set;}
    public String popupTitle {get; set;}
    private List<Schema.PicklistEntry> productReferenceTypePicklistValues {
        get {
            List<Schema.PicklistEntry> picklistEntriesList = productReferenceTypePicklistValues != null ? productReferenceTypePicklistValues : Product2.fields.Product_Reference_Type__c.getDescribe().getPicklistValues();
            return picklistEntriesList;
        }
    }
    // popup stopProduct fields
    public Boolean popupStopProduct {get; set;}
    public List<StopProductWrapper> stopProductsList {get; set;}
    public Id productToStopId {get; set;}
    
    public String clientStatus_serialized {get; set;}
    /*public Map<String, Map<Integer, Orga_BU__c>> buClustersMap {get; set;}*/
    public Map<Id, List<BUClusterWrapper>> categoryBUClustersMap {get; set;} // categoryId => list of clusters
    public String categoryBUClustersMap_serialized {get; set;}
    public Integer maxClusterCount {get; set;}
    public String maxClusterCategory {get; set;}
    private Integer clusterNameLength;
    
    public Assortment_BU__c assortmentBU {get; set;}
    private Id assortmentCategoryId;
    private HierarchyElementTree het;
    public ApexPages.StandardSetController assortmentDetailStdSetCtrl { get; set;}
    public Map<Id, String> categoryNamesMap {get; set;}
    
    // map of strat ids for each assortment_bu
    private Map<Id, Assortment_Detail__c> assortmentDetailsUpdatedMap {get; set;}
    public Map<Id, Assortment_Detail__c> initialAssortmentDetailsMap {get; set;}
    private Set<Id> categorySet {get; set;}
    public List<AssortmentDetailWrapper> wAssortmentDetailList {get; set;} // iterated in view to display records
    public Map<Id, Map<String, Integer>> counts {get; set;}
    public Map<Id, Map<String, Decimal>> sums {get; set;}
    private List<String> fieldsToCountList;
    private List<String> fieldsToSumList;
        
    public Integer pageSize {get; set;} // pagination size
    public Integer noOfRecords {get; set;} // total number of records
    public List<SelectOption> pageSizes {get; set;}
    
    public String jsonCategoryTree {get; set;}
    public Map<Id, CategoryTreeWrapper> categoryTreeMap {get; set;}
    
    /** Constructor. */
    public AssortmentBUMatrixController(ApexPages.StandardController stdController) {
        // add fields to standard controller to be used in excel files
        List<String> fieldNames = new List<String> {
            SObjectType.Assortment_BU__c.fields.Name.Name,
            SObjectType.Assortment_BU__c.fields.Budget_WD__c.Name,
            SObjectType.Assortment_BU__c.fields.New_Client_WD_MarketBased__c.Name,
            SObjectType.Assortment_BU__c.fields.Budget_Quantity__c.Name,
            SObjectType.Assortment_BU__c.fields.New_Client_Quantity_YE__c.Name,
            SObjectType.Assortment_BU__c.fields.Budget_SellIn__c.Name,
            SObjectType.Assortment_BU__c.fields.New_Client_SellIn_YE__c.Name,
            SObjectType.Assortment_BU__c.fields.BU_Target__c.Name,
            SObjectType.Assortment_BU__c.fields.Orga_HE__c.Name,
            SObjectType.Assortment_BU__c.fields.Ass_EDate__c.Name,
            SObjectType.Assortment_BU__c.fields.Status__c.Name,
            SObjectType.Assortment_BU__c.fields.Year__c.Name
        };
        // add fields only if test is not running
        if (!System.Test.isRunningTest())
            stdController.addFields(fieldNames);
        // Get record Id
        String assortmentBUId = stdController.getId();
        if(String.isNotBlank(assortmentBUId)) {
            try {
                this.categoryNamesMap = new Map<Id, String>();
                // To display apex message when validate assortment after page redirect:
                String message = ApexPages.CurrentPage().getParameters().get('messages');
                if(String.isNotBlank(message)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message)); 
                }
                //
                // load custom settings
                NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
                // load matrix grid layout from custom settings
                String assortmentMatrixGridLayout = settings.assortmentMatrixGridLayout;
                String layoutParam = ApexPages.currentPage().getParameters().get('layout');
                assortmentMatrixGridLayout = String.isBlank(layoutParam) ? assortmentMatrixGridLayout : layoutParam;
                String staticFields = 'Name,Category__c,Force_Update__c,Category__r.Name,Category__r.Parent_Element__c,Category__r.Level__c,Category__r.Path__c,Assortment_BU__r.BU_Target__c,Ass_BU_Cluster__c,Assortment_BU__r.Ass_BDate__c,Assortment_BU__r.Ass_EDate__c,';
                staticFields += 'Product__r.Product_Reference_Type__c,Product__r.Market_End_of_Life_Date__c,Product__r.IsRenovation__c,Product__r.IsInnovation__c,Product__r.recordType.DeveloperName,Assortment_BU__c,Record_date__c,Version__c,Category__r.Long_Name_1__c,';
                staticFields += 'Movement_Date__c,Client_Status__c,Status__c,Product__r.Name,Assortment_BU__r.Orga_HE__c,Assortment_BU__r.Orga_HE__r.Path__c,New_Client_WD_ClientBased__c,New_Client_WD_MarketBased__c,Year__c,';
                for (Integer i = 1; i <= 6; i++) {
                    staticFields += 'Last_History__r.Client_Clust' + i + '__c,';
                    staticFields += 'Ref_Client_Assortment__r.Client_Clust' + i + '__c,';
                }
                staticFields += 'Last_History__r.Client_Status__c,';
                staticFields += 'Ref_Client_Assortment__r.Client_Status__c,Ref_Client_Assortment__r.Year__c,Ref_Client_Assortment__r.Status__c';
                this.gridSettingsManager = new GridSettingsManager('Assortment_Detail__c', staticFields, assortmentMatrixGridLayout);
                this.picklistValuesMap_serialized = JSON.serialize(this.gridSettingsManager.picklistValuesMap);
                // init fields related to totals
                //// Map<String, Schema.SObjectField> sFieldMap = Assortment_Detail__c.sObjectType.getDescribe().fields.getMap();
                this.dynamicFields = new List<String>();
                this.fieldsToCountList = new List<String>();
                this.fieldsToSumList = new List<String>();
                this.totalFields = new List<String>();
                Map<String, GridSettingsManager.FieldWrapper> gridFieldsMap = new Map<String, GridSettingsManager.FieldWrapper>();
                for (GridSettingsManager.FieldWrapper field : this.gridSettingsManager.GRID_FIELDS) {
                    dynamicFields.add(field.fieldName);
                    gridFieldsMap.put(field.fieldName, field);
                    if (!field.isReference
                        && (field.fieldType == DisplayType.Currency
                            || field.fieldType == DisplayType.Double
                            || field.fieldType == DisplayType.Integer
                            || field.fieldType == DisplayType.Percent
                            || field.fieldType == DisplayType.Boolean))
                    {
                        totalFields.add(field.fieldName);
                        if (field.fieldType == DisplayType.Boolean)
                            fieldsToCountList.add(field.fieldName);
                        else fieldsToSumList.add(field.fieldName);
                    } 
                }
                this.gridFields_serialized = JSON.serialize(gridFieldsMap);
                this.totalFields_serialized = JSON.serialize(this.totalFields);
                this.fieldsToCountList_serialized = JSON.serialize(this.fieldsToCountList);
                this.fieldsToSumList_serialized = JSON.serialize(this.fieldsToSumList);
                //
                // check user profile against custom settings
                List<String> matrixProfiles = settings.assortmentMatrixProfile;
                String userProfile = UserInfo.getProfileId();
                this.readOnlyUser = matrixProfiles == null || matrixProfiles.isEmpty() || !matrixProfiles.contains(userProfile);
                //
                this.recordId = Id.valueOf(assortmentBUId);
                this.product = new Product2();
                this.isStopProducts = false;
                this.productReferenceType = '';
                this.hasDetails = false;
                this.clientStatusesPickList = new List<SelectOption>{new SelectOption('null', Label.Blank)}; // 'null' because of use in javascript
                for (Schema.PicklistEntry pickListVal : Assortment_Detail__c.Client_Status__c.getDescribe().getPicklistValues()) {
                    this.clientStatusesPickList.add(new SelectOption (pickListVal.getValue().remove(' '), pickListVal.getLabel()));
                }
                this.clientStatus = '';
                this.popupGenerateExcel = false;
                this.assortmentDetailsUpdatedMap = new Map<Id, Assortment_Detail__c>();
                this.wAssortmentDetailList = new List<AssortmentDetailWrapper>();
                this.initialAssortmentDetailsMap = new Map<Id, Assortment_Detail__c>();
                this.categorySet = new Set<Id>();
                this.pageSize = 50;
                this.pageSizes = new List<SelectOption>();
                this.pageSizes.add(new SelectOption('5', '5'));
                this.pageSizes.add(new SelectOption('10', '10'));
                this.pageSizes.add(new SelectOption('25', '25'));
                this.pageSizes.add(new SelectOption('50', '50'));
                this.pageSizes.add(new SelectOption('75', '75'));
                this.pageSizes.add(new SelectOption('100', '100'));
                this.counts = new Map<Id, Map<String, Integer>>();
                this.sums = new Map<Id, Map<String, Decimal>>();
                this.popupSwitchProduct = false;
                this.singleProductAction = false;
                this.switchProductsList = new List<SwitchProductWrapper>();
                this.popupStopProduct = false;
                this.stopProductsList = new List<StopProductWrapper>();
                this.assortmentBU = (Assortment_BU__c)stdController.getRecord();
                this.readOnly = (this.assortmentBU.Ass_EDate__c < Date.today() && this.assortmentBU.Status__c == 'Closed') || readOnlyUser;
                this.assortmentBUName = this.assortmentBU.Name;
                // Load Hierarchy Element Tree based on Assortment BU Category
                assortmentCategoryId = this.assortmentBU.Orga_HE__c == null ? NegoptimHelper.getRootId() : this.assortmentBU.Orga_HE__c;
                this.het = new HierarchyElementTree(new Set<Id>{assortmentCategoryId});
                this.isShowHistory = false;
                this.includeStores = false;
                this.includeAllStatus = false;
                this.hideBlankStatus =  false;
                
                /*this.buClustersMap = new Map<String, Map<Integer, Orga_BU__c>>();*/
                // clustering by category
                this.categoryBUClustersMap = new Map<Id, List<BUClusterWrapper>>();
                
                if (gridSettingsManager.ERRORS.isEmpty()) {
                    // get assortment details
                    this.search();
                } else {
                    for (String errorMessage : gridSettingsManager.ERRORS) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                    }
                }
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        } else {
            String errorMessage = 'Assortment Id is Null';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }
    }
    
    /**
     * @description constructs a query to fetch assortment details based on filters
     * @return String the query
    */
    private String buildAssortmentDetailQuery() {
        List<String> conditions = this.getConditions();
        if (!this.isShowHistory) {
            conditions.add('Version__c = NULL');
        }
        String orderBy = 'Category__r.Path__c, Product__r.Name ASC, Version__c DESC';
        String query = this.gridSettingsManager.buildQuery(null, conditions, orderBy);
        return query;
    }
    
    /**
     * @param conditions
     * @description constructs the where clause of an SOQL query by returning 'WHERE' followed by each condition in conditions seperated by 'AND'
     * @return String a well structured WHERE clause
    */
    private String buildWhere(List<String> conditions) {
        return ' WHERE ' +String.join(conditions, ' AND ');
    }
    
    private List<String> getConditions() {
        List<String> conditions = new List<String>();
        conditions.add('Category__c <> null');
        if (String.isNotBlank(this.recordId))
            conditions.add('Assortment_BU__c = \'' + String.escapeSingleQuotes(recordId) + '\'');
        if (String.isNotBlank(product.Category__c)) {
            String condition;
            if (het.isAncestor(assortmentCategoryId, product.Category__c)) {
                Orga_HE__c filterCategory = het.allElementsWithParentsMap.get(product.Category__c);
                condition = 'Category__r.Path__c LIKE \'' + String.escapeSingleQuotes(filterCategory.Path__c) + '%\'';
            } else {
                condition = 'Category__c = \'' + String.escapeSingleQuotes(product.Category__c) + '\'';
            }
            conditions.add(condition);
        }
        if (String.isNotBlank(productSearch)) {
            String searchString = String.escapeSingleQuotes(productSearch);
            String condition = '(Product__r.Name LIKE \'%' + searchString + '%\'';
            condition += ' OR Product__r.ProductCode LIKE \'%' + searchString + '%\'';
            condition += ' OR Product__r.Product_EAN__c LIKE \'%' + searchString + '%\'';
            condition += ' OR Product__r.VIP__c LIKE \'%' + searchString + '%\'';
            condition += ' OR Category__r.Name LIKE \'%' + searchString + '%\')';
            conditions.add(condition);
        }
        if (String.isNotBlank(clientStatus)) {
            String separator = '-';
            clientStatus = clientStatus.removeStart(separator);
            String str = clientStatus.toLowerCase().replace('probablydeleted', 'probably deleted');
            List<String> filterStatus = new List<String>();
            if (String.isNotBlank(str))
                filterStatus = str.split(separator);
            String condition = '';
            if (filterStatus.contains('null')) {
                condition = 'Client_Status__c = NULL';
                filterStatus.remove(filterStatus.indexOf('null'));
            }
            if (!filterStatus.isEmpty()) {
                List<String> filterStatus_escaped = new List<String>();
                for (String status : filterStatus) {
                    filterStatus_escaped.add(String.escapeSingleQuotes(status));
                }
                if (String.isNotBlank(condition)) {
                    condition = '(' + condition + ' OR Client_Status__c IN (\'' + String.join(filterStatus_escaped, '\',\'') + '\')' + ')';
                } else if (String.isBlank(condition)) {
                    condition = 'Client_Status__c IN (\'' + String.join(filterStatus_escaped, '\',\'') + '\')';
                }
                if (String.isNotBlank(condition))
                    conditions.add(condition);
            }
        }
        if (String.isNotBlank(this.productReferenceType) || this.isStopProducts) {
            List<String> selectedReferenceTypesList = new List<String>();
            String productReferenceTypeCondition = '';
            String condition = '';
            String stopProductConditions = '';
            if (String.isNotBlank(this.productReferenceType)) {
                for (String str : this.productReferenceType.split('-')) {
                    if (str.equals('Switch') || str.equals('Reno')) {
                        selectedReferenceTypesList.add(str);
                    }
                }
            }
            if (!selectedReferenceTypesList.isEmpty()) {
                productReferenceTypeCondition = '(Product__r.Market_End_of_Life_Date__c = NULL OR CALENDAR_YEAR(Product__r.Market_End_of_Life_Date__c) > ' + this.assortmentBU.Year__c + ')';
                productReferenceTypeCondition += ' AND Product__r.Product_Reference_Type__c IN (\'' + String.join(selectedReferenceTypesList, '\',\'') + '\')';
            }
            if(this.isStopProducts) {
                stopProductConditions = 'CALENDAR_YEAR(Product__r.Market_End_of_Life_Date__c) <= ' + this.assortmentBU.Year__c;
            }
            if (!selectedReferenceTypesList.isEmpty() && this.isStopProducts) {
                condition = '((' + productReferenceTypeCondition + ') OR (' + stopProductConditions + '))';
            } else {
                condition = !selectedReferenceTypesList.isEmpty() ? productReferenceTypeCondition : stopProductConditions;
            }
            condition += ' AND Version__c = NULL';
            conditions.add(condition);
        }
        if (this.hideBlankStatus) {
            conditions.add('Client_Status__c != NULL');
        }
        return conditions;
    }
    
    public void getAssortmentDetails() {
        Set<Id> categoryIds = new Set<Id>();
        this.wAssortmentDetailList = new List<AssortmentDetailWrapper>();
        this.initialAssortmentDetailsMap = new Map<Id, Assortment_Detail__c>();
        assortmentDetailWrapperMap = new Map<Id, AssortmentDetailWrapper>();
        Map<Id, ClientStatusWrapper> clientStatusWrapperMap = new Map<Id, ClientStatusWrapper>(); // to serialize
        Integer clusterCount;
        Id categoryId;
        List<Assortment_Detail__c> assortmentDetailsList = (List<Assortment_Detail__c>) this.assortmentDetailStdSetCtrl.getRecords();
        if (!assortmentDetailsList.isEmpty()) {
            for (Assortment_Detail__c item : assortmentDetailsList) {
                categoryIds.add(item.Category__c);
                Assortment_Detail__c initialAssortmentDetail = item.Clone(true);
                if (initialAssortmentDetail.Version__c == NULL) {
                    initialAssortmentDetail.Movement_Date__c = initialAssortmentDetail.Movement_Date__c == NULL ? Date.today() : initialAssortmentDetail.Movement_Date__c;
                    initialAssortmentDetail.Record_Date__c = initialAssortmentDetail.Record_Date__c == NULL ? initialAssortmentDetail.Movement_Date__c  : initialAssortmentDetail.Record_Date__c;
                    
                }
                AssortmentDetailWrapper wAssortmentDetail;
                
                // fill wrapper assortment detail
                initialAssortmentDetail = fillAssortmentDetail(initialAssortmentDetail);
                if(!assortmentDetailWrapperMap.containsKey(initialAssortmentDetail.Category__c)) {
                    wAssortmentDetail = new AssortmentDetailWrapper(initialAssortmentDetail.Category__c, initialAssortmentDetail.category__r.Name, initialAssortmentDetail);
                } else {
                    wAssortmentDetail = assortmentDetailWrapperMap.get(initialAssortmentDetail.Category__c);
                    wAssortmentDetail.assortmentDetails.add(initialAssortmentDetail);
                }
                this.initialAssortmentDetailsMap.put(item.Id, item);
                assortmentDetailWrapperMap.put(initialAssortmentDetail.Category__c, wAssortmentDetail);
                if (!this.categoryNamesMap.containsKey(item.Category__c))
                    this.categoryNamesMap.put(item.Category__c, item.Category__r.Long_Name_1__c);
                if(!this.counts.containsKey(item.Category__c))
                    initTotals(item.Category__c);
            }
            
            // get Assortment Clusters using NegoptimHelper.getAssortmentBUClustersMap
            Map<Id, Map<Integer, Orga_BU__c>> assortmentBUClustersMap = AssortmentUtility.getAssortmentBUClustersMap(assortmentDetailsList).get(this.assortmentBU.BU_Target__c);
            this.clusterNameLength = 0;
            this.maxClusterCount = 0;
            this.maxClusterCategory = '';
            this.categoryBUClustersMap.clear();
            for (Id detailCategoryId : assortmentBUClustersMap.keySet()) {
                this.categoryBUClustersMap.put(detailCategoryId, new List<BUClusterWrapper>());
                if (assortmentBUClustersMap.get(detailCategoryId).size() > maxClusterCount) {
                    maxClusterCount = assortmentBUClustersMap.get(detailCategoryId).size();
                    maxClusterCategory = detailCategoryId;
                }
                for (Orga_BU__c cluster : assortmentBUClustersMap.get(detailCategoryId).values()) {
                    this.categoryBUClustersMap.get(detailCategoryId).add(new BUClusterWrapper(cluster));
                    this.clusterNameLength = cluster.Name.length() > clusterNameLength ? cluster.Name.length() : this.clusterNameLength;
                }
            }
            
            for (Assortment_Detail__c detail : assortmentDetailsList) {
                if (!this.categoryBUClustersMap.containskey(detail.Category__c))
                    this.categoryBUClustersMap.put(detail.Category__c, new List<BUClusterWrapper>());
                
                if (this.categoryBUClustersMap.get(detail.Category__c).size() < maxClusterCount) {
                    for (Integer i = this.categoryBUClustersMap.get(detail.Category__c).size(); i < maxClusterCount; i++)
                        this.categoryBUClustersMap.get(detail.Category__c).add(new BUClusterWrapper(null));
                }
                // fill clientStatusWrapperMap
                clusterCount = 0;
                for (BUClusterWrapper bcw : this.categoryBUClustersMap.get(detail.Category__c))
                    clusterCount += bcw.orgaBU == null ? 0 : 1;
                clientStatusWrapperMap.put(detail.Id, new ClientStatusWrapper(detail, clusterCount, this.dynamicFields));
            }
            
            this.categoryBUClustersMap_serialized = JSON.serialize(this.categoryBUClustersMap);
            this.clientStatus_serialized = JSON.serialize(clientStatusWrapperMap);
            this.wAssortmentDetailList = assortmentDetailWrapperMap.values();
        }
        this.hasDetails = this.wAssortmentDetailList.size() > 0;
    }

    /**
     * @description builds the assortment detail grid including headers and totals
    */
    public Component.Apex.PageBlockTable getDynamicPageBlockTable() {
        if (recordId == null) return null;
        if (wAssortmentDetailList.isEmpty()) return null;
        Component.Apex.PageBlockTable dynamicBlockTable = new  Component.Apex.PageBlockTable();
        dynamicBlockTable.expressions.value = '{!group.assortmentDetails}';
        dynamicBlockTable.var = 'item';        
        for (GridSettingsManager.FieldWrapper fieldWrapper : this.gridSettingsManager.GRID_FIELDS) {
            ColumnWrapper matrixCol = new ColumnWrapper();
            if (fieldWrapper.fieldName.equalsIgnoreCase('Ref_Client_Clust1__c')) {
                dynamicBlockTable.childComponents.add(matrixCol.getClientClusters('ref', clusterNameLength));
            } else if (fieldWrapper.fieldName.equalsIgnoreCase('Client_Clust1__c')) {
                dynamicBlockTable.childComponents.add(matrixCol.getClientClusters('new', clusterNameLength));
            } else if ((fieldWrapper.fieldName.startsWithIgnoreCase('Client_Clust') || fieldWrapper.fieldName.startsWithIgnoreCase('Ref_Client_Clust')) 
                     && fieldWrapper.fieldName.endsWithIgnoreCase('__c'))
            {
                continue;
            } 
            else {
                Component.Apex.Column col = matrixCol.getColumn(fieldWrapper, fieldsToSumList.contains(fieldWrapper.fieldName)
                                                                || fieldsToCountList.contains(fieldWrapper.fieldName));
                if (col != null) dynamicBlockTable.childComponents.add(col);
            }
        }
        return dynamicBlockTable;
    }
    
    /**
     * @description creates and serializes a map of id => ClientStatusWrapper
    */
    private void setClientStatus_serialized(List<Assortment_Detail__c> detailsList) {
        Map<Id, ClientStatusWrapper> clientStatusWrapperMap = new Map<Id, ClientStatusWrapper>();
        for (Assortment_Detail__c item : detailsList) {
            Integer clusterCount = 0;
            for (BUClusterWrapper bcw : this.categoryBUClustersMap.get(item.Category__c))
                clusterCount += bcw.orgaBU == null ? 0 : 1;
            clientStatusWrapperMap.put(item.Id, new ClientStatusWrapper(item, clusterCount, this.dynamicFields));
        }
        this.clientStatus_serialized = JSON.serialize(clientStatusWrapperMap);
    }                   
    
    /**
     * @description resets search filters
    */
    public PageReference resetFilters() {
        this.product.Category__c = null;
        this.productReferenceType = null;
        this.product.IsRenovation__c = false;
        this.isStopProducts = false;
        this.productSearch = '';
        this.isShowHistory = false;
        this.clientStatus = '';
        this.hideBlankStatus = false;
        this.includeStores = false;
        this.includeAllStatus = false;
        return this.search();
    }
    
    public void first() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.assortmentDetailStdSetCtrl.first();
        this.getAssortmentDetails();
    }
    
    public void previous() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.assortmentDetailStdSetCtrl.previous();
        this.getAssortmentDetails();
    }
    
    public void next() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.assortmentDetailStdSetCtrl.next();
        this.getAssortmentDetails();
    }
    
    public void last() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.assortmentDetailStdSetCtrl.last();
        this.getAssortmentDetails();
    }
    
    public void refreshPageSize() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.assortmentDetailStdSetCtrl.setPageSize(pageSize);
        this.getAssortmentDetails();
    }
    
    /**
     * @description checks if the record has changed since it has been loaded
     * by comparing it with it's clone created on load
     * */
    private boolean hasChanged(Assortment_Detail__c originalRecord, Assortment_Detail__c recordOnPage) {
        Map<String, Object> oldValues = originalRecord.getPopulatedFieldsAsMap();
        Map<String, Object> newValues = recordOnPage.getPopulatedFieldsAsMap();
        for(String key: newValues.keySet()) {
            if(newValues.get(key) != oldValues.get(key)) {
                return true;
            }
        }
        return false;
    }
    
    private Map<Id, Assortment_Detail__c> processBeforeUpdate() {
        Map<Id, Assortment_Detail__c> updatedResultsMap = new Map<Id, Assortment_Detail__c>();
        for (AssortmentDetailWrapper item : this.wAssortmentDetailList) {
            for(Assortment_Detail__c asd : item.assortmentDetails) {
                Assortment_Detail__c initialAssortmentDetail;
                if(this.assortmentDetailsUpdatedMap.containsKey(asd.Id)) {
                    initialAssortmentDetail = this.assortmentDetailsUpdatedMap.get(asd.Id);
                } else {
                    initialAssortmentDetail = this.initialAssortmentDetailsMap.get(asd.Id);
                }
                // fill updated assortment details
                if(hasChanged(initialAssortmentDetail, asd) && asd.Version__c == null) {
                    updatedResultsMap.put(asd.Id, asd);
                }
            }
        }
        return updatedResultsMap;
    }
    
    private void processAfterUpdate(List<Assortment_Detail__c> updatedResults) {
        if (!updatedResults.isEmpty()) {
            Map<Id, Assortment_Detail__c> updatedResultsMap = new Map<Id, Assortment_Detail__c>();
            for (Assortment_Detail__c item : updatedResults) {
                updatedResultsMap.put(item.Id, item);
            }
            // fill total after update formula
            for (AssortmentDetailWrapper item : this.wAssortmentDetailList) {
                Id categoryId = item.categoryId;
                Map<String, Integer> categoryCountMap = this.counts.get(categoryId);
                Map<String, Decimal> categorySumMap = this.sums.get(categoryId);
                for(Assortment_Detail__c asd : item.assortmentDetails) {
                    Assortment_Detail__c currentAssortmentDetail, oldAssortmentDetail;
                    if(updatedResultsMap.containsKey(asd.Id)) {
                        currentAssortmentDetail = updatedResultsMap.get(asd.Id);
                        if(this.assortmentDetailsUpdatedMap.containsKey(asd.Id)) {
                            oldAssortmentDetail = this.assortmentDetailsUpdatedMap.get(asd.Id);
                        } else {
                            oldAssortmentDetail = this.initialAssortmentDetailsMap.get(asd.Id);
                        }
                        // add record to map
                        Assortment_Detail__c clonedItem = currentAssortmentDetail.clone(true, true, true, true);
                        this.assortmentDetailsUpdatedMap.put(currentAssortmentDetail.Id, clonedItem);
                    }
                }
            }
        }
    }
    
    
    public PageReference save() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        Map<Id, Assortment_Detail__c> updatedResultsMap = assortmentDetailsUpdatedMap;
        Savepoint sp = Database.setSavepoint();
        try {
            if (!updatedResultsMap.isEmpty()) {
                // Check Assortment_Detail__c upsert field security
                String[] assortmentDetailFields = new List<String>();
                for (GridSettingsManager.FieldWrapper fieldWrapper : this.gridSettingsManager.GRID_FIELDS) {
                    if(fieldWrapper.isInputField && !fieldWrapper.isCalculated && !fieldWrapper.fieldName.contains('.')) assortmentDetailFields.add(getFieldName(fieldWrapper.fieldName));
                }
                if(checkCreatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields) &&
                   checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields))
                {
                    List<Database.SaveResult> results = Database.update(updatedResultsMap.values(), false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Assortment_Detail__c assortmentDetail = updatedResultsMap.values().get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = assortmentDetail.Product__r.Name + ' : ';
                            Database.Error[] errors = result.getErrors();
                            System.debug('errors='+errors.size());
                            for (Database.Error err : errors) {
                                String msg = '' + err.getStatusCode();
                                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                    errorMessage += err.getMessage();
                                } else {
                                    errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n'; 
                                }
                            }
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                        }
                    }
                    // exist the method if there are any messages added to the list -- on runtime any messages is this case will be an error message
                    if (!ApexPages.getMessages().isEmpty()) {
                        return null;
                    }
                    // get updated record
                    this.assortmentDetailsUpdatedMap.clear();
                    search();
                    // refresh values in clientStatus_serialized
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Modifications_Saved_SF_And_Sequences_Generated));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.MSG_Nothing_To_Update));
            }
        } catch (DmlException ex) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getMessage()));
        } catch (Exception ex) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getMessage()));
        }
        return null;
    }
    
    public PageReference validateAssortment() {
        this.assortmentBU.Status__c = 'Validated';
        try {
            String[] assortmentBUFields = new List<String>{'Status__c'};
            if(checkUpdatibility(Assortment_BU__c.SObjectType, assortmentBUFields)) {
            	update this.assortmentBU;
            }
        	PageReference pageRef = Page.AssortmentBUMatrix;
        	pageRef.getParameters().put('id', this.recordId);
        	pageRef.getParameters().put('layout', ApexPages.currentPage().getParameters().get('layout'));
        	pageRef.getParameters().put('messages', Label.MSG_Assortment_Validated);
        	pageRef.setRedirect(true);
        	return pageRef;
        } catch(DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDMLMessage(0)));
            return null;
        } catch(Exception ex){
            return null;
        }
    }
    
    private Assortment_Detail__c fillAssortmentDetail(Assortment_Detail__c item) {
        // check if assortment detail already updated
        if(this.assortmentDetailsUpdatedMap.containsKey(item.Id)) {
            Assortment_Detail__c updatedAssortmentDetail = this.assortmentDetailsUpdatedMap.get(item.Id);
            item = updatedAssortmentDetail.clone(true);
        }
        return item;
    }
    
    public PageReference search() {
        // Check Assortment_Detail__c field security
        String[] assortmentDetailFields = new List<String>();
        for(String field : this.gridSettingsManager.ALL_FIELDS) {
            if(!field.contains('.')) assortmentDetailFields.add(getFieldName(field));
        }
        this.assortmentDetailStdSetCtrl = new ApexPages.StandardSetController(new List<Assortment_Detail__c>());
        if(checkAccessibility(Assortment_Detail__c.SObjectType, assortmentDetailFields)) {
            String query = this.buildAssortmentDetailQuery();
            this.assortmentDetailStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        }
        this.noOfRecords = assortmentDetailStdSetCtrl.getResultSize(); 
        assortmentDetailStdSetCtrl.setPageSize(this.pageSize);
        this.fillCategoryTotals();
        this.getHierarchies();
        this.jsonCategoryTree = JSON.serialize(this.categoryTreeMap.values());
        this.getAssortmentDetails();
        return null;
    }
    
    public void saveAndSearch() {
        this.save();
        this.search();
    }
    
    private List<AggregateResult> getCountByCategory(String fieldName) {
        String fieldName_escaped = String.escapeSingleQuotes(fieldName);
        String query = 'SELECT Category__c, COUNT(Id) ' + fieldName_escaped + ' FROM Assortment_Detail__c ';
        List<String> conditions = this.getConditions();
        conditions.add(fieldName_escaped + ' = TRUE');
        conditions.add('Version__c = NULL');
        if (!this.includeAllStatus) {
            String condition = 'Client_Status__c NOT IN (NULL, \'Opportunity\', \'Probably deleted\')';
            conditions.add(condition);
        }
        query += this.buildWhere(conditions);
        query += ' Group BY Category__c';
        return Database.query(query);
    }
        
    private void fillCategoryTotals() {
        this.categorySet.clear();
        this.counts.clear();
        this.sums.clear();
        this.categoryNamesMap.clear();
        
        List<String> sumAggregations = new List<String>();
        for (String field : this.fieldsToSumList) {
            String field_escaped = String.escapeSingleQuotes(field);
            sumAggregations.add('SUM(' + field_escaped + ') ' + field_escaped);
        }
        String aggregateQuery = 'SELECT Category__c Category__c';
        if (!sumAggregations.isEmpty()) aggregateQuery += ',' + String.join(sumAggregations, ',');
        aggregateQuery += ' FROM Assortment_Detail__c';
        List<String> conditions = this.getConditions();
        conditions.add('Version__c = NULL');
        if (!this.includeAllStatus) {
            String condition = 'Client_Status__c NOT IN (NULL, \'Opportunity\', \'Probably deleted\')';
            conditions.add(condition);
        }
        aggregateQuery += this.buildWhere(conditions);
        aggregateQuery += ' Group By Category__c';
        // to garantee that all categories are in counts and sums maps
        for (AggregateResult item : Database.query(aggregateQuery)) {
            Id categoryId = (Id) item.get('Category__c');
            initTotals(categoryId);
            Map<String, Decimal> categorySumMap = this.sums.get(categoryId);
            if (categorySumMap != null) {
                for (String fieldname : categorySumMap.keySet()) {
                    Decimal value = item.get(fieldname) != null ? Decimal.valueOf(String.valueOf((item.get(fieldname)))) : 0;
                    categorySumMap.put(fieldname, value);
                }
                this.categorySet.add(categoryId);
            }
        }
        // fill counts by category
        // querying counts (24 aggregate queries)
        List<Map<String, List<AggregateResult>>> aggregateMapList = new List<Map<String, List<AggregateResult>>>();
        String key;
        List<AggregateResult> value;
        
        for (String field : this.fieldsToCountList) {
            value = this.getCountByCategory(field/*, fieldAlias*/);
            aggregateMapList.add(new Map<String, List<AggregateResult>> {field => value});
        }
        
        for (Map<String, List<AggregateResult>> item : aggregateMapList) {
            for (String fieldname : item.keySet()) {
                for (AggregateResult ar : item.get(fieldname)) {
                    Id categoryId = (Id) String.valueOf(ar.get('Category__c'));
                    Map<String, Integer> categoryCountMap = this.counts.get(categoryId);
                    Integer count = ar.get(fieldname) != null ? Integer.valueOf(String.valueOf(ar.get(fieldname))) : 0;
                    categoryCountMap.put(fieldname, count);
                }
            }
        }
    }
    
    private void initTotals (Id categoryId) {
        Map<String, Integer> categoryCountMap = new Map<String, Integer>();
        Map<String, Decimal> categorySumMap = new Map<String, Decimal>(); 
        // initial Count fields
        for(String str : this.fieldsToCountList) {
            categoryCountMap.put(str, 0);
        }
        // initial Sums fields
        for(String str : this.fieldsToSumList) {
            categorySumMap.put(str, 0);
        }
        this.counts.put(categoryId, categoryCountMap);
        this.sums.put(categoryId, categorySumMap);
    }
    
    // Get category hierarchies
    public void getHierarchies() {
        this.categoryTreeMap = new Map<Id, CategoryTreeWrapper>();
        Map<Id, CategoryTreeWrapper> hierarchyTree = new Map<Id, CategoryTreeWrapper>();
        Map<Id, Orga_HE__c> parentCategories = new Map<Id, Orga_HE__c>();
        Set<Id> relatedCategoryIds = new Set<Id>();
        Map<Id, Id> parentChildMap = new Map<Id, Id>();
        if (!het.allElementsList.isEmpty()) {
            for (Orga_HE__c item : het.allElementsList) {
                fillParentCategoriesTotal(item.Parent_Element__c, item.Id);
            }
            // navigate inversely from top level
            Integer rootLevel = (Integer) het.allElementsList[het.allElementsList.size() - 1].Level__c;
            for (Integer i = het.allElementsList.size() - 1; i >= 0; i--) {
                Orga_HE__c item = het.allElementsList.get(i);
                CategoryTreeWrapper node = new CategoryTreeWrapper();
                CategoryTreeWrapper parentNode = hierarchyTree.get(item.Parent_Element__c);
                node.title = item.Level__c == rootLevel ? 'TOTAL' : item.Name;
                node.key = item.Id;
                node.folder = item.Level__c <= rootLevel + 1;
                node.counts = this.counts.get(item.Id);
                node.sums = this.sums.get(item.Id);
                if (parentNode != null) {
                    node.path = parentNode.path + '' + item.Id;
                    node.parentId = item.Parent_Element__c;
                } else {
                    node.path = item.Id;
                    this.categoryTreeMap.put(item.Id, node);
                }
                hierarchyTree.put(item.Id, node);
            }
            for (Orga_HE__c item : het.allElementsList) {
                if (hierarchyTree.containsKey(item.Parent_Element__c)) {
                    hierarchyTree.get(item.Parent_Element__c).children.add(hierarchyTree.get(item.Id));
                }
            }
        }
    }
    
    private void fillParentCategoriesTotal(Id parentCategoryId, Id subCategoryId) {
        if(!this.counts.containsKey(parentCategoryId)) {
            initTotals(parentCategoryId);
        }
        if(!this.counts.containsKey(subCategoryId)) {
            initTotals(subCategoryId);
        }
        // fill total sum
        Map<String, Decimal> parentCategorySumMap = this.sums.get(parentCategoryId);
        Map<String, Decimal> subCategorySumMap = this.sums.get(subCategoryId);
        for (String fieldname : parentCategorySumMap.keySet()) {
            Decimal total = parentCategorySumMap.get(fieldname) != null ? parentCategorySumMap.get(fieldname) : 0;
            Decimal value = subCategorySumMap.get(fieldname) != null ? subCategorySumMap.get(fieldname) : 0;
            parentCategorySumMap.put(fieldname, total + value);
        }
        // fill total count
        Map<String, Integer> parentCategoryCountMap = this.counts.get(parentCategoryId);
        Map<String, Integer> subCategoryCountMap = this.counts.get(subCategoryId);
        for (String fieldname : parentCategoryCountMap.keySet()) {
            Integer total = parentCategoryCountMap.get(fieldname) != null ? parentCategoryCountMap.get(fieldname) : 0;
            total = total + (subCategoryCountMap.get(fieldname) != null ? subCategoryCountMap.get(fieldname) : 0);
            parentCategoryCountMap.put(fieldname, total);
        }
    }
    
    @RemoteAction
    public static Assortment_Detail__c evaluateAssortmentDetail(Assortment_Detail__c evaluateAssortmentDetail, String fieldsToSum_serialized) {
        List<String> fieldsToSum = (List<String>) JSON.deserialize(fieldsToSum_serialized, List<String>.class);
        SavePoint sp = Database.setSavepoint();
        evaluateAssortmentDetail.Force_Update__c = true;
        update evaluateAssortmentDetail;
        String query = 'SELECT Id, Product__c, Category__c, Assortment_BU__c';
        if (!fieldsToSum.isEmpty()) {
            query += ',' + String.join(fieldsToSum, ',');
        }
        query += ' FROM Assortment_Detail__c';
        query += ' WHERE Id = \'' + evaluateAssortmentDetail.Id + '\'';
        Assortment_Detail__c evaluationResults = Database.query(query);
        Database.rollback(sp);
        return evaluationResults;
    }
    
    /**
     * @description switch single of multiple products
     * @return PageReference : Null
    */    
    public void switchProduct() {
        List<Assortment_Detail__c> toUpdateList = new List<Assortment_Detail__c>();
        for (SwitchProductWrapper item : switchProductsList) {
            if (item.isSelected) {
                item.assortmentDetail.Product__c = item.newProductId;
                toUpdateList.add(item.assortmentDetail);
            }
        }
        try {
            // check security on update Assortment_Detail__c
            String[] assortmentDetailFields = new String[] {getFieldName('Product__c')};
            if(checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields)) {
                update toUpdateList;
            }
            // To auto display history lines after switch product
            isShowHistory = true;
            this.search();
        } catch (Exception ex) {}
    }
    
    /**
     * @description stop a product in the assortment
    */
    public void stopProducts() {
        List<Product_Assortment_Introduction_History__c> historyList = new List<Product_Assortment_Introduction_History__c>();
        for (StopProductWrapper item : stopProductsList) {
            if (item.isSelected) {
                item.history.Load_Status__c = 'Yes';
                item.history.Application_Date__c = Date.today();
                historyList.add(item.history);
            }
        }
        try {
            // check security on update Product_Assortment_Introduction_History__c
            String[] productHistoryFields = new String[] {getFieldName('Load_Status__c'), getFieldName('Application_Date__c')};
            if(checkUpdatibility(Product_Assortment_Introduction_History__c.SObjectType, productHistoryFields)) {
                update historyList;
            }
            isShowHistory = true;
            this.search();
        } catch (DMLException ex) {
        }
    }
    
    
    public PageReference showPopup() {
        
        if (this.popupSwitchProduct) {
            switchProductsList.clear();
            Map<Id, Assortment_Detail__c> productAssortmentMap = new Map<Id, Assortment_Detail__c>();
            if (!singleProductAction) {
                String query = 'SELECT Product__c, Client_Status__c, Status__c, Movement_Date__c';
                query += ' FROM Assortment_Detail__c';
                List<String> conditions = this.getConditions();
                conditions.add('Product__r.Product_Reference_Type__c = \'Switch\'');
                conditions.add('Version__c = NULL');
                query += this.buildWhere(conditions);
                for (Assortment_Detail__c assortmentDetail : Database.query(query)) {
                    productAssortmentMap.put(assortmentDetail.Product__c, assortmentDetail);
                }
            } else {
                if (!assortmentDetailWrapperMap.containsKey(assortmentDetailCategory)) return null;
                Assortment_Detail__c assortmentDetail;
                AssortmentDetailWrapper adw = assortmentDetailWrapperMap.get(assortmentDetailCategory);
                for (Assortment_Detail__c item : adw.assortmentDetails) {
                    if (item.Id == this.assortmentDetailId) {
                        assortmentDetail = item;
                        break;
                    }
                }
                productAssortmentMap.put(assortmentDetail.Product__c, assortmentDetail);
                for (Schema.PicklistEntry pe: this.productReferenceTypePicklistValues) {
                    if (pe.getValue().equals(assortmentDetail.Product__r.Product_Reference_Type__c)) {
                        this.popupTitle = pe.getLabel();
                    }
                }
            }
            for (Product2 item : [SELECT Name, Reference_Product__c, Reference_Product__r.Name
                                  FROM Product2
                                  WHERE Reference_Product__c IN :productAssortmentMap.keySet()
                                  ORDER BY Category__r.Name, Name ASC])
                switchProductsList.add(new SwitchProductWrapper(item.Reference_Product__r.Name, item.Id, item.Name, productAssortmentMap.get(item.Reference_Product__c)));
        }
        
        if (this.popupStopProduct) {
            stopProductsList.clear();
            Set<Id> productsIdSet = new Set<Id>();
            if (this.singleProductAction) {
                String query = 'SELECT Product__c FROM Assortment_Detail__c';
                List<String> conditions = this.getConditions();
                conditions.add('Product__r.Market_End_of_Life_Date__c <> NULL');
                conditions.add('Client_Status__c <> \'Delete\'');
                conditions.add('Version__c = NULL');
                query += this.buildWhere(conditions);
                for (Assortment_Detail__c item : Database.query(query))
                    productsIdSet.add(item.Product__c);
            } else {
                productsIdSet.add(productToStopId);
            }
            for (Product_Assortment_Introduction_History__c item : [SELECT Load_Status__c, Load_Rules__c, Product__c, BU_Target__c
                                                                    FROM Product_Assortment_Introduction_History__c
                                                                    WHERE Product__c IN :productsIdSet
                                                                    AND RecordType.DeveloperName = 'Stop'
                                                                    AND BU_Target__c = :this.assortmentBU.BU_Target__c]) 
            {
                stopProductsList.add(new StopProductWrapper(item));
            }
        }
        
        return null;
    }

    public PageReference cancelPopup() {
        this.popupGenerateExcel = false;
        return null;
    }
    
    public PageReference send() {
        String[] toList = getEmailAddresses(emailTo);
        String[] ccList = getEmailAddresses(emailCc);
        String[] bccList = getEmailAddresses(emailBcc);
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
        Integer oldPageSize = this.pageSize;
        Integer oldPageNumber = assortmentDetailStdSetCtrl.getPageNumber();
        PageReference pageRef = this.generateExcel();
        if (pageRef != null) {
            // save attachement
            String descriptionText = 'Email\nto :' + String.join(toList, ';') + '\n';
            descriptionText += 'cc :' + String.join(ccList, ';') + '\n';
            descriptionText += 'bcc :' + String.join(bccList, ';') + '\n';
            descriptionText += 'subject :' + emailSubject + '\n';
            descriptionText += 'body :' + emailBody + '\n';
            
            Attachment attachmentExcel = new Attachment(ParentId = recordId, Name = this.assortmentBUName + '_'+ system.now() + '.xls',
                                                        ContentType = 'application/vnd.ms-excel', Body = pageRef.getContent(),
                                                        Description = descriptionText);
            // check security on insert attachment fields
            String[] attachmentCreateFields = new String[]{ 'Name', 'Body', 'ParentId', 'ContentType', 'Description' };
            if(NegoptimHelper.checkCreatibility(Attachment.SObjectType, attachmentCreateFields)) {
                Database.insert(attachmentExcel);
            }
            
            email_att.setBody(pageRef.getContent());
            email_att.setContentType('application/vnd.ms-excel');
            email_att.setFileName(assortmentBUName + '_'+ system.now() + '.xls');
            email_att.setinline(false);
            emailAttachments.add(email_att);
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSenderDisplayName('NegOptim');
            email.setToAddresses(toList);
            email.setCcAddresses(ccList);
            email.setBccAddresses(bccList);
            email.setFileAttachments(emailAttachments);
            email.setSubject(emailSubject);
            email.setHtmlBody(emailBody);
            
            if(Limits.getEmailInvocations() >= Limits.getLimitEmailInvocations()) {
                this.popupGenerateExcel = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Single Email Limit Exceeded. Cannot send this email'));
                return null;
            }
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});    
            } catch (System.EmailException ex) {
                this.popupGenerateExcel = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Single Email Limit Exceeded. Cannot send this email'));
                return null;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Successfully Send Email.'));
            this.popupGenerateExcel = false;
        }
        this.pageSize = oldPageSize;
        assortmentDetailStdSetCtrl.setPageSize(this.pageSize);
        assortmentDetailStdSetCtrl.setPageNumber(oldPageNumber);
        getAssortmentDetails();
        return null;
    }

   /**
    * allow user to enter multiple email addresses seperated by ',' or ';'
    */
    private String[] getEmailAddresses(String source) {
        if (source == null || String.isEmpty(source)) {
            return new String[]{};
        }
        source = source.remove(' ');
        source = source.replaceAll(',', ';');
        return source.split(';');
    }
        
    // generate Excel
    public PageReference generateExcel() {
        try {
            if(recordId == null) return null;
            PageReference pageRef = Page.AssortmentBUMatrixExcel;
            pageRef.setRedirect(false);
            this.pageSize = this.noOfRecords;
            this.search();
            return pageRef;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getMessage()));
            return null;
        }
    }
    
    /** Wrapper class for Category Tree. */
    public class CategoryTreeWrapper {
        private String title;
        private String key;
        private boolean folder;
        private String path;
        private String parentId {get; set;}
        private List<CategoryTreeWrapper> children {get; set;}
        private Map<String, Integer> counts {get; set;}
        private Map<String, Decimal> sums {get; set;}
        
        public CategoryTreeWrapper() {
            this.children = new List<CategoryTreeWrapper>();
            this.counts = new Map<String, Integer>();
            this.sums = new Map<String, Decimal>();
        }
    }

    /** Wrapper class for Assortment Detail. */
    public class AssortmentDetailWrapper {
        public Id categoryId {get; set;}
        public String categoryName {get; set;}
        public List<Assortment_Detail__c> assortmentDetails {get; set;}

        public AssortmentDetailWrapper(Id categoryId, String categoryName, Assortment_Detail__c item) {
            this.categoryId = categoryId;
            this.categoryName = categoryName;
            if (item.record_date__c == null) item.record_date__c = Date.valueOf(item.CreatedDate);
            this.assortmentDetails = new List<Assortment_Detail__c>{item};
        }
    }
        
    public class SwitchProductWrapper {
        public String currentProduct {get; set;}
        private Id newProductId;
        public String newProduct {get; set;}
        public Assortment_Detail__c assortmentDetail {get; set;}
        public Boolean isSelected {get; set;}
        
        public SwitchProductWrapper(String currentProduct, Id newProductId, String newProduct, Assortment_Detail__c assortmentDetail) {
            this.currentProduct = currentProduct;
            this.newProductId = newProductId;
            this.newProduct = newProduct;
            this.assortmentDetail = assortmentDetail;
            this.isSelected = true;
        }
    }
    
    public class StopProductWrapper {
        public Product_Assortment_Introduction_History__c history {get; set;}
        public Boolean isSelected {get; set;}
        
        public StopProductWrapper(Product_Assortment_Introduction_History__c history) {
            this.history = history;
            this.isSelected = true;
        }
    }
    
    public class ClientStatusWrapper {
        
        public Id assortmentBUId {get; set;}
        public Id assortmentDetailId {get; set;}
        public Id categoryId {get; set;}
        public String clientStatus {get; set;}
        public Boolean clientAssortment {get; set;}
        public Boolean[] clientClusters {get; set;}
        public Boolean[] corpClusters {get; set;}
        public Integer strat {get; set;}
        public Integer buClustersCount {get; set;}
        //last history
        public Boolean hasLastHistory {get; set;}
        // last valid
        public String lastValidClientStatus {get; set;}
        public Integer lastValidStratCount {get; set;}
        
        public ClientStatusWrapper(Assortment_Detail__c assortmentDetail, Integer buClustersCount, List<String> gridFields) {
            this.assortmentBUId = assortmentDetail.Assortment_BU__c;
            this.assortmentDetailId = assortmentDetail.Id;
            this.categoryId = assortmentDetail.Category__c;
            this.clientStatus = gridFields.contains('Client_Status__c') ? assortmentDetail.Client_Status__c : '';
            this.clientAssortment = gridFields.contains('Client_Ass__c') ? assortmentDetail.Client_Ass__c : false;
                       
            this.clientClusters = new List<Boolean>();
            this.corpClusters = new List<Boolean>();
            this.strat = 0;
            this.buClustersCount = buClustersCount;
            Boolean clientCluster;
            Assortment_Detail__c lastHistory = String.isNotBlank(assortmentDetail.Last_History__c) ? assortmentDetail.Last_History__r : assortmentDetail.Ref_Client_Assortment__r;
            this.hasLastHistory = String.isNotBlank(assortmentDetail.Last_History__c) || String.isNotBlank(assortmentDetail.Ref_Client_Assortment__c);
            this.lastValidStratCount = 0;
            for (Integer i = 1; i <= 6; i++) {
                if (i <= buClustersCount) {
                    clientCluster = gridFields.contains('Client_Clust' + i + '__c') ? (Boolean) assortmentDetail.get('Client_Clust' + i + '__c') : false;
                    this.clientClusters.add(clientCluster);
                    if (this.strat == 0 && clientCluster) {
                        this.strat = i;
                    }
                }
                if (assortmentDetail.Status__c == 'Validated') {
                    this.lastValidStratCount += (Boolean) assortmentDetail.get('Client_Clust' + i + '__c') ? 1 : 0;
                } else if (this.hasLastHistory) {
                    this.lastValidStratCount += (Boolean) lastHistory.get('Client_Clust' + i + '__c') ? 1 : 0;
                }
                Boolean corpCluster = gridFields.contains('Corp_Clust' + i + '__c') ? (Boolean) assortmentDetail.get('Corp_Clust' + i + '__c') : false;
                this.corpClusters.add(corpCluster);
            }
            if (assortmentDetail.Status__c == 'Validated') {
                this.lastValidClientStatus = assortmentDetail.Client_Status__c;
            } else if (this.hasLastHistory) {
                this.lastValidClientStatus = lastHistory.Client_Status__c;
            }
            
        }
    }
    
    public class BUClusterWrapper {
        public Orga_BU__c orgaBU {get; set;}
        public Integer stratIndex {get; set;}
        
        public BUClusterWrapper (Orga_BU__c orgaBU) {
            this.orgaBU = orgaBU;
            this.stratIndex = orgaBU == null ? 0 : Integer.valueOf(orgaBU.Assortment_Strat__c.right(1));
        }
    }
    
    public enum ClusterType {REF_CLIENT, NEW_CLIENT} // TODO: When nessecary add REF_CORP, NEW_CORP
    
    public class ColumnWrapper {
        
        public Component.Apex.Column getColumn(GridSettingsManager.FieldWrapper fieldWrapper, Boolean hasFooter) {
            
            Component.Apex.Column column = new Component.Apex.Column();
            column.headerClass = 'text-center';
            column.expressions.styleClass = 'text-center {!IF(item["Version__c"] != NULL, "history", "")}';
            column.headerValue = fieldWrapper.fieldLabel;
            if (String.isNotBlank(fieldWrapper.bgColor)) {
                column.style = 'background-color: ' + fieldWrapper.bgColor + ' !important;';
            }
            // case product__c
            if (fieldWrapper.fieldName.equalsIgnoreCase('product__c')) {
                column.headerClass += ' productName';
                column.expressions.styleClass += ' productName';
                column.expressions.styleClass += '{!IF(OR(item.Product__r.IsInnovation__c, item.Product__r.recordType.developerName == "Unit_Need")," innoProduct", "")}';
                column.expressions.styleClass += '{!IF(AND(item.Product__r.Market_End_of_Life_Date__c!=null, YEAR(item.Product__r.Market_End_of_Life_Date__c) <= Assortment_BU__c.Year__c), " stopProduct", "")}';

                
                Component.Apex.OutputText versionText = new Component.Apex.OutputText();
                versionText.expressions.value ='{!$Label.Version}{!item["Version__c"]}: ';
                versionText.expressions.rendered = '{!!ISNULL(item["Version__c"])}';
                
                Component.Apex.OutputField output = new Component.Apex.OutputField();
                output.expressions.value = '{!item.' + fieldWrapper.fieldName + '}';
                
                // conponent for switchIcon
                Component.Apex.OutputLink switchIcon = new Component.Apex.OutputLink();
                List<String> renderConditions = new List<String> {'initialAssortmentDetailsMap[item.Id]["Product__r"]["Product_Reference_Type__c"] == "Switch"',
                    'OR(ISNULL(initialAssortmentDetailsMap[item.Id]["Product__r"]["Market_End_of_Life_Date__c"]), YEAR(initialAssortmentDetailsMap[item.Id]["Product__r"]["Market_End_of_Life_Date__c"]) > Assortment_BU__c.Year__c)',
                    'ISNULL(item["Version__c"])'
                };
                switchIcon.expressions.rendered = '{!AND(' + String.join(renderConditions, ',') + ')}';
                switchIcon.expressions.onclick = 'showSingleSwitchPopup(true, "{!item.Id}", "{!item.Category__c}", true); return false;';
                Component.Apex.OutputText switchIconText = new Component.Apex.OutputText();
                switchIconText.value = '<span class="switchIcon">';
                switchIconText.value += '</span>';
                switchIconText.escape = false;
                // conponent for stopIcon
                Component.Apex.OutputLink stopIcon = new Component.Apex.OutputLink();
                renderConditions = new List<String> {'!ISNULL(initialAssortmentDetailsMap[item.Id]["Product__r"]["Market_End_of_Life_Date__c"])',
                    'YEAR(initialAssortmentDetailsMap[item.Id]["Product__r"]["Market_End_of_Life_Date__c"]) <= Assortment_BU__c.Year__c',
                    'ISNULL(item["Version__c"])'
                };
                stopIcon.expressions.rendered = '{!AND(' + String.join(renderConditions, ',') + ')}'; 
                stopIcon.onclick = 'return false;';
                Component.Apex.OutputText stopIconText = new Component.Apex.OutputText();
                stopIconText.value = '<span class="stopIcon">';
                stopIconText.value += '</span>';
                stopIconText.escape = false;
                // conponent for renoIcon
                Component.Apex.OutputLink renoIcon = new Component.Apex.OutputLink();
                renderConditions = new List<String> {'initialAssortmentDetailsMap[item.Id]["Product__r"]["Product_Reference_Type__c"] == "Reno"',
                    'OR(ISNULL(initialAssortmentDetailsMap[item.Id]["Product__r"]["Market_End_of_Life_Date__c"]), YEAR(initialAssortmentDetailsMap[item.Id]["Product__r"]["Market_End_of_Life_Date__c"]) > Assortment_BU__c.Year__c)',
                    'ISNULL(item["Version__c"])'
                };
                renoIcon.expressions.rendered = '{!AND(' + String.join(renderConditions, ',') + ')}';
                renoIcon.expressions.onclick = 'showSingleSwitchPopup(true, "{!item.Id}", "{!item.Category__c}", true); return false;';
                Component.Apex.OutputText renoIconText = new Component.Apex.OutputText();
                renoIconText.value = '<span class="renoIcon">';
                renoIconText.value += '</span>';
                renoIconText.escape = false;
                
                switchIcon.childComponents.add(switchIconText);
                stopIcon.childComponents.add(stopIconText);
                renoIcon.childComponents.add(renoIconText);
                
                column.childComponents.add(versionText);
                column.childComponents.add(output);
                column.childComponents.add(renoIcon);
                column.childComponents.add(switchIcon);
                column.childComponents.add(stopIcon);
            }
            // case product__r.field__c TODO: remove this case and make use of field Describe to get field parent SObject
            else if (fieldWrapper.fieldName.containsIgnoreCase('product__r')) {
                String fieldName = fieldWrapper.fieldName.split('\\.')[1];
                column.headerClass += fieldWrapper.fieldName.containsIgnoreCase('product_ean__c') ? ' productEAN' : ' col1';
                column.expressions.value = '{!item.Product__r.' + fieldName + '}';
            }
            // all other cases
            else {
                column.headerClass += ' col';
                Component.Apex.InputField input = new Component.Apex.InputField();
                Component.Apex.OutputField output = new Component.Apex.OutputField();
                // formula fields are rendered as span without the class attribute
                // using an outputText in case field insures the class attribute is rendered
                Component.Apex.OutputText outputFormula = new Component.Apex.OutputText();
                outputFormula.escape = false;
                // adding border class to column headerClass and column styleClass
                if (fieldWrapper.isBorderColumn) {
                    column.headerClass += ' border-col';
                    column.expressions.styleClass += ' border-col';
                }
                
                input.expressions.value = '{!item.' + fieldWrapper.fieldName + '}';
                input.expressions.styleClass = 'inputNoEnter {!item.Id}_' + fieldWrapper.fieldName;
                if (fieldWrapper.fieldType == DisplayType.Double || fieldWrapper.fieldType == DisplayType.Integer || fieldWrapper.fieldType == DisplayType.Long
                    || fieldWrapper.fieldType == DisplayType.Percent || fieldWrapper.fieldType == DisplayType.Currency)
                    input.style = 'text-align: right;';
                input.expressions.rendered = '{!item["Version__c"] == NULL && !readOnly}';
                
                output.expressions.value = '{!item.' + fieldWrapper.fieldName + '}';
                output.expressions.rendered = '{!item["Version__c"] <> NULL || readOnly}';
                
                if (fieldWrapper.fieldType == DisplayType.Double || fieldWrapper.fieldType == DisplayType.Integer || fieldWrapper.fieldType == DisplayType.Long
                    || fieldWrapper.fieldType == DisplayType.Percent || fieldWrapper.fieldType == DisplayType.Currency)
                    outputFormula.expressions.value = '{!ROUND(item.' + fieldWrapper.fieldName +' ,' + fieldWrapper.scale + ')}';
                else
                    outputFormula.expressions.value = '{!item.' + fieldWrapper.fieldName + '}';
                outputFormula.expressions.styleClass = ' {!item.Id}_' + fieldWrapper.fieldName;
                if (fieldWrapper.fieldType == DisplayType.Double || fieldWrapper.fieldType == DisplayType.Integer || fieldWrapper.fieldType == DisplayType.Long
                    || fieldWrapper.fieldType == DisplayType.Percent || fieldWrapper.fieldType == DisplayType.Currency)
                {
                    outputFormula.expressions.styleClass += ' formatNumber-' + fieldWrapper.fieldName;
                }
                outputFormula.expressions.rendered = '{!AND (item["Version__c"] == NULL, !readOnly)}';
                
                if (hasFooter) {
                    column.expressions.footerClass='text-center {!group.categoryId}' + fieldWrapper.fieldName;
                    if (fieldWrapper.fieldType == DisplayType.Boolean) {
                        column.expressions.footerValue = '{!categoryCountMap["' + fieldWrapper.fieldName + '"]}';
                        // register onchange event to recalculate totals
                        input.expressions.onchange = ' calculateTotal("' + fieldWrapper.fieldName + '","{!item.Id}", "{!group.categoryId}", "{!item.Assortment_BU__c}");';
                    } else {
                        Component.Apex.OutputText footerText = new Component.Apex.OutputText(); 
                        if (fieldWrapper.fieldType == DisplayType.Double || fieldWrapper.fieldType == DisplayType.Integer || fieldWrapper.fieldType == DisplayType.Long
                            || fieldWrapper.fieldType == DisplayType.Percent || fieldWrapper.fieldType == DisplayType.Currency)
                        {
                            footerText.expressions.value = '{!ROUND(categorySumMap["' + fieldWrapper.fieldName + '"]' +' ,' + fieldWrapper.scale + ')}';
                            footerText.styleClass = 'formatNumber-' + fieldWrapper.fieldName;
                        }
                        column.facets.footer = footerText;
                        input.expressions.styleClass += ' numberInput';
                        // different than checkbox method
                        input.expressions.onchange = 'calculateTotal("' + fieldWrapper.fieldName + '","{!item.Id}", "{!group.categoryId}", "{!item.Assortment_BU__c}");';
                        // add hidden input to keep first loaded value
                        Component.Apex.OutputText hidden = new Component.Apex.OutputText();
                        hidden.expressions.styleClass = '{!item.Id}initial' + fieldWrapper.fieldName;
                        hidden.expressions.value = '{!IF(item["' + fieldWrapper.fieldName + '"] == null, 0, item["' + fieldWrapper.fieldName + '"])}';
                        hidden.style = 'display:none';
                        column.childComponents.add(hidden);
                    }
                }
                
                // adding item Id as a class for fields with color highlight
                if (fieldWrapper.fieldName.equalsIgnoreCase('Ref_Client_Ass__c') 
                    || fieldWrapper.fieldName.equalsIgnoreCase('Client_Ass__c')
                    || fieldWrapper.fieldName.equalsIgnoreCase('Ref_Client_ProductNumber__c')
                    || fieldWrapper.fieldName.equalsIgnoreCase('New_Client_ProductNumber__c')
                    || fieldWrapper.fieldName.equalsIgnoreCase('Client_status__c')
                    || fieldWrapper.fieldName.equalsIgnoreCase('Key_Note__c'))
                {
                    column.expressions.styleClass += ' {!item.Id}';
                    column.style = '';
                }
                if (fieldWrapper.fieldName.equalsIgnoreCase('Ref_Client_Ass__c') 
                    || fieldWrapper.fieldName.equalsIgnoreCase('Ref_Client_ProductNumber__c'))
                {
                    column.expressions.styleClass = 'text-center highlight-ref {!IF(item["Version__c"] != NULL, "history", "")}';
                }
                
                // case mouvement date - add Id and register onchange event to update release date
                if (fieldWrapper.fieldName.equalsIgnoreCase('Movement_Date__c')) {
                    input.id = 'movementDateField';
                    input.onchange='setReleaseDate(this)';
                }
                // case release date - add Id
                if (fieldWrapper.fieldName.equalsIgnoreCase('Release_Date__c')) {
                    input.id = 'release-date';
                }
                // case client status
                if (fieldWrapper.fieldName.equalsIgnoreCase('Client_Status__c')) {
                    column.expressions.styleClass += ' clientStatus_col {!item.Id}_Client_Status__col';
                    input.expressions.styleClass += ' clientStatus';
                    input.expressions.onchange = ' toggleCheckboxes(this, "{!item.Id}", "clientStatus"); handleClientStatusColors();';
                }
                // case client ass
                if (fieldWrapper.fieldName.equalsIgnoreCase('Client_Ass__c')) {
                    input.expressions.onchange += ' toggleCheckboxes(this, "{!item.Id}","clientAss");';
                }
                if (fieldWrapper.fieldName.startsWithIgnoreCase('Corp_Clust')) {
                    Integer index = Integer.valueOf(fieldWrapper.fieldName.removeEnd('__c').removeStartIgnoreCase('Corp_Clust'));
                    input.expressions.onchange += ' toggleCheckboxes(this, "{!item.Id}", "corpClust", ' + index + ');';
                }
                if ((fieldWrapper.isCalculated && fieldWrapper.fieldType != DisplayType.Boolean)
                    || (!fieldWrapper.isInputField && fieldWrapper.fieldType != DisplayType.Boolean))
                {
                    column.childComponents.add(outputFormula);
                } else if ((fieldWrapper.isCalculated && fieldWrapper.fieldType == DisplayType.Boolean) || fieldWrapper.isInputField) {
                    column.childComponents.add(input);
                }
                column.childComponents.add(output);
            }
            return column;
        }
        
        public Component.Apex.Repeat getClientClusters(String clusterType, Integer clusterNameLength) {
            Component.Apex.Repeat clientClustersRepeat = new Component.Apex.repeat();
            clientClustersRepeat.expressions.value = '{!categoryBUClustersMap[group.categoryId]}';
            clientClustersRepeat.var = 'buCluster';
            Component.Apex.Column column = new Component.Apex.Column();
            column.expressions.styleClass = 'text-center {!item.id} {!IF(item["Version__c"] != NULL, "history", "")}';
            column.headerClass = 'text-center checkbox';
            column.style = 'min-width:'+ (clusterNameLength * 6) + 'px';
            
            Component.Apex.OutputLink header = new Component.Apex.OutputLink();
            header.expressions.value = '/{!buCluster.orgaBU.Id}';
            header.target = '_blank';
            header.expressions.rendered = '{!buCluster.orgaBU != null}';
            Component.Apex.OutputText headerText = new Component.Apex.OutputText();
            headerText.expressions.value = '{!buCluster.orgaBU.Name}';
            header.childComponents.add(headerText);
            column.facets.header = header;
            
            if (clusterType.equals('new')) {
                
                column.footerClass = 'text-center';
                Component.Apex.OutputPanel panel = new Component.Apex.OutputPanel();
                panel.expressions.rendered = '{!buCluster.orgaBU != null}';
                Component.Apex.OutputText hiddenText = new Component.Apex.OutputText();
                hiddenText.style = 'display: none;';
                hiddenText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"", group.categoryId + "Client_Clust"&TEXT(buCluster.stratIndex+1) + "__c")}';
                hiddenText.expressions.value = '{!categoryCountMap["Client_Clust"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                Component.Apex.OutputText visibleText = new Component.Apex.OutputText();
                visibleText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"","text-center visible_" + group.categoryId + "Client_Clust"&TEXT(buCluster.stratIndex+1) + "__c")}';
                visibleText.value = '0';
                panel.childComponents.add(hiddenText);
                panel.childComponents.add(visibleText);
                column.facets.footer = panel;
                
                Component.Apex.InputField input = new Component.Apex.InputField();
                input.expressions.value = '{!item["Client_Clust"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                input.expressions.styleClass = '{!item.Id}_Client_Clust{!(buCluster.stratIndex+1)}__c';
                input.expressions.rendered = '{!AND(item["Version__c"] == NULL, buCluster.orgaBU != null, !readOnly)}';
                input.expressions.onchange = 'toggleCheckboxes(this, "{!item.Id}", "clientClust", {!TEXT(buCluster.stratIndex+1)});';
                Component.Apex.OutputField output = new Component.Apex.OutputField();
                output.expressions.value= '{!item["Client_Clust"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                output.expressions.rendered = '{!AND(OR(item["Version__c"] <> NULL, readOnly), buCluster.orgaBU != null)}';
                
                column.childComponents.add(input);
                column.childComponents.add(output);
            }
            else if (clusterType.equals('ref')) {
                column.expressions.styleClass = 'text-center highlight-ref {!IF(item["Version__c"] != NULL, "history", "")}';
                column.footerClass = 'text-center';
                Component.Apex.OutputPanel panel = new Component.Apex.OutputPanel();
                panel.expressions.rendered = '{!buCluster.orgaBU != null}';
                Component.Apex.OutputText hiddenText = new Component.Apex.OutputText();
                hiddenText.style = 'display: none;';
                hiddenText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"", group.categoryId + "Ref_Client_Clust"&TEXT(buCluster.stratIndex+1) + "__c")}';
                hiddenText.expressions.value = '{!categoryCountMap["Ref_Client_Clust"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                Component.Apex.OutputText visibleText = new Component.Apex.OutputText();
                visibleText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"","text-center visible_" + group.categoryId + "Ref_Client_Clust"&TEXT(buCluster.stratIndex+1) + "__c")}';
                visibleText.value = '0';
                panel.childComponents.add(hiddenText);
                panel.childComponents.add(visibleText);
                column.facets.footer = panel;
                Component.Apex.OutputField output = new Component.Apex.OutputField();
                output.expressions.value= '{!item["Ref_Client_Clust"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                output.expressions.rendered = '{!buCluster.orgaBU != null}';
                column.childComponents.add(output);
            }
            clientClustersRepeat.childComponents.add(column);
            return clientClustersRepeat;
        }
    }
}