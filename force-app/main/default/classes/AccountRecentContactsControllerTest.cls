@IsTest
private class AccountRecentContactsControllerTest {
  private static final Integer BULK_CONTACT_COUNT = 251;
  private static final String BULK_ACCOUNT_NAME = 'Bulk Account';
  private static final String OTHER_ACCOUNT_NAME = 'Other Account';
  private static final String EMPTY_ACCOUNT_NAME = 'Empty Account';
  private static final Integer OTHER_ACCOUNT_CONTACT_COUNT = 3;

  @TestSetup
  static void setupTestData() {
    List<Account> accounts = TestDataFactory.createAccounts(3, false);
    accounts[0].Name = BULK_ACCOUNT_NAME;
    accounts[1].Name = OTHER_ACCOUNT_NAME;
    accounts[2].Name = EMPTY_ACCOUNT_NAME;
    insert accounts;

    List<Contact> contacts = TestDataFactory.createContacts(
      new List<Account>{ accounts[0] },
      BULK_CONTACT_COUNT,
      false
    );
    contacts.addAll(
      TestDataFactory.createContacts(
        new List<Account>{ accounts[1] },
        OTHER_ACCOUNT_CONTACT_COUNT,
        false
      )
    );
    insert contacts;
  }

  private static Id getAccountId(String accountName) {
    return [SELECT Id FROM Account WHERE Name = :accountName LIMIT 1].Id;
  }

  @IsTest
  static void shouldReturnAtMostFive_WhenAccountHasManyContacts() {
    Id accountId = getAccountId(BULK_ACCOUNT_NAME);

    Test.startTest();
    List<Contact> contacts = AccountRecentContactsController.getRecentContacts(
      accountId
    );
    Test.stopTest();

    Assert.areEqual(
      AccountRecentContactsController.MAX_CONTACTS,
      contacts.size(),
      'Only the 5 most recent of ' +
        BULK_CONTACT_COUNT +
        ' Contacts should be returned'
    );
  }

  @IsTest
  static void shouldOrderByLastModifiedDateThenIdDescending_WhenContactsReturned() {
    Id accountId = getAccountId(BULK_ACCOUNT_NAME);
    // LastModifiedDate can't be set in tests. The bulk insert gives most Contacts the same value but can
    // span a second boundary, so the exact order depends on both keys: newest first, ties by Id DESC.
    // The expected Ids come from an independent query on both keys and are compared exactly.
    List<Id> expectedIds = new List<Id>();
    for (Contact expected : [
      SELECT Id
      FROM Contact
      WHERE AccountId = :accountId
      ORDER BY LastModifiedDate DESC, Id DESC
      LIMIT :AccountRecentContactsController.MAX_CONTACTS
    ]) {
      expectedIds.add(expected.Id);
    }

    Test.startTest();
    List<Contact> contacts = AccountRecentContactsController.getRecentContacts(
      accountId
    );
    Test.stopTest();

    List<Id> actualIds = new List<Id>();
    for (Contact actual : contacts) {
      actualIds.add(actual.Id);
    }
    Assert.areEqual(
      expectedIds,
      actualIds,
      'Contacts should be ordered by LastModifiedDate descending, then Id descending'
    );
  }

  @IsTest
  static void shouldReturnOnlyContactsOfGivenAccount_WhenOtherAccountsHaveContacts() {
    Id accountId = getAccountId(OTHER_ACCOUNT_NAME);

    Test.startTest();
    List<Contact> contacts = AccountRecentContactsController.getRecentContacts(
      accountId
    );
    Test.stopTest();

    Assert.areEqual(
      OTHER_ACCOUNT_CONTACT_COUNT,
      contacts.size(),
      'All Contacts of the Account and none of other Accounts should be returned'
    );
    Set<Id> contactIds = new Map<Id, Contact>(contacts).keySet();
    Integer matching = [
      SELECT COUNT()
      FROM Contact
      WHERE Id IN :contactIds AND AccountId = :accountId
    ];
    Assert.areEqual(
      OTHER_ACCOUNT_CONTACT_COUNT,
      matching,
      'Every returned Contact should belong to the given Account'
    );
  }

  @IsTest
  static void shouldReturnEmptyList_WhenAccountHasNoContacts() {
    Id accountId = getAccountId(EMPTY_ACCOUNT_NAME);

    Test.startTest();
    List<Contact> contacts = AccountRecentContactsController.getRecentContacts(
      accountId
    );
    Test.stopTest();

    Assert.isTrue(
      contacts.isEmpty(),
      'No Contacts should be returned for an Account without Contacts'
    );
  }

  @IsTest
  static void shouldReturnEmptyList_WhenAccountIdIsNull() {
    Test.startTest();
    List<Contact> contacts = AccountRecentContactsController.getRecentContacts(
      null
    );
    Test.stopTest();

    Assert.isNotNull(contacts, 'An empty list, not null, should be returned');
    Assert.isTrue(
      contacts.isEmpty(),
      'No Contacts should be returned for a null Id'
    );
  }

  @IsTest
  static void shouldThrowAuraHandledException_WhenUserLacksContactAccess() {
    Id accountId = getAccountId(BULK_ACCOUNT_NAME);
    User restrictedUser = TestDataFactory.createUser(
      'Minimum Access - Salesforce',
      true
    );

    Test.startTest();
    System.runAs(restrictedUser) {
      try {
        AccountRecentContactsController.getRecentContacts(accountId);
        Assert.fail(
          'Expected AuraHandledException for a user without Contact access'
        );
      } catch (AuraHandledException userError) {
        Assert.areEqual(
          AccountRecentContactsController.LOAD_ERROR_MESSAGE,
          userError.getMessage(),
          'The user-safe error message should be returned'
        );
      }
    }
    Test.stopTest();
  }
}
