public with sharing class ReportsFilteringController {
    
    public List<SelectOption> buOptions  {get; set;}
    public List<SelectOption> reportsOptions  {get; set;}
    public String selectCountry {get; set;} 
    public Id selectReport {get; set;} 
    public Integer  year {get; set;}
    public Map<Id,String> mapReportName{get; set;}
    public ReportsFilteringController() {
        
        List<Orga_BU__c> listBu = [SELECT Id, Name, Business_Unit_Type__c
                                   FROM Orga_BU__c 
                                   WHERE Business_Unit_Type__c = 'Country' ORDER BY Name];
        buOptions = new List<Selectoption>();
        buOptions.add(new SelectOption('',''));
        for(Orga_BU__c bu: listBu) {
            String countryName = bu.Name;
            buOptions.add(new SelectOption(countryName,countryName));
        }
        Map<String, List<report>> mapReports = new Map<String, List<report>>();
        mapReportName = new Map<Id,String>();
        List<report> listReports = [SELECT Id, Name, DeveloperName, FolderName FROM Report
        							WHERE FolderName IN ('AUDIT - Business control','COMPTA - Synthèse de trésorerie') ORDER BY Name];
        //Fill report result into a map of key as folder name and 
        //value as the report list
        for(report rpts: listReports) {
        	mapReportName.put(rpts.Id,rpts.DeveloperName);
            if(mapReports.containsKey(rpts.foldername)) {
                mapReports.get(rpts.foldername).add(rpts);
            }else{
                mapReports.put(rpts.foldername,new List<report> { rpts });
            }
        }
        // loop on map collected and add it to the dropdown list 
        reportsOptions = new List<Selectoption>();
        for(String folderName : mapReports.keySet()) {
            List<report> lstReport = mapReports.get(folderName);
            reportsOptions.add(new SelectOption('',folderName,true));
            for(report rpt: lstReport) {
                reportsOptions.add(new SelectOption(rpt.Id,'-- ' + rpt.Name));
            }
        }
    }
    
    public PageReference submitReportResult() {
        
        String params = '';
        String params2 = '';
        String yearFrom,yearTo;
         // get report api name  
        String reportApiName = mapReportName.get(selectReport);
     
        if(selectCountry != '' && selectCountry != null) {
            params = '?pv0='+ selectCountry;
        }
        if(year != 0) {
            params2 = '&pv1='+ year;
            if(reportApiName == 'Supplier_Status' || reportApiName == 'New_PGs_created' 
            || reportApiName == 'Contract_Statuses' || reportApiName == 'SUP_PG_Status'
            || reportApiName == 'Stores_Amount_Analysis') {
	        	yearFrom = '1/1/' + year;
	        	yearTo = '12/31/' + year;
	        	params2 = '&pv1='+ yearFrom + '&pv2='+ yearTo;
            }
  
        }
        
        PageReference retURL = new PageReference('/'+selectReport + params + params2);
        retURL.setRedirect(true);
        return retURL;
    }
    
    public List<SelectOption> getYears() {
        List<SelectOption> options = new List<SelectOption>();
        for(Integer year = Date.today().year(); year >= Date.today().year() - 4   ; year--) {
            options.add( new SelectOption(String.valueOf(year), String.valueOf(year)) ); 
        }
        return options;
    }
    
}