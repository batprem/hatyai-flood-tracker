---
description: Jira task management rules for the Hat Yai flood tracker
alwaysApply: true
---

# Jira Task Management

Use Jira for project task tracking when the user asks to create, view, update, assign, transition, or organize work items.

## Jira Context

- Site: `data-karate.atlassian.net`.
- Account: `prem.ch@ku.th`.
- Project key: `HFT`.
- Project name: `Hatyai-flood-Tracker`.
- Board ID: `4`.
- Board API name: `HFT board`.
- Board type: `simple`; do not use sprint-based commands for this board.

## CLI Usage

- Use `acli jira ...` commands for Jira operations.
- Prefer read-only commands first when validating board, project, or work item state.
- Use project `HFT` unless the user explicitly says otherwise.
- Show created or updated issue keys and URLs in the final response when available.

## Work Item Hierarchy

- The project hierarchy is `Epic → Task → Subtask`. Epics have `Task` children; Tasks may have `Subtask` children.
- When creating an Epic with planned children, create each child as a real Jira work item linked via `--parent <EPIC-KEY>`. Do not list children only as text bullets in the Epic description — Jira already tracks the parent/child link.
- Match the existing project type pattern: children of an Epic are `Task` items unless the user explicitly asks for `Subtask`.
- Do not invent custom key prefixes (for example `HFT-1.5.A`) for child cards. Let Jira assign the next sequential key (`HFT-15`, `HFT-16`, …) and refer to children by their real keys.
- Verify the parent/child relationship after creation with `acli jira workitem search --jql "project = HFT AND parent = <EPIC-KEY>"`.

## Status Policy

- Move a card to `In Progress` before starting a task.
- Move a card to `Require human` when work cannot finish without a human decision, credential, dependency install, or other out-of-band action. Comment with the exact blocker, what was tried, and the specific input needed before transitioning. Resume only after the human responds and moves the card back to `In Progress`.
- Do not transition any card directly to `Done` unless its current status is `Review`.
- Before moving a card to `Done`, check the current status with a read-only Jira command.
- If a card is not in `Review`, explain that it must move through `Review` first.
- Only the `QA` agent may move a card from `Review` to `Done`, and only after validating acceptance criteria and commenting with evidence.
- Only the `QA` agent may move a failed card from `Review` to `Blocked`, and only after commenting with blockers and failed validation evidence.
- Do not bypass this rule with bulk transitions.

## Sub-Agent Checklist

When a sub-agent (backend-senior, backend-junior, frontend-senior, frontend-junior, data-engineering, etc.) is briefed on a Jira-tracked task, its prompt **must** include these three explicit steps:

1. `acli jira workitem transition --key <KEY> --status "In Progress"` — run before making any code changes.
2. Push the branch, open the PR.
3. `acli jira workitem transition --key <KEY> --status "Review"` then `acli jira workitem comment create --key <KEY> --body "PR: <URL>. <evidence summary>."` — run after the PR is open.

If a sub-agent returns without having performed these steps, the coordinator or calling agent must perform them before reporting completion to the user. Do not rely on the sub-agent reading this rule file — include the steps as numbered instructions in every briefing.

## Safety

- Do not delete Jira work items unless the user explicitly requests deletion.
- Do not perform bulk edits or transitions without clearly confirming the target JQL or issue keys.
- Keep task descriptions concise and tied to the current MVP plan.
