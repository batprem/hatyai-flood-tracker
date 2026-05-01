# MVP Plan

## MVP Definition

The first MVP is a mobile-first clickable website prototype for flood awareness in Hat Yai and the U-Tapao canal / Songkhla Lake basin area.

The MVP succeeds when a user can open the website and see a forecast rainfall map for the target basin with a public-facing risk status.

## Product Positioning

This is not a formal government warning system in Phase 1. It is a public flood-awareness and research prototype that presents weather model data and simple risk interpretation clearly.

## Milestone 1: Clickable UI Prototype

Goal:

- Validate the public-facing experience before building the full data pipeline.

Deliverables:

- Mobile-first landing page
- Public alert status card
- Interactive map shell
- Forecast time controls
- Layer toggles for rainfall forecast, water stations, and risk heatmap
- Thai and English content structure
- Mock data matching planned API contracts

Acceptance criteria:

- Users can understand current risk status within a few seconds.
- Map loads with at least one forecast-style rainfall layer.
- UI works well on a mobile viewport.
- Mock data can later be replaced by backend API responses without major UI rewrites.

## Milestone 2: Backend API Skeleton

Goal:

- Establish the data contract between frontend and backend.

Deliverables:

- FastAPI project
- Health endpoint
- Forecast endpoint returning normalized mock forecast frames
- Water station endpoint returning mock stations
- Risk endpoint returning current basin-level risk
- Basic CORS setup for Vercel frontend

Acceptance criteria:

- Frontend can load all data from FastAPI instead of local mock files.
- API response schemas are documented.
- Backend can run locally and on Railway.

## Milestone 3: Forecast Data Ingestion

Goal:

- Replace mock rainfall forecast with real model data.

Deliverables:

- GFS ingestion proof of concept
- ECMWF Open Data ingestion proof of concept
- Basin bounding box configuration
- Normalized rainfall forecast storage in MongoDB
- Scheduled update workflow based on model cycle

Acceptance criteria:

- At least one weather model produces real forecast data for the target area.
- Forecast frames include model run time and valid time.
- Frontend can display real forecast data from backend.

## Milestone 4: Rule-Based Risk Layer

Goal:

- Convert forecast rainfall into simple public risk levels.
- Use the practical design in [`risk-layer-design.md`](risk-layer-design.md) for Phase 1 thresholds, decision logic, output schema, explanation text, freshness handling, and later historical calibration.

Deliverables:

- Rule-based risk calculation
- 4-level risk output: green, yellow, orange, red
- Risk explanation text in Thai and English
- Risk heatmap or area overlay based on available resolution

Acceptance criteria:

- Risk level changes based on forecast rainfall thresholds.
- Users can see why a level was assigned.
- Thresholds are configurable in backend settings.

## Milestone 5: Data Source Research

Goal:

- Identify sustainable real-time rain and water-level sources.

Deliverables:

- ThaiWater / HAII feasibility check
- TMD radar or rainfall data feasibility check
- RID or local water-level source feasibility check
- License and attribution notes

Acceptance criteria:

- At least one candidate source is selected for water levels.
- At least one candidate source is selected for observed rainfall.
- Data license risk is documented before production use.

## Later Phases

Potential future work:

- LINE Messaging API alerts
- Email alerts
- Web Push / PWA support
- Historical flood event explorer
- Citizen reports
- Evacuation center details
- ML-assisted flood risk prediction
- Research export tools

