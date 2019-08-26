/**
 * @author ULiT
 * @date JUN-4-2018
 * @group Negoptim Support
 * @description Use GlobalSettingsManager to load and save global settings. global settings are available in salesforce cache and custom settings section
 ********************************************************************************************************************************************* */

public with sharing class GlobalSettingsManager {
    
    /**
     * @description Used to load global settings, first, try to load global settings from custom setting, if it's not available try to load data from salesforce cache (document)
     * @return NegoptimSettings
     ***************************************************************************************************************************************** */
    public static NegoptimSettings loadGlobalSettings() {
        NegoptimSettings settings = loadFromCustomSettings();
        if(settings == null) settings = loadFromCache();
        if(settings == null) settings = new NegoptimSettings();
        return settings;
    }
    /**
     * @description load Global Settings from salesforce custom settings section
     * @return NegoptimSettings
     ***************************************************************************************************************************************** */
    private static NegoptimSettings loadFromCustomSettings() {
        
        Map<String, NegoptimCustomSettings__c> negoptimSettingsMap = NegoptimCustomSettings__c.getAll();
        if(negoptimSettingsMap == null || negoptimSettingsMap.get('NegoptimSettings') == null){
            return null;
        }
                
        NegoptimCustomSettings__c negoptimCustomSettings = negoptimSettingsMap.get('NegoptimSettings');
        NegoptimSettings negoSettings = new NegoptimSettings();
        
        // General Settings
        negoSettings.runSellinReparentingForBusinessUnit = negoptimCustomSettings.run_Sellin_Reparenting_For_Business_Unit__c;
        negoSettings.defaultConditionCode = negoptimCustomSettings.default_Condition_Code__c;
        negoSettings.delimiter = negoptimCustomSettings.CSV_Delimiter__c;
        negoSettings.csvDateFormat = negoptimCustomSettings.csv_Date_Format__c;
        negoSettings.groupBU = negoptimCustomSettings.Group_Code_BU_for_Integration__c;
        negoSettings.sBusinessType = negoptimCustomSettings.Business_Type__c;
        negoSettings.tOGapTolerenceNegative = negoptimCustomSettings.TO_gap_Tolerence_neg__c;
        negoSettings.tOGapTolerencePositive = negoptimCustomSettings.TO_gap_Tolerence_Pos__c;
        negoSettings.coopGapTolerenceNegative = negoptimCustomSettings.Coop_gap_Tolerence_neg__c;
        negoSettings.coopGapTolerencePositive = negoptimCustomSettings.Coop_gap_Tolerence_pos__c;
        negoSettings.reminderLevel = negoptimCustomSettings.Level_of_reminder_managed__c != null ? negoptimCustomSettings.Level_of_reminder_managed__c.intValue() : 0;
        negoSettings.reminderValue1 = negoptimCustomSettings.Reminder1__c != null ? negoptimCustomSettings.Reminder1__c.intValue() : 0;
        negoSettings.reminderValue2 = negoptimCustomSettings.Reminder2__c != null ? negoptimCustomSettings.Reminder2__c.intValue() : 0;
        negoSettings.reminderValue3 = negoptimCustomSettings.Reminder3__c != null ? negoptimCustomSettings.Reminder3__c.intValue() : 0;
        negoSettings.reminderDescription1 = negoptimCustomSettings.Reminder_Description1__c;
        negoSettings.reminderDescription2 = negoptimCustomSettings.Reminder_Description2__c;
        negoSettings.reminderDescription3 = negoptimCustomSettings.Reminder_Description3__c;
        if(negoptimCustomSettings.Reminder_BU_Managed__c != null) {
            negoSettings.reminderBUManagedList = negoptimCustomSettings.Reminder_BU_Managed__c.split(',');
        }
        negoSettings.groupBU1 = negoptimCustomSettings.Group_BU_1__c;
        negoSettings.groupBU2 = negoptimCustomSettings.Group_BU_2__c;
        negoSettings.profile = negoptimCustomSettings.Profile__c;
        negoSettings.datesOverlapControlBU = negoptimCustomSettings.Allow_contract_overlap_dates__c;
        if(negoptimCustomSettings.BU_Record_types__c != null) {
            negoSettings.selectedBURTList = negoptimCustomSettings.BU_Record_types__c.split(',');
        }
        negoSettings.allowUpdatingInvoiceDateOnPrint = negoptimCustomSettings.Allow_Updating_Invoice_Date_On_Print__c;
        negoSettings.allowUpdatingPrintDateOnPrint = negoptimCustomSettings.Allow_Updating_Print_Date_On_Print__c;
        negoSettings.dispatchMaxClosingDay = Integer.valueOf(negoptimCustomSettings.Dispatch_Max_Closing_Day__c);
        negoSettings.invoiceMaxClosingDay = Integer.valueOf(negoptimCustomSettings.Invoice_Max_Closing_Day__c);
        negoSettings.dispatchAggregateMode = negoptimCustomSettings.Dispatch_Aggregate_Mode__c;
        // Grid Layout Settings
        negoSettings.assortmentMatrixGridLayout = negoptimCustomSettings.Assortment_Matrix_Grid_Layout__c;
        negoSettings.productSwitchGridLayout = negoptimCustomSettings.Product_Switch_Grid_Layout__c;
        negoSettings.productInnoGridLayout = negoptimCustomSettings.Product_Inno_Grid_Layout__c;
        negoSettings.productStopGridLayout = negoptimCustomSettings.Product_Stop_Grid_Layout__c;
        negoSettings.assortmentBudgetSimulatorGridLayout = negoptimCustomSettings.Assortment_Budget_Simulator_Grid_Layout__c;
        negoSettings.assortmentMatrixComparatorGridLayout = negoptimCustomSettings.Assortment_Matrix_Comparator_Grid_Layout__c;
        // Grid Settings Profiles
        if(negoptimCustomSettings.Assortment_Matrix_Profile__c != null) {
            negoSettings.assortmentMatrixProfile = negoptimCustomSettings.Assortment_Matrix_Profile__c.split(';');
        }
        if(negoptimCustomSettings.Product_Switch_Profile__c != null) {
            negoSettings.productSwitchProfile = negoptimCustomSettings.Product_Switch_Profile__c.split(';');
        }
        if(negoptimCustomSettings.Product_Inno_Profile__c != null) {
            negoSettings.productInnoProfile = negoptimCustomSettings.Product_Inno_Profile__c.split(';');
        }
        if(negoptimCustomSettings.Product_Stop_Profile__c != null) {
            negoSettings.productStopProfile = negoptimCustomSettings.Product_Stop_Profile__c.split(';');
        }
        if(negoptimCustomSettings.Assortment_Budget_Simulator_Profile__c != null) {
            negoSettings.assortmentBudgetSimulatorProfile = negoptimCustomSettings.Assortment_Budget_Simulator_Profile__c.split(';');
        }
        if(negoptimCustomSettings.Assortment_Matrix_Comparator_Profile__c != null) {
            negoSettings.assortmentMatrixComparatorProfile = negoptimCustomSettings.Assortment_Matrix_Comparator_Profile__c.split(';');
        }
        // Products Profile Management
        if(negoptimCustomSettings.Allowed_profiles_to_manage_Products__c != null) {
            negoSettings.allowedProfilesToManageProducts = negoptimCustomSettings.Allowed_profiles_to_manage_Products__c.split(';');
        }
        // Mass Batch Form Settings
        negoSettings.MBF_Section_ContractTOProcedures = negoptimCustomSettings.MBF_Section_ContractTOProcedures__c;
        negoSettings.MBF_Section_ContractDuplication = negoptimCustomSettings.MBF_Section_ContractDuplication__c;
        negoSettings.MBF_Section_LastActiveContractProcedure = negoptimCustomSettings.MBF_Section_LastActiveContractProcedure__c;
        negoSettings.MBF_Section_ContractRates = negoptimCustomSettings.MBF_Section_ContractRates__c;
        negoSettings.MBF_Section_GroupScanAndSynchro = negoptimCustomSettings.MBF_Section_GroupScanAndSynchro__c;
        negoSettings.MBF_Section_PromoDetailProcedure = negoptimCustomSettings.MBF_Section_PromoDetailProcedure__c;
        negoSettings.MBF_Section_MarketDataCollection = negoptimCustomSettings.MBF_Section_MarketDataCollection__c;
        negoSettings.MBF_Section_AssortmentSFPlanning = negoptimCustomSettings.MBF_Section_AssortmentSFPlanning__c;
        negoSettings.MBF_Section_SellInProcedure = negoptimCustomSettings.MBF_Section_SellInProcedure__c;
        negoSettings.MBF_Section_Batches = negoptimCustomSettings.MBF_Section_Batches__c;
        negoSettings.MBF_Section_InvoiceReminder = negoptimCustomSettings.MBF_Section_InvoiceReminder__c;
        negoSettings.MBF_Section_MassDistribution = negoptimCustomSettings.MBF_Section_MassDistribution__c;
        negoSettings.MBF_Section_CallingWebServices = negoptimCustomSettings.MBF_Section_CallingWebServices__c;
        negoSettings.MBF_Section_PenaltiesProcedure = negoptimCustomSettings.MBF_Section_PenaltiesProcedure__c;
        negoSettings.MBF_Section_ContractCounterpartyDetail = negoptimCustomSettings.MBF_Section_ContractCounterpartyDetail__c;
        negoSettings.MBF_Section_RecalculateAssortmentDetail = negoptimCustomSettings.MBF_Section_RecalculateAssortmentDetail__c;

        return negoSettings;
    }
    /**
     * @description load Global Settings from Cache (the cache get the settings from document)
     * @return NegoptimSettings
     ***************************************************************************************************************************************** */
    private static NegoptimSettings loadFromCache() {
        try {
            return (NegoptimSettings) Cache.Org.get(GlobalSettingCache.class, NegoptimHelper.DOCUMENT_SETTINGS_NAME);
        } catch(Exception ex){
            return null;
        }
    }
    /**
     * @description save Global Settings in cache and custom settings
     * @param NegoptimSettings settings to be saved
     * @return Set<String> list of errors, if no errors return an empty list
     ***************************************************************************************************************************************** */
    public static Set<String> saveGlobalSettings(NegoptimSettings negoSettings) {
        Set<String> errors = new Set<String>();
        errors.addAll(saveCustomSettings(negoSettings));
        errors.addAll(saveGlobalSettingDocument(negoSettings));
        return errors;
    }
    /**
     * @description save Global Settings in custom settings
     * @param NegoptimSettings settings to be saved in custom settings
     * @return Set<String> list of errors, if no errors return an empty list
     ***************************************************************************************************************************************** */
    private static Set<String> saveCustomSettings(NegoptimSettings negoSettings){
        Set<String> errors = new Set<String>();
        
        final String settingsKey = 'NegoptimSettings';
        
        Map<String, NegoptimCustomSettings__c> negoptimSettingMap = NegoptimCustomSettings__c.getAll();
        NegoptimCustomSettings__c negoptimCustomSettings;
        if(negoptimSettingMap == null || negoptimSettingMap.get(settingsKey) == null){
            negoptimCustomSettings = new NegoptimCustomSettings__c(name = settingsKey);
        }else{
            negoptimCustomSettings = negoptimSettingMap.get(settingsKey);
        }
        
        negoptimCustomSettings.CSV_Delimiter__c = negoSettings.delimiter;
        negoptimCustomSettings.csv_Date_Format__c = negoSettings.csvDateFormat;
        negoptimCustomSettings.Group_Code_BU_for_Integration__c = negoSettings.groupBU;
        negoptimCustomSettings.Business_Type__c = negoSettings.sBusinessType;
        negoptimCustomSettings.TO_gap_Tolerence_neg__c = negoSettings.tOGapTolerenceNegative;
        negoptimCustomSettings.TO_gap_Tolerence_Pos__c = negoSettings.tOGapTolerencePositive;
        negoptimCustomSettings.Coop_gap_Tolerence_neg__c = negoSettings.coopGapTolerenceNegative;
        negoptimCustomSettings.Coop_gap_Tolerence_pos__c = negoSettings.coopGapTolerencePositive;
        negoptimCustomSettings.Level_of_reminder_managed__c = negoSettings.reminderLevel;
        negoptimCustomSettings.Reminder1__c = negoSettings.reminderValue1;
        negoptimCustomSettings.Reminder2__c = negoSettings.reminderValue2;
        negoptimCustomSettings.Reminder3__c = negoSettings.reminderValue3;
        negoptimCustomSettings.Reminder_Description1__c = negoSettings.reminderDescription1;
        negoptimCustomSettings.Reminder_Description2__c = negoSettings.reminderDescription2;
        negoptimCustomSettings.Reminder_Description3__c = negoSettings.reminderDescription3;
        if(!negoSettings.reminderBUManagedList.isEmpty()) {
            negoptimCustomSettings.Reminder_BU_Managed__c = String.join(negoSettings.reminderBUManagedList, ',');
        }
        negoptimCustomSettings.Group_BU_1__c = negoSettings.groupBU1;
        negoptimCustomSettings.Group_BU_2__c = negoSettings.groupBU2;
        negoptimCustomSettings.Profile__c = negoSettings.profile;
        negoptimCustomSettings.Allow_contract_overlap_dates__c = negoSettings.datesOverlapControlBU;
        String buRecType = '';
        if(negoSettings.selectedBURTList != null){
            for (String selected : negoSettings.selectedBURTList){
                buRecType +=selected+',';
            }
        }
        negoptimCustomSettings.BU_Record_types__c = buRecType.removeEnd(',');
        negoptimCustomSettings.Allow_Updating_Invoice_Date_On_Print__c = negoSettings.allowUpdatingInvoiceDateOnPrint;
        negoptimCustomSettings.Allow_Updating_Print_Date_On_Print__c = negoSettings.allowUpdatingPrintDateOnPrint;
        negoptimCustomSettings.Dispatch_Max_Closing_Day__c = negoSettings.dispatchMaxClosingDay;
        negoptimCustomSettings.Invoice_Max_Closing_Day__c = negoSettings.invoiceMaxClosingDay == 0 ? null : negoSettings.invoiceMaxClosingDay;
        negoptimCustomSettings.Dispatch_Aggregate_Mode__c = negoSettings.dispatchAggregateMode;
        //Grid Layout settings
        negoptimCustomSettings.Assortment_Matrix_Grid_Layout__c = negoSettings.assortmentMatrixGridLayout;
        negoptimCustomSettings.Product_Switch_Grid_Layout__c = negoSettings.productSwitchGridLayout;
        negoptimCustomSettings.Product_Inno_Grid_Layout__c = negoSettings.productInnoGridLayout;
        negoptimCustomSettings.Product_Stop_Grid_Layout__c = negoSettings.productStopGridLayout;
        negoptimCustomSettings.Assortment_Budget_Simulator_Grid_Layout__c = negoSettings.assortmentBudgetSimulatorGridLayout;
        negoptimCustomSettings.Assortment_Matrix_Comparator_Grid_Layout__c = negoSettings.assortmentMatrixComparatorGridLayout;
        // Grid Settings Profiles
        negoptimCustomSettings.Assortment_Matrix_Profile__c = negoSettings.assortmentMatrixProfile != null ? String.join(negoSettings.assortmentMatrixProfile, ';') : '';
        negoptimCustomSettings.Product_Switch_Profile__c = negoSettings.productSwitchProfile != null ? String.join(negoSettings.productSwitchProfile, ';') : '';
        negoptimCustomSettings.Product_Inno_Profile__c = negoSettings.productInnoProfile != null ? String.join(negoSettings.productInnoProfile, ';') : '';
        negoptimCustomSettings.Product_Stop_Profile__c = negoSettings.productStopProfile != null ? String.join(negoSettings.productStopProfile, ';') : '';
        negoptimCustomSettings.Assortment_Budget_Simulator_Profile__c = negoSettings.assortmentBudgetSimulatorProfile != null ? String.join(negoSettings.assortmentBudgetSimulatorProfile, ';') : '';
        negoptimCustomSettings.Assortment_Matrix_Comparator_Profile__c = negoSettings.assortmentMatrixComparatorProfile != null ? String.join(negoSettings.assortmentMatrixComparatorProfile, ';') : '';
        // Products Management
        negoptimCustomSettings.Allowed_profiles_to_manage_Products__c = negoSettings.allowedProfilesToManageProducts != null ? String.join(negoSettings.allowedProfilesToManageProducts, ';') : '';
        // General Settings
        negoptimCustomSettings.Run_Sellin_Reparenting_For_Business_Unit__c = negoSettings.runSellinReparentingForBusinessUnit;
        negoptimCustomSettings.Default_Condition_Code__c = negoSettings.defaultConditionCode;
        // Mass Batch Form Settings
        negoptimCustomSettings.MBF_Section_ContractTOProcedures__c = negoSettings.MBF_Section_ContractTOProcedures;
        negoptimCustomSettings.MBF_Section_ContractDuplication__c = negoSettings.MBF_Section_ContractDuplication;
        negoptimCustomSettings.MBF_Section_LastActiveContractProcedure__c = negoSettings.MBF_Section_LastActiveContractProcedure;
        negoptimCustomSettings.MBF_Section_ContractRates__c = negoSettings.MBF_Section_ContractRates;
        negoptimCustomSettings.MBF_Section_GroupScanAndSynchro__c = negoSettings.MBF_Section_GroupScanAndSynchro;
        negoptimCustomSettings.MBF_Section_PromoDetailProcedure__c = negoSettings.MBF_Section_PromoDetailProcedure;
        negoptimCustomSettings.MBF_Section_MarketDataCollection__c = negoSettings.MBF_Section_MarketDataCollection;
        negoptimCustomSettings.MBF_Section_AssortmentSFPlanning__c = negoSettings.MBF_Section_AssortmentSFPlanning;
        negoptimCustomSettings.MBF_Section_SellInProcedure__c = negoSettings.MBF_Section_SellInProcedure;
        negoptimCustomSettings.MBF_Section_Batches__c = negoSettings.MBF_Section_Batches;
        negoptimCustomSettings.MBF_Section_InvoiceReminder__c = negoSettings.MBF_Section_InvoiceReminder;
        negoptimCustomSettings.MBF_Section_MassDistribution__c = negoSettings.MBF_Section_MassDistribution;
        negoptimCustomSettings.MBF_Section_CallingWebServices__c = negoSettings.MBF_Section_CallingWebServices;  
        negoptimCustomSettings.MBF_Section_PenaltiesProcedure__c = negoSettings.MBF_Section_PenaltiesProcedure;
        negoptimCustomSettings.MBF_Section_ContractCounterpartyDetail__c = negoSettings.MBF_Section_ContractCounterpartyDetail;
        negoptimCustomSettings.MBF_Section_RecalculateAssortmentDetail__c = negoSettings.MBF_Section_RecalculateAssortmentDetail;
        
        try{
            // check security on create or update negoptimCustomSettings fields
            String [] negoptimCustomSettingsFields = new String [] {NegoptimHelper.normalizeAPIName('CSV_Delimiter__c'), NegoptimHelper.normalizeAPIName('csv_Date_Format__c'),
                NegoptimHelper.normalizeAPIName('Group_Code_BU_for_Integration__c'), NegoptimHelper.normalizeAPIName('Business_Type__c'),
                NegoptimHelper.normalizeAPIName('TO_gap_Tolerence_neg__c'), NegoptimHelper.normalizeAPIName('TO_gap_Tolerence_Pos__c'),
                NegoptimHelper.normalizeAPIName('Coop_gap_Tolerence_neg__c'), NegoptimHelper.normalizeAPIName('Coop_gap_Tolerence_pos__c'),
                NegoptimHelper.normalizeAPIName('Level_of_reminder_managed__c'), NegoptimHelper.normalizeAPIName('Reminder1__c'),
                NegoptimHelper.normalizeAPIName('Reminder2__c'), NegoptimHelper.normalizeAPIName('Reminder3__c'),
                NegoptimHelper.normalizeAPIName('Reminder_Description1__c'), NegoptimHelper.normalizeAPIName('Reminder_Description2__c'),
                NegoptimHelper.normalizeAPIName('Reminder_Description3__c'), NegoptimHelper.normalizeAPIName('Group_BU_1__c'),
                NegoptimHelper.normalizeAPIName('Group_BU_2__c'), NegoptimHelper.normalizeAPIName('Profile__c'),
                NegoptimHelper.normalizeAPIName('Allow_contract_overlap_dates__c'), NegoptimHelper.normalizeAPIName('Reminder_BU_Managed__c')};
                
            if(NegoptimHelper.checkCreatibility(NegoptimCustomSettings__c.SObjectType, negoptimCustomSettingsFields) && 
               NegoptimHelper.checkUpdatibility(NegoptimCustomSettings__c.SObjectType, negoptimCustomSettingsFields)) {
                   upsert negoptimCustomSettings;
               }
        }catch(DmlException ex){
            errors.add(Label.MSG_Error_Occurred + ' : ' + ex.getDmlMessage(0));
            
        }
        return errors;
    }
    /**
     * @description save Global Settings in custom settings
     * @param NegoptimSettings settings to be saved in the document
     * @return Set<String> list of errors, if no errors return an empty list
     ***************************************************************************************************************************************** */
    private static Set<String> saveGlobalSettingDocument(NegoptimSettings negoSettings){
        // check security on create or update document fields
        String [] documentFields = new String [] { 'Name', 'AuthorId', 'Body', 'ContentType', 'Type', 'FolderId'};
            if(!NegoptimHelper.checkCreatibility(Document.SObjectType, documentFields) || !NegoptimHelper.checkUpdatibility(Document.SObjectType, documentFields)) {
                return new Set<String>();
            }
        
        Document settingsFile;
        Folder folderSetting;
        Set<String> errors = new Set<String>();
        if(!NegoptimHelper.checkAccessibility(Folder.SObjectType, new String [] {'Id'}) ||
           !NegoptimHelper.checkAccessibility(Document.SObjectType, new String [] {'Id'})) {
               errors.add(Label.MSG_Access_Denied);
           }
        else {
            // Get folder settings.
            List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = :NegoptimHelper.FOLDER_SETTINGS_NAME LIMIT 1];
            if(folders != null && folders.size() > 0)
                folderSetting = folders.get(0);
            if(folderSetting == null) {
                errors.add(string.format(Label.MSG_FolderSettingsNotExist, new String[]{ NegoptimHelper.FOLDER_SETTINGS_NAME }));
            }
        }
        if(errors.size() == 0) {
            // Get document settings.
            List<Document> documents = [SELECT Id, FolderId, Folder.Name, Body, AuthorId FROM Document 
                                        WHERE Folder.Name = :NegoptimHelper.FOLDER_SETTINGS_NAME
                                        AND Name = :NegoptimHelper.DOCUMENT_SETTINGS_NAME LIMIT 1];
            if(documents != null && documents.size() > 0)
                settingsFile = documents.get(0);
            
            String strJSON = JSON.serialize(negoSettings);
            try {
                Blob content = Blob.valueof(strJSON);
                Id authorId = UserInfo.getUserId();
                Boolean editContent = true;
                if (folderSetting != null) {
                    if (settingsFile != null) {
                        if (settingsFile.Body != content) {
                            settingsFile.Body = content;
                            settingsFile.AuthorId = authorId;
                        } else {
                            errors.add('Save Global Setting in Document Error: Nothing to update');
                            editContent = false;
                        }
                    }
                    else{
                        settingsFile = new Document(Name = NegoptimHelper.DOCUMENT_SETTINGS_NAME, Type = 'json',
                                                    ContentType = 'application/json', //DeveloperName = NegoptimHelper.DOCUMENT_SETTINGS_NAME,
                                                    Body = content, FolderId = folderSetting.Id, AuthorId = authorId);                
                    }
                } else{
                    errors.add(string.format(Label.MSG_FolderSettingsNotExist, new String[]{ NegoptimHelper.FOLDER_SETTINGS_NAME }));
                }
                if (settingsFile != null && editContent) {
                    if(NegoptimHelper.checkCreatibility(Document.SObjectType, documentFields) &&
                       NegoptimHelper.checkUpdatibility(Document.SObjectType, documentFields)) {
                           upsert settingsFile;
                       }
                    // Remove from cache to reload the new value
                    ////Cache.Org.remove(GlobalSettingCache.class, NegoptimHelper.DOCUMENT_SETTINGS_NAME);
                }
            } catch(DmlException e) {
                errors.add(Label.MSG_Error_Occurred + ' : ' + e.getDmlMessage(0));
            } catch(Exception e) {
                
            }
        }
        return errors;
    }
    /*
     * @description this class used to handle the miss object in the cache, salesforce check for the cache if object is not available, it calls load data then return the result.
     ***************************************************************************************************************************************** */
    public class GlobalSettingCache implements Cache.CacheBuilder{
        
        public Object doLoad(String cacheType){
            
            Document settingsFile;
            NegoptimSettings negoSettings = new NegoptimSettings();
            List<Document> documents = [SELECT Id, Body FROM Document WHERE Folder.Name = :NegoptimHelper.FOLDER_SETTINGS_NAME AND Name = :cacheType LIMIT 1];
            if(documents != null && documents.size() > 0) {
                settingsFile = documents.get(0);
                negoSettings = (NegoptimSettings) JSON.deserializeStrict(settingsFile.Body.toString(), NegoptimSettings.class);        
            }
            else{
                negoSettings = new NegoptimSettings();
            }
            return negoSettings;
        }
    }
    
}