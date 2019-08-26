public with sharing class SampleLookupController {

    private final static Integer MAX_RESULTS = 10;

    @AuraEnabled(Cacheable=true)
    public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds,String Path) {
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
         query += ' LIMIT '+MAX_RESULTS;
        system.debug(query);
              }
 
        List< product2> searchResults = Database.query(query);

        // Prepare results
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        // Extract Accounts & convert them into LookupSearchResult
        String productIcon = 'standard:product';
         
        for (product2 product : searchResults) {
            results.add(new LookupSearchResult(product.Id, 'Product', productIcon, product.Name,'Account • '+ product.Product_EAN__c));
        }


        return results;
    }
    @AuraEnabled()
    public static String searchSOSL(String searchTerm, String Path,String field) {
        List<List<SObject>> searchResults ;
        Path = Path+'%';
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        if ( String.isNotEmpty(SearchTerm)&& String.isNotEmpty(field) ) {
                searchResults = [FIND :searchTerM IN NAME FIELDS   
                    RETURNING Sup_brand__c(Id,Name),
                              Orga_HE__c(Id,Name,Parent_Element__c where Path__c like :Path),
                              Product2(Name,Product_EAN__c,Category__c WHERE IsActive = true And Category__r.Path__c like :Path)  
                     LIMIT :MAX_RESULTS];

        List<Product2> Products = searchResults[2];
        List< Orga_HE__c> Categories = searchResults[1];
        List<Sup_brand__c> Brands = searchResults[0];
        System.debug('>>>'+Products);
        // Extract Accounts & convert them into LookupSearchResult
        String productIcon = 'standard:product';
        String lookupString;

        if(field.equals('All') || field.equals('Product_EAN__c') || field.equals('Name')) {
            for (product2 product : Products) {
                lookupString =  'EAN •'+ product.Product_EAN__c ;
                results.add(new LookupSearchResult(product.Id, 'Product2', productIcon, product.Name,lookupString));
            }
        }
        productIcon = 'https://negoptim-qa-dev-ed--c.eu17.content.force.com/servlet/servlet.ImageServer?id=0151v000002wqBj&oid=00D0Y000000ZAyy&lastMod=1553007972000';
        if(field.equals('All') || field.equals('Brand__c')) {
            for (Sup_Brand__c Brand : Brands) {
                lookupString =  'Brand •'+ Brand.Name  ;
                results.add(new LookupSearchResult(Brand.Id, 'Sup_brand__c', productIcon, Brand.Name,lookupString));
            }
        }
        productIcon = 'https://negoptim-qa-dev-ed--c.eu17.content.force.com/servlet/servlet.ImageServer?id=0151v000002wqBm&oid=00D0Y000000ZAyy&lastMod=1553007972000';
        if(field.equals('All') || field.equals('Category__c')) {
            for (Orga_HE__c Category : Categories) {
                lookupString =   'Category •'+ Category.Name  ;
                results.add(new LookupSearchResult(Category.Id, 'Orga_HE__c', productIcon, Category.Name,lookupString));
            }
        }
    }
    return JSON.serialize(results);
    }


    @AuraEnabled(Cacheable=true)
    public static List<LookupSearchResult> searchh(String searchTerm, List<String> selectedIds) {
        // Prepare query paramters
        searchTerm += '*';
        
        // Execute search query
        List<List<SObject>> searchResults = [FIND :searchTerm IN ALL FIELDS RETURNING
            Account (Id, Name, BillingCity WHERE id NOT IN :selectedIds),
            Opportunity (Id, Name, StageName WHERE id NOT IN :selectedIds)
            LIMIT :MAX_RESULTS];

        // Prepare results
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        // Extract Accounts & convert them into LookupSearchResult
        String accountIcon = 'standard:account';
        Account [] accounts = ((List<Account>) searchResults[0]);
        for (Account account : accounts) {
            results.add(new LookupSearchResult(account.Id, 'Account', accountIcon, account.Name, 'Account • '+ account.BillingCity));
        }

        // Extract Opportunities & convert them into LookupSearchResult
        String opptyIcon = 'standard:opportunity';
        Opportunity [] opptys = ((List<Opportunity>) searchResults[1]);
        for (Opportunity oppty : opptys) {
            results.add(new LookupSearchResult(oppty.Id, 'Opportunity', opptyIcon, oppty.Name, 'Opportunity • '+ oppty.StageName));
        }
        System.debug(results);
        return results;
    }








}