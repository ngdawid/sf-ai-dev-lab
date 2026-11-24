/**
 * When an Account's Industry changes, stamps the Description of every related
 * Contact with "Industry changed to <new value>".
 */
public with sharing class AccountIndustryHandler {
  @TestVisible
  private static final String PREFIX = 'Industry changed to ';

  public static void syncContactDescriptions(
    List<Account> newAccounts,
    Map<Id, Account> oldMap
  ) {
    Map<Id, String> industryByAccountId = new Map<Id, String>();
    for (Account acc : newAccounts) {
      Account old = oldMap.get(acc.Id);
      if (old != null && acc.Industry != old.Industry) {
        industryByAccountId.put(acc.Id, acc.Industry);
      }
    }
    if (industryByAccountId.isEmpty()) {
      return;
    }

    List<Contact> toUpdate = new List<Contact>();
    for (Contact c : [
      SELECT Id, AccountId
      FROM Contact
      WHERE AccountId IN :industryByAccountId.keySet()
    ]) {
      String industry = industryByAccountId.get(c.AccountId);
      toUpdate.add(
        new Contact(
          Id = c.Id,
          Description = PREFIX + (industry == null ? '' : industry)
        )
      );
    }
    if (!toUpdate.isEmpty()) {
      update toUpdate;
    }
  }
}
