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

## Observed Rainfall And Water-Level Research

HFT-7 focuses on sustainable real-time or near-real-time observations for Hat Yai, the U-Tapao canal, and the Songkhla Lake basin. The MVP should not depend on brittle scraping. Use documented APIs, open data catalogs, bulk files, or written data-sharing paths first; use public dashboards and news bulletins only as manual validation or emergency context until permission and stability are clear.

### Minimum Observed Data Fields

Every observed rainfall or water-level record should be normalized before it reaches API responses.

Required fields:

- `provider`: source owner or aggregator, such as `thaiwater`, `tmd`, `rid`, `hatyai_municipality`, `psu`, `gsmap`, or `imerg`.
- `sourceSystem`: API, bulk file, data-sharing agreement, manual bulletin, or satellite product.
- `stationId` or `gridCellId`: stable provider identifier.
- `stationName` and `stationNameLocal`: if available.
- `location`: longitude, latitude, coordinate reference system, and elevation or gauge datum if available.
- `basin`, `province`, `amphoe`, and `tambon`: when the provider supplies administrative or basin filters.
- `variable`: `rainfall`, `water_level`, `discharge`, `reservoir_storage`, or satellite precipitation variable.
- `value` and `unit`: preserve original unit and normalize rainfall to millimeters, water level to meters, and discharge to cubic meters per second.
- `observedAt`: measurement time in UTC.
- `sourceUpdatedAt`: provider update time when supplied.
- `retrievedAt`: when this system fetched the record.
- `qualityFlag` and `qualityControlLevel`: provider quality fields when supplied.
- `provenance`: source URL, access method, license or terms note, attribution text, and contact path.

### Source Evaluation Matrix

| Source | Useful data | Practical access path | Expected update frequency | Integration risk | License/access risk | Next contact or research step |
| --- | --- | --- | --- | --- | --- | --- |
| ThaiWater / HAII / HII National Hydroinformatics and Climate Data Center | Rainfall observations, water-level or discharge observations, station metadata, basin and agency filters | ThaiWater water-data standard documents describe online API resources for `/Rainfall`, water-level or river-flow data, and `/StationInfo`; API examples include station code, agency code, basin filters, `measureTime`, `updateTime`, variable, value, unit, and quality fields | API standard supports interval-based retrieval such as latest values and time ranges; likely hourly for many water resources, but confirm per station | Medium: documented schema is strong, but production access may require authentication, certificates, or agency approval | Medium: best national aggregator, but public display, caching, research export, attribution, and redistribution terms must be confirmed | Treat as Phase 1 primary observed-data target. Request access or credentials, list stations in Songkhla/U-Tapao basin by `provinceCode`, `basinCode`, and station type, then test latest rainfall and water-level calls |
| Thai Meteorological Department Open Data / TMDAPI | Observed rainfall/weather stations, station metadata, rain regions, radar and satellite context, forecast APIs | TMD Open Data advertises JSON/XML APIs, station datasets, observed weather/rainfall products, radar/support data, and registration for some forecast APIs | Observed station cadence varies by product; assume hourly to daily until confirmed; radar/support products may be more frequent but terms may restrict redistribution | Medium: official API exists, but product-specific docs and registration requirements differ | Medium: TMD publishes as Open Government Data, but registration terms and copyright language need review before public redistribution or caching | Use as Phase 1 secondary rainfall cross-check. Identify Songkhla/Hat Yai AWS and rain products, confirm terms, and verify whether rainfall observations can be cached and shown publicly |
| Royal Irrigation Department / RID Smart Data / RIWI / SWOC | Canal water level, discharge, reservoir status, flood-operation context, rainfall at RID stations | RID has public reservoir APIs and Smart Data/RIWI channels; U-Tapao water-level stations are referenced publicly through ONWR/RID reports, including X.173A Ban Muang Kong, X.44 Ban Hat Yai, and X.174 Khlong Wa | Reservoir public data may be daily; canal telemetry may be near-real-time or hourly, but access path is not yet confirmed | High for canal telemetry unless Smart Data API access is granted; low to medium for public reservoir endpoint | Medium to high: public dashboard/app visibility does not automatically permit API reuse, caching, or redistribution | Contact RID regional office or Smart Water Operation Center for U-Tapao canal telemetry access. In parallel, use public station IDs as a manual seed list and avoid scraping RIWI dashboards |
| Hat Yai municipality, Songkhla province, DDPM, and ONWR public bulletins | Local flood flags, canal levels relative to bank, detention pond status, evacuation context, event reports | Official statements, flood center announcements, ONWR/National Water Command Center reports, province updates, and emergency bulletins | Irregular during normal periods; frequent during events | Medium for manual use, high for automated ingestion unless a feed or written permission exists | High for automated reuse if content comes from social posts, news summaries, or non-API pages | Use as validation and public-context source only for MVP. Ask municipality/province for any machine-readable feed, API, CSV, or data-sharing contact for flood-center observations |
| Prince of Songkla University and local research groups | Historical flood studies, local basin knowledge, possible sensors or event datasets, evacuation/shelter context | Research publications, disaster studies contacts, project pages, and direct collaboration with relevant PSU centers | Usually event-based or research archive, not operational telemetry unless a project feed exists | Medium: strong local relevance but likely not a standardized operational API | Medium: research data may need explicit permission and citation terms | Contact PSU researchers or disaster/risk centers for historical event datasets, station references, and possible collaboration; use published studies for context, not live ingestion |
| GSMaP by JAXA | Satellite precipitation fallback over Thailand, hourly near-real-time rainfall rate, gauge-calibrated products, flags | JAXA Global Rainfall Watch / G-Portal provides GSMaP products in binary, text, NetCDF, HDF5, GeoTIFF, and related formats; clip to the Phase 1 bounding box | GSMaP_NRT is hourly with about 4-hour latency; GSMaP_NOW map is updated about every 30 minutes but product access and use need product-specific review | Medium: gridded processing is straightforward, but binary/NetCDF parsing, latency, and bias validation are needed | Low to medium: G-Portal data is generally free with acknowledgement requirements, but exact product terms and citation must be stored | Use as satellite fallback for observed rainfall gaps. Start with one recent GSMaP_NRT hourly file, clip to the basin, and compare against any ThaiWater/TMD gauges |
| IMERG by NASA GPM | Satellite precipitation fallback, half-hourly near-real-time precipitation, historical research record | NASA GPM / PPS directories provide IMERG Early, Late, and Final runs in HDF, GeoTIFF, NetCDF, and other formats; PPS registration may be required for some access | Early Run is about 4-hour latency; Late Run about 12-hour latency; half-hourly native estimates | Medium: good documentation and formats, but account setup and file naming/version changes must be handled | Low to medium: NASA data is broadly reusable, but attribution, product version, and PPS access terms must be documented | Keep as secondary satellite fallback or research comparison against GSMaP. Verify current V07B access path and automate a small basin subset before production use |

### Recommended Phase 1 Path For Observations

Phase 1 should select ThaiWater / HAII as the first observed-data integration candidate because it is the most relevant national aggregator and has documented standard API resources for rainfall, water-level or river-flow observations, and station metadata. Build the backend observation schema around ThaiWater-like records: station metadata, latest measurement retrieval, time-range retrieval, units, quality flags, and provenance.

Use TMD Open Data as the rainfall cross-check and official meteorological context. TMD is especially useful for observed rainfall, AWS stations, radar context, and public weather attribution, but each product needs a terms and registration check before public display.

For water levels, pursue RID or ONWR/RID data-sharing for U-Tapao canal telemetry, especially stations reported publicly as X.173A Ban Muang Kong, X.44 Ban Hat Yai, and X.174 Khlong Wa. Until a stable API or written permission exists, keep these as mock/manual station references and do not build operational ingestion around scraped dashboards.

Use Hat Yai municipality, Songkhla province, DDPM, ONWR bulletins, and PSU research as validation and historical context. They are high value for local interpretation, flood flags, bank-relative levels, and event narratives, but they are not reliable primary ingestion sources unless an official feed or data-sharing agreement is obtained.

Add GSMaP_NRT first as the satellite rainfall fallback if local gauges are delayed or restricted. It provides hourly gridded precipitation with about 4-hour latency and can be clipped to the Phase 1 basin. Keep IMERG Early/Late as a second satellite option for comparison and research continuity, especially if the NASA data path is easier to automate for this project.

### MVP Observation Recommendation

MVP selection:

1. Primary observed rainfall and water-level target: ThaiWater / HAII APIs, pending access and license confirmation.
2. Rainfall cross-check: TMD Open Data observed station products, pending product-specific terms.
3. Water-level priority: RID/ONWR data-sharing path for U-Tapao canal stations, with public station IDs used only as seed metadata until API access is confirmed.
4. Fallback gridded observed rainfall: GSMaP_NRT clipped to the configured basin; add IMERG only if GSMaP access or validation is insufficient.
5. Local context: municipality, province, DDPM, ONWR bulletins, and PSU contacts for event validation, thresholds, and historical interpretation.

Do not expose any observed source in public risk calculations until the record includes source, station or grid id, measurement time, retrieval time, variable, unit, quality status, and license/attribution notes. If source freshness becomes stale, the backend should keep serving forecasts and mark observations as unavailable or stale rather than silently mixing old station values into risk levels.

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

