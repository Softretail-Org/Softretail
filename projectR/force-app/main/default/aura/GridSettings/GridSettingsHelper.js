({
    getObjectList: function (component) {
        var action = component.get("c.getObjects");
        var self = this;
        action.setCallback(this, function (response) {
            var state = response.getState();
            var results = [];
            if (state === "SUCCESS") {
                results = response.getReturnValue();
                // Sort A->Z
                results.sort(function (a, b) {
                    var keyA = a.objectLabel,
                        keyB = b.objectLabel;
                    // Compare the 2 Label
                    if (keyA < keyB) return -1;
                    if (keyA > keyB) return 1;
                    return 0;
                });
                component.set("v.allObjects", results);
            } else self.handelError(component, response);
        });
        $A.enqueueAction(action);
    },

    getGridSettings: function (component, callback) {
        // loading all data
        var action = component.get("c.getGridLayouts");
        var self = this;
        action.setCallback(this, function (response) {
            var results = [];
            var state = response.getState();
            if (state === "SUCCESS") {
                results = response.getReturnValue();
                var templateList = [];
                // push extra item
                templateList.push({
                    'label': 'New Template',
                    'value': 'Custom_Template'
                });
                for (var item in results) {
                    var objectname = results[item].Object_Name__c;
                    templateList.push({
                        'label': results[item].MasterLabel + ' [' + objectname + ']',
                        'value': item
                    })
                }

                component.set('v.templateList', templateList);
                component.set('v.allMetaData', results);
                if (callback) callback();
            } else self.handelError(component, response);
            var allMetaData = component.get('v.allMetaData');
        });
        $A.enqueueAction(action);
    },

    getAllFields: function (component, selectedObject, callback) {
        component.set("v.showLoadingSpinner", true);
        // load all fields for selected object
        var action = component.get("c.getAllFields");
        action.setParams({
            'objectName': selectedObject
        });
        var self = this;
        action.setCallback(this, function (response) {
            var results = [],
                allFields = [];
            var state = response.getState();
            if (state === "SUCCESS") {
                results = response.getReturnValue();
                for(var k in results){
                    console.log(results[k]+'-'+k);
                     allFields.push({
                        key: k, // field name
                        value: results[k], // field label
                        label: results[k]
                    });
                }
                
                for (var field in results) {
                    /*allFields.push({
                        key: field, // field name
                        value: results[field], // field label
                        label: results[field]
                    });*/
                }
                // Sort A->Z
                allFields.sort(function (a, b) {
                    var keyA = a.value,
                        keyB = b.value;
                    if (keyA < keyB) return -1;
                    if (keyA > keyB) return 1;
                    return 0;
                });
                component.set('v.sObjectFields', allFields);
                if (callback) callback();
                component.set("v.showLoadingSpinner", false);
            } else self.handelError(component, response);
        });
        $A.enqueueAction(action);
    },

    getAllReferenceFields: function (component, fieldName, objectName) {
        if (fieldName.includes('__r')) fieldName = fieldName.replace('__r', '__c');
        var action = component.get("c.getAllReferenceFields");
        action.setParams({
            'fieldName': fieldName,
            'objectName': objectName
        });
        var self = this;
        action.setCallback(this, function (response) {
            var state = response.getState();
            var arrReference = [];
            if (state === "SUCCESS") {
                var results = response.getReturnValue();
                for (var field in results) {
                    arrReference.push({
                        key: field,
                        value: results[field]
                    });
                }
                arrReference.sort(function (a, b) {
                    var keyA = a.value,
                        keyB = b.value;
                    if (keyA < keyB) return -1;
                    if (keyA > keyB) return 1;
                    return 0;
                });
                component.set('v.referenceFields', arrReference);
                component.find("selectedReferenceFields").set("v.disabled", false);
            } else self.handelError(component, response);
        });
        $A.enqueueAction(action);
    },

    getGridSettingsFieldsLabel: function (component, objectName, columns) {
        // get label for all fields in grid settings
        var action = component.get("c.getGridSettingsFieldsLabel");
        action.setParams({
            'objectName': objectName,
            'columns': columns
        });
        var self = this;
        action.setCallback(this, function (response) {
            var results = [],
                allFields = [];
            var state = response.getState();
            if (state === "SUCCESS") {
                // get labels                
            } else self.handelError(component, response);
        });
        $A.enqueueAction(action);
    },

    array_move: function (arr, old_index, new_index) {
        if (new_index < 0) {
            new_index = 0;
        }
        if (new_index > arr.length) {
            new_index = arr.length;
        }
        arr.splice(new_index, 0, arr.splice(old_index, 1)[0]);
        return arr;
    },

    removeDuplicatedValue: function (arr, comp) {
        const unique = arr
            .map(e => e[comp])

            // store the keys of the unique objects
            .map((e, i, final) => final.indexOf(e) === i && i)

            // eliminate the dead keys & store unique objects
            .filter(e => arr[e]).map(e => arr[e]);

        return unique;
    },

    doSave: function (component, objectName, selectedTemplate, templateName, columns, callback) {
        var action = component.get("c.save");
        action.setParams({
            'objectName': objectName,
            'selectedTemplate': selectedTemplate,
            'templateName': templateName,
            'columns': columns
        });
        var self = this;
        // set call back
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {

                // get metadadata list
                /* self.getGridSettings(component, function() {
                });*/
                self.showMessages(component, 'success', 'Successfully saved Metadata.');

                if (selectedTemplate != null) {
                    var allMetaData = component.get('v.allMetaData');
                    allMetaData[selectedTemplate].Columns__c = columns;
                    component.set('v.allMetaData', allMetaData);
                }
                if (callback) callback();
            } else self.handelError(component, response);
        });
        // enqueue the action
        $A.enqueueAction(action);
    },

    handelError: function (component, response) {
        var self = this;
        var state = response.getState();
        if (state === "INCOMPLETE") {
            self.showMessages(component, 'error', "Error server: " + response.getReturnValue());
        } else if (state === "ERROR") {
            var errors = response.getError();
            if (errors) {
                if (errors[0] && errors[0].message) {
                    self.showMessages(component, 'error', "Error server: " + errors[0].message);
                }
            } else {
                self.showMessages(component, 'error', "Unknown error");
            }
        }
    },

    showMessages: function (component, messageType, message) {
        component.set("v.showMessage", true);
        component.set("v.messageType", messageType);
        component.set('v.message', message);
        component.set("v.showLoadingSpinner", false);
    },

    dismissMessages: function (component) {
        component.set("v.showMessage", false);
        component.set('v.message', '');
    },
    findElementInArray: function (array, element) {
        var isFound = false;
        for (var k in array) {
            if (array[k].key.localeCompare(element) == 0) {
                isFound = true;
                break;
            }
        }
        if (isFound)
            return true;
        else
            return false;
    }
})