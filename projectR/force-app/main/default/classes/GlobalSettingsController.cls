/**
 * @author ULiT Team
 * @date JUN-1-2017
 * @group Negoptim Support
 * @description Controller to handle GlobalSettings page action for updating global settings
 ***************************************************************************************************************************************** */
public with sharing class GlobalSettingsController extends NegoptimBaseController {
    
    public List<String> errors {get; set;}
    public NegoptimSettings negoSettings {get; set;}
    public List<SelectOption> gridSettingsLayouts {get; set;}
    /**
     * temporary value for checking if this settings exists before saving 
	********************************************************************** */
    public String tempBusinessType {get; set;}
    /**
     * the string value of None option for comparisson in page 
	********************************************************************** */
    public String businessTypeNone {
        get {
            return NegoptimSettings.BusinessType.None.name();
        }
    }
    /**
	 * @description Constructor load global settings
	 ********************************************************************** */
    public GlobalSettingsController() {
        negoSettings = GlobalSettingsManager.loadGlobalSettings();
        this.tempBusinessType = negoSettings.sBusinessType != businessTypeNone ? negoSettings.sBusinessType : businessTypeNone;
        this.gridSettingsLayouts = new list<SelectOption>();
        for (Grid_Settings__mdt item : [SELECT DeveloperName, Label FROM Grid_Settings__mdt LIMIT 1000]) {
            this.gridSettingsLayouts.add(new SelectOption(item.DeveloperName, item.Label));
        }
    }
    /**
	 * @description get all available delimiter
	 * @return List<SelectOption> list of delimiters
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getDelimiters() {
        List<SelectOption> options = new List<SelectOption>();
        String[] separators = new String[]{',', ';', ':', '|'};
            for(String str : separators) {
                options.add(new SelectOption(str, str));
            }
        return options;
    }
    /**
	 * @description Get Business Types
	 * @return List<SelectOption> List of Business Types
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getBusinessTypes() {
        List<SelectOption> options = new List<SelectOption>() ;
        for (NegoptimSettings.BusinessType bType : NegoptimSettings.BusinessType.values()) {
            options.add(new SelectOption(bType.name(), bType.name()));
        }
        return options;
    }
    /**
	 * @description Get Reminder Level
	 * @return List<SelectOption> List of Reminder Level
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getReminderLevels() {
        List<SelectOption> options = new List<SelectOption>();
        String[] levels = new String[]{'0', '1', '2', '3'};
            for(String l : levels) {
                options.add(new SelectOption(l, l));
            }
        return options;
    }
    /**
	 * @description Get Bu Type
	 * @return List<SelectOption> List of Bu Type
	 ***************************************************************************************************************************************** */
    // TODO: create in NegoptimHelper
    public List<SelectOption> getBURecordTypes() {
        List<SelectOption> options = new List<SelectOption>();
        for(RecordType item : [SELECT DeveloperName, Name
                               FROM RecordType
                               WHERE SobjectType = :SObjectType.Orga_BU__c.Name])
        {
            options.add(new SelectOption(item.DeveloperName, item.Name));
        }
        return options;
    }
    /**
	 * @description Get Groups
	 * @return List<SelectOption> List of Groups
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getGroups() {
        List<SelectOption> groups = new List<SelectOption>();
        for(Orga_BU__c item: [SELECT Id, Name, BU_Code__c, RecordType.Name FROM Orga_BU__c WHERE RecordType.DeveloperName =: 'Group']) {
            groups.add(new SelectOption(item.BU_Code__c, item.Name));
        }
        return groups;
    }
    /**
	 * @description Get group BU
	 * @return List<SelectOption> List of group BU
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getGroupsBU() {
        List<SelectOption> groups = new List<SelectOption>{new SelectOption('', '--Select--')};
            for(Orga_BU__c item: [SELECT Id, Name FROM Orga_BU__c
                                  WHERE RecordType.DeveloperName = 'Group'
                                  OR RecordType.DeveloperName = 'Country']) {
                                      groups.add(new SelectOption(item.Id, item.Name));
                                  }
        return groups;
    }
    /**
	 * @description Get profiles
	 * @return List<SelectOption> List of profiles
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getProfiles() {
        List<SelectOption> profiles = new List<SelectOption>();
            for (Profile item: [SELECT Id, Name FROM Profile ORDER BY Name LIMIT 1000]) {
                profiles.add(new SelectOption(item.Id, item.Name));
            }
        return profiles;
    }
    /**
	 * @description Save Global setting in the cache and custom settings
	 ***************************************************************************************************************************************** */
	public PageReference save() {
        
        negoSettings.sBusinessType = negoSettings.sBusinessType == this.businessTypeNone ? tempBusinessType : negoSettings.sBusinessType;
        Set<String> errors = GlobalSettingsManager.saveGlobalSettings(negoSettings);
        if(errors.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
        } else {
            for(String err : errors) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, err));
            }
        }
        return null;
    }
}