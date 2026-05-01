# Data Sources Plan

## Phase 1 Data Strategy

Phase 1 should start with open forecast model data and mock or placeholder observation data. This lets the product validate the map, time controls, public alert UX, and API contracts before committing to fragile or restricted real-time station sources.

Provider priority:

1. GFS for the first working rainfall forecast ingestion path.
2. ECMWF Open Data as a second model for comparison and redundancy.
3. ThaiWater / HAII, TMD, RID, and local sources for observed rainfall and water level research after the forecast pipeline shape is stable.
4. Satellite rainfall products such as GSMaP or IMERG only if local observed rainfall sources are unavailable or licensing is unclear.

Do not build Phase 1 around scraping public web pages. Prefer documented APIs, published bulk files, data-sharing agreements, manually maintained seed datasets, or explicit permission from the source owner.

## Target Area

The first ingestion area should be a configurable bounding box that covers Hat Yai, the U-Tapao canal, nearby upstream catchment, and the Songkhla Lake connection. Keep the exact basin geometry as a later refinement once an authoritative catchment boundary is selected.

Initial configuration shape:

```json
{
  "name": "hatyai_utapao_songkhla_phase1",
  "bbox": {
    "west": 100.15,
    "south": 6.55,
    "east": 100.95,
    "north": 7.35
  },
  "crs": "EPSG:4326",
  "notes": "Conservative Phase 1 bounding box. Replace or supplement with basin polygon after authoritative GIS review."
}
```

Ingestion should subset to this bounding box as early as practical to reduce download size, parsing time, and MongoDB storage cost. Store the bounding box or geometry reference on every normalized forecast frame so map rendering and research exports can explain what was processed.

## Forecast Models

### GFS

Use case:

- Primary open global rainfall forecast for MVP ingestion.
- Frequent model cycles suitable for a public forecast map.
- Good first source because GRIB2 tooling and examples are widely available.

Priority variables:

- Accumulated precipitation for forecast windows.
- Optional precipitation rate if needed for intensity displays.
- Latitude and longitude grid.
- Model run time, forecast lead time, and valid time.

Implementation notes:

- Use NOAA/NCEP GFS GRIB2 products from public object storage or HTTPS endpoints.
- Start with a low-resolution product and short forecast horizon for the proof of concept before increasing temporal coverage.
- Normalize provider-specific accumulated precipitation semantics into explicit frame windows such as `accumulationHours`.
- Keep provider units in provenance and expose normalized precipitation in millimeters.

### ECMWF Open Data

Use case:

- Secondary open forecast model for comparison, fallback, and research confidence.
- Useful for checking whether GFS-only risk signals are model-specific.

Priority variables:

- Total precipitation.
- Latitude and longitude grid.
- Model run time, forecast lead time, and valid time.

Implementation notes:

- Use ECMWF Open Data only within its published terms.
- Confirm exact dataset, redistribution rules, and attribution text before public launch.
- Keep ECMWF ingestion behind the same normalized schema as GFS so the backend and frontend can switch by `provider` and `model`.

## Normalized Forecast Schema

The backend should not expose raw GRIB, NetCDF, or provider-specific field names to the frontend. Normalize each processed frame before storage.

Suggested `forecast_frames` document:

```json
{
  "provider": "noaa",
  "model": "gfs",
  "runTime": "2026-05-01T00:00:00Z",
  "validTime": "2026-05-02T00:00:00Z",
  "retrievedAt": "2026-05-01T04:18:30Z",
  "forecastHour": 24,
  "variable": "precipitation",
  "statistic": "accumulation",
  "accumulationHours": 24,
  "unit": "mm",
  "area": {
    "name": "hatyai_utapao_songkhla_phase1",
    "bbox": [100.15, 6.55, 100.95, 7.35],
    "crs": "EPSG:4326"
  },
  "grid": {
    "type": "regular_lat_lon",
    "resolutionDegrees": 0.25,
    "width": 4,
    "height": 4
  },
  "valuesRef": {
    "storage": "mongodb",
    "collection": "forecast_frame_values",
    "frameId": "noaa:gfs:2026050100:precipitation:f024"
  },
  "source": {
    "url": "https://example-provider-url",
    "license": "review-required",
    "attribution": "NOAA/NCEP GFS",
    "rawArtifactRef": "gfs/20260501/00/f024.grib2"
  },
  "quality": {
    "status": "complete",
    "missingValueCount": 0,
    "min": 0,
    "max": 82.4
  }
}
```

The value storage can start simple. For a small POC, values may be stored as a compact array or GeoJSON-like grid cells. For larger coverage, keep raw artifacts in object storage and store only frame metadata plus a tile or raster reference in MongoDB.

## MongoDB Storage Shape

Use MongoDB time-series collections where documents are naturally time-indexed and small enough for efficient range queries. Keep large raster payloads out of hot collections if they grow beyond MVP scale.

Recommended collections:

- `forecast_runs`: one document per provider/model run with run status, source URLs, retrieval timestamps, and error details.
- `forecast_frames`: one document per model run, valid time, variable, and accumulation window.
- `forecast_frame_values`: optional POC collection for clipped grid values keyed by frame id and location or cell index.
- `station_observations`: future time-series collection for water level and observed rainfall.
- `data_freshness`: latest successful run, expected next run, last failure, and freshness status by provider/model.

Index implications:

- `forecast_frames`: compound index on `{ provider, model, variable, runTime, validTime }`.
- `forecast_frames`: `2dsphere` index if frame cells or polygons are stored as GeoJSON geometries.
- `forecast_runs`: unique index on `{ provider, model, runTime }` for idempotent reruns.
- `station_observations`: time-series time field `observedAt`, metadata field `stationId`, and geospatial station metadata stored separately or embedded carefully.

## Model Time Handling

All stored timestamps should be timezone-aware UTC ISO 8601 strings.

Required times:

- `runTime`: model cycle initialization time.
- `validTime`: forecast target time represented by the frame.
- `retrievedAt`: when this system downloaded or fetched the provider artifact.
- `processedAt`: when normalization completed, if different from retrieval.
- `observedAt`: measurement time for future station observations.

Forecast ingestion should follow provider model cycles instead of pretending to be real time. If a new cycle is late, keep serving the latest successful forecast with a visible stale status.

## Freshness, Retries, And Failures

Freshness status should be visible to backend operators and eventually to public or research views.

Recommended statuses:

- `fresh`: latest expected run has been processed successfully.
- `delayed`: expected provider run is not available yet, but previous data is still acceptable.
- `stale`: latest successful data is older than the configured freshness threshold.
- `partial`: some forecast hours or variables are missing.
- `failed`: retrieval, parsing, validation, or storage failed.

Retry behavior:

- Poll provider availability with bounded retries after each expected model cycle.
- Use exponential backoff with a maximum retry window per cycle.
- Make ingestion idempotent by using provider, model, run time, variable, and forecast hour as stable keys.
- Record failures with phase-specific reasons such as `missing_provider_run`, `download_error`, `parse_error`, `schema_mismatch`, `unit_mismatch`, or `storage_error`.

## Data Quality Checks

Minimum checks for every normalized forecast run:

- Confirm required metadata exists: provider, model, run time, valid time, retrieval time, variable, unit, and area.
- Confirm coordinates intersect the configured basin bounding box.
- Confirm precipitation values are non-negative after unit conversion.
- Confirm accumulation windows are explicit and consistent across forecast hours.
- Confirm expected forecast hours were processed or mark the run `partial`.
- Confirm run time and valid time order is valid.
- Confirm maximum rainfall is within a plausible range before using it in risk calculations.
- Confirm provenance and license notes are present.

These checks should fail closed for public risk generation. A failed or partial forecast can still be stored for debugging, but the risk engine should only consume frames marked usable.

## Observation Sources To Research

### ThaiWater / HAII

Research direction:

- Check for documented public APIs, open data endpoints, data catalogs, or requestable access for rainfall and water-level stations.
- Confirm update frequency, station metadata, units, historical access, attribution language, and redistribution limits.
- Prefer API or bulk access over parsing public dashboard pages.

Potential use:

- Observed rainfall for validation.
- Water-level station observations in the U-Tapao canal and surrounding basin.
- Historical event context if data access includes archives.

### Thai Meteorological Department

Research direction:

- Check available rainfall station, radar, forecast, warning, and API products.
- Confirm whether radar imagery or gridded precipitation can be redistributed or only linked.
- Prefer official data feeds or written permission before operational use.

Potential use:

- Observed rainfall and radar context.
- Cross-checking model forecasts during heavy rain events.

### Royal Irrigation Department And Local Sources

Research direction:

- Identify RID gauges, local municipality stations, university-maintained sensors, and provincial public reports near Hat Yai and the U-Tapao canal.
- Check whether data is available through official APIs, CSV downloads, published bulletins, or data-sharing agreements.
- Avoid automated scraping unless terms explicitly allow it and the page structure is stable.

Potential use:

- Water level thresholds.
- Manual seed dataset for key stations if real-time access is not ready.

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
  "source": "mock",
  "sourceUpdatedAt": "2026-05-01T05:05:00Z"
}
```

## Update Frequency

The MVP should follow model cycles rather than forcing real-time updates.

Suggested approach:

- Forecast ingestion: follow GFS and ECMWF model availability.
- Risk calculation: run only after new usable forecast frames are normalized.
- Freshness checks: run more often than model ingestion so stale data is visible quickly.
- Mock stations: static or periodically regenerated for UI testing.
- Later sensor data: update every 15 to 60 minutes depending on source.

## First Implementation Plan: GFS/ECMWF POC

1. Add backend configuration for provider enablement, target bounding box, forecast horizon, accepted variables, and storage collection names.
2. Build a GFS-only proof of concept that downloads one recent run, one precipitation variable, and a short set of forecast hours for the configured bounding box.
3. Parse GRIB2 locally, convert precipitation to millimeters, and emit normalized `forecast_frames` records with provenance.
4. Store frame metadata and a small clipped value payload in MongoDB using stable idempotency keys.
5. Add data quality checks for metadata, timestamps, units, bounding box intersection, missing values, and plausible precipitation ranges.
6. Add `forecast_runs` and `data_freshness` records so the backend can expose run status and stale data.
7. Repeat the same flow for ECMWF Open Data behind the normalized provider interface.
8. Compare GFS and ECMWF frames for one heavy-rain scenario before using either model in public risk messaging.

Keep the first POC intentionally small: one area, one variable, short horizon, and manual or scheduled-once execution. Expand forecast hours, provider coverage, and schedule automation after the normalized contract is proven.

## Historical Data

The first historical focus should be major flood events, not exhaustive archive coverage.

Candidate events:

- Hat Yai flood events with public reports and rainfall records.
- Major U-Tapao basin flood events.
- Any events with available rainfall, water-level, and impact data.

Historical event data should eventually support:

- Case study pages.
- Model validation.
- Threshold tuning.
- Research downloads.

## License Notes

The project can use public/free APIs for prototyping, but production data should document:

- Source owner.
- License or terms of use.
- Required attribution text.
- Redistribution limits for raw data, derived data, screenshots, and map tiles.
- Update frequency limits.
- API quota or reliability risks.
- Whether public display, research export, and cached storage are permitted.

Open questions before production launch:

- Exact permitted attribution and redistribution terms for ECMWF Open Data in this app.
- Whether ThaiWater / HAII offers a stable API or data-sharing path for the target basin.
- Whether TMD radar or rainfall station data can be redistributed in a public research prototype.
- Which RID or local water-level stations are authoritative for U-Tapao canal thresholds.

