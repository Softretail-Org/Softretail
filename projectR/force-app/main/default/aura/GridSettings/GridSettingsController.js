({
    doInit: function (component, event, helper) {
        window.arrSelectedField = [];
        window.separatorIndex = 0;
        window.fieldReferenceName = '';
        component.set("v.showLoadingSpinner", true);
        // get metadadata list
        helper.getGridSettings(component, function () {
            component.set("v.showLoadingSpinner", false);
        });
        //Fetch object list
        helper.getObjectList(component);
    },

    onObjectSelectionChange: function (component, event, helper) {
        component.set('v.showColorPicker', false);
        helper.dismissMessages(component);
        window.arrSelectedField = [];
        window.separatorIndex = 0;
        window.fieldReferenceName = '';
        component.set('v.addedFields', arrSelectedField);
        component.set('v.jsonGenerated', '');
        var selectedObject = component.find("objectList").get("v.value");
        component.set('v.selectedObject', selectedObject);
        // get all fields for sObject
        if (selectedObject != null) helper.getAllFields(component, selectedObject);
    },

    onSelectedTemplateChange: function (component, event, helper) {
        component.set('v.showColorPicker', false);
        helper.dismissMessages(component);
        window.arrSelectedField = [];
        window.separatorIndex = 0;
        window.fieldReferenceName = '';
        component.set('v.selectedObject', '');
        component.set('v.addedFields', arrSelectedField);
        component.set('v.jsonGenerated', '');
        var selectedTemplate = component.get("v.selectedTemplate");
        if (selectedTemplate == 'Custom_Template') {
            component.set('v.isCustomTemplate', true);
            component.set('v.templateName', '');
            component.find("templatename").set("v.disabled", false);
            component.find("objectList").set("v.disabled", false);
        } else {
            component.find("templatename").set("v.disabled", true);
            component.find("objectList").set("v.disabled", true);
            component.set('v.isCustomTemplate', false);
            component.set('v.templateName', selectedTemplate);
            var template = component.get('v.allMetaData')[selectedTemplate];
            if (template != undefined && template != null) {
                // load fields object for selected template
                if (template.Object_Name__c != null) {
                    helper.getAllFields(component, template.Object_Name__c);
                }
                component.set('v.selectedObject', template.Object_Name__c);
                component.set('v.jsonGenerated', template.Columns__c);
                var columns = JSON.parse(template.Columns__c);
                // get label for all fields for selected template
                var action = component.get("c.getGridSettingsFieldsLabel");
                action.setParams({
                    'objectName': template.Object_Name__c,
                    'columns': template.Columns__c
                });
                action.setCallback(this, function (response) {
                    var gridFields = [];
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var results = response.getReturnValue();
                        for (var key in results) {
                            if (key.search('Separator') == 0) {
                                arrSelectedField.push({
                                    key: '--- Separator(' + (separatorIndex) + ') ---',
                                    value: 'Separator' + separatorIndex,
                                    isInputField: results[key]["isInputField"],
                                    isSeparator: true,
                                    bgColor: results[key]["bgColor"] || '#FFFFFF'
                                });
                                separatorIndex++;
                            } else {
                                arrSelectedField.push({
                                    key: results[key]["fieldLabel"],
                                    value: key,
                                    isInputField: results[key]["isInputField"],
                                    bgColor: results[key]["bgColor"] || '#FFFFFF'
                                });
                            }
                        }
                        component.set('v.addedFields', arrSelectedField);
                    } else helper.handelError(component, response);
                });
                $A.enqueueAction(action);
            }
        }
    },

    onClear: function (component, event, helper) {
        component.set('v.showColorPicker', false);
        ////helper.dismissMessages(component);
        window.arrSelectedField = [];
        window.separatorIndex = 0;
        window.fieldReferenceName = '';
        ////component.set('v.selectedObject', '');
        component.set('v.addedFields', arrSelectedField);
        component.set('v.jsonGenerated', '');
    },

    onSelectedFieldsChange: function (component, event, helper) {
        var selectedFields = component.find('selectedFields');
        fieldReferenceName = selectedFields.get('v.value');
        if (selectedFields.get('v.value').includes(' >') && !selectedFields.get('v.value').includes(';')) {
            var selectedFieldsRef = component.find('selectedReferenceFields');
            component.set('v.selectedReferenceFields', '');
            component.set('v.displayReference', true);
            component.find("selectedReferenceFields").set("v.disabled", true);
            component.set('v.currentReferenceFieldName', selectedFields.get('v.value').replace(' >', ''));
            var fieldName = '';
            var allFields = component.get('v.sObjectFields');
            for (var field in allFields) {
                if (allFields[field].value == selectedFields.get('v.value')) {
                    fieldName = allFields[field].key;
                    break;
                }
            }
            var objectName = component.get('v.selectedObject');
            helper.getAllReferenceFields(component, fieldName, objectName);
        } else component.set('v.displayReference', false);
    },

    onSelectedInOut: function (component, event, helper) {
        var selectedInOutValue = component.get("v.selectedInOutValue");
        if (selectedInOutValue == 'I') component.set("v.isInputField", true);
        else component.set("v.isInputField", false);
    },

    addField: function (component, event, helper) {
        var selectedFields = component.find('selectedFields');
        var selectedFieldsRef = component.find('selectedReferenceFields');
        var allFields = component.get('v.sObjectFields');
        var allFieldsReference = component.get('v.referenceFields');
        var fieldName = '',
            fieldNamereference = [],
            selectedValue = '',
            selectedValueRef = [];
        var fieldNameSplited = [];
        var isInputField = component.get("v.isInputField");
        if (selectedFields.get('v.value') == '') {
            return;
        }
        if (!selectedFields.get('v.value').includes(';')) {
            for (var field in allFields) {
                if (allFields[field].value == selectedFields.get('v.value')) fieldName = allFields[field].key;
            }
        } else {
            var splited = selectedFields.get('v.value').split(';');
            for (var k in allFields) {
                for (var l = 0; l < splited.length; l++) {
                    var s = splited[l];
                    var p = allFields[k].value;
                    var q = allFields[k].key;
                    if (s.includes('>')) s = s.replace(/>/g, '');
                    if (p.includes('>')) p = p.replace(/>/g, '');
                    if (p == s) fieldNameSplited.push(q);
                }
            }
        }
        if (selectedFieldsRef != undefined) {
            var splitedRef = [];
            if (selectedFieldsRef.get('v.value').includes(';'))
                splitedRef = selectedFieldsRef.get('v.value').split(';');
            else
                splitedRef.push(selectedFieldsRef.get('v.value'));

            for (var t in allFieldsReference) {
                for (var k = 0; k < splitedRef.length; k++) {
                    if (allFieldsReference[t].value == splitedRef[k])
                        fieldNamereference[k] = allFieldsReference[t].key;
                    selectedValueRef[k] = splitedRef[k];
                }
            }
        }
        selectedValue = selectedFields.get('v.value');
        if (selectedValue.includes('>')) {
            selectedValue = selectedValue.replace(/>/g, '');
        }
        if (selectedFieldsRef != undefined && !selectedValue.includes(';')) {
            if (selectedValueRef.length != 0 && fieldNamereference.length != 0)
                for (var l = 0; l < selectedValueRef.length; l++)
                    arrSelectedField.push({
                        key: selectedValue.trim() + '.' + selectedValueRef[l],
                        value: fieldName.trim() + '.' + fieldNamereference[l],
                        isInputField: component.get("v.isInputField")
                    });
            else
                arrSelectedField.push({
                    key: selectedValue,
                    value: fieldName,
                    isInputField: component.get("v.isInputField")
                });
        } else {
            var splitselectedValue = '';
            if (selectedValue.includes(';')) {
                splitselectedValue = selectedValue.split(';');
                for (var i = 0; i < splitselectedValue.length; i++)
                    arrSelectedField.push({
                        key: splitselectedValue[i],
                        value: fieldNameSplited[i],
                        isInputField: component.get("v.isInputField")
                    });
            } else
                arrSelectedField.push({
                    key: selectedValue,
                    value: fieldName,
                    isInputField: component.get("v.isInputField")
                });
        }
        for (var k in arrSelectedField) {
            var fieldVal1 = arrSelectedField[k].key;
            var fieldKey1 = arrSelectedField[k].value;
            var isMatched = fieldVal1.match(/[0-9]+/g);
            //// var indexOfValue = -1;
            ////if (arrSelectedField[k].key == selectedValue)
            ////   indexOfValue = k;
            if (isMatched != null && !selectedValue.includes(';') && fieldVal1 == selectedValue) {

                var fieldKeyTab1 = fieldKey1.split(/[0-9]+/g);
                var fieldValTab1 = fieldVal1.split(/[0-9]+/g);

                for (var k in allFields) {

                    var fieldVal2 = allFields[k].value;
                    var fieldKey2 = allFields[k].key;
                    var fieldKeyTab2 = fieldKey2.split(/[0-9]+/g);
                    var fieldValTab2 = fieldVal2.split(/[0-9]+/g);
                    var sameKey = false;
                    if (fieldValTab2.length == fieldValTab1.length) {
                        var same = true;
                        for (var i = 0; i < fieldValTab2.length; i++) {
                            if (fieldValTab2[i].localeCompare(fieldValTab1[i]) != 0) {
                                same = false;
                            }
                        }
                        sameKey = same;
                    }
                    var add = !helper.findElementInArray(allFields, allFields[k].value);
                    if (sameKey && add)
                        arrSelectedField.push({
                            key: allFields[k].value,
                            value: allFields[k].key,
                            isInputField: component.get("v.isInputField")
                        });

                }

                ////arrSelectedField.splice(indexOfValue, 1);
            }
        }
        arrSelectedField = helper.removeDuplicatedValue(arrSelectedField, 'value');
        component.set('v.addedFields', arrSelectedField);
    },

    removefield: function (component, event, helper) {
        var selectedFields = component.find('insertedFields');
        var selectedFieldsRef = component.find('selectedReferenceFields');
        var index = -1;
        var IndexRef = -1;
        var indexTotremove = [];
        var selectedToRemove = selectedFields.get('v.value');

        var isMultipleSelection = false;
        isMultipleSelection = selectedToRemove.includes(';');

        if (isMultipleSelection) {
            var selectedToRemoveList = selectedToRemove.split(';');
            for (var i = 0; i < selectedToRemoveList.length; i++) {
                for (var k in arrSelectedField) {
                    index = -1;
                    if (arrSelectedField[k].key == selectedToRemoveList[i]) index = k;
                    if (index > -1) {
                        if (!indexTotremove.includes(index))
                            indexTotremove.push(index);
                        break;
                    }
                }
            }
            indexTotremove.sort(function (a, b) {
                return b - a
            });
            for (var l in indexTotremove) {
                arrSelectedField.splice(indexTotremove[l], 1);
            }
        } else {
            index = -1;
            for (var k in arrSelectedField) {
                if (arrSelectedField[k].key == selectedToRemove) {
                    index = k;
                }
            }
            if (index > -1) arrSelectedField.splice(index, 1);
            //added for remove all field related like 'Client Clust1,Client Clust2 ...':
            var ismatch = selectedToRemove.match(/[0-9]+/g);
            var indexofrelated = -1;
            var isfoundInFields = false;
            if(ismatch != null){
                for(var l = 0 ;l <=12;l++){
                    selectedToRemove = selectedToRemove.replace(/[0-9]+/g,l);
                    isfoundInFields = helper.findElementInArray(arrSelectedField, selectedToRemove);
                    if(isfoundInFields){
                        for(var selected in arrSelectedField){
                            if(arrSelectedField[selected].key == selectedToRemove)
                               indexofrelated = selected;
                            if (indexofrelated > -1) arrSelectedField.splice(indexofrelated, 1);
                        }
                    }
                }
            }
            //
        }
        component.set('v.addedFields', arrSelectedField);
    },

    addSeparator: function (component, event, helper) {
        arrSelectedField.push({
            key: '--- Separator(' + separatorIndex + ') ---',
            value: 'Separator' + separatorIndex,
            isInputField: component.get("v.isInputField"),
            isSeparator: true
        });
        component.set('v.addedFields', arrSelectedField);
        separatorIndex++;
    },

    //old method :
    /*moveUpSelectedColumnsList: function(component, event, helper) {
        var oldIndex = -1;
        var selectedcomponent = component.find('insertedFields');
        for (var k in arrSelectedField) {
            if (arrSelectedField[k].key == selectedcomponent.get('v.value'))
                oldIndex = k;
        }
        arrSelectedField = helper.array_move(arrSelectedField, parseInt(oldIndex), parseInt(oldIndex) - 1);
        component.set('v.addedFields', arrSelectedField);
    },*/

    //new method:
    moveUpSelectedColumnsList: function (component, event, helper) {
        var oldIndex = -1;
        var oldIndexList = [];
        var selectedcomponent = component.find('insertedFields');
        var singleItem = '';
        var multipleItem = [];
        var selectedItems = selectedcomponent.get('v.value');
        if (!selectedItems.includes(';'))
            singleItem = selectedItems;
        else
            multipleItem = selectedItems.split(';');
        if (singleItem != '') {
            for (var k in arrSelectedField) {
                if (arrSelectedField[k].key == singleItem) {
                    oldIndex = k;
                    break;
                }
            }
            arrSelectedField = helper.array_move(arrSelectedField, parseInt(oldIndex), parseInt(oldIndex) - 1);
            component.set('v.addedFields', arrSelectedField);
        } else {
            for (var k in arrSelectedField) {
                for (var l = 0; l < multipleItem.length; l++) {
                    if (arrSelectedField[k].key == multipleItem[l]) {
                        oldIndexList[l] = k;
                        break;
                    }
                }
            }
            oldIndexList.sort(function (a, b) {
                return a - b
            });
            for (var t = 0; t < oldIndexList.length; t++) {
                arrSelectedField = helper.array_move(arrSelectedField, parseInt(oldIndexList[t]), parseInt(oldIndexList[t]) - 1);
            }

            component.set('v.addedFields', arrSelectedField);
        }
    },

    //old method:
    /*moveDownSelectedColumnsList: function(component, event, helper) {
        var oldIndex = -1;
        var selectedcomponent = component.find('insertedFields');
        for (var k in arrSelectedField) {
            if (arrSelectedField[k].key == selectedcomponent.get('v.value'))
                oldIndex = k;
        }
        arrSelectedField = helper.array_move(arrSelectedField, parseInt(oldIndex), parseInt(oldIndex) + 1);
        component.set('v.addedFields', arrSelectedField);
    },*/

    //new method:
    moveDownSelectedColumnsList: function (component, event, helper) {
        var oldIndex = -1;
        var oldIndexList = [];
        var selectedcomponent = component.find('insertedFields');
        var singleItem = '';
        var multipleItem = [];
        var selectedItems = selectedcomponent.get('v.value');
        if (!selectedItems.includes(';'))
            singleItem = selectedItems;
        else
            multipleItem = selectedItems.split(';');
        if (singleItem != '') {
            for (var k in arrSelectedField) {
                if (arrSelectedField[k].key == singleItem) {
                    oldIndex = k;
                    break;
                }
            }
            arrSelectedField = helper.array_move(arrSelectedField, parseInt(oldIndex), parseInt(oldIndex) + 1);
            component.set('v.addedFields', arrSelectedField);
        } else {
            for (var k in arrSelectedField) {
                for (var l = 0; l < multipleItem.length; l++) {
                    if (arrSelectedField[k].key == multipleItem[l]) {
                        oldIndexList[l] = k;
                        break;
                    }
                }
            }
            oldIndexList.sort(function (a, b) {
                return b - a
            });
            for (var t = 0; t < oldIndexList.length; t++) {
                arrSelectedField = helper.array_move(arrSelectedField, parseInt(oldIndexList[t]), parseInt(oldIndexList[t]) + 1);
            }

            component.set('v.addedFields', arrSelectedField);
        }
    },
    generateJson: function (component, event, helper) {
        var savedFields = [];
        if (arrSelectedField != undefined) {
            for (var field in arrSelectedField) {
                if (arrSelectedField[field].value.includes('.')) {
                    var referenceApiName = arrSelectedField[field].value.split('.')[1];
                    if (referenceApiName.includes('Product2')) referenceApiName = 'Product__r';
                    savedFields.push({
                        FieldName: referenceApiName + '.' + arrSelectedField[field].value.split('.')[2],
                        isInputField: arrSelectedField[field].isInputField,
                        bgColor: arrSelectedField[field].bgColor ? arrSelectedField[field].bgColor : '#FFFFFF'
                    });
                } else {
                    var separatorVal = arrSelectedField[field].value;
                    if (separatorVal.includes('Separator')) separatorVal = '';
                    savedFields.push({
                        FieldName: separatorVal,
                        isInputField: arrSelectedField[field].isInputField,
                        bgColor: arrSelectedField[field].bgColor ? arrSelectedField[field].bgColor : '#FFFFFF'
                    });
                }
            }
            savedFields = JSON.stringify(savedFields);
            component.set('v.jsonGenerated', savedFields);
        }
    },

    copyJson: function (component, event, helper) {
        var el = document.getElementById('jsonData');
        el.select();
        document.execCommand('copy');
        alert("successfly copied !!");
    },

    // saving custom metadata record
    doSave: function (component, event, helper) {
        helper.dismissMessages(component);
        var objectName = component.get('v.selectedObject');
        var isCustomTemplate = component.get('v.isCustomTemplate');
        var templateName = component.get('v.templateName');
        var selectedTemplate = component.get('v.selectedTemplate');

        if (objectName != undefined && objectName != '') {
            if ((isCustomTemplate && (templateName != undefined && templateName != '')) ||
                (!isCustomTemplate && (selectedTemplate != undefined && selectedTemplate != 'Custom_Template'))) {
                if (arrSelectedField != undefined) {
                    var action = component.get('c.generateJson');
                    action.setCallback(this, function (response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                            var columns = component.get('v.jsonGenerated');
                            if (selectedTemplate == undefined || selectedTemplate == 'Custom_Template') selectedTemplate = null;
                            component.set("v.showLoadingSpinner", true);
                            helper.doSave(component, objectName, selectedTemplate, templateName, columns, function () {
                                component.set("v.showLoadingSpinner", false);
                            });
                            this.onClear(component, event, helper);
                        } else helper.handelError(component, response);
                    });
                    $A.enqueueAction(action);
                }
            } else {
                helper.showMessages(component, 'error', "You must select or enter template name.");
            }
        } else {
            helper.showMessages(component, 'error', "You must select object name.");
        }
    },
    onSelectedInsertedFieldsChange: function (component, event, helper) {
        component.set('v.showColorPicker', true);
        var selectedInsertedFields = component.find('insertedFields');
        var selectedInsertedFieldsValue = selectedInsertedFields.get('v.value');
        var selectedInsertedFieldsValuesTable = selectedInsertedFieldsValue.split(';');
        var Allfields = window.arrSelectedField;
        var colors = [];
        var unicolor = true;
        for (var index in Allfields) {
            if (selectedInsertedFieldsValuesTable.includes(Allfields[index]['key'])) {
                var color = Allfields[index]['bgColor'];
                if (!colors.includes(color)) {
                    if (colors.length > 0) {
                        unicolor = false;
                        break;
                    } else {
                        colors.push(color);
                    }
                }
            }
        }
        if (unicolor && colors.length > 0) {
            component.find('ColorPicker').set('v.value', colors[0]);
        } else {
            component.find('ColorPicker').set('v.value', '#FFFFFF');
        }
    },
    confirmColor: function (component, event, helper) {
        var changed = false;
        if (component.find('ColorPicker')) {
            var selectedInsertedFields = component.find('insertedFields');
            var selectedInsertedFieldsValue = selectedInsertedFields.get('v.value');
            var selectedInsertedFieldsValuesTable = selectedInsertedFieldsValue.split(';');
            var Allfields = arrSelectedField;
            var colorValue = component.find('ColorPicker').get('v.value');
            console.log('::::::::::' + colorValue);
            for (var index in Allfields) {
                if (selectedInsertedFieldsValuesTable.includes(Allfields[index]['key'])) {
                    if (colorValue && colorValue.match('^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$')) {
                        Allfields[index]['bgColor'] = colorValue;
                        changed = true;
                    }
                }
            }
            arrSelectedField = Allfields;
            if (changed) {
                helper.showMessages(component, 'info', "Background color changed.");
            } else {
                helper.showMessages(component, 'info', "Background color not changed.");
            }
        }
        component.set('v.showColorPicker', false);
    },
    dismissColorPicker: function (component, event, helper) {
        component.set('v.showColorPicker', false);
    }
})