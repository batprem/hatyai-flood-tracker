# QA Workspace

This directory is the working area for the `QA` agent.

Use it for validation tooling that should not live in `frontend/` or `backend/`, such as Playwright checks, acceptance-test scripts, fixtures, and temporary QA reports.

## Guidelines

- Validate Jira cards that are in `Review`.
- Add a Jira comment with validation evidence before moving a card.
- Move a card from `Review` to `Done` only when the acceptance criteria pass.
- Leave failed cards in `Review` and document blockers.
- Keep generated reports, traces, screenshots, videos, and `node_modules/` out of git.

## Current Tooling

`package.json` currently includes Playwright for browser-based validation.

