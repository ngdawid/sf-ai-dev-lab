@IsTest
private class AccountIndustryHandlerTest {
  private static Account makeAccount(
    String name,
    String industry,
    Integer contactCount
  ) {
    Account acc = new Account(Name = name, Industry = industry);
    insert acc;
    List<Contact> contacts = new List<Contact>();
    for (Integer i = 0; i < contactCount; i++) {
      contacts.add(
        new Contact(
          LastName = name + ' C' + i,
          AccountId = acc.Id,
          Description = 'original'
        )
      );
    }
    insert contacts;
    return acc;
  }

  private static List<Contact> contactsOf(Id accountId) {
    return [SELECT Description FROM Contact WHERE AccountId = :accountId];
  }

  @IsTest
  static void industryChangeUpdatesAllContacts() {
    Account acc = makeAccount('Acme', 'Banking', 3);

    Test.startTest();
    acc.Industry = 'Technology';
    update acc;
    Test.stopTest();

    List<Contact> contacts = contactsOf(acc.Id);
    Assert.areEqual(3, contacts.size());
    for (Contact c : contacts) {
      Assert.areEqual('Industry changed to Technology', c.Description);
    }
  }

  @IsTest
  static void otherFieldChangeLeavesContactsAlone() {
    Account acc = makeAccount('Acme', 'Banking', 2);

    Test.startTest();
    acc.Name = 'Acme Renamed';
    acc.Industry = 'Banking';
    update acc;
    Test.stopTest();

    for (Contact c : contactsOf(acc.Id)) {
      Assert.areEqual('original', c.Description);
    }
  }

  @IsTest
  static void industryClearedWritesEmptyValue() {
    Account acc = makeAccount('Acme', 'Banking', 1);

    Test.startTest();
    acc.Industry = null;
    update acc;
    Test.stopTest();

    Assert.areEqual(
      'Industry changed to', // the platform trims the trailing space on save
      contactsOf(acc.Id)[0].Description
    );
  }

  @IsTest
  static void onlyChangedAccountsAffectedInBulk() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
      accounts.add(new Account(Name = 'Bulk ' + i, Industry = 'Banking'));
    }
    insert accounts;
    List<Contact> contacts = new List<Contact>();
    for (Account acc : accounts) {
      contacts.add(
        new Contact(
          LastName = acc.Name,
          AccountId = acc.Id,
          Description = 'original'
        )
      );
    }
    insert contacts;

    Test.startTest();
    for (Integer i = 0; i < accounts.size(); i++) {
      if (Math.mod(i, 2) == 0) {
        accounts[i].Industry = 'Energy';
      }
    }
    update accounts;
    Test.stopTest();

    Map<Id, Integer> indexById = new Map<Id, Integer>();
    for (Integer i = 0; i < accounts.size(); i++) {
      indexById.put(accounts[i].Id, i);
    }
    for (Contact c : [
      SELECT AccountId, Description
      FROM Contact
      WHERE AccountId IN :accounts
    ]) {
      String expected = Math.mod(indexById.get(c.AccountId), 2) == 0
        ? 'Industry changed to Energy'
        : 'original';
      Assert.areEqual(expected, c.Description);
    }
  }

  @IsTest
  static void accountWithoutContactsDoesNotFail() {
    Account acc = makeAccount('Lonely', 'Banking', 0);

    Test.startTest();
    acc.Industry = 'Retail';
    update acc;
    Test.stopTest();

    Assert.areEqual(0, contactsOf(acc.Id).size());
  }
}
