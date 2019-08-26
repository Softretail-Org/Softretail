/**
* @description Custom controller that uses the standard Product2 controller
* to allows the handling of merge unit needs and products process.
* It provides the following initial functionalities:
* 1- Display selected/all Unit Needs + Filter.
* 2- Display Products that have categories of the displayed unit need + Filter.
* 3- Merge products and unit needs
* 3- GOAL: Optimising the ASSORTMENT of PRODUCTS you plan to stock &
* then ARRANGING those products on the shelves for MAXIMUM impact.
**/  
global with sharing class UnitNeedProductMergeController extends NegoptimBaseController {
    
    public boolean showPopup {get;set;}//show confirmation popup after clicking save button in VF page
    public boolean reInit = false;
    public boolean afterRollback = false;
    public Boolean isSelectedRecords = false;//define if the user select unit needs or it should display all unit needs
    public static Id productRecordtype = NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, 'Product');
    public Id unitNeedRecordtype = NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, 'Unit_Need');  
    // filter fields
    public String unitNeedSearchString {get; set;}//used for search unit needs
    public String productSearchString {get; set;}//used for search unit products
    // pagination fields
    public Integer pageSize {get; set;}//Number of elements in the page used for unit needs and for products
    public Integer noOfRecords {get; set;}//Number of selected/all unit needs
    public Integer unitNeedNoOfRecords {get; set;}//Number of all correspandat products
    public Integer unitNeedOriginalNoOfRecords {get; set;}
    public List<SelectOption> paginationSizeOptions {get; set;}//picklist to change page size
    // Merge atributes
    public Map<String, List<Product2>> allProductsMap {get; set;}//map productCode with the products that have this product code
    //to ensure if there is product code duplication
    public String allProductsJson {get; set;}//convert allProductsMap to JSON to use it in the visualforce page
    public List<Product2> selectedUNsList {get; set;}
    public List<Product2> selectedUnitNeedList {get; set;}//unit needs selected from products page, if the user does not select any unit need,
    public List<Product2> originalUnsList;
    //this list must contains all unit needs
    public Map<Id, List<Product2>> unitNeedsMap {get; set;}//map grouped by long hierarchy name
    public Map<Id, List<Product2>> productsMap {get; set;}
    public Map<Id, String> longNameByCategoryIdMap {get; set;}
    public Map<String, String> uniNeedWithMergedProducts {get; set;}
    public List<String> unCategoriesId;//get all categories of selected unit needs, to display only the products belongs to these categories
    public Map<Id, String> unProductsMap {get; Set;}// mapping between unit Need Id and the linked product
    private boolean isNullClassification = false;
    //Reporting
    public Map<String, Map<String, MergeReportWrapper>> reportMap {get; set;}// Map of <Status(Failed/Successed),<unitNeedId, MergeReportWrapper>>
    public String successedSummaryMessage {get; set;}
    public String failedSummaryMessage {get; set;}
    public String xmlHeader {get; set;}// used for Excel
    //Standard Set Controllers
    public ApexPages.StandardSetController unitNeedStdcontroller {get; set;}
    public ApexPages.StandardSetController productsStdSetCtrl {get; set;}
    
    public String formatedExcelDate {
        get {
            return NegoptimDate.formatDate(system.now(), 'EEEEE, d MMMMM yyyy HH:mm');
        }
        private set;
    }
    
    //default constructor, used for Excel VF Page
    public UnitNeedProductMergeController(){
        this.xmlHeader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        String reportMapJson = ApexPages.currentPage().getParameters().get('reportMapJson');
        if(String.isNotBlank(reportMapJson)){
            this.reportMap = (Map<String, Map<String, MergeReportWrapper>>) JSON.deserializeStrict(reportMapJson, Map<String, Map<String, MergeReportWrapper>>.class);
        }
    }
    
    public UnitNeedProductMergeController(ApexPages.StandardSetController stdSetController){
        List<String> fields = new List<String> {'Long_Name_Hierarchy__c', 'recordTypeId', 'recordTypeId', 'recordType.DeveloperName', 'isActive', 'ProductCode', 'Name', 'Category__c', 'Category__r.Name', 
            'Animation__c', 'Attribute1_code__c', 'Attribute1_name__c', 'Attribute2_code__c', 'Attribute2_name__c', 'Attribute3_code__c', 'Attribute3_name__c', 'Brand__c', 
            'Commercial_Name__c', 'Depth__c', 'Ext_id__c', 'Height__c', 'Length_Unit__c', 'Long_Name__c', 'Market__c', 'Packaging__c', 'ProductCode2__c', 'Product_EAN__c', 
            'Product_MasterSupplier__c', 'Status__c', 'UC__c', 'UV__c', 'UVC_Pack__c', 'Weight__c', 'Weight_UC__c', 'Width__c', 'Average_Weekly_Sales_Hyper__c', 'Retail_Price_Reco__c'}; 
                if (!Test.isRunningTest()) {
                    stdSetController.addFields(fields);
                }
        //Lists and Maps initialization
        unitNeedSearchString = '';
        productSearchString = '';
        unCategoriesId = new List<String>();
        unProductsMap = new Map<Id,String>();
        longNameByCategoryIdMap = new Map<Id,String>();
        reportMap = new Map<String, Map<String, MergeReportWrapper>>();
        isSelectedRecords = stdSetController.getSelected() != null && !stdSetController.getSelected().isEmpty();
        selectedUNsList = stdSetController.getSelected() ;
        selectedUnitNeedList = Database.query(buildUnitNeedQuery()); 
        allProductsMap = new Map<String, List<Product2>>();
        String query = buildMergedProductQuery();
        for(Product2 product : Database.query(query)){
            if(!allProductsMap.containsKey(product.ProductCode))
                allProductsMap.put(product.ProductCode, new List<Product2>()); 
            allProductsMap.get(product.ProductCode).add(product);
        }
        allProductsJson = JSON.serialize(allProductsMap);
        //fill pagination size options select list
        this.paginationSizeOptions = new List<SelectOption>();
        this.paginationSizeOptions.add(new SelectOption('10','10'));
        this.paginationSizeOptions.add(new SelectOption('25','25'));
        this.paginationSizeOptions.add(new SelectOption('50','50'));
        this.paginationSizeOptions.add(new SelectOption('100','100'));
        this.pageSize = 10;//default page size
        //Show popup attribute initialization
        showPopup = false;
        searchUnitNeed();
        searchProducts();
    }
    /**
* @description called when the user search for unit needs or on re-initialization of unit needs table
*/
    public void searchUnitNeed() {
        List <Product2> searchResult = new List<Product2>();
        unCategoriesId.clear();
        selectedUnitNeedList = Database.query(buildUnitNeedQuery());
        List<Product2> listToIterate = afterRollback && originalUnsList!=null ? originalUnsList : selectedUnitNeedList;
        for(Product2 prod : listToIterate){
            if(prod.recordTypeId == unitNeedRecordtype &&
               (unitNeedSearchString == null || String.isBlank(unitNeedSearchString) || prod.Name.toLowerCase().contains(unitNeedSearchString.toLowerCase()) 
                || prod.Long_Name_Hierarchy__c.toLowerCase().contains(unitNeedSearchString.toLowerCase()))){
                    searchResult.add(prod);
                    if (unProductsMap.get(prod.Id) == null || reInit)
                        unProductsMap.put(prod.Id, '');
                    if(prod.Category__c == null)
                        isNullClassification = true;
                    else if(!unCategoriesId.contains(prod.Category__c+''))
                        unCategoriesId.add(prod.Category__c+'');
                }
        }
        unitNeedStdcontroller = new ApexPages.StandardSetController(searchResult);
        this.unitNeedNoOfRecords = unitNeedStdcontroller.getResultSize();
        if(unitNeedOriginalNoOfRecords == null)
            this.unitNeedOriginalNoOfRecords = unitNeedNoOfRecords;
        unitNeedStdcontroller.setPageSize(this.pageSize);
        unitNeedsMap = groupListByCategory(unitNeedStdcontroller.getRecords());
        afterRollback = false;
    }
    
    /**
* @description called when the user search for products or on re-initialization of the product table
*/
    public void searchProducts() {
        String query = this.buildProductQuery();
        productsStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        this.noOfRecords = productsStdSetCtrl.getResultSize();
        productsStdSetCtrl.setPageSize(this.pageSize);
        this.productsMap = groupListByCategory(productsStdSetCtrl.getRecords());
        if(productsMap.isEmpty() && isNullClassification)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Empty_Product_Classification));
    }
    /**
* @description constructs a query to fetch seleted unit needs and order them by category and createdDate
* @return String the query
*/
    private String buildUnitNeedQuery() {
        String query = 'SELECT Name, Category__c, Category__r.Name, Category__r.Elt_Code__c, '
            +' Average_Weekly_Sales_Hyper__c, Retail_Price_Reco__c, recordTypeId, recordType.DeveloperName, Long_Name_Hierarchy__c'
            +' FROM Product2 where recordType.DeveloperName like \'Unit_Need\''
            +' AND Category__c <> NULL';
        if(isSelectedRecords){
            String selectedIds = '';
            for(Product2 unItem : selectedUNsList){
                selectedIds += ',\'' + unItem.Id +'\'';
            }
            query += ' AND Id in (' + selectedIds.replaceFirst(',', '') + ')';
        }
        query += ' ORDER BY Category__r.Name ASC, CreatedDate DESC';
        query += ' LIMIT 10000';
        return query;
    }
    /**
* @description constructs a query to fetch products belongs to the same categories of displayed unit needs and matched with search input (if search input is not empty)
* @return String the query
*/
    private String buildProductQuery() {
        String query = '';
        String whereClause = '';
        query += ' SELECT ProductCode, Name, Category__c, Category__r.Name, Product_EAN__c, Status__c,Long_Name_Hierarchy__c ';
        query += ' FROM Product2';
        whereClause = ' WHERE recordTypeId = \'' + productRecordtype + '\'';
        whereClause += ' AND UN_origin__c = Null';
        if(isNullClassification && !unCategoriesId.isEmpty()){
            whereClause += ' AND ( category__c in ('+buildSearchList(unCategoriesId)+') OR Category__c = NULL)';
        }
        else{
            if(!unCategoriesId.isEmpty())
                whereClause += ' AND category__c in ('+buildSearchList(unCategoriesId)+')';
            else  if(isNullClassification)
                whereClause += ' AND Category__c = NULL';}
        if (String.isNotBlank(productSearchString)) {
            String condition = ' ((Name LIKE \'%' + String.escapeSingleQuotes(productSearchString) + '%\')';
            condition += ' OR (ProductCode LIKE \'%' + String.escapeSingleQuotes(productSearchString) + '%\')';
            condition += ' OR (Product_EAN__c LIKE \'%' + String.escapeSingleQuotes(productSearchString) + '%\')';
            condition += ' OR (Long_Name_Hierarchy__c LIKE \'%' + String.escapeSingleQuotes(productSearchString) + '%\'))';
            whereClause = buildWhere(whereClause, condition);
        }
        query += whereClause;
        query += ' ORDER BY Category__r.Name ASC, CreatedDate DESC';
        query += ' LIMIT 10000';
        return query;
    }
    /**
* @description constructs a query to fetch products linked by the user to unit needs
* @return String the query
*/
    private String buildMergedProductQuery() {
        String query = '';
        String whereClause = '';
        query += ' SELECT IsActive, ProductCode, Name, Category__c, Category__r.Name, Animation__c, Attribute1_code__c, Attribute1_name__c, Attribute2_code__c,';
        query += ' Attribute2_name__c, Attribute3_code__c, Attribute3_name__c, Brand__c, Commercial_Name__c, Depth__c, Ext_id__c, Height__c,';
        query += ' Length_Unit__c, Long_Name__c, Market__c, Packaging__c, ProductCode2__c, Product_EAN__c, Product_MasterSupplier__c, Status__c, UC__c, UV__c, UVC_Pack__c,';
        query += ' Weight__c, Weight_UC__c, Width__c, Average_Weekly_Sales_Hyper__c, Retail_Price_Reco__c, RecordTypeId, Long_Name_Hierarchy__c';
        query += ' FROM Product2';
        query += ' WHERE recordTypeId = \'' + productRecordtype + '\'';
        query += ' AND ProductCode <> NULL';
        query += ' AND UN_origin__c = Null';
        return query;
    }
    private String buildWhere(String whereClause, String condition) {
        return String.isEmpty(whereClause) ? ' WHERE ' + condition : whereClause + ' AND ' + condition;
    }    
    private String buildSearchList(List <String> searchList) {
        String s='';
        for(String searchItem : searchList){
            if(String.isNotBlank(searchItem)){
                s += '\''+searchItem+'\', ';
            }
        }
        return s.removeEnd(', ');
    }
    //Pagination Methods
    public void refreshPageSize() {
        this.productsStdSetCtrl.setPageSize(this.pageSize);
        this.productsMap = groupListByCategory(productsStdSetCtrl.getRecords());
        this.unitNeedStdcontroller.setPageSize(this.pageSize);
        this.unitNeedsMap = groupListByCategory(unitNeedStdcontroller.getRecords());
    }
    public void resetProduct() {
        this.productSearchString = '';
        searchProducts();
    }
    public void resetUnitNeed() {
        this.unitNeedSearchString = '';
        searchUnitNeed();
    }
    public void first() {
        this.productsStdSetCtrl.first();
        this.productsMap = groupListByCategory(productsStdSetCtrl.getRecords());
    }
    public void next() {
        this.productsStdSetCtrl.next(); 
        this.productsMap = groupListByCategory(productsStdSetCtrl.getRecords());
    }
    public void previous() {
        this.productsStdSetCtrl.previous(); 
        this.productsMap = groupListByCategory(productsStdSetCtrl.getRecords());
    }
    public void last() {
        this.productsStdSetCtrl.last(); 
        this.productsMap = groupListByCategory(productsStdSetCtrl.getRecords());
    }
    public void unitNeedFirst() {
        this.unitNeedStdcontroller.first();
        this.unitNeedsMap = groupListByCategory(unitNeedStdcontroller.getRecords());
    }
    public void unitNeedNext() {
        this.unitNeedStdcontroller.next();
        this.unitNeedsMap = groupListByCategory(unitNeedStdcontroller.getRecords());
    }
    public void unitNeedPrevious() {
        this.unitNeedStdcontroller.previous();
        this.unitNeedsMap = groupListByCategory(unitNeedStdcontroller.getRecords());
    }
    public void unitNeedLast() {
        this.unitNeedStdcontroller.last();
        this.unitNeedsMap = groupListByCategory(unitNeedStdcontroller.getRecords());
    }
    /**
* @description find all products that have a product code contains a specified string. used in auto-complete for product code field in unit needs table
* @return String the result (convert the list of found products to JSON String)
*/
    @RemoteAction
    global static String findProduct(String productCode) {
        String productCodeLike = '%' + productCode + '%';
        List<Product2> listProducts = [SELECT Id, Name, ProductCode 
                                       FROM Product2
                                       WHERE ProductCode LIKE :productCodeLike
                                       AND recordTypeId = :productRecordtype
                                       AND UN_Origin__c = NULL];
        return JSON.serialize(listProducts);
    }
    
    /*
    * @description: show confirmation Popup
    */
    public void openPopup(){
        uniNeedWithMergedProducts = new Map<String, String>();
        Map<Id, Product2> unitNeedsMap = new Map<Id, Product2>(selectedUnitNeedList);
        for(Id unitNeedId : unProductsMap.keySet()){
            String unProductCode = unProductsMap.get(unitNeedId);
            Product2 unToUpdate = unitNeedsMap.get(unitNeedId);
            List<Product2> linkedProducts = allProductsMap.get(unProductCode);
            if(linkedProducts != null && !linkedProducts.isEmpty()){
                uniNeedWithMergedProducts.put(unToUpdate.Name, linkedProducts.get(0).Name);
            }
            else if(unProductCode != null && !String.isBlank(unProductCode)){
                uniNeedWithMergedProducts.put(unToUpdate.Name, Label.MSG_Product_Not_Found);
            }
        }
        showPopup = true;
    }
    public void hidePopup(){
        showPopup = false;
    }
    /*
    * @description perform the merge process; it validate the linked products, merge products and unit needs, and send a report by email o the user
    */
        public void save(){
            Map<Id, Product2> unitNeedsMap = new Map<Id, Product2>(selectedUnitNeedList);
            Map <Id, Product2> unToUpdateList = new Map <Id, Product2>();
            Map <Id, Product2> productsToDelete = new Map <Id, Product2>(); 
            List<Product2> originalUnsList = selectedUnitNeedList.deepClone(true, true, true);
            for(Id unitNeedId : unProductsMap.keySet()){
                String unProductCode = unProductsMap.get(unitNeedId);
                Product2 unToUpdate = unitNeedsMap.get(unitNeedId);
                List<Product2> linkedProducts = allProductsMap.get(unProductCode);
                if(String.isNotBlank(unProductCode) && unToUpdate != null){
                    if(validateMerge(unitNeedId, unToUpdate, linkedProducts, unProductCode)) {
                        //Update Unit Need
                        Product2 productToDelete = allProductsMap.get(unProductCode).get(0);
                        Product2 tmpProduct = unToUpdate;
                        mergeProducts(unToUpdate, productToDelete);
                        unToUpdateList.put(unToUpdate.Id, unToUpdate);
                        productsToDelete.put(productToDelete.Id, productToDelete);
                    }
                }
            }
            Savepoint sp = Database.setSavepoint();
            try{
                delete productsToDelete.values();// delete the merged products
                update unToUpdateList.values();// update unit Needs informations
                successedSummaryMessage = reportMap.get(Label.MSG_Success) != null ? reportMap.get(Label.MSG_Success).size() + ' ' + Label.MSG_Products_Merged_Successfully : '';// summaries the successed merged unit needs
                failedSummaryMessage = reportMap.get(Label.MSG_Failed) != null ? reportMap.get(Label.MSG_Failed).size() + ' ' + Label.MSG_Products_Failed_In_Merge : '';// summaries the failed merged unit needs
                reInit = true;
                searchUnitNeed();// re-initialize the unit needs table
                searchProducts();// re-initialize the products table
                if(!String.isBlank(successedSummaryMessage) || !String.isBlank(failedSummaryMessage)){
                    if(!String.isBlank(successedSummaryMessage))
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, successedSummaryMessage));                
                    if(!String.isBlank(failedSummaryMessage))
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, failedSummaryMessage)); 
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,  Label.MSG_Email_Sent_Successfully));
                    sendEmail();// send an email with the report
                }
            }
            catch(DMLException ex){
                Database.rollback(sp);// rollback the deletion and the update in case of any exception
                afterRollback = true;
                searchUnitNeed();
                for (Integer i = 0; i < ex .getNumDml(); i++) {
                    String recordName =  '';
                    String recordType = '';
                    String errorMsg = '';
                    if(unToUpdateList.containsKey(ex.getDmlId(i))) {
                        recordName = unToUpdateList.get(ex.getDmlId(i)).Name;
                        recordType = 'Unit Need';
                    }
                    else if(productsToDelete.containsKey(ex.getDmlId(i))) {
                        recordName = productsToDelete.get(ex.getDmlId(i)).Name;
                        recordType = 'Product';
                    }
                    if(StatusCode.ENTITY_IS_DELETED == ex.getDmlType(i)){
                        errorMsg = Label.MSG_ENTITY_IS_DELETED;
                    }
                    else if(StatusCode.ENTITY_IS_LOCKED == ex.getDmlType(i)){
                        errorMsg = Label.MSG_ENTITY_IS_LOCKED;
                    }
                    else if(StatusCode.ENTITY_IS_ARCHIVED == ex.getDmlType(i)){
                        errorMsg = Label.MSG_ENTITY_IS_ARCHIVED;
                    }
                    else {
                        errorMsg = ex.getDmlMessage(i);
                    }
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, string.format(errorMsg, new String[]{recordType + ' "' + recordName + '"'})));
                }
            }
            catch(exception ex){
                Database.rollback(sp);// rollback the deletion and the update in case of any exception
                afterRollback = true;
                searchUnitNeed();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            }
            showPopup = false;
        }
    /**
* @description validate if the the linked products is valid to merge with the selected unit need or not
* @return Boolean 
*/
    private boolean validateMerge(Id unitNeedId, Product2 unToUpdate, List <Product2> linkedProducts, String unProductCode){
        boolean isValid = false;
        String status, comment, linkedProductName, linkedProductCategory;
        if(linkedProducts == null || linkedProducts.isEmpty()){//a product code not found
            status =  Label.MSG_Failed;
            comment = Label.MSG_Product_Not_Found;
            linkedProductName = '';
            linkedProductCategory = '';
        }
        else if(linkedProducts.size() > 1){//Multiple Products with same Product Code
            status = Label.MSG_Failed;
            comment = Label.MSG_Duplicated_Product_Code;
            linkedProductName =  linkedProducts.get(0).Name;
            linkedProductCategory = linkedProducts.get(0).Long_Name_Hierarchy__c;
        }
        else  
            if(!linkedProducts.get(0).Category__c.equals( unToUpdate.Category__c)){//code product refer to a product on another classification
                status = Label.MSG_Failed;
                comment = Label.MSG_Code_Product_On_Wrong_Product_Classification;
                linkedProductName =  linkedProducts.get(0).Name;
                linkedProductCategory = linkedProducts.get(0).Long_Name_Hierarchy__c;
            }
        else  {// product is valid and can be merged
            isValid = true;
            status = Label.MSG_Success;
            comment = Label.MSG_Success;
            linkedProductName =  linkedProducts.get(0).Name;
            linkedProductCategory = linkedProducts.get(0).Long_Name_Hierarchy__c;
        }
        //add the status to the reports map
        if(reportMap.get(status) == null )
            reportMap.put(status, new Map<String, MergeReportWrapper>());
        reportMap.get(status).put(unitNeedId,new MergeReportWrapper(unitNeedId, unToUpdate.Name, unToUpdate.Long_Name_Hierarchy__c, unProductCode, linkedProductName , linkedProductCategory, status, comment));
        return isvalid;
    }
    /**
* @description send an email contains an Excel sheet that summaries the status of merged products
*/
    private void sendEmail() {
        String[] toList = new String []{UserInfo.getUserEmail()};
            PageReference  pageRef = Page.UnitNeedProductMergeExcel;
        pageRef.getParameters().put('reportMapJson', JSON.serialize(this.reportMap));
        pageRef.setRedirect(true);
        blob excelBlob = pageRef.getContent();
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
        email_att.setBody(excelBlob);
        email_att.setContentType('application/vnd.ms-excel');
        email_att.setFileName(Label.LBL_Excel_Name + ' - ' + formatedExcelDate + '.xls');
        email_att.setinline(false);
        emailAttachments.add(email_att);
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSenderDisplayName('NegOptim');
        email.setToAddresses(toList);
        email.setFileAttachments(emailAttachments);
        email.setSubject(Label.LBL_Merge_Products_Report);
        email.setHtmlBody(Label.LBL_Email_Body_Content);
        email.setPlainTextBody('');
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});    
        } catch (System.EmailException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Single Email Limit Exceeded. Cannot send this email'));
        }
    }
    private Map<Id, List<Product2>> groupListByCategory(List<Product2> productList){//used to group th unit needs list and the products list by long hiearachy Name 
        Map<Id, List<Product2>> groupedMap = new Map<Id, List<Product2>>();
        for(Product2 product : productList){
            if(!longNameByCategoryIdMap.containsKey(product.Category__c)){
                longNameByCategoryIdMap.put(product.Category__c, product.Long_Name_Hierarchy__c);
            }
            if(!groupedMap.containsKey(product.Category__c)){
                groupedMap.put(product.Category__c, new List<Product2>{product});
            }
            else {
                groupedMap.get(product.Category__c).add(product);
            }
        }
        return groupedMap;
    }
    /**
* @description copy linked product information to the selected unit need
*/
    private void mergeProducts(Product2 unToUpdate, Product2 productToMerge){
        unToUpdate.UN_Origin__c = unToUpdate.Name;
        unToUpdate.IsActive = productToMerge.IsActive;
        unToUpdate.ProductCode = productToMerge.ProductCode;
        //unToUpdate.Familly = productToMerge.Familly;
        unToUpdate.Name = productToMerge.Name;
        unToUpdate.Animation__c = productToMerge.Animation__c;
        unToUpdate.Attribute1_code__c = productToMerge.Attribute1_code__c;
        unToUpdate.Attribute1_name__c = productToMerge.Attribute1_name__c;
        unToUpdate.Attribute2_code__c = productToMerge.Attribute2_code__c;
        unToUpdate.Attribute2_name__c = productToMerge.Attribute2_name__c;
        unToUpdate.Attribute3_code__c = productToMerge.Attribute3_code__c;
        unToUpdate.Attribute3_name__c = productToMerge.Attribute3_name__c;
        unToUpdate.Brand__c = productToMerge.Brand__c;
        unToUpdate.Commercial_Name__c = productToMerge.Commercial_Name__c;
        unToUpdate.Depth__c = productToMerge.Depth__c;
        unToUpdate.Ext_id__c = productToMerge.Ext_id__c;
        unToUpdate.Height__c = productToMerge.Height__c;
        unToUpdate.Length_Unit__c = productToMerge.Length_Unit__c;
        unToUpdate.Long_Name__c = productToMerge.Long_Name__c;
        unToUpdate.Market__c = productToMerge.Market__c;
        unToUpdate.Packaging__c = productToMerge.Packaging__c;
        unToUpdate.ProductCode2__c = productToMerge.ProductCode2__c;
        unToUpdate.Product_EAN__c = productToMerge.Product_EAN__c;
        unToUpdate.Product_MasterSupplier__c = productToMerge.Product_MasterSupplier__c;
        unToUpdate.Status__c = productToMerge.Status__c;
        unToUpdate.UC__c = productToMerge.UC__c;
        unToUpdate.UV__c = productToMerge.UV__c;
        unToUpdate.UVC_Pack__c = productToMerge.UVC_Pack__c;
        unToUpdate.Weight__c = productToMerge.Weight__c;
        unToUpdate.Weight_UC__c = productToMerge.Weight_UC__c;
        unToUpdate.Width__c = productToMerge.Width__c;
        unToUpdate.RecordTypeId = productToMerge.RecordTypeId;
    }
    public with sharing Class MergeReportWrapper {
        public String unId {get; set;}// unit need ID
        public String unName {get; set;}// unit need Name
        public String unCategory {get; set;}// unit need classification
        public String linkedProductCode {get; set;}// linked product code
        public String linkedProductName {get; set;}//linked product name
        public String linkedProductCategory {get; set;}//linked product classification
        public String status {get; set;}// status of the merge
        public String note {get; set;}// failure cause (if it exists)
        //Constructor
        public MergeReportWrapper(String unId, String unName, String unCategory, String linkedProductCode, String linkedProductName, String linkedProductCategory, String status, String note){
            this.unId = unId;
            this.unName = unName;
            this.unCategory = unCategory;
            this.linkedProductCode = linkedProductCode;
            this.linkedProductName = linkedProductName;
            this.linkedProductCategory = linkedProductCategory;
            this.status = status;
            this.note = note;
        }
    }
}