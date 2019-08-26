/**
 * Check and validate uniqueness constraint of name  in Brand (Sup_Brand__c)
 * Prevent Updating or deleting a brand if the supplier(Brand Owner) have a Pg related to brand 
 * Add defualt brand distributor for the supplier brand  
 * On brand creation we add the brand in negoscope if it has field Include New Brand = true 
 */
trigger Trg_Org_Sup_Brand on Sup_Brand__c (before insert, before update,before delete, after insert, after update) {
    String errMsg = System.Label.MSG_Brand_Name_Already_Exist;
    String errMsg2  = System.Label.MSG_Cannot_Change_Current_Supplier;
    Supplier_PG_Mapping__c PG;
    list<Sup_NS_Brand__c> allNegoscopeBrand = new List<Sup_NS_Brand__c>();
    
    if (Trigger.isBefore) { 
        if (System.Trigger.isInsert || System.Trigger.isUpdate) {
            Map<String, Sup_Brand__c > brandMap1 = new Map<String, Sup_Brand__c >();
            
            for (Sup_Brand__c  brand : System.Trigger.new) {
                if (System.Trigger.isInsert || (System.Trigger.isUpdate &&
                                                (brand.name != System.Trigger.oldMap.get(brand.Id).name)))
                {
                    // Make sure another new brand isn't also a duplicate 
                    if (brandMap1.containsKey(brand.name)) {
                        brand.addError(errMsg);
                    }
                    else {
                        brandMap1.put(brand.name,brand);
                    }
                }
            }
            // prevent update the brand supplier(Brand Owner) that have a Pg related
            Set<Id> brandOwners = new Set<Id>();
            Set<Id> brandIds = new Set<Id>();
            for (Sup_Brand__c brand : System.Trigger.new) {
                if(System.Trigger.isUpdate && brand.Brand_Owner__c != System.Trigger.oldMap.get(brand.Id).Brand_Owner__c) {
                    brandOwners.add(System.Trigger.oldMap.get(brand.Id).Brand_Owner__c);
                    brandIds.add(brand.Id);
                }
            }
            List<Supplier_PG_Mapping__c> pgList = [SELECT Id
                                                   FROM Supplier_PG_Mapping__c
                                                   WHERE Brand__c = :brandIds 
                                                   AND Supplier__c = :brandOwners];
            
            for (Sup_Brand__c brand : System.Trigger.new) {
                if (pgList != NULL && pgList.size() > 0) {  
                    brand.Brand_Owner__c.addError(errMsg2);			 		
                }
            }
            
            // Using a single database query, find all the brands in 
            // the database that have the same name as any 
            // of the brands being inserted or updated. 
            for (Sup_Brand__c brand : [SELECT Name FROM Sup_Brand__c WHERE Name IN :brandMap1.KeySet()]) {
                Sup_Brand__c newbrand = brandMap1.get(brand.name);
                newbrand.name.addError(errMsg);
            }
        }
        
        if(System.Trigger.isDelete) {
            
            //prevent delete brand if supplier(Brand Owner) have a Pg related   
            Set<Id> brandOwners = new Set<Id>();
            Set<Id> brandIds = new Set<Id>();
            for (Sup_Brand__c  brand : System.Trigger.old) {
                brandOwners.add(brand.Brand_Owner__c);
                brandIds.add(brand.Id);
            }
            List<Supplier_PG_Mapping__c> pgList = [SELECT  Id 
                                                   FROM Supplier_PG_Mapping__c
                                                   WHERE Brand__c = :brandIds 
                                                   AND Supplier__c = :brandOwners];
            
            for (Sup_Brand__c  brand : System.Trigger.old) {
                if (pgList != NULL && pgList.size() > 0){  
                    brand.Brand_Owner__c.addError(errMsg2);			 		
                } 
            }
        }
    }
    
    if (Trigger.isAfter) {
        
        if (Trigger.isInsert) {
            //Add defualt brand distributor for the supplier brand 
            List<Sup_Bra_Distributor__c> Sup_Owners = new List<Sup_Bra_Distributor__c>{};
                
                for (Sup_Brand__c a : Trigger.new) {
                    Sup_Bra_Distributor__c Sup_Owner = new Sup_Bra_Distributor__c();
                    Sup_Owner.Name = a.Name  ; 
                    Sup_Owner.Brand__c = a.Id;
                    Sup_Owner.Supplier__c = a.Brand_Owner__c;
                    Sup_Owner.Is_Brand_Distributor__c = true;
                    Sup_Owner.Status_BDate__c = a.Status_BDate__c;
                    Sup_Owners.add(Sup_Owner);   
                }
            insert Sup_Owners;
            
            // On brand creation we add the brand in negoscope if it has field Incl_NewBrand__c = true 
            Map<Id,List<Id>>  mapSuppBrand = new Map<Id,List<Id>>();
            for (Sup_Brand__c  brand : System.Trigger.new){
                
                if(mapSuppBrand.containsKey(brand.Brand_Owner__c)) {
                    List<Id> lstBrandId= mapSuppBrand.get(brand.Brand_Owner__c);
                    lstBrandId.add(brand.Id);
                    mapSuppBrand.put(brand.Brand_Owner__c, lstBrandId);
                }else{
                    mapSuppBrand.put(brand.Brand_Owner__c,new List<Id> { brand.Id });
                }
            }	
            List<Sup_sup_NegoScope__c> allNegoScope = [Select Id,Name,Supplier__c, Is_All_Brands__c, Incl_NewBrand__c FROM Sup_sup_NegoScope__c WHERE Supplier__c IN :mapSuppBrand.KeySet() AND (Is_All_Brands__c = true OR Incl_NewBrand__c = true) ];		
            if(allNegoScope != NULL && allNegoScope.size() > 0){
                for(Sup_sup_NegoScope__c negoscope : allNegoScope){
                    List<Id> lstBrand= mapSuppBrand.get(negoscope.Supplier__c);
                    for(Id brand : lstBrand){
                        Sup_NS_Brand__c negoScopeBrand = new Sup_NS_Brand__c(Sup_Scope_Brand__c =brand, Supplier__c = negoscope.Supplier__c, Sup_sup_NegoScope__c = negoscope.Id);
                        allNegoscopeBrand.add(negoScopeBrand);
                        
                    }
                }
            } 		    
            if(allNegoscopeBrand != null && allNegoscopeBrand.size() > 0){
                insert allNegoscopeBrand;
            }
            
        }
        
        if (Trigger.isUpdate) {
            List<Sup_Brand__c> Lst_Brands = [select id, name, Brand_Owner__c, (select id, name, supplier__c from Sup_Bra_Suppliers__r) from Sup_Brand__c 
                                             where id IN :Trigger.newMap.keySet()];
            
            List<Sup_Bra_Distributor__c> Sup_Owners = new List<Sup_Bra_Distributor__c>();                                
            for (Sup_Brand__c a : Lst_Brands) {
                integer test = 0;
                for (Sup_Bra_Distributor__c d : a.Sup_Bra_Suppliers__r) {
                    if (d.supplier__c == a.brand_owner__c) {
                        test = 1;
                    }
                }
                if (test == 0) {
                    Sup_Bra_Distributor__c Sup_Owner = new Sup_Bra_Distributor__c();
                    Sup_Owner.Name = a.Name  ; 
                    Sup_Owner.Brand__c = a.Id;
                    Sup_Owner.Supplier__c = a.Brand_Owner__c;
                    Sup_Owner.Is_Brand_Distributor__c = true;
                    Sup_Owner.Status_BDate__c = date.today();
                    Sup_Owners.add(Sup_Owner);
                }
            }
            insert Sup_Owners;
        }
    }
}