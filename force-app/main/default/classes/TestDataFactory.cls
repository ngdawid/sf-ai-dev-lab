/**
 * Creates test records with sensible defaults. Bulk methods create many records; nothing here relies on org data.
 */
@IsTest
public class TestDataFactory {
  // Numbers Contacts across calls in one transaction so names and emails never repeat (standard duplicate rules).
  private static Integer contactSequence = 0;

  /**
   * @param count Number of Accounts to build
   * @param doInsert Insert the records when true
   * @return The Accounts
   */
  public static List<Account> createAccounts(Integer count, Boolean doInsert) {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < count; i++) {
      accounts.add(new Account(Name = 'Test Account ' + i));
    }
    if (doInsert) {
      insert accounts;
    }
    return accounts;
  }

  /**
   * @param accounts Parent Accounts
   * @param countPerAccount Number of Contacts per Account
   * @param doInsert Insert the records when true
   * @return The Contacts
   */
  public static List<Contact> createContacts(
    List<Account> accounts,
    Integer countPerAccount,
    Boolean doInsert
  ) {
    List<Contact> contacts = new List<Contact>();
    for (Account parentAccount : accounts) {
      for (Integer i = 0; i < countPerAccount; i++) {
        Integer index = contactSequence++;
        contacts.add(
          new Contact(
            FirstName = 'Test',
            LastName = 'Contact ' + index,
            Title = 'Title ' + index,
            Email = 'test.contact' + index + '@example.com',
            Phone = '555-0' + String.valueOf(index).leftPad(3, '0'),
            AccountId = parentAccount.Id
          )
        );
      }
    }
    if (doInsert) {
      insert contacts;
    }
    return contacts;
  }

  /**
   * @param profileName Name of the Profile to assign, e.g. 'Minimum Access - Salesforce'
   * @param doInsert Insert the record when true
   * @return The User
   */
  public static User createUser(String profileName, Boolean doInsert) {
    Profile userProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = :profileName
      LIMIT 1
    ];
    String uniqueKey =
      String.valueOf(Datetime.now().getTime()) +
      String.valueOf(Crypto.getRandomInteger()).remove('-');
    User testUser = new User(
      FirstName = 'Test',
      LastName = 'User',
      Alias = 'tuser',
      Email = 'test.user@example.com',
      Username = 'test.user.' + uniqueKey + '@example.com',
      ProfileId = userProfile.Id,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles'
    );
    if (doInsert) {
      insert testUser;
    }
    return testUser;
  }
}
