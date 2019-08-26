public with sharing class ZeroRebatesContractController extends NegoptimBaseController {
    
    public List<Purchases_Flow_PG__c> purchases {get; set;}
    public String selectedCountry {get; set;}
    public String selectedYear {get; set;}
    public List<SelectOption> countries {get; set;}
    public Boolean isVisible {get; set;}
    public String fileName {get; set;}
    private Map<Id, String> mapCountryBU;
    
    // Constructor.
    public ZeroRebatesContractController() {
    	// Set selected year (default value).
        selectedYear = String.valueof(System.Today().Year());
        // Get selectedCountry parameter's value from View to the current controller.
    	selectedCountry = ApexPages.currentPage().getParameters().get('selectedCountry');
    	// Map creation.
    	mapCountryBU = new Map<Id, String>();
    	// Get job parameter's value from ZeroRebatesContractExport page to the current controller.
        String param = ApexPages.currentPage().getParameters().get('job');
        if (param != null && param == 'Export') {
            // Set file name.
	        fileName = 'Zero_Rebates_Contract_Export-' + System.now();        	
        	// Get selectedYear parameter's value from View to the current controller.
        	selectedYear = ApexPages.currentPage().getParameters().get('selectedYear');
            setReportData();
        } else {
        	// Fetch BU Countries.
	        List<Orga_BU__c> countryBUs = [SELECT Id, Name FROM Orga_BU__c WHERE Business_Unit_Type__c = 'Country' ORDER BY Name];
	        countries = new List<Selectoption>();
	        // Fill countries list.
	        for(Orga_BU__c BU : countryBUs) {
	            countries.add(new SelectOption(BU.Id, BU.Name));
	            mapCountryBU.put(BU.Id, BU.Name);
	        }
        }
    }
    // Used from view.
    public List<SelectOption> getYears() {
        List<SelectOption> options = new List<SelectOption>();
        for(Integer year = Date.today().year() - 4 ; year <= Date.today().year() ; year++) {
            options.add(new SelectOption(String.valueOf(year), String.valueOf(year)));
        }
        return options;
    }
    // Run report.
    public void submitReport() {
        setReportData();
    }
    private void setReportData() {
        Boolean contractNotRequired = false;
        // Select all conditions and purchases from all contracts.
        List<Contract__c> contracts = [Select Id, Contract_BU__r.Name, (Select Value_per__c, Value_amt__c From Contract_Discounts__r),
                                       (Select Id, Contrat1__r.Name, Supplier__r.Name, Supplier_Nego_Scope__r.Name, PG__r.Name, TO1__c, TO2__c, TO3__c,
                                       TO4__c, TO5__c, TO6__c, TO7__c, TO8__c, TO9__c, TO10__c, TO11__c, TO12__c From Purchases_Flow_PG__r)
                                       From Contract__c WHERE Contract_BU__c =: selectedCountry
                                       AND CALENDAR_YEAR(Contract_BDate__c) =: Integer.valueOf(selectedYear)];
        // List of required contracts which must to have purchase(s) and must to have only amount condition(s).
        List<Contract__c> requiredContracts = new List<Contract__c>();
        if (contracts.size() == 0 || contracts == null) {
            isVisible = false;
        } else {
            isVisible = true;
            for (Contract__c c : contracts) {
                // Each contract should have one or more purchases.
                if (c.Purchases_Flow_PG__r.size() > 0) {
                    for (Contract_Discount__c cond : c.Contract_Discounts__r) {
                        // Each condition should not be percentage.
                        if (cond.Value_per__c != null) {
                            contractNotRequired = true;
                            break;
                        } else {
                            contractNotRequired = false;
                        }
                    }
                    // Test if the current contract is required: 1) have purchase(s) 2) have amount condition(s).
                    if (contractNotRequired == false) {
                        requiredContracts.add(c);
                    }
                } else {
                    isVisible = false;
                }
            }
            // Loop over the required contracts to fill the list of purchases.
            purchases = new List<Purchases_Flow_PG__c>();
            if (requiredContracts.size() != 0 && requiredContracts != null) {
                isVisible = true;
                for (Contract__c c : requiredContracts) {
                    for (Purchases_Flow_PG__c p : c.Purchases_Flow_PG__r) {
                        purchases.add(p);
                    }
                }
            } else {
                isVisible = false;
            }
        }
        if (isVisible == false) {
            // Call String.format() to get the token replaced.
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.format(Label.MSG_Zero_Rebates_Report_Desc, new String[] {mapCountryBU.get(selectedCountry), selectedYear})));
        }
    }
    // Export Zero Rebates Contract report to Excel file.
    public PageReference exportReport() {
    	setReportData();
		// If there is data, then redirection to Excel view is occured, else, nothing to do in which the validation message is already appeared.
		if (isVisible == true) {
			// Declare page reference.
			PageReference ref;
			// Allocate the ZeroRebatesContractExport page into the declared page reference.
	        ref = Page.ZeroRebatesContractExport;
	        // Passing parameters from the current controller to the ExportZeroRebatesContractExcel page.
	        ref.getParameters().put('job', 'Export');
	        ref.getParameters().put('selectedCountry', selectedCountry);
	        ref.getParameters().put('selectedYear', selectedYear);
	    	ref.setRedirect(true);
		   	return ref;
		} else {
			return null;
		}
    }
}