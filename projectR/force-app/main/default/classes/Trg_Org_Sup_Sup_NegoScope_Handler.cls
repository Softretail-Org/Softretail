public class Trg_Org_Sup_Sup_NegoScope_Handler {
    
    public static void OnBeforeInsert(List<Sup_sup_NegoScope__c> nNSs) {
        assignSupCurrencyISOCode(nNSs);
    }
    
    public static void OnAfterUpdate(List<Sup_sup_NegoScope__c> nNSs, Map<Id, Sup_sup_NegoScope__c> oNSMap) {
        // Call this method everytime after update but before calling setAllRelations
        removeAllRelations(nNSs, oNSMap);
        updateSubNSOwner(nNSs, oNSMap);
        assignStockOwnerToContracts(nNSs);
    }
    
    public static void OnAfterInsertOrUpdate(List<Sup_sup_NegoScope__c> nNSs, Map<Id, Sup_sup_NegoScope__c> oNSMap) {
        setAllRelations(nNSs, oNSMap);
    }
    
    public static void OnBeforeInsertOrUpdate(List<Sup_sup_NegoScope__c> nNSs, Map<Id, Sup_sup_NegoScope__c> oNSMap) {
        avoidNSDup(nNSs, oNSMap);
    }
    
    public static void OnBeforeUpdate(Map<Id, Sup_sup_NegoScope__c> nNSMap,  Map<Id, Sup_sup_NegoScope__c> oNSMap){
    	avoidSetParentWhenRelatedToContract(nNSMap, oNSMap);
    }
    
    /**
     * Assign the supplier currency ISO code into the NS currency ISO code. Single/Bulk
     * @param List<Sup_sup_NegoScope__c>
     * On Before Insert.
     **/
    private static void assignSupCurrencyISOCode(List<Sup_sup_NegoScope__c> nNSs) {
    	Map<Id, String> supplierCurrencyMap = new Map<Id, String>();
    	Set<Id> supplierIds = new Set<Id>();
    	for (Sup_sup_NegoScope__c NS : nNSs) {
        	supplierIds.add(NS.Supplier__c);
        }
    	for (Sup_Supplier__c sup : [SELECT Id, CurrencyIsoCode
        							FROM Sup_Supplier__c
        							WHERE Id IN :supplierIds]) {
        	supplierCurrencyMap.put(sup.Id, sup.CurrencyIsoCode);
        }
        // Assignment.
    	for (Sup_sup_NegoScope__c NS : nNSs) {
			NS.CurrencyIsoCode = supplierCurrencyMap.get(NS.Supplier__c);
    	}
    }
    /**
     * Update Sub NS owner when parent NS owner change.
     * @param List<Sup_sup_NegoScope__c>
     * On After Update.
     **/
    private static void updateSubNSOwner(List<Sup_sup_NegoScope__c> nNSs, Map<Id, Sup_sup_NegoScope__c> oNSMap) {
        Map<Id, Id> ownerIdMap = new Map<Id, Id>();
        for (Sup_sup_NegoScope__c item : nNSs) {
            if (item.OwnerId != oNSMap.get(item.Id).OwnerId) {
                ownerIdMap.put(item.Id, item.OwnerId);
            }
        }
        
        if (!ownerIdMap.isEmpty()) {
            List<Sup_sup_NegoScope__c> subNSList = [SELECT Id, Parent_Nego_Scope__c
                                                    FROM Sup_sup_NegoScope__c
                                                    WHERE Parent_Nego_Scope__c IN :ownerIdMap.keySet()];
            if (!subNSList.isEmpty()) {
                for (Sup_sup_NegoScope__c item : subNSList) {
                    if(ownerIdMap.containsKey(item.Parent_Nego_Scope__c)) {
                        item.OwnerId = ownerIdMap.get(item.Parent_Nego_Scope__c);
                    }
                }
                update subNSList;
            }
        }
    }
    /**
     * Remove relations of NS with brands, PGs and HE
     * in cases of related ALL field is true
     * @param List<Sup_sup_NegoScope__c>
     * On After Update
     **/
    private static void removeAllRelations(List<Sup_sup_NegoScope__c> negoscopes, Map<Id, Sup_sup_NegoScope__c> oNSMap) {
        Set<Id> NSIdBrands = new Set<Id>();
        Set<Id> NSIdPGs = new Set<Id>();
        Set<Id> NSIdHEs = new Set<Id>();
        for (Sup_sup_NegoScope__c NS : negoscopes) {
            if(NS.Is_All_Brands__c == true && oNSMap.get(NS.Id).Is_All_Brands__c == false) {
                NSIdBrands.add(NS.Id);
            }
            if(NS.Is_All__c == true && oNSMap.get(NS.Id).Is_All__c == false) {
                NSIdPGs.add(NS.Id);
            }
            if(NS.Is_All_HE__c == true && oNSMap.get(NS.Id).Is_All_HE__c == false) {
                NSIdHEs.add(NS.Id);
            }
        }
        try {
            // delete all Sup_NS_Brand__c for current negoscopes
            if (!NSIdBrands.isEmpty() && NegoptimHelper.checkDeletibility(Sup_NS_Brand__c.SObjectType)) {
                delete [SELECT Id FROM Sup_NS_Brand__c WHERE Sup_sup_NegoScope__c = :NSIdBrands];
            }
            // delete all Sup_NS_PG__c for current negoscopes
            if (!NSIdPGs.isEmpty() && NegoptimHelper.checkDeletibility(Sup_NS_PG__c.SObjectType)) {
                delete [SELECT Id FROM Sup_NS_PG__c WHERE Sup_sup_NegoScope__c = :NSIdPGs];
            }
            // delete all Supplier_NS_HE__c for current negoscopes
            if (!NSIdHEs.isEmpty() && NegoptimHelper.checkDeletibility(Supplier_NS_HE__c.SObjectType)) {
                delete [SELECT Id FROM Supplier_NS_HE__c WHERE Sup_sup_NegoScope__c = :NSIdHEs];
            }
        } catch (DmlException e) {
            for (Sup_sup_NegoScope__c item : negoscopes) {
                item.addError(e.getDmlMessage(0));
            }            
        } catch (Exception e) {
            for (Sup_sup_NegoScope__c item : negoscopes) {
                item.addError(e.getMessage());
            }            
        }
    }
    /**
     * Set relations of NS with brands, PGs and HE
     * in cases of related ALL field is true
     * @param List<Sup_sup_NegoScope__c>
     * On After Insert Or After Update
     **/
    private static void setAllRelations(List<Sup_sup_NegoScope__c> negoscopes, Map<Id, Sup_sup_NegoScope__c> oNSMap) {
        
        Id rootId = NegoptimHelper.getRootId();
        Set<Sup_sup_NegoScope__c> NSBrandSet = new Set<Sup_sup_NegoScope__c>();
        Set<Sup_sup_NegoScope__c> NSPGSet = new Set<Sup_sup_NegoScope__c>();
        Set<Id> supIdBrands = new Set<Id>();
        Set<Id> supIdPGs = new Set<Id>();
        Set<Id> NSIdHEs = new Set<Id>();
        Map<Id, List<Id>> supplierBrandsMap = new Map<Id, List<Id>>();
        Map<Id, List<Id>> supplierPGsMap = new Map<Id, List<Id>>();
        Boolean isAll;
        // Add all negoscope id and supplier id  in set.
        for (Sup_sup_NegoScope__c NS : negoscopes) {
            isAll = oNSMap == null || (oNSMap != null && (NS.Is_All_Brands__c && !oNSMap.get(NS.Id).Is_All_Brands__c ||
                                                          NS.Is_All_HE__c && !oNSMap.get(NS.Id).Is_All_HE__c ||
                                                          NS.Is_All__c && !oNSMap.get(NS.Id).Is_All__c));
            if(NS.Is_All_Brands__c && (oNSMap == null || (oNSMap != null && !oNSMap.get(NS.Id).Is_All_Brands__c))) {
                NSBrandSet.add(NS);
                supIdBrands.add(NS.Supplier__c);
            }
            if(NS.Is_All__c && NS.Is_All_Brands__c && NS.Is_All_HE__c && isAll) {
                NSPGSet.add(NS);
                supIdPGs.add(NS.Supplier__c);
            }
            if(NS.Is_All_HE__c == true && (oNSMap == null || (oNSMap != null && oNSMap.get(NS.Id).Is_All_HE__c == false))) {
                NSIdHEs.add(NS.Id);
            }
        }
        // Attach brands to NS
        if(supIdBrands.size() > 0) {
            // Fill map of supplier Id with its related brands Id
            for(Sup_Bra_Distributor__c item : [SELECT Brand__r.Id, Name, Brand__r.Name, Brand__r.Brand_Owner__r.Name, Supplier__r.Name
                                               FROM Sup_Bra_Distributor__c
                                               WHERE Sup_Bra_Distributor__c.Supplier__c IN :supIdBrands
                                               ORDER BY NAME ASC])
            {
                // Group brand in a map by supplier id
                if(supplierBrandsMap.containsKey(item.Supplier__c)) {
                    supplierBrandsMap.get(item.Supplier__c).add(item.Brand__r.Id);
                } else {
                    supplierBrandsMap.put(item.Supplier__c, new List<Id>{item.Brand__r.Id});
                }
            }
            // Loop on negoscope to get brand that belong to the supplier of this negoscope
            if(supplierBrandsMap.size() > 0) {
                Sup_NS_Brand__c NSBrand;
                List<Sup_NS_Brand__c> NSBrands = new List<Sup_NS_Brand__c>();
                for (Sup_sup_NegoScope__c item : NSBrandSet) {
                    if(supplierBrandsMap.containsKey(item.Supplier__c)) {
                        for (Id brandId : supplierBrandsMap.get(item.Supplier__c)) {
                            NSBrand = new Sup_NS_Brand__c(Sup_Scope_Brand__c = brandId, Sup_sup_NegoScope__c = item.Id);
                            NSBrands.add(NSBrand);
                        }
                    }
                }
                if(NSBrands.size() > 0) {
                    insert NSBrands;
                }
            }
        }
        // Attach PGs to NS
        if(supIdPGs.size() > 0) {
            for(Supplier_PG_Mapping__c item : [SELECT Id, Supplier__c,
                                               (SELECT Sup_PG__c FROM Supplier_Nego_Scope_PG__r WHERE Sup_sup_NegoScope__c IN :negoscopes)
                                               FROM Supplier_PG_Mapping__c
                                               WHERE Supplier__c = :supIdPGs
                                               ORDER BY Name ASC])
            {
                // Do not create relation if already exist
                if(item.Supplier_Nego_Scope_PG__r.size() > 0) {
                    continue;
                }
                // Group pg in a map by supplier id
                if(supplierPGsMap.containsKey(item.Supplier__c)) {
                    supplierPGsMap.get(item.Supplier__c).add(item.Id);
                } else {
                    supplierPGsMap.put(item.Supplier__c, new List<Id>{item.Id});
                }
            }
            // Loop on negoscope to get pg that belong to the supplier of this negoscope.
            if(supplierPGsMap.size() > 0) {
                Sup_NS_PG__c NSPG;
                List<Sup_NS_PG__c> NSPGs = new List<Sup_NS_PG__c>();
                for (Sup_sup_NegoScope__c item : NSPGSet) {
                    if(supplierPGsMap.containsKey(item.Supplier__c)) {
                        for (Id pgId : supplierPGsMap.get(item.Supplier__c)) {
                            NSPG = new Sup_NS_PG__c(Sup_PG__c = pgId, Sup_sup_NegoScope__c = item.Id);
                            NSPGs.add(NSPG);
                        }
                    }
                }
                if(NSPGs.size() > 0) {
                    insert NSPGs;
                }
            }
        }
        // Attach HE to NS
        if(NSIdHEs.size() > 0) {
            List<Supplier_NS_HE__c> NSElements = new List<Supplier_NS_HE__c>();
            // Get root element id and add it to the negoscope.
            for (Id id : NSIdHEs) {
                Supplier_NS_HE__c NSElement = new Supplier_NS_HE__c(Structure_Element__c = rootId, Choice__c = 'Include', Sup_sup_NegoScope__c = id);
                NSElements.add(NSElement);
            }
            if(NSElements.size() > 0) {
                insert NSElements;
            }
        }
    }
    /**
     * Check and validate uniqueness constraint of name and supplier in negoscope (Sup_sup_NegoScope__c)
     * @param List<Sup_sup_NegoScope__c>
     * @param Map<Id, Sup_sup_NegoScope__c>
     * On Before Insert Or Before Update.
     **/
    private static void avoidNSDup(List<Sup_sup_NegoScope__c> nNSs, Map<Id, Sup_sup_NegoScope__c> oNSMap) {
    	//@todo : Might use a inner class to handle more the negoscope management 
    	Map<String, Sup_sup_NegoScope__c> NSMap1 = new Map<String, Sup_sup_NegoScope__c>();
    	Map<String, Sup_sup_NegoScope__c> NSMap2 = new Map<String, Sup_sup_NegoScope__c>();
        for (Sup_sup_NegoScope__c NS : nNSs) {
            if (system.trigger.isInsert ||
            	(system.trigger.isUpdate && (NS.name != oNSMap.get(NS.Id).name || NS.Supplier__c != oNSMap.get(NS.Id).Supplier__c))) {
                // Make sure another new NS isn't also a duplicate
                if (NSMap1.containsKey(NS.name) && NSMap2.containsKey(NS.Supplier__c)) {
            		String errMsg = String.format(Label.MSG_The_Combination_NS_Name_Supplier_Keys_Must_Be_Unique, new String[]{NS.name});
                    NS.addError(errMsg);
                } else {
                    NSMap1.put(NS.name, NS);
                    NSMap2.put(NS.Supplier__c, NS);
                }
            }
        }
        // Using a single database query, find all the nNSs in the database that have the same name as any of the NSs being inserted or updated. 
        for (Sup_sup_NegoScope__c NS : [SELECT name,Supplier__c
        								FROM Sup_sup_NegoScope__c
        								WHERE name IN:NSMap1.KeySet() AND Supplier__c IN :NSMap2.KeySet()]) {
        	Sup_sup_NegoScope__c newNS1 = NSMap1.get(NS.name);
            Sup_sup_NegoScope__c newNS2 = NSMap2.get(NS.Supplier__c);
            String errMsg = String.format(Label.MSG_The_Combination_NS_Name_Supplier_Keys_Must_Be_Unique, new String[]{NS.name});
            if (newNS1 != null || newNS2 != null) newNS1.addError(errMsg);
            if (newNS1 != null || newNS2 != null) newNS2.addError(errMsg);
        }
    }
    
     /**
     * Do Not Allow To Put Parent Of NS If This NS Is Attached To One Or More Contract
     * @param Map<Id, Sup_sup_NegoScope__c>
     * @param Map<Id, Sup_sup_negoScope__c>
     * On Before Update.
     **/
    private static void avoidSetParentWhenRelatedToContract(Map<Id, Sup_sup_NegoScope__c> nNSMap, Map<Id, Sup_sup_NegoScope__c> oNSMap){
        List<Id> nsIds = new List<id>();
        
        for(Id item : nNSMap.keySet()){
            if(oNSMap.get(item).Parent_Nego_Scope__c == null && nNSMap.get(item).Parent_Nego_Scope__c != null)
                nsIds.add(item);
        }
        
        if(!nsIds.isEmpty()){
            List<Contract__c> contracts = [SELECT Id, Contract__c.Supplier_Nego_Scope__c FROM Contract__c WHERE Supplier_Nego_Scope__c IN :nsIds];
            if(!contracts.isEmpty()){
                for(Contract__c contract: contracts){
                    nNSMap.get(contract.Supplier_Nego_Scope__c).addError(System.Label.Cannot_Set_Parent_NegoScope);
                }
            }
        }
    }
    /**
     * Assign stock owner BU to contracts 
     * @param List<Sup_sup_NegoScope__c>.
     * On After Update
     **/
    private static void assignStockOwnerToContracts(List<Sup_sup_NegoScope__c> nNSs) {
        Map<Id, Sup_sup_NegoScope__c> nNSMap = new Map<Id, Sup_sup_NegoScope__c>(nNSs);
        List<Contract__c> contracts = [SELECT Id, Supplier_Nego_Scope__c, Stock_Owner__c
                                       FROM Contract__c
                                       WHERE Supplier_Nego_Scope__c IN :nNSMap.KeySet()
                                       AND (Contract_EDate__c = NULL OR Contract_EDate__c > :System.today())];
        if(!contracts.isEmpty()) {
            for (Contract__c item : contracts) {
                item.Stock_Owner__c = nNSMap.get(item.Supplier_Nego_Scope__c).Stock_Owner__c;
            }
            update contracts;
        }
    }
}