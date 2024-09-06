@isTest
public class CaseTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
    }

    @isTest
    static void testAfterInsertCases() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 10];
        
        List<Case> cases = new List<Case>();
        for (Account acc : accounts) {
            cases.add(new Case(AccountId = acc.Id, Status = 'New'));
            cases.add(new Case(AccountId = acc.Id, Status = 'Closed'));
        }

        Test.startTest();
        insert cases;
        Test.stopTest();
        
        verifyAccountCaseCounts(accounts, 1, 1);
    }

    @isTest
    static void testAfterUpdateCases() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 10];
        
        List<Case> cases = new List<Case>();
        for (Account acc : accounts) {
            cases.add(new Case(AccountId = acc.Id, Status = 'New'));
        }
        insert cases;

        for (Case caseItem : cases) {
            caseItem.Status = 'Closed';
        }

        Test.startTest();
        update cases;
        Test.stopTest();
        
        verifyAccountCaseCounts(accounts, 0, 1);
    }

    @isTest
    static void testAfterDeleteCases() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 10];
        
        List<Case> cases = new List<Case>();
        for (Account acc : accounts) {
            cases.add(new Case(AccountId = acc.Id, Status = 'Closed'));
        }
        insert cases;
        
        Test.startTest();
        delete cases;
        Test.stopTest();
        
        verifyAccountCaseCounts(accounts, 0, 0);
    }

    @isTest
    static void testBulkCaseInsert() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 10];
        
        List<Case> cases = new List<Case>();
        for (Account acc : accounts) {
            for (Integer i = 0; i < 100; i++) {
                cases.add(new Case(AccountId = acc.Id, Status = 'New'));
            }
        }

        Test.startTest();
        insert cases;
        Test.stopTest();
        
        verifyAccountCaseCounts(accounts, 100, 0);
    }

    @isTest
    static void testBulkCaseUpdate() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 10];
        
        List<Case> cases = new List<Case>();
        for (Account acc : accounts) {
            for (Integer i = 0; i < 100; i++) {
                cases.add(new Case(AccountId = acc.Id, Status = 'New'));
            }
        }
        insert cases;

        for (Case caseItem : cases) {
            caseItem.Status = 'Closed';
        }

        Test.startTest();
        update cases;
        Test.stopTest();
        
        verifyAccountCaseCounts(accounts, 0, 100);
    }

    @isTest
    static void testStatusChangeFromClosed() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 10];
        
        List<Case> cases = new List<Case>();
        for (Account acc : accounts) {
            cases.add(new Case(AccountId = acc.Id, Status = 'Closed'));
        }
        insert cases;

        for (Case caseItem : cases) {
            caseItem.Status = 'New';
        }

        Test.startTest();
        update cases;
        Test.stopTest();
        
        verifyAccountCaseCounts(accounts, 1, 0);
    }

    private static void verifyAccountCaseCounts(List<Account> accounts, Integer expectedOpen, Integer expectedClosed) {
        Map<Id, Account> accountMap = new Map<Id, Account>([
                                                            SELECT 
                                                                Id,
                                                                Number_of_Open_Cases__c,
                                                                Number_of_Closed_Cases__c
                                                            FROM Account
                                                            WHERE Id IN :accounts
                                                        ]);
        
        for (Account acc : accounts) {
            Account updatedAccount = accountMap.get(acc.Id);
            System.assertEquals(expectedOpen, updatedAccount.Number_of_Open_Cases__c);
            System.assertEquals(expectedClosed, updatedAccount.Number_of_Closed_Cases__c);
        }
    }
}