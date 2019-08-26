/**
 * @author ULiT
 * */
public with sharing class CancelPromoController extends NegoptimBaseController {

    public Commercial_Plan__c commercialPlan {get; set;}
    public Id commercialPlanId {get; set;}
    public Boolean isCanceled {get; set;}
    
    public CancelPromoController(ApexPages.StandardController stdController) {        
        this.commercialPlanId = stdController.getId();
        this.isCanceled = false;
        try {
            if(String.isNotBlank(commercialPlanId)) {
                // Check commercial plan field security
                String[] commercialPlanFields = new String[] {'Id', 'Name', getFieldName('Event_Code__c'), getFieldName('Start_Date__c'),
                getFieldName('End_Date__c'), getFieldName('Target_Elasticity__c'), getFieldName('Target_Constribution_rate__c'), getFieldName('Contribution_Validated__c')};
                
                String[] commercialPlanDetailFields = new String[] {'Id', 'Name', getFieldName('Commercial_Event__c'), getFieldName('Supplier__c'), getFieldName('Product__c')};
                
                if(checkAccessibility(Commercial_Plan__c.SObjectType, commercialPlanFields) && checkAccessibility(Commercial_Plan_Detail__c.SObjectType, commercialPlanDetailFields)) {
                    this.commercialPlan = [SELECT Id, Name, Status__c, Commercial_Animation_Plan_Parent__c, CurrencyIsoCode, Condition_Code__c, BU_Source__c, BU_Target__c, Event_Code__c, Start_Date__c, End_Date__c, Supplier__c, Supplier__r.Name, Supplier__r.Code__c,
                                           Promo_Budget_Type__c, Target_Elasticity__c, Target_Constribution_rate__c, Regular_Nego_Discount__c, History_Reference__c, Reference_Year__c, Contribution_Validated__c,
                                           Event_Support__c, Event_Type__c, Global_budget__c, Volume_Reach__c,
                                           (SELECT Id FROM Commercial_Animation_Plan__r),
                                           (SELECT Id, Name, Commercial_Event__c, Nego_Scope__c, Supplier__c, Contract__c, Product__c,
                                            Regular_Purchase_Price__c, Regular_Sales_Price__c, Promo_Purchase_Price__c, Promo_Sales_Price__c,
                                            Contribution_Unit_Quantity__c, Contribution_Unit_Amount__c, Volume_Period_Reference__c, Volume_to_Reach__c, Prenego_envelop__c,
                                            COGS_Init__c, Contribution_Unit_Amount_Init__c, Regular_Purchase_Price_Init__c, Regular_Sales_Price_Init__c,
                                            Promo_Purchase_Price_Init__c, Promo_Sales_Price_Init__c, Volume_Reached__c, Statut__c
                                            FROM Marketing_Event_Detail__r WHERE Product__c <> NULL)
                                           FROM Commercial_Plan__c WHERE Id = :commercialPlanId];
                    if (this.commercialPlan.Commercial_Animation_Plan_Parent__c != null
                       || !this.commercialPlan.Commercial_Animation_Plan__r.isEmpty()) {
                        this.isCanceled = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Promo_Already_Canceled));
                    }
                }
            }
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid commercial plan Id'));
        }
    }
    
    // cancel promo
    public PageReference cancelPromo() {
        // Check commercial plan update field security
        String[] commercialPlanFields = new String [] {getFieldName('Supplier__c'), getFieldName('Target_Elasticity__c'), getFieldName('Target_Constribution_rate__c'),
            getFieldName('Promo_Budget_Type__c'), getFieldName('Regular_Nego_Discount__c'), getFieldName('History_Reference__c')};

        List<Commercial_Plan_Detail__c> newCommercialPlanDetails = new List<Commercial_Plan_Detail__c>();
        Commercial_Plan__c newCommercialPlan = this.commercialPlan.clone(false);
        if(checkCreatibility(Commercial_Plan__c.SObjectType, commercialPlanFields)) {
            newCommercialPlan.Commercial_Animation_Plan_Parent__c = this.commercialPlan.Id;
            newCommercialPlan.Name += ' (' + Label.Cancel + ')';
            newCommercialPlan.Status__c = 'In preparation';
            insert newCommercialPlan;
        }
        // Get default record type of Commercial_Plan_Detail__c
        Schema.DescribeSObjectResult dsr = Commercial_Plan_Detail__c.SObjectType.getDescribe();
        Schema.RecordTypeInfo defaultRecordType;
        for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
            if(rti.isDefaultRecordTypeMapping()) {
                defaultRecordType = rti;
            }
        }
        // Clone commercial plan details
        for(Commercial_Plan_Detail__c item : this.commercialPlan.Marketing_Event_Detail__r) {
            Commercial_Plan_Detail__c newCommercialPlanDetail = item.clone(false);
            newCommercialPlanDetail.Commercial_Event__c = newCommercialPlan.Id;
            newCommercialPlanDetail.Statut__c = 'In process of validation';
            newCommercialPlanDetail.RecordTypeId = defaultRecordType.getRecordTypeId();
            newCommercialPlanDetail.Prenego_envelop__c = null;
            newCommercialPlanDetail.Regular_Purchase_Price__c = item.Regular_Purchase_Price__c != null ? -1 * item.Regular_Purchase_Price__c : null;
            newCommercialPlanDetail.Regular_Sales_Price__c = item.Regular_Sales_Price__c != null ? -1 * item.Regular_Sales_Price__c : null;
            newCommercialPlanDetail.Promo_Purchase_Price__c = item.Promo_Purchase_Price__c != null ? -1 * item.Promo_Purchase_Price__c : null;
            newCommercialPlanDetail.Promo_Sales_Price__c = item.Promo_Sales_Price__c != null ? -1 * item.Promo_Sales_Price__c : null;
            newCommercialPlanDetail.Contribution_Unit_Amount__c = item.Contribution_Unit_Amount__c != null ? -1 * item.Contribution_Unit_Amount__c : null;
            newCommercialPlanDetails.add(newCommercialPlanDetail);
        }
        
        // Check commercial plan detail upsert field security
        String[] commercialPlanDetailFields = new String [] {'CurrencyIsoCode', getFieldName('Contract__c'), getFieldName('Nego_Scope__c'),
            getFieldName('BU_Target__c'), getFieldName('Product__c'), getFieldName('Supplier__c'),
            getFieldName('Promo_Purchase_Price__c'), getFieldName('Promo_Sales_Price__c'), getFieldName('Regular_Purchase_Price__c'),
            getFieldName('Regular_Sales_Price__c'), getFieldName('Contribution_Unit_Amount__c'), getFieldName('Volume_Period_Reference__c'),
            getFieldName('Elasticity_rate_calc__c')};
       
        String[] commercialPlanDetailInsertFields = new String [] {getFieldName('Commercial_Event__c')};
            commercialPlanDetailInsertFields.addAll(commercialPlanDetailFields);
        
        if(checkCreatibility(Commercial_Plan_Detail__c.SObjectType, commercialPlanDetailInsertFields)) {
            List<Database.SaveResult> results = Database.insert(newCommercialPlanDetails, false);
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results.get(i);
                Commercial_Plan_Detail__c commercialPlanDetail = newCommercialPlanDetails.get(i);
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
        return new PageReference('/' + newCommercialPlan.Id);
    }
}