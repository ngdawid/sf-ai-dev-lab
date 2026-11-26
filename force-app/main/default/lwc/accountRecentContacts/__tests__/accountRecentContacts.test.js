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

// Navigation mock whose GenerateUrl the tests control, so link generation can be held back for one record.
const mockGenerateUrl = jest.fn();
jest.mock("lightning/navigation", () => {
  const Navigate = Symbol("Navigate");
  const GenerateUrl = Symbol("GenerateUrl");
  const NavigationMixin = (Base) =>
    class extends Base {
      [Navigate]() {}
      [GenerateUrl](pageReference) {
        return mockGenerateUrl(pageReference);
      }
    };
  NavigationMixin.Navigate = Navigate;
  NavigationMixin.GenerateUrl = GenerateUrl;
  return { NavigationMixin };
});

const ACCOUNT_ID = "001000000000001AAA";
const OTHER_ACCOUNT_ID = "001000000000002AAA";
const OTHER_ACCOUNT_CONTACTS = [
  {
    Id: "003000000000003AAA",
    Name: "Grace Hopper",
    Title: "Admiral",
    Email: "grace@example.com",
    Phone: "555-0003",
    LastModifiedDate: "2026-11-26T10:00:00.000Z"
  }
];
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
  beforeEach(() => {
    mockGenerateUrl.mockResolvedValue("https://www.example.com");
  });

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

  it("clears the previous record's rows and shows the spinner when recordId changes", async () => {
    const element = createComponent();
    getRecentContacts.emit(MOCK_CONTACTS);
    await flushPromises();
    expect(
      element.shadowRoot.querySelector("lightning-datatable")
    ).not.toBeNull();

    element.recordId = OTHER_ACCOUNT_ID;
    await flushPromises();

    expect(
      element.shadowRoot.querySelector("lightning-spinner")
    ).not.toBeNull();
    expect(element.shadowRoot.querySelector("lightning-datatable")).toBeNull();
    expect(getRecentContacts.getLastConfig()).toEqual({
      accountId: OTHER_ACCOUNT_ID
    });
  });

  it("clears the previous record's error when recordId changes", async () => {
    const element = createComponent();
    getRecentContacts.error({ message: "No access" });
    await flushPromises();
    expect(
      element.shadowRoot.querySelector('[data-id="error"]')
    ).not.toBeNull();

    element.recordId = OTHER_ACCOUNT_ID;
    await flushPromises();

    expect(element.shadowRoot.querySelector('[data-id="error"]')).toBeNull();
    expect(
      element.shadowRoot.querySelector("lightning-spinner")
    ).not.toBeNull();
  });

  it("ignores a result for the old recordId that resolves after the new one", async () => {
    // Hold back link generation for the first Account's Contacts until the second Account has rendered.
    let releaseOldLinks;
    const oldLinksHeld = new Promise((resolve) => {
      releaseOldLinks = resolve;
    });
    const oldContactIds = new Set(MOCK_CONTACTS.map((contact) => contact.Id));
    mockGenerateUrl.mockImplementation((pageReference) => {
      if (oldContactIds.has(pageReference.attributes.recordId)) {
        return oldLinksHeld.then(() => "https://www.example.com/old");
      }
      return Promise.resolve("https://www.example.com/new");
    });
    const element = createComponent();
    getRecentContacts.emit(MOCK_CONTACTS);
    await flushPromises();

    element.recordId = OTHER_ACCOUNT_ID;
    await flushPromises();
    getRecentContacts.emit(OTHER_ACCOUNT_CONTACTS);
    await flushPromises();
    releaseOldLinks();
    await flushPromises();

    const table = element.shadowRoot.querySelector("lightning-datatable");
    expect(table).not.toBeNull();
    expect(table.data.map((contact) => contact.Id)).toEqual(
      OTHER_ACCOUNT_CONTACTS.map((contact) => contact.Id)
    );
    expect(table.data[0].contactUrl).toBe("https://www.example.com/new");
  });
});
