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

## Status Policy

-  Move a card to `In Progress` before  start a task
- Do not transition any card directly to `Done` unless its current status is `Review`.
- Before moving a card to `Done`, check the current status with a read-only Jira command.
- If a card is not in `Review`, explain that it must move through `Review` first.
- Do not bypass this rule with bulk transitions.

## Safety

- Do not delete Jira work items unless the user explicitly requests deletion.
- Do not perform bulk edits or transitions without clearly confirming the target JQL or issue keys.
- Keep task descriptions concise and tied to the current MVP plan.

