public with sharing class MyTestLWCController {
    //hello world
    @AuraEnabled(cacheable=true)
   // public static List<Contact> initRecords(String ObjectName, String fieldNamesStr, String Orderby, String OrderDir) {
    public static DataTableWrapper initRecords(String recId ,String Path,Integer limitSize, String Orderby, String OrderDir) {
        //return [SELECT ID,NAME,Phone from Contact];
        DataTableWrapper dtw = new DataTableWrapper();
        List<ProductWrapper> LstPWrap = new List<ProductWrapper>();
        List<Product2> sObjectRecords = LoadRecords(Path ,limitSize, 0,'');
        system.debug(sObjectRecords);
        for(Product2 item : sObjectRecords){
            LstPWrap.add(new ProductWrapper(item));
        }
        system.debug(LstPWrap);
        List<Assortment_Detail__c> ProductsToSelect = getsExistingRecords(sObjectRecords ,recId);
        system.debug(':::::'+ProductsToSelect);
        dtw.sobList 	= JSON.serialize(LstPWrap);
        dtw.AssBUDetailsList = JSON.serialize(ProductsToSelect);
        dtw.totalCount  = getsObjectCountRecords(Path,'');
        return dtw;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getAssPath(String recId){
        Assortment_BU__c Path = [SELECT Orga_HE__r.Path__c FROM Assortment_BU__c where Id =:recId LIMIT 1];
        return Path.Orga_HE__r.Path__c;
    }
    public static Integer getsObjectCountRecords(String Path,String SearchTerm) {
        String query = 'SELECT Count() FROM Product2';
        query += ' Where Category__r.Path__c like \''+Path+'%\'';
        query += ' And IsActive = true';
        if(String.isNotEmpty(SearchTerm)){
            SearchTerm =  '%'+String.escapeSingleQuotes(SearchTerm)+'%';
            query += ' AND (Category__r.Long_Name__c LIKE \''+SearchTerm+'\'';
            query += ' OR Category__r.Parent_Element__r.Name LIKE \''+SearchTerm+'\'';
            query += ' OR Product_EAN__c LIKE \''+SearchTerm+'\' ';
            query += ' OR Name LIKE \''+SearchTerm+'\')';
        }
        return Database.countQuery(query);
    }
        

    @AuraEnabled(cacheable=true)
    public static List<Product2> getsObjectRecords(String ObjectName, List<String> fieldNameSet,Integer LimitSize,Integer offset, String recId, String Orderby, String OrderDir) {
        
        OrderDir = String.isBlank(OrderDir) ? 'asc' : OrderDir;
        System.debug(fieldNameSet);
        System.debug(String.join(fieldNameSet, ','));
        String query = 'SELECT '+String.join(fieldNameSet, ',')+' FROM '+ObjectName;
        query += ' Where Category__r.Path__c like \'1|'+recId+'%\'';
        query += ' And IsActive = true';
        query += ' ORDER BY '+Orderby+' '+OrderDir+' NULLS LAST';
        query += ' LIMIT 50 ';
        query += ' OFFSET 0';
        
       /* if(LimitSize != null && Integer.valueOf(LimitSize) > 0) {
            LimitSize = Integer.valueOf(LimitSize);
            query += ' Limit '+LimitSize;
        }*/
        system.debug(LimitSize+'-----'+query+'-----'+recId);
        List<Product2> ReturnedList = Database.query(query);
        System.debug(ReturnedList);
        return  ReturnedList ;
        //return new List<Account>();
    }
    @AuraEnabled
    public static List<Assortment_Detail__c> getsExistingRecords( List<Product2> Products ,String recId) {
        Set<Id> ProductsId = new Set<Id>();
        for (Product2 item : Products) {
            ProductsId.add(item.Id);
        }
        List<Assortment_Detail__c> ReturnedList = [SELECT Id, product__c FROM Assortment_Detail__c WHERE Product__r.Id IN :ProductsId AND Assortment_BU__c =:recId];
        return ReturnedList;
    }
  
    
    @AuraEnabled
    public static String SaveSelection( String  removedAssortmentDetails ,  String  addedProducts ,String assBUId) {
        try {
        List<String> A = new List<String>();
        System.debug('removed:'+removedAssortmentDetails);
        System.debug('Added'+addedProducts);
        if (String.isNotBlank(removedAssortmentDetails)){
        List<Id> AssToDelete = (List<Id>)JSON.deserialize(removedAssortmentDetails,List<Id>.class);
        List<Assortment_Detail__c> assortmentDetailsToDelete = [SELECT Id FROM Assortment_Detail__c WHERE Id IN :AssToDelete];
        System.debug(assortmentDetailsToDelete);
        List<Database.DeleteResult> assortmentResults = database.delete(assortmentDetailsToDelete, true);
        }
        if (String.isNotBlank(addedProducts)) {
        List<Id> ProductsToAdd = (List<Id>)JSON.deserialize(addedProducts,List<Id>.class);
        List<Product2> products  = [SELECT Id,Category__c FROM Product2 WHERE Id IN :ProductsToAdd];
        List<Assortment_Detail__c> createdAssortmentDetails = new List<Assortment_Detail__c>();
        for (Product2 item :products ) {
            createdAssortmentDetails.add(new Assortment_Detail__c(Assortment_BU__c = assBUId, Product__c = item.id,Category__c = item.Category__c));
        }
        System.debug(createdAssortmentDetails);
        List<Database.SaveResult> assortmentDetailResults = Database.insert(createdAssortmentDetails, true);
        
        }
        return JSON.serialize(A);
        }catch(DmlException DML) {
            System.debug(Logginglevel.ERROR, DML.getStackTraceString());
            throw new AuraHandledException(DML.getDmlMessage(0));
        }catch(Exception E){
            System.debug(Logginglevel.ERROR, E.getStackTraceString());
            throw new AuraHandledException('Error');
        }
    }
        @AuraEnabled
        public static PagingWrapper getsProductRecords(String recId,String Path,Integer LimitSize,Integer offset,String SearchTerm){
        List<Product2> sobl = LoadRecords( Path, LimitSize, offset,SearchTerm);
        List<Assortment_Detail__c> adl = getsExistingRecords(sobl,recId);
        List<ProductWrapper> LstPWrap = new List<ProductWrapper>();
        for(Product2 item : sobl){
            LstPWrap.add(new ProductWrapper(item));
        }
        PagingWrapper Pw = new PagingWrapper();
        System.debug(LstPWrap);
        System.debug(adl);
        Pw.PageData = JSON.serialize(LstPWrap);
        Pw.PageAssBUDetails = JSON.serialize(adl);
        Pw.Total = getsObjectCountRecords(Path,SearchTerm);
        return Pw;
    }
    @AuraEnabled
    public static List<Product2> LoadRecords(String Path,Integer LimitSize,Integer offset,String SearchTerm ){
        Path = Path+'%';
        
        String query = 'SELECT Id,Name,Logo__c,Product_EAN__c,Brand__c,Brand__r.Name,Category__r.Parent_Element__r.Name, ';
                                        query +='Category__c,Category__r.Name,Category__r.Path__c,ProductCode,Ext_id__c ';
                                        query +='FROM Product2 ';
                                        query +='WHERE Category__r.Path__c like \''+Path+'\' AND IsActive = true ';
                                        
        if(String.isNotEmpty(SearchTerm)){
            SearchTerm =  '%'+String.escapeSingleQuotes(SearchTerm)+'%';
        query += ' AND (Category__r.Long_Name__c LIKE \''+SearchTerm+'\'';
        query += ' OR Brand__r.Name LIKE \''+SearchTerm+'\'';
        query += ' OR Category__r.Parent_Element__r.Name LIKE \''+SearchTerm+'\'';
        query += ' OR Product_EAN__c LIKE \''+SearchTerm+'\' ';
        query += ' OR Name LIKE \''+SearchTerm+'\')';
        }

        query +=' LIMIT '+LimitSize+' ';
        query +=' OFFSET '+offset+' ';
        system.debug(query);
         List<Product2> ProductList = Database.query(query)     ;                   
         return ProductList;
    }
    @AuraEnabled
    public static String HeaderData(String recordId){ 
        Assortment_BU__c Assort = [SELECT Name FROM Assortment_BU__c WHERE Id = :recordId LIMIT 1];
        List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(new List<String>{'Assortment_BU__c'}); // this can accept list of strings, we describe only one object here
        String Label = describeSobjectsResult[0].getLabel();
        HeaderWrapper HW = new HeaderWrapper();
        HW.LongName = Assort.Name;
        HW.Label = Label;
        system.debug(HW);
        return JSON.serialize(HW);
    }
    @AuraEnabled(cacheable=true)
    public static String getIconName(String sObjectName){
        String u;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

        for(Schema.DescribeTabSetResult tsr : tabSetDesc) { tabDesc.addAll(tsr.getTabs()); }

        for(Schema.DescribeTabResult tr : tabDesc) {
            if( sObjectName == tr.getSobjectName() ) {
                if( tr.isCustom() == true ) {
                    iconDesc.addAll(tr.getIcons());
                } else {
                    u = 'standard:' + sObjectName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) {
            if (ir.getContentType() == 'image/svg+xml'){
                u = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }
        System.debug('Before '+u);
        
        if(u.endsWith('2')){
            System.debug('has 2');
        u = (u.substring(0, u.length()-1));
        }
        System.debug('After '+u);
        return u;
    }
    public class HeaderWrapper {
        @AuraEnabled
        public String LongName;
        @AuraEnabled
        public String Label;
        
    }
    
    public class DataTableWrapper {
        @AuraEnabled
        public String sobList;
        @AuraEnabled
        public String AssBUDetailsList;
        @AuraEnabled
        public List<String> fieldsList;
        @AuraEnabled
        public Integer totalCount;
    }
    public class PagingWrapper {
        @AuraEnabled
        public String PageData;
        @AuraEnabled
        public String PageAssBUDetails;
        @AuraEnabled
        public Integer Total;
    }
    
    
    public class LabelDescriptionWrapper {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public boolean sortable;
        
        public LabelDescriptionWrapper(String labelTemp, String fieldNameTemp, String typeTemp, boolean sortableTemp) {
            label 	  = labelTemp;
            fieldName = fieldNameTemp;
            type 	  = typeTemp;
            sortable  = sortableTemp;
        }
            
    }
            public class ProductWrapper {
            @AuraEnabled
            public String Id {get; set;}
            @AuraEnabled
            public String Name {get; set;}
            @AuraEnabled
            public string BrandName {get; set;}
            @AuraEnabled
            public string CategoryName {get; set;}
            @AuraEnabled
            public string ParetnElementName {get; set;}
            @AuraEnabled
            public string ProductEAN {get; set;}
            @AuraEnabled
            public string attrA {get; set;}
            @AuraEnabled
            public Boolean ShowIcon {get; set;}
            @AuraEnabled
            public Boolean attrB {get; set;}
            @AuraEnabled
            public String status {get; set;}
            public ProductWrapper(Product2 product) {
                this.Id = product.Id;
                this.Name = product.Name;
                this.BrandName = product.Brand__r.name;
                this.CategoryName = product.Category__r.Name;
                this.ParetnElementName = product.Category__r.Parent_Element__r.Name;
                this.ProductEAN = product.Product_EAN__c;
                this.status = 'myCSS';
                if(String.isNotEmpty(product.Logo__c)){
                this.ShowIcon = false;
                this.attrB = false;
                this.attrA = product.Logo__c;
                }
                else{
                this.ShowIcon = true;
                this.attrB = true;
                this.attrA = 'standard:product';
                }
            }
        }
        @AuraEnabled
        public static boolean importFilteredProducts(String AssBU ,String Path,String SearchTerm) {
           try{
                Path = Path+'%';
             SearchTerm =  '%'+String.escapeSingleQuotes(SearchTerm)+'%';
        List<Product2> Products = [SELECT Id,Category__c 
                                  FROM Product2 
                                  WHERE Category__r.Path__c like :Path AND IsActive = true 
                                  AND (Category__r.Long_Name__c LIKE :SearchTerm
                                  OR Category__r.Parent_Element__r.Name LIKE :SearchTerm
                                  OR Product_EAN__c LIKE :SearchTerm
                                  OR Name LIKE :SearchTerm)];
        List<Assortment_Detail__c> createdAssortmentDetails = new List<Assortment_Detail__c>();
        List<Assortment_Detail__c> existingAssDetail= [SELECT Product__r.Id from Assortment_Detail__c where Id = :AssBU];
        List<Id> existingAssDetailProductsId = new List<Id>();
        System.debug('returned products >>>'+Products);
        for (Assortment_Detail__c item :existingAssDetail){
            existingAssDetailProductsId.add(item.Product__r.Id);
        }
        for (Product2 item : Products) {
            if(!existingAssDetailProductsId.contains(item.Id))
            createdAssortmentDetails.add(new Assortment_Detail__c(Assortment_BU__c = AssBU, Product__c = item.id,Category__c = item.Category__c));
        }
         System.debug('About to be inserted Assortment Details >>>'+createdAssortmentDetails);
         List<Database.SaveResult> assortmentDetailResults = Database.insert(createdAssortmentDetails, true);
         System.debug('Insertion Done');
         return true;
        }catch(DmlException DML) {
            System.debug(Logginglevel.ERROR, DML.getStackTraceString());
            throw new AuraHandledException(DML.getDmlMessage(0));
        }catch(Exception E){
            System.debug(Logginglevel.ERROR, E.getStackTraceString());
            throw new AuraHandledException('Error');
        } 
        }
        /*getBoundingClientRect()*/
   @AuraEnabled
   public static String getLookupSerachRecords(String SearchTerm, String selectedSObject, Integer recordLimit,String Path) {  
     String query;
     if(String.isNotEmpty(SearchTerm)){
     Path = Path+'%';
         query = 'SELECT Name,Product_EAN__c,Category__c ';
         query +='FROM Product2 ';
         query +='WHERE Category__r.Path__c like \''+Path+'\' AND IsActive = true ';
                                        
        
            SearchTerm =  '%'+String.escapeSingleQuotes(SearchTerm)+'%';
        query += ' AND (Category__r.Long_Name__c LIKE \''+SearchTerm+'\'';
        query += ' OR Category__r.Parent_Element__r.Name LIKE \''+SearchTerm+'\'';
        query += ' OR Product_EAN__c LIKE \''+SearchTerm+'\' ';
        query += ' OR Name LIKE \''+SearchTerm+'\')';
        
        system.debug(query);
         List<Product2> ProductList = Database.query(query)     ;                   
         return JSON.serialize(ProductList);
    }
    return JSON.serialize('');
   }
     
}