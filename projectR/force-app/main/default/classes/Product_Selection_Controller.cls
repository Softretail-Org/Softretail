/**
 * SPEC: NEGOP - FS.PROD.01 -Product selection
 * Definition:
 * Client = Supplier
 * Client Assortment = PG
 * */
global with sharing class Product_Selection_Controller extends NegoptimBaseController {
    
    public Sup_Supplier__c supplier {get; set;}
    public Supplier_PG_Mapping__c clientAssortment {get; set;}
    public Integer year {get; set;}
    public Boolean hasCreatePGAccess {get; set;}
    public Boolean hasDeletePGAccess {get; set;}
    
    // selection and filter
    public list<String> AlphaList {get; set;}
    public String AlphaFilter {get; set;}
    public String textFilter {get; set;}
    public String productListingFilter {get; set;}
    private String textFilterValue;
    private String productListingFilterValue;
    private String query;
    public static List<String> searchNameList{get; set;}
    
    Public Integer size {get; set;}
    Public Integer noOfRecords {get; set;}
    public List<SelectOption> paginationSizeOptions {get; set;}
    public String SortFieldSave;
    
    public String supplierId;
    Set<ProductWrapper> allProductSet = new Set<ProductWrapper>();
    // List of Products already exist in Client Assortment list for current client
    Set<Id> productsInAssortmentIds = new Set<Id>();
    // Current selection of Products
    public Set<Id> selectedProductsIds = new Set<Id>();
    private Map<Id, Product2> selectedProductsMap = new Map<Id, Product2>();
    Set<Id> brandDistributorSet = new Set<Id>();
    
    Public Decimal totalSellIn {get; set;}
    public String sTotalSellIn {
        get {
            return this.totalSellIn != null ? this.totalSellIn.format() : '';
        }
        set;
    }
    
    public ApexPages.StandardSetController setCtrlr {
        get {
            if (setCtrlr == null) {
                if(String.isNotBlank(query)){
                    setCtrlr = new ApexPages.StandardSetController(Database.getQueryLocator(query));
                    if(size == null) size = 10;
                    setCtrlr.setPageSize(size);
                }
                else{
                    setCtrlr = new ApexPages.StandardSetController(new List<Product2>());
                }
                noOfRecords = setCtrlr.getResultSize();                
            }
            return setCtrlr;
        }
        set;
    }
    //to enable or disable page ActionPollar
    public Boolean batchInProgress {get; set;}
    private Id productToPGBatchId;
    
    public Product_Selection_Controller(ApexPages.StandardController stdController) {
        supplierId = ApexPages.currentPage().getParameters().get('id');
        if(String.isNotBlank(supplierId)) {
            clientAssortment = new Supplier_PG_Mapping__c(Supplier__c = supplierId);
            supplier = [SELECT Id, Name, Code__c, Country_origin__c FROM Sup_Supplier__c WHERE Id = :supplierId];
        }
        string selectYear = ApexPages.CurrentPage().getParameters().get('selectYear');
        if(String.isNotBlank(selectYear)){
            year = Integer.valueOf(selectYear);
        }
        else{
            year = Date.today().year();
        }
        size = 10;
        paginationSizeOptions = new List<SelectOption>();
        paginationSizeOptions.add(new SelectOption('5','5'));
        paginationSizeOptions.add(new SelectOption('10','10'));
        paginationSizeOptions.add(new SelectOption('20','20'));
        paginationSizeOptions.add(new SelectOption('50','50'));
        paginationSizeOptions.add(new SelectOption('100','100'));
        
        SortFieldSave = SortField;
        totalSellIn = 0;
        hasCreatePGAccess = Supplier_PG_Mapping__c.SObjectType.getDescribe().isCreateable();
        hasDeletePGAccess = Supplier_PG_Mapping__c.SObjectType.getDescribe().isDeletable();
        batchInProgress = false;
        try {
            // load intial data and existing selection product
            load();
            buildQuery();
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid Id'));
        }
    }
    
    public List<SelectOption> getListYears() {
        List<SelectOption> options = new List<SelectOption>();
        for(Integer year = Date.today().year() - 2; year <= Date.today().year(); year++) {
            options.add( new SelectOption(String.valueOf(year), String.valueOf(year)) );
        }
        return options;
    }
    
    public void load() {
        // get brand distributor list
        for(Sup_Bra_Distributor__c item :[SELECT Brand__c FROM Sup_Bra_Distributor__c WHERE Supplier__c = :supplierId]){
            if(!brandDistributorSet.contains(item.Brand__c)){
                brandDistributorSet.add(item.Brand__c);
            }
        }
        // get products related to Supplier
        for(Supplier_PG_Mapping__c item : [SELECT Id, Product__c, Product__r.Name, Product__r.Category__c,
                                           Product__r.Category__r.Parent_Element__c, Product__r.ProductCode,
                                           Brand__c, Department__c, Section__c, Supplier__c
                                           FROM Supplier_PG_Mapping__c
                                           WHERE Supplier__c = :supplierId 
                                           AND Product__r.IsActive = TRUE])
        {
            Product2 product = new Product2(Id = item.Product__c, Name = item.Product__r.Name, Category__c = item.Product__r.Category__c,
                                            ProductCode = item.Product__r.ProductCode, Brand__c = item.Brand__c);
            if(!selectedProductsMap.containsKey(item.Product__c)){
                selectedProductsMap.put(item.Product__c, product);
            }
            if(!productsInAssortmentIds.contains(item.Product__c)){
                productsInAssortmentIds.add(item.Product__c);
            }
            if(!selectedProductsIds.contains(item.Product__c)){
                selectedProductsIds.add(item.Product__c);
            }
        }
    }
    
    // Changes the size of pagination product grid
    public PageReference refreshPageSize() {
        processProductSelection();
        setCtrlr.setPageSize(size);
        return null;
    }
    
    // Initialize setCtrlr and return a list of records
    public List<ProductWrapper> getProducts() {
        if(supplier == null) return new List<ProductWrapper>();
        
        allProductSet = new Set<ProductWrapper>();
        List<ProductWrapper> productsList = new List<ProductWrapper>();
        Set<Id> productIds = new Set<Id>();
        for(Product2 item : (List<Product2>) setCtrlr.getRecords()) {
            Boolean isSelected = selectedProductsIds.contains(item.Id);
            ProductWrapper wProduct = new ProductWrapper(item, isSelected);
            wProduct.inAssortment = productsInAssortmentIds.contains(item.Id);
            //wProduct.calculateSellIn();           
            productsList.add(wProduct);
            productIds.add(item.Id);
        }
        // Get sell in flow grouping by supplier and products selected
        Map<Id, Map<Integer, Decimal>> sellinMonthMap = new Map<Id, Map<Integer, Decimal>>();
        Integer previousMonth = Date.today().month() - 1;
        for(AggregateResult aggr : [SELECT Supplier__c, Mvt_Purch_Product__c, Calendar_Month(Invoice_Date__c) month, SUM(Invoice_Net_Amount_woTax_Calc__c) amount
                                    FROM Sell_in_Flow__c
                                    WHERE Supplier__c = :supplier.Id AND Mvt_Purch_Product__c IN :productIds AND Year__c = :year
                                    AND Invoice_Net_Amount_woTax_Calc__c <> null
                                    AND Mvt_Purch_Product__r.IsActive = TRUE
                                    GROUP BY Supplier__c, Mvt_Purch_Product__c, Calendar_Month(Invoice_Date__c)])
        {
            Id productId = (Id)aggr.get('Mvt_Purch_Product__c');
            decimal amount = Decimal.valueOf(String.valueOf(aggr.get('amount')));
            Integer month = Integer.valueOf(aggr.get('month'));
            if(!sellinMonthMap.containsKey(productId)){
                Map<Integer, Decimal> amountMonthMap = new Map<Integer, Decimal>();
                amountMonthMap.put(month, amount);
                sellinMonthMap.put(productId, amountMonthMap);
            }
            else {
                Map<Integer, Decimal> amountMonthMap = sellinMonthMap.get(productId);
                if(!amountMonthMap.containsKey(month)){                    
                    amountMonthMap.put(month, amount);
                }
                else {
                    Decimal totalAmount = amountMonthMap.get(month);
                    amountMonthMap.put(month, amount + totalAmount);
                }
            }
        }
        for(ProductWrapper item : productsList){
            Map<Integer, Decimal> amountMonthMap = sellinMonthMap.get(item.product.Id);
            if(amountMonthMap != null && amountMonthMap.size() > 0){
                for(Integer month : amountMonthMap.keySet()){
                    if(month == previousMonth){
                        item.sellInLastMonth = amountMonthMap.get(month) != null ? amountMonthMap.get(month) : 0;
                    }
                    item.sellInYTD += amountMonthMap.get(month) != null ? amountMonthMap.get(month) : 0;
                }
            }
        }
        allProductSet.addAll(productsList);
        return productsList;
    }
    
    private void processProductSelection() {
        for(ProductWrapper item : allProductSet) {
            if (item.selected == true) {
                if(!selectedProductsMap.containsKey(item.product.Id)){
                    selectedProductsMap.put(item.product.Id, item.product);
                }
                if(!selectedProductsIds.contains(item.product.Id)){
                    selectedProductsIds.add(item.product.Id);
                }
            }
            else {
                selectedProductsMap.remove(item.product.Id);
                selectedProductsIds.remove(item.product.Id);
            }
        }
    }
    
    // returns the first page of records
    public void first() {
        processProductSelection();
        setCtrlr.first();
    }
    
    // returns the last page of records
    public void last() {
        processProductSelection();
        setCtrlr.last();
    }
    
    // returns the previous page of records
    public void previous() {
        processProductSelection();
        setCtrlr.previous();
    }
    
    // returns the next page of records
    public void next() {
        processProductSelection();
        setCtrlr.next();
    }
    
    // set search criteria fields and refresh Supplier PG table
    public PageReference search() {
        processProductSelection();
        textFilterValue = textFilter;
        productListingFilterValue = productListingFilter;
        BuildQuery();
        return null;
    }
    
    public PageReference reset(){
        // Clear lists
        textFilter = '';
        textFilterValue = '';
        productListingFilter = '';
        productListingFilterValue = '';
        AlphaFilter = 'All';
        
        BuildQuery();
        return null;
    }
    
    public pageReference refresh() {
        setCtrlr = null;
        size = 10;
        selectedProductsIds.clear();
        selectedProductsMap.clear();
        load();
        buildQuery();
        return null;
    }
    
    // set year
    public PageReference setYearValue() {
        BuildQuery();
        PageReference pageRef = Page.Product_Selection;
        pageRef.getParameters().put('id', supplierId);
        pageRef.getParameters().put('selectYear', String.valueOf(year));
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    // Build query command for list selection change
    public void buildQuery() {
        if(supplier == null) return;
        setCtrlr = null;
        String queryWhere = '';
        
        if (AlphaFilter == null || AlphaFilter.trim().length() == 0) {
            AlphaFilter = 'All';
        }
        
        query = 'SELECT Id, Name, ProductCode, Category__c, Category__r.Parent_Element__c, Category__r.Parent_Element__r.Parent_Element__c,';
        query += ' Brand__c, Brand__r.Name, Attribute1_name__c ';
        //query += ' (SELECT Id, Mvt_Purch_Product__c, Invoice_Net_Amount_woTax_Calc__c, Month__c ';
        //query += ' FROM Sell_in_Flows__r WHERE Supplier__c = \'' + supplier.Id + '\' AND Year__c = ' + year + ')';
        query += ' FROM Product2';
        
        if (AlphaFilter == 'Other') {
            queryWhere = buildWhere(queryWhere, '(' + String.escapeSingleQuotes(SortField) + ' < \'A\' OR ' + 
                                    String.escapeSingleQuotes(SortField) + ' > \'Z\') AND (NOT ' + 
                                    String.escapeSingleQuotes(SortField) + ' LIKE \'Z%\') ');
        } else if (AlphaFilter != 'All') {
            queryWhere = buildWhere(queryWhere, '(' + String.escapeSingleQuotes(SortField) + ' LIKE \'' + String.escapeSingleQuotes(AlphaFilter) + '%\')' );
        }
        queryWhere = BuildWhere(queryWhere, 'IsActive = TRUE');        
        // check all produts with a brand linked to the client/supplier Brand_Distributor
        queryWhere = BuildWhere(queryWhere, 'Brand__c IN (\'' + String.join(new List<Id>(brandDistributorSet), '\',\'') +'\')');
        
        if (textFilterValue != null && textFilterValue != '') {
            queryWhere = buildWhere(queryWhere, ' ((Name LIKE \'%' + String.escapeSingleQuotes(textFilterValue) + '%\') OR' +
                                    ' (ProductCode LIKE \'%' + String.escapeSingleQuotes(textFilterValue) + '%\') OR' +
                                    ' (Brand__r.Name LIKE \'%' + String.escapeSingleQuotes(textFilterValue) + '%\') OR' +
                                    ' (Category__r.Name LIKE \'%' + String.escapeSingleQuotes(textFilterValue) + '%\') OR' +
                                    ' (Category__r.Parent_Element__r.Name LIKE \'%' + String.escapeSingleQuotes(textFilterValue) + '%\') OR' +
                                    ' (Category__r.Parent_Element__r.Parent_Element__r.Name LIKE \'%' + String.escapeSingleQuotes(textFilterValue) + '%\'))');
        }
        
        if (productListingFilterValue != null) {
            if(productListingFilterValue.contains('A')) {
                queryWhere = buildWhere(queryWhere, ' (Id IN (SELECT Product__c FROM Supplier_PG_Mapping__c WHERE Supplier__c = \'' + supplier.Id +'\'))');
            }
            if(productListingFilterValue.contains('B')) {
                queryWhere = buildWhere(queryWhere, ' (Id IN (SELECT Mvt_Purch_Product__c FROM Sell_in_Flow__c WHERE Supplier__c = \'' + supplier.Id + '\' AND Year__c = ' + year + '))');
            }
        }
        
        query += queryWhere;
        query += ' ORDER BY ' + String.escapeSingleQuotes(SortField) + ' ' + String.escapeSingleQuotes(SortDirection) + ' LIMIT 10000';
    }
    
    // Build soql string for where criteria 
    public String buildWhere(String q, String condition) {
        if (q == '') {
            return ' WHERE ' + condition;
        } else {
            return q + ' AND ' + condition;
        }
    }
    
    // SortDirection - return sort direction. Default ascending(asc)
    public String SortDirection {
        get { if (SortDirection == null) {  SortDirection = 'asc'; } return SortDirection;  }
        set;
    }
    
    // SortField - return sort by field. Default to Name
    public String SortField {
        get { if (SortField == null) {SortField = 'Name'; } return SortField;  }
        set; 
    }
    
    // SortToggle - toggles the sorting of query from asc<-->desc
    public void SortToggle() {
        SortDirection = SortDirection.equals('asc') ? 'desc NULLS LAST' : 'asc';
        // reset alpha filter and sort sequence when sorted field is changed
        if (SortFieldSave != SortField) {
            SortDirection = 'asc';
            AlphaFilter = 'All';
            SortFieldSave = SortField;
        }
        processProductSelection();
        // run the query again
        BuildQuery();
    }    
    
    // Get Products List
    public List<SelectOption> getProductListingOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', Label.LBL_ALL));
        options.add(new SelectOption('A', Label.LBL_Assortment));
        options.add(new SelectOption('B', Label.LBL_Sell_in));
        options.add(new SelectOption('AB', Label.LBL_Assortment_Sell_in));        
        return options;
    }
    
    // Button Save Action
    public PageReference savePGs() { // Renamed because standard name follow permission rules
        processProductSelection();
        // list Supplier_PG_Mapping__c to insert
        List<Supplier_PG_Mapping__c> clientAssortmentListToInsert = new List<Supplier_PG_Mapping__c>();
        // list Product related to the Supplier_PG_Mapping__c to delete
        Set<Id> clientAssortmentListToDelete = new Set<Id>();
        for(Id item : selectedProductsIds) {
            Product2 p = selectedProductsMap.get(item);
            if (!productsInAssortmentIds.contains(item) && p != null) {
                Supplier_PG_Mapping__c ca = clientAssortment.clone();
                ca.Name = p.Name;
                ca.Product__c = p.Id;
                ca.Brand__c = p.Brand__c;
                ca.Department__c = p.Category__r.Parent_Element__c;
                ca.Section__c = p.Category__c;
                ca.SNA_Code__c = supplier.Code__c + p.ProductCode;
                ca.GIMA_Code__c = supplier.Code__c + p.ProductCode;
                clientAssortmentListToInsert.add(ca);
            }
        }
        try {
            String[] pgFields = new String[] {'Name', getFieldName('Supplier__c'),  getFieldName('Product__c'), getFieldName('Brand__c'),
                getFieldName('Department__c'), getFieldName('Section__c'), getFieldName('SNA_Code__c'), getFieldName('GIMA_Code__c')};

            if(!clientAssortmentListToInsert.isEmpty()) {
                if (checkCreatibility(Supplier_PG_Mapping__c.SObjectType, pgFields)) {
                    List<Supplier_PG_Mapping__c> assortmentList = new List<Supplier_PG_Mapping__c>();
                    List<Database.SaveResult> results = Database.insert(clientAssortmentListToInsert, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Supplier_PG_Mapping__c item = clientAssortmentListToInsert.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = item.Name + ' : ';
                            Database.Error[] errs = result.getErrors();
                            for (Database.Error err : errs){
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                        } else {
                            assortmentList.add(item);
                        }
                    }
                    // update last price
                    if(!assortmentList.isEmpty()) {
                        Database.executeBatch(new RefreshLastPriceBatch('Product_Selection_Controller', assortmentList));
                    }
                }
            }
            
            // Delete dettached relations
            Set<Id> relationsToremove = new Set<Id>();
            for(Id item : productsInAssortmentIds) {
                if (!selectedProductsMap.containsKey(item)) {
                    clientAssortmentListToDelete.add(item);
                }
            }
            if (NegoptimHelper.checkDeletibility(Supplier_PG_Mapping__c.SObjectType) && !clientAssortmentListToDelete.isEmpty()) {
                Delete [SELECT Id FROM Supplier_PG_Mapping__c
                        WHERE Supplier__c = :supplier.Id
                        AND Product__c IN :clientAssortmentListToDelete
                        AND Product__r.IsActive = TRUE];
            }
            // fill new list of products
            productsInAssortmentIds.removeAll(clientAssortmentListToDelete);
            productsInAssortmentIds.addAll(selectedProductsIds);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
        } catch (DmlException e) {
            // commented to not show message twice
            ////ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        // TODO: Send Email notification to supplier
        return null;
    }
    
    // insert all products having sell in for the client but not ‘in assortment’
    public PageReference fastAction1() {
        Integer sellInCount = [SELECT Count()
                               FROM Product2
                               WHERE Id IN (SELECT Mvt_Purch_Product__c FROM Sell_in_Flow__c
                                            WHERE Mvt_Purch_Product__c <> null
                                            AND Invoice_Net_Amount_woTax_Calc__c <> NULL
                                            AND Year__c = :year
                                            AND Supplier__c = :supplier.Id)
                               AND Id NOT IN (SELECT Product__c FROM Supplier_PG_Mapping__c WHERE Supplier__c = :supplier.Id)];
        if (sellInCount > 1000) {
            String msg = 'Process in progress';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, msg));
            productToPGBatchId = Database.executeBatch(new ProductToPGBatch('Product_Selection_Controller', year, new List<Id>{ supplier.Id }));
            batchInProgress = true;
            return null;
        }
        try {
            String[] pgFields = new String[] {'Name', getFieldName('Supplier__c'), getFieldName('Product__c'), getFieldName('Brand__c'),
                getFieldName('Department__c'), getFieldName('Section__c'), getFieldName('SNA_Code__c'), getFieldName('GIMA_Code__c')};

            List<Supplier_PG_Mapping__c> clientAssortmentListToInsert = new List<Supplier_PG_Mapping__c>();
            for(Product2 p : [SELECT Id, Name, ProductCode, Category__c, Category__r.Parent_Element__c, Brand__c
                              FROM Product2
                              WHERE Id IN (SELECT Mvt_Purch_Product__c FROM Sell_in_Flow__c
                                           WHERE Mvt_Purch_Product__c <> null
                                           AND Invoice_Net_Amount_woTax_Calc__c <> NULL
                                           AND Year__c = :year
                                           AND Supplier__c = :supplier.Id)
                              AND Id NOT IN (SELECT Product__c FROM Supplier_PG_Mapping__c WHERE Supplier__c = :supplier.Id)])
            {
                Supplier_PG_Mapping__c ca = new Supplier_PG_Mapping__c(Supplier__c = supplier.Id);
                ca.Name = p.Name;
                ca.Product__c = p.Id;
                ca.Brand__c = p.Brand__c;
                ca.Department__c = p.Category__r.Parent_Element__c;
                ca.Section__c = p.Category__c;
                ca.SNA_Code__c = supplier.Code__c + p.ProductCode;
                ca.GIMA_Code__c = supplier.Code__c + p.ProductCode;
                clientAssortmentListToInsert.add(ca);
            }
            if(!clientAssortmentListToInsert.isEmpty()) {
                if (checkCreatibility(Supplier_PG_Mapping__c.SObjectType, pgFields)) {
                    List<Supplier_PG_Mapping__c> assortmentList = new List<Supplier_PG_Mapping__c>();
                    List<Database.SaveResult> results = Database.insert(clientAssortmentListToInsert, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Supplier_PG_Mapping__c item = clientAssortmentListToInsert.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = item.Name + ' : ';
                            Database.Error[] errs = result.getErrors();
                            for (Database.Error err : errs){
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                        }
                        else {
                            selectedProductsIds.add(item.Product__c);
                            assortmentList.add(item);
                        }
                    }
                    // update last price
                    if(!assortmentList.isEmpty()) {
                        Database.executeBatch(new RefreshLastPriceBatch('Product_Selection_Controller', assortmentList));
                    }
                }
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }
    
    // delete all products ‘in assortment’ for the client but not having sell in
    public PageReference fastAction2() {
        try {
            List<Supplier_PG_Mapping__c> pgsToDelete = [SELECT Id, Product__c FROM Supplier_PG_Mapping__c
                                                        WHERE Supplier__c = :supplier.Id
                                                        AND Product__c <> null
                                                        AND Product__c NOT IN (SELECT Mvt_Purch_Product__c
                                                                               FROM Sell_in_Flow__c WHERE Year__c = :year
                                                                               AND Supplier__c = :supplier.Id)];
            for(Supplier_PG_Mapping__c item : pgsToDelete) {
                selectedProductsIds.remove(item.Product__c);
            }
            if(NegoptimHelper.checkDeletibility(Supplier_PG_Mapping__c.SObjectType)) {
                delete pgsToDelete;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
        } catch (DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }
    
    @RemoteAction
    global static String[] populateProducts(String value) {
        try {
            searchNameList = new List<String>();
            if(String.isNotBlank(value))
            {
                value= '%'+value+'%';
                for(Product2 item: [SELECT Id, Name FROM Product2 WHERE Name LIKE :value AND IsActive = TRUE])
                {
                    searchNameList.add(item.Name);
                }
            }
            return searchNameList;
        } catch(Exception e) { }
        return null;
    }
    
    public void pollarAction() {
        if (batchInProgress) {
            String status = [SELECT Status FROM AsyncApexJob WHERE Id = :productToPGBatchId].Status;
            String msg = 'Process in progress';
            if(status.equals('Completed')) {
                msg = 'Process Compeleted';
                batchInProgress = false;
            }
            if(status.equals('Failed')) {
                msg = 'Process Failed';
                batchInProgress = false;
            }
            if(status.equals('Aborted')) {
                msg = 'Process Aborted';
                batchInProgress = false;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, msg));
        }
    }
    
    /* Supplier Wrapper Class */
    public class ProductWrapper {
        public Product2 product {get; set;}
        public Boolean selected {get; set;}
        public Boolean inAssortment {get; set;}
        public Decimal sellInYTD {get; set;}
        public String sValueSellInYTD {
            get {
                return this.sellInYTD.format();
            }
            set;
        }
        public Decimal sellInLastMonth {get; set;}
        public String sValueSellInLastMonth {
            get {
                return this.sellInLastMonth.format();
            }
            set;
        }
        public String codeColor {
            get {
                String code = '';
                if (sellInYTD > 0 && inAssortment)
                    code = '#b6e32e';
                if (sellInYTD > 0 && !inAssortment)
                    code = '#ff5858';
                if (sellInYTD <= 0 && inAssortment)
                    code = '#ffc862';
                return code;
            }
            set;
        }
        public ProductWrapper(Product2 p, Boolean sel) {
            product = p;
            selected = sel;
            inAssortment = sel;
            sellInYTD = 0;
            sellInLastMonth = 0;
        }
        public void calculateSellIn() {
            Decimal d = 0, m = 0, y = 0;
            Integer previousMonth = Date.today().month() - 1;
            for(Sell_in_Flow__c item : product.Sell_in_Flows__r) {
                d = item.Invoice_Net_Amount_woTax_Calc__c != null ? item.Invoice_Net_Amount_woTax_Calc__c : 0;
                if (item.Month__c != null && item.Month__c == previousMonth) {
                    m += d;
                }
                y += d;
            }
            sellInYTD = y;
            sellInLastMonth = m;
        }
    }    
}