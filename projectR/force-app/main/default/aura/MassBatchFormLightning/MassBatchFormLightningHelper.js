({pollApex : function(component, event, helper) { 
    helper.callApexMethod(component,helper);
},
  callApexMethod : function (component,helper){    
      var action = component.get("c.getJobs");
      action.setCallback(this, function(response) {
          component.set('v.jobs', response.getReturnValue());
          /*for (var i = 0; i < response.getReturnValue().length;i++){
              if(response.getReturnValue()[i].Status != 'Completed' && response.getReturnValue()[i].Status != 'Aborted' && response.getReturnValue()[i].Status != 'Failed') {
                isPollerActive = true;
                break;
            }
          }*/
      });
      $A.enqueueAction(action);
     
       /*window.setInterval(
              $A.getCallback(function() { 
                  helper.callApexMethod(component,helper);
              }), 5000
          );*/
  }
 })