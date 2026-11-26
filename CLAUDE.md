# Agent instructions: sf-ai-dev-lab

Salesforce DX project (API 68.0), developed in a dev container. These rules apply to every task. If a rule and
a request conflict, ask before acting. These project rules override guidance from skills.

## Workflow

1. **Understand.** Read the relevant code first. If the request leaves open who uses it, what data it touches, where
   values are stored or how it is approved, ask 3–5 short questions before anything else.
2. **Plan.** For anything bigger than a one-file change, propose a plan (files, data model, security, tests) and wait
   for approval before writing files.
3. **Build.** Follow the rules for the metadata type (`.claude/rules/`) and use the matching skill:
   Apex → `platform-apex-generate`, Apex tests → `platform-apex-test-generate`, LWC → `experience-lwc-generate`.
   Create and change files with the Write and Edit tools, not with shell commands (`cat > file <<EOF`, `sed -i`):
   hooks check file writes, and the diff stays reviewable.
4. **Verify.** Run the definition of done (below) and report the results.
5. **Hand over.** Summarize; the human then runs `/code-review` and `/security-review` and opens the PR.

## Orgs

- Work only in scratch orgs with the alias `lab-eval` or `lab-feat<N>`. Always pass `--target-org <alias>`.
- No scratch org yet? Create one:
  `sf org create scratch --definition-file config/project-scratch-def.json --alias lab-feat<N> --target-dev-hub lab-prod --duration-days 1 --wait 10`
- `lab-prod` is the Dev Hub only: creating scratch orgs and checking limits. `lab-qa` belongs to CI. Never run
  anything else against either, and don't suggest them as alternatives.

## Git

- Work on the current branch if it isn't `main`; otherwise create `feature/<short-name>`. Commit when done.
  Don't push, open PRs or merge unless asked.
- Only `status`, `diff`, `log`, `add`, `commit`, `switch`/`checkout -b`. No `stash`, `reset`, `restore`,
  `rebase`, `clean` or force operations: if the working tree is in a state you didn't expect, stop and ask.

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
