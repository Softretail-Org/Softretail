@isTest
private class Nego360_Main_Selection_Controller_TEST {

    @isTest static void test_findSupplier() {

        Sup_Supplier__c supplier = new Sup_Supplier__c(Code__c = 'CD01', Name = 'Supplier 1');
        insert supplier;

        system.assert(Nego360_Main_Selection_Controller.findSupplier('Supplier 1').contains('CD01'));
        system.assert(Nego360_Main_Selection_Controller.findSupplier('CD01').contains('Supplier 1'));

    }


    @isTest static void test_getListYears() {

        Nego360_Main_Selection_Controller Nego360_Main_Selection_Controller = new Nego360_Main_Selection_Controller();

        system.assertEquals(6, Nego360_Main_Selection_Controller.getListYears().size());

    }


    @isTest static void test_goToConditionScreen() {

        Sup_Supplier__c supplier = new Sup_Supplier__c(Code__c = 'CD01', Name = 'Supplier 1');
        insert supplier;

        Nego360_Main_Selection_Controller Nego360_Main_Selection_Controller = new Nego360_Main_Selection_Controller();

        Nego360_Main_Selection_Controller.selectedNegoYear = '2016';
        Nego360_Main_Selection_Controller.selectedSupplierId = supplier.Id;

        PageReference pageRef = new PageReference('/apex/Nego360_Main_Edit');
        pageRef.getParameters().put('supplier', supplier.Id);
        pageRef.getParameters().put('negoyear', '2016');

        system.assertEquals( pageRef.getUrl(), Nego360_Main_Selection_Controller.goToConditionScreen().getUrl() );

    }

}