({
    doInit : function(component, event, helper) {
        var action = component.get('c.getSelectOptionsCountries');
        // Set up the callback
        action.setCallback(this, function(actionResult) {
            component.set('v.countr', actionResult.getReturnValue());
        });
        var action2 = component.get('c.getSelectOptionsGroupBusinessUnits');
        // Set up the callback
        action2.setCallback(this, function(actionResult2) {
            component.set('v.groupBu', actionResult2.getReturnValue());
            console.log(actionResult2.getReturnValue());
        });
        var action3 = component.get('c.getSettingsForSections');
        // Set up the callback
        action3.setCallback(this, function(actionResult) {
            var results  = actionResult.getReturnValue();
            for(var k in results){
                var sectionVal = results[k].split('=')[0];
                switch(sectionVal){
                    case 'MBF_Section_AssortmentSFPlanning' :
                        component.set('v.SectionAssortmentSFPlanning',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_Batches':
                        component.set('v.SectionBatches',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_CallingWebServices':
                        component.set('v.SectionCallingWebServices',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_ContractCounterpartyDetail':
                        component.set('v.SectionContractCounterpartyDetail',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_ContractDuplication':
                        component.set('v.SectionContractDuplication',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_ContractRates':
                        component.set('v.SectionContractRates',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_ContractTOProcedures':
                        component.set('v.SectionContractTOProcedures',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_GroupScanAndSynchro':
                        component.set('v.SectionGroupScanAndSynchro',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_InvoiceReminder':
                        component.set('v.SectionInvoiceReminder',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_LastActiveContractProcedure':
                        component.set('v.SectionLastActiveContractProcedure',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_MarketDataCollection ':
                        component.set('v.SectionMarketDataCollection',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_MassDistribution':
                        component.set('v.SectionMassDistribution',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_PenaltiesProcedure':
                        component.set('v.SectionPenaltiesProcedure',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_PromoDetailProcedure':
                        component.set('v.SectionPromoDetailProcedure',results[k].split('=')[1]);
                        break;
                    case 'MBF_Section_SellInProcedure':
                        component.set('v.SectionSellInProcedure',results[k].split('=')[1]);
                        break;
                    default:break;
                }
            }
        });
        $A.enqueueAction(action);
        $A.enqueueAction(action2);
        $A.enqueueAction(action3);
        helper.pollApex(component, event, helper);
    },
    changeRadio : function(component,event,helper){
        console.log(event.getSource().get('v.label'));
    },
    changevalue : function(component,event,helper){
        var val = component.find('mySelect').get('v.value');
        console.log(val);
    }, 
    changevalueBu : function(component,event,helper){
        var val = component.find('mySelectBu').get('v.value');
        console.log(val);
    },
    changevalueReminder : function(component,event,helper){
        var val = component.find('mySelectReminder').get('v.value');
        console.log(val);
    },
    onCheck: function(cmp, evt) {
        var checkCmp = cmp.find("checkbox");
        console.log(checkCmp.get("v.value"));
        
    },
    run :function(component,event,helper){
        var country = component.find('mySelect').get('v.value');
        var date = component.find('expdate').get('v.value');
        console.log('country=>'+country+":date=>"+date);
        var action = component.get('c.generateInvoice');
        action.setParams({'c':country,'d':new Date(date).toJSON()});
        $A.enqueueAction(action);
        location.reload();
    },
    CalculateTo : function(component,event,helper){
        var countryId = component.find('mySelect').get('v.value');
        console.log('calculate to '+countryId);
        var action = component.get('c.callCalculateTo');
        action.setParams({'id':countryId});
        $A.enqueueAction(action);
    },
    dispatching : function(component,event,helper){
        var countryId = component.find('mySelect').get('v.value');
        console.log('dispatching id '+countryId);
        var action = component.get('c.dispatchingBatch');
        action.setParams({'id':countryId});
        $A.enqueueAction(action);
    },
    baseRedistribution : function (component,event,helper) {
        var action = component.get('c.baseRedistributionBatch'); 
        $A.enqueueAction(action);
    },
    duplicateContract : function (component,event,helper) {
        var countryId = component.find('mySelect').get('v.value');
        console.log('duplicate contract id '+countryId);
        var action = component.get('c.duplicateContractBatch');
        action.setParams({'id':countryId});
        $A.enqueueAction(action);
    },
    generateCRCRate : function(component,event,helper){
        var countryId = component.find('mySelect').get('v.value');
        var lastActiveContr = cmp.find("checkbox").get("v.value");
        var action = component.get('c.generateGRCRatesBatch');
        action.setParams({'id':countryId,'lastActiveContract':lastActiveContr});
        $A.enqueueAction(action);
    },
    groupContractScan: function(component,event,helper){
        var bucode = component.find('mySelectBu').get('v.value');
        var action = component.get('c.groupContractScanBatch');
        action.setParams({'bu':bucode});
        $A.enqueueAction(action);
    },
    groupContractSynchr: function(component,event,helper){
        var bucode = component.find('mySelectBu').get('v.value');
        var action = component.get('c.groupContractSynchroBatch');
        action.setParams({'bu':bucode});
        $A.enqueueAction(action);
    },
    groupInvoiceScan: function(component,event,helper){
        var action = component.get('c.groupInvoiceScanBatch');
        $A.enqueueAction(action);
    },
    groupInvoiceSynchr: function(component,event,helper){
        var action = component.get('c.groupInvoiceSynchroBatch');
        $A.enqueueAction(action);
    },
    groupInvoicePayScan: function(component,event,helper){
        var action = component.get('c.groupInvoicePaymentScanBatch');
        $A.enqueueAction(action);
    },
    groupInvoicePaySynchr: function(component,event,helper){
        var action = component.get('c.groupInvoicePaymentSynchroBatch');
        $A.enqueueAction(action);
    },
    groupRebatePayScan: function(component,event,helper){
        var action = component.get('c.submitGroupRebatePaymentScanBatch');
        $A.enqueueAction(action); 
    },
    groupRebatePaySynchr: function(component,event,helper){
        var action = component.get('c.submitGroupRebatePaymentSynchroBatch');
        $A.enqueueAction(action); 
    },
    commercialPlanScanContract: function(component,event,helper){
        var countryId = component.find('mySelect').get('v.value');
        var action = component.get('c.submitCommercialPlanScanContractBatch');
        action.setParams({'id':countryId});
        $A.enqueueAction(action);
    },
    commercialPlanScanStatus: function(component,event,helper){
        var countryId = component.find('mySelect').get('v.value');
        var action = component.get('c.submitCommercialPlanScanStatusBatch');
        action.setParams({'id':countryId});
        $A.enqueueAction(action);
    },
    closeSuppBatch: function(component,event,helper){
        var action = component.get('c.submitCloseSupplierBatch');
        $A.enqueueAction(action);
    },
    lastActiveContract: function(component,event,helper){
        var countryId = component.find('mySelect').get('v.value');
        var action = component.get('c.submitLastActiveContractBatch');
        action.setParams({'id':countryId});
        $A.enqueueAction(action);
    },
    sellinToPurchase: function(component,event,helper){
        var countryId = component.find('mySelect').get('v.value');
        var action = component.get('c.submitSellinToPurchaseBatch');
        action.setParams({'id':countryId});
        $A.enqueueAction(action);
    },
    reparentingSellin: function(component,event,helper){
        var countryId = component.find('mySelect').get('v.value');
        var action = component.get('c.submitReparentingSellinBatch');
        action.setParams({'id':countryId});
        $A.enqueueAction(action);
    },
    invoiceReminder: function(component,event,helper){
        var reminderLevel = component.find('mySelectReminder').get('v.value');
        var action = component.get('c.submitInvoiceReminderBatch');
        action.setParams({'selectedReminderLevel':parseInt(reminderLevel)});
        $A.enqueueAction(action);
    },
    penaltyScanSynchr: function(component,event,helper){
        var action = component.get('c.penaltiesScanSynchroBatch');
        $A.enqueueAction(action);
    },
    CloseSupplierBatch : function(component,event,helper){
        var action = component.get('c.submitCloseSupplierBatch');
        $A.enqueueAction(action);
    },
     CounterpartiesScanContractBatch: function(component,event,helper){
        var countryId = component.find('mySelect').get('v.value');
        var action = component.get('c.submitCounterpartiesScanContractBatch');
        action.setParams({'id':countryId});
        $A.enqueueAction(action);
    },
      CounterpartiesScanStatusBatch: function(component,event,helper){
        var countryId = component.find('mySelect').get('v.value');
        var action = component.get('c.submitCounterpartiesScanStatusBatch');
        action.setParams({'id':countryId});
        $A.enqueueAction(action);
    },
     MarketDataCollectionScanBatch : function(component,event,helper){
        var action = component.get('c.submitMarketDataCollectionScanBatch');
        $A.enqueueAction(action);
    },
      MarketDataCollectionSynchroBatch : function(component,event,helper){
        var action = component.get('c.submitMarketDataCollectionSynchroBatch');
        $A.enqueueAction(action);
    },
     handleFilesChange: function(component, event, helper) {
 
    }
})