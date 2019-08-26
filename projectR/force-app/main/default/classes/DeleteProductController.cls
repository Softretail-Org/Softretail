public with sharing class DeleteProductController extends NegoptimBaseController {

    public Product2 product {get; set;}
    
    public DeleteProductController(ApexPages.Standardcontroller stdController) {
        product = (Product2)stdController.getRecord();
    }
    
    // delete product
    public PageReference deleteProduct() {
        try {
            if (product != null) {
                if(checkDeletibility(Product2.SObjectType)) {
                    Database.DeleteResult result = Database.delete(product);
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ' \n';
                        }
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                        return null;
                    }
                }
            }
        } catch(System.DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
            return null;
        }
        Schema.DescribeSObjectResult result = Product2.SObjectType.getDescribe();
        PageReference pageRef = new PageReference('/' + result.getKeyPrefix());
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public PageReference cancel() {
        return new PageReference('/' + product.Id);
    }
}