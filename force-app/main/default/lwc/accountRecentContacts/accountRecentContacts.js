import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getRecentContacts from "@salesforce/apex/AccountRecentContactsController.getRecentContacts";

const COLUMNS = [
  {
    label: "Name",
    fieldName: "contactUrl",
    type: "url",
    typeAttributes: { label: { fieldName: "Name" }, target: "_self" }
  },
  { label: "Title", fieldName: "Title", type: "text" },
  { label: "Email", fieldName: "Email", type: "email" },
  { label: "Phone", fieldName: "Phone", type: "phone" },
  {
    label: "Last Modified",
    fieldName: "LastModifiedDate",
    type: "date",
    typeAttributes: {
      year: "numeric",
      month: "short",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit"
    }
  }
];

const GENERIC_ERROR = "Recent contacts could not be loaded.";

export default class AccountRecentContacts extends NavigationMixin(
  LightningElement
) {
  columns = COLUMNS;
  contacts = [];
  errorMessage;
  isLoading = true;
  _recordId;

  @api
  get recordId() {
    return this._recordId;
  }

  // A new record means new data: show the spinner instead of the previous record's rows or error.
  set recordId(value) {
    if (value !== this._recordId) {
      this._recordId = value;
      this.isLoading = true;
      this.contacts = [];
      this.errorMessage = undefined;
    }
  }

  @wire(getRecentContacts, { accountId: "$recordId" })
  async wiredContacts({ data, error }) {
    if (data) {
      const requestedRecordId = this.recordId;
      try {
        const contacts = await Promise.all(
          data.map(async (contact) => ({
            ...contact,
            contactUrl: await this[NavigationMixin.GenerateUrl]({
              type: "standard__recordPage",
              attributes: {
                recordId: contact.Id,
                objectApiName: "Contact",
                actionName: "view"
              }
            })
          }))
        );
        // recordId changed while the links were generated: this result belongs to the old record.
        if (requestedRecordId !== this.recordId) {
          return;
        }
        this.contacts = contacts;
        this.errorMessage = undefined;
      } catch {
        if (requestedRecordId !== this.recordId) {
          return;
        }
        this.contacts = [];
        this.errorMessage = GENERIC_ERROR;
      }
      this.isLoading = false;
    } else if (error) {
      this.contacts = [];
      this.errorMessage = error?.body?.message || GENERIC_ERROR;
      this.isLoading = false;
    }
  }

  get hasContacts() {
    return !this.isLoading && !this.errorMessage && this.contacts.length > 0;
  }

  get isEmpty() {
    return !this.isLoading && !this.errorMessage && this.contacts.length === 0;
  }
}
