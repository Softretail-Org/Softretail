/**
 * Class Called from process builder to
 * set related assortment details Client Product Code
 * */
global class UpdateRelatedAssortmentDetailsInvocable {
    
    @InvocableMethod(label='Update Related Assortment Details Client Product Code Invocable' description='Update Related Assortment Details Client Product Code Invocable.')
    public static void updateRelatedAssortmentDetailsClientProductCode(List<Assortment_Detail__c> assortmentDetails) {
        if(assortmentDetails == null || assortmentDetails.isEmpty()) {
            return;
        }
        
        Set<Id> assortmentIdSet = new Set<Id>();
        Set<Id> assortmentDetailsIdIgnoreSet = new Set<Id>();
        Map<Id, String> productCodeMap = new Map<Id, String>();
        Map<Id, Integer> productLowerYearMap = new Map<Id, Integer>();
        Integer minYear = Integer.valueof(assortmentDetails.get(0).Year__c);
        
        for (Assortment_Detail__c item : assortmentDetails) {
            assortmentIdSet.add(item.Assortment_BU__c);
            // Assortment details lines to be ignored from updates
            assortmentDetailsIdIgnoreSet.add(item.Id);
            // Put each product with the new client code
            productCodeMap.put(item.Product__c, item.Client_Product_Code__c);
            // Put each product with the it's lower assortment year
            if (productLowerYearMap.containsKey(item.Product__c)) {
                if (productLowerYearMap.get(item.Product__c) < item.Year__c) {
                    productLowerYearMap.put(item.Product__c, Integer.valueof(item.Year__c));
                }
            } else {
                productLowerYearMap.put(item.Product__c, Integer.valueof(item.Year__c));
            }
            // Get the lower assortment year
            if (item.Year__c < minYear) minYear = Integer.valueof(item.Year__c);
        }
        // Get the Country Origin Ids
        Set<Id> BUSet = new Set<Id>();
        for (Assortment_BU__c item : [SELECT Id, BU_Target__r.Country_Origin__r.BU_Code__c
                                      FROM Assortment_BU__c
                                      WHERE Id IN :assortmentIdSet])
        {
            BUSet.add(item.BU_Target__r.Country_Origin__c);
        }
        // Assortment details lines matching filters to be updated
        List<Assortment_Detail__c> listToUpdate = new List<Assortment_Detail__c> ();
        for (Assortment_Detail__c item : [SELECT Id, Product__c, Client_Product_Code__c, Year__c, Assortment_BU__r.BU_Target__c
                                          FROM Assortment_Detail__c
                                          WHERE Id NOT IN :assortmentDetailsIdIgnoreSet
                                          AND Assortment_BU__c IN (SELECT Id
                                                                   FROM Assortment_BU__c
                                                                   WHERE BU_Target__r.Country_Origin__c IN :BUSet)
                                          AND Product__c IN :productCodeMap.keySet()
                                          AND Year__c >= :minYear
                                          AND Version__c = NULL])
        {
            if (productLowerYearMap.containsKey(item.Product__c) && item.Year__c >= productLowerYearMap.get(item.Product__c)) {
                item.Client_Product_Code__c = productCodeMap.get(item.Product__c);
                listToUpdate.add(item);
            }
        }
        // Check and Save data
        String[] fields = new String[]{NegoptimHelper.normalizeAPIName('Client_Product_Code__c')};
        if(!listToUpdate.isEmpty() && NegoptimHelper.checkUpdatibility(Assortment_Detail__c.SObjectType, fields)) {
            update listToUpdate;
        }
    }
}