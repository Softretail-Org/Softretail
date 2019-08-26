/**
 * Generate Assortment_Matrix_review__c on-After Insert/Update
 */ 
trigger Trg_Assortment_SF_Data_Collection on Assortment_SF_Data_Collection__c (after insert, after update) {
    if (trigger.isAfter) {
        if (trigger.isInsert || trigger.isUpdate) {
            Set<Id> productSet = new Set<Id>();
            Set<Id> buTargetSet = new Set<Id>();
            Set<Integer> monthSet = new Set<Integer>();
            Set<Integer> yearSet = new Set<Integer>();
            List<Assortment_Matrix_review__c> assortmentMatrixReviews = new List<Assortment_Matrix_review__c>();
            for (Assortment_SF_Data_Collection__c item : Trigger.new) {
                if(item.Product__c != null && !productSet.contains(item.Product__c)) {
                    productSet.add(item.Product__c);
                }
                if(item.Orga_BU__c != null && !buTargetSet.contains(item.Orga_BU__c)) {
                    buTargetSet.add(item.Orga_BU__c);
                }
                if(item.Movment_Date__c != null) {
                    monthSet.add(Integer.valueOf(item.Movment_Date__c.month()));
                    yearSet.add(Integer.valueOf(item.Movment_Date__c.year()));
                }
            }            
            // get old assortment Matrix reviews
            Map<String, Assortment_Matrix_review__c> assortmentMatrixReviewMap = new Map<String, Assortment_Matrix_review__c>();
            for(Assortment_Matrix_review__c item : [SELECT Id, BU_Source__c, BU_Target__c, Category__c, Produit__c, Sequence__c, Year__c, Name__c, ND__c
                                                    FROM Assortment_Matrix_review__c
                                                    WHERE BU_Target__c IN :buTargetSet AND Produit__c IN :productSet
                                                    AND Year__c IN :yearSet AND Sequence__c IN :monthSet AND Name__c = 'Salesforce'])
            {
                String key = item.BU_Target__c + '' + item.Produit__c + '' + Integer.valueOf(item.Year__c) + '' + Integer.valueOf(item.Sequence__c);
                if(!assortmentMatrixReviewMap.containsKey(key)) {
                    assortmentMatrixReviewMap.put(key, item);
                }
            }
            for (Assortment_SF_Data_Collection__c item : Trigger.new) {
                if(item.Movment_Date__c != null) {
                    String key = item.Orga_BU__c + '' + item.Product__c + '' + Integer.valueOf(item.Movment_Date__c.year()) + '' + Integer.valueOf(item.Movment_Date__c.month());
                    Assortment_Matrix_review__c assortmentMatrixReview;                    
                    if(assortmentMatrixReviewMap.containsKey(key)) {
                        assortmentMatrixReview = assortmentMatrixReviewMap.get(key);
                    } else {
                        // insert assortment Matrix review
                        assortmentMatrixReview = new Assortment_Matrix_review__c(BU_Source__c = null,
                                                                                 BU_Target__c = item.Orga_BU__c,
                                                                                 Produit__c = item.Product__c,
                                                                                 Sequence__c = Integer.valueOf(item.Movment_Date__c.month()),
                                                                                 Year__c = Integer.valueOf(item.Movment_Date__c.year()),
                                                                                 Name__c = 'Salesforce');
                    }
                    assortmentMatrixReview.ND__c = item.ND__c;
                    assortmentMatrixReviews.add(assortmentMatrixReview);
                }
            }
            // upsert assortment matrix reviews
            if(!assortmentMatrixReviews.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(assortmentMatrixReviews, false);
            }
        }
    }
}