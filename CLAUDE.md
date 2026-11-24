# Agent instructions: sf-ai-dev-lab

Salesforce DX project (API 68.0), developed in a dev container. These rules apply to every task. If a rule and
a request conflict, ask before acting.

## Orgs

- Work only in scratch orgs with the alias `lab-eval` or `lab-feat<N>`. Always pass `--target-org <alias>`.
- No scratch org yet? Create one:
  `sf org create scratch --definition-file config/project-scratch-def.json --alias lab-feat<N> --target-dev-hub lab-prod --duration-days 1 --wait 10`
- `lab-prod` is the Dev Hub only: creating scratch orgs and checking limits. `lab-qa` belongs to CI. Never run
  anything else against either, and don't suggest them as alternatives.

## Before you build

- If the request leaves open who uses it, what data it touches, where values are stored or how it is approved,
  ask first (3–5 short questions), then build. Don't create metadata on assumptions.
- Work on the current branch if it isn't `main`; otherwise create `feature/<short-name>`. Commit when done.
  Don't push, open PRs or merge unless asked.
- Git: only `status`, `diff`, `log`, `add`, `commit`, `switch`/`checkout -b`. No `stash`, `reset`, `restore`,
  `rebase`, `clean` or force operations: if the working tree is in a state you didn't expect, stop and ask.

## Apex

- One trigger per object (`<Object>Trigger`), no logic in the trigger: it calls `<Object>TriggerHandler`.
- Bulk-safe: no SOQL or DML inside loops. Tests cover 200 records.
- Classes are `with sharing` unless there is a written reason.
- User mode for data access: SOQL `WITH USER_MODE`; DML `update as user records;` or
  `Database.update(records, AccessLevel.USER_MODE)`. Plain SOQL/DML is flagged High by Code Analyzer
  (`ApexCRUDViolation`). System mode only if the user can't have access by design: add
  `// SYSTEM MODE: <reason>` and mention it in your summary.
- Tests: `@IsTest`, `Assert` class, `Test.startTest()`/`Test.stopTest()`, own test data (no `SeeAllData`).
- A failing test means: fix the code. Change an assertion only if the assertion itself is wrong, and say so.

## LWC

- Every component gets a Jest test (`__tests__/<name>.test.js`) that mocks its Apex calls.

## Definition of done

Run all of these and report the results before you say a task is done:

1. Deploy to your scratch org: `sf project deploy start --source-dir force-app --target-org <scratch>`
2. Apex tests: `sf apex run test --target-org <scratch> --code-coverage --result-format human --wait 10`
   (all pass; aim for 85% coverage on new classes)
3. Code Analyzer: `sf code-analyzer run --target force-app --view table`. **No Critical or High findings.**
   Fix them; never suppress or disable a rule without asking.
4. `npm run lint -- --no-error-on-unmatched-pattern`, `npm run prettier:verify`,
   `npx sfdx-lwc-jest -- --passWithNoTests` (exactly as CI runs them)

These are the same checks the PR pipeline runs. Summary: files changed, test result, analyzer result, open points.

## When something is blocked

If a hook or permission rule blocks a command: stop and say what was blocked and why. Don't look for another
route, and don't offer workarounds: no `!` commands, no scripts for the human to run, no "add an exception",
no other org. The human decides.

## Off limits

- Org logins, auth URLs, tokens and the CLI's credential folders: never read, print or copy them.
- Don't change `.github/`, `.devcontainer/`, `.claude/`, `CLAUDE.md` or `code-analyzer.yml` unless the task is
  exactly that.
