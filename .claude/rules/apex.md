---
paths:
  - "force-app/**/classes/**"
  - "force-app/**/triggers/**"
---

# Apex: project decisions

These override `platform-apex-generate` and `platform-apex-test-generate` where they differ.

## Structure

- One trigger per object, `<Object>Trigger`, no logic in it: it calls `<Object>TriggerHandler`.
- Classes are `with sharing` unless there is a written reason.

## Data access

- Write the access mode explicitly: SOQL `WITH USER_MODE`; DML `update as user records;` or
  `Database.update(records, AccessLevel.USER_MODE)`. API 68.0 runs in user mode by default anyway, but the explicit
  form documents intent, survives a change of API version, and is what Code Analyzer (`ApexCRUDViolation`) checks for.
- System mode only if the user can't have access by design: add `// SYSTEM MODE: <reason>` and mention it in your
  summary.

## Behaviour (from `/code-review` findings on earlier code)

- `!=` and `==` on Strings ignore case in Apex. Use `.equals()` when a case-only change must count.
- Decide all-or-nothing vs partial DML (`Database.update(records, false)`) on purpose, and say which in the summary.
- Updates that fan out from parent to children (e.g. Account → Contacts) can exceed the 10,000-row DML limit in
  one transaction; for large fan-out, move the work to a Queueable and say so.
- A trigger whose handler updates records that can re-fire it needs a recursion guard (static `Set<Id>` of processed
  records).

## Tests

- Follow `platform-apex-test-generate`: `TestDataFactory`, 251+ records for bulk tests (crosses the 200-record
  trigger chunk), `Assert` class, one behaviour per test method.
- A failing test means: fix the code. Change an assertion only if the assertion itself is wrong, and say so.
- Test method names are camelCase without underscores (`returnsNewestFirstWhenContactsExist`), not the skill's
  `should…_When…`: PMD's `MethodNamingConventions` flags underscores.
- Test data must pass the org's duplicate rules: names and emails unique across every factory call in a test.
- Ordering tests: give records distinct sort keys where you can set them. Where you can't (`LastModifiedDate`,
  `CreatedDate` in one transaction), compute the expected order in Apex from the returned records' own fields and
  assert the tie-breaker explicitly. Never assume timestamps are equal, or different.
