public with sharing class CaseTriggerHandler {
    private static final String CLOSED_CASE_STATUS = 'Closed';

    // Method handles insert, update case to count account case numbers
    public static void updateAccountCaseCounts(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        Map<Id, Integer> openCaseChangesMap = new Map<Id, Integer>();
        Map<Id, Integer> closedCaseChangesMap = new Map<Id, Integer>();

        for (Case caseItem : newCases) {
            if (caseItem.AccountId != null) {
                Integer openChange = 0;
                Integer closedChange = 0;

                if (oldCasesMap != null) {
                    Case oldCase = oldCasesMap.get(caseItem.Id);
                    if (oldCase.Status != caseItem.Status) {
                        if (caseItem.Status == CLOSED_CASE_STATUS) {
                            closedChange++;
                            openChange--;
                        } else if (oldCase.Status == CLOSED_CASE_STATUS) {
                            openChange++;
                            closedChange--;
                        }
                    }
                } else {
                    if (caseItem.Status == CLOSED_CASE_STATUS) {
                        closedChange++;
                    } else {
                        openChange++;
                    }
                }

                openCaseChangesMap.put(caseItem.AccountId, openCaseChangesMap.containsKey(caseItem.AccountId)
                                        ? openCaseChangesMap.get(caseItem.AccountId) + openChange
                                        : openChange);
                
                closedCaseChangesMap.put(caseItem.AccountId, closedCaseChangesMap.containsKey(caseItem.AccountId)
                                        ? closedCaseChangesMap.get(caseItem.AccountId) + closedChange
                                        : closedChange);
            }
        }

        // Check if at least one map is not empty before updating accounts
        if (!openCaseChangesMap.isEmpty() || !closedCaseChangesMap.isEmpty()) {
            updateAccounts(openCaseChangesMap, closedCaseChangesMap);
        }
    }

    // Method handles case deletions to count account case numbers
    public static void handleCaseDeletion(List<Case> deletedCases) {
        Map<Id, Integer> openCaseChangesMap = new Map<Id, Integer>();
        Map<Id, Integer> closedCaseChangesMap = new Map<Id, Integer>();

        for (Case caseItem : deletedCases) {
            if (caseItem.AccountId != null) {
                if (caseItem.Status == CLOSED_CASE_STATUS) {
                    closedCaseChangesMap.put(caseItem.AccountId, closedCaseChangesMap.containsKey(caseItem.AccountId)
                                            ? closedCaseChangesMap.get(caseItem.AccountId) - 1
                                            : -1);
                } else {
                    openCaseChangesMap.put(caseItem.AccountId, openCaseChangesMap.containsKey(caseItem.AccountId)
                                            ? openCaseChangesMap.get(caseItem.AccountId) - 1
                                            : -1);
                }
            }
        }

        // Check if at least one map is not empty before updating accounts
        if (!openCaseChangesMap.isEmpty() || !closedCaseChangesMap.isEmpty()) {
            updateAccounts(openCaseChangesMap, closedCaseChangesMap);
        }
    }

    // Private method to update account records with new case counts
    private static void updateAccounts(Map<Id, Integer> openCaseChangesMap, Map<Id, Integer> closedCaseChangesMap) {
        List<Account> accountsToUpdate = [SELECT
                                                Id,
                                                Number_of_Open_Cases__c,
                                                Number_of_Closed_Cases__c
                                            FROM Account
                                            WHERE Id IN :openCaseChangesMap.keySet()
                                               OR Id IN :closedCaseChangesMap.keySet()];

        for (Account account : accountsToUpdate) {
            if (openCaseChangesMap.containsKey(account.Id)) {
                Integer openCaseChange = openCaseChangesMap.get(account.Id);
                Integer totalOpenCaseCount = account.Number_of_Open_Cases__c != null
                                                ? (Integer) account.Number_of_Open_Cases__c + openCaseChange
                                                : openCaseChange;
                account.Number_of_Open_Cases__c = totalOpenCaseCount;
            }

            if (closedCaseChangesMap.containsKey(account.Id)) {
                Integer closedCaseChange = closedCaseChangesMap.get(account.Id);
                Integer totalClosedCaseCount = account.Number_of_Closed_Cases__c != null
                                                ? (Integer) account.Number_of_Closed_Cases__c + closedCaseChange
                                                : closedCaseChange;
                account.Number_of_Closed_Cases__c = totalClosedCaseCount;
            }
        }

        Database.SaveResult[] results = Database.update(accountsToUpdate, false);
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                for (Database.Error error : result.getErrors()) {
                    System.debug('Updating account case number error: ' + error.getMessage());
                }
            }
        }
    }
}