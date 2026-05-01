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
- `.cursor/` contains project rules and sub-agent definitions.
- `rtoon/` is read-only.

## Sub-Agent Routing

Use the focused agent when work clearly belongs to one area:

- `frontend`: Vite, React, TypeScript, MapLibre UI, public alert pages, map controls, styling, frontend env vars.
- `backend`: FastAPI routes, Pydantic schemas, MongoDB access, backend settings, API contracts, risk endpoints.
- `data-engineering`: GFS/ECMWF ingestion, GRIB/NetCDF parsing, time-series storage, freshness, retries, provenance, data quality.
- `data-analytics`: historical flood events, rainfall thresholds, risk rule calibration, model comparison, validation, research summaries.

Coordinate across agents when changing API contracts, data shapes, risk levels, or map layer schemas.

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
- Do not transition any card to `Done` unless its current status is `Review`.
- Before moving a card to `Done`, check the current status with a read-only Jira command.
- Do not delete Jira work items unless the user explicitly requests deletion.

## Verification

Before reporting completion:

- Run targeted checks for touched frontend or backend files when tooling exists.
- Check lints for edited rule, agent, or documentation files when practical.
- Report changed files, verification steps, and any data source or environment assumptions.

