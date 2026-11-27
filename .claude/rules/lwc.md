---
paths:
  - "force-app/**/lwc/**"
---

# LWC: project decisions

These override `experience-lwc-generate` where they differ.

- Every component gets a Jest test in `__tests__/<name>.test.js` that mocks its Apex and wire calls.
- Read data with `@AuraEnabled(cacheable=true)` Apex methods or Lightning Data Service; no hard-coded record Ids.
- Declare targets explicitly in `.js-meta.xml` (e.g. `lightning__RecordPage` with the object).
- Record-page components must handle a changing `recordId` (console tabs, reused pages): reset loading state, data
  and errors when it changes, and ignore async results that arrive for an earlier `recordId`. The Jest test covers
  a `recordId` switch.
- The skill's local-preview commands (`sf lightning dev ...`) use `--target-org <scratch alias>` like everything else.
