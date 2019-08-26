/**
 * Batchable class used to calculate Base TO for contract conditions.
 **/
public with sharing class CalculateBaseTOBatch implements Database.Batchable<SObject> {
    
    private NegoptimBatch nb;
    public final String query;
    public final Id country;
    public final List<Id> contractIds;
    public final List<Id> conditionIds;
    public final Integer year;
	
    // Constructor.
    public CalculateBaseTOBatch(String startedFrom, Id countryId, List<Id> cIds, List<Id> conditionIds, Integer y) {
        this.nb = new NegoptimBatch('Conditions TO Calculation', NegoptimBatch.BatchType.Stateless, startedFrom);
        this.country = countryId;
        this.contractIds = cIds;
        this.conditionIds = conditionIds;
        this.year = y;
        // Declare the query to get conditions.
        String q = 'SELECT Id, Name, CurrencyIsoCode, Disc_BDate__c, Disc_EDate__c, Product_Scope__c, BU_Scope__c,';
        q += ' Value_amt__c, Value_per__c, Y_Actu__c, Condition_Type__c, Already_Invoiced__c, BU_Scope__r.Business_Unit_Type__c';
        q += ' FROM Contract_Discount__c';       
        q += ' WHERE Contract__r.Contract_Type__c = \'Contract\'';
        q += ' AND Respects_Contract_Scope__c = False';
        if(this.country != null) {
            q += ' AND Contract__r.Contract_BU__c = \'' + this.country + '\'';      
        }
        if(this.contractIds != null && this.contractIds.size() > 0) {
            q += ' AND Contract__c IN (\'' + String.join(this.contractIds, '\',\'') +'\')';
        }
        if(this.conditionIds != null && this.conditionIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(this.conditionIds, '\',\'') +'\')';
        }
        else if(year != null) {
             q += ' AND Contract__r.Reference_Year__c = ' + year + '';
        }
        this.query = q;
        
        // push inputs to log
        nb.logParameter('counrty', this.country);
        nb.logParameter('contractIds', this.contractIds);
        nb.logParameter('conditionIds', this.conditionIds);
        nb.logParameter('year', this.year);
        nb.logParameter('query', this.query);
    }
	// Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // Execute method.
    public void execute(Database.BatchableContext bc, List<Contract_Discount__c> scope) {
        List<Contract_Discount__c> conditionsList = scope;
        // Load map of currencies with exchange rate.
        Map<String, Double> currencies = NegoptimHelper.getCurrencyMap();
        Set<Id> setOfNS = new Set<id>();
        Set<Id> setOfBU = new Set<id>();
        Set<Integer> setOfYear = new Set<Integer>();
        for(Contract_Discount__c item : conditionsList) {
            // Fill the Set of NS
            if(!setOfNS.contains(item.Product_Scope__c)) {
                setOfNS.add(item.Product_Scope__c);
            }
            // Fill the Set of BU
            if(!setOfBU.contains(item.BU_Scope__c)) {
                setOfBU.add(item.BU_Scope__c);
            }
            // Fill the Set of Years
            Integer referenceYear = Integer.valueOf(item.Disc_BDate__c.Year());
            if(!setOfYear.contains(referenceYear)) {
                setOfYear.add(referenceYear);
            }
        }
        // Load Map of BUs
        Map<Id, Set<Id>> businessUnitsMap = NegoptimHelper.getBUChildrenMap(setOfBU);
        Set<Id> businessUnitsSet = new Set<Id>();
        for(Id key : businessUnitsMap.keySet()) {
            for(Id item : businessUnitsMap.get(key)) {
                businessUnitsSet.add(item);
            }
        }
        // Get total month from DB Grouped by BU.
        List<WrapperTotalPurchases> wTotalPurchasesList = new List<WrapperTotalPurchases>();
        for(Id NS : setOfNS) {
            // Query the Sum of TOs for the matching criteria.
            AggregateResult[] groupedResults = [SELECT BU__c bu,
                                                SUM(TO1__c) total1,
                                                SUM(TO2__c) total2,
                                                SUM(TO3__c) total3,
                                                SUM(TO4__c) total4,
                                                SUM(TO5__c) total5,
                                                SUM(TO6__c) total6,
                                                SUM(TO7__c) total7,
                                                SUM(TO8__c) total8,
                                                SUM(TO9__c) total9,
                                                SUM(TO10__c) total10,
                                                SUM(TO11__c) total11,
                                                SUM(TO12__c) total12,
                                                SUM(FX1__c) forecast1,
                                                SUM(FX2__c) forecast2,
                                                SUM(FX3__c) forecast3,
                                                SUM(FX4__c) forecast4,
                                                SUM(FX5__c) forecast5,
                                                SUM(FX6__c) forecast6,
                                                SUM(FX7__c) forecast7,
                                                SUM(FX8__c) forecast8,
                                                SUM(FX9__c) forecast9,
                                                SUM(FX10__c) forecast10,
                                                SUM(FX11__c) forecast11,
                                                SUM(FX12__c) forecast12,
                                                SUM(Qty1__c) qty1,
                                                SUM(Qty2__c) qty2,
                                                SUM(Qty3__c) qty3,
                                                SUM(Qty4__c) qty4,
                                                SUM(Qty5__c) qty5,
                                                SUM(Qty6__c) qty6,
                                                SUM(Qty7__c) qty7,
                                                SUM(Qty8__c) qty8,
                                                SUM(Qty9__c) qty9,
                                                SUM(Qty10__c) qty10,
                                                SUM(Qty11__c) qty11,
                                                SUM(Qty12__c) qty12
                                                FROM Purchases_Flow_PG__c
                                                WHERE PG__c IN (SELECT Sup_PG__c
                                                				FROM Sup_NS_PG__c
                                                				WHERE Sup_sup_NegoScope__c = :NS)
                                                AND BU__c IN :businessUnitsSet
                                                AND Flow_Type__c IN (1, 2) // Get only the direct flows from supplier (1: Store to Supplier, 2: Warehouse to Supplier)
                                                AND DC__c = null
                                                AND Year__c = :setOfYear
                                                GROUP BY BU__c];
            for (AggregateResult ar : groupedResults) {
                WrapperTotalPurchases wTotalPurchases = new WrapperTotalPurchases();
                wTotalPurchases.NSId = NS;
                wTotalPurchases.BUId = (Id) ar.get('bu');
                Integer j = 0;
                for(Integer i = 0; i < 12; i++) {
                    j = i + 1;
                    wTotalPurchases.totalActualPerMonth[i] = (Decimal) ar.get('total' + j);
                    wTotalPurchases.totalForecastPerMonth[i] = (Decimal) ar.get('forecast' + j);
                    wTotalPurchases.totalQtyPerMonth[i] = (Decimal) ar.get('qty' + j);
                }
                wTotalPurchasesList.add(wTotalPurchases);
            }
        }
        List<WrapperConditionPurchase> wConditionPurchaseList = new List<WrapperConditionPurchase>();
        // Set TO for conditions based on NS / BU / Months range.
        for(Contract_Discount__c condition : conditionsList) {
            Double conversionRate = currencies.get(condition.CurrencyIsoCode);
            WrapperConditionPurchase wcp = new WrapperConditionPurchase(condition, conversionRate);
            // Get BU list related to the condition
            if(businessUnitsMap.containsKey(condition.BU_Scope__c))
                wcp.conditionBUIds = businessUnitsMap.get(condition.BU_Scope__c);
            for(WrapperTotalPurchases wtp : wTotalPurchasesList) {
                if(condition.Product_Scope__c == wtp.NSId && wcp.conditionBUIds.contains(wtp.BUId)) {
                    wcp.purchases.add(wtp);
                }
            }
            wConditionPurchaseList.add(wcp);
        }
        // Conditions to be updated.
        List<Contract_Discount__c> conditionsListToBeUpdated = new List<Contract_Discount__c>();
        for(WrapperConditionPurchase wcp : wConditionPurchaseList) {
            Contract_Discount__c condition = wcp.setTO();
            conditionsListToBeUpdated.add(condition);
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
        	String[] fields = new String[] {NegoptimHelper.normalizeAPIName('Base_TO_Actual__c'), NegoptimHelper.normalizeAPIName('Base_Quantity_Actual__c')};
            if(NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, fields)) {
	            // update YTD for all conditions related to the current contract
	            update conditionsListToBeUpdated;
            }
        } catch(DMLException e) {
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
            Database.rollback(sp);
        } catch(Exception ex) {
            nb.logError('Exception: ' + ex.getMessage() + ' - ' + ex.getLineNumber());
            Database.rollback(sp);
        }
        nb.saveLog(bc);
    }
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        // Get Country Name
        String countryName = 'N/A';
        try {
            if(country != null)
                countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :country LIMIT 1].Name;
        } catch(DmlException e) {
            nb.logError('Exception: ' + e.getDMLMessage(0) + ' - ' + e.getLineNumber());
        }
        String customSubject = nb.getBatchName() + ' - ' + countryName + '/' + year + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
        // Execute Dispatching Batch
        if(nb.getStartedFrom().equalsIgnoreCase('SellinToPurchaseBatch')) {
            Database.executeBatch(new DispatchingBatch('CalculateBaseTOBatch', null, this.contractIds, this.conditionIds, null));
        }
    }
    
    /* Wrapper class for conditions + purchases. */
    public class WrapperConditionPurchase {
    	
        public Contract_Discount__c condition {get;set;}
        public List<WrapperTotalPurchases> purchases {get;set;}
        public Double conversionRate {get;set;}
        public Set<Id> conditionBUIds {get;set;}
        
        public WrapperConditionPurchase(Contract_Discount__c c, Double d) {
            condition = c;
            purchases = new List<WrapperTotalPurchases>();
            conversionRate = d;
            conditionBUIds = new Set<Id>();
        }
        
        public Contract_Discount__c setTO() {
            // Set total of all months.
            Decimal baseTOActuel = 0, baseTOForecast = 0, quantityActual = 0;
            // Get the first and last month related to the condition.
            Integer firstMonth = condition.Disc_BDate__c != null ? condition.Disc_BDate__c.month() : 1 /* January */;
            Integer lastMonth = condition.Disc_EDate__c != null ? condition.Disc_EDate__c.month() : 12 /* December */;
            for(WrapperTotalPurchases purchase : purchases) {
                for(Integer i = firstMonth - 1; i < lastMonth; i++) {
                    baseTOActuel += purchase.totalActualPerMonth[i] != null ? purchase.totalActualPerMonth[i] : 0;
                    baseTOForecast += purchase.totalForecastPerMonth[i] != null ? purchase.totalForecastPerMonth[i] : 0;
                    quantityActual += purchase.totalQtyPerMonth[i] != null ? purchase.totalQtyPerMonth[i] : 0;
                }
            }
            // Stock Base_TO_Actual__c.
            condition.Base_TO_Actual__c = baseTOActuel * conversionRate;
            // Stock Base_TO_Forecast__c.
            condition.Base_TO_Forecast__c = baseTOForecast * conversionRate;
            condition.Base_Quantity_Actual__c = quantityActual;
            return condition;
        }
    }
    
    /* Wrapper class for purchases. */
    public class WrapperTotalPurchases {
        public Id BUId {get;set;}
        public Id NSId {get;set;}
        // List of decimal number for 1 to 12 represent each month of the year.
        public Decimal[] totalActualPerMonth {get;set;}
        public Decimal[] totalForecastPerMonth {get;set;}
        public Decimal[] totalQtyPerMonth {get;set;}
        
        public WrapperTotalPurchases() {
            totalActualPerMonth = new List<Decimal>();
            totalForecastPerMonth = new List<Decimal>();
            totalQtyPerMonth = new List<Decimal>();
            for(Integer i = 0; i < 12; i++) {
                totalActualPerMonth.add(0);
                totalForecastPerMonth.add(0);
                totalQtyPerMonth.add(0);
            }
        }
    }
}