import { createElement } from "@lwc/engine-dom";
import AccountRecentContacts from "c/accountRecentContacts";
import getRecentContacts from "@salesforce/apex/AccountRecentContactsController.getRecentContacts";

jest.mock(
  "@salesforce/apex/AccountRecentContactsController.getRecentContacts",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

const ACCOUNT_ID = "001000000000001AAA";
const MOCK_CONTACTS = [
  {
    Id: "003000000000001AAA",
    Name: "Ada Lovelace",
    Title: "CTO",
    Email: "ada@example.com",
    Phone: "555-0001",
    LastModifiedDate: "2026-11-25T10:00:00.000Z"
  },
  {
    Id: "003000000000002AAA",
    Name: "Alan Turing",
    Title: "Engineer",
    Email: "alan@example.com",
    Phone: "555-0002",
    LastModifiedDate: "2026-11-24T10:00:00.000Z"
  }
];

// Drains pending microtasks (wire config, URL generation, re-render).
const flushPromises = () =>
  Array.from({ length: 5 }).reduce(
    (chain) => chain.then(() => Promise.resolve()),
    Promise.resolve()
  );

function createComponent() {
  const element = createElement("c-account-recent-contacts", {
    is: AccountRecentContacts
  });
  element.recordId = ACCOUNT_ID;
  document.body.appendChild(element);
  return element;
}

describe("c-account-recent-contacts", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("passes the record Id to the Apex wire", async () => {
    createComponent();
    await flushPromises();
    expect(getRecentContacts.getLastConfig()).toEqual({
      accountId: ACCOUNT_ID
    });
  });

  it("shows a spinner while loading", () => {
    const element = createComponent();
    expect(
      element.shadowRoot.querySelector("lightning-spinner")
    ).not.toBeNull();
  });

  it("renders contacts with record links in the datatable", async () => {
    const element = createComponent();
    getRecentContacts.emit(MOCK_CONTACTS);
    await flushPromises();

    const table = element.shadowRoot.querySelector("lightning-datatable");
    expect(table).not.toBeNull();
    expect(table.data).toHaveLength(MOCK_CONTACTS.length);
    expect(table.data[0].Name).toBe("Ada Lovelace");
    expect(table.data[0].contactUrl).toBe("https://www.example.com");
    expect(table.columns.map((column) => column.label)).toEqual([
      "Name",
      "Title",
      "Email",
      "Phone",
      "Last Modified"
    ]);
    expect(element.shadowRoot.querySelector("lightning-spinner")).toBeNull();
  });

  it("shows the empty state when the account has no contacts", async () => {
    const element = createComponent();
    getRecentContacts.emit([]);
    await flushPromises();

    expect(
      element.shadowRoot.querySelector('[data-id="empty"]')
    ).not.toBeNull();
    expect(element.shadowRoot.querySelector("lightning-datatable")).toBeNull();
  });

  it("shows the server error message when the wire fails", async () => {
    const element = createComponent();
    getRecentContacts.error({ message: "No access" });
    await flushPromises();

    const error = element.shadowRoot.querySelector('[data-id="error"]');
    expect(error).not.toBeNull();
    expect(error.textContent).toContain("No access");
    expect(element.shadowRoot.querySelector("lightning-datatable")).toBeNull();
  });
});
