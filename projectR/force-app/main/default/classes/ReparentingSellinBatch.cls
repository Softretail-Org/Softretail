/**
 * Update sell in contract
 **/
public with sharing class ReparentingSellinBatch implements Database.Batchable<SObject>, Database.stateful {
    
    private NegoptimBatch nb;
    private final String query;
    private Integer year;
    // case insert contracts
    private final List<Contract__c> contractInsertedList;
    // case update contracts
    private final Set<Id> contractUpdatedSet;
    // case delete contracts
    private final Set<Id> contractDeletedSet;
    // case insert Assortment
    private final List<Sup_NS_PG__c> NSPGInsertedList;
    // case delete Assortment
    private final List<Sup_NS_PG__c> NSPGDeletedList;
    // case insert BU List
    private final Set<Id> BUListInsertedSet;
    // case delete BU List
    private final Set<Id> BUListDeletedSet;
    // case Re-Scan Sell_in
    private final Boolean reScanSellin;    
    // params passing to ResetSellinMonthlyConsobatch
    // case reset sell_in monthly conso on delete NS_PG, delete BU List and delete contracts
    private final List<Sell_in_Flow__c> resetSellInList;
    private final Set<Id> oldContractIds;
    
    /* @params description :
     * 1- Case insert/update contracts: used params (newContracts, updatedContracts, businessUnitsMap) and called from Trg_Nego360_Contract_Handler using method updateSellinFlow.   
     * 2- Case delete contracts: used params (contractDeletedIds) and called from Trg_Nego360_Contract_Handler
     * 3- Case insert Assortment: used params (newNSPGs) and called from Trg_Org_Supplier_Negoscope_ProductGroup
     * 4- Case delete Assortment: used params (deletedNSPGs) and called from Trg_Org_SupplierPg
     * 5- Case insert BU List Detail: used params (newBUListIds) and called from Trg_Org_Orga_BU_List_Detail_Handler
     * 6- Case delete BU List Detail: used params (deletedBUListIds) and called from Trg_Org_Orga_BU_List_Detail_Handler
     * 7- Case reScan Sell_in: used params (reScan,masterBU,selectedDate) and called from MassBatchFormController
     */
    // Constructor.
    public ReparentingSellinBatch(String startedFrom, List<Contract__c> newContracts, List<Contract__c> updatedContracts, List<Id> contractDeletedIds, 
                                  Map<Id, Set<Id>> businessUnitsMap, List<Sup_NS_PG__c> newNSPGs, List<Sup_NS_PG__c> deletedNSPGs,
                                  List<Id> newBUListIds, List<Id> deletedBUListIds,
                                  Boolean reScan, Id masterBU, Date selectedDate)
    {
        this.nb = new NegoptimBatch('Reparenting Sell in Batch', NegoptimBatch.BatchType.Stateful, startedFrom);
        // reparenting sell_in in current year
        this.year = System.today().year();
        this.resetSellInList = new List<Sell_in_Flow__c>();
        this.oldContractIds = new Set<Id>();
        
        String q = 'SELECT Id, Name, Has_Correct_Contract__c, Master_bu__c, BU__c, Year__c, Month__c, Supplier__c, Mvt_Purch_Product__c, ';
        q += ' Contract__c, Contract__r.Contract_Type__c, Contract__r.Contract_BU__c, Invoice_Date__c, CurrencyISOCode ';
        q += ' FROM Sell_in_Flow__c ';
        
        // 1- case insert/update contracts
        if((newContracts != null && newContracts.size() > 0) || (updatedContracts != null && updatedContracts.size() > 0)){
            List<Contract__c> contracts = new List<Contract__c>();
            contracts.addAll(newContracts);
            contracts.addAll(updatedContracts);
            contractInsertedList = newContracts;
            contractUpdatedSet = (new Map<Id, Contract__c>(updatedContracts)).keySet();
            Set<Id> supplierSet = new Set<Id>();
            Set<Id> sourceBUSet = new Set<Id>();
            Set<Integer> referenceYearSet = new Set<Integer>();
            for(Contract__c item : contracts){
                if(item.Reference_Year__c != null && item.Supplier__c != null && item.BU_Source__c != null && item.Contract_BU__c != null &&
                   item.Supplier_Nego_Scope__c != null && item.Contract_BDate__c != null && item.Contract_EDate__c != null)
                {
                    if(!supplierSet.contains(item.Supplier__c)){
                        supplierSet.add(item.Supplier__c);
                    }
                    if(!sourceBUSet.contains(item.BU_Source__c)){
                        sourceBUSet.add(item.BU_Source__c);
                    }
                    if(!referenceYearSet.contains(Integer.valueOf(item.Reference_Year__c))){
                        referenceYearSet.add(Integer.valueOf(item.Reference_Year__c));
                    }
                }
            }
            // Load Childs of BUs
            List<Id> childBUIds = new List<Id>();
            if(businessUnitsMap.size() > 0) {
                for(Id buId : businessUnitsMap.keySet()) {
                    childBUIds.addAll(businessUnitsMap.get(buId));
                    if(!childBUIds.contains(buId)){
                        childBUIds.add(buId);
                    }
                }
            }
            q += ' WHERE ';
            q += ' (Has_Correct_Contract__c = FALSE ';
            q += ' AND Supplier__c IN (\'' + String.join(new List<Id>(supplierSet), '\',\'') +'\')';
            q += ' AND Master_bu__c IN (\'' + String.join(new List<Id>(sourceBUSet), '\',\'') +'\')';
            q += ' AND BU__c IN (\'' + String.join(childBUIds, '\',\'') +'\')';
            q += ' AND Year__c IN (' + String.join(new List<Integer>(referenceYearSet), '\',\'') +')';
            q += ' ) OR Contract__c IN (\'' + String.join(new List<Id>(contractUpdatedSet), '\',\'') +'\')';
        }
        
        // 2- case delete contracts
        if(contractDeletedIds != null && contractDeletedIds.size() > 0){
            contractDeletedSet = new Set<Id>(contractDeletedIds);
            q += ' WHERE Contract__c IN (\'' + String.join(contractDeletedIds, '\',\'') +'\')';
        }
        
        // 3- case insert Assortment
        if(newNSPGs != null && newNSPGs.size() > 0){
            NSPGInsertedList = newNSPGs;
            Set<Id> supplierSet = new Set<Id>();
            Set<Id> productSet = new Set<Id>();
            for(Sup_NS_PG__c item : newNSPGs){
                if(!supplierSet.contains(item.Sup_PG__r.Supplier__c)){
                    supplierSet.add(item.Sup_PG__r.Supplier__c);
                }
                if(!productSet.contains(item.Sup_PG__r.Product__c)){
                    productSet.add(item.Sup_PG__r.Product__c);
                }
            }
            q += ' WHERE Has_Correct_Contract__c = FALSE ';
            q += ' AND Supplier__c IN (\'' + String.join(new List<Id>(supplierSet), '\',\'') +'\')';
            q += ' AND Mvt_Purch_Product__c IN (\'' + String.join(new List<Id>(productSet), '\',\'') +'\')';
            q += ' AND Year__c = '+ year;
        }
        
        // 4- case delete Assortment
        if(deletedNSPGs != null && deletedNSPGs.size() > 0){
            NSPGDeletedList = deletedNSPGs;            
            Set<Id> productIdSet = new Set<Id>();
            Set<Id> supplierSet = new Set<Id>();
            Set<Id> negoScopeSet = new Set<Id>();
            for(Sup_NS_PG__c item : deletedNSPGs){
                if(!productIdSet.contains(item.Sup_PG__r.Product__c)){
                    productIdSet.add(item.Sup_PG__r.Product__c);
                }
                if(!supplierSet.contains(item.Sup_PG__r.Supplier__c)){
                    supplierSet.add(item.Sup_PG__r.Supplier__c);
                }
                if(!negoScopeSet.contains(item.Sup_sup_NegoScope__c)){
                    negoScopeSet.add(item.Sup_sup_NegoScope__c);
                }
            }
            q += ' WHERE Has_Correct_Contract__c = TRUE ';
            q += ' AND Supplier__c IN (\'' + String.join(new List<Id>(supplierSet), '\',\'') +'\')';
            q += ' AND Mvt_Purch_Product__c IN (\'' + String.join(new List<Id>(productIdSet), '\',\'') +'\')';
            q += ' AND Contract__r.Supplier_Nego_Scope__c IN (\'' + String.join(new List<Id>(negoScopeSet), '\',\'') +'\')';
            q += ' AND Year__c = '+ year;
        }
        
        // 5- case insert BU List Detail
        if(newBUListIds != null && newBUListIds.size() > 0){
            BUListInsertedSet = new Set<Id>(newBUListIds);
            q += ' WHERE Has_Correct_Contract__c = FALSE ';
            q += ' AND BU__c IN (\'' + String.join(newBUListIds, '\',\'') +'\')';
            q += ' AND Year__c = '+ year;
        }
        
        // 6- case delete BU List Detail
        if(deletedBUListIds != null && deletedBUListIds.size() > 0){
            BUListDeletedSet = new Set<Id>(deletedBUListIds);
            q += ' WHERE Has_Correct_Contract__c = TRUE ';
            q += ' AND BU__c IN (\'' + String.join(deletedBUListIds, '\',\'') +'\')';
            q += ' AND Year__c = '+ year;
        }
        
        // 7- case reScan Sell_in
        if(reScan) {
            this.reScanSellin = reScan;
            q += ' WHERE Has_Correct_Contract__c = FALSE ';
            if(masterBU != null) {
                q += ' AND Master_bu__c = \'' + masterBU + '\'';
            }
            // case selected date from mass batch form
            if(selectedDate != null) {
                q += ' AND Year__c =' + selectedDate.year();
            }
            else {
                q += ' AND Year__c = '+ year;
            }
        }
        
        query = q;
        // push inputs to log
        nb.logParameter('newContracts', newContracts);
        nb.logParameter('updatedContracts', updatedContracts);
        nb.logParameter('contractDeletedIds', contractDeletedIds);
        nb.logParameter('businessUnitsMap', businessUnitsMap);
        nb.logParameter('newNSPGs', newNSPGs);
        nb.logParameter('deletedNSPGs', deletedNSPGs);
        nb.logParameter('newBUListIds', newBUListIds);
        nb.logParameter('deletedBUListIds', deletedBUListIds);
        nb.logParameter('reScan', reScan);
        nb.logParameter('masterBU', masterBU);
        nb.logParameter('selectedDate', selectedDate);
        nb.logParameter('query', this.query);
    }
    
    // start
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    // execute
    public void execute(Database.BatchableContext BC, List<Sell_in_Flow__c> scope) {
        List<Sell_in_Flow__c> sellinFlowList = new List<Sell_in_Flow__c>();
        // Map old sell_in/contract
        Map<Id, Id> oldSellinContractMap = new Map<Id, Id>();
        Map<Id, Boolean> contractMap = new Map<Id, Boolean>();
        for(Sell_in_Flow__c item : scope) {
            oldSellinContractMap.put(item.Id, item.Contract__c);
            if(!contractMap.containsKey(item.Contract__c)) {
                contractMap.put(item.Contract__c, item.Has_Correct_Contract__c);
            }
        }
        
        // update Contract__c for each sell in on insert/delete contract
        Trg_Sell_in_Flow_Handler.reparentingSellin(scope, null, contractInsertedList, contractUpdatedSet, contractDeletedSet, 
                                                   NSPGInsertedList, NSPGDeletedList, BUListInsertedSet, BUListDeletedSet,
                                                   reScanSellin);
        
        // check contract linked to sell in
        for(Sell_in_Flow__c item : scope) {
            Id oldContractId = oldSellinContractMap.get(item.Id);
            Boolean correctContract = contractMap.get(oldContractId);            
            if(item.Contract__c == oldContractId){
                // case delete contracts
                if(contractDeletedSet != null && contractDeletedSet.size() > 0){
                    contractDeletedSet.remove(oldContractId);
                }
            }
            else {
                sellinFlowList.add(item);
                // case reset sell_in monthly conso on delete NS_PG, delete BU list
                if((NSPGDeletedList != null && !NSPGDeletedList.isEmpty()) || (BUListDeletedSet != null && !BUListDeletedSet.isEmpty()) || (contractDeletedSet != null && !contractDeletedSet.isEmpty())) {
                    resetSellInList.add(item);
                    // case delete NS_PG : to recalculate TO of old contracts
                    if(correctContract){
                        oldContractIds.add(oldContractId);
                    }
                }
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on update sell in flow
            String[] sellinFlowFields = new String[] {NegoptimHelper.normalizeAPIName('Contract__c')};
                
            if(NegoptimHelper.checkUpdatibility(Sell_in_Flow__c.SObjectType, sellinFlowFields) && sellinFlowList.size() > 0){
                List<Database.SaveResult> results = Database.update(sellinFlowList, false);
                nb.logResults(results, sellinFlowList);
            }
        } catch(DmlException e){
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e){
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    
    // finish
    public void finish(Database.BatchableContext BC) {
        if(contractDeletedSet != null && contractDeletedSet.size() > 0) {
            deleteContracts();
        }
        // reset sell_in monthly conso on insert/delete NS_PG
        if (!this.resetSellInList.isEmpty()) {
            List<Id> buIds = new List<Id>();
            List<Id> supplierIds = new List<Id>();
            List<Id> productIds = new List<Id>();
            List<Integer> months = new List<Integer>();
            
            for(Sell_in_Flow__c item : this.resetSellInList) {
                if(!buIds.contains(item.BU__c)){
                    buIds.add(item.BU__c);
                }
                if(!supplierIds.contains(item.Supplier__c)){
                    supplierIds.add(item.Supplier__c);
                }
                if(!productIds.contains(item.Mvt_Purch_Product__c)){
                    productIds.add(item.Mvt_Purch_Product__c);
                }
                if(!months.contains(Integer.valueOf(item.Month__c))){
                    months.add(Integer.valueOf(item.Month__c));
                }
            }
            // Execute update monthly conso sell in flow
            Database.executeBatch(new ResetSellinMonthlyConsoBatch('ReparentingSellinBatch', new List<Id>(oldContractIds), buIds, supplierIds, productIds, months, this.year, null, null));
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    private void deleteContracts(){
        // Delete contracts
        List<Contract__c> contractDeletedList = [SELECT Id, Name FROM Contract__c WHERE Id IN :contractDeletedSet];
        if(NegoptimHelper.checkDeletibility(Contract__c.SObjectType) && contractDeletedList.size() > 0){
            Database.DeleteResult[] results = Database.Delete(contractDeletedList, false);            
            for (Integer i = 0; i < results.size(); i++){
                Database.DeleteResult result = results.get(i);
                Contract__c contract = contractDeletedList.get(i);
                if (!result.isSuccess()){
                    String errorMessage = 'Error deleting contract (Id=' + contract.Id + ', Name=' + contract.Name + ') : ';
                    Database.Error[] errs = result.getErrors();
                    for (Database.Error err : errs){
                        errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                    }
                    nb.logError(errorMessage);
                }
            }
        }
    }
}