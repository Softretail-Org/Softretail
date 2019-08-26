/**
 * @description controller for pages ProductAssortmentIntroduction and MassProductsStop
*/
public with sharing class MassProductsActionController extends NegoptimBaseController {
    // logged in user Id
    private Id loggedUser = UserInfo.getUserId();
    private String recordType;
    private Map<Id, String> categoryPathMap = new Map<Id, String>();
    
    // fields to display from settings
    private final String OBJECT_NAME = 'Product_Assortment_Introduction_History__c';
    private String staticFields;
    private NegoptimSettings settings;
    public GridSettingsManager gridSettingsManager {get; set;}
    
    // filter fields
    public List<SelectOption> loadRulesPicklist {get; set;}
    public String dateFilter {get; set;} // was searchParam in intro page
    public String selectedLoadRule {get; set;}
    public String searchString {get; set;}
    public List<SelectOption> buFormats {get; set;} // filter by bu targer format origin
    public String selectedBuFormat {get; set;}
    public List<SelectOption> level1HEs {get; set;} // filter by level 1 categories (on BU and Products)
    public Id selectedLevel1HE {get; set;}
    public List<SelectOption> clients {get; set;}
    public Id selectedClient {get; set;}
    
    // pagination fields
    public ListIterable productIntroHistoryListCtrl {get; set;}
    public Integer pageSize {get; set;}
    public Integer noOfRecords {get; set;}
    public List<SelectOption> paginationSizeOptions {get; set;}
    
    // Map<Product__c + BU_Target__c, product intro> initial product intro
    public Map<String, Product_Assortment_Introduction_History__c> initialProductIntroHistoryMap {get; set;}
    // Map<Product__c + BU_Target__c, product intro> updated product intro
    public Map<String, Product_Assortment_Introduction_History__c> updatedProductIntroHistoryMap {get; set;}
    public List<AggregateResult> productIntroHistoryAggregateResultList {get; set;}
    public List<List<ProductIntroHistoryWrapper>> productIntroHistoryWrappersByCategoryList {get; set;}
    public Map<Id, BUWrapper> assortmentBUsMap {get; set;}
       
    // sorting fields
    public String orderDirection {get; set;}
    public String orderField {get; set;}

    public MassProductsActionController() {
        // get load rules values
        this.loadRulesPicklist = new List<SelectOption>();
        Schema.DescribeFieldResult loadRulesFields = Product_Assortment_Introduction_History__c.Load_Rules__c.getDescribe();
        for (Schema.PicklistEntry pv : loadRulesFields.getPicklistValues())
            this.loadRulesPicklist.add(new SelectOption(pv.getValue(), pv.getLabel()));
        // default filter values
        dateFilter = Label.All_History;
        // Formats for BU Targets
        this.buFormats = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Orga_BU__c.Format_Origin__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            this.buFormats.add(new SelectOption(pickListVal.value, pickListVal.label));
        }
        this.buFormats.add(new SelectOption(Label.LBL_All, Label.LBL_All));
        this.selectedBuFormat = this.buFormats[0].getValue();
        // Level 1 Categories
        this.level1HEs = new List<SelectOption>();
        for (Orga_HE__c level1HE : [SELECT Id, Name, Path__c FROM Orga_HE__c WHERE Level__c = 1 AND Status__c = 'Active']) {
            this.level1HEs.add(new SelectOption(level1HE.Id, level1HE.Name));
            this.categoryPathMap.put(level1HE.Id, level1HE.Path__c);
        }
        if (!this.level1HEs.isEmpty())
            this.selectedLevel1HE = this.level1HEs[0].getValue();
        // clients
        this.clients = new List<SelectOption>();
        for (Sup_Supplier__c client : [SELECT Id, Name FROM Sup_Supplier__c WHERE Status__c = 'Active']) {
            this.clients.add(new SelectOption(client.Id, client.Name));
        }
        if (!this.clients.isEmpty())
            this.selectedClient = this.clients[0].getValue();
        selectedLoadRule = loadRulesFields.getPicklistValues()[0].getValue();
        // fill pagination size options select list
        this.paginationSizeOptions = new List<SelectOption>();
        this.paginationSizeOptions.add(new SelectOption('10','10'));
        this.paginationSizeOptions.add(new SelectOption('25','25'));
        this.paginationSizeOptions.add(new SelectOption('50','50'));
        this.paginationSizeOptions.add(new SelectOption('100','100'));
        // default page size
        this.pageSize = 10;
        this.orderField = 'Name';
        this.orderDirection = 'ASC';
        // fill static fields
        this.staticFields = 'Id,Name,RecordTypeId,Load_Status__c,BU_Assortment__c,Application_Date__c,CreatedDate,BU_Target__c,Client__c,Load_Rules__c,Product_Market_Introduction_Date__c,Product_Type__c,';
        this.staticFields += 'Product_Market_End_of_Life_Date__c,Product_Creation_Date__c,Product_Category__c,Product_Brand__c,Product_EAN__c,Product_Code__c,Product_Code2__c,Product__c,Product__r.Name,';
        this.staticFields += 'Product__r.Retail_Price_Reco__c,Product__r.Average_Weekly_Sales_Hyper__c,Product__r.Average_Weekly_Sales_Super__c,Product__r.Logo__c,';
        this.staticFields += 'Product__r.Category__c,Product__r.Brand__c,Product__r.Keynote_Marketing__c,Product__r.Keynote_Administrative__c,Record_Date__c,BU_Target__r.Name';
        // load gloabal settings
        settings = GlobalSettingsManager.loadGlobalSettings();       
    }
        
    public void introAction() {
        this.initialProductIntroHistoryMap = new Map<String, Product_Assortment_Introduction_History__c>();
        this.updatedProductIntroHistoryMap = new Map<String, Product_Assortment_Introduction_History__c>();
        this.productIntroHistoryWrappersByCategoryList = new List<List<ProductIntroHistoryWrapper>>();
        this.recordType = 'Inno';
        // get fields from Grid Settings
        String metadataDeveloperName = settings.productInnoGridLayout;
        this.gridSettingsManager = new GridSettingsManager(OBJECT_NAME, this.staticFields, metadataDeveloperName);
        for (String errorMessage : this.gridSettingsManager.ERRORS) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }
        this.searchRecords();
    }
    
    public void stopAction() {
        this.initialProductIntroHistoryMap = new Map<String, Product_Assortment_Introduction_History__c>();
        this.updatedProductIntroHistoryMap = new Map<String, Product_Assortment_Introduction_History__c>();
        this.productIntroHistoryWrappersByCategoryList = new List<List<ProductIntroHistoryWrapper>>();
        this.recordType = 'Stop';
        // get fields from Grid Settings
        String metadataDeveloperName = settings.productStopGridLayout;
        this.gridSettingsManager = new GridSettingsManager(OBJECT_NAME, this.staticFields, metadataDeveloperName);
        for (String errorMessage : this.gridSettingsManager.ERRORS) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }
        this.searchRecords();
    }

    /**
     * @description
    */
    public void searchRecords() {
        if(this.gridSettingsManager.ERRORS.isEmpty()) {
            // load BU Target Formats
            List<String> selectedFormatsList = new List<String>();
            if (String.isNotBlank(this.selectedBuFormat))
                selectedFormatsList.addAll(String.escapeSingleQuotes(this.selectedBuFormat).split(','));
            // load target BU list
            this.assortmentBUsMap = new Map<Id, BUWrapper>();
            Map<Id, Orga_BU__c> targetBUMap = new Map<Id, Orga_BU__c>([SELECT Id, Name, Related_Client__c
                                                                       FROM Orga_BU__c WHERE Status__c = 'Open' AND Related_Client__c <> NULL
                                                                       AND OwnerId = :loggedUser AND RecordType.DeveloperName = 'Banner'
                                                                       AND Related_Client__r.Status__c = 'Active' AND Format_Origin__c IN :selectedFormatsList
                                                                       ////AND Category__c = :String.escapeSingleQuotes(this.selectedLevel1HE)
                                                                       ORDER BY Name]);
            if(!targetBUMap.isEmpty()) {
                for (Orga_BU__c item : targetBUMap.values()) {
                    this.assortmentBUsMap.put(item.Id, new BUWrapper(item));
                }
                for (Orga_BU_List_Detail__c child : [SELECT Entity__c, Entity_List__r.Id, Entity_List__r.Name, Entity_List__r.CurrencyIsoCode,
                                                     Entity_List__r.Business_Unit_Type__c, Entity_List__r.RecordTypeId, Entity_List__r.RecordType.DeveloperName
                                                     FROM Orga_BU_List_Detail__c
                                                     WHERE Entity__c IN :this.assortmentBUsMap.keySet()
                                                     AND Entity_List__r.Status__c = 'Open'
                                                     AND Entity_List__r.RecordType.DeveloperName = 'Assortment_Cluster'
                                                     ORDER BY Entity_List__r.Name])
                {
                    BUWrapper buWrapper = this.assortmentBUsMap.get(child.Entity__c);
                    buWrapper.assortmentBUOptions.add(new SelectOption(child.Entity_List__r.Id, child.Entity_List__r.Name));
                }
            }
            // Check Product_Assortment_Introduction_History__c field security
            String[] productIntroductionFields = new List<String>();
            for(String field : this.gridSettingsManager.ALL_FIELDS) {
                if(!field.contains('.')) productIntroductionFields.add(getFieldName(field));
            }
            List<AggregateResult> results = new List<AggregateResult>();
            if(checkAccessibility(Product_Assortment_Introduction_History__c.SObjectType, productIntroductionFields)) {
                String query = this.buildQuery();
                results = Database.query(query);
            }
            productIntroHistoryListCtrl = new ListIterable(results);
            if (results.size() > pageSize) {
                productIntroHistoryListCtrl.setPageSize = pageSize;
            } else {
                productIntroHistoryListCtrl.setPageSize = results.size();
            }
            this.noOfRecords = results.size();
            // fill results
            this.productIntroHistoryAggregateResultList = this.productIntroHistoryListCtrl.next();
            this.getRecords();
        }
    }
    
    /*public void reset() {
        this.searchString = '';
        this.searchRecords();
    }*/
    
    public Boolean getNoData() {
        return productIntroHistoryWrappersByCategoryList.isEmpty();
    }
    
    public void refreshPageSize() {
        this.productIntroHistoryAggregateResultList = this.productIntroHistoryListCtrl.setPageSize(pageSize);
        this.getRecords();
    }
    
    public void first() {
        this.productIntroHistoryAggregateResultList = this.productIntroHistoryListCtrl.first();
        this.getRecords();
    }
    
    public void next() {
        this.productIntroHistoryAggregateResultList = this.productIntroHistoryListCtrl.next();
        this.getRecords();
    }
    
    public void previous() {
        this.productIntroHistoryAggregateResultList = this.productIntroHistoryListCtrl.previous();
        this.getRecords();
    }
    
    public void last() {
        this.productIntroHistoryAggregateResultList = this.productIntroHistoryListCtrl.last();
        this.getRecords();
    }
        
    /**
     * @return String an aggregate query
     * @description the buildQuery method constructs a string aggregate query in order to group records by product, this way we make sure that all records
     * of the same product are displayed on the same page. Also this allows to controll page size
    */
    private String buildQuery() {
        String query = '';
        String whereClause = '', condition;
        query = 'SELECT Product__c ProductId';
        query += ' FROM Product_Assortment_Introduction_History__c';
        whereClause = this.buildWhere(whereClause, 'Product__c <> NULL AND BU_Target__c <> NULL AND Client__c <> NULL');
        // get records respecting ownership
        whereClause = this.buildWhere(whereClause, 'BU_Target__r.OwnerId = \'' + this.loggedUser + '\'');
        // get records by record type
        whereClause = this.buildWhere(whereClause, 'RecordType.DeveloperName = \'' + this.recordType + '\'');
        if(this.dateFilter == 'last_7_days') {
            DateTime d = System.today().addDays(-7);
            condition = this.recordType.equals('Inno') ? 'Product_Creation_Date__c  >= ' + d.format('yyyy-MM-dd') : 'Product_Market_End_of_Life_Date__c >= ' + d.format('yyyy-MM-dd');
            whereClause = buildWhere(whereClause, condition);
        } else if(this.dateFilter == 'last_60_days') {
            DateTime d = System.today().addDays(-60);
            condition = this.recordType.equals('Inno') ? 'Product_Creation_Date__c  >= ' + d.format('yyyy-MM-dd') : 'Product_Market_End_of_Life_Date__c >= ' + d.format('yyyy-MM-dd');
            whereClause = buildWhere(whereClause, condition);
        }
        //search string
        if (String.isNotBlank(this.searchString)) {
            condition = '((Product__r.Name LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\')';
            condition += ' OR (Product__r.ProductCode LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\')';
            condition += ' OR (Product__r.Product_EAN__c LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\')';
            condition += ' OR (Product__r.Category__r.Elt_Code__c LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\')';
            condition += ' OR (Product__r.Category__r.Name LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\'))';
            whereClause = buildWhere(whereClause, condition);
        }
        // category filter
        condition = 'Product__r.Category__r.Path__c LIKE \'' + categoryPathMap.get(selectedLevel1HE) + '%\'';
        whereClause = buildWhere(whereClause, condition);
        if (this.recordType.equals('Inno')) {
            // get records of record where product__c is NOT referenced
            condition = 'Product__r.Reference_Product__c = NULL';
            whereClause = this.buildWhere(whereClause, condition);
            // restrict results to retreived orga BUs
            condition = 'BU_Target__c IN (\'' + String.join(new List<Id>(assortmentBUsMap.keySet()), '\',\'') + '\')';
            whereClause = buildWhere(whereClause, condition);
        } else if (this.recordType.equals('Stop')) {
            // get records where product__c is NOT a reference product
            condition = 'Product__r.Product_Reference_Type__c = NULL';
            whereClause = this.buildWhere(whereClause, condition);
        }
        query += whereClause;
        query += ' GROUP BY Product__c, Product__r.Name, Product__r.Category__c';
        query += ' ORDER BY Product__r.Category__c ASC, Product__r.Name ' + orderDirection;
        query += ' LIMIT 1000';
        return query;
    }

    /**
     * @param whereClause the already existing where clause (if not emprty it must include WHERE)
     * @param condition the new condition to add to the where Clause
     * @return String of a clean where clause 
     * @description if whereClause is empty or null the method returns the condition lead by the keyword WHERE
     * if whereClause is not empty the method returns the string of joining whereClause & condition with the keyword AND
    */
    private String buildWhere(String whereClause, String condition) {
        return String.isBlank(whereClause) ? ' WHERE ' + condition : whereClause + ' AND ' + condition;
    }
    
    /**
     * @description change order direction between DESC and ASC
	*/
    public void toggleOrderDirection() {
        if (orderDirection.equals('ASC')) orderDirection = 'DESC';
        else orderDirection = 'ASC';
        searchRecords();
    }

    /**
     * @description
     * get all product intro history
    */
    private void getRecords() {
        Set<Id> productIdSet = new Set<Id>();
        for (AggregateResult result : productIntroHistoryAggregateResultList)
            productIdSet.add((Id) result.get('ProductId'));
        
        List<String> conditions = new List<String>();
        conditions.add('Product__c IN (\'' + String.join(new List<Id>(productIdSet), '\',\'') + '\')');
        conditions.add('RecordType.DeveloperName = \'' + this.recordType + '\'');
        conditions.add('BU_Target__r.OwnerId = \'' + loggedUser + '\'');
        if (this.recordType.equals('Stop')) {
            conditions.add('BU_Target__r.Status__c = \'Open\'');
            conditions.add('BU_Target__r.RecordType.DeveloperName = \'Banner\'');
            conditions.add('Client__r.Status__c = \'Active\'');
        } else if (this.recordType.equals('Inno')) {
            conditions.add('BU_Target__c IN (\'' + String.join(new List<Id>(this.assortmentBUsMap.keySet()), '\',\'') + '\')');
        }
        String orderBy = 'Product_Category__c, Product__r.Name, BU_Target__r.Related_Client__r.Name, BU_Target__r.Name';
        String query = this.gridSettingsManager.buildQuery(null, conditions, orderBy);
        
        List<Product_Assortment_Introduction_History__c> records = Database.query(query);
        // clear product intros
        this.productIntroHistoryWrappersByCategoryList.clear();        
        Map<Id, ProductIntroHistoryWrapper> productIntroWrapperMap = new Map<Id, ProductIntroHistoryWrapper>();
        Map<Id, List<ProductIntroHistoryWrapper>> productIntroHistoryWrappersByCategoryMap = new Map<Id, List<ProductIntroHistoryWrapper>>();
        
        // fill product intros grouped by product and BU
        Map<Id, Map<Id, Product_Assortment_Introduction_History__c>> productIntrosMap = new Map<Id, Map<Id, Product_Assortment_Introduction_History__c>>();
        for (Product_Assortment_Introduction_History__c item : records) {
            Map<Id, Product_Assortment_Introduction_History__c> productIntroBUMap;
            if (!productIntrosMap.containsKey(item.Product__c)) {
                productIntroBUMap = new Map<Id, Product_Assortment_Introduction_History__c>();
            } else {
                productIntroBUMap = productIntrosMap.get(item.Product__c);
            }
            productIntroBUMap.put(item.BU_Target__c, item);
            productIntrosMap.put(item.Product__c, productIntroBUMap);
        }
        for (Id productId : productIntrosMap.keySet()) {
            Map<Id, Product_Assortment_Introduction_History__c> productIntroBUMap = productIntrosMap.get(productId);
            Product_Assortment_Introduction_History__c initRecord = productIntroBUMap.values().get(0);
            for (BUWrapper item : this.assortmentBUsMap.values()) {
                Product_Assortment_Introduction_History__c record;
                if(!productIntroBUMap.containsKey(item.buId)) {
                    // Generate records for all BUs in case the BU is created
                    // after insertion of new products
                    record = new Product_Assortment_Introduction_History__c(Product__c = productId, BU_Target__c = item.buId,
                                                                            RecordTypeId = initRecord.RecordTypeId, Client__c = item.clientId);
                } else {
                    record = productIntroBUMap.get(item.buId);
                }
                String complexKey = productId + '' + item.buId;
                if (!this.initialProductIntroHistoryMap.containsKey(complexKey)) this.initialProductIntroHistoryMap.put(complexKey, record.clone(true));
                if (!this.updatedProductIntroHistoryMap.containsKey(complexKey)) this.updatedProductIntroHistoryMap.put(complexKey, record.clone(true));
                // fill updated records
                record = this.updatedProductIntroHistoryMap.get(complexKey);
                if (record.Application_Date__c == null) record.Application_Date__c = Date.today();
                if (!productIntroWrapperMap.containsKey(record.Product__c)) productIntroWrapperMap.put(record.Product__c, new ProductIntroHistoryWrapper(record));
                productIntroWrapperMap.get(record.Product__c).productIntroHistoryMap.put(complexKey, record);
            }
        }
        for (ProductIntroHistoryWrapper item : productIntroWrapperMap.values()) {
            if (!productIntroHistoryWrappersByCategoryMap.containsKey(item.productIntro.Product__r.Category__c))
                productIntroHistoryWrappersByCategoryMap.put(item.productIntro.Product__r.Category__c, new List<ProductIntroHistoryWrapper>());
            productIntroHistoryWrappersByCategoryMap.get(item.productIntro.Product__r.Category__c).add(item);
        }
        this.productIntroHistoryWrappersByCategoryList = productIntroHistoryWrappersByCategoryMap.values();
    }
    
    /**
     * @description
     * process update products intro/stop
    */
    private Boolean hasChanged(Product_Assortment_Introduction_History__c oldItem, Product_Assortment_Introduction_History__c newItem) {
        return (String.isNotBlank(newItem.Load_Status__c) && oldItem.Load_Status__c != newItem.Load_Status__c) ||
            (String.isNotBlank(newItem.Load_Status__c) && String.isNotBlank(newItem.BU_Assortment__c) && oldItem.BU_Assortment__c != newItem.BU_Assortment__c) ||
            (String.isNotBlank(newItem.Load_Status__c) && oldItem.Application_Date__c != newItem.Application_Date__c);
    }
    
    public void save() {
        List<Product_Assortment_Introduction_History__c> toUpdateList = new List<Product_Assortment_Introduction_History__c>();
        for (String key : this.initialProductIntroHistoryMap.keySet()) {
            Product_Assortment_Introduction_History__c oldItem = this.initialProductIntroHistoryMap.get(key);
            Product_Assortment_Introduction_History__c newItem = this.updatedProductIntroHistoryMap.get(key);
            if (hasChanged(oldItem, newItem)) {
                newItem.Load_Rules__c = this.selectedLoadRule;
                newItem.Record_Date__c = System.today();
                toUpdateList.add(newItem);
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            if (!toUpdateList.isEmpty()) {
                // Check Product_Assortment_Introduction_History__c upsert field security
                String[] productIntroductionFields = new String [] {getFieldName('Load_Status__c'), getFieldName('BU_Assortment__c'),
                    getFieldName('Load_Rules__c'), getFieldName('Record_Date__c'), getFieldName('Application_Date__c')};
                
                // TODO Warning : check if not exist Assortment_BU__c linked to BU_Target__c for product intro updated list
                if(checkCreatibility(Product_Assortment_Introduction_History__c.SObjectType, productIntroductionFields) && 
                   checkUpdatibility(Product_Assortment_Introduction_History__c.SObjectType, productIntroductionFields))
                {
                    List<Database.UpsertResult> results = Database.upsert(toUpdateList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        Product_Assortment_Introduction_History__c productIntro = toUpdateList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = (productIntro.Name != null ? productIntro.Name + ' : ' : '');                            
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                            return;
                        } else {
                            // get updated record
                            String complexKey = productIntro.Product__c + '' + productIntro.BU_Target__c;
                            Product_Assortment_Introduction_History__c productHistory = this.updatedProductIntroHistoryMap.get(complexKey);
                            productHistory.Load_Status__c = productIntro.Load_Status__c;
                            productHistory.BU_Assortment__c = productIntro.BU_Assortment__c;
                            productHistory.Application_Date__c = productIntro.Application_Date__c;
                            productHistory.Load_Rules__c = productIntro.Load_Rules__c;
                            this.initialProductIntroHistoryMap.put(productIntro.Product__c + '' + productIntro.BU_Target__c, productHistory.clone(true));
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
                        }
                    }
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Nothing to update'));
            }
        } catch (DmlException ex) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getDmlFields(0) + '-' + ex.getDmlMessage(0)));
        } catch (Exception ex) {
            Database.rollback(sp);
        }
    }
    
    public PageReference cancel() {
        return new PageReference('/');
    }
    
    /** BU Wrapper Class **/
    public class BUWrapper {
        public Id buId {get; set;}
        public Id clientId {get; set;}
        public String Name {get; set;}
        public List<SelectOption> assortmentBUOptions {get; set;}
        
        public BUWrapper(Orga_BU__c entity) {
            this.buId = entity.Id;
            this.Name = entity.Name;
            this.clientId = entity.Related_Client__c;
            this.assortmentBUOptions = new List<SelectOption>{new SelectOption('', '--None--')};
       }
    }

    // Wrapper for ProductIntro/Stop page
    public class ProductIntroHistoryWrapper {
        public Product_Assortment_Introduction_History__c productIntro {get; set;}
        // Map<complex Key: Product + BU + Client, Product_Assortment_Introduction_History__c>
        public Map<String, Product_Assortment_Introduction_History__c> productIntroHistoryMap {get; set;}
        
        public ProductIntroHistoryWrapper(Product_Assortment_Introduction_History__c productIntro) {
            this.productIntro = productIntro;
            this.productIntroHistoryMap = new Map<String, Product_Assortment_Introduction_History__c>();
        }
    }
}