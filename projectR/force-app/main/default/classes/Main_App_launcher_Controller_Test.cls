@isTest 
private class Main_App_launcher_Controller_Test {
    @isTest static void test_constructor() {
        Main_App_launcher_Controller launcher = new Main_App_launcher_Controller();
        system.assertEquals(9, launcher.appMenuItems.size());        
    }
}