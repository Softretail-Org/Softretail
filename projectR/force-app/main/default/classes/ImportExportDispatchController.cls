/*
 * Import and export dispatch details.
 */
public with sharing class ImportExportDispatchController {
    
    //public final String IMPORT_ACTION = 'Import';
    public final String EXPORT_ACTION = 'Export';
    public String fileName {get; set;}
    public String csvHeader {get; set;}
    public Contract_Discount__c instance {get; set;}
    public List<WrapperDispatchDetail> wDispatchDetailList {get; set;}

    // Constructor
    public ImportExportDispatchController(ApexPages.StandardController stdController) {
        List<String> fieldNames = new List<String> {
            SObjectType.Assortment_BU__c.fields.Name.Name,
            SObjectType.Contract_Discount__c.fields.BU_Scope__c.Name,
            SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
            'Contract__r.Reference_Year__c'
        };
        // add fields only if test is not running
        if (!System.Test.isRunningTest())
            stdController.addFields(fieldNames);
        instance = (Contract_Discount__c)stdController.getRecord();
        String discountId = stdController.getId();
        String param = ApexPages.currentPage().getParameters().get('action');
        if (param != null && param == EXPORT_ACTION) {
            fileName = 'Export_Dispatch-' + instance.Name + '-' + Date.today().format();
            csvHeader = 'Business Unit,Section,PG,Month1,Month2,Month3,Month4,Month5,Month6,Month7,Month8,Month9,Month10,Month11,Month12';
            try {
                exportFile();
            } catch(QueryException e) {
            }
        }
    }
    // Export file
    private void exportFile() {
        Integer selectedNegoYear = Integer.valueOf(instance.Contract__r.Reference_Year__c);
        List<Orga_BU__c> BUs = loadBU(instance.BU_Scope__c);
        Map<Id, Inv_BUDispatch__c> dispatchHeadMap = new Map<Id, Inv_BUDispatch__c>();
        Map<String, Inv_BUDispatch_Details__c> distpatchDetailsMap = new Map<String, Inv_BUDispatch_Details__c>();
        
        List<Supplier_PG_Mapping__c> PGs = [SELECT Id, SNA_Code__c, Section__c, Section__r.name
                                            FROM Supplier_PG_Mapping__c
                                            WHERE Id IN (SELECT Sup_PG__c FROM Sup_NS_PG__c
                                                         WHERE Sup_sup_NegoScope__c = :instance.Product_Scope__c)];
        for (Inv_BUDispatch__c item : [SELECT Id, Inv_BU__c
                                       FROM Inv_BUDispatch__c
                                       WHERE Inv_BU__c = :BUs
                                       AND Inv_Fiscal_Year__c = :selectedNegoYear])
        {
            dispatchHeadMap.put(item.Inv_BU__c, item);
        }
        List<Inv_BUDispatch_Details__c> distpatchDetailList = [SELECT Id, PG__c, Status__c, Sequence__c, Inv_DispatchHead__c, Inv_BUDispatch__c, Hierarchy_level_dispatch__c,
                                                               Fix_Amount_Dispatch_M9__c, Fix_Amount_Dispatch_M8__c, Fix_Amount_Dispatch_M7__c, Fix_Amount_Dispatch_M6__c,
                                                               Fix_Amount_Dispatch_M5__c, Fix_Amount_Dispatch_M4__c, Fix_Amount_Dispatch_M3__c, Fix_Amount_Dispatch_M2__c,
                                                               Fix_Amount_Dispatch_M1__c, Fix_Amount_Dispatch_M12__c, Fix_Amount_Dispatch_M11__c, Fix_Amount_Dispatch_M10__c,
                                                               Discount__c, Base_TO_Dispatch__c
                                                               FROM Inv_BUDispatch_Details__c
                                                               WHERE Discount__c = :instance.Id];
        for (Inv_BUDispatch_Details__c item : distpatchDetailList)
        {
            distpatchDetailsMap.put(item.Inv_BUDispatch__c + '' + item.PG__c, item);
        }
        wDispatchDetailList = new List<WrapperDispatchDetail>();
        
        for (Orga_BU__c bu : BUs) {
            if (!dispatchHeadMap.containsKey(bu.Id)) {
                Inv_BUDispatch__c newDispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = 1, Inv_Fiscal_Year__c = selectedNegoYear, Inv_BU__c = bu.Id);
                dispatchHeadMap.put(bu.Id, newDispatchHead);
            }
            // Dispatch Details
            for(Supplier_PG_Mapping__c PG : PGs) {
                Inv_BUDispatch_Details__c dd = null;
                if (!distpatchDetailsMap.containsKey(bu.Id + '' + PG.Id)) {
                    dd = new Inv_BUDispatch_Details__c(Inv_DispatchHead__c = dispatchHeadMap.get(bu.Id).Id, Discount__c = instance.Id, Inv_BUDispatch__c = bu.Id,
                                                       Hierarchy_level_dispatch__c = PG.Section__c, Base_TO_Dispatch__c = 0, Status__c = 'New', Sequence__c = 1);
                } else {
                    dd = distpatchDetailsMap.get(bu.Id + '' + PG.Id);
                }
                wDispatchDetailList.add(new WrapperDispatchDetail(bu.Name, PG.Section__r.Name, PG.SNA_Code__c, dd));
            }
        }
    }
    // Load BU for dispatch details
    private List<Orga_BU__c> loadBU(Id BUId) {
        List<Orga_BU__c> businessUnitsList = new List<Orga_BU__c>();
        // Get BU Record Type based from global settings
        // TODO: MOVE OUTSIDE TO CLASS PROPERTY
        String[] recordTypeBUSettings = GlobalSettingsManager.loadGlobalSettings().selectedBURTList;
        Orga_BU__c buItem = [SELECT Id, Name, CurrencyIsoCode, Business_Unit_Type__c, RecordTypeId, RecordType.DeveloperName,
                             (SELECT Entity_List__r.Id, Entity_List__r.Name, Entity_List__r.CurrencyIsoCode, Entity_List__r.Business_Unit_Type__c,
                              Entity_List__r.RecordTypeId, Entity_List__r.RecordType.DeveloperName
                              FROM List_detail1__r
                              WHERE Entity_List__r.Status__c = 'Open')
                             FROM Orga_BU__c
                             WHERE RecordType.DeveloperName IN ('Store', 'Web', 'Warehouse', 'Country', 'List', 'Group', 'Banner')
                             AND Status__c = 'Open'
                             AND Id = :BUId
                             LIMIT 1000];
        // Add directly BU scope of type 'Store' or 'Web' or 'Banner'
        if(recordTypeBUSettings.contains(buItem.RecordType.DeveloperName)) {
            businessUnitsList.add(buItem);
        }
        // else get children for BU scope of type 'Country' or 'List' or 'Group'
        else {
            for(Orga_BU_List_Detail__c item : buItem.List_detail1__r) {
                if(recordTypeBUSettings.contains(item.Entity_List__r.RecordType.DeveloperName)) {
                    businessUnitsList.add(new Orga_BU__c(Id = item.Entity_List__c, Name = item.Entity_List__r.Name));
                }
            }
        }
        return businessUnitsList;
    }
    
    /**
     * Wrapper class for BU name + Section name + dispatch details
     * */
    public class WrapperDispatchDetail {
        public String nameBU {get;set;}
        public String section {get;set;}
        public String sna {get;set;}
        public Inv_BUDispatch_Details__c distpatchDetail {get;set;}
        
        public WrapperDispatchDetail(String bu, String sec, String snaPG, Inv_BUDispatch_Details__c dispatch) {
            nameBU = bu;
            section = sec;
            sna = snaPG;
            distpatchDetail = dispatch;
        }
    }
}