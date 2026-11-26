---
paths:
  - "force-app/**/lwc/**"
---

# LWC: project decisions

These override `experience-lwc-generate` where they differ.

- Every component gets a Jest test in `__tests__/<name>.test.js` that mocks its Apex and wire calls.
- Read data with `@AuraEnabled(cacheable=true)` Apex methods or Lightning Data Service; no hard-coded record Ids.
- Declare targets explicitly in `.js-meta.xml` (e.g. `lightning__RecordPage` with the object).
- The skill's local-preview commands (`sf lightning dev ...`) use `--target-org <scratch alias>` like everything else.
