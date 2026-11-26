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
  @api recordId;

  columns = COLUMNS;
  contacts = [];
  errorMessage;
  isLoading = true;

  @wire(getRecentContacts, { accountId: "$recordId" })
  async wiredContacts({ data, error }) {
    if (data) {
      try {
        this.contacts = await Promise.all(
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
        this.errorMessage = undefined;
      } catch {
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
