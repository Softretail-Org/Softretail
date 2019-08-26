({
    MAX_FILE_SIZE: 4500000, // After Base64 Encoding, this is the max file size 4.5 MB
    MAX_CHUNK_FILE_SIZE: 240000,
    CHUNK_SIZE: 120000, //Chunk Max size 950Kb, Maximum Javascript Remoting message size is 1,000,000 characters
    List_Chunks: [],
    
    doProcess: function (component, event) {
        console.log('---doProcess---');
        this.dismissMessages(component);
        component.set("v.uploadInProgress", true);
        // clear files
        component.set("v.fileIdMap", {});
        component.set("v.contentVersions", {});
        component.set("v.fileCount", 0);

        var fileInput = component.find("fileId").get("v.files");
        var file = null, fileType = '';
        if (fileInput != null) file = fileInput[0];
        if (file != null) fileType = file.name.split('.').pop().trim();
        // validate file name
        component.set("v.validFileName", true);
        if (file != null && file.size > 0 && fileType == 'csv') {
            this.processFile(component, event);
        } else {
            this.showMessages(component, 'error', $A.get("$Label.c.MSG_Select_Valid_CSV_File"));
        }
    },
    
    processFile: function (component, event) {
        this.List_Chunks = [];
        // start/show the loading spinner
        component.set("v.showLoadingSpinner", true);
        // get the selected files using aura:id [return array of files]
        var fileInput = component.find("fileId").get("v.files");
        // get the first file using array index[0]
        var file = fileInput[0];
        var self = this;
        // validate file name
        self.validateFileName(component, event, file);
    },

    validateFileName: function (component, event, file) {
        var instance = component.get("v.instance");
        // set value in class properties
        instance.errorMessage = '';
        instance.flowType = null;
        instance.categoryName = null;
        instance.isWeekly = false;
        instance.isMonthly = false;
        instance.year = null;
        instance.month = null;
        var action = component.get("c.validateFileName");
        action.setParams({
            fileName: file.name,
            instance: instance
        });
        var self = this;
        // set call back
        action.setCallback(this, function (response) {
            // handel the response
            var objClass = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.instance', objClass);
                if (objClass.errorMessage != '') {
                    component.set("v.validFileName", false);
                    self.showMessages(component, 'error', "Error: " + objClass.errorMessage);
                    component.set("v.showLoadingSpinner", false);
                    component.set("v.uploadInProgress", false);
                } else {
                    // process uploading file
                    self.processHelper(component, event, file);
                }
            } else self.handelError(component, response);
        });
        // enqueue the action
        $A.enqueueAction(action);
    },

    processHelper: function (component, event, file) {
        var self = this;
        if (component.get("v.validFileName") == true) {
            // create a FileReader object
            var objFileReader = new FileReader();
            objFileReader.onload = $A.getCallback(function () {
                var data = objFileReader.result;
                var base64 = 'base64,';
                var dataStart = data.indexOf(base64) + base64.length;
                data = data.substring(dataStart);
                var csvContents = atob(data);
                var lines = csvContents.split("\n");
                var fileContents = '';
                var fileNumber = 1;
                var isLastFile = false;
                var fileContentsSize = 0;
                // call the uploadProcess method
                for (var i = 0; i < lines.length; i++) {
                    var newLineSize = new Blob(lines[i] + "\n").size;
                    if (fileContents == '') {
                        fileContents = lines[i];
                        fileContentsSize = newLineSize;
                    } else {
                        fileContents = fileContents + "\n" + lines[i];
                        fileContentsSize = fileContentsSize + newLineSize;
                    }
                    var nextLineSize = 0;
                    if (i < lines.length - 1) nextLineSize = new Blob(lines[i + 1] + "\n").size;
                    if ((i === (lines.length - 1)) || (fileContentsSize < self.MAX_CHUNK_FILE_SIZE && (fileContentsSize + nextLineSize) > self.MAX_CHUNK_FILE_SIZE) || (fileContentsSize >= self.MAX_CHUNK_FILE_SIZE)) {
                        if (i == lines.length - 1) isLastFile = true;
                        self.processFileChunk(component, file, fileContents + "\n", fileNumber, isLastFile);
                        fileContents = '';
                        fileContentsSize = 0;
                        if (i < lines.length - 1) fileNumber = fileNumber + 1;
                    }
                }
                if (isLastFile) {
                    console.log('isLastFile >>> ' + isLastFile);
                    self.uploadAll(component);
                }
            });
            ////objFileReader.readAsText(file, "UTF-8");
            objFileReader.readAsDataURL(file);
        }
    },
    
    processFileChunk: function (component, file, fileContents, fileNumber, isLastFile) {
        var filechunk = {
            fileName: file.name,
            fileContents: fileContents,
            fileNumber: fileNumber,
            isLastFile: isLastFile
        };
        // set a default size or startpostiton as 0
        var startPosition = 0;
        // calculate the end size or endPostion using Math.min() function which is return the min. value 
        var endPosition = Math.min(filechunk.fileContents.length, startPosition + this.CHUNK_SIZE);
        // start with the initial chunk
        this.processChunk(component, filechunk, startPosition, endPosition, 0);
    },
    
    processChunk: function (component, file, startPosition, endPosition, chunkNumber) {
        console.log('---processChunk---');
        // call the apex method saveFile
        var chunk = file.fileContents.substring(startPosition, endPosition);
        this.List_Chunks.push({
            file: file,
            chunkNumber: chunkNumber,
            fileNumber: file.fileNumber,
            startPosition: startPosition,
            endPosition: endPosition
        });
        startPosition = endPosition;
        endPosition = Math.min(file.fileContents.length, startPosition + this.CHUNK_SIZE);
        // check if the start postion is still less then end postion 
        // then call again 'processChunk' method ,
        // else, display msg and hide the loading spinner
        if (startPosition < endPosition) {
            this.processChunk(component, file, startPosition, endPosition, chunkNumber++);
        }
    },
    
    uploadAll: function (component) {
        console.log('---uploadAll---');
        if (this.List_Chunks.length > 0) {
            this.uploadChunk(component, this.List_Chunks[0], 0, '');
        }
    },

    uploadChunk: function (component, filechunk, counter, fileId) {
        if (filechunk.startPosition == 0) {
            fileId = '';
        }
        // call the apex method saveFile
        var chunk = filechunk.file.fileContents.substring(filechunk.startPosition, filechunk.endPosition);
        var action = component.get("c.saveFile");
        var fileName = filechunk.file.fileName;
        action.setParams({
            fileName: filechunk.file.fileName,
            fileContents: btoa(chunk),
            fileId: fileId,
            fileNumber: filechunk.file.fileNumber
        });
        var self = this;
        // set call back
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.uploadPercentage", 100 * counter / this.List_Chunks.length);
                // store the response / File Id
                fileId = response.getReturnValue();
                // fill map of files inserted
                var fileIdMap = component.get("v.fileIdMap");
                fileIdMap[filechunk.file.fileNumber] = fileId;
                component.set("v.fileIdMap", fileIdMap);

                counter++;
                if (this.List_Chunks.length <= counter) {
                    // get all files
                    self.getContentVersions(component, fileIdMap);
                    self.doImport(component, fileName);
                    component.set("v.uploadPercentage", 100);
                    component.set("v.uploadComplete", true);
                    component.set("v.uploadInProgress", false);
                    return;
                }
                self.uploadChunk(component, this.List_Chunks[counter], counter, fileId);
                // handel the response errors
            } else self.handelError(component, response);
        });
        // enqueue the action
        $A.enqueueAction(action);
    },

    getContentVersions: function (component, fileIdMap) {
        var action = component.get("c.getContentVersions");
        action.setParams({
            fileIdMap: component.get("v.fileIdMap")
        });
        var self = this;
        // set call back
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var contentVersions = response.getReturnValue();
                component.set("v.contentVersions", contentVersions);
                component.set("v.fileCount", contentVersions.length);
                // handel the response errors        
            } else self.handelError(component, response);
        });
        // enqueue the action
        $A.enqueueAction(action);
    },

    doImport: function (component, fileName) {
        var instance = component.get("v.instance");
        // set value in class properties
        instance.errorMessage = '';
        instance.processingMessage = '';
        // call import
        var action = component.get("c.import");
        action.setParams({
            fileName: fileName,
            fileIdMap: component.get("v.fileIdMap"),
            instance: instance
        });
        var self = this;
        // set call back
        action.setCallback(this, function (response) {
            // handel the response
            var objClass = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.instance', objClass);
                if (objClass.errorMessage != '') {
                    self.showMessages(component, 'error', "Error: " + objClass.errorMessage);
                } else {
                    self.showMessages(component, 'success', objClass.processingMessage);
                }
            } else self.handelError(component, response);
        });
        // enqueue the action
        $A.enqueueAction(action);
    },

    getMarketHeadTabURL: function (component) {
        var action = component.get("c.getMarketHeadTabURL");
        var self = this;
        // set call back
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.url", response.getReturnValue());
            } else self.handelError(component, response);
        });
        // enqueue the action
        $A.enqueueAction(action);
    },

    getObjectType: function (component) {
        var action = component.get("c.getObjectType");
        var self = this;
        // set call back
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set('v.ObjectType', JSON.parse(response.getReturnValue()));
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
        component.set("v.uploadInProgress", false);
    },

    dismissMessages: function (component) {
        component.set("v.showMessage", false);
        component.set('v.message', '');
    },
})