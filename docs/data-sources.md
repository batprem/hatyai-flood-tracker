# Data Sources Plan

## Phase 1 Data Strategy

Phase 1 should start with forecast model data and mock or placeholder observation data. This lets the product validate the map, time controls, public alert UX, and API contracts before committing to fragile or restricted real-time data sources.

## Forecast Models

### GFS

Use case:

- Global rainfall forecast
- Frequent updates
- Good free starting point for MVP

Expected variables:

- Precipitation rate or accumulated precipitation
- Forecast run time
- Forecast valid time
- Latitude and longitude grid

Notes:

- GFS is a practical first integration because it is openly available and widely documented.
- Data volume can be large, so the backend should clip to the basin bounding box as early as possible.

### ECMWF Open Data

Use case:

- Secondary forecast model for comparison
- Higher-quality model family where open data coverage is sufficient

Expected variables:

- Total precipitation
- Forecast run time
- Forecast valid time

Notes:

- ECMWF Open Data is useful but has specific availability and licensing terms.
- Confirm allowed usage and attribution before public launch.

## Rain Observation Sources To Research

Candidates:

- Thai Meteorological Department rainfall or radar data
- ThaiWater / HAII public data
- Satellite precipitation estimates such as GSMaP or IMERG
- Public station pages from local agencies if access is stable and permitted

Phase 1 recommendation:

- Use mock observation data in the clickable UI.
- Research ThaiWater / HAII and TMD first.
- Avoid brittle scraping until license and stability are understood.

## Water-Level Sources To Research

Candidates:

- ThaiWater / HAII
- Royal Irrigation Department
- Local government or municipal data
- Manual seed dataset for known stations

Phase 1 recommendation:

- Start with mock water stations.
- Use realistic fields so the frontend does not need to change later.

Suggested station shape:

```json
{
  "id": "station-utapao-001",
  "name": {
    "th": "สถานีคลองอู่ตะเภา",
    "en": "U-Tapao Canal Station"
  },
  "location": {
    "type": "Point",
    "coordinates": [100.47, 7.01]
  },
  "waterLevelM": 2.35,
  "warningLevelM": 3.2,
  "dangerLevelM": 3.8,
  "observedAt": "2026-05-01T05:00:00Z",
  "source": "mock"
}
```

## Update Frequency

The MVP should follow model cycles rather than forcing real-time updates.

Suggested approach:

- Forecast ingestion: follow GFS and ECMWF model availability.
- Risk calculation: run after each new forecast ingestion.
- Mock stations: static or periodically regenerated for UI testing.
- Later sensor data: update every 15 to 60 minutes depending on source.

## Historical Data

The first historical focus should be major flood events, not exhaustive archive coverage.

Candidate events:

- Hat Yai flood events with public reports and rainfall records
- Major U-Tapao basin flood events
- Any events with available rainfall, water-level, and impact data

Historical event data should eventually support:

- Case study pages
- Model validation
- Threshold tuning
- Research downloads

## License Notes

The project can use public/free APIs for prototyping, but production data should document:

- Source owner
- License or terms of use
- Attribution requirement
- Redistribution limits
- Update frequency limits
- API quota or reliability risks

