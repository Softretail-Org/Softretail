/*
 * Item selection simulation for marketing event
 */
public with sharing class CommercialPlanSimulatorController extends NegoptimBaseController  {
    public Commercial_Plan__c commercialPlan {get; set;}
    public Boolean isCanceled {get; set;}
    
    String commercialPlanId;
    Map<Id, Commercial_Plan_Detail__c> commercialPlanDetailMap {get; set;}
    
    // Filter product Params
    public List<String> selectedBrands {get; set;}
    Public Map<String, Sup_Brand__c> brandMap {get; set;}
    public LookupValue structureLevelLookup {get; set;}
    public LookupValue brandLookup {get; set;}
    public LookupValue negoScopeLookup {get; set;}
    public Boolean inAssortment {get; set;}
    public Boolean isActiveProduct {get; set;}
    public String structureLevelName {get; set;}
    public String brandName {get; set;}
    public String negoScopeName {get; set;}
    
    List<ProductWrapper> productList {get; set;}
    Set<Id> selectedProductsIds = new Set<Id>();
    Map<Id, ProductUpdatedWrapper> selectedProductMap {get; set;}
    List<ProductWrapper> simulatorList {get; set;}
    Map<Id, Integer> lastSelectedIdsMap = new Map<Id, Integer>();
    Set<Id> simulatorIds;
    Set<Id> NsPGSet = new Set<Id>();
    
    // Selection and filter products
    public List<String> alphaList {get; set;}
    public String alphaFilter {get; set;}
    public String searchName {get; set;}
    String saveSearchName;
    String queryProduct;
    String querySelectedProduct;
    
    // display sort and number for standard list controllers
    public String alphaFilterSimulator {get; set;}
    public Integer recPerPage {get; set;}
    Public Integer noOfRecords {get; set;}
    public list<SelectOption> recPerPageOption {get; set;}
    public String sortFieldSave;
    
    public String sortFieldSaveSimulator;
    public Integer recPerPageSimulatorInit {get; set;}
    public Integer recPerPageSimulator {get; set;}
    Public Integer noOfRecordsInit {get; set;}
    Public Integer noOfRecordsFact {get; set;}
    
    // Global Params
    Public Date startHistoryPeriod {get; set;}
    Public Date endHistoryPeriod {get; set;}
    Public String sStartHistoryPeriod {
        get {
            return this.startHistoryPeriod != null ? this.startHistoryPeriod.format() : '';
        }
        set;
    }
    Public String sEndHistoryPeriod {
        get {
            return this.endHistoryPeriod != null ? this.endHistoryPeriod.format() : '';
        }
        set;
    }
    Public Decimal amount {get; set;}
    Public Decimal elasticityRateCalc {get; set;}
    Public Decimal correctionRate {get; set;}
    Public Decimal contributionRate {get; set;}    
    public String sellInOrOut {get; set;}
    public Boolean selectedSellIn {get; set;}
    public String historyReference {get; set;}    
    Map<Id, Decimal> pvpMap {get;set;}
    Map<Id, Decimal> sellOutUnitMap {get;set;}
    Map<Id, Decimal> discountedValueMap {get;set;}
    
    // Fact Simulator Params
    List<Product2> allSimulatorRecords = new List<Product2>();
    public Transient List<ProductWrapper> simulatorRecords {get; set;}
       
    // Used for the Import process.
    public boolean displayImportPopup {get; set;}
  	public boolean importFile {get; set;}
    
    // initial Columns Init Simulator
    public NegoptimNumber totalSellinPriceInit {get; set;}
    public NegoptimNumber totalSellinUnitInit {get; set;}
    public NegoptimNumber totalSellinValueInit {get; set;}
    public NegoptimNumber totalMarketShareInit {get; set;}
    public NegoptimNumber totalSellOutUnitInit {get; set;}
    public NegoptimNumber totalSellOutValueInit {get; set;}
    public NegoptimNumber totalUnitsInit {get; set;}
    public NegoptimNumber totalValueInit {get; set;}
    public NegoptimNumber totalDiscountedValueInit {get; set;}
    public NegoptimNumber totalDiscSellOutInit {get; set;}
    public NegoptimNumber totalCorSellInInit {get; set;}
    public NegoptimNumber totalCorCOGSInit {get; set;}
    public NegoptimNumber totalRegularGMInit {get; set;}
    public NegoptimNumber totalGMAfterDiscInit {get; set;}
    public NegoptimNumber totalDiffInit {get; set;}
    
    // Init Simulator Params
    List<Product2> allSimulatorInitRecords = new List<Product2>();
    public Transient List<ProductWrapper> simulatorInitRecords {get; set;}    
    String querySimulatorInit;
    
    // initial Columns Fact Simulator
    public NegoptimNumber totalSellinPrice {get; set;}
    public NegoptimNumber totalSellinUnit {get; set;}
    public NegoptimNumber totalSellinValue {get; set;}
    public NegoptimNumber totalMarketShare {get; set;}
    public NegoptimNumber totalSellOutUnit {get; set;}
    public NegoptimNumber totalSellOutValue {get; set;}
    public NegoptimNumber totalUnits {get; set;}
    public NegoptimNumber totalValue {get; set;}
    public NegoptimNumber totalDiscountedValue {get; set;}
    public NegoptimNumber totalDiscSellOut {get; set;}
    public NegoptimNumber totalCorSellIn {get; set;}
    public NegoptimNumber totalCorCOGS {get; set;}
    public NegoptimNumber totalRegularGM {get; set;}
    public NegoptimNumber totalGMAfterDisc {get; set;}
    public NegoptimNumber totalDiff {get; set;}
    
    // initial Columns GAP Simulator
    public NegoptimNumber totalSellinPriceGAP {
        get{ totalSellinPriceGAP.value = totalSellinPrice.value - totalSellinPriceInit.value; return totalSellinPriceGAP;} set;
    }
    public NegoptimNumber totalSellinUnitGAP {
        get{ totalSellinUnitGAP.value = totalSellinUnit.value - totalSellinUnitInit.value; return totalSellinUnitGAP;} set;
    }
    public NegoptimNumber totalSellinValueGAP {
        get{ totalSellinValueGAP.value = totalSellinValue.value - totalSellinValueInit.value; return totalSellinValueGAP;} set;
    }
    public NegoptimNumber totalMarketShareGAP {
        get{ totalMarketShareGAP.value = totalMarketShare.value - totalMarketShareInit.value; return totalMarketShareGAP;} set;
    }
    public NegoptimNumber totalSellOutUnitGAP {
        get{ totalSellOutUnitGAP.value = totalSellOutUnit.value - totalSellOutUnitInit.value; return totalSellOutUnitGAP;} set;
    }
    public NegoptimNumber totalSellOutValueGAP {
        get{ totalSellOutValueGAP.value = totalSellOutValue.value - totalSellOutValueInit.value; return totalSellOutValueGAP;} set;
    }
    public NegoptimNumber totalUnitsGAP {
        get{ totalUnitsGAP.value = totalUnits.value - totalUnitsInit.value; return totalUnitsGAP;} set;
    }
    public NegoptimNumber totalValueGAP {
        get{ totalValueGAP.value = totalValue.value - totalValueInit.value; return totalValueGAP;} set;
    }
    public NegoptimNumber totalDiscountedValueGAP {
        get{ totalDiscountedValueGAP.value = totalDiscountedValue.value - totalDiscountedValueInit.value; return totalDiscountedValueGAP;} set;
    }
    public NegoptimNumber totalDiscSellOutGAP {
        get{ totalDiscSellOutGAP.value = totalDiscSellOut.value - totalDiscSellOutInit.value; return totalDiscSellOutGAP;} set;
    }
    public NegoptimNumber totalCorSellInGAP {
        get{ totalCorSellInGAP.value = totalCorSellIn.value - totalCorSellInInit.value; return totalCorSellInGAP;} set;
    }
    public NegoptimNumber totalCorCOGSGAP {
        get{ totalCorCOGSGAP.value = totalCorCOGS.value - totalCorCOGSInit.value; return totalCorCOGSGAP;} set;
    }
    public NegoptimNumber totalRegularGMGAP {
        get{ totalRegularGMGAP.value = totalRegularGM.value - totalRegularGMInit.value; return totalRegularGMGAP;} set;
    }
    public NegoptimNumber totalGMAfterDiscGAP {
        get{ totalGMAfterDiscGAP.value = totalGMAfterDisc.value - totalGMAfterDiscInit.value; return totalGMAfterDiscGAP;} set;
    }
    public NegoptimNumber totalDiffGAP {
        get{ totalDiffGAP.value = totalDiff.value - totalDiffInit.value; return totalDiffGAP;} set;
    }
    
    public String xmlheader {
        get{
            return '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        }
    }
    
    public Boolean exportSimulatorExcel {get; set;}
    public Boolean editSimulator {get; set;}
    public Boolean updatePromoFact {get; set;}
    public Boolean simulatorIsUpdated {get; set;}
    
    public CommercialPlanSimulatorController(ApexPages.StandardController stdController) {
        // Initial Load
        this.commercialPlanDetailMap = new Map<Id, Commercial_Plan_Detail__c>();
        this.productList = new List<ProductWrapper>();
        this.selectedProductMap = new Map<Id, ProductUpdatedWrapper>();
        this.simulatorList = new List<ProductWrapper>();
        this.simulatorIds = new Set<Id>();
        this.selectedBrands = new List<String>();
        this.brandMap = new Map<String, Sup_Brand__c>();
        this.structureLevelLookup = new LookupValue(true);
        this.brandLookup = new LookupValue(true);
        this.negoScopeLookup = new LookupValue(false);
        this.pvpMap = new Map<Id, Decimal>();
        this.sellOutUnitMap = new Map<Id, Decimal>();
        this.discountedValueMap = new Map<Id, Decimal>();
        
        this.inAssortment = false;
        this.isActiveProduct = true;
        this.amount = 0;
        this.elasticityRateCalc = 100;
        this.correctionRate = 1;
        this.contributionRate = 0;
        this.displayImportPopup = false;
        this.importFile = false;
        this.selectedSellIn = true;
        this.exportSimulatorExcel = false;
        this.editSimulator = false;
        this.updatePromoFact = false;
        this.simulatorIsUpdated = false;
        
        //records for page initialization
        recPerPageOption = new List<SelectOption>();
        recPerPageOption.add(new SelectOption('5','5'));
        recPerPageOption.add(new SelectOption('10','10'));
        recPerPageOption.add(new SelectOption('25','25'));
        recPerPageOption.add(new SelectOption('50','50'));
        recPerPage = 10;
        recPerPageSimulator = 10;
        recPerPageSimulatorInit = 10;
        
        // initial columns values
        this.totalSellinPrice = new NegoptimNumber(2);
        this.totalSellinUnit = new NegoptimNumber(2);
        this.totalSellinValue = new NegoptimNumber(2);
        this.totalMarketShare = new NegoptimNumber(2);
        this.totalSellOutUnit = new NegoptimNumber(2);
        this.totalSellOutValue = new NegoptimNumber(2);
        this.totalUnits = new NegoptimNumber(2);
        this.totalValue = new NegoptimNumber(2);
        this.totalDiscountedValue = new NegoptimNumber(2);
        this.totalDiscSellOut = new NegoptimNumber(2);
        this.totalCorSellIn = new NegoptimNumber(2);
        this.totalCorCOGS = new NegoptimNumber(2);
        this.totalRegularGM = new NegoptimNumber(2);
        this.totalGMAfterDisc = new NegoptimNumber(2);
        this.totalDiff = new NegoptimNumber(2);

        this.totalSellinPriceInit = new NegoptimNumber(2);
        this.totalSellinUnitInit = new NegoptimNumber(2);
        this.totalSellinValueInit = new NegoptimNumber(2);
        this.totalMarketShareInit = new NegoptimNumber(2);
        this.totalSellOutUnitInit = new NegoptimNumber(2);
        this.totalSellOutValueInit = new NegoptimNumber(2);
        this.totalUnitsInit = new NegoptimNumber(2);
        this.totalValueInit = new NegoptimNumber(2);
        this.totalDiscountedValueInit = new NegoptimNumber(2);
        this.totalDiscSellOutInit = new NegoptimNumber(2);
        this.totalCorSellInInit = new NegoptimNumber(2);
        this.totalCorCOGSInit = new NegoptimNumber(2);
        this.totalRegularGMInit = new NegoptimNumber(2);
        this.totalGMAfterDiscInit = new NegoptimNumber(2);
        this.totalDiffInit = new NegoptimNumber(2);
        
        this.totalSellinPriceGAP = new NegoptimNumber(2);
        this.totalSellinUnitGAP = new NegoptimNumber(2);
        this.totalSellinValueGAP = new NegoptimNumber(2);
        this.totalMarketShareGAP = new NegoptimNumber(2);
        this.totalSellOutUnitGAP = new NegoptimNumber(2);
        this.totalSellOutValueGAP = new NegoptimNumber(2);
        this.totalUnitsGAP = new NegoptimNumber(2);
        this.totalValueGAP = new NegoptimNumber(2);
        this.totalDiscountedValueGAP = new NegoptimNumber(2);
        this.totalDiscSellOutGAP = new NegoptimNumber(2);
        this.totalCorSellInGAP = new NegoptimNumber(2);
        this.totalCorCOGSGAP = new NegoptimNumber(2);
        this.totalRegularGMGAP = new NegoptimNumber(2);
        this.totalGMAfterDiscGAP = new NegoptimNumber(2);
        this.totalDiffGAP = new NegoptimNumber(2);
        
        // initialization alpha list
        alphaList = new List<String> {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 
            'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Other', 'All'};
        sortFieldSave = SortField;
        sortFieldSaveSimulator = SortFieldSimulator;
        
        // alpha filter, use page parameter or set default to all
        if (apexpages.currentpage().getparameters().get('alpha') == null) {
            alphaFilter = 'All';
            alphaFilterSimulator = 'All';
        } else {
            alphaFilter = apexpages.currentpage().getparameters().get('alpha');
            alphaFilterSimulator = apexpages.currentpage().getparameters().get('alpha'); 
        }
        
        this.commercialPlanId = stdController.getId();        
        try {
            if(String.isNotBlank(commercialPlanId)) {
                init();
                String action = ApexPages.currentPage().getParameters().get('action');
                String updatePromoFact = ApexPages.currentPage().getParameters().get('updatePromoFact');
                if (action != null && action == 'Export') {
                    this.exportSimulatorExcel = true;
                    loadExcel();
                }
                if (updatePromoFact != null && Boolean.valueOf(updatePromoFact) == true) {
                    this.updatePromoFact = true;
                }
            }
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid commercial plan Id'));
        }
    }
    
    private void init(){
        // Check commercial plan field security
        String[] commercialPlanFields = new String [] {'Id', 'Name', getFieldName('Event_Code__c'), getFieldName('Start_Date__c'),
            getFieldName('End_Date__c'), getFieldName('Target_Elasticity__c'), getFieldName('Target_Constribution_rate__c'), getFieldName('Contribution_Validated__c')};
        
        String[] commercialPlanDetailFields = new String [] {'Id', 'Name', getFieldName('Commercial_Event__c'), getFieldName('Supplier__c'), getFieldName('Product__c')};
        
        // Check product field security
        String[] productFields = new String [] {'Id', 'Name', 'ProductCode', getFieldName('Category__c'), getFieldName('Brand__c')};
        
        // Check sellinFlow field security
        String[] sellinFlowFields = new String [] {'Id', 'Name', 'CurrencyIsoCode', getFieldName('Invoice_quantity__c')};

        if(checkAccessibility(Commercial_Plan__c.SObjectType, commercialPlanFields) && checkAccessibility(Commercial_Plan_Detail__c.SObjectType, commercialPlanDetailFields)){
            commercialPlan = [SELECT Id, Name, Status__c, Commercial_Animation_Plan_Parent__c, CurrencyIsoCode, Condition_Code__c, BU_Target__c, Event_Code__c, Start_Date__c, End_Date__c, Supplier__c, Supplier__r.Name, Supplier__r.Code__c,
                              Promo_Budget_Type__c, Target_Elasticity__c, Target_Constribution_rate__c, Regular_Nego_Discount__c, History_Reference__c, Reference_Year__c, Contribution_Validated__c,
                              (SELECT Id FROM Commercial_Animation_Plan__r),
                              (SELECT Id, Name, Commercial_Event__c, Nego_Scope__c, Supplier__c, Contract__c, Product__c,
                               Regular_Purchase_Price__c, Regular_Sales_Price__c, Promo_Purchase_Price__c, Promo_Sales_Price__c,
                               Contribution_Unit_Amount__c, Volume_Period_Reference__c, Volume_to_Reach__c, Prenego_envelop__c,
                               COGS_Init__c, Contribution_Unit_Amount_Init__c, Regular_Purchase_Price_Init__c, Regular_Sales_Price_Init__c,
                               Promo_Purchase_Price_Init__c, Promo_Sales_Price_Init__c, Volume_Reached__c, Statut__c
                               FROM Marketing_Event_Detail__r WHERE Product__c <> NULL)
                              FROM Commercial_Plan__c WHERE Id = :commercialPlanId];
            if (this.commercialPlan.Commercial_Animation_Plan_Parent__c != null
                || !this.commercialPlan.Commercial_Animation_Plan__r.isEmpty()) {
                    this.isCanceled = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Promo_Already_Canceled));
                    return;
                }
            if(commercialPlan.Supplier__c == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Supplier not found.'));
                return;
            }
            if(commercialPlan.Promo_Budget_Type__c != null){
                this.selectedSellin = commercialPlan.Promo_Budget_Type__c == 'Sell In' ? true : false;
            }
            if(commercialPlan.Target_Elasticity__c != null){
                this.elasticityRateCalc = commercialPlan.Target_Elasticity__c;
            }
            if(commercialPlan.Target_Constribution_rate__c != null){
                this.contributionRate = commercialPlan.Target_Constribution_rate__c;
            }
            if(commercialPlan.Regular_Nego_Discount__c != null){
                this.correctionRate = commercialPlan.Regular_Nego_Discount__c;
            }
            if(commercialPlan.Contribution_Validated__c != null){
                this.amount = commercialPlan.Contribution_Validated__c;
            }
            // fill list of history reference
            getHistoryReferenceOptions();
            if(commercialPlan.History_Reference__c != null){
                this.historyReference = commercialPlan.History_Reference__c;
            }
            // fill the history period start/end date
            fillHistoryPeriod();
        }
        
        // load selection list of product
        for(Commercial_Plan_Detail__c item : commercialPlan.Marketing_Event_Detail__r) {
            // check edit mode after execute PromoConditionSynchroBatch
            if(String.isNotBlank(item.Prenego_envelop__c)) {
                this.editSimulator = true;
            }
            // get PVP
            if(item.Promo_Purchase_Price__c != null && this.selectedSellin){
                this.pvpMap.put(item.Product__c, item.Promo_Purchase_Price__c);
            }
            else if(item.Promo_Sales_Price__c != null && !this.selectedSellin){
                this.pvpMap.put(item.Product__c, item.Promo_Sales_Price__c);
            }
            // get Discount Value
            if(item.Contribution_Unit_Amount__c != null){
                this.discountedValueMap.put(item.Product__c, item.Contribution_Unit_Amount__c);
            }
            // get sell Out Unit
            if(item.Volume_Period_Reference__c != null){
                this.sellOutUnitMap.put(item.Product__c, item.Volume_Period_Reference__c);
            }
            if(item.Product__c != null){
                this.simulatorIds.add(item.Product__c);
                this.commercialPlanDetailMap.put(item.Product__c, item);
            }
        }

        if(simulatorIds.size() > 0) {
            Integer index = 0;
            for(Product2 item :[SELECT Id FROM Product2 WHERE Id IN :simulatorIds ORDER BY Name]) {
                // Fill existing list product
                ProductWrapper wProduct = new ProductWrapper(item, true);
                wProduct.index = index;
                lastSelectedIdsMap.put(item.Id, index);
                index ++;
            }
        }
        
        if(!this.exportSimulatorExcel && checkAccessibility(Product2.SObjectType, productFields) && checkAccessibility(Sell_in_Flow__c.SObjectType, sellinFlowFields)){
            // fill list products
            BuildProductQuery();
            // fill list selection products
            BuildSimulatorQuery();
            // fill init simulator
            if(this.editSimulator) {
                BuildSimulatorInitQuery();
            }
        }
        this.sellInOrOut = this.selectedSellin == true ? 'sell_in' : 'sell_out';
    }
    
    private void loadExcel(){
        try {
            String sSelectedSellIn = ApexPages.currentPage().getParameters().get('selectedSellIn');
            String sAmount = ApexPages.currentPage().getParameters().get('amount');
            String sContributionRate = ApexPages.currentPage().getParameters().get('contributionRate');
            String sElasticityRateCalc = ApexPages.currentPage().getParameters().get('elasticityRateCalc');
            String sCorrectionRate = ApexPages.currentPage().getParameters().get('correctionRate');       
            this.structureLevelName = ApexPages.currentPage().getParameters().get('structureLevelName');
            this.brandName = ApexPages.currentPage().getParameters().get('brandName');
            this.negoScopeName = ApexPages.currentPage().getParameters().get('negoScopeName');
            String sInAssortment = ApexPages.currentPage().getParameters().get('inAssortment');
            this.searchName = ApexPages.currentPage().getParameters().get('searchName');            
            String simulators = ApexPages.currentPage().getParameters().get('simulatorIds');
            Set<String> simulatorsSet = (simulators == null) ? new Set<String>() : new Set<String>(simulators.split(','));
            
            this.selectedSellIn = Boolean.valueOf(sSelectedSellIn);
            this.amount = Decimal.valueOf(sAmount);
            this.contributionRate = Decimal.valueOf(sContributionRate);
            this.elasticityRateCalc = Decimal.valueOf(sElasticityRateCalc);
            this.correctionRate = Decimal.valueOf(sCorrectionRate);
            this.inAssortment = Boolean.valueOf(sInAssortment);            
            this.simulatorIds = (simulatorsSet == null) ? new Set<Id>() : new Set<Id>((List<Id>)new List<String>(simulatorsSet));
            
            String sPVPMap = ApexPages.currentPage().getParameters().get('pvpMap');
            if(String.isNotBlank(sPVPMap)){
                this.pvpMap = (Map<Id, Decimal>) JSON.deserializeStrict(sPVPMap, Map<Id, Decimal>.class);
            }
            String sSellOutUnitMap = ApexPages.currentPage().getParameters().get('sellOutUnitMap');
            if(String.isNotBlank(sSellOutUnitMap)){
                this.sellOutUnitMap = (Map<Id, Decimal>) JSON.deserializeStrict(sSellOutUnitMap, Map<Id, Decimal>.class);
            }
            
            // build list selection products
            BuildSimulatorQuery();
            // get list selection products
            getSimulatorList();            
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() + ' - ' + e.getLineNumber()));
        }
    }
            
    // Get Sell in Or Sell Out
    public List<SelectOption> getSellInOrOutOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('sell_in', 'Sell In'));
        options.add(new SelectOption('sell_out', 'Sell Out'));
        return options;
    }
    
    // Get history reference
    List<SelectOption> historyReferenceOptions {get; set;}
    public List<SelectOption> getHistoryReferenceOptions() {
        historyReferenceOptions = new List<SelectOption>();
        historyReferenceOptions.add(new SelectOption('', '--None--'));
        // Load History Reference picklist
        Schema.DescribeFieldResult historyReferencePickList = Commercial_Plan__c.History_Reference__c.getDescribe();
        for (Schema.PicklistEntry pv: historyReferencePickList.getPicklistValues()) {
            historyReferenceOptions.add(new SelectOption(pv.getValue(), pv.getLabel()));
            if (pv.isDefaultValue()) {
                //this.historyReference = pv.getValue();
            }
        }
        return historyReferenceOptions;
    }
    
    public PageReference changeStatus() {
        selectedSellIn = sellInOrOut == 'sell_in' ? true : false;
        calculateSimulatorValue();
        return null;
    }
    
    public PageReference changeHistoryPeriod() {
        this.simulatorList.clear();
        this.pvpMap.clear();
        this.sellOutUnitMap.clear();
        fillHistoryPeriod();
        // fill list selection products
        BuildSimulatorQuery();
        this.simulatorIsUpdated = false;
        return null;
    }
    
    private void fillHistoryPeriod() {
        Date startEventDate = commercialPlan.Start_Date__c;
        Date endEventDate = commercialPlan.End_Date__c;        
        Integer historyMonth, historyYear;
        if(String.isNotBlank(historyReference)) {
            if(historyReference == 'M-1_Y') {
                historyMonth = startEventDate.month() == 1 ? 12 : startEventDate.month() - 1;
                historyYear = startEventDate.month() == 1 ? startEventDate.year() - 1 : startEventDate.year();
                this.startHistoryPeriod = Date.newInstance(historyYear, historyMonth, 1);
                this.endHistoryPeriod = negoptimHelper.getLastDayOfMonth(historyYear, historyMonth);
            }
            else if(historyReference == 'M_Y') {
                historyMonth = startEventDate.month();
                historyYear = startEventDate.year();
                this.startHistoryPeriod = Date.newInstance(historyYear, historyMonth, 1);
                this.endHistoryPeriod = negoptimHelper.getLastDayOfMonth(historyYear, historyMonth);
            }
            else if(historyReference == 'M_Y-1') {
                historyMonth = startEventDate.month();
                historyYear = startEventDate.year() - 1;
                this.startHistoryPeriod = Date.newInstance(historyYear, historyMonth, 1);
                this.endHistoryPeriod = negoptimHelper.getLastDayOfMonth(historyYear, historyMonth);
            }
            else if(historyReference == 'Same_period_Y-1') {
                historyYear = startEventDate.year() - 1;
                this.startHistoryPeriod = Date.newInstance(historyYear, startEventDate.month(), startEventDate.day());
                this.endHistoryPeriod = Date.newInstance(historyYear, endEventDate.month(), endEventDate.day());
            }
        } else {
            this.startHistoryPeriod = null;
            this.endHistoryPeriod = null;
        }
    }
    
    // refresh lookup fields
    public void refresh(){
    }
    
    /*********************************** PRODUCT GRID ***************************************/
    
    // paging through the product list
    public ApexPages.StandardSetController StdSetControllerProduct {
        get {
            if(StdSetControllerProduct == null) {
                if(String.isNotBlank(queryProduct)){
                    try{
                        StdSetControllerProduct = new ApexPages.StandardSetController(Database.getQueryLocator(queryProduct));
                        if(recPerPage == null) recPerPage = 10;
                        // sets the number of records in each page set
                        StdSetControllerProduct.setPageSize(recPerPage);
                    } catch(Exception e) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() + ' - ' + e.getLineNumber()));
                    }
                }
                else{
                    StdSetControllerProduct = new ApexPages.StandardSetController(new List<Product2>());
                }
            }
            return StdSetControllerProduct;
        }
        set;
    }

    // Changes the size of pagination of product Grid
    public PageReference refreshPageSize() {
        processProductSelection();
        StdSetControllerProduct.setPageSize(recPerPage);
        return null;
    }
    
    // return an product list for the table
    public List<ProductWrapper> getProducts() {
        try{
            // get all records in product Table
            productList = new List<ProductWrapper>();
            if(StdSetControllerProduct != null){
                for (Product2 item : (List<Product2>)StdSetControllerProduct.getRecords()) {
                    ProductWrapper wProduct = new ProductWrapper(item, selectedProductsIds.contains(item.Id));
                    if(item.Supplier_PG_Mapping__r.size() > 0){
                        wProduct.inAssortment = true;                
                    }
                    productList.add(wProduct);
                }
                noOfRecords = StdSetControllerProduct.getResultSize();
            }
            return productList;
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() + ' - ' + e.getLineNumber()));
            return new List<ProductWrapper>();
        }
    }
    
    // Get NS PG based on supplier and negoScope.
    private void getNsPG() {
        this.NsPGSet = new Set<Id>();
        string query = 'SELECT Id, Sup_sup_NegoScope__c, Sup_PG__c, Sup_PG__r.Product__c, Sup_PG__r.Supplier__c ';
        query += 'FROM Sup_NS_PG__c WHERE Sup_PG__r.Supplier__c = \'' + this.commercialPlan.Supplier__c + '\' ';        
        if(String.isNotBlank(negoScopeLookup.value)){
            query += ' AND Sup_sup_NegoScope__c = \'' + negoScopeLookup.value +'\'';
        }
        else if(String.isNotBlank(negoScopeLookup.label)){
            query += ' AND (Sup_sup_NegoScope__r.Name LIKE \'%' + String.escapeSingleQuotes(negoScopeLookup.label) + '%\' OR Sup_sup_NegoScope__r.NS_Code__c LIKE \'%' + String.escapeSingleQuotes(negoScopeLookup.label) + '%\')';
        }
        List<Sup_NS_PG__c> NsPGList = Database.query(query);
        if(NsPGList != null && NsPGList.size() > 0){
            // Get NS PG based on supplier.
            for(Sup_NS_PG__c item : NsPGList) {
                if(!this.NsPGSet.contains(item.Sup_PG__r.Product__c)){
                    this.NsPGSet.add(item.Sup_PG__r.Product__c);
                }
            }
        }
    }
    
	// add/remove product from the selected id list
    private void processProductSelection() {
        for(ProductWrapper item : productList) {
            if (item.selected) {
                if(!selectedProductsIds.contains(item.product.Id)){
                    selectedProductsIds.add(item.product.Id);
                }
            }
            else {
                selectedProductsIds.remove(item.product.Id);
            }
        }
    }
	
    // returns the first page of records
    public void first() {
        processProductSelection();
        StdSetControllerProduct.first();
    }
    
    // returns the last page of records
    public void last() {
        processProductSelection();
        StdSetControllerProduct.last();
    }
    
    // returns the previous page of records
    public void previous() {
        processProductSelection();
        StdSetControllerProduct.previous();
    }
    
    // returns the next page of records
    public void next() {
        processProductSelection();
        StdSetControllerProduct.next();
    }
    
    // remove selected product and initialize counter
    public PageReference resetProduct(){
        productList.clear();
        selectedProductsIds.clear();
        searchName = '';
        saveSearchName = '';
        structureLevelLookup = new LookupValue(true);
        brandLookup = new LookupValue(true);
        negoScopeLookup = new LookupValue(false);
        structureLevelName = '';
        brandName = '';
        negoScopeName = '';
        inAssortment = false;
        isActiveProduct = false;
        alphaFilter = 'All';
        
        BuildProductQuery();
        return null;
    }
    
    // set search criteria fields and refresh product table
    public PageReference searchProduct() {
        saveSearchName = searchName;
        BuildProductQuery();
        return null;
	}
    
    // build query command for list selection change product
    public void BuildProductQuery() {
        if(commercialPlan.Supplier__c == null) return;
        processProductSelection();
        
        StdSetControllerProduct = null;
        String queryWhere = '';
        
        if (alphaFilter == null || alphaFilter.trim().length() == 0) {
            alphaFilter = 'All';
        }
        
        queryProduct = 'SELECT Id, Name, ProductCode, Category__c, Category__r.Parent_Element__c, Category__r.Parent_Element__r.Parent_Element__c, Brand__c, Brand__r.Name,';
        queryProduct += '(SELECT Id, Name, Brand__c, Department__c, Nego_Scope__c, Section__c, Supplier__c FROM Supplier_PG_Mapping__r WHERE Supplier__c = \'' + commercialPlan.Supplier__c + '\')';
        queryProduct += ' FROM Product2';
        
        if(alphaFilter == 'Other') {
            queryWhere = BuildWhere(queryWhere, '(' + String.escapeSingleQuotes(SortField) + ' < \'A\' OR ' + 
                                    String.escapeSingleQuotes(SortField) + ' > \'Z\') AND (NOT ' + 
                                    String.escapeSingleQuotes(SortField) + ' LIKE \'Z%\') ');
        } else if (alphaFilter != 'All') {
            queryWhere = BuildWhere(queryWhere, '(' + String.escapeSingleQuotes(SortField) + ' LIKE \'' + String.escapeSingleQuotes(alphaFilter) + '%\')' );
        }
        
        if (String.isNotBlank(saveSearchName)) {
            queryWhere = buildWhere(queryWhere, ' ((Name LIKE \'%' + String.escapeSingleQuotes(saveSearchName) + '%\') OR' +
                                    ' (ProductCode LIKE \'%' + String.escapeSingleQuotes(saveSearchName) + '%\') OR' +
                                    ' (Brand__r.Name LIKE \'%' + String.escapeSingleQuotes(saveSearchName) + '%\') OR' +
                                    ' (Category__r.Name LIKE \'%' + String.escapeSingleQuotes(saveSearchName) + '%\') OR' +
                                    ' (Category__r.Parent_Element__r.Name LIKE \'%' + String.escapeSingleQuotes(saveSearchName) + '%\') OR' +
                                    ' (Category__r.Parent_Element__r.Parent_Element__r.Name LIKE \'%' + String.escapeSingleQuotes(saveSearchName) + '%\'))');
        }
        
        if(isActiveProduct){
            queryWhere = buildWhere(queryWhere, ' IsActive = ' + isActiveProduct +'');
        }
        
        if(String.isNotBlank(brandLookup.value) || String.isNotBlank(brandLookup.label)) {
            if(String.isNotBlank(brandLookup.value)){
                List<String> selectedBrandsIds = String.escapeSingleQuotes(brandLookup.value).split(',');
                queryWhere = BuildWhere(queryWhere, 'Brand__c IN (\'' + String.join(selectedBrandsIds, '\',\'') +'\')');
            }
            else if(String.isNotBlank(brandLookup.label)){
                queryWhere = BuildWhere(queryWhere, '(Brand__r.Name LIKE \'%' + String.escapeSingleQuotes(brandLookup.label) + '%\' OR Brand__r.Brand_code__c LIKE \'%' + String.escapeSingleQuotes(brandLookup.label) + '%\')');
            }
        }
        
        if(String.isNotBlank(structureLevelLookup.value) || String.isNotBlank(structureLevelLookup.label)) {
            if(String.isNotBlank(structureLevelLookup.value)){
                List<String> selectedStructureLevelIds = String.escapeSingleQuotes(structureLevelLookup.value).split(',');
                queryWhere = BuildWhere(queryWhere, '(Category__r.Parent_Element__c IN (\'' + String.join(selectedStructureLevelIds, '\',\'') +'\') OR Category__c IN (\'' + String.join(selectedStructureLevelIds, '\',\'') +'\'))');
            }
            else if(String.isNotBlank(structureLevelLookup.label)){
                queryWhere = BuildWhere(queryWhere, '(Category__r.Parent_Element__r.Name LIKE \'%' + String.escapeSingleQuotes(structureLevelLookup.label) +'%\' OR Category__r.Parent_Element__r.Elt_Code__c LIKE \'%' + String.escapeSingleQuotes(structureLevelLookup.label) + '%\' OR ' +
                                        ' Category__r.Name LIKE \'%' + String.escapeSingleQuotes(structureLevelLookup.label) + '%\' OR Category__r.Elt_Code__c LIKE \'%' + String.escapeSingleQuotes(structureLevelLookup.label) + '%\')');
            }
        }
        
        if(inAssortment) {
            queryWhere = buildWhere(queryWhere, 'Id IN (SELECT Product__c FROM Supplier_PG_Mapping__c WHERE Supplier__c = \'' + commercialPlan.Supplier__c + '\')');
        }
        
        // search the product linked to NS
        if(String.isNotBlank(negoScopeLookup.value) || String.isNotBlank(negoScopeLookup.label)) {
            getNsPG();
            queryWhere = BuildWhere(queryWhere, 'Id IN (\'' + String.join(new List<Id>(this.NsPGSet), '\',\'') +'\')');
        }
        
        // remove all product dragged to simulator grid OR if already exist commercial plan detail for products
        if(simulatorIds.size() > 0) {
            queryWhere = BuildWhere(queryWhere, 'Id NOT IN (\'' + String.join(new List<Id>(simulatorIds), '\',\'') +'\')');
        }
        
        queryProduct += queryWhere;
        queryProduct += ' ORDER BY ' + String.escapeSingleQuotes(SortField) + ' ' + String.escapeSingleQuotes(SortDirection) + ' LIMIT 5000';
    }
    
    // build soql string for where criteria 
    public String BuildWhere(String QW, String Cond) {
        if (QW == '') {
            return ' WHERE ' + Cond;
        } else {
            return QW + ' AND ' + Cond;
        }
    }
    
    // return sort direction. Default ascending(asc)
    public String SortDirection {
        get { if (SortDirection == null) {  SortDirection = 'asc'; } return SortDirection; }
        set;
    }
    
    // return sort by field. Default to Name
    public String SortField {
        get { if (SortField == null) {SortField = 'Name'; } return SortField; }
        set; 
    }
    
    // toggles the sorting of query from asc<-->desc
    public void SortToggle() {
        SortDirection = SortDirection.equals('asc') ? 'desc NULLS LAST' : 'asc';
        // reset alpha filter and sort sequence when sorted field is changed
        if (sortFieldSave != SortField) {
            SortDirection = 'asc';
            alphaFilter = 'All';
            sortFieldSave = SortField;
        }
        // run the query again
        BuildProductQuery();
    }
    
    /************************************** SIMULATOR INIT GRID ********************************/
    
    // paging through the Simulator Init Grid
    public ApexPages.StandardSetController StdSetControllerSimulatorInit {
        get {
            if(StdSetControllerSimulatorInit == null) {
                if(String.isNotBlank(querySimulatorInit)){
                    allSimulatorInitRecords = Database.query(querySimulatorInit);
                    StdSetControllerSimulatorInit = new ApexPages.StandardSetController(Database.getQueryLocator(querySimulatorInit));
                    // sets the number of records in each page set
                    StdSetControllerSimulatorInit.setPageSize(recPerPageSimulatorInit);
                }
                else{
                    StdSetControllerSimulatorInit = new ApexPages.StandardSetController(new List<Product2>());
                }
            }
            return StdSetControllerSimulatorInit;
        }
        set;
    }
        
    // Changes the size of pagination of Simulator Init Grid
    public PageReference refreshPageSizeSimulatorInit() {
        calculateSimulatorValue();
        recPerPageSimulator = recPerPageSimulatorInit;
        StdSetControllerSimulatorInit.setPageSize(recPerPageSimulatorInit);
        StdSetControllerSimulator.setPageSize(recPerPageSimulatorInit);
        return null;
    }
    
    // build query command for list Init simulator
    public void BuildSimulatorInitQuery() {
        if(commercialPlan.Supplier__c == null) return;        
        StdSetControllerSimulatorInit = null;
        String queryWhere = '';
        
        if (alphaFilterSimulator == null || alphaFilterSimulator.trim().length() == 0) {
            alphaFilterSimulator = 'All';
        }        
        querySimulatorInit = 'SELECT Id, Name, ProductCode FROM Product2 ';

        if (alphaFilterSimulator == 'Other') {
            queryWhere = BuildWhere(queryWhere, '(' + String.escapeSingleQuotes(SortFieldSimulator) + ' < \'A\' OR ' + 
                                    String.escapeSingleQuotes(SortFieldSimulator) + ' > \'Z\') AND (NOT ' + 
                                    String.escapeSingleQuotes(SortFieldSimulator) + ' LIKE \'Z%\') ');
        } else if (alphaFilterSimulator != 'All') {
            queryWhere = BuildWhere(queryWhere, '(' + String.escapeSingleQuotes(SortFieldSimulator) + ' LIKE \'' + String.escapeSingleQuotes(alphaFilterSimulator) + '%\')' );
        }
        queryWhere = BuildWhere(queryWhere, ' Id IN (\'' + String.join(new List<Id>(this.commercialPlanDetailMap.keySet()), '\',\'') +'\')');
        querySimulatorInit += queryWhere;        
        
        if(String.isNotBlank(SortFieldSimulator) && String.isNotBlank(SortDirectionSimulator)) {
            querySimulatorInit += ' ORDER BY ' + String.escapeSingleQuotes(SortFieldSimulator) + ' ' + String.escapeSingleQuotes(SortDirectionSimulator);
        }
        querySimulatorInit += ' LIMIT ' + this.commercialPlanDetailMap.size();
    }
    
    // return simulator Init list
    public List<ProductWrapper> getSimulatorInitList() {
        List<ProductWrapper> simulatorInitList = new List<ProductWrapper>();
        List<Product2> productList = (List<Product2>)StdSetControllerSimulatorInit.getRecords();
        Set<Id> productIds = (new Map<Id, Product2>(productList)).keySet();
        if(productIds.size() > 0) {
            calculateSellinUnitAndPrice(productIds);
        }
        for (Product2 item : productList) {
            ProductWrapper wProduct = fillInitProductWrapper(item);
            simulatorInitList.add(wProduct);
        }
        // fill all records for calculate total values
        fillAllInitSimulators();
        
        for(ProductWrapper item : simulatorInitList) {
            item.marketShare.value = totalSellinPriceInit.value != 0 ? item.sellinPrice.value/totalSellinPriceInit.value * 100 : 0;            
            item.discSellOut.value = item.value.value - item.discountedValue.value;
            item.corSellIn.value = item.units.value * (item.sellinPrice.value * (1 - (this.correctionRate/100)));
            item.corCOGS.value = item.units.value * item.COGS.value;
            item.regularGM.value = item.corSellIn.value != 0 ? (1 - (item.corCOGS.value/item.corSellIn.value)) * 100 : 0;
            item.GMAfterDisc.value = (item.corSellIn.value - item.discountedValue.value) != 0 ? (1 - (item.corCOGS.value/(item.corSellIn.value - item.discountedValue.value))) * 100 : 0;
            item.Diff.value = (item.GMAfterDisc.value - item.regularGM.value);            
        }
        noOfRecordsInit = StdSetControllerSimulatorInit.getResultSize();
        simulatorInitList.sort();
        return simulatorInitList;
    }
    
    private ProductWrapper fillInitProductWrapper(Product2 item) {
        ProductWrapper wProduct = new ProductWrapper(item, false);
        // get Init promo detail
        Commercial_Plan_Detail__c promoDetail = this.commercialPlanDetailMap.get(item.Id);
        wProduct.sellinPrice.value = this.selectedSellin && promoDetail.Regular_Purchase_Price_Init__c != null ? promoDetail.Regular_Purchase_Price_Init__c :
                                    !this.selectedSellin && promoDetail.Regular_Sales_Price_Init__c != null ? promoDetail.Regular_Sales_Price_Init__c : 0;
        
        wProduct.COGS.value = promoDetail.COGS_Init__c != null ? promoDetail.COGS_Init__c : 0;
        wProduct.sellinUnit.value = sellinUnitMap.get(item.Id) != null ? sellinUnitMap.get(item.Id) : 0;
        
        wProduct.grossMargin.value = wProduct.sellinPrice.value != 0 ? ((wProduct.sellinPrice.value - wProduct.COGS.value)/wProduct.sellinPrice.value) * 100 : 0;
        wProduct.sellinValue.value = wProduct.sellinUnit.value * wProduct.sellinPrice.value;
        
        wProduct.PVP.value = this.selectedSellin && promoDetail.Promo_Purchase_Price_Init__c != null ? promoDetail.Promo_Purchase_Price_Init__c : 
                            !this.selectedSellin && promoDetail.Promo_Sales_Price_Init__c != null ? promoDetail.Promo_Sales_Price_Init__c : 0;
        wProduct.sellOutUnit.value = promoDetail.Volume_Reached__c != null ? promoDetail.Volume_Reached__c : 0;
        
        wProduct.sellOutValue.value = wProduct.sellOutUnit.value * wProduct.PVP.value;
        wProduct.units.value = (1 + (this.elasticityRateCalc/100)) * wProduct.sellOutUnit.value;
        wProduct.value.value = wProduct.units.value * wProduct.PVP.value;
        wProduct.discountedValue.value = promoDetail.Contribution_Unit_Amount_Init__c != null ? promoDetail.Contribution_Unit_Amount_Init__c : 0;
        return wProduct;
    }
    
    public List<ProductWrapper> fillAllInitSimulators() {
        simulatorInitRecords = new List<ProductWrapper>();
        totalSellinPriceInit.value = 0; totalSellinUnitInit.value = 0; totalSellinValueInit.value = 0; totalMarketShareInit.value = 0; totalSellOutUnitInit.value = 0;
        totalSellOutValueInit.value = 0; totalUnitsInit.value = 0; totalValueInit.value = 0; totalDiscountedValueInit.value = 0; totalDiscSellOutInit.value = 0;
        totalCorSellInInit.value = 0; totalCorCOGSInit.value = 0; totalRegularGMInit.value = 0; totalGMAfterDiscInit.value = 0; totalDiffInit.value = 0;
        for(Product2 item : allSimulatorInitRecords) {
            ProductWrapper wProduct = fillInitProductWrapper(item);
            calculateInitTotal(wProduct);
            simulatorInitRecords.add(wProduct);
        }
        for(ProductWrapper item : simulatorInitRecords) {
            item.marketShare.value = totalSellinPriceInit.value != 0 ? item.sellinPrice.value/totalSellinPriceInit.value * 100 : 0;
            
            item.discSellOut.value = item.value.value - item.discountedValue.value;
            item.corSellIn.value = item.units.value * (item.sellinPrice.value * (1 - (this.correctionRate/100)));
            item.corCOGS.value = item.units.value * item.COGS.value;
            item.regularGM.value = item.corSellIn.value != 0 ? (1 - (item.corCOGS.value/item.corSellIn.value)) * 100 : 0;
            item.GMAfterDisc.value = (item.corSellIn.value - item.discountedValue.value) != 0 ? (1 - (item.corCOGS.value/(item.corSellIn.value - item.discountedValue.value))) * 100 : 0;
            item.Diff.value = (item.GMAfterDisc.value - item.regularGM.value);
            
            totalMarketShareInit.value += item.marketShare.value;
            totalDiscountedValueInit.value += item.discountedValue.value;
            totalDiscSellOutInit.value += item.discSellOut.value;
            totalCorSellInInit.value += item.corSellIn.value;
            totalCorCOGSInit.value += item.corCOGS.value;
            totalRegularGMInit.value += item.regularGM.value;
            totalGMAfterDiscInit.value += item.GMAfterDisc.value;
            totalDiffInit.value += item.Diff.value;
        }
        simulatorInitRecords.sort();
        return simulatorInitRecords;
    }
    
    private void calculateInitTotal(ProductWrapper wProduct) {
        totalSellinPriceInit.value += wProduct.sellinPrice.value;
        totalSellinUnitInit.value += wProduct.sellinUnit.value;
        totalSellinValueInit.value += wProduct.sellinValue.value;
        totalSellOutUnitInit.value += wProduct.sellOutUnit.value;
        totalSellOutValueInit.value += wProduct.sellOutValue.value;
        totalUnitsInit.value += wProduct.units.value;
        totalValueInit.value += wProduct.value.value;
    }
        
    /************************************** SIMULATOR FACT GRID **************************************/

    // paging through the Simulator Grid
    public ApexPages.StandardSetController StdSetControllerSimulator {
        get {
            if(StdSetControllerSimulator == null) {
                if(String.isNotBlank(querySelectedProduct)){
                    allSimulatorRecords = Database.query(querySelectedProduct);
                    StdSetControllerSimulator = new ApexPages.StandardSetController(Database.getQueryLocator(querySelectedProduct));
                    // sets the number of records in each page set
                    StdSetControllerSimulator.setPageSize(recPerPageSimulator);
                }
                else{
                    StdSetControllerSimulator = new ApexPages.StandardSetController(new List<Product2>());
                }
            }
            return StdSetControllerSimulator;
        }
        set;
    }
    
    // Changes the size of pagination of Simulator Fact Grid
    public PageReference refreshPageSizeSimulator() {
        calculateSimulatorValue();
        recPerPageSimulatorInit = recPerPageSimulator;
        StdSetControllerSimulatorInit.setPageSize(recPerPageSimulator);
        StdSetControllerSimulator.setPageSize(recPerPageSimulator);
        return null;
    }

    // return simulator list
    public List<ProductWrapper> getSimulatorList() {
        simulatorList = new List<ProductWrapper>();
        try {
            List<Product2> productList = (List<Product2>)StdSetControllerSimulator.getRecords();
            Set<Id> productIds = (new Map<Id, Product2>(productList)).keySet();
            if(productIds.size() > 0) {
                calculateSellinUnitAndPrice(productIds);
            }
            for (Product2 item : productList) {
                ProductWrapper wProduct = fillProductWrapper(item);
                if(lastSelectedIdsMap.containsKey(item.Id)){
                    wProduct.index = lastSelectedIdsMap.get(item.Id);
                }
                simulatorList.add(wProduct);
            }
            // fill all records for calculate total values
            fillAllSimulators();
            
            for(ProductWrapper item : simulatorList) {
                item.marketShare.value = totalSellinPrice.value != 0 ? item.sellinPrice.value/totalSellinPrice.value * 100 : 0;
                item.discountedValue.value = totalValue.value != 0 ? (this.amount + (this.contributionRate/100) * totalValue.value) * item.value.value/totalValue.value : 0;
                
                item.discSellOut.value = item.value.value - item.discountedValue.value;
                item.corSellIn.value = item.units.value * (item.sellinPrice.value * (1 - (this.correctionRate/100)));
                item.corCOGS.value = item.units.value * item.COGS.value;
                item.regularGM.value = item.corSellIn.value != 0 ? (1 - (item.corCOGS.value/item.corSellIn.value)) * 100 : 0;
                item.GMAfterDisc.value = (item.corSellIn.value - item.discountedValue.value) != 0 ? (1 - (item.corCOGS.value/(item.corSellIn.value - item.discountedValue.value))) * 100 : 0;
                item.Diff.value = (item.GMAfterDisc.value - item.regularGM.value);            
            }
            noOfRecordsFact = StdSetControllerSimulator.getResultSize();
            simulatorList.sort();
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_Error_Occurred));
        }
        return simulatorList;
    }
    
    private ProductWrapper fillProductWrapper(Product2 item) {
        ProductWrapper wProduct = new ProductWrapper(item, false);
        wProduct.sellinPrice.value = sellinPriceMap.get(item.Id) != null ? sellinPriceMap.get(item.Id) : 0;
        wProduct.COGS.value = item.Last_Unit_Cost__c != null ? item.Last_Unit_Cost__c : 0;
        wProduct.sellinUnit.value = sellinUnitMap.get(item.Id) != null ? sellinUnitMap.get(item.Id) : 0;
        
        wProduct.grossMargin.value = wProduct.sellinPrice.value != 0 ? ((wProduct.sellinPrice.value - wProduct.COGS.value)/wProduct.sellinPrice.value) * 100 : 0;
        wProduct.sellinValue.value = wProduct.sellinUnit.value * wProduct.sellinPrice.value;        
        wProduct.PVP.value = wProduct.sellinPrice.value;
        wProduct.sellOutUnit.value = wProduct.sellinUnit.value;
        // change pvp value
        if(pvpMap.containsKey(item.Id)) {
            wProduct.PVP.value = pvpMap.get(item.Id);
        }
        // change sellOutUnit value
        if(sellOutUnitMap.containsKey(item.Id)) {
            wProduct.sellOutUnit.value = sellOutUnitMap.get(item.Id);
        }
        wProduct.sellOutValue.value = wProduct.sellOutUnit.value * wProduct.PVP.value;
        wProduct.units.value = (1 + (this.elasticityRateCalc/100)) * wProduct.sellOutUnit.value;
        wProduct.value.value = wProduct.units.value * wProduct.PVP.value;
        return wProduct;
    }
    
    public List<ProductWrapper> fillAllSimulators() {
        simulatorRecords = new List<ProductWrapper>();
        totalSellinPrice.value = 0; totalSellinUnit.value = 0; totalSellinValue.value = 0; totalMarketShare.value = 0; totalSellOutUnit.value = 0;
        totalSellOutValue.value = 0; totalUnits.value = 0; totalValue.value = 0; totalDiscountedValue.value = 0; totalDiscSellOut.value = 0;
        totalCorSellIn.value = 0; totalCorCOGS.value = 0; totalRegularGM.value = 0; totalGMAfterDisc.value = 0; totalDiff.value = 0;
        for(Product2 item : allSimulatorRecords) {
            ProductWrapper wProduct = fillProductWrapper(item);
            if(lastSelectedIdsMap.containsKey(item.Id)){
                wProduct.index = lastSelectedIdsMap.get(item.Id);
            }
            calculateTotal(wProduct);
            simulatorRecords.add(wProduct);
        }
        for(ProductWrapper item : simulatorRecords) {
            item.marketShare.value = totalSellinPrice.value != 0 ? item.sellinPrice.value/totalSellinPrice.value * 100 : 0;
            item.discountedValue.value = totalValue.value != 0 ? (this.amount + (this.contributionRate/100) * totalValue.value) * item.value.value/totalValue.value : 0;

            item.discSellOut.value = item.value.value - item.discountedValue.value;
            item.corSellIn.value = item.units.value * (item.sellinPrice.value * (1 - (this.correctionRate/100)));
            item.corCOGS.value = item.units.value * item.COGS.value;
            item.regularGM.value = item.corSellIn.value != 0 ? (1 - (item.corCOGS.value/item.corSellIn.value)) * 100 : 0;
            item.GMAfterDisc.value = (item.corSellIn.value - item.discountedValue.value) != 0 ? (1 - (item.corCOGS.value/(item.corSellIn.value - item.discountedValue.value))) * 100 : 0;
            item.Diff.value = (item.GMAfterDisc.value - item.regularGM.value);
            
            totalMarketShare.value += item.marketShare.value;
            totalDiscountedValue.value += item.discountedValue.value;
            totalDiscSellOut.value += item.discSellOut.value;
            totalCorSellIn.value += item.corSellIn.value;
            totalCorCOGS.value += item.corCOGS.value;
            totalRegularGM.value += item.regularGM.value;
            totalGMAfterDisc.value += item.GMAfterDisc.value;
            totalDiff.value += item.Diff.value;
            // fill product in map for save
            ProductUpdatedWrapper updatedProduct = fillUpdatedProductWrapper(item);
            selectedProductMap.put(updatedProduct.productId, updatedProduct);
        }
        simulatorRecords.sort();
        return simulatorRecords;
    }
    
    private ProductUpdatedWrapper fillUpdatedProductWrapper(ProductWrapper item) {
        ProductUpdatedWrapper updatedProduct = new ProductUpdatedWrapper(item.product.Id);
        updatedProduct.COGS = item.COGS.value;
        updatedProduct.sellinPrice = item.sellinPrice.value;
        updatedProduct.PVP = item.PVP.value;
        updatedProduct.discountedValue = item.discountedValue.value;
        updatedProduct.sellOutUnit = item.sellOutUnit.value;
        return updatedProduct;
    }
    
    private void calculateTotal(ProductWrapper wProduct) {
        totalSellinPrice.value += wProduct.sellinPrice.value;
        totalSellinUnit.value += wProduct.sellinUnit.value;
        totalSellinValue.value += wProduct.sellinValue.value;
        totalSellOutUnit.value += wProduct.sellOutUnit.value;
        totalSellOutValue.value += wProduct.sellOutValue.value;
        totalUnits.value += wProduct.units.value;
        totalValue.value += wProduct.value.value;
    }
    
    Map<Id, Decimal> sellinUnitMap = new Map<Id, Decimal>();
    Map<Id, Decimal> sellinPriceMap = new Map<Id, Decimal>();    
    private void calculateSellinUnitAndPrice(Set<Id> productIds) {
        sellinUnitMap = new Map<Id, Decimal>();
        sellinPriceMap = new Map<Id, Decimal>();
        if(!productIds.isEmpty() &&  this.commercialPlan.Supplier__c != null && this.startHistoryPeriod != null && this.endHistoryPeriod != null) {
            // Get sell in flow grouping by supplier and products selected
            for(AggregateResult aggr : [SELECT Supplier__c, Mvt_Purch_Product__c, SUM(Invoice_quantity__c) quantity
                                        FROM Sell_in_Flow__c
                                        WHERE Supplier__c = :this.commercialPlan.Supplier__c AND Mvt_Purch_Product__c IN :productIds
                                        AND Invoice_Date__c >= :this.startHistoryPeriod AND Invoice_Date__c <= :this.endHistoryPeriod
                                        AND Invoice_quantity__c <> null
                                        GROUP BY Supplier__c, Mvt_Purch_Product__c])
            {
                Id productId = (Id)aggr.get('Mvt_Purch_Product__c');
                decimal quantity = Decimal.valueOf(String.valueOf(aggr.get('quantity')));
                if(!sellinUnitMap.containsKey(productId)){
                    sellinUnitMap.put(productId, quantity);
                }
            }
            
            // Get pg supplier
            for(Supplier_PG_Mapping__c item :[SELECT Id, Product__c, Supplier__c, Last_Net_Price__c FROM Supplier_PG_Mapping__c 
                                              WHERE Product__c IN :productIds AND Supplier__c = :this.commercialPlan.Supplier__c])
            {
                if(!sellinPriceMap.containsKey(item.Product__c)) {
                    sellinPriceMap.put(item.Product__c, item.Last_Net_Price__c);
                }
            }
        }
    }
    
    // build query command for list selection change products
    public void BuildSimulatorQuery() {
        if(commercialPlan.Supplier__c == null) return;
        calculateSimulatorValue();
        
        StdSetControllerSimulator = null;
        String queryWhere = '';
                
        if (alphaFilterSimulator == null || alphaFilterSimulator.trim().length() == 0) {
            alphaFilterSimulator = 'All';
        }
        
        querySelectedProduct = 'SELECT Id, Name, ProductCode, Category__c, Category__r.Parent_Element__c, Category__r.Parent_Element__r.Parent_Element__c, Brand__c, Brand__r.Name, Last_Unit_Cost__c ';
        querySelectedProduct += ' FROM Product2';

        if (alphaFilterSimulator == 'Other') {
            queryWhere = BuildWhere(queryWhere, '(' + String.escapeSingleQuotes(SortFieldSimulator) + ' < \'A\' OR ' + 
                                    String.escapeSingleQuotes(SortFieldSimulator) + ' > \'Z\') AND (NOT ' + 
                                    String.escapeSingleQuotes(SortFieldSimulator) + ' LIKE \'Z%\') ');
        } else if (alphaFilterSimulator != 'All') {
            queryWhere = BuildWhere(queryWhere, '(' + String.escapeSingleQuotes(SortFieldSimulator) + ' LIKE \'' + String.escapeSingleQuotes(alphaFilterSimulator) + '%\')' );
        }
        
        queryWhere = BuildWhere(queryWhere, 'Id IN (\'' + String.join(new List<Id>(simulatorIds), '\',\'') +'\')');
        
        querySelectedProduct += queryWhere;
        if(String.isNotBlank(SortFieldSimulator) && String.isNotBlank(SortDirectionSimulator)) {
            querySelectedProduct += ' ORDER BY ' + String.escapeSingleQuotes(SortFieldSimulator) + ' ' + String.escapeSingleQuotes(SortDirectionSimulator);
        }
        querySelectedProduct += ' LIMIT ' + (5000 - this.commercialPlanDetailMap.size());
    }
    
    public void SearchSimulatorsByAlphaFilter() {
        BuildSimulatorInitQuery();
        BuildSimulatorQuery();
    }
    
    // return sort direction. Default ascending(asc)
    public String SortDirectionSimulator {
        get { if (SortDirectionSimulator == null) {  SortDirectionSimulator = 'asc'; } return SortDirectionSimulator; }
        set;
    }
    
    // return sort by field. Default to Name
    public String SortFieldSimulator {
        get {
            if(SortFieldSimulator == null) {SortFieldSimulator = 'Name';}
            return SortFieldSimulator;
        }
        set;
    }
    
    // toggles the sorting of query from asc<-->desc
    public void SortToggleSimulator() {
        // clear comparable
        lastSelectedIdsMap.clear();
        
        SortDirectionSimulator = SortDirectionSimulator.equals('asc') ? 'desc NULLS LAST' : 'asc';
        // reset alpha filter and sort sequence when sorted field is changed
        if (sortFieldSaveSimulator != SortFieldSimulator && String.isNotBlank(SortFieldSimulator)) {
            SortDirectionSimulator = 'asc';
            alphaFilterSimulator = 'All';
            sortFieldSaveSimulator = SortFieldSimulator;
        }
        // run the query again
        BuildSimulatorQuery();
        BuildSimulatorInitQuery();
    }

    // returns the first page of simulators
    public void firstSimulatorPage() {
        calculateSimulatorValue();
        if(StdSetControllerSimulator.getHasPrevious()) StdSetControllerSimulator.first();
        if(StdSetControllerSimulatorInit.getHasPrevious()) StdSetControllerSimulatorInit.first();
    }
    
    // returns the previous page of simulators
    public void previousSimulatorPage() {
        calculateSimulatorValue();
        if(StdSetControllerSimulator.getHasPrevious()) StdSetControllerSimulator.previous();
        if(StdSetControllerSimulatorInit.getHasPrevious()) StdSetControllerSimulatorInit.previous();
    }
    
    // returns the next page of simulators
    public void nextSimulatorPage() {
        calculateSimulatorValue();
        if(StdSetControllerSimulator.getHasNext()) StdSetControllerSimulator.next();
        if(StdSetControllerSimulatorInit.getHasNext()) StdSetControllerSimulatorInit.next();
    }
    
    // returns the last page of simulators
    public void lastSimulatorPage() {
        calculateSimulatorValue();
        if(StdSetControllerSimulator.getHasNext()) StdSetControllerSimulator.last();
        if(StdSetControllerSimulatorInit.getHasNext()) StdSetControllerSimulatorInit.last();
    }
        
    /****************************************************************************************/
    
    // set Elasticity rate, Correction rate, Contribution rate
    public PageReference calculateSimulatorValue() {
        if(this.importFile) return null;
        if(!simulatorList.isEmpty()) {
            for(ProductWrapper item : this.simulatorList) {
                Decimal oldPVP = this.pvpMap.get(item.product.Id) != null ? this.pvpMap.get(item.product.Id) : 0;
                Decimal oldSellOutUnit = this.sellOutUnitMap.get(item.product.Id) != null ? this.sellOutUnitMap.get(item.product.Id) : 0;
                if(oldPVP != item.PVP.value || oldSellOutUnit != item.sellOutUnit.value) this.simulatorIsUpdated = true;
                this.pvpMap.put(item.product.Id, item.PVP.value);
                this.sellOutUnitMap.put(item.product.Id, item.sellOutUnit.value);
            }
        }
        return null;
    }
    
    // Drag product to the Simulator grid list
    public PageReference dragProductSelected() {
        try {
            processProductSelection();
            updateSimulator();
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_Error_Occurred));
        }
        return null;
    }
    
    public void updateSimulator() {
        if(selectedProductsIds.size() > 0){
            // update last index
            if(lastSelectedIdsMap.size() > 0){
                for(Id productId : lastSelectedIdsMap.keySet()){
                    Integer pIndex = lastSelectedIdsMap.get(productId);
                    lastSelectedIdsMap.put(productId, pIndex + selectedProductsIds.size());
                }
            }
            Integer index = 0;
            for(Id productId : selectedProductsIds){
                if(!simulatorIds.contains(productId)){
                    simulatorIds.add(productId);
                }
                lastSelectedIdsMap.put(productId, index);
                index++;
            }
            productList.clear();
            selectedProductsIds.clear();
            BuildProductQuery();
            BuildSimulatorQuery();
        }
    }
    
    // delete product from simulator 
    public void deleteProductSimulator() {
        Id productId = system.CurrentPageReference().getParameters().get('productId');
        simulatorIds.remove(productId);
        lastSelectedIdsMap.remove(productId);
        selectedProductsIds.add(productId);
        BuildProductQuery();
        BuildSimulatorQuery();
        // check if product already exist in promo detail
        Commercial_Plan_Detail__c commercialPlanDetail = this.commercialPlanDetailMap.get(productId);
        if(this.pvpMap.containsKey(productId)) {
            if(commercialPlanDetail != null) {
                if(commercialPlanDetail.Promo_Purchase_Price__c != null && this.selectedSellin) {
                    this.pvpMap.put(productId, commercialPlanDetail.Promo_Purchase_Price__c);
                } else if(commercialPlanDetail.Promo_Sales_Price__c != null && !this.selectedSellin) {
                    this.pvpMap.put(productId, commercialPlanDetail.Promo_Sales_Price__c);
                }
            } else {
                this.pvpMap.remove(productId);
            }
        }
        if(this.sellOutUnitMap.containsKey(productId)) {
            if(commercialPlanDetail != null) {
                this.sellOutUnitMap.put(productId, commercialPlanDetail.Volume_Period_Reference__c);
            } else {
                this.sellOutUnitMap.remove(productId);
            }
        }
    }
      	
    // Show popup method.
    public void showPopup() {
        this.displayImportPopup = true;
    }
    
    // Close popup method.
    public void closePopup() {
    	this.displayImportPopup = false;
    }
    
    // Simulator Grid: Import csv products with columns(Product Name, Product Code, PVO, Sell Out Units) from excel file.
    public PageReference import() {
        this.importFile = true;
        String fileName = Apexpages.currentPage().getParameters().get('fileName');
        String fileContent = Apexpages.currentPage().getParameters().get('fileContent');
        this.displayImportPopup = false;
        productList = new List<ProductWrapper>();
        try {
            if (fileName == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'ERROR-001: I/O EXCEPTION. No file chosen!'));
            }
            else {
                if (fileName.endsWith('.csv')) {
                    String contentData = EncodingUtil.Base64Decode(fileContent).toString();                    
                    // Parsing CSV file.
                    List<List<String>> records = NegoptimHelper.parseCSV(contentData, true);
                    Set<String> productCodes = new Set<String>();
                    Integer lineIndex = 1;
                    try {
                        Boolean errorLine = false;
                        String errorMsgLine = 'Issue on the column number. Please, check the input file. Line : ';
                        for (List<String> record : records) {
                            lineIndex++;
                            if (record.size() != 4) {
                                errorMsgLine += String.valueOf(lineIndex) + ', ';
                                errorLine = true;
                                continue;
                            }
                            ProductWrapper wLine = new ProductWrapper(null, true);
                            wLine.index = lineIndex;
                            wLine.productCode = record[0];
                            wLine.productName = record[1];
                            wLine.PVP.value = NegoptimHelper.getDecimalValue(record[2]) != null ? NegoptimHelper.getDecimalValue(record[2]) : 0;
                            wLine.sellOutUnit.value = NegoptimHelper.getDecimalValue(record[3]) != null ? NegoptimHelper.getDecimalValue(record[3]) : 0;
                            
                            for (Integer i = 0 ; i <= 2 ; i++) {
                                if (record.size() == i) {
                                    for (Integer j = 1 ; j <= 3 - i ; j++) {
                                        record.add('');
                                    }
                                }
                            }
                            productList.add(wLine);
                            if (!productCodes.contains(wLine.productCode)) {
                                productCodes.add(wLine.productCode);
                            }
                        }
                        // get products
                        List<Product2> products = [SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode IN :productCodes];
                        Map<String, Product2> productMap = new Map<String, Product2>();
                        for(Product2 p : products) {
                            productMap.put(p.ProductCode, p);
                        }
                        // fetch error lines
                        Boolean productNotFound = false, duplicateProducts = false, productNameNotMatch = false;
                        String errorMsgProductNotFound = Label.MSG_Product_Does_Not_Exist;
                        String errorMsgDuplicateProduct = Label.MSG_Duplicate_Product;
                        String errorMsgProductNameNotMatch = 'Error: Product name and code does not match. Row Index: ';
                        Set<Id> importProductsIds = new Set<Id>();
                        // Fill the global successful records map.
                        for (ProductWrapper item : productList) {
                            // check products not found
                            if(!productMap.containsKey(item.ProductCode)) {
                                errorMsgProductNotFound += String.valueOf(item.index) + ', ';
                                productNotFound = true;
                                continue;
                            }
                            // check duplicate products
                            Product2 product = productMap.get(item.ProductCode);
                            if(!importProductsIds.contains(product.Id)){
                                importProductsIds.add(product.Id);
                            }
                            else {
                                errorMsgDuplicateProduct += String.valueOf(item.index) + ', ';
                                duplicateProducts = true;
                            }
                            // check products name and code does not match
                            /***if(item.productName != product.Name) {
                                errorMsgProductNameNotMatch += String.valueOf(item.index) + ', ';
                                productNameNotMatch = true;
                            }***/
                        }
                        if(!duplicateProducts /*&& !productNameNotMatch*/) {
                            for (ProductWrapper item : productList) {
                                if(productMap.containsKey(item.ProductCode)) {
                                    Product2 product = productMap.get(item.ProductCode);
                                    this.pvpMap.put(product.Id, item.PVP.value);
                                    this.sellOutUnitMap.put(product.Id, item.sellOutUnit.value);
                                }
                            }
                            if(!importProductsIds.isEmpty()) {
                                selectedProductsIds.addAll(importProductsIds);
                                updateSimulator();
                            }
                        }
                        
                        if(errorLine || productNotFound || duplicateProducts /*|| productNameNotMatch*/){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, (errorLine ? errorMsgLine + '\n' : '') +
                                                                       (productNotFound ? errorMsgProductNotFound + '\n' : '') +
                                                                       (duplicateProducts ? errorMsgDuplicateProduct + '\n' : '') /*+
                                                                       (productNameNotMatch ? errorMsgProductNameNotMatch : '')*/));
                        }
                        else {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Successfully Uploaded!'));
                        }
                    } catch (Exception ex) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Occurred: ' + ex.getMessage()));
                    }
                }
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'FILE NOT FOUND.'));
        }
        this.importFile = false;
        return null;
    }
        
    // generate Commmercial_plan_detail
    public PageReference save() {
        Savepoint sp = Database.setSavepoint();
        try {
            if(commercialPlan.Supplier__c == null) return null;
            calculateSimulatorValue();
            getSimulatorList();
            // delete commercial plan details, conditions and dispatch details
            if(checkDeletibility(Commercial_Plan_Detail__c.SObjectType)){
                List<Commercial_Plan_Detail__c> commercialPlanDetailDeleteList  = [SELECT Id, Prenego_envelop__c FROM Commercial_Plan_Detail__c
                                                                                   WHERE Commercial_Event__c = :commercialPlan.Id
                                                                                   AND Supplier__c = :commercialPlan.Supplier__c
                                                                                   AND (Product__c NOT IN :simulatorIds)];
                if(commercialPlanDetailDeleteList.size() > 0) {
                    delete commercialPlanDetailDeleteList; 
                }
            }
            
            // find contract linked to commercial plan Target_BU            
            Contract__c contract = findContract(new Set<Id>{commercialPlan.BU_Target__c});
            // if contract not exist find contract linked to parent BU
            if(contract == null) {
                Map<Id, Set<Id>> childParentBUMap = NegoptimHelper.getBUParentsMap(new Set<Id>{commercialPlan.BU_Target__c});
                Set<Id> BUSet = new Set<Id>();
                if(childParentBUMap.size() > 0){
                    for(Id key : childParentBUMap.keySet()) {
                        BUSet.add(key);
                        for(Id item : childParentBUMap.get(key)) {
                            BUSet.add(item);
                        }
                    }
                }
                else {
                    BUSet.add(commercialPlan.BU_Target__c);
                }
                contract = findContract(BUSet);
            }
            if(contract == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.MSG_ContractNotExist));
            }
            
            // Check commercial plan update field security
            String[] commercialPlanFields = new String [] {getFieldName('Supplier__c'), getFieldName('Target_Elasticity__c'), getFieldName('Target_Constribution_rate__c'),
                getFieldName('Promo_Budget_Type__c'), getFieldName('Regular_Nego_Discount__c'), getFieldName('History_Reference__c')};
            
            // Check commercial plan detail upsert field security
            String[] commercialPlanDetailFields = new String [] {'CurrencyIsoCode', getFieldName('Contract__c'), getFieldName('Nego_Scope__c'),
                getFieldName('BU_Target__c'), getFieldName('Product__c'), getFieldName('Supplier__c'),
                getFieldName('Promo_Purchase_Price__c'), getFieldName('Promo_Sales_Price__c'), getFieldName('Regular_Purchase_Price__c'),
                getFieldName('Regular_Sales_Price__c'), getFieldName('Contribution_Unit_Amount__c'), getFieldName('Volume_Period_Reference__c'),
                getFieldName('Elasticity_rate_calc__c')};
                    
            String[] commercialPlanDetailInsertFields = new String [] {getFieldName('Commercial_Event__c')};
            commercialPlanDetailInsertFields.addAll(commercialPlanDetailFields);
            
            List<Commercial_Plan_Detail__c> commercialPlanDetailList = new List<Commercial_Plan_Detail__c>();
            if(checkCreatibility(Commercial_Plan_Detail__c.SObjectType, commercialPlanDetailInsertFields) && 
               checkUpdatibility(Commercial_Plan_Detail__c.SObjectType, commercialPlanDetailFields))
            {
                for(String id : this.simulatorIds) {
                    ProductUpdatedWrapper wProduct = selectedProductMap.get(id);
                    if(wProduct != null) {
                        Commercial_Plan_Detail__c commercialPlanDetail;
                        if(!commercialPlanDetailMap.containsKey(wProduct.productId)) {
                            commercialPlanDetail = new Commercial_Plan_Detail__c(Commercial_Event__c = commercialPlan.Id,
                                                                                 Product__c = wProduct.productId,
                                                                                 CurrencyIsoCode = commercialPlan.CurrencyIsoCode);
                            commercialPlanDetailMap.put(wProduct.productId, commercialPlanDetail);
                        } else {
                            commercialPlanDetail = commercialPlanDetailMap.get(wProduct.productId);
                            if(this.editSimulator) commercialPlanDetail.Statut__c = 'Update with fact data';                            
                        }
                        commercialPlanDetail.Supplier__c = commercialPlan.Supplier__c;
                        commercialPlanDetail.Contract__c = contract != null ? contract.Id : null;
                        commercialPlanDetail.Nego_Scope__c = contract != null ? contract.Supplier_Nego_Scope__c : null;
                        commercialPlanDetail.BU_Target__c = this.commercialPlan.BU_Target__c;
                        commercialPlanDetail.COGS__c = wProduct.COGS;
                        commercialPlanDetail.Regular_Purchase_Price__c = this.selectedSellin ? wProduct.sellinPrice : null;
                        commercialPlanDetail.Regular_Sales_Price__c = !this.selectedSellin ? wProduct.sellinPrice : null;
                        commercialPlanDetail.Promo_Purchase_Price__c = this.selectedSellin ? wProduct.PVP : null;
                        commercialPlanDetail.Promo_Sales_Price__c = !this.selectedSellin ? wProduct.PVP : null;
                        commercialPlanDetail.Contribution_Unit_Amount__c = wProduct.discountedValue;
                        commercialPlanDetail.Volume_Period_Reference__c = wProduct.sellOutUnit;
                        commercialPlanDetail.Elasticity_rate_calc__c = this.elasticityRateCalc;
                        commercialPlanDetailList.add(commercialPlanDetail);
                    }
                }
                // upsert commercial plan details
                if(commercialPlanDetailList.size() > 0) {
                    List<Database.UpsertResult> results = Database.upsert(commercialPlanDetailList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        Commercial_Plan_Detail__c commercialPlanDetail = commercialPlanDetailList.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = (commercialPlanDetail.Name != null ? commercialPlanDetail.Name + ' : ' : '');                            
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                            return null;
                        }
                    }
                }
            }
            if(checkUpdatibility(Commercial_Plan__c.SObjectType, commercialPlanFields)){
                // update commercial plan
                commercialPlan.Promo_Budget_Type__c = this.selectedSellin ? 'Sell In' : 'Sell Out';
                commercialPlan.Target_Elasticity__c = this.elasticityRateCalc;
                commercialPlan.Target_Constribution_rate__c = this.contributionRate;
                commercialPlan.Regular_Nego_Discount__c = this.correctionRate;
                commercialPlan.History_Reference__c = String.isNotBlank(this.historyReference) ? this.historyReference : null;
                if(this.editSimulator) commercialPlan.Status__c = 'Update with fact data';
                Database.SaveResult result = Database.update(commercialPlan, false);
            }
        } catch(DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_Error_Occurred));
            Database.rollback(sp);
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_Error_Occurred));
            Database.rollback(sp);
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
        
        PageReference previousPage = new PageReference('/' + commercialPlanId);
        previousPage.setRedirect(true);
        return previousPage;
    }
    
    private Contract__c findContract(Set<Id> BUSet){
        List<Contract__c> contracts = [SELECT Id, Name, Supplier_Nego_Scope__c, Reference_Year__c, Contract_BU__c
                                       FROM Contract__c 
                                       WHERE Supplier__c = :commercialPlan.Supplier__c AND Contract_Type__c = 'Contract'
                                       AND Contract_BU__c <> NULL AND Contract_BU__c IN :BUSet
                                       AND Contract_BDate__c <= :commercialPlan.Start_Date__c
                                       AND Contract_EDate__c >= :commercialPlan.End_Date__c
                                       ORDER BY Contract_BDate__c DESC LIMIT 1];
        if(contracts != null && contracts.size() > 0) {
            return contracts.get(0);
        }
        return null;
    }
    
    // generate Excel
    public PageReference generateExcel() {
        if(commercialPlan.Supplier__c == null) return null;
        PageReference pageRef = new PageReference('/apex/CommercialPlanSimulatorExport');
        pageRef.getParameters().put('action', 'Export');
        pageRef.getParameters().put('id', commercialPlanId);
        pageRef.getParameters().put('selectedSellIn', String.valueOf(selectedSellIn));
        pageRef.getParameters().put('amount', String.valueOf(amount));
        pageRef.getParameters().put('contributionRate', String.valueOf(contributionRate));
        pageRef.getParameters().put('elasticityRateCalc', String.valueOf(elasticityRateCalc));
        pageRef.getParameters().put('correctionRate', String.valueOf(correctionRate));
        pageRef.getParameters().put('structureLevelName', structureLevelLookup.label);
        pageRef.getParameters().put('brandName', brandLookup.label);
        pageRef.getParameters().put('negoScopeName', negoScopeLookup.label);
        pageRef.getParameters().put('inAssortment', String.valueOf(inAssortment));
        pageRef.getParameters().put('searchName' , searchName);
        pageRef.getParameters().put('simulatorIds', String.join(new List<Id>(simulatorIds), ','));
        pageRef.getParameters().put('pvpMap', JSON.serialize(pvpMap));
        pageRef.getParameters().put('sellOutUnitMap', JSON.serialize(sellOutUnitMap));
        
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public PageReference Cancel() {
        PageReference previousPage = new PageReference('/' + commercialPlanId );
        previousPage.setRedirect(true);
        return previousPage;
    }
    
    /* Product Wrapper Class */
    public class ProductWrapper implements Comparable {
        //implements Comparable
        public Integer index {get;set;}
        public Product2 product {get; set;}
        public String productCode {get;set;}
        public String productName {get;set;}
        public Boolean selected {get; set;}
        public Boolean inAssortment {get; set;}        
        public NegoptimNumber COGS {get; set;}
        public NegoptimNumber sellinPrice {get; set;}
        public NegoptimNumber grossMargin {get; set;}
        public NegoptimNumber sellinUnit {get; set;}
        public NegoptimNumber sellinValue {get; set;}
        public NegoptimNumber marketShare {get; set;}
        public NegoptimNumber PVP {get; set;}
        public NegoptimNumber sellOutUnit {get; set;}
        public NegoptimNumber sellOutValue {get; set;}
        public NegoptimNumber units {get; set;}
        public NegoptimNumber value {get; set;}
        public NegoptimNumber discountedValue {get; set;}
        public NegoptimNumber discSellOut {get; set;}
        public NegoptimNumber corSellIn {get; set;}
        public NegoptimNumber corCOGS {get; set;}
        public NegoptimNumber regularGM {get; set;}
        public NegoptimNumber GMAfterDisc {get; set;}
        public NegoptimNumber Diff {get; set;}
        
        public ProductWrapper(Product2 p, Boolean sel) {
            product = p;
            selected = sel;
            inAssortment = false;
            this.COGS = new NegoptimNumber(2);
            this.sellinPrice = new NegoptimNumber(2);
            this.grossMargin = new NegoptimNumber(2);
            this.sellinUnit = new NegoptimNumber(2);
            this.sellinValue = new NegoptimNumber(2);
            this.marketShare = new NegoptimNumber(2);
            this.PVP = new NegoptimNumber(2);
            this.sellOutUnit = new NegoptimNumber(2);
            this.sellOutValue = new NegoptimNumber(2);
            this.units = new NegoptimNumber(2);
            this.value = new NegoptimNumber(2);
            this.discountedValue = new NegoptimNumber(2);
            this.discSellOut = new NegoptimNumber(2);
            this.corSellIn = new NegoptimNumber(2);
            this.corCOGS = new NegoptimNumber(2);
            this.regularGM = new NegoptimNumber(2);
            this.GMAfterDisc = new NegoptimNumber(2);
            this.Diff = new NegoptimNumber(2);
        }
        
        // Implement the compareTo() method
        public Integer compareTo(Object compareTo) {
            Integer returnValue = 0;
            ProductWrapper compareToProductWrapper = (ProductWrapper)compareTo;            
            if(this.index != null && compareToProductWrapper.index != null){
                if (this.index < compareToProductWrapper.index)
                    return -1;
                else if (this.index > compareToProductWrapper.index)
                    return 1;
            }
            return returnValue;
        }
    }
    
    // updated fields for save
    private class ProductUpdatedWrapper  {
        Id productId {get; set;}
        Decimal COGS {get; set;}
        Decimal sellinPrice {get; set;}
        Decimal PVP {get; set;}
        Decimal discountedValue {get; set;}
        Decimal sellOutUnit {get; set;}
        
        public ProductUpdatedWrapper(Id pId) {
            this.productId = pId;
        }
    }
}