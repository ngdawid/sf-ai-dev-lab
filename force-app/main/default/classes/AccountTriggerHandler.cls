/**
 * Handler for AccountTrigger. Called from the trigger only, holds all logic.
 */
public with sharing class AccountTriggerHandler {
  @TestVisible
  private static final String DESCRIPTION_PREFIX = 'Industry changed to ';
  @TestVisible
  private static final String BLANK_INDUSTRY_PLACEHOLDER = '(none)';

  public void run() {
    if (Trigger.isAfter && Trigger.isUpdate) {
      afterUpdate(
        (List<Account>) Trigger.new,
        (Map<Id, Account>) Trigger.oldMap
      );
    }
  }

  public void afterUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
    Map<Id, String> industryByAccountId = new Map<Id, String>();
    for (Account acc : newAccounts) {
      Account oldAcc = oldMap.get(acc.Id);
      if (oldAcc != null && acc.Industry != oldAcc.Industry) {
        industryByAccountId.put(acc.Id, acc.Industry);
      }
    }
    if (industryByAccountId.isEmpty()) {
      return;
    }

    List<Contact> contacts = [
      SELECT Id, AccountId
      FROM Contact
      WHERE AccountId IN :industryByAccountId.keySet()
      WITH USER_MODE
    ];
    for (Contact con : contacts) {
      con.Description = buildDescription(
        industryByAccountId.get(con.AccountId)
      );
    }
    if (!contacts.isEmpty()) {
      update as user contacts;
    }
  }

  @TestVisible
  private static String buildDescription(String industry) {
    return DESCRIPTION_PREFIX +
      (String.isBlank(industry) ? BLANK_INDUSTRY_PLACEHOLDER : industry);
  }
}
