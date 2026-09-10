# Browser process budget

- Treat browser instances as a scarce shared desktop resource. Across all Codex
  tasks on this machine, use at most one agent-controlled browser instance at a
  time. Prefer tabs in the user's existing Chrome when safe and sufficient.
- Never create a new Playwright session for each screenshot, viewport, test
  case, page, or image inspection. Open one session once, then reuse it with
  navigation and `tab-new` / `tab-select`.
- Before opening Playwright, run `playwright-cli list`. If an agent-controlled
  browser already exists, do not launch another one. Reuse it through separate
  tabs when ownership is clear; otherwise serialize the browser work or ask the
  user before opening a second isolated instance.
- Prefer `view_image` for local static-image inspection; it must not be paired
  with launching a browser unless the page runtime itself needs validation.
- Prefer the in-app browser or tabs in the user's existing Chrome when that is
  sufficient and does not require an isolated test profile.
- Close task-owned tabs as soon as browser validation is complete. Close the
  Playwright session when no active task is using it. Before ending the task,
  list sessions again and close any task-owned leftovers, including after
  failed commands.
- If more than one isolated browser instance is genuinely required, explain
  why and obtain the user's approval before opening it.

## Agent skills

### Issue tracker

Track issues and specs as local Markdown under `.scratch/<feature>/`; before creating, reading, or updating tickets, read `docs/agents/issue-tracker.md`.

### Triage labels

Use the five default triage labels; before assigning issue status, read `docs/agents/triage-labels.md`.

### Domain docs

Use a single-context layout with root `CONTEXT.md` and `docs/adr/`; before exploring the codebase, read `docs/agents/domain.md`.
