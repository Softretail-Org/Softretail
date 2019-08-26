public class Trg_Sell_in_Flow_Handler {
    
    public static void OnAfterInsertOrUpdate(List<Sell_in_Flow__c> nSellinFlows, Map<Id, Sell_in_Flow__c> oSellinFlowMap) {
        updateProductLastPrice(nSellinFlows, oSellinFlowMap);
    }
    /**
     * find the official contract on insert/update sell_in_flow or reparenting sell in on before-delete contract
     * On After Insert/Update
     **/
    public static void reparentingSellin(List<Sell_in_Flow__c> nSellinFlows, Map<Id, Sell_in_Flow__c> oSellinFlowMap,
                                         List<Contract__c> contractInsertedList, Set<Id> contractUpdatedIds, Set<Id> contractDeletedIds,
                                         List<Sup_NS_PG__c> NSPGInsertedList, List<Sup_NS_PG__c> NSPGDeletedList,
                                         Set<Id> newBUListIds, Set<Id> deletedBUListIds, Boolean reScanSellin)
    {
        Set<Id> masterBUSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Id> businessUnitsSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> supplierSet = new Set<Id>();
        // Push Master_bu__c, BU__c, Mvt_Purch_Product__c, Supplier__c and Year__c into Sets
        for(Sell_in_Flow__c item : nSellinFlows){
            if (oSellinFlowMap == null || (oSellinFlowMap != null &&
                                           ((item.Supplier__c != oSellinFlowMap.get(item.Id).Supplier__c) ||
                                            (item.Mvt_Purch_Product__c != oSellinFlowMap.get(item.Id).Mvt_Purch_Product__c) ||
                                            (item.Master_bu__c != oSellinFlowMap.get(item.Id).Master_bu__c) ||
                                            (item.BU__c != oSellinFlowMap.get(item.Id).BU__c) ||
                                            (item.Invoice_Date__c != oSellinFlowMap.get(item.Id).Invoice_Date__c)))
                || contractInsertedList != null
                || contractUpdatedIds != null
                || contractDeletedIds != null
                || NSPGInsertedList != null
                || NSPGDeletedList != null
                || newBUListIds != null
                || deletedBUListIds != null
                || reScanSellin)
            {
                if(item.Master_bu__c != null && item.Year__c != null && item.Mvt_Purch_Product__c != null && item.Supplier__c != null){
                    if(!businessUnitsSet.contains(item.Master_bu__c)){
                        businessUnitsSet.add(item.Master_bu__c);
                    }
                    if(!businessUnitsSet.contains(item.BU__c)){
                        businessUnitsSet.add(item.BU__c);
                    }
                    if(!masterBUSet.contains(item.Master_bu__c)){
                        masterBUSet.add(item.Master_bu__c);
                    }
                    if(!yearSet.contains(Integer.valueOf(item.Year__c))){
                        yearSet.add(Integer.valueOf(item.Year__c));
                    }
                    if(!productIdSet.contains(item.Mvt_Purch_Product__c)){
                        productIdSet.add(item.Mvt_Purch_Product__c);
                    }
                    if(!supplierSet.contains(item.Supplier__c)){
                        supplierSet.add(item.Supplier__c);
                    }
                }
            }
        }
        
        // Main map to find correct contract
        Map<String, List<Contract__c>> contractSourceBUMap = new Map<String, List<Contract__c>>();
        // Second map in case no official contract found, attach sell in to temporary one
        Map<String, List<Contract__c>> contractBUMap = new Map<String, List<Contract__c>>();
        
        if(masterBUSet.size() > 0 && yearSet.size() > 0 && businessUnitsSet.size() > 0 && supplierSet.size() > 0 && productIdSet.size() > 0) {
            // Load Map of Parent BUs
            Map<Id, Set<Id>> childParentBUMap = NegoptimHelper.getBUParentsMap(businessUnitsSet);
            Map<Id, Set<Id>> parentChildrenBUMap = new Map<Id, Set<Id>>();
            for(Id key : childParentBUMap.keySet()){
                for(Id item : childParentBUMap.get(key)){
                    businessUnitsSet.add(item);
                    if(parentChildrenBUMap.containsKey(item)){
                        parentChildrenBUMap.get(item).add(key);
                    }
                    else{
                        parentChildrenBUMap.put(item, new Set<Id>{key});
                    }
                }
            }
            
            // Map NS
            Map<String, Id> NSsMap = new Map<String, Id>();
            // Get NS based on supplier PG.
            List<Sup_NS_PG__c> NSPGList = new List<Sup_NS_PG__c>();
            if(NSPGInsertedList != null && !NSPGInsertedList.isEmpty()) {
                NSPGList.addAll(NSPGInsertedList);
            } else {
                String qry = 'SELECT Id, Sup_sup_NegoScope__c, Sup_sup_NegoScope__r.Parent_Nego_Scope__c,';
                qry += ' Sup_PG__c, Sup_PG__r.Product__c, Sup_PG__r.Supplier__c';
                qry += ' FROM Sup_NS_PG__c';
                qry += ' WHERE Sup_PG__r.Supplier__c IN :supplierSet';
                qry += ' AND Sup_PG__r.Product__c IN :productIdSet';
                if(NSPGDeletedList != null && !NSPGDeletedList.isEmpty()) {
                    qry += ' AND Id NOT IN :NSPGDeletedList';
                }
                NSPGList = Database.query(qry);
                /*NSPGList = [SELECT Id, Sup_sup_NegoScope__c, Sup_sup_NegoScope__r.Parent_Nego_Scope__c, 
                            Sup_PG__c, Sup_PG__r.Product__c, Sup_PG__r.Supplier__c
                            FROM Sup_NS_PG__c
                            WHERE Sup_PG__r.Supplier__c IN :supplierSet
                            AND Sup_PG__r.Product__c IN :productIdSet
                            AND Id NOT IN :NSPGDeletedList];*/
            }
            for(Sup_NS_PG__c item : NSPGList){
                String key = item.Sup_sup_NegoScope__c + '' + item.Sup_PG__r.Product__c + '' + item.Sup_PG__r.Supplier__c;
                if(!NSsMap.containsKey(key)){
                    NSsMap.put(key, item.Sup_sup_NegoScope__c);
                }
            }
            
            // get contracts
            if(contractInsertedList == null) contractInsertedList = new List<Contract__c>();
            List<Contract__c> contractList = [SELECT Id, Name, Supplier_Nego_Scope__c, Reference_Year__c, Supplier__c, BU_Source__c,
                                              Contract_BU__c, Contract_BDate__c, Contract_EDate__c, Contract_Numbder__c
                                              FROM Contract__c
                                              WHERE (Contract_BU__c IN :businessUnitsSet OR BU_Source__c IN :businessUnitsSet)
                                              AND Reference_Year__c IN :yearSet AND Contract_Type__c = 'Contract'
                                              AND Id NOT IN :contractInsertedList
                                              ORDER BY Contract_BDate__c DESC];
            if(contractInsertedList != null && contractInsertedList.size() > 0){
                contractList.addAll(contractInsertedList);
            }
            
            for(Contract__c item : contractList){
                // case delete contract: reparenting sell in to another contract
                if(contractDeletedIds != null && contractDeletedIds.size() > 0 && contractDeletedIds.contains(item.Id)) continue;
                
                // case insert contract: reparenting sell in to the inserted contract
                ////if(contractInsertedIds != null && contractInsertedIds.size() > 0 && !contractInsertedIds.contains(item.Id)) continue;
                
                String key = '';
                if(masterBUSet.contains(item.BU_Source__c)){
                    key = Integer.valueOf(item.Reference_Year__c) + '' + item.BU_Source__c;
                    if(contractSourceBUMap.containsKey(key)){
                        contractSourceBUMap.get(key).add(item);
                    } 
                    else{
                        contractSourceBUMap.put(key, new List<Contract__c>{item});
                    }
                }
                if(masterBUSet.contains(item.Contract_BU__c)){
                    key = Integer.valueOf(item.Reference_Year__c) + '' + item.Contract_BU__c;
                    if(contractBUMap.containsKey(key)){
                        contractBUMap.get(key).add(item);
                    } 
                    else{
                        contractBUMap.put(key, new List<Contract__c>{item});
                    }
                }
            }
            // update Contract__c for each sell in
            if(contractSourceBUMap.size() > 0 || contractBUMap.size() > 0){
                for(Sell_in_Flow__c item : nSellinFlows){
                    String key = Integer.valueOf(item.Year__c) + '' + item.Master_bu__c;
                    List<Contract__c> contracts = contractSourceBUMap.get(key);
                    Boolean contractLinked = false, parentBUFound = false;
                    // Case find the official contract
                    if(contracts != null && contracts.size() > 0){
                        for(Contract__c contract : contracts){
                            String keyNS = contract.Supplier_Nego_Scope__c + '' + item.Mvt_Purch_Product__c + '' + item.Supplier__c;
                            if(!NSsMap.containsKey(keyNS)) continue;                            
                            parentBUFound = parentChildrenBUMap.containsKey(contract.Contract_BU__c) ? parentChildrenBUMap.get(contract.Contract_BU__c).contains(item.BU__c) : false;
                            if(item.BU__c != null && (item.BU__c == contract.Contract_BU__c || parentBUFound)
                               && item.Supplier__c != null && item.Supplier__c == contract.Supplier__c
                               && contract.Contract_BDate__c <= item.Invoice_Date__c && item.Invoice_Date__c <= contract.Contract_EDate__c)
                            {
                                item.Contract__c = contract.Id;
                                item.Has_Correct_Contract__c = true;
                                contractLinked = true;
                                break;
                            }
                        }
                    }
                    // Case no contract found for the same supplier
                    if(!contractLinked){
                        contracts = contractBUMap.get(key);
                        if(contracts != null && contracts.size() > 0){
                            for(Contract__c contract : contracts){                                
                                if(contract.Contract_BDate__c <= item.Invoice_Date__c && item.Invoice_Date__c <= contract.Contract_EDate__c){
                                    item.Contract__c = contract.Id;
                                    item.Has_Correct_Contract__c = false;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    /**
     * Update product and PG last price
     * On After Insert/Update
     **/
    private static void updateProductLastPrice(List<Sell_in_Flow__c> nSellinFlows, Map<Id, Sell_in_Flow__c> oSellinFlowMap) {
        List<Sell_in_Flow__c> sellinList = new List<Sell_in_Flow__c>();
        for(Sell_in_Flow__c item : nSellinFlows) {
            if (oSellinFlowMap == null || (oSellinFlowMap != null &&
                                           ((item.Supplier__c != oSellinFlowMap.get(item.Id).Supplier__c) ||
                                            (item.Mvt_Purch_Product__c != oSellinFlowMap.get(item.Id).Mvt_Purch_Product__c) ||
                                            (item.Invoice_Date__c != oSellinFlowMap.get(item.Id).Invoice_Date__c) ||
                                            (item.Gross_Price__c != oSellinFlowMap.get(item.Id).Gross_Price__c) ||
                                            (item.List_price__c != oSellinFlowMap.get(item.Id).List_price__c) ||
                                            (item.Net_Price__c != oSellinFlowMap.get(item.Id).Net_Price__c) ||
                                            (item.Unit_Cost__c != oSellinFlowMap.get(item.Id).Unit_Cost__c))))
            {
                // get list sell in
                if(item.Mvt_Purch_Product__c != null && item.Supplier__c != null && item.Invoice_Date__c != null){                    
                    sellinList.add(item);
                }
            }
        }
        if(sellinList.size() > 0) {
            Database.executeBatch(new UpdateLastPriceBatch('Trg_Sell_in_Flow_Handler', sellinList));
        }
    }
}