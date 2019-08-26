({
    doInit: function (component, event, helper) {
        helper.getMarketHeadTabURL(component);
        helper.getObjectType(component);
        //call apex class method
        var action = component.get('c.initClass');
        action.setCallback(this, function (response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                // set response value in instance attribute on component
                component.set('v.instance', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    handleFilesChange: function (component, event, helper) {
        helper.dismissMessages(component);
        component.set("v.uploadPercentage", 0);
        component.set("v.uploadComplete", false);
        var fileName = $A.get("$Label.c.LBL_No_File_Selected");
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
    },

    doUpload: function (component, event, helper) {
        helper.dismissMessages(component);
        helper.doProcess(component, event);
    },

    doCancel: function (component, event, helper) {
        ////window.location.href = component.get("v.url");
        var url = window.location.href;
        var value = url.substr(0, url.lastIndexOf('/') + 1);
        window.history.back();
        return false;
    },
})