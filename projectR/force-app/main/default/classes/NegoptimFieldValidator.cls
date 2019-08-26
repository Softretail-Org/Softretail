/*
*  Public class that handle all validation logic
*  along with trigger for custom button ( save , submit ) 
*/
public class NegoptimFieldValidator {

    /**
     * Check negoscope name and supplier field validation
     * String name : negoscope Name
     * String supplier : supplier that belong to negoscope
     */
    public Boolean negoScopeCheckDuplication(String name, String supplier, Id negoScopeId) {
        Sup_sup_NegoScope__c NS;
        try {
            NS = [SELECT Name FROM Sup_sup_NegoScope__c WHERE Name = :name AND supplier__c = :supplier AND Id != :negoScopeId LIMIT 1];
        } catch(Exception e) {
            NS = NULL;
        }
        if(NS != NULL) {
            NS.addError(System.Label.MSG_The_Combination_NS_Name_Supplier_Keys_Must_Be_Unique);
            return false;
        }
        return true;
    }
}