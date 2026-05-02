# Agent Guide

This repository is the Hat Yai flood warning project: a mobile-first public flood-awareness and research website for the U-Tapao canal and Songkhla Lake basin.

## Product Context

- Frontend: Vite, React, TypeScript.
- Backend: Python FastAPI.
- Database: MongoDB.
- Map: prefer MapLibre GL JS.
- Deployment target: Vercel for frontend, Railway for backend.
- UI language: Thai and English.
- Phase 1 goal: public alert view with forecast rainfall map, mockable water stations, and rule-based 4-level flood risk.
- Deferred: LINE/email/push alerts, custom ML training, full production emergency response workflow.

## Repository Boundaries

- `frontend/` is owned by frontend work.
- `backend/` is owned by backend, data engineering, and data analytics work depending on task type.
- `docs/` contains architecture, MVP, and data source planning.
- `qa/` is the QA agent workspace for validation tooling such as Playwright checks and acceptance evidence.
- `.claude/` contains project rules, sub-agent definitions, skills, and hooks for Claude Code.
- `.cursor/` contains the parallel set of rules, sub-agents, skills, and hooks for Cursor. Keep `.claude/` and `.cursor/` aligned when project-wide conventions change.
- `rtoon/` is read-only.

## Sub-Agent Routing

Use the focused agent when work clearly belongs to one area. Definitions live in `.claude/agents/` (Claude Code) and `.cursor/agents/` (Cursor):

- `frontend`: Vite, React, TypeScript, MapLibre UI, public alert pages, map controls, styling, frontend env vars.
- `backend`: FastAPI routes, Pydantic schemas, MongoDB access, backend settings, API contracts, risk endpoints.
- `data-engineering`: GFS/ECMWF ingestion, GRIB/NetCDF parsing, time-series storage, freshness, retries, provenance, data quality.
- `data-analytics`: historical flood events, rainfall thresholds, risk rule calibration, model comparison, validation, research summaries.
- `QA`: validation of Jira cards in `Review`, acceptance checks from `qa/`, Playwright/browser testing, moving passed cards from `Review` to `Done`, and moving failed cards from `Review` to `Blocked`.

Coordinate across agents when changing API contracts, data shapes, risk levels, or map layer schemas.

## Project Rules

Detailed conventions live in your tool's rules directory — `.claude/rules/` (Claude Code) or `.cursor/rules/` (Cursor). Both directories share the same content:

- `project-context.mdc` — core project context (always applies).
- `git.md` — submodule-aware Git workflow (always applies).
- `jira.md` — Jira/`acli` workflow on project `HFT` (always applies).
- `python.md` — Python/FastAPI/MongoDB conventions for `backend/`.
- `frontend.md` — TypeScript/React/MapLibre conventions for `frontend/`.

Read the relevant rule file before working in `frontend/` or `backend/`.

## Engineering Rules

- Keep early implementation simple with `frontend/`, `backend/`, and `docs/`.
- Prefer stable mock data shaped like future API responses before integrating fragile external data sources.
- Keep public API responses typed and normalized; do not expose raw provider payloads unless explicitly modeled.
- Use timezone-aware UTC datetimes internally and ISO 8601 timestamps externally.
- Track source attribution, retrieval time, model run time, valid time, units, and freshness metadata for weather and water data.
- Use the project risk levels consistently: green, yellow, orange, red.
- Design public safety UI with clear loading, empty, stale, and error states.

## Jira Workflow

Use Jira project `HFT` on `data-karate.atlassian.net` for task tracking. Board ID is `4` and the board type is `simple`, so do not use sprint-based commands.

- Do not move cards to `In Progress` automatically when starting work.
- Only move a card to `In Progress` when the user explicitly asks.
- Move a card to `Require human` when an agent cannot finish the work without a human decision, credential, dependency install, or other out-of-band action. Comment on the card with the exact blocker, what was tried, and the specific input needed from the user.
- Do not transition any card to `Done` unless its current status is `Review`.
- Before moving a card to `Done`, check the current status with a read-only Jira command.
- Only the `QA` agent should move cards from `Review` to `Done`, after it validates acceptance criteria and comments with evidence.
- Only the `QA` agent should move failed cards from `Review` to `Blocked`, after it comments with blockers and failed validation evidence.
- Do not delete Jira work items unless the user explicitly requests deletion.

## Verification

Before reporting completion:

- Run targeted checks for touched frontend or backend files when tooling exists.
- Check lints for edited rule, agent, or documentation files when practical.
- Report changed files, verification steps, and any data source or environment assumptions.

