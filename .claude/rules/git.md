---
description: Git repository and submodule rules for this project
alwaysApply: true
---

# Git Rules

This project treats `frontend/` and `backend/` as separate Git submodules.

## Repository Boundaries

- The root repository is only for project-level files such as `docs/`, `.cursor/`, `.claude/`, and root coordination files.
- `frontend/` has its own Git history and remote.
- `backend/` has its own Git history and remote.
- Do not assume root `git status` fully represents changes inside `frontend/` or `backend/`.

## Working With Changes

- Run Git commands from the repository that owns the files being changed.
- For frontend code changes, inspect and commit from `frontend/`.
- For backend code changes, inspect and commit from `backend/`.
- For project coordination files, inspect and commit from the root repository.
- When changes span root plus one or both submodules, report each repository status separately.

## Commit Safety

- Do not commit submodule pointer updates in the root repository unless the user explicitly asks to record the new submodule revision.
- Do not mix unrelated frontend and backend commits just because they are in one workspace.
- Do not push any repository unless the user explicitly requests it.
- Never use destructive Git commands such as hard reset or checkout to discard changes unless the user explicitly approves.

## Status Reporting

When summarizing Git state, separate it by repository:

- Root repository
- `frontend/` submodule
- `backend/` submodule
