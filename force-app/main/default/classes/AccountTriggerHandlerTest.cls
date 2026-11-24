@IsTest
private class AccountTriggerHandlerTest {
  private static final Integer RECORD_COUNT = 200;

  @TestSetup
  static void setup() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < RECORD_COUNT; i++) {
      accounts.add(new Account(Name = 'Acc ' + i, Industry = 'Banking'));
    }
    insert accounts;

    List<Contact> contacts = new List<Contact>();
    for (Account acc : accounts) {
      contacts.add(
        new Contact(
          LastName = 'Con ' + acc.Name,
          AccountId = acc.Id,
          Description = 'Original'
        )
      );
    }
    insert contacts;
  }

  @IsTest
  static void industryChangeUpdatesAllContactsBulk() {
    List<Account> accounts = [SELECT Id FROM Account];
    for (Account acc : accounts) {
      acc.Industry = 'Energy';
    }

    Test.startTest();
    update accounts;
    Test.stopTest();

    List<Contact> contacts = [SELECT Description FROM Contact];
    Assert.areEqual(
      RECORD_COUNT,
      contacts.size(),
      'Expected one contact per account'
    );
    for (Contact con : contacts) {
      Assert.areEqual(
        'Industry changed to Energy',
        con.Description,
        'Description should be overwritten'
      );
    }
  }

  @IsTest
  static void unchangedIndustryLeavesContactsAlone() {
    List<Account> accounts = [SELECT Id FROM Account];
    for (Account acc : accounts) {
      acc.Description = 'Something else changed';
    }

    Test.startTest();
    update accounts;
    Test.stopTest();

    for (Contact con : [SELECT Description FROM Contact]) {
      Assert.areEqual(
        'Original',
        con.Description,
        'Description must not change when Industry is unchanged'
      );
    }
  }

  @IsTest
  static void clearedIndustryWritesPlaceholder() {
    List<Account> accounts = [SELECT Id FROM Account];
    for (Account acc : accounts) {
      acc.Industry = null;
    }

    Test.startTest();
    update accounts;
    Test.stopTest();

    for (Contact con : [SELECT Description FROM Contact]) {
      Assert.areEqual(
        'Industry changed to (none)',
        con.Description,
        'Blank industry should use placeholder'
      );
    }
  }

  @IsTest
  static void onlyChangedAccountsAffectContacts() {
    List<Account> accounts = [SELECT Id FROM Account ORDER BY Name LIMIT 2];
    accounts[0].Industry = 'Retail';
    accounts[1].Industry = 'Banking'; // same value, no change

    Test.startTest();
    update accounts;
    Test.stopTest();

    Contact changed = [
      SELECT Description
      FROM Contact
      WHERE AccountId = :accounts[0].Id
    ];
    Contact unchanged = [
      SELECT Description
      FROM Contact
      WHERE AccountId = :accounts[1].Id
    ];
    Assert.areEqual(
      'Industry changed to Retail',
      changed.Description,
      'Changed account contact updated'
    );
    Assert.areEqual(
      'Original',
      unchanged.Description,
      'Unchanged account contact untouched'
    );
  }
}
