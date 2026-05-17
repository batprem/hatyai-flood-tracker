# Hat Yai Flood Warning Architecture

## Product Goal

Build a mobile-first flood monitoring website for the U-Tapao canal and Songkhla Lake basin. The first user experience should answer a public question quickly: "Is my area at risk now, and what should I watch?"

Primary audiences:

- Public users in Hat Yai and nearby basin areas
- Researchers, students, and technical users who need transparent data layers

Phase 1 focuses on a clickable public-facing prototype and a weather forecast map. Real-time alerts and platform notifications are deferred to later phases.

## Phase 1 Scope

Phase 1 should provide:

- Thai and English UI foundation
- Public alert landing view
- Forecast rainfall map for the basin area
- Basic layer controls
- Mockable water station markers
- Rule-based flood risk levels
- Architecture ready for real data ingestion

Out of scope for Phase 1:

- LINE, email, Telegram, and push notifications
- Custom ML model training
- Full hydrological simulation
- Production emergency response workflow

## Recommended Stack

Frontend:

- Bun as the bundler and dev server (see "Frontend Bundler Choice" below); the `VITE_*` env-var prefix is retained for compatibility
- React
- TypeScript
- MapLibre GL JS for the interactive map

Backend:

- Python
- FastAPI
- Scheduled ingestion workers

Database:

- MongoDB
- Time-series collections for observations and forecasts
- `2dsphere` indexes for station and geographic queries

Deployment:

- Vercel for frontend
- Railway for FastAPI backend and scheduled jobs

## Repository Shape

Use a simple two-directory structure:

```text
frontend/
backend/
docs/
```

This keeps early development lightweight while preserving a clean frontend/backend boundary.

## System Components

### Frontend

The frontend should render a public-first interface:

- Current status card
- 4-level risk indicator: green, yellow, orange, red
- Map with rainfall forecast layer
- Toggleable map layers
- Time slider for forecast frames
- Mobile-first layout with desktop expansion

### Backend API

The backend should expose normalized endpoints rather than leaking raw provider formats to the frontend:

- `GET /health`
- `GET /api/forecast/rainfall`
- `GET /api/stations/water-level`
- `GET /api/risk/current`
- `GET /api/map/layers`

Phase 1 can return mock data for stations and risk while the forecast pipeline is being built.

### Data Pipeline

The data pipeline should ingest public forecast data from:

- GFS
- ECMWF Open Data

The first useful target is rainfall forecast over the U-Tapao canal and Songkhla Lake basin. Prefer storing normalized forecast frames with model, run time, valid time, variable, unit, bounds, and source attribution.

### Risk Engine

Use a rule-based approach in Phase 1:

- Forecast rainfall intensity
- Accumulated rainfall windows such as 24h, 48h, and 72h
- Optional water-level thresholds when reliable data is available

Output should be simple and public-facing:

- `green`: normal
- `yellow`: watch
- `orange`: warning
- `red`: danger

The rule engine should be replaceable later with hydrological or ML models.

## Data Principles

- Prefer public or open data sources.
- Track source attribution and retrieval time.
- Keep raw provider data separate from normalized API data when possible.
- Design mocks with the same shape as expected real data.
- Treat license review as part of selecting permanent data sources.

## Frontend Bundler Choice

The frontend currently uses Bun (`bun install`, `bun run dev`, `bun run build` via `build.ts`) rather than Vite, even though browser env vars keep the `VITE_*` prefix for compatibility. Open question: stay on Bun long-term or move to Vite once tooling needs (plugins, SSR, ecosystem parity) demand it. Revisit before Phase 2.

## Early Architecture Decision

The first implementation should optimize for a thin visible slice:

1. Frontend map shell with public alert UI.
2. Mock forecast/risk/station payloads.
3. FastAPI endpoint contracts.
4. Replace mock forecast with GFS or ECMWF Open Data ingestion.

