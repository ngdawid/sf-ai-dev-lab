/**
 * Supplies the accountRecentContacts LWC with the most recently modified Contacts of an Account.
 * Runs in user mode, so the running user's sharing, object and field access apply.
 */
public with sharing class AccountRecentContactsController {
  @TestVisible
  private static final Integer MAX_CONTACTS = 5;
  @TestVisible
  private static final String LOAD_ERROR_MESSAGE = 'Recent contacts could not be loaded. You may not have access to Contacts.';

  /**
   * Returns the most recently modified Contacts of an Account, newest first.
   * Ties on LastModifiedDate are ordered by Id descending so the result is deterministic.
   *
   * @param accountId Id of the Account whose Contacts are returned
   * @return Up to 5 Contacts; an empty list when accountId is null or the Account has no visible Contacts
   * @throws AuraHandledException when the query fails, e.g. the user lacks access to Contact or its fields
   * @example
   * List<Contact> contacts = AccountRecentContactsController.getRecentContacts(accountId);
   */
  @AuraEnabled(cacheable=true)
  public static List<Contact> getRecentContacts(Id accountId) {
    if (accountId == null) {
      return new List<Contact>();
    }
    try {
      return [
        SELECT Id, Name, Title, Email, Phone, LastModifiedDate
        FROM Contact
        WHERE AccountId = :accountId
        WITH USER_MODE
        ORDER BY LastModifiedDate DESC, Id DESC
        LIMIT :MAX_CONTACTS
      ];
    } catch (QueryException queryError) {
      AuraHandledException userError = new AuraHandledException(
        LOAD_ERROR_MESSAGE
      );
      userError.setMessage(LOAD_ERROR_MESSAGE);
      userError.initCause(queryError);
      throw userError;
    }
  }
}
