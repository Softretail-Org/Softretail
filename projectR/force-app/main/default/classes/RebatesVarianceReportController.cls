public with sharing class RebatesVarianceReportController   {
    
    public List<WrapperRebatesCondition> listWrapperRebatesCondition {get; set;}
    public Integer currentYear{ get; set; }
    public Integer previousYear{ get; set; }
    public List<SelectOption> buOptions  {get; set;}
    public String selectCountry {get; set;} 
    public Integer  year {get; set;}
    public String fileName {get; set;}
    public Boolean isExport;
    public Boolean isDataExist{get; set;}
    public Boolean isPreviousContractExist;
    private Map<Id,String> mapCountry;
   
    public RebatesVarianceReportController() {
    	isDataExist = false;
    	mapCountry = new Map<Id,String>();
        fileName = 'RebatesVarianceReportExport-' + system.now();
        currentYear = System.Today().Year();
        previousYear = currentYear-1;
        year = currentYear;
        List<Orga_BU__c> listBu = [SELECT Id, Name, Business_Unit_Type__c
                                   FROM Orga_BU__c 
                                   WHERE Business_Unit_Type__c = 'Country' ORDER BY Name];
        
        buOptions = new List<Selectoption>();
        for(Orga_BU__c bu: listBu) {
        	mapCountry.put(bu.Id,bu.Name);
            buOptions.add(new SelectOption(bu.Id,bu.Name));
        }
        String param = ApexPages.currentPage().getParameters().get('action');
        if (param != null && param == 'Export') {
            // execute export data base on filter
            selectCountry = ApexPages.currentPage().getParameters().get('country');
            year = integer.valueof(ApexPages.currentPage().getParameters().get('year'));
            submitReport();
            
        }                        			
    }
    
    /*
* Export data as excel on submit of export button
*/
    public PageReference exportReport() {
        
        PageReference ref;
        ref = Page.RebatesVarianceReportExport;
        ref.getParameters().put('action', 'Export');
        ref.getParameters().put('country', selectCountry);
        ref.getParameters().put('year', string.valueOf(year));
        
        submitReport();
        if(isExport==false){
            ref = null;
        }else{
            ref.setRedirect(true);
        }
        return ref;
    }
    
    /*
* get list of years betwen current year and previous 4 years 
*/
    public List<SelectOption> getYears() {
        List<SelectOption> options = new List<SelectOption>();
        for(Integer year = Date.today().year() - 4 ; year <= Date.today().year()  ; year++) {
            options.add( new SelectOption(String.valueOf(year), String.valueOf(year)) );
        }
        return options;
    }
    
    /* 
* Filter report data 
*/
    public PageReference submitReport(){
        
        listWrapperRebatesCondition = new List<WrapperRebatesCondition>();
        list<Contract__c> listRefContract = new list<Contract__c>();
        Map<Id,Contract__c> mapContract = new Map<Id,Contract__c>();
        Map<Id,Contract_Discount__c> mapCondition = new Map<Id,Contract_Discount__c>();
        // construct the query to get data based on filter
        String query = 'SELECT c.Id, c.Name, c.Contract_BDate__c, c.Contract_EDate__c, c.Status__c , c.Contract_Type__c,';
        query += ' c.Parent_Contract__c, c.Supplier__r.Name, c.Supplier__r.Status__c, c.Supplier_Nego_Scope__r.Status__c,c.Supplier__r.Country_origin__c, c.Supplier_Nego_Scope__r.Name,';
        query += ' (Select Id, Name, Reference_condition__c, BU_Scope__c, Condition_Type__c, Condition_Type__r.Name,';
        query += ' Contract__c, Disc_EDate__c, Status__c, Value_per__c, Value_amt__c, Disc_BDate__c, BU_Scope__r.Name,Product_Scope__r.Name';
        query += ' FROM Contract_Discounts__r)';
        query += ' FROM Contract__c c WHERE c.Contract_Type__c = \'Contract\'';
        
        if(selectCountry != '' && selectCountry != null) {
            query += ' AND c.Supplier__r.Country_origin__c =\'' + String.escapeSingleQuotes(selectCountry) +'\'';
        } 
        if(year != 0) {
            currentYear = year;
            previousYear = currentYear - 1;
        }   
        query +=' AND (CALENDAR_YEAR(c.Contract_BDate__c) = ' + currentYear + ' OR CALENDAR_YEAR(c.Contract_BDate__c) = ' + previousYear + ')';
        if(query != '') {
            
            list<Contract__c> lstContractCond = Database.query(query);
            // check if there is data
            if (lstContractCond.size() == 0 || lstContractCond == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.format(Label.MSG_No_Available_Conditions, new String[] {mapCountry.get(selectCountry) ,String.valueof(year) })));
                isExport = false;
                isDataExist = false;
            }else{
            	isDataExist = true;
                // fill old contract in list nd current contract in map 
                for (Contract__c c : lstContractCond) {
                    
                    if(c.Contract_BDate__c.Year() == previousYear) {
                        listRefContract.add(c);
                    }
                    if(c.Contract_BDate__c.Year() == currentYear) {
                        mapContract.put(c.Parent_Contract__c, c);
                    }  
                }
                // loop on old contract to find by ref key the matchin current contract and add it to wrapper 
                for(Contract__c refItem : listRefContract) {
                    if(mapContract.get(refItem.Id) != null) {
                        WrapperRebatesCondition wrapperRebatesCondition = new WrapperRebatesCondition(refItem, mapContract.get(refItem.Id));
                        listWrapperRebatesCondition.add(wrapperRebatesCondition);
                    }
                    else{
                    	isPreviousContractExist = false;
                    }
                }
                // then we do same on conditions , we loop on old conditions and new one then we add them in list and map
                // we find matching by ref key  condition and add them in the wrapper
                for(WrapperRebatesCondition  condition : listWrapperRebatesCondition) {
                    List<Contract_Discount__c> condItems = condition.contractRef.Contract_Discounts__r;            	
                    list<Contract_Discount__c> listRefCond = new list<Contract_Discount__c>();
                    listRefCond = condItems;
                    for(Contract_Discount__c item : condition.contractNew.Contract_Discounts__r) {
                        Id refCondition = item.Reference_condition__c != null ? item.Reference_condition__c : item.Id;
                        mapCondition.put(refCondition, item);
                    }
            
                    for(Contract_Discount__c refItem : listRefCond) {
                        Decimal val = 0;
                        if(mapCondition.get(refItem.Id) != null) {  
                            // calculate variance between old and new condition
                            Decimal  newPercValue = mapCondition.get(refItem.Id).Value_per__c;
                            Decimal  refPerValue = refItem.Value_per__c;
                            if(refPerValue == null){
                                refPerValue = 0;
                            }
                            if(newPercValue == null){
                                newPercValue = 0;
                            }
                            
                            val = newPercValue - refPerValue;
                            condition.lstVariance.add(val);
                            condition.lstConditionRef.add(refItem);
                            condition.lstConditionNew.add(mapCondition.get(refItem.Id));
                            condition.isExist = true; 
                        }else{
                            condition.lstConditionRef.add(refItem);
                            Contract_Discount__c  newCondition = new Contract_Discount__c();
                            condition.lstConditionNew.add(newCondition);
                            
                            Decimal newPercValue = 0;
                            Decimal refPerValue = refItem.Value_per__c;
                            if(refPerValue == null){
                                refPerValue = 0;
                            }
                            val = newPercValue - refPerValue;
                            condition.lstVariance.add(val);
                            condition.isExist = true; 
                        }
                    }
                    for(Contract_Discount__c item : condition.contractNew.Contract_Discounts__r) {
                        if(item.Reference_condition__c == null){
                            Decimal  newPercValue = item.Value_per__c;
                            Decimal  refPerValue = 0;
                            refPerValue = 0;
                            
                            if(newPercValue == null){
                                newPercValue = 0;
                            }
                            Decimal  val = newPercValue - refPerValue;
                            condition.lstConditionNew.add(item);
                            Contract_Discount__c oldCondition = new Contract_Discount__c();
                            condition.lstConditionRef.add(oldCondition);
                            condition.lstVariance.add(val);
                            condition.isExist = true; 
                        }
                    }
                }
           
                isExport = true;
                if(isPreviousContractExist == false){
                	 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.format(Label.MSG_No_Ref_Contract, new String[] {mapCountry.get(selectCountry) ,String.valueof(year) })));
                	
                }
            }
        }        	
        
        return null;
    }
    
    /*
* Wrapper Class to handle contract, conditions and variance value 
*/
    public class WrapperRebatesCondition {
        
        public Contract__c contractRef {get; set;}
        public Contract__c contractNew {get; set;}
        public List<Contract_Discount__c> lstConditionRef {get; set;}
        public List<Contract_Discount__c> lstConditionNew {get; set;}
        public List<Decimal> lstVariance {get; set;}
        public Boolean isExist {get; set;}
        
        
        public WrapperRebatesCondition(Contract__c contractRef, Contract__c contractNew) {
            this.contractRef = contractRef;
            this.contractNew = contractNew;
            this.lstConditionRef = new List<Contract_Discount__c>();
            this.lstConditionNew = new List<Contract_Discount__c>();
            this.lstVariance =  new List<Decimal>();            
            this.isExist = false;
        }
    }
    
}