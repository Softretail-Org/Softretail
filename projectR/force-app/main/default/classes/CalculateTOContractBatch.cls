/**
 * Batchable class used to calculate TOs Fact, Tos FX, Qtys, Sales and FrontMargins for contracts.
 **/
public with sharing class CalculateTOContractBatch implements Database.Batchable<sObject>, Database.stateful {
	
	private NegoptimBatch nb;
	public final String query;
	public final Id country;
    public final List<Id> contractIds;
	public final Integer year;
    public Set<String> errors;
	
	// Constructor.
   	public CalculateTOContractBatch(String startedFrom, Id countryId, List<Id> cId, Integer y) {
   		this.nb = new NegoptimBatch('Contracts TO Calculation', NegoptimBatch.BatchType.Stateful, startedFrom);
   		this.country = countryId;
        this.contractIds = cId;
   		this.year = y;
   		// Declare the query to get contracts.
   		String q = 'SELECT Id, Name, Supplier_Nego_Scope__c, Contract_BDate__c, Contract_EDate__c,';
   		q += '  Contract_BU__c, CurrencyIsoCode, Reference_Year__c';
   		q += ' FROM Contract__c';
   		q += ' WHERE Contract_Type__c = \'Contract\'';
        if(this.country != null) {
            q += ' AND Contract_BU__c = \'' + country + '\'';      
        }
        if(this.contractIds != null && this.contractIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(this.contractIds, '\',\'') +'\')';
        }
        else if(year != null){
             q += ' AND Reference_Year__c = ' + this.year + '';
        }
   		this.query = q;
        // push inputs to log
        nb.logParameter('counrty', this.country);
        nb.logParameter('contractIds', this.contractIds);
        nb.logParameter('year', this.year);
        nb.logParameter('query', this.query);
   	}
	// Start method implementation.
   	public Database.QueryLocator start(Database.BatchableContext BC) {
      	return Database.getQueryLocator(query);
   	}
	// Execute method implementation.
   	public void execute(Database.BatchableContext BC, List<Contract__c> scope) {
        // Load map of currencies with exchange rate.
        Map<String, Double> currencies = NegoptimHelper.getCurrencyMap();
        Set<Id> setOfNS = new Set<Id>();
        Set<Id> setOfBU = new Set<Id>();
        Set<Integer> setOfYear = new Set<Integer>();
        for(Contract__c item : scope) {
            // Fill the Set of NS
            if(!setOfNS.contains(item.Supplier_Nego_Scope__c)) {
                setOfNS.add(item.Supplier_Nego_Scope__c);
            }
            // Fill the Set of BU
            if(!setOfBU.contains(item.Contract_BU__c)) {
                setOfBU.add(item.Contract_BU__c);
            }
            // Fill the Set of Years
            Integer referenceYear = Integer.valueOf(item.Reference_Year__c);
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
                                                SUM(Qty12__c) qty12,
                                                
                                                SUM(Sales_M1__c) sales1,
                                                SUM(Sales_M2__c) sales2,
                                                SUM(Sales_M3__c) sales3,
                                                SUM(Sales_M4__c) sales4,
                                                SUM(Sales_M5__c) sales5,
                                                SUM(Sales_M6__c) sales6,
                                                SUM(Sales_M7__c) sales7,
                                                SUM(Sales_M8__c) sales8,
                                                SUM(Sales_M9__c) sales9,
                                                SUM(Sales_M10__c) sales10,
                                                SUM(Sales_M11__c) sales11,
                                                SUM(Sales_M12__c) sales12,
                                                
                                                SUM(Front_Margin_M1__c) frontMargin1,
                                                SUM(Front_Margin_M2__c) frontMargin2,
                                                SUM(Front_Margin_M3__c) frontMargin3,
                                                SUM(Front_Margin_M4__c) frontMargin4,
                                                SUM(Front_Margin_M5__c) frontMargin5,
                                                SUM(Front_Margin_M6__c) frontMargin6,
                                                SUM(Front_Margin_M7__c) frontMargin7,
                                                SUM(Front_Margin_M8__c) frontMargin8,
                                                SUM(Front_Margin_M9__c) frontMargin9,
                                                SUM(Front_Margin_M10__c) frontMargin10,
                                                SUM(Front_Margin_M11__c) frontMargin11,
                                                SUM(Front_Margin_M12__c) frontMargin12
                                                
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
                    wTotalPurchases.totalQty1PerMonth[i] = (Decimal) ar.get('qty' + j);
                    wTotalPurchases.totalSales1PerMonth[i] = (Decimal) ar.get('sales' + j);
                    wTotalPurchases.totalFrontMargin1PerMonth[i] = (Decimal) ar.get('frontMargin' + j);
                }
                wTotalPurchasesList.add(wTotalPurchases);
            }
        }
 		List<WrapperContractPurchase> wContractPurchaseList = new List<WrapperContractPurchase>();
        // Set TO for contracts based on NS / BU / Months range.
        for(Contract__c contract : scope) {
            Double conversionRate = currencies.get(contract.CurrencyIsoCode);
            WrapperContractPurchase wcp = new WrapperContractPurchase(contract, conversionRate);
            // Get BU list related to the condition
            if(businessUnitsMap.containsKey(contract.Contract_BU__c))
                wcp.contractBUIds = businessUnitsMap.get(contract.Contract_BU__c);
            for(WrapperTotalPurchases wtp : wTotalPurchasesList) {
                if(contract.Supplier_Nego_Scope__c == wtp.NSId && wcp.contractBUIds.contains(wtp.BUId)) {
                    wcp.purchases.add(wtp);
                }
            }
            wContractPurchaseList.add(wcp);
        }
        // Contracts to be updated.
        List<Contract__c> contractsListToBeUpdated = new List<Contract__c>();
        for(WrapperContractPurchase wcp : wContractPurchaseList) {
            Contract__c contract = wcp.setTO();
            contractsListToBeUpdated.add(contract);
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            String[] fields = new String[] {NegoptimHelper.normalizeAPIName('TO1_Fact__c'), NegoptimHelper.normalizeAPIName('TO1_FX__c'),
                NegoptimHelper.normalizeAPIName('Qty1_Fact__c'), NegoptimHelper.normalizeAPIName('Sales_M1__c'),
                NegoptimHelper.normalizeAPIName('Front_Margin_M1__c')};
            if(NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, fields)) {
                List<Database.SaveResult> results = Database.update(contractsListToBeUpdated, false);
                nb.logResults(results, contractsListToBeUpdated);
            }
        } catch(DMLException e) {
            Database.rollback(sp);
        } catch(Exception ex) {
            nb.logError('Exception: ' + ex.getMessage() + ' - ' + ex.getLineNumber());
            Database.rollback(sp);
        }
        nb.incrementBatchIndex();
    }
	// Finish method implementation.
    public void finish(Database.BatchableContext BC) {
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
    }
    
   	/* Wrapper class for contracts + purchases. */
    public class WrapperContractPurchase {
    	
        public Contract__c contract {get;set;}
        public List<WrapperTotalPurchases> purchases {get;set;}
        public Double conversionRate {get;set;}
        public Set<Id> contractBUIds {get;set;}
        
        public WrapperContractPurchase(Contract__c c, Double d) {
            contract = c;
            purchases = new List<WrapperTotalPurchases>();
            conversionRate = d;
            contractBUIds = new Set<Id>();
        }
        
        public Contract__c setTO() {
            // Set total of all months.
            Decimal[] sumTO = new List<Decimal>(), sumTOForecast = new List<Decimal>(), sumQty = new List<Decimal>(),
        		sumSales = new List<Decimal>(), sumFrontMargin = new List<Decimal>();
            for(Integer i = 0; i < 12; i++) {
                sumTO.add(0);
                sumTOForecast.add(0);
                sumQty.add(0);
                sumSales.add(0);
                sumFrontMargin.add(0);
            }
            // Get the first and last month related to the contract.
            Integer firstMonth = contract.Contract_BDate__c != null ? contract.Contract_BDate__c.month() : 1; // January
            Integer lastMonth = contract.Contract_EDate__c != null ? contract.Contract_EDate__c.month() : 12; // December
            for(WrapperTotalPurchases purchase : purchases) {
                for(Integer i = firstMonth - 1; i < lastMonth; i++) {
                    sumTO[i] += purchase.totalActualPerMonth[i] != null ? purchase.totalActualPerMonth[i] : 0;
                    sumTOForecast[i] += purchase.totalForecastPerMonth[i] != null ? purchase.totalForecastPerMonth[i] : 0;
                    sumQty[i] += purchase.totalQty1PerMonth[i] != null ? purchase.totalQty1PerMonth[i] : 0;
                    sumSales[i] += purchase.totalSales1PerMonth[i] != null ? purchase.totalSales1PerMonth[i] : 0;
                    sumFrontMargin[i] += purchase.totalFrontMargin1PerMonth[i] != null ? purchase.totalFrontMargin1PerMonth[i] : 0;
                }
            }
            for(Integer i = firstMonth; i < lastMonth + 1; i++) {
                String fieldTO = 'TO' + i + '_Fact__c'; // TO1_Fact__c
                String fieldTOForecast = 'TO' + i + '_FX__c';
                String fieldQty = 'Qty' + i + '_Fact__c'; //Qty1_Fact__c
                String fieldSales = 'Sales_M' + i + '__c';
                String fieldFrontMargin = 'Front_Margin_M' + i + '__c';
                contract.put(fieldTO, sumTO[i-1] * conversionRate);
                contract.put(fieldTOForecast, sumTOForecast[i-1] * conversionRate);
                contract.put(fieldQty, sumQty[i-1]);
                contract.put(fieldSales, sumSales[i-1] * conversionRate);
                contract.put(fieldFrontMargin, sumFrontMargin[i-1] * conversionRate);
            }
            return contract;
        }
    }
    
    /* Wrapper class for purchases. */
    public class WrapperTotalPurchases {
    	
        public Id BUId {get;set;}
        public Id NSId {get;set;}
        // List of decimal number for 1 to 12 represent each month of the year.
        public Decimal[] totalActualPerMonth {get;set;}
        public Decimal[] totalForecastPerMonth {get;set;}
        public Decimal[] totalQty1PerMonth {get;set;}
        public Decimal[] totalSales1PerMonth {get;set;}
        public Decimal[] totalFrontMargin1PerMonth {get;set;}
        
        public WrapperTotalPurchases() {
            totalActualPerMonth = new List<Decimal>();
            totalForecastPerMonth = new List<Decimal>();
            totalQty1PerMonth = new List<Decimal>();
            totalSales1PerMonth = new List<Decimal>();
            totalFrontMargin1PerMonth = new List<Decimal>();
            for(Integer i = 0; i < 12; i++) {
                totalActualPerMonth.add(0);
                totalForecastPerMonth.add(0);
                totalQty1PerMonth.add(0);
                totalSales1PerMonth.add(0);
                totalFrontMargin1PerMonth.add(0);
            }
        }
    }
}