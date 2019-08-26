/**
 * @description Custom controller that uses the standard Orga_BU__c controller and includes the 
 * Assortment Store Clustering logic for the corresponding view. It provides the following initial functionalities:
 * 1- Display all stores regarding the related assortment cluster for all BUs source (clients) + Filter.
 * 2- Display the stores regarding the related assortment cluster for a single client + Filter.
 **/
public with sharing class AssortmentStoreClusteringController extends NegoptimBaseController {
    
	// Mapping between Country Id & Country Wrapper.
    public Map<Id, CountryWrapper> wCountryMap {get; set;}
    // Mapping between Store Id & Store.
    private Map<Id, Orga_BU__c> allStoresMap;
    // Mapping between Assortment Cluster Id & Assortment Cluster.
    public Map<Id, Orga_BU__c> assortmentClusterMap {get; set;}
    // Private Record Id declaration: Country BU.
    public LookupValue countryLookup {get; set;}
    public String recordId {get; set;}
    // Record Type Ids declaration.
    private String countryRecordTypeId, assortmentClusterRecordTypeId;
    // List of Countries/Stores
    public List<Orga_BU__c> countryList {get; set;}
    private List<Orga_BU__c> storeList {get; set;}
    private Map<Id, List<Orga_BU__c>> countryStoresMap {get; set;}
    // Client name input.
    public String searchText {get; set;}
    // Strat values.
    public Set<String> stratsPicklist {get; set;}
    // Weight Distribution values.
    public List<SelectOption> weightedDistributionforecastingPicklist {get; set;}
	// Used to pass the store Id corresponding to the manual input WD to the controller.
	public Id storeId {get; set;}
    public Id countryId {get; set;}
	
	// Pagination variables.
    public list<SelectOption> recPerPageOptions {get; set;}
    private String soqlCountry;
    private String soqlStores;
    public Integer QUERY_LIMIT = 10000;
    
    // Stores strats updated Map
    Map<String, Map<String, Orga_BU__c>> storeStratsUpdatedMap {get; set;}
    // country updated WD
    Map<Id, CountryWrapper> countryUpdatedWDMap {get; set;}
    // stores updated WD
    Map<Id, StoreWrapper> storeUpdatedWDMap {get; set;}

    /** Constructor. */
    public AssortmentStoreClusteringController(ApexPages.StandardController stdController) {
        String countryId = stdController.getId();
        try {
            this.recordId = countryId;
            init();
            load();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }
    
    private void init() {
        //records for page initialization
        recPerPageOptions = new List<SelectOption>();
        recPerPageOptions.add(new SelectOption('5','5'));
        recPerPageOptions.add(new SelectOption('10','10'));
        recPerPageOptions.add(new SelectOption('25','25'));
        recPerPageOptions.add(new SelectOption('50','50'));
        
        this.countryLookup = new LookupValue(true);
        if(String.isNotBlank(this.recordId)) {
            Orga_BU__c country = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :this.recordId];
            this.countryLookup.value = country.Id;
            this.countryLookup.label = country.Name;
        }
        
        this.storeStratsUpdatedMap = new Map<String, Map<String, Orga_BU__c>>();
        this.countryUpdatedWDMap = new Map<Id, CountryWrapper>();
        this.storeUpdatedWDMap = new Map<Id, StoreWrapper>();
        // Load strats picklist
        Schema.DescribeFieldResult assortmentStratsFields = Orga_BU__c.Assortment_Strat__c.getDescribe();
        stratsPicklist = new Set<String>();
        for (Schema.PicklistEntry pv: assortmentStratsFields.getPicklistValues()) {
            stratsPicklist.add(pv.getValue());
        }
        // Load weight distribution picklist
        Schema.DescribeFieldResult wDFields = Orga_BU__c.Weighted_Distribution_forecasting_Ass__c.getDescribe();
        this.weightedDistributionforecastingPicklist = new List<SelectOption>();
        for (Schema.PicklistEntry pv: wDFields.getPicklistValues()) {
            this.weightedDistributionforecastingPicklist.add(new SelectOption(pv.getValue(), pv.getValue()));
        }
        // Set record types Id.
        Map<String, Id> buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Orga_BU__c.SObjectType);
        countryRecordTypeId = buRTIds.get('Country');
        assortmentClusterRecordTypeId = buRTIds.get('Assortment_Cluster');  
    }
    
    private void load() {
        // get country List.
        getCountryList();
        // get stores
        getStoreList();
        getAssortments();
        fillAssortmentsWeightDistribution();
        // fill total strats by country            
        fillCountryTotalStrats();
        // fill total WD
        fillCountryTotalWD();
    }
   
    private void fillCountryTotalStrats() {
        Map<Id, Map<String, Integer>> countryStratsMap = new Map<Id, Map<String, Integer>>();
        Map<Id, Integer> totalStotesMap = new Map<Id, Integer>();
        if(!wCountryMap.isEmpty()) {
            for(AggregateResult item : [SELECT Country_origin__c Country_origin__c, Assortment_Strat__c Assortment_Strat__c, Count(Id) total
                                        FROM Orga_BU__c
                                        WHERE Country_origin__c IN :wCountryMap.keySet()
                                        AND (RecordType.Name = 'Store' OR RecordType.Name = 'Web')
                                        GROUP BY Assortment_Strat__c, Country_origin__c]) 
            {
                Id countryId = (Id) item.get('Country_origin__c');
                string strat = String.valueOf(item.get('Assortment_Strat__c'));
                Integer total = Integer.valueOf(item.get('total'));
                if(!countryStratsMap.containsKey(countryId)) {
                    Map<String, Integer> stratsTotalMap = new Map<String, Integer>();
                    stratsTotalMap.put(strat, total);
                    countryStratsMap.put(countryId, stratsTotalMap);
                } else {
                    Map<String, Integer> stratsTotalMap = countryStratsMap.get(countryId);
                    if(!stratsTotalMap.containsKey(strat)) {
                        stratsTotalMap.put(strat, total);
                    }
                    countryStratsMap.put(countryId, stratsTotalMap);
                }
                // fill total stores by country
                if(!totalStotesMap.containsKey(countryId)) {
                    totalStotesMap.put(countryId, total);
                } else {
                    Integer totalStores = totalStotesMap.get(countryId);
                    totalStotesMap.put(countryId, totalStores + total);
                }
            }
            for(CountryWrapper item : wCountryMap.values()) {
                if(countryStratsMap.containsKey(item.country.Id)) {
                    Map<String, Integer> stratsTotalMap = countryStratsMap.get(item.country.Id);
                    for(String strat : stratsTotalMap.keySet()) {
                        item.currentStratsTotalMap.put(strat, stratsTotalMap.get(strat));
                    }
                    item.newStratsTotalMap = countryStratsMap.get(item.country.Id);
                }
                // init total stores
                if(totalStotesMap.containsKey(item.country.Id)) {
                    item.totalStores = totalStotesMap.get(item.country.Id);
                } else {
                    item.totalStores = 0;
                }
                // fill all strats
                for(String strat : stratsPicklist) {
                    if(!item.currentStratsTotalMap.containsKey(strat)) {
                        item.currentStratsTotalMap.put(strat, 0);
                    }
                    if(!item.newStratsTotalMap.containsKey(strat)) {
                        item.newStratsTotalMap.put(strat, 0);
                    }
                }
            }
        }        
    }
       
    private void fillCountryTotalWD() {
        Map<Id, Map<String, Decimal>> countrytotalStratsWDMap = new Map<Id, Map<String, Decimal>>();
        if(!wCountryMap.isEmpty()) {
            for(AggregateResult item : [SELECT Country_origin__c Country_origin__c, Assortment_Strat__c Assortment_Strat__c,
                                        Weighted_Distribution_forecasting_Ass__c Weighted_Distribution_forecasting_Ass__c,
                                        SUM(Weighted_Distribution_SellOut_Fact__c) wDSelloutFact, SUM(Weighted_Distribution_SellOut_Forecast__c) wDSelloutForecast,
                                        SUM(Weighted_Distribution_SellIn_Fact__c) wDSellinFact, SUM(Weighted_Distribution_SellIn_Forecast__c) wDSellinForecast,
                                        SUM(Weighted_Distribution_Manual__c) wDManual
                                        FROM Orga_BU__c
                                        WHERE Country_origin__c IN :wCountryMap.keySet() AND Weighted_Distribution_forecasting_Ass__c <> NULL
                                        AND (RecordType.Name = 'Store' OR RecordType.Name = 'Web')
                                        GROUP BY Country_origin__c, Assortment_Strat__c, Weighted_Distribution_forecasting_Ass__c]) 
            {
                Id countryId = (Id) item.get('Country_origin__c');
                String strat = String.valueOf(item.get('Assortment_Strat__c'));
                String weightedDistributionforecasting = String.valueOf(item.get('Weighted_Distribution_forecasting_Ass__c'));                
                Decimal wDSelloutFact = item.get('wDSelloutFact') != null ? Decimal.valueOf(String.valueOf(item.get('wDSelloutFact'))) : 0;
                Decimal wDSelloutForecast = item.get('wDSelloutForecast') != null ? Decimal.valueOf(String.valueOf(item.get('wDSelloutForecast'))) : 0;
                Decimal wDSellinFact = item.get('wDSellinFact') != null ? Decimal.valueOf(String.valueOf(item.get('wDSellinFact'))) : 0;
                Decimal wDSellinForecast = item.get('wDSellinForecast') != null ?Decimal.valueOf(String.valueOf(item.get('wDSellinForecast'))) : 0;
                Decimal wDManual = item.get('wDManual') != null ? Decimal.valueOf(String.valueOf(item.get('wDManual'))) : 0;
                Decimal WD = 0;
                if (weightedDistributionforecasting == 'Sell Out (Fact)' && wDSelloutFact != null) {
                    WD = wDSelloutFact;
                } else if(weightedDistributionforecasting == 'Sell Out (Forecast)' && wDSelloutForecast != null) {
                    WD = wDSelloutForecast;
                } else if(weightedDistributionforecasting == 'Sell In (Fact)' && wDSellinFact != null) {
                    WD = wDSellinFact;
                } else if(weightedDistributionforecasting == 'Sell In (Forecast)' && wDSellinForecast != null) {
                    WD = wDSellinForecast;
                } else if(weightedDistributionforecasting == 'Manual' && wDManual != null) {
                    WD = wDManual;
                }
                
                // calculate total WD by strats
                if(!countrytotalStratsWDMap.containsKey(countryId)) {
                    Map<String, Decimal> stratsTotalWDMap = new Map<String, Decimal>();
                    stratsTotalWDMap.put(strat, WD);
                    countrytotalStratsWDMap.put(countryId, stratsTotalWDMap);
                } else {
                    Map<String, Decimal> stratsTotalWDMap = countrytotalStratsWDMap.get(countryId);
                    if(!stratsTotalWDMap.containsKey(strat)) {
                        stratsTotalWDMap.put(strat, WD);
                    } else {
                        decimal total = stratsTotalWDMap.get(strat);
                        stratsTotalWDMap.put(strat, total + WD);
                    }
                    countrytotalStratsWDMap.put(countryId, stratsTotalWDMap);
                }
                
                // calculate total WD
                CountryWrapper wCountry = wCountryMap.get(countryId);
                wCountry.totalWD += WD;
                wCountry.totalWDSellOutFact += wDSelloutFact;
                wCountry.totalWDSellOutForecast += wDSelloutForecast;
                wCountry.totalWDSellInFact += wDSellinFact;
                wCountry.totalWDSellInForecast += wDSellinForecast;
                wCountry.totalWDManual += wDManual;
            }
            for(CountryWrapper item : wCountryMap.values()) {
                if(countrytotalStratsWDMap.containsKey(item.country.Id)) {
                    Map<String, Decimal> stratsTotalWDMap = countrytotalStratsWDMap.get(item.country.Id);
                    for(String strat : stratsTotalWDMap.keySet()) {
                        item.currentStoresTotalWDMap.put(strat, stratsTotalWDMap.get(strat));
                    }
                    item.newStoresTotalWDMap = countrytotalStratsWDMap.get(item.country.Id);
                }
                // fill all strats
                for(String strat : stratsPicklist) {
                    if(!item.currentStoresTotalWDMap.containsKey(strat)) {
                        item.currentStoresTotalWDMap.put(strat, 0);
                    }
                    if(!item.newStoresTotalWDMap.containsKey(strat)) {
                        item.newStoresTotalWDMap.put(strat, 0);
                    }
                }
            }
        }        
    }
    
    private void fillAssortmentsWeightDistribution() {
        for (Id countryId : wCountryMap.keySet()) {
            CountryWrapper wCountry = wCountryMap.get(countryId);
            // Calculate WD on country level.
            wCountry.weightedDistributionValue = getInitWD(wCountry.country, null);
            // Fill the Assortment Clusters.
            for (Id key : assortmentClusterMap.keySet()) {
                Orga_BU__c assortmentCluster = assortmentClusterMap.get(key);
                Decimal weightedDistributionValue;
                if (assortmentCluster.Country_origin__c == countryId && assortmentCluster.Assortment_Strat__c != null) {
                    wCountry.assortmentClusters.add(assortmentCluster);
                    // Push assortment name.
                    wCountry.countryHeaderMap.put(assortmentCluster.Assortment_Strat__c, assortmentCluster.Name);
                    // Push available strats.
                    wCountry.countryStratsMap.put(assortmentCluster.Assortment_Strat__c, true);
                    // Calculate WD on assortment level.
                    weightedDistributionValue = getInitWD(assortmentCluster, null);
                    weightedDistributionValue = weightedDistributionValue == null ? -1 : weightedDistributionValue;
                    wCountry.assortmentWDMap.put(assortmentCluster.Assortment_Strat__c, weightedDistributionValue);
                }
            }
        }
    }

    // process update stores strats
    private void processUpdateStoreStrats() {
        for (Id countryId : wCountryMap.keySet()) {
            CountryWrapper wCountry = wCountryMap.get(countryId);
            for (StoreWrapper wStore : wCountry.wStores) {
                String key = countryId + '' + wStore.store.Id;
                Map<String, Boolean> currentSratsMap = wStore.storeStratsMap.get(wStore.store.Id);
                String oldStrat = null;
                if(this.storeStratsUpdatedMap.containsKey(key)) {
                    Map<String, Orga_BU__c> stratMap = this.storeStratsUpdatedMap.get(key);
                    List<String> strats = new List<String>(stratMap.keySet());
                    oldStrat = strats.get(0);
                }
                if(oldStrat == null) oldStrat = wStore.store.Assortment_Strat__c;
                for(String strat : currentSratsMap.keySet()) {
                    if(currentSratsMap.get(strat) == true) {
                        if(oldStrat != strat) {
                            // update country new strats total
                            if(!wCountry.newStratsTotalMap.containsKey(strat)) {
                                wCountry.newStratsTotalMap.put(strat, 1);
                            } else {
                                Integer total = wCountry.newStratsTotalMap.get(strat);
                                wCountry.newStratsTotalMap.put(strat, total + 1);
                            }
                            // update country old strats total
                            if(wCountry.newStratsTotalMap.containsKey(oldStrat)) {
                                Integer total = wCountry.newStratsTotalMap.get(oldStrat);
                                wCountry.newStratsTotalMap.put(oldStrat, total - 1);
                            }
                            Map<String, Orga_BU__c> stratMap = new Map<String, Orga_BU__c>();
                            stratMap.put(strat, wStore.store);
                            this.storeStratsUpdatedMap.put(key, stratMap);
                            
                            // update strat WD
                            if(wCountry.newStoresTotalWDMap.containsKey(strat)) {
                                // update WD for new strat
                                Decimal totalWD = wCountry.newStoresTotalWDMap.get(strat);
                                fillStoreWD(wStore);
                                wCountry.newStoresTotalWDMap.put(strat, totalWD + wStore.weightedDistributionValue);
                                // update WD total for old strat
                                totalWD = wCountry.newStoresTotalWDMap.get(oldStrat);
                                wCountry.newStoresTotalWDMap.put(oldStrat, totalWD - wStore.weightedDistributionValue);
                            }
                        }
                        break;
                    }
                }
            }
        }
    }
    
    // refresh lookup fields
    public void refresh(){
    }
    
    /**
     * @description Get Country Soql String.
     * @param recordId, countryRecordTypeId.
     * @return String
     **/
  	private void getCountryList() {
        soqlCountry = 'SELECT Id, Name, BU_Code__c, Country_origin__c,';
        soqlCountry += ' Weighted_Distribution_forecasting_Ass__c, Weighted_Distribution_Manual__c,';
        soqlCountry += ' Weighted_Distribution_SellIn_Fact__c, Weighted_Distribution_SellIn_Forecast__c,';
        soqlCountry += ' Weighted_Distribution_SellOut_Fact__c, Weighted_Distribution_SellOut_Forecast__c,';
        soqlCountry += ' Weighted_Distribution_SelloutWDWeight__c, Weighted_Distribution_SellinWDWeight__c, Weighted_Distribution_Weighted__c';
        soqlCountry += ' FROM Orga_BU__c';
        soqlCountry += ' WHERE RecordTypeId =\'' + String.escapeSingleQuotes(countryRecordTypeId) +'\' AND Id IN (SELECT Entity__c FROM Orga_BU_List_Detail__c)';
        
        if(String.isNotBlank(countryLookup.value) || String.isNotBlank(countryLookup.label)) {
            if(String.isNotBlank(countryLookup.value)){
                List<String> selectedCountryIds = String.escapeSingleQuotes(countryLookup.value).split(',');
                soqlCountry += ' AND Id IN (\'' + String.join(selectedCountryIds, '\',\'') +'\')';
            }
            else if(String.isNotBlank(countryLookup.label)){
                soqlCountry += ' AND (Name LIKE \'%' + String.escapeSingleQuotes(countryLookup.label) + '%\' OR BU_Code__c LIKE \'%' + String.escapeSingleQuotes(countryLookup.label) + '%\')';
            }
        }
        soqlCountry += ' ORDER BY Name, Country_origin__c ASC';
        
        // fill countries
        this.countryList = Database.query(soqlCountry);
        wCountryMap = new Map<Id, CountryWrapper>();
        for (Orga_BU__c c : countryList) {
            wCountryMap.put(c.Id, new CountryWrapper(c, stratsPicklist));
        }
        
        // Check Orga_BU__c fields accessibility.
        String[] BUFields = new String [] {'Id', 'Name', getFieldName('BU_Code__c'), getFieldName('Format_Origin__c'),
            getFieldName('Country_Zone_origin__c'), getFieldName('Country_origin__c'), getFieldName('Related_client__c'),
            getFieldName('Assortment_Strat__c'), getFieldName('Weighted_Distribution_forecasting_Ass__c'), 
            getFieldName('Weighted_Distribution_Manual__c'), getFieldName('Weighted_Distribution_SellIn_Fact__c'),
            getFieldName('Weighted_Distribution_SellIn_Forecast__c'), getFieldName('Weighted_Distribution_SellOut_Fact__c'),
            getFieldName('Weighted_Distribution_SellOut_Forecast__c'), getFieldName('Weighted_Distribution_SelloutWDWeight__c'),
            getFieldName('Weighted_Distribution_SellinWDWeight__c'), getFieldName('Weighted_Distribution_Weighted__c')};
                
        if (checkAccessibility(Orga_BU__c.SObjectType, BUFields)) {
            // fill Assortment Cluster BUs.
            this.assortmentClusterMap = new Map<Id, Orga_BU__c>([SELECT Id, Name, BU_Code__c, Format_Origin__c, Country_Zone_origin__c,
                                                                 Country_origin__c, Related_client__c, RecordType.Name, Assortment_Strat__c,
                                                                 Weighted_Distribution_forecasting_Ass__c, Weighted_Distribution_Manual__c,
                                                                 Weighted_Distribution_SellIn_Fact__c, Weighted_Distribution_SellIn_Forecast__c,
                                                                 Weighted_Distribution_SellOut_Fact__c, Weighted_Distribution_SellOut_Forecast__c,
                                                                 Weighted_Distribution_SelloutWDWeight__c, Weighted_Distribution_SellinWDWeight__c, Weighted_Distribution_Weighted__c
                                                                 FROM Orga_BU__c
                                                                 WHERE RecordTypeId = :assortmentClusterRecordTypeId AND Country_origin__c IN :countryList
                                                                 ORDER BY Assortment_Strat__c ASC]);
        }
  	}
    
    /**
     * @description Get Store Soql String.
     * @return String
     **/
    private void getStoreList() {        
        soqlStores = 'SELECT Id, Name, BU_Code__c, Format_Origin__c, Country_Zone_origin__c, Country_origin__c, Related_client__c, Assortment_Strat__c,';
        soqlStores += ' Weighted_Distribution_forecasting_Ass__c, Weighted_Distribution_Manual__c, Weighted_Distribution_SellIn_Fact__c,';
        soqlStores += ' Weighted_Distribution_SellIn_Forecast__c, Weighted_Distribution_SellOut_Fact__c, Weighted_Distribution_SellOut_Forecast__c,';
        soqlStores += ' Weighted_Distribution_SelloutWDWeight__c, Weighted_Distribution_SellinWDWeight__c, Weighted_Distribution_Weighted__c';
        soqlStores += ' FROM Orga_BU__c';
        soqlStores += ' WHERE RecordType.DeveloperName IN (\'Store\',\'Web\')';
        soqlStores += ' AND Country_origin__c IN (\'' + String.join(new List<Id>(wCountryMap.keySet()), '\',\'') +'\')';
        if (String.isNotBlank(this.searchText)) {
            soqlStores += ' AND (Name LIKE \'%' + String.escapeSingleQuotes(searchText) + '%\' OR BU_Code__c LIKE \'%' + String.escapeSingleQuotes(searchText) + '%\')';
        }
        
        // get store list
        for(CountryWrapper item : wCountryMap.values()) {
            item.StdSetControllerStores = null;
            item.soqlStores = soqlStores + ' AND Country_origin__c = \'' + item.country.Id + '\'';
            item.soqlStores += ' ORDER BY Name ASC LIMIT ' + QUERY_LIMIT;
        }
    }
    
    // fill store assortment list
    public void getAssortments() {
        for (Id countryId : wCountryMap.keySet()) {
            CountryWrapper wCountry = wCountryMap.get(countryId);
            wCountry.wStores = new List<StoreWrapper>();
            List<Orga_BU__c> storeList = (List<Orga_BU__c>)wCountry.StdSetControllerStores.getRecords();
            if(!storeList.isEmpty()) {
                for (Orga_BU__c item : storeList) {
                    // fill store wrapper
                    StoreWrapper wStore = fillStoreWrapper(wCountry, item);
                    wCountry.wStores.add(wStore);
                }
            }
        }
    }
    
    private StoreWrapper fillStoreWrapper(CountryWrapper wCountry, Orga_BU__c store) {
        String key = wCountry.country.Id + '' + store.Id;
        Map<String, Boolean> stratsMap = new Map<String, Boolean>();                
        for(String strat : this.stratsPicklist) {
            // check if strats is updated
            if(this.storeStratsUpdatedMap.containsKey(key) && this.storeStratsUpdatedMap.get(key).containsKey(strat)) {
                stratsMap.put(strat, true);
            } else if (!this.storeStratsUpdatedMap.containsKey(key) && store.Assortment_Strat__c == strat) {
                stratsMap.put(strat, true);
            } else {
                stratsMap.put(strat, false);
            }
        }
        // init store wrapper
        StoreWrapper wStore = new StoreWrapper(store);
        // check if update all stores Forecasting Assortment// Sellout WD/ Sellin WD
        if(wCountry.updateStoresWDForecasting) {
            wStore.weightedDistributionforecastingAss = wCountry.weightedDistributionforecastingAss;
        }
        if(wCountry.updateStoresSelloutWDWeight) {
            wStore.weightedDistributionSelloutWDWeight = wCountry.weightedDistributionSelloutWDWeight;
        }
        if(wCountry.updateStoresSellinWDWeight) {
            wStore.weightedDistributionSellinWDWeight = wCountry.weightedDistributionSellinWDWeight;
        }
        // fill strats
        wStore.storeStratsMap.put(store.Id, stratsMap);
        // get weighted distribution value
        if (wStore.weightedDistributionforecastingAss != null) {
            // Calculate WD on store level.
            fillStoreWD(wStore);
        }
        return wStore;
    }
        
    // Changes the size of pagination of stores Grid
    public PageReference refreshPageSizeStores() {
        if(countryId == null) return null;
        CountryWrapper wCountry = wCountryMap.get(countryId);
        processUpdateStoreStrats();
        wCountry.StdSetControllerStores.setPageSize(wCountry.recPerPageStores);
        getAssortments();
        return null;
    }
    
    // returns the first page of stores
    public void firstStoresPage() {
        if(countryId == null) return;
        CountryWrapper wCountry = wCountryMap.get(countryId);
        processUpdateStoreStrats();
        wCountry.StdSetControllerStores.first();
        getAssortments();
    }
    
    // returns the previous page of stores
    public void previousStoresPage() {
        if(countryId == null) return;
        CountryWrapper wCountry = wCountryMap.get(countryId);
        processUpdateStoreStrats();
        wCountry.StdSetControllerStores.previous();
        getAssortments();
    }
    
    // returns the next page of stores
    public void nextStoresPage() {
        if(countryId == null) return;
        CountryWrapper wCountry = wCountryMap.get(countryId);
        processUpdateStoreStrats();
        wCountry.StdSetControllerStores.next();
        getAssortments();
    }
    
    // returns the last page of stores
    public void lastStoresPage() {
        if(countryId == null) return;
        CountryWrapper wCountry = wCountryMap.get(countryId);
        processUpdateStoreStrats();
        wCountry.StdSetControllerStores.last();
        getAssortments();
    }
    
    public PageReference search() {
        /*for(CountryWrapper item : wCountryMap.values()) {
            item.soqlStores = null;
            item.wStores.clear();
        }
        getCountryList();
        getStoreList();
        getAssortments();*/
        load();
        return null;
    }

    public PageReference resetStores() {
        for(CountryWrapper item : wCountryMap.values()) {
            item.soqlStores = null;
            item.wStores.clear();
        }
        this.searchText = '';
        this.countryLookup = new LookupValue(true);
        /*getStoreList();
        getAssortments();*/
        load();
        return null;
    }

    /**
     * @description Calculate button. Set the new Assortment part of the grid (sum of the corresponding WDs + sum of the checked checkboxes).
     * @return PageReference : null
     **/
    public PageReference calculate() {
        processUpdateStoreStrats();     
    	return null;
    }
    
  	/**
     * @description Save method.
     * @return PageReference
     **/
    public PageReference save() {
        calculate();
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on update Orga_BU__c
            String[] orgaBUFields = new String[] { getFieldName('Weighted_Distribution_forecasting_Ass__c'), getFieldName('Weighted_Distribution_SelloutWDWeight__c'),
                getFieldName('Weighted_Distribution_SellinWDWeight__c'), getFieldName('Weighted_Distribution_Manual__c')};
            
            List<Orga_BU__c> countryUpdatedList = new List<Orga_BU__c>();
            Map<Id, Orga_BU__c> storesUpdatedMap = new Map<Id, Orga_BU__c>();
            Map<Id, CountryWrapper> countryUpdatedMap = new Map<Id, CountryWrapper>();
            if(!this.countryUpdatedWDMap.isEmpty()) {
                for(CountryWrapper wCountry : this.countryUpdatedWDMap.values()) {
                    wCountry.country.Weighted_Distribution_forecasting_Ass__c = wCountry.weightedDistributionforecastingAss;
                    wCountry.country.Weighted_Distribution_SelloutWDWeight__c = wCountry.weightedDistributionSelloutWDWeight;
                    wCountry.country.Weighted_Distribution_SellinWDWeight__c = wCountry.weightedDistributionSellinWDWeight;
                    wCountry.country.Weighted_Distribution_Manual__c = wCountry.weightedDistributionManual;
                    countryUpdatedList.add(wCountry.country);
                    // check if update all stores Forecasting Assortment/ Sellout WD/ Sellin WD
                    if(wCountry.updateStoresWDForecasting || wCountry.updateStoresSelloutWDWeight || wCountry.updateStoresSellinWDWeight) {
                        countryUpdatedMap.put(wCountry.country.Id, wCountry);
                    }
                }
                if(!countryUpdatedList.isEmpty()) {
                    if (checkUpdatibility(Orga_BU__c.SObjectType, orgaBUFields)) {
                        List<Database.SaveResult> results = Database.update(countryUpdatedList, false);
                    }
                }
            }
            if(!this.storeUpdatedWDMap.isEmpty()) {
                for(StoreWrapper wStore : this.storeUpdatedWDMap.values()) {
                    wStore.store.Weighted_Distribution_forecasting_Ass__c = wStore.weightedDistributionforecastingAss;
                    wStore.store.Weighted_Distribution_SelloutWDWeight__c = wStore.weightedDistributionSelloutWDWeight;
                    wStore.store.Weighted_Distribution_SellinWDWeight__c = wStore.weightedDistributionSellinWDWeight;
                    wStore.store.Weighted_Distribution_Manual__c = wStore.weightedDistributionManual;
                    storesUpdatedMap.put(wStore.store.Id, wStore.store);
                }
            }
            // check if update all stores Forecasting Assortment/ Sellout WD/ Sellin WD
            if(!countryUpdatedMap.isEmpty()) {
                for(Orga_BU__c item : [SELECT Id, Country_origin__c, Assortment_Strat__c,
                                       Weighted_Distribution_forecasting_Ass__c, Weighted_Distribution_Manual__c, Weighted_Distribution_SellIn_Fact__c,
                                       Weighted_Distribution_SellIn_Forecast__c, Weighted_Distribution_SellOut_Fact__c, Weighted_Distribution_SellOut_Forecast__c,
                                       Weighted_Distribution_SelloutWDWeight__c, Weighted_Distribution_SellinWDWeight__c, Weighted_Distribution_Weighted__c
                                       FROM Orga_BU__c
                                       WHERE RecordType.DeveloperName IN ('Store','Web')
                                       AND Country_origin__c IN :countryUpdatedMap.keySet() 
                                       AND Id NOT IN :storesUpdatedMap.keySet()])
                {
                    CountryWrapper wCountry = this.countryUpdatedWDMap.get(item.Country_origin__c);
                    // check if update all stores Forecasting Assortment
                    if(wCountry.updateStoresWDForecasting) {
                        item.Weighted_Distribution_forecasting_Ass__c = wCountry.weightedDistributionforecastingAss;
                    }
                    // check if update all stores Sellout WD
                    if(wCountry.updateStoresSelloutWDWeight) {
                        item.Weighted_Distribution_SelloutWDWeight__c = wCountry.weightedDistributionSelloutWDWeight;
                    }
                    // check if update all stores Sellin WD
                    if(wCountry.updateStoresSellinWDWeight) {
                        item.Weighted_Distribution_SellinWDWeight__c = wCountry.weightedDistributionSellinWDWeight;
                    }
                    storesUpdatedMap.put(item.Id, item);
                }
            }
            // check if update strats
            if (!this.storeStratsUpdatedMap.isEmpty()) {
                for(String key : this.storeStratsUpdatedMap.keySet()) {
                    Map<String, Orga_BU__c> stratStoreMap = this.storeStratsUpdatedMap.get(key);
                    List<String> strats = new List<String>(stratStoreMap.keySet());
                    Orga_BU__c store = stratStoreMap.values().get(0);
                    if(storesUpdatedMap.containsKey(store.Id)) {
                        store = storesUpdatedMap.get(store.Id);
                        store.Assortment_Strat__c = strats.get(0);
                    } else {
                        store.Assortment_Strat__c = strats.get(0);
                        storesUpdatedMap.put(store.Id, store);
                    }
                }                
            }
            
            // initializing data
            if (!storesUpdatedMap.isEmpty()) {
                
                if(!storesUpdatedMap.isEmpty()) {
                    if (checkUpdatibility(Orga_BU__c.SObjectType, orgaBUFields)) {
                        List<Database.SaveResult> results = Database.update(storesUpdatedMap.values(), false);
                    }
                }
                for(CountryWrapper item : wCountryMap.values()) {
                    item.StdSetControllerStores = null;
                }
                this.storeStratsUpdatedMap.clear();
                this.countryUpdatedWDMap.clear();
                this.storeUpdatedWDMap.clear();
                load();
            }
            ApexPages.Message successMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved);
            ApexPages.addMessage(successMsg);
        } catch (DmlException ex) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getMessage()));
        }
        return null;
    }
    
    public PageReference Cancel() {
        PageReference previousPage = new PageReference('/' + recordId );
        previousPage.setRedirect(true);
        return previousPage;
    }
    
    //** Mohammad **/
  	// Update Weight Distribution method
    public PageReference updateWeightDistribution() {
        return save();
    }
    
    /**
     * @description Set WD Sellout WD Weight OnStore Level. Event on WD Sellout WD Weight input field on country level.
     * @return PageReference
     **/
    public PageReference setWDSelloutWDWeight() {
        if(countryId == null) return null;
        CountryWrapper wCountry = wCountryMap.get(countryId);
        wCountry.updateStoresSelloutWDWeight = true;
        this.countryUpdatedWDMap.put(wCountry.country.Id, wCountry);
        for (StoreWrapper wStore : wCountry.wStores) {
            wStore.weightedDistributionSelloutWDWeight = wCountry.weightedDistributionSelloutWDWeight;
            this.storeUpdatedWDMap.put(wStore.store.Id, wStore);
        }
        return null;
    }
    
    /**
     * @description Set WD Sellin WD Weight On Store Level. Event on WD Sellin WD Weight input field on Country level.
     * @return PageReference
     **/
    public PageReference setWDSellinWDWeight() {
        if(countryId == null) return null;
        CountryWrapper wCountry = wCountryMap.get(countryId);
        wCountry.updateStoresSellinWDWeight = true;
        this.countryUpdatedWDMap.put(wCountry.country.Id, wCountry);
        for (StoreWrapper wStore : wCountry.wStores) {
            wStore.weightedDistributionSellinWDWeight = wCountry.weightedDistributionSellinWDWeight;
            this.storeUpdatedWDMap.put(wStore.store.Id, wStore);
        }
        return null;
    }
    
    /**
     * @description Set the WDs on store level on the first grid. (Event on WD Forecasting Assortment select list on store level)
     * @return PageReference
     **/
    public PageReference setWDForecastingForStore() {
        if(countryId == null || storeId == null) return null;
        CountryWrapper wCountry = wCountryMap.get(countryId);
        for (StoreWrapper wStore : wCountry.wStores) {
            if (wStore.store.Id == storeId) {
                // process update totals WD
                Decimal newWD = getWD(wStore);
                processUpdateStoresWD(wCountry, wStore, newWD);
                // fill stores updated Map
                if (wStore.weightedDistributionforecastingAss != null) {
                    // Calculate WD on store level.
                    fillStoreWD(wStore);
                }
                this.storeUpdatedWDMap.put(wStore.store.Id, wStore);
            }
        }
        return null;
    }
    
    /**
     * @description Set WD Forecasting Assortment On Store Level. Set WD Forcasting Assort. of all related stores. (Event on WD forecasting Assortment selected list on Country level)
     * @return PageReference
     **/
    public PageReference setWDForecastingForCountry() {
        if(countryId == null) return null;
        CountryWrapper wCountry = wCountryMap.get(countryId);
        wCountry.updateStoresWDForecasting = true;
        // Set WD Forcasting Assort. of all related stores.
        this.countryUpdatedWDMap.put(wCountry.country.Id, wCountry);
        
        Set<Id> updatedStoreIds = new Set<Id>();
        for (StoreWrapper wStore : wCountry.wStores) {
            if(wStore.weightedDistributionforecastingAss != wCountry.weightedDistributionforecastingAss) {
                wStore.weightedDistributionforecastingAss = wCountry.weightedDistributionforecastingAss;
                // process update totals WD
                Decimal newWD = getWD(wStore);
                processUpdateStoresWD(wCountry, wStore, newWD);
                // fill stores updated Map
                if(wStore.weightedDistributionforecastingAss != null) {
                    fillStoreWD(wStore);
                }
                this.storeUpdatedWDMap.put(wStore.store.Id, wStore);
                updatedStoreIds.add(wStore.store.Id);
            }
        }
        List<Orga_BU__c> storeList = [SELECT Id, Name, BU_Code__c, Format_Origin__c, Country_Zone_origin__c, Country_origin__c, Assortment_Strat__c,
                                      Weighted_Distribution_forecasting_Ass__c, Weighted_Distribution_Manual__c, Weighted_Distribution_SellIn_Fact__c,
                                      Weighted_Distribution_SellIn_Forecast__c, Weighted_Distribution_SellOut_Fact__c, Weighted_Distribution_SellOut_Forecast__c,
                                      Weighted_Distribution_SelloutWDWeight__c, Weighted_Distribution_SellinWDWeight__c, Weighted_Distribution_Weighted__c
                                      FROM Orga_BU__c
                                      WHERE RecordType.DeveloperName IN ('Store','Web')
                                      AND Country_origin__c =:countryId AND Id NOT IN :updatedStoreIds];
        // update all stores in country
        for(Orga_BU__c store : storeList) {
            if(!this.storeUpdatedWDMap.containsKey(store.Id)) {
                if(store.Weighted_Distribution_forecasting_Ass__c != wCountry.weightedDistributionforecastingAss) {
                    // fill store wrapper
                    StoreWrapper wStore = fillStoreWrapper(wCountry, store);
                    wStore.weightedDistributionforecastingAss = wCountry.weightedDistributionforecastingAss;
                    // process update totals WD
                    processUpdateStoresWD(wCountry, wStore, wStore.weightedDistributionValue);
                }
            } else {
                StoreWrapper wStore = this.storeUpdatedWDMap.get(store.Id);
                if(wStore.weightedDistributionforecastingAss != wCountry.weightedDistributionforecastingAss) {
                    wStore.weightedDistributionforecastingAss = wCountry.weightedDistributionforecastingAss;
                    // process update totals WD
                    Decimal newWD = getWD(wStore);
                    processUpdateStoresWD(wCountry, wStore, newWD);
                }
            }
        }
    	return null;
    }

    /**
     * @description Set the WD value on the footer. (Event on WD Manualinput on store level)
     * @return PageReference
     **/
    public PageReference setWDManualForCountry() {
        if(countryId == null) return null;
        CountryWrapper wCountry = wCountryMap.get(countryId);
        wCountry.weightedDistributionValue = wCountry.weightedDistributionManual;
        this.countryUpdatedWDMap.put(wCountry.country.Id, wCountry);
        return null;
    }
    
    /**
     * @description Set the WD values column. (Event on WD Manualinput on store level)
     * @return PageReference
     **/
    public PageReference setWDManualForStore() {
        if(countryId == null || storeId == null) return null;
        CountryWrapper wCountry = wCountryMap.get(countryId);
        for (StoreWrapper wStore : wCountry.wStores) {
            if (wStore.store.Id == storeId) {
                // process update totals WD
                processUpdateStoresWD(wCountry, wStore, wStore.weightedDistributionManual);
                // fill store updated Map
                wStore.weightedDistributionValue = wStore.weightedDistributionManual;
                this.storeUpdatedWDMap.put(wStore.store.Id, wStore);
            }
        }
    	return null;
    }
    
    // process update stores WD
    private void processUpdateStoresWD(CountryWrapper wCountry, StoreWrapper wStore, Decimal newWD) {
        Decimal initWD = 0;
        if(this.storeUpdatedWDMap.containsKey(wStore.store.Id)) {
            initWD = this.storeUpdatedWDMap.get(wStore.store.Id).weightedDistributionValue;
        } else {
            initWD = getInitWD(wStore.store, null);
        }
        if(newWD != initWD) {
            Map<String, Boolean> stratsMap = wStore.storeStratsMap.get(wStore.store.Id);
            for(String strat : stratsMap.keySet()) {
                if(stratsMap.get(strat) == true && wCountry.newStoresTotalWDMap.containsKey(strat)) {
                    // update WD for new strat
                    Decimal totalWD = wCountry.newStoresTotalWDMap.get(strat);
                    wCountry.newStoresTotalWDMap.put(strat, totalWD + (newWD - initWD));
                }
            }
            // calculate total WD
            if(wStore.weightedDistributionforecastingAss == 'Manual') {
                wCountry.totalWDManual = wCountry.totalWDManual + (newWD - initWD);
                wCountry.totalWD = wCountry.totalWD + (newWD - initWD);
            }
        }
    }
    
    /**
     * @description IF target is null THEN Get WD based on the BU Record Type (Country, Store, Assortment),
     *				ELSE Get WD store conditional by the country WD.
     * @param source, target
     * @return Decimal
     **/
    private Decimal getInitWD(Orga_BU__c source, Orga_BU__c target) {
        if (target == null)
            target = source;
    	Decimal WD = 0;
		if (source.Weighted_Distribution_forecasting_Ass__c == 'Sell Out (Fact)' && target.Weighted_Distribution_SellOut_Fact__c != null) {
        	WD = target.Weighted_Distribution_SellOut_Fact__c;
        } else if(source.Weighted_Distribution_forecasting_Ass__c == 'Sell Out (Forecast)' && target.Weighted_Distribution_SellOut_Forecast__c != null) {
        	 WD = target.Weighted_Distribution_SellOut_Forecast__c;
        } else if(source.Weighted_Distribution_forecasting_Ass__c == 'Sell In (Fact)' && target.Weighted_Distribution_SellIn_Fact__c != null) {
        	WD = target.Weighted_Distribution_SellIn_Fact__c;
        } else if(source.Weighted_Distribution_forecasting_Ass__c == 'Sell In (Forecast)' && target.Weighted_Distribution_SellIn_Forecast__c != null) {
        	WD = target.Weighted_Distribution_SellIn_Forecast__c;
        } else if(source.Weighted_Distribution_forecasting_Ass__c == 'Manual' && target.Weighted_Distribution_Manual__c != null) {
        	WD = target.Weighted_Distribution_Manual__c;
        }
    	return WD;
    }
    
    private void fillStoreWD(StoreWrapper wStore) {
        // check updated WD
        if(this.storeUpdatedWDMap.containsKey(wStore.store.Id)) {
            StoreWrapper updatedStoreWD = this.storeUpdatedWDMap.get(wStore.store.Id);
            wStore.weightedDistributionforecastingAss = updatedStoreWD.weightedDistributionforecastingAss;
            wStore.weightedDistributionSelloutWDWeight = updatedStoreWD.weightedDistributionSelloutWDWeight;
            wStore.weightedDistributionSellinWDWeight = updatedStoreWD.weightedDistributionSellinWDWeight;
            wStore.weightedDistributionManual = updatedStoreWD.weightedDistributionManual;
        }
        wStore.weightedDistributionValue = getWD(wStore);
    }
    
    private Decimal getWD(StoreWrapper wStore) {
        Decimal WD = 0;
        if (wStore.weightedDistributionforecastingAss == 'Sell Out (Fact)' && wStore.store.Weighted_Distribution_SellOut_Fact__c != null) {
            WD = wStore.store.Weighted_Distribution_SellOut_Fact__c;
        } else if(wStore.weightedDistributionforecastingAss == 'Sell Out (Forecast)' && wStore.store.Weighted_Distribution_SellOut_Forecast__c != null) {
            WD = wStore.store.Weighted_Distribution_SellOut_Forecast__c;
        } else if(wStore.weightedDistributionforecastingAss == 'Sell In (Fact)' && wStore.store.Weighted_Distribution_SellIn_Fact__c != null) {
            WD = wStore.store.Weighted_Distribution_SellIn_Fact__c;
        } else if(wStore.weightedDistributionforecastingAss == 'Sell In (Forecast)' && wStore.store.Weighted_Distribution_SellIn_Forecast__c != null) {
            WD = wStore.store.Weighted_Distribution_SellIn_Forecast__c;
        } else if(wStore.weightedDistributionforecastingAss == 'Manual' && wStore.weightedDistributionManual != null) {
            WD = wStore.weightedDistributionManual;
        }
        return WD;
    }
        
    /* Wrapper Classes for country */
    public class CountryWrapper {
        public Orga_BU__c country {get; set;}
        public String weightedDistributionforecastingAss {get; set;}
        public decimal weightedDistributionSelloutWDWeight {get; set;}        
        public String sWeightedDistributionSelloutWDWeight {
            get {
                return NegoptimHelper.formatDecimalValue(this.weightedDistributionSelloutWDWeight, 2);
            }
            set;
        }
        public decimal weightedDistributionSellinWDWeight {get; set;}
        public String sWeightedDistributionSellinWDWeight {
            get {
                return NegoptimHelper.formatDecimalValue(this.weightedDistributionSellinWDWeight, 2);
            }
            set;
        }
        public decimal weightedDistributionManual {get; set;}
        public String sWeightedDistributionManual {
            get {
                return NegoptimHelper.formatDecimalValue(this.weightedDistributionManual, 2);
            }
            set;
        }
        public Decimal weightedDistributionValue {get; set;}        
        public Boolean updateStoresWDForecasting {get; set;}
        public Boolean updateStoresSellinWDWeight {get; set;}
        public Boolean updateStoresSelloutWDWeight {get; set;}
        
        public List<StoreWrapper> wStores {get; set;}
        public String soqlStores {get; set;}
        public Integer totalStores {get; set;}
                
        public List<Orga_BU__c> assortmentClusters {get; set;}
        public Map<String, String> countryHeaderMap {get; set;}
        public Map<String, Boolean> countryStratsMap {get; set;}
        public Map<String, Decimal> assortmentWDMap {get; set;}
        public Map<String, Decimal> currentStoresTotalWDMap {get; set;}
        public Map<String, Decimal> newStoresTotalWDMap {get; set;}
        public Map<String, Integer> currentStratsTotalMap {get; set;}
        public Map<String, Integer> newStratsTotalMap {get; set;}
                
        //**Start of Mohammad Code**/
        public decimal totalWD {get; set;}
        public String sTotalWD {
            get {
                return NegoptimHelper.formatDecimalValue(this.totalWD, 2);
            }
            set;
        }
        public decimal totalWDSellOutFact {get; set;}
        public String sTotalWDSellOutFact {
            get {
                return NegoptimHelper.formatDecimalValue(this.totalWDSellOutFact, 2);
            }
            set;
        }
        public decimal totalWDSellOutForecast {get; set;}
        public String sTotalWDSellOutForecast {
            get {
                return NegoptimHelper.formatDecimalValue(this.totalWDSellOutForecast, 2);
            }
            set;
        }
        public decimal totalWDSellInFact {get; set;}
        public String sTotalWDSellInFact {
            get {
                return NegoptimHelper.formatDecimalValue(this.totalWDSellInFact, 2);
            }
            set;
        }
        public decimal totalWDSellInForecast {get; set;}
        public String sTotalWDSellInForecast {
            get {
                return NegoptimHelper.formatDecimalValue(this.totalWDSellInForecast, 2);
            }
            set;
        }
        public decimal totalWDManual {get; set;}
        public String sTotalWDManual {
            get {
                return NegoptimHelper.formatDecimalValue(this.totalWDManual, 2);
            }
            set;
        }
    	
        // pagination
        public Integer recPerPageStores {get; set;}
        public Integer noOfStoresRecords {get; set;}
        
        public CountryWrapper(Orga_BU__c country, Set<String> availableStrats) {
        	this.country = country;
            this.wStores = new List<StoreWrapper>();
            this.updateStoresWDForecasting = false;
            this.updateStoresSellinWDWeight = false;
            this.updateStoresSelloutWDWeight = false;
            this.totalStores = 0;
            this.currentStratsTotalMap = new Map<String, Integer>();
            this.newStratsTotalMap = new Map<String, Integer>();
            
            this.assortmentClusters = new List<Orga_BU__c>();
            this.countryHeaderMap = new Map<String, String>();
            this.countryStratsMap = new Map<String, Boolean>();
            this.assortmentWDMap = new Map<String, Decimal>();
            this.currentStoresTotalWDMap = new Map<String, Decimal>();
            this.newStoresTotalWDMap = new Map<String, Decimal>();
            for(String strat : availableStrats) {
                this.countryHeaderMap.put(strat, '');
                this.countryStratsMap.put(strat, false);
                this.assortmentWDMap.put(strat, -1);
            }
            this.totalWD = 0;
            this.totalWDSellOutFact = 0;
            this.totalWDSellOutForecast = 0;
            this.totalWDSellInFact = 0;
            this.totalWDSellInForecast = 0;
            this.totalWDManual = 0;
            this.recPerPageStores = 10;
            this.noOfStoresRecords = 0;
            
            init();
        }
        
        private void init() {
            this.weightedDistributionforecastingAss = this.country.Weighted_Distribution_forecasting_Ass__c != null ? this.country.Weighted_Distribution_forecasting_Ass__c : null;
            this.weightedDistributionSelloutWDWeight = this.country.Weighted_Distribution_SelloutWDWeight__c != null ? this.country.Weighted_Distribution_SelloutWDWeight__c : 0;
            this.weightedDistributionSellinWDWeight = this.country.Weighted_Distribution_SellinWDWeight__c != null ? this.country.Weighted_Distribution_SellinWDWeight__c : 0;
            this.weightedDistributionManual = this.country.Weighted_Distribution_Manual__c != null ? this.country.Weighted_Distribution_Manual__c : 0;
        }
        
        // paging through the stores Grid
        public ApexPages.StandardSetController StdSetControllerStores {
            get {
                if(StdSetControllerStores == null) {
                    if(String.isNotBlank(soqlStores)) {
                        StdSetControllerStores = new ApexPages.StandardSetController(Database.getQueryLocator(soqlStores));
                        StdSetControllerStores.setPageSize(recPerPageStores);
                        this.noOfStoresRecords = StdSetControllerStores.getResultSize();
                    } else {
                        StdSetControllerStores = new ApexPages.StandardSetController(new List<Orga_BU__c>());
                    }
                }
                return StdSetControllerStores;
            }
            set;
        }
    }
    
    public class StoreWrapper {
        public Orga_BU__c store {get; set;}
        
        public Decimal weightedDistributionValue {get; set;}
        public Map<Id, Map<String, Boolean>> storeStratsMap {get; set;}
        public String weightedDistributionforecastingAss {get; set;}
        public decimal weightedDistributionSelloutWDWeight {get; set;}
        public String sWeightedDistributionSelloutWDWeight {
            get {
                return NegoptimHelper.formatDecimalValue(this.weightedDistributionSelloutWDWeight, 2);
            }
            set;
        }
        public decimal weightedDistributionSellinWDWeight {get; set;}
        public String sWeightedDistributionSellinWDWeight {
            get {
                return NegoptimHelper.formatDecimalValue(this.weightedDistributionSellinWDWeight, 2);
            }
            set;
        }
        public decimal weightedDistributionManual {get; set;}
        public String sWeightedDistributionManual {
            get {
                return NegoptimHelper.formatDecimalValue(this.weightedDistributionManual, 2);
            }
            set;
        }
        
        public StoreWrapper(Orga_BU__c store) {
            this.store = store;
            this.weightedDistributionValue = 0;
            this.storeStratsMap = new Map<Id, Map<String, Boolean>>();
            init();
        }
        
        private void init() {
            this.weightedDistributionforecastingAss = this.store.Weighted_Distribution_forecasting_Ass__c != null ? this.store.Weighted_Distribution_forecasting_Ass__c : null;
            this.weightedDistributionSelloutWDWeight = this.store.Weighted_Distribution_SelloutWDWeight__c != null ? this.store.Weighted_Distribution_SelloutWDWeight__c : 0;
            this.weightedDistributionSellinWDWeight = this.store.Weighted_Distribution_SellinWDWeight__c != null ? this.store.Weighted_Distribution_SellinWDWeight__c : 0;
            this.weightedDistributionManual = this.store.Weighted_Distribution_Manual__c != null ? this.store.Weighted_Distribution_Manual__c : 0;
        }
    }
}