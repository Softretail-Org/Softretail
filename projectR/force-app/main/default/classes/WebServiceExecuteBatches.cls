global with sharing class WebServiceExecuteBatches{
    // Execute GroupContractScanBatch
    WebService static string ExecuteGroupContractScanBatch(List<String> ids, String groupBUCode){
        GroupContractScanBatch b = new GroupContractScanBatch('Group Contract Page', false, ids, groupBUCode);
        ID batchprocessid = Database.executeBatch(b);
        return batchprocessid;
    }
    // Execute GroupContractSynchroBatch
    WebService static string ExecuteGroupContractSynchroBatch(List<Id> ids, String groupBUCode){
        ID batchprocessid = Database.executeBatch(new GroupContractSynchroBatch('Group Contract Page', false, ids, groupBUCode));
        return batchprocessid;
    }
    // Execute GroupInvoiceScanBatch
    WebService static string ExecuteGroupInvoiceScanBatch(List<String> ids, String selectedDate){
        Date d = String.isNotBlank(selectedDate) ? Date.valueOf(selectedDate) : null;
        if(ids != null && ids.size() > 0 && String.isBlank(ids[0])) ids = null;
        ID batchprocessid = Database.executeBatch(new GroupInvoiceScanBatch('Group Invoice Page', false, ids, d));
        return batchprocessid;
    }
    // Execute GroupInvoiceSynchroBatch
    WebService static string ExecuteGroupInvoiceSynchroBatch(List<String> ids, String groupBUCode){
        if(ids != null && ids.size() > 0 && String.isBlank(ids[0])) ids = null;
        ID batchprocessid = Database.executeBatch(new GroupInvoiceSynchroBatch('Group Invoice Page', false, ids)); 
        return batchprocessid;
    }
    // Execute GroupInvoicePaymentScanBatch
    WebService static string ExecuteGroupInvoicePaymentScanBatch(List<String> ids){
        if(ids != null && ids.size() > 0 && String.isBlank(ids[0])) ids = null;
        ID batchprocessid = Database.executeBatch(new GroupInvoicePaymentScanBatch('Group Payment Page', false, ids)); 
        return batchprocessid;
    }
    // Execute GroupInvoicePaymentSynchroBatch
    WebService static string ExecuteGroupInvoicePaymentSynchroBatch(List<String> ids, String groupBUCode){
        if(ids != null && ids.size() > 0 && String.isBlank(ids[0])) ids = null;
        ID batchprocessid = Database.executeBatch(new GroupInvoicePaymentSynchroBatch('Group Payment Page', false, ids)); 
        return batchprocessid;
    }
    // Execute PenaltiesScanSynchroBatch
    WebService static string ExecutePenaltiesScanSynchroBatch(List<String> ids){
        if(ids != null && ids.size() > 0 && String.isBlank(ids[0])) ids = null;
        ID batchprocessid = Database.executeBatch(new PenaltiesScanSynchroBatch('Supply Penalty Page', ids)); 
        return batchprocessid;
    }
    // Execute GroupRebatePaymentScanBatch
    WebService static string ExecuteGroupRebatePaymentScanBatch(List<String> ids, String selectedDate){
        Date d = String.isNotBlank(selectedDate) ? Date.valueOf(selectedDate) : null;
        if(ids != null && ids.size() > 0 && String.isBlank(ids[0])) ids = null;
        ID batchprocessid = Database.executeBatch(new GroupRebatePaymentScanBatch('Group Rebate Page', false, ids, d)); 
        return batchprocessid;
    }
    // Execute GroupRebatePaymentSynchroBatch
    WebService static string ExecuteGroupRebatePaymentSynchroBatch(List<String> ids, String groupBUCode){
        if(ids != null && ids.size() > 0 && String.isBlank(ids[0])) ids = null;
        ID batchprocessid = Database.executeBatch(new GroupRebatePaymentSynchroBatch('Group Rebate Page', ids)); 
        return batchprocessid;
    }
    // Execute ExecuteCommercialPlanScanContractBatch
    WebService static string ExecuteCommercialPlanScanContractBatch(List<String> ids, Id countryId, String selectedDate){
        if(ids != null && ids.size() > 0 && String.isBlank(ids[0])) ids = null;
        ID batchprocessid = Database.executeBatch(new CommercialPlanScanBatch('WebServiceExecuteBatches', ids, countryId, selectedDate, true, false)); 
        return batchprocessid;
    }
    // Execute ExecuteCommercialPlanScanStatusBatch
    WebService static string ExecuteCommercialPlanScanStatusBatch(List<String> ids, Id countryId, String selectedDate){
        if(ids != null && ids.size() > 0 && String.isBlank(ids[0])) ids = null;
        ID batchprocessid = Database.executeBatch(new CommercialPlanScanBatch('WebServiceExecuteBatches', ids, countryId, selectedDate, false, true)); 
        return batchprocessid;
    }
    // Execute ContractBalancingBatch
    WebService static string ExecuteContractBalancingBatch(List<String> ids){
        if(ids != null && ids.size() > 0 && String.isBlank(ids[0])) ids = null;
        ID batchprocessid = Database.executeBatch(new ContractBalancingBatch('WebServiceExecuteBatches', ids)); 
        return batchprocessid;
    }
    // Execute GenerateInvoicesBatch
    WebService static string ExecuteGenerateInvoicesBatch(String countryId, List<String> contractIds, List<String> conditionIds, String selectedDate){
        Date d = String.isNotBlank(selectedDate) ? Date.valueOf(selectedDate) : System.today();
        if(String.isBlank(countryId)) countryId = null;
        if(contractIds != null && contractIds.size() > 0 && String.isBlank(contractIds[0])) contractIds = null;
        if(conditionIds != null && conditionIds.size() > 0 && String.isBlank(conditionIds[0])) conditionIds = null;
        ID batchprocessid = Database.executeBatch(new GenerateInvoicesBatch('WebServiceExecuteBatches', countryId, contractIds, conditionIds, d)); 
        return batchprocessid;
    }
    // Execute DispatchingBatch
    WebService static string ExecuteDispatchingBatch(String countryId, List<String> contractIds, String selectedDate){
        Date d = String.isNotBlank(selectedDate) ? Date.valueOf(selectedDate) : System.today();
        if(String.isBlank(countryId)) countryId = null;
        if(contractIds != null && contractIds.size() > 0 && String.isBlank(contractIds[0])) contractIds = null;
        ID batchprocessid = Database.executeBatch(new DispatchingBatch('WebServiceExecuteBatches', countryId, contractIds, null, d)); 
        return batchprocessid;
    }
    // Execute CalculateBaseTOBatch and CalculateTOContractBatch
    WebService static string ExecuteCalculateTOBatch(String countryId, List<String> contractIds, List<String> conditionIds, String selectedDate){
        String res = '';
        if(String.isBlank(countryId)) countryId = null;
        if(contractIds != null && contractIds.size() > 0 && String.isBlank(contractIds[0])) contractIds = null;
        if(conditionIds != null && conditionIds.size() > 0 && String.isBlank(conditionIds[0])) {
            conditionIds = null;
            ID batchprocessid1 = Database.executeBatch(new CalculateTOContractBatch('WebServiceExecuteBatches', countryId, contractIds, null));
            res = batchprocessid1 + '-';
        }
        ID batchprocessid2 = Database.executeBatch(new CalculateBaseTOBatch('WebServiceExecuteBatches', countryId, contractIds, conditionIds, null));
        return res += batchprocessid2;
    }
    // Execute GenerateGRCRatesBatch
    WebService static string ExecuteGenerateGRCRatesBatch(String countryId, List<String> contractIds, String selectedDate, Boolean lastActiveContract){
        Date d = String.isNotBlank(selectedDate) ? Date.valueOf(selectedDate) : System.today();
        if(String.isBlank(countryId)) countryId = null;
        if(contractIds != null && contractIds.size() > 0 && String.isBlank(contractIds[0])) contractIds = null;
        ID batchprocessid = Database.executeBatch(new GenerateGRCRatesBatch('WebServiceExecuteBatches', countryId, contractIds, d, lastActiveContract)); 
        return batchprocessid;
    }
    // Execute ReparentingSellinBatch : reparenting Sellin on delete contract
    WebService static string ExecuteReparentingSellinBatch(List<String> ids){
        if(ids != null && ids.size() > 0 && String.isBlank(ids[0])) ids = null;
        ID batchprocessid = Database.executeBatch(new ReparentingSellinBatch('WebServiceExecuteBatches', null, null, ids, null, null, null, null, null, false, null, null));
        return batchprocessid;
    }
    // Execute SellinToPurchaseBatch
    WebService static string ExecuteSellinToPurchaseBatch(List<Id> contractRecalculateIds) {
        ID batchprocessid = Database.executeBatch(new SellinToPurchaseBatch('WebServiceExecuteBatches', contractRecalculateIds, null, null, null, null, null, true));
        return batchprocessid;
    }
}