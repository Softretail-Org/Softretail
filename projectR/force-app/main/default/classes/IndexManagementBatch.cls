/**
 * @description Batchable Apex class responsible for performing the "Index Management" procedure.
 **/
public with sharing class IndexManagementBatch implements Database.Batchable<SObject>, Database.Stateful {

	private NegoptimBatch nb;
	private String query;
	private Id country;
	private Integer year;
	
	// Constructor.
    public IndexManagementBatch(Id cId, List<Id> contractIds, Integer y) {
    	// Create instance of NegoptimBatch.
    	nb = new NegoptimBatch('Index Management', NegoptimBatch.BatchType.Stateful, 'itself');
    	// Set global variables.
    	country = cId;
    	year = y;
        // Buil query.
        String q = 'SELECT c.Rise_Rate__c, c.Depreciation_Rate__c, c.Markdown_Rate_Break__c, c.Markdown_Rate_Promo__c, c.Markdown_Rate_Theft__c,';
        q += ' c.Index1__c, c.Index1_perc__c, c.Index2__c, c.Index2_perc__c, c.Index3__c, c.Index3_perc__c, c.Index4__c, c.Index4_perc__c,';
        q += ' c.Total_TO_Fact__c,';
        q += ' (Select Value_per__c, Value_amt__c, Index__c, Contract__r.Total_TO_Fact__c, Condition_Type__r.index__c FROM Contract_Discounts__r )'; // WHERE Condition_Type__r.Condition_Mode__c = \'%\'
        q += ' FROM Contract__c c';
        q += ' WHERE c.Status__c IN (\'Signed\')';
        if (country != null) q += ' AND c.Contract_BU__c = \'' + country + '\'';
        if (contractIds != null && contractIds.size() > 0) q += ' AND c.Id IN (\'' + String.join(contractIds, '\',\'') +'\')';
        if (year != null) q += ' AND CALENDAR_YEAR(c.Contract_BDate__c) = ' + year + '';
        // Set global variable.
        query = q;
        // Set Logs.
        nb.logParameter('query', this.query);
        nb.logParameter('country', this.country);
        nb.logParameter('contractIds', contractIds);
        nb.logParameter('year', this.year);
    }
    
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    // Execute method.
    public void execute(Database.BatchableContext bc, List<Contract__c> scope) {
    	IndexManagementWrapper wIndexManagement;
    	List<IndexManagementWrapper> wIndexManagements = new List<IndexManagementWrapper>();
    	// Iterate over the scope in order to fill the list of the Index Management Wrapper.
    	for (Contract__c contract : scope) {
    		wIndexManagement = new IndexManagementWrapper(contract);
    		wIndexManagements.add(wIndexManagement);
    	}
    	List<Contract__c> cToUpdate = new List<Contract__c>();
    	// Iterate over the list of Index Management Wrapper in order to set the Indexes values.
    	for (IndexManagementWrapper wItem : wIndexManagements) {
    		if (wItem.indexes.size() > 0) {
    			wItem.contract.Index1__c = wItem.indexes[0];
	    		wItem.contract.Index2__c = wItem.indexes[1];
	    		wItem.contract.Index3__c = wItem.indexes[2];
	    		wItem.contract.Index4__c = wItem.indexes[3];
	    		cToUpdate.add(wItem.contract);
    		}
    	}
    	try {
    		// Check updatibility on Index1__c, Index2__c, Index3__c and Index4__c contract fields.
            String[] contractFields = new String[] {
					        		NegoptimHelper.normalizeAPIName('Index1__c'), NegoptimHelper.normalizeAPIName('Index2__c'),
					            	NegoptimHelper.normalizeAPIName('Index3__c'), NegoptimHelper.normalizeAPIName('Index4__c')};
        	Boolean isUpdatable = NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractFields);
    		// Update the list of modified contracts.
    		if (isUpdatable) update cToUpdate;
    	} catch (DmlException e) {
     		nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
     	}
    }
    
    // Finish method.
    public void finish(Database.BatchableContext bc) {
    	String countryName = 'N/A';
        try {
            if (country != null) countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :country LIMIT 1].Name;
        } catch(DmlException e) {
            nb.logError('Exception: ' + e.getDMLMessage(0) + ' - ' + e.getLineNumber());
        }
        String customSubject = nb.getBatchName() + ' - ' + countryName + '/'+ this.year + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    /**
     * Inner class
     * @description Wrapper class that has the role of linking between contract and their Computed Condition Wrapper.
     * 				+ It is responsable to perform all calculations.
     **/
    private class IndexManagementWrapper {
    	
    	private Contract__c contract;
    	private List<ComputedConditionWrapper> wConditions;
    	
    	private Decimal cIndex0 {
    		get {
				if (this.contract.Rise_Rate__c == Null) this.contract.Rise_Rate__c = 0;
				if (this.contract.Depreciation_Rate__c == Null) this.contract.Depreciation_Rate__c = 0;
				if (this.contract.Markdown_Rate_Break__c == Null) this.contract.Markdown_Rate_Break__c = 0;
				if (this.contract.Markdown_Rate_Promo__c == Null) this.contract.Markdown_Rate_Promo__c = 0;
				if (this.contract.Markdown_Rate_Theft__c == Null) this.contract.Markdown_Rate_Theft__c = 0;
    			return 100 + contract.Rise_Rate__c - contract.Depreciation_Rate__c + contract.Markdown_Rate_Break__c + contract.Markdown_Rate_Promo__c + contract.Markdown_Rate_Theft__c;
    		}
    		set;
    	}
    	
    	private List<Decimal> valIndexes {
    		get {
    			Decimal val1 = 0, val2 = 0, val3 = 0, val4 = 0;
				for (ComputedConditionWrapper item : wConditions) {
					if (item.condition.Condition_Type__r.index__c == 'Index1') val1 += item.computedVal;
					if (item.condition.Condition_Type__r.index__c == 'Index2') val2 += item.computedVal;
					if (item.condition.Condition_Type__r.index__c == 'Index3') val3 += item.computedVal;
					if (item.condition.Condition_Type__r.index__c == 'Index4') val4 += item.computedVal;
				}
				return new List<Decimal>{val1, val2, val3, val4};
    		}
    		set;
    	}
    	
    	private List<Decimal> percIndexes {
    		get {
    			Decimal val1 = 0, val2 = 0, val3 = 0, val4 = 0;
				if (contract.Total_TO_Fact__c != 0) {
					val1 = valIndexes[0] / contract.Total_TO_Fact__c * 100;
					val2 = valIndexes[1] / contract.Total_TO_Fact__c * 100;
					val3 = valIndexes[2] / contract.Total_TO_Fact__c * 100;
					val4 = valIndexes[3] / contract.Total_TO_Fact__c * 100;
					return new List<Decimal>{val1, val2, val3, val4};
				} else {
    				return new List<Decimal>();
    			}
    		}
    		set;
    	}
    	
    	private List<Decimal> indexes {
    		get {
    			Decimal val1 = 0, val2 = 0, val3 = 0, val4 = 0;
				if (percIndexes.size() > 0) {
					val1 = cIndex0 - percIndexes[0];
					val2 = val1 - percIndexes[1];
					val3 = val2 - percIndexes[2];
					val4 = val3 - percIndexes[3];
					return new List<Decimal>{val1, val2, val3, val4};
				} else {
    				return new List<Decimal>();
    			}
    		}
    		set;
    	}
    	
    	private IndexManagementWrapper(Contract__c contract) {
    		this.contract = contract;
    		wConditions = new List<ComputedConditionWrapper>();
    		ComputedConditionWrapper wCondition;
			for (Contract_Discount__c item : this.contract.Contract_Discounts__r) {
				wCondition = new ComputedConditionWrapper(item);
				wConditions.add(wCondition);
			}
    	}
    }
    
    /**
     * Inner class
     * @description Wrapper class that has the role of linking between condition and its computed value.
     **/
    private class ComputedConditionWrapper {
    	
    	private Contract_Discount__c condition;
    	private Decimal computedVal {
    		get {
    			if (this.condition.Value_per__c == Null) this.condition.Value_per__c = 0;
    			if (this.condition.Value_amt__c == Null) this.condition.Value_amt__c = 0;
    			return this.condition.Contract__r.Total_TO_Fact__c * this.condition.Value_per__c / 100 + this.condition.Value_amt__c;
    		}
    		set;
    	}
    	
    	private ComputedConditionWrapper(Contract_Discount__c condition) {
    		this.condition = condition;
    	}
    }
}