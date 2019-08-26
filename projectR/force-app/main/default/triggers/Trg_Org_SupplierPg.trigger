/**
* Check and validate uniqueness constraint of name in Product Group (Supplier_PG_Mapping__c)
* Check and validate uniqueness constraint of name, code, supplier and section  in Product Group (Supplier_PG_Mapping__c)
* Check and validate uniqueness constraint of name, supplier and section in Product Group (Supplier_PG_Mapping__c)
* Check and validate uniqueness constraint of supplier and product
* On PG creation we add the Pg in negoscope if it has field Include New product = true 
* On Pg deletion , delete relation between pg and negoscope
**/
trigger Trg_Org_SupplierPg on Supplier_PG_Mapping__c (before insert, before update, after insert, before delete, after delete) {
    
    String errMsg  = System.Label.MSG_Product_Group_Already_Exists_With_The_Same_Name;
    String errMsg2 = System.Label.MSG_The_Combination_Code_Supplier_Section_Keys_Must_Be_Unique;
    String errMsg3 = System.Label.MSG_The_Combination_Name_Supplier_Keys_Must_Be_Unique;
    String errMsg4 = System.Label.MSG_The_combination_of_Supplier_and_Product_must_be_unique;
    
    Map<String, Supplier_PG_Mapping__c> PGMap = new Map<String, Supplier_PG_Mapping__c>();
    // Map with Key combination of Supplier__c, Section__c and GIMA_Code__c
    Map<String, Supplier_PG_Mapping__c> supplierSectionGIMAMap = new Map<String, Supplier_PG_Mapping__c>();
    // Map with Key combination of Supplier__c and Product__c.
    Map<String, Supplier_PG_Mapping__c> supplierProductMap = new Map<String, Supplier_PG_Mapping__c>();
    /*// Map with Key combination of PG Name and Supplier__c
    Map<String, Supplier_PG_Mapping__c> pgNameSupplierMap = new Map<String, Supplier_PG_Mapping__c>();*/
    /*Set<String> pgNameSet = new Set<String>();*/
    Set<Id> supplierSet = new Set<Id>();
    Set<Id> sectionSet = new Set<Id>();
    Set<String> gimaSet = new Set<String>();
    Set<Id> productSet = new Set<Id>();
    /*Set<Sup_NS_PG__c> setAllNegoscopePG = new Set<Sup_NS_PG__c>();*/
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Supplier_PG_Mapping__c PG : System.Trigger.new) {
                /*// fill the Sets
                if(!pgNameSet.contains(PG.Name)) {
                    pgNameSet.add(PG.Name);
                }*/
                if(!supplierSet.contains(PG.Supplier__c)) {
                    supplierSet.add(PG.Supplier__c);
                }
                if(!sectionSet.contains(PG.Section__c)) {
                    sectionSet.add(PG.Section__c);
                }
                if(!gimaSet.contains(PG.GIMA_Code__c)) {
                    gimaSet.add(PG.GIMA_Code__c);
                }
                if(!productSet.contains(PG.Product__c)) {
                    productSet.add(PG.Product__c);
                }
                if (System.Trigger.isInsert || (System.Trigger.isUpdate
                                                && ((PG.GIMA_Code__c != System.Trigger.oldMap.get(PG.Id).GIMA_Code__c)
                                                    || (PG.Supplier__c != System.Trigger.oldMap.get(PG.Id).Supplier__c)
                                                    || (PG.Section__c != System.Trigger.oldMap.get(PG.Id).Section__c))))
                {
                    String key = PG.Supplier__c + '' + PG.Section__c + '' + PG.GIMA_Code__c;
                    // Make sure another new Product Group isn't also a duplicate  by code, supplier and section
                    if (supplierSectionGIMAMap.containsKey(key)) {
                        PG.addError(errMsg2);
                    } else {
                        supplierSectionGIMAMap.put(key, PG);
                    }
                }
                /***
                if (System.Trigger.isInsert || (System.Trigger.isUpdate && ((PG.name != System.Trigger.oldMap.get(PG.Id).name)
                                                || (PG.Supplier__c != System.Trigger.oldMap.get(PG.Id).Supplier__c))))
                {
                    String keyId = PG.Name + '' + PG.Supplier__c;
                    // Make sure another new Product Group isn't also a duplicate by name, supplier
                    if (pgNameSupplierMap.containsKey(keyId)) {
                        PG.addError(errMsg3);
                    } else {
                        pgNameSupplierMap.put(keyId, PG);
                    }
                }
				***/
                // Restriction of the duplication of Supplier + product.
                if ((System.Trigger.isInsert || (System.Trigger.isUpdate && (PG.Product__c != System.Trigger.oldMap.get(PG.Id).Product__c)))
                    && PG.Product__c != null)
                {
                    String key = PG.Supplier__c + '' + PG.Product__c;
                    if (supplierProductMap.containsKey(key)) {
                        PG.addError(errMsg4);
                    } else {
                        supplierProductMap.put(key, PG);
                    }
                }
            }
            
            // Using a single database query, find all the PG  in the database that have the same combination of code + supplier + section or
            // supplier + product of the records being inserted or updated.     
            for (Supplier_PG_Mapping__c item : [SELECT Name, GIMA_Code__c, Supplier__c, Section__c, Product__c
                                                FROM Supplier_PG_Mapping__c
                                                WHERE Supplier__c IN :supplierSet
                                                AND ((Section__c IN :sectionSet
                                                      AND GIMA_Code__c IN :gimaSet)
                                                     OR Product__c IN :productSet)])
            {
                String key1 = item.Supplier__c + '' + item.Section__c + '' + item.GIMA_Code__c;
                String key2 = item.Supplier__c + '' + item.Product__c;
                if (supplierSectionGIMAMap.get(key1) != null) {
                    supplierSectionGIMAMap.get(key1).addError(errMsg2); 
                }
                /***
                String key = item.Name + '' + item.Supplier__c;
                if (pgNameSupplierMap.get(key) != null) {
                    pgNameSupplierMap.get(key).addError(errMsg3); 
                }
				***/
                // Restriction of the duplication of Supplier + product.
                if (supplierProductMap.get(key2) != null) {
                    supplierProductMap.get(key2).addError(errMsg4); 
                }
            }
        }
        
        // Check if the NS_PG deleted is linked to sell_in_flow.
        // On Before-Delete
        if(Trigger.isDelete) {
            // reparenting sell_in on delete NS_PG
            if(!System.isBatch() && !System.isFuture()) {
                List<Sup_NS_PG__c> nsPGList = new List<Sup_NS_PG__c>();
                for(Sup_NS_PG__c item : [SELECT Id, Sup_PG__c, Sup_sup_NegoScope__c, Sup_PG__r.Product__c, Sup_PG__r.Supplier__c
                                         FROM Sup_NS_PG__c WHERE Sup_PG__c IN :Trigger.old])
                {
                    if(item.Sup_PG__r.Product__c != null && item.Sup_PG__r.Supplier__c != null) {
                        nsPGList.add(item);
                    }
                }
                if(!nsPGList.isEmpty()) {
                    Database.executeBatch(new ReparentingSellinBatch('Before Delete Assortment', null, null, null, null, null, nsPGList, null, null, false, null, null));
                }
            }
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            Map<Id,List<Id>> mapSuppPg = new Map<Id,List<Id>>();
            List<Id> listBrandId = new List<Id>();
            List<Id> listHeDepId = new List<Id>();
            List<Id> listHeSecId = new List<Id>();
            // Todo : rewrite for better format and practice maybe
            
            for (Supplier_PG_Mapping__c PG : System.Trigger.new ) {
                // add list of pg id into a map by supplier as key 
                if(mapSuppPg.containsKey(PG.Supplier__c)) {
                    mapSuppPg.get(PG.Supplier__c).add(PG.Id);
                } else {
                    mapSuppPg.put(PG.Supplier__c, new List<Id> { PG.Id });
                }
                // collect brand id and he comming from pg's
                if(PG.Brand__c != null) {
                    listBrandId.add(PG.Brand__c);
                }
                
                listHeDepId.add(PG.Department__c);
                listHeSecId.add(PG.Section__c);
            }
            Set<Id> setNegoScopeId = new Set<Id>();
            
            Map<Id, List<Sup_sup_NegoScope__c>> supplierNegoscopeMap = new Map<Id, List<Sup_sup_NegoScope__c>>();
            for(Sup_sup_NegoScope__c item : [SELECT Id, Name, Supplier__c, Is_All__c, Is_All_HE__c, Is_All_Brands__c, Incl_NewProduct__c,
                                             (SELECT Sup_sup_NegoScope__c, Structure_Element__c, Structure_Element__r.Level__c, Choice__c
                                              FROM Supplier_Nego_Scope_HEs__r
                                              WHERE (Structure_Element__r.Level__c = 0
                                                     OR Structure_Element__c IN :listHeDepId
                                                     OR Structure_Element__c IN :listHeSecId)
                                              ORDER BY Structure_Element__r.Level__c DESC),
                                             (SELECT Sup_sup_NegoScope__c, Sup_Scope_Brand__c
                                              FROM Supplier_Nego_scope_Brands__r
                                              WHERE Sup_Scope_Brand__c IN :listBrandId)
                                             FROM Sup_sup_NegoScope__c
                                             WHERE Supplier__c IN :mapSuppPg.keySet()
                                             AND (Incl_NewProduct__c = true OR Is_All__c = true)])
            {
                // fill the records having NS_HE
                if(item.Supplier_Nego_Scope_HEs__r.size() > 0) {
                    if(supplierNegoscopeMap.containsKey(item.Supplier__c)) {
                        supplierNegoscopeMap.get(item.Supplier__c).add(item);
                    } else {
                        supplierNegoscopeMap.put(item.Supplier__c, new List<Sup_sup_NegoScope__c> {item});
                    }
                }
            }
            Map<String, Sup_sup_NegoScope__c> pgNSMap = new Map<String, Sup_sup_NegoScope__c>();
            for(Id key : supplierNegoscopeMap.keySet()) {
                for(Supplier_PG_Mapping__c pg : System.Trigger.new) {
                    if(pg.Supplier__c == key) {
                        for(Sup_sup_NegoScope__c item : supplierNegoscopeMap.get(key)) {
                            String pgNSkey = pg.Id + '-' + item.Id;
                            if(!item.Is_All_HE__c) {
                                // Check Department/Section
                                for(Supplier_NS_HE__c nshe : item.Supplier_Nego_Scope_HEs__r) {
                                    // Check Section first then Department then root because it is ordered by Level__c DESC
                                    if(pg.Section__c == nshe.Structure_Element__c) {
                                        if(nshe.Choice__c == 'Include' && !pgNSMap.containsKey(pgNSkey))
                                            pgNSMap.put(pgNSkey, item);
                                        else if(nshe.Choice__c == 'Exclude' && pgNSMap.containsKey(pgNSkey))
                                            pgNSMap.put(pgNSkey, item);
                                        break;
                                    } else if(pg.Department__c == nshe.Structure_Element__c) {
                                        if(nshe.Choice__c == 'Include' && !pgNSMap.containsKey(pgNSkey))
                                            pgNSMap.put(pgNSkey, item);
                                        else if(nshe.Choice__c == 'Exclude' && pgNSMap.containsKey(pgNSkey))
                                            pgNSMap.put(pgNSkey, item);
                                        break;
                                    } else if(nshe.Structure_Element__r.Level__c == 0) {
                                        if(nshe.Choice__c == 'Include' && !pgNSMap.containsKey(pgNSkey))
                                            pgNSMap.put(pgNSkey, item);
                                        else if(nshe.Choice__c == 'Exclude' && pgNSMap.containsKey(pgNSkey))
                                            pgNSMap.put(pgNSkey, item);
                                        break;
                                    }
                                }
                            } else {
                                pgNSMap.put(pgNSkey, item);
                            }
                            // Check Brand
                            if(!item.Is_All_Brands__c && pg.Brand__c != null) { // ignore filter on brands if it is on all brands or the pg not related to a brand
                                Integer totalNSBrandsCount = item.Supplier_Nego_scope_Brands__r.size();
                                for(Sup_NS_Brand__c nsbrand : item.Supplier_Nego_scope_Brands__r) {
                                    if(pg.Brand__c != nsbrand.Sup_Scope_Brand__c) {
                                        totalNSBrandsCount--;
                                    }
                                    else {
                                        break;
                                    }
                                }
                                if(totalNSBrandsCount == 0) {
                                    pgNSMap.remove(pgNSkey);
                                }
                            }
                        }
                    }
                }
            }
            List<Sup_NS_PG__c> nsPGList = new List<Sup_NS_PG__c>();
            for(String key : pgNSMap.keySet()) {
                Id pgId = Id.valueOf(key.split('-')[0]);
                nsPGList.add(new Sup_NS_PG__c(Sup_PG__c = pgId, Supplier__c = pgNSMap.get(key).Supplier__c, Sup_sup_NegoScope__c = pgNSMap.get(key).Id));
            }
            insert nsPGList;
            
            /**** OLD CODE - TO BE DELETED ****
            List<Sup_sup_NegoScope__c> allNegoscopeWithRoot = [SELECT Id FROM Sup_sup_NegoScope__c
                                                               WHERE Supplier__c IN :mapSuppPg.keySet()
                                                               AND Id IN (SELECT Sup_sup_NegoScope__c
                                                                          FROM Supplier_NS_HE__c
                                                                          WHERE Structure_Element__r.Level__c = 0)
                                                               AND Id NOT IN (SELECT Sup_sup_NegoScope__c
                                                                              FROM Supplier_NS_HE__c
                                                                              WHERE Structure_Element__r.Level__c = 1
                                                                              OR Structure_Element__r.Level__c = 2)];
            
            if(allNegoscopeWithRoot != NULL && allNegoscopeWithRoot.size() > 0) {
                for(Sup_sup_NegoScope__c negoscope : allNegoscopeWithRoot) {
                    setNegoScopeId.add(negoscope.Id);
                }
            }
            
            List<Supplier_NS_HE__c> allNegoscopeWithRootAndHe = [SELECT Sup_sup_NegoScope__c FROM Supplier_NS_HE__c
                                                                 WHERE Sup_sup_NegoScope__r.Supplier__c IN :mapSuppPg.keySet()
                                                                 AND ((Structure_Element__c IN :listHeDepId
                                                                       AND Choice__c='Include'
                                                                       AND Structure_Element__r.Level__c = 1)
                                                                      OR (Structure_Element__c IN :listHeSecId
                                                                          AND Choice__c='Include' 
                                                                          AND Structure_Element__r.Level__c = 2))];
            
            if(allNegoscopeWithRootAndHe != NULL && allNegoscopeWithRootAndHe.size() > 0) {
                for(Supplier_NS_HE__c negoscope : allNegoscopeWithRootAndHe) {
                    setNegoScopeId.add(negoscope.Sup_sup_NegoScope__c);
                }
            }
            
            List<Supplier_NS_HE__c> allNegoscopeWithRootAndNotInHe = [Select Sup_sup_NegoScope__c FROM Supplier_NS_HE__c
                                                                      WHERE Structure_Element__r.Level__c = 0 
                                                                      AND Structure_Element__c NOT IN :listHeDepId 
                                                                      AND Structure_Element__c NOT IN :listHeSecId ];
            
            if(allNegoscopeWithRootAndNotInHe != NULL && allNegoscopeWithRootAndNotInHe.size() > 0) {
                for(Supplier_NS_HE__c negoscope : allNegoscopeWithRootAndNotInHe) {
                    setNegoScopeId.add(negoscope.Sup_sup_NegoScope__c);
                }
            }
            
            List<AggregateResult> allNegoscopeWithHe = [Select Sup_sup_NegoScope__c nsId FROM Supplier_NS_HE__c
                                                        WHERE  ((Structure_Element__c IN :listHeDepId AND Choice__c='Include' 
                                                                 AND Structure_Element__r.Level__c = 1 ) 
                                                                OR (Structure_Element__c IN :listHeSecId AND Choice__c='Include' 
                                                                    AND Structure_Element__r.Level__c = 2))
                                                        GROUP BY Sup_sup_NegoScope__c ];
            
            // filter pg by dep and section that are included
            if(allNegoscopeWithHe != NULL && allNegoscopeWithHe.size() > 0) {
                for(AggregateResult negoscope : allNegoscopeWithHe) {
                    setNegoScopeId.add((Id)negoscope.get('nsId'));
                }
            }
            
            List<Supplier_NS_HE__c> allNegoscopeWithSectionExclude = [Select Sup_sup_NegoScope__c FROM Supplier_NS_HE__c
                                                                      WHERE (Structure_Element__c IN :listHeSecId AND Choice__c='Exclude' 
                                                                             AND Structure_Element__r.Level__c = 2)];
            if(allNegoscopeWithSectionExclude!= null && allNegoscopeWithSectionExclude.size() > 0){
                for(Supplier_NS_HE__c negoscope : allNegoscopeWithSectionExclude) {
                    if(setNegoScopeId.contains(negoscope.Sup_sup_NegoScope__c)){
                        setNegoScopeId.remove(negoscope.Sup_sup_NegoScope__c);
                    }
                }
            }
            List<Id> listNegoScopeId = new List<Id>();
            if(listBrandId.size() > 0){
                
                // filter nego scope id based on brand
                List<Sup_NS_Brand__c> allNegoScopeBrand = [Select Sup_sup_NegoScope__c FROM Sup_NS_Brand__c WHERE Sup_Scope_Brand__c IN:listBrandId];
                
                // mashkal hun ..new query to getall negoscope that doesnt have any dep or sec to compare with brand loop
                if(allNegoScopeBrand != NULL && allNegoScopeBrand.size() > 0) {
                    for(Id  NsId : setNegoScopeId){
                        for(Sup_NS_Brand__c negoscope : allNegoScopeBrand) {
                            if(negoscope.Sup_sup_NegoScope__c == NsId){
                                listNegoScopeId.add(negoscope.Sup_sup_NegoScope__c);
                            }
                        }
                    }
                }
            }else{
                listNegoScopeId.addAll(setNegoScopeId);
            }
            
            // Add Pg to on Dep and section with new product include true
            for(Sup_sup_NegoScope__c item : [SELECT Id, Name, Is_All__c, Supplier__c, Incl_NewProduct__c
                                             FROM Sup_sup_NegoScope__c 
                                             WHERE Id IN :listNegoScopeId
                                             AND Supplier__c IN :mapSuppPg.KeySet()
                                             AND Incl_NewProduct__c = true])
            {
                for (Supplier_PG_Mapping__c pg : System.Trigger.new) {
                    if(pg.Supplier__c == item.Supplier__c) {
                        setAllNegoscopePG.add(new Sup_NS_PG__c(Sup_PG__c = pg.Id, Supplier__c = item.Supplier__c, Sup_sup_NegoScope__c = item.Id));
                    }
                }
            }
            
            // Add all pg if is all pg is true in negoscope
            for(Sup_sup_NegoScope__c item : [SELECT Id, Name, Is_All__c, Supplier__c, Incl_NewProduct__c
                                             FROM Sup_sup_NegoScope__c
                                             WHERE Supplier__c IN :mapSuppPg.KeySet()
                                             AND Is_All__c = true])
            {
                List<Id> lstPg = mapSuppPg.get(item.Supplier__c);
                for(Id pg : lstPg) {
                    setAllNegoscopePG.add(new Sup_NS_PG__c(Sup_PG__c = pg, Supplier__c = item.Supplier__c, Sup_sup_NegoScope__c = item.Id));
                }
            }
            // insert
            if(setAllNegoscopePG != null && setAllNegoscopePG.size() > 0) {
                ////insert new List<Sup_NS_PG__c>(setAllNegoscopePG);
            }
            **** END OLD CODE - TO BE DELETED ****/
        }
        
        if(Trigger.isDelete) {
            // delete relation between negoscope and pg on pg deletion 
            List<Sup_NS_PG__c> lstPgNs = [SELECT Sup_PG__c,Sup_sup_NegoScope__c FROM Sup_NS_PG__c WHERE Sup_PG__c = '' AND Sup_sup_NegoScope__c != ''];		   
            if(!lstPgNs.isEmpty()) {
                delete lstPgNs;
            }
        }
    }
}