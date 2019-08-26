/**
 * Advanced Settings class
 **/
public class NegoptimSettings {
    
    public String sBusinessType {get; set;}
    // General Settings
    public Boolean runSellinReparentingForBusinessUnit {get; set;}
    public String defaultConditionCode {get; set;}
    public String delimiter {get; set;}
    public String csvDateFormat {get; set;}
    public String groupBU {get; set;}
    public Decimal tOGapTolerenceNegative {get; set;}
    public Decimal tOGapTolerencePositive {get; set;}
    public Decimal coopGapTolerenceNegative {get; set;}
    public Decimal coopGapTolerencePositive {get; set;}
    public Integer reminderLevel {get; set;}
    public Integer reminderValue1 {get; set;}
    public Integer reminderValue2 {get; set;}
    public Integer reminderValue3 {get; set;}
    public String reminderDescription1 {get; set;}
    public String reminderDescription2 {get; set;}
    public String reminderDescription3 {get; set;}
    // list of BU to be used in invoice reminder
    public List<Id> reminderBUManagedList {get; set;}
    // used to get Id for specifies BU ex: AMC
    public Id groupBU1 {get; set;}
    public Id groupBU2 {get; set;}
    public Id profile {get; set;}
    // Control the level of date validation overlap of contracts
    public Boolean datesOverlapControlBU {get; set;}
    // control the type of BU to be used in distribution (Condition_List page)
    public String[] selectedBURTList {get; set;}
    public Boolean allowUpdatingInvoiceDateOnPrint {get; set;}
    public Boolean allowUpdatingPrintDateOnPrint {get; set;}
    //closing days
    public Integer dispatchMaxClosingDay {get; set;}
    public Integer invoiceMaxClosingDay {get; set;}
    public Boolean dispatchAggregateMode {get; set;}
    // Grid Settings
    public String assortmentMatrixGridLayout {get; set;}
    public String productSwitchGridLayout {get; set;}
    public String productInnoGridLayout {get; set;}
    public String productStopGridLayout {get; set;}
    public String assortmentBudgetSimulatorGridLayout {get; set;}
    public String assortmentMatrixComparatorGridLayout {get; set;}
    // Grid Settings Profiles
    public String[] assortmentMatrixProfile {get; set;}
    public String[] productSwitchProfile {get; set;}
    public String[] productInnoProfile {get; set;}
    public String[] productStopProfile {get; set;}
    public String[] assortmentBudgetSimulatorProfile {get; set;}
    public String[] assortmentMatrixComparatorProfile {get; set;}
    // Products Management
    public String[] allowedProfilesToManageProducts {get; set;}
    // Mass batch form sections
    public Boolean MBF_Section_ContractTOProcedures {get; set;}
    public Boolean MBF_Section_ContractDuplication {get; set;}
    public Boolean MBF_Section_LastActiveContractProcedure {get; set;}
    public Boolean MBF_Section_ContractRates {get; set;}
    public Boolean MBF_Section_GroupScanAndSynchro {get; set;}
    public Boolean MBF_Section_PromoDetailProcedure {get; set;}
    public Boolean MBF_Section_MarketDataCollection {get; set;}
    public Boolean MBF_Section_AssortmentSFPlanning {get; set;}
    public Boolean MBF_Section_SellInProcedure {get; set;}
    public Boolean MBF_Section_Batches {get; set;}
    public Boolean MBF_Section_InvoiceReminder {get; set;}
    public Boolean MBF_Section_MassDistribution {get; set;}
    public Boolean MBF_Section_CallingWebServices {get; set;}
    public Boolean MBF_Section_PenaltiesProcedure {get; set;}
    public Boolean MBF_Section_ContractCounterpartyDetail {get; set;}
    public Boolean MBF_Section_RecalculateAssortmentDetail {get; set;}


    public NegoptimSettings() {
        this.delimiter = ',';
        this.csvDateFormat = 'dd/MM/yyyy';
        this.groupBU = null;
        this.tOGapTolerenceNegative = 0;
        this.tOGapTolerencePositive = 0;
        this.coopGapTolerenceNegative = 0;
        this.coopGapTolerencePositive = 0;
        this.reminderLevel = 0;
        this.reminderValue1 = 0;
        this.reminderValue2 = 0;
        this.reminderValue3 = 0;
        this.reminderBUManagedList = new List<Id>();
        this.groupBU1 = null;
        this.groupBU2 = null;
        this.profile = null;
        this.datesOverlapControlBU = false;
        this.selectedBURTList = new String[] {'Store', 'Web'};
        this.sBusinessType = BusinessType.None.name();
        this.allowUpdatingInvoiceDateOnPrint = true;
        this.allowUpdatingPrintDateOnPrint = true;
        this.dispatchMaxClosingDay = 31;
        this.invoiceMaxClosingDay = 31;
        this.dispatchAggregateMode = true;
        this.assortmentMatrixGridLayout = 'Matrix_Full';
        this.productSwitchGridLayout = 'Product_Switch';
        this.productInnoGridLayout = 'Product_Inno';
        this.productStopGridLayout = 'Product_Stop';
        this.assortmentBudgetSimulatorGridLayout = 'Budget_Simulator';
        this.assortmentMatrixComparatorGridLayout = 'Matrix_Full';
        this.assortmentMatrixProfile = new String[]{UserInfo.getProfileId()};
        this.productSwitchProfile = new String[]{UserInfo.getProfileId()};
        this.productInnoProfile = new String[]{UserInfo.getProfileId()};
        this.productStopProfile = new String[]{UserInfo.getProfileId()};
        this.assortmentBudgetSimulatorProfile = new String[]{UserInfo.getProfileId()};
        this.assortmentMatrixComparatorProfile = new String[]{UserInfo.getProfileId()};
        this.allowedProfilesToManageProducts = new String[]{UserInfo.getProfileId()};
        this.runSellinReparentingForBusinessUnit = true;
        this.defaultConditionCode = null;
        this.MBF_Section_ContractTOProcedures = true;
        this.MBF_Section_ContractDuplication = true;
        this.MBF_Section_LastActiveContractProcedure = true;
        this.MBF_Section_ContractRates = true;
        this.MBF_Section_GroupScanAndSynchro = true;
        this.MBF_Section_PromoDetailProcedure= true;
        this.MBF_Section_MarketDataCollection = true;
        this.MBF_Section_AssortmentSFPlanning = true;
        this.MBF_Section_SellInProcedure = true;
        this.MBF_Section_Batches = true;
        this.MBF_Section_InvoiceReminder = true;
        this.MBF_Section_MassDistribution = true;
        this.MBF_Section_CallingWebServices = true;
        this.MBF_Section_PenaltiesProcedure = true;
        this.MBF_Section_ContractCounterpartyDetail = true;
        this.MBF_Section_RecalculateAssortmentDetail = true;
    }
    
    /**
     * for Business Type
     * */
    public enum BusinessType {None, Retailer, CPG}
}