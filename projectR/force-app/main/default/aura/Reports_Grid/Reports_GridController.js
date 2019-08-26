({
    doInit : function(component, event, helper) {
        var reportList = [];
        var actiongetReports = component.get("c.getReportByFolderName");
        actiongetReports.setParams({
            'id' : component.get('v.folderName'),
        });
        actiongetReports.setCallback(this, function(response) {
            var state1 = response.getState();
            if (state1 === "SUCCESS") {
                var results = response.getReturnValue();
                for(var k in results){
                        reportList.push({Id:results[k].Id,Name:results[k].Name,DeveloperName:results[k].DeveloperName});
                }
                component.set('v.listOfReport', reportList);
            } else helper.handelError(component, response);
        });
        $A.enqueueAction(actiongetReports);
        /////////////////////////////////////////////////////
        var actiongetFolderName = component.get("c.getFolderNameById");
        actiongetFolderName.setParams({
            'id' : component.get('v.folderName'),
        });
        actiongetFolderName.setCallback(this, function(re) {
            var state1 = re.getState();
            var splited = '';
            if (state1 === "SUCCESS") {
                var results = re.getReturnValue();
                if(results != ''){
                    splited = results.split('_');
                    component.set('v.selectedFolder', splited[0]);
                    component.set('v.selectedFolderApiName', splited[1]);
                }
            } else helper.handelError(component, re);
        });
        $A.enqueueAction(actiongetFolderName);
        /////////////////////////////////////////////////////
        var allCategoryAction = component.get("c.getAllCategoriesLevel1");
        allCategoryAction.setCallback(this, function(rt) {
            var state1 = rt.getState();
            if (state1 === "SUCCESS") {
                var results = rt.getReturnValue();
                component.set('v.allCategoryList', results);
            } else helper.handelError(component, rt);
        });
        $A.enqueueAction(allCategoryAction);
         /////////////////////////////////////////////////////
        var actionBanners = component.get("c.getBannersWithMasterBu");
        actionBanners.setCallback(this, function(rtb) {
            var state1 = rtb.getState();
            if (state1 === "SUCCESS") {
                var data = [];
                var results = rtb.getReturnValue();
                for(var k in results) {
                    data.push({Name: results[k].Name, NameEncode: results[k].Name.replace(/\+/g,'%2B')});
                }
                component.set('v.allBanners', data);
            } else helper.handelError(component, rtb);
        });
        $A.enqueueAction(actionBanners);
    }
})