({
    SetText: function(component, event, helper) {
        component.set("v.Text", event.getParam("number") + " Products Selected");
        console.log("IM in BOi "+component.get("v.Text"));
         
    },
    EnableButtons: function() {
        let Save = component.find('SaveBtn');
        let Cancel = component.find('CancelBtn');
        let Import = component.find('ImportFilteredBtn');
        Save.set('v.disabled',false);
        Cancel.set('v.disabled',false);
        Import.set('v.disabled',false);
    },
    DisableButtons: function () {
        let Save = component.find('SaveBtn');
        let Cancel = component.find('CancelBtn');
        let Import = component.find('ImportFilteredBtn');
        Save.set('v.disabled',true);
        Cancel.set('v.disabled',true);
        Import.set('v.disabled',true);
    },
    DoneSaving: function(component , event , helper) {
        EnableButtons();
    },
    cancelBtn : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        DisableButtons();
        dismissActionPanel.fire();
        
    },
    SaveBtn : function(component, event, helper) {
        var pubsub = component.find('pubsub');
        pubsub.fireEvent('SaveAction');
    },
    ImportFiltered: function (component, event, helper){
        var pubsub = component.find('pubsub');
        pubsub.fireEvent('importAllFiltered');
    },
    handleDestroy: function(component) {
        var pubsub = component.find('pubsub');
        pubsub.unregisterAllListeners();
    }
})