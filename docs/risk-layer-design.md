# Rule-Based Flood Risk Layer Design

## Purpose

The Phase 1 risk layer converts forecast rainfall, accumulated rainfall windows, and optional water-level observations into a transparent 4-level public status for Hat Yai and the U-Tapao canal / Songkhla Lake basin.

This is an awareness and research prototype, not an official emergency warning system. The first implementation should favor auditable rules, clear explanations, source attribution, and conservative uncertainty handling over complex models.

## Risk Levels

| Level | Meaning | Public intent |
| --- | --- | --- |
| `green` | Normal | Conditions do not currently indicate elevated flood risk. |
| `yellow` | Watch | Rain or water levels may increase local flood risk; monitor updates. |
| `orange` | Warning | Flooding is possible in vulnerable or low-lying areas; prepare and follow local advice. |
| `red` | Danger | High flood risk signal; avoid flood-prone areas and follow official instructions. |

## Inputs

### Forecast Rainfall

Required for Phase 1:

- Forecast provider: `gfs` or `ecmwf_open_data`
- Model run time in UTC
- Forecast valid time in UTC
- Lead time in hours
- Rainfall amount in millimeters
- Grid cell or basin subarea geometry
- Retrieval time and source attribution

Derived rainfall features:

- `rainfall1hMm`
- `rainfall3hMm`
- `rainfall6hMm`
- `rainfall24hMm`
- `rainfall48hMm`
- `rainfall72hMm`

Phase 1 can calculate these from model accumulation fields or normalized forecast frames, as long as the API output documents the window and unit.

### Water Level

Optional when reliable station data exists:

- Station ID and name
- Observed time in UTC
- Water level in meters
- Station-specific `watchLevelM`, `warningLevelM`, and `dangerLevelM` when available
- Source attribution and retrieval time

If water-level thresholds are missing or the station source is mock data, water level should be shown as supporting context, not as the sole reason for a public `red` status.

### Geographic Unit

The risk layer can be computed at either:

- Basin-level summary for the public status card
- Grid cell or subarea for a map heatmap

Use the same rule table for both, then aggregate to the public status by taking the maximum risk across inhabited or relevant basin cells. For display, include the dominant reasons instead of exposing every cell calculation.

## Seed Thresholds

These thresholds are initial MVP values for transparent testing. They must be calibrated against historical Hat Yai flood events before being treated as operational guidance.

### Rainfall Accumulation Thresholds

| Feature | `green` | `yellow` | `orange` | `red` |
| --- | ---: | ---: | ---: | ---: |
| 1h rainfall | `< 25 mm` | `25-39 mm` | `40-59 mm` | `>= 60 mm` |
| 3h rainfall | `< 40 mm` | `40-69 mm` | `70-99 mm` | `>= 100 mm` |
| 6h rainfall | `< 60 mm` | `60-99 mm` | `100-149 mm` | `>= 150 mm` |
| 24h rainfall | `< 80 mm` | `80-129 mm` | `130-199 mm` | `>= 200 mm` |
| 48h rainfall | `< 120 mm` | `120-199 mm` | `200-299 mm` | `>= 300 mm` |
| 72h rainfall | `< 160 mm` | `160-249 mm` | `250-349 mm` | `>= 350 mm` |

Use inclusive lower bounds. For example, `rainfall24hMm = 130` maps to `orange`.

### Water-Level Thresholds

Station-specific thresholds are preferred. When a station has `watchLevelM`, `warningLevelM`, and `dangerLevelM`:

| Condition | Water-level contribution |
| --- | --- |
| Below `watchLevelM` | `green` |
| At or above `watchLevelM` | `yellow` |
| At or above `warningLevelM` | `orange` |
| At or above `dangerLevelM` | `red` |

If only `warningLevelM` and `dangerLevelM` exist, derive `watchLevelM` as 80% of `warningLevelM` for prototype display and mark the derived value in metadata.

## Scoring And Decision Logic

Assign each level a score:

| Level | Score |
| --- | ---: |
| `green` | 0 |
| `yellow` | 1 |
| `orange` | 2 |
| `red` | 3 |

For each geographic unit:

1. Score each rainfall window using the threshold table.
2. Score each available water-level station using station thresholds.
3. Set the base score to the maximum score from rainfall and reliable water-level signals.
4. Keep the highest-scoring reasons as `drivers`.
5. Apply freshness and uncertainty flags, but do not silently lower a risk score because data is stale or uncertain.

Decision table:

| Situation | Output behavior |
| --- | --- |
| No forecast rainfall is available | Do not assign a risk level; return availability metadata or omit the risk feature and show a data unavailable message. |
| Forecast is available and fresh | Return the max rainfall score, optionally raised by reliable water-level score. |
| Forecast is stale | Return the computed level with `freshness.status: "stale"` and public stale-data copy. |
| Rainfall is low but water level is at warning/danger | Use water-level score if station thresholds are reliable. |
| Water station data is mock or thresholdless | Include station context, but do not raise above rainfall score. |
| Multiple models disagree | Use the higher risk level for public display and expose model disagreement in `uncertainty`. |

Recommended freshness rules:

- `fresh`: model run age is at or below 12 hours.
- `aging`: model run age is greater than 12 hours and at or below 18 hours.
- `stale`: model run age is greater than 18 hours, or retrieval failed for the latest expected cycle.

## Output Schema

The backend-facing shape should stay stable whether the risk comes from mock data, GFS, ECMWF Open Data, or later calibrated rules.

```json
{
  "id": "risk-hatyai-basin-current",
  "areaId": "hatyai-basin",
  "areaName": {
    "th": "ลุ่มน้ำคลองอู่ตะเภาและพื้นที่หาดใหญ่",
    "en": "U-Tapao Canal and Hat Yai basin"
  },
  "level": "orange",
  "score": 2,
  "validFrom": "2026-05-01T00:00:00Z",
  "validTo": "2026-05-04T00:00:00Z",
  "generatedAt": "2026-05-01T03:30:00Z",
  "drivers": [
    {
      "type": "rainfall_accumulation",
      "windowHours": 24,
      "valueMm": 142,
      "thresholdLevel": "orange",
      "source": "gfs",
      "runTime": "2026-05-01T00:00:00Z",
      "validTime": "2026-05-02T00:00:00Z"
    }
  ],
  "freshness": {
    "status": "fresh",
    "modelRunAgeHours": 3.5,
    "latestSourceRetrievedAt": "2026-05-01T03:20:00Z"
  },
  "uncertainty": {
    "level": "medium",
    "reasons": [
      "Forecast rainfall can shift between model runs.",
      "Observed water-level data is not yet available for all stations."
    ]
  },
  "explanation": {
    "th": "คาดว่าฝนสะสม 24 ชั่วโมงอยู่ในระดับสูง อาจเกิดน้ำท่วมในพื้นที่ลุ่มต่ำและพื้นที่ระบายน้ำช้า โปรดติดตามประกาศจากหน่วยงานทางการ",
    "en": "Forecast 24-hour accumulated rainfall is high. Flooding is possible in low-lying or slow-drainage areas. Please monitor official local guidance."
  },
  "isOfficialWarning": false
}
```

For map features, wrap the same properties in GeoJSON:

```json
{
  "type": "Feature",
  "geometry": {
    "type": "Polygon",
    "coordinates": []
  },
  "properties": {
    "areaId": "hatyai-grid-001",
    "level": "yellow",
    "score": 1,
    "primaryDriver": "rainfall24hMm",
    "generatedAt": "2026-05-01T03:30:00Z"
  }
}
```

## Public Explanation Text

Use concise Thai and English copy that explains what the level means and why it was assigned.

| Level | Thai | English |
| --- | --- | --- |
| `green` | สถานการณ์ปกติ จากข้อมูลพยากรณ์ล่าสุดยังไม่พบสัญญาณฝนสะสมหรือระดับน้ำที่เพิ่มความเสี่ยงน้ำท่วมอย่างมีนัยสำคัญ | Normal conditions. Latest forecast data does not show rainfall accumulation or water-level signals that meaningfully increase flood risk. |
| `yellow` | เฝ้าระวัง ฝนสะสมหรือระดับน้ำเริ่มสูงขึ้น ควรติดตามข้อมูลอัปเดต โดยเฉพาะพื้นที่ลุ่มต่ำและพื้นที่ระบายน้ำช้า | Watch. Rainfall accumulation or water levels are increasing. Monitor updates, especially in low-lying or slow-drainage areas. |
| `orange` | เตือนภัย มีสัญญาณฝนสะสมหรือระดับน้ำสูงที่อาจทำให้เกิดน้ำท่วมในบางพื้นที่ เตรียมพร้อมและติดตามคำแนะนำจากหน่วยงานในพื้นที่ | Warning. Forecast rainfall or water-level signals suggest flooding is possible in some areas. Prepare and follow local official guidance. |
| `red` | อันตราย มีสัญญาณความเสี่ยงน้ำท่วมสูง หลีกเลี่ยงพื้นที่เสี่ยงน้ำท่วมและปฏิบัติตามคำแนะนำจากหน่วยงานทางการทันที | Danger. High flood-risk signals are present. Avoid flood-prone areas and follow official instructions immediately. |

Freshness copy:

| Status | Thai | English |
| --- | --- | --- |
| `fresh` | ข้อมูลพยากรณ์อัปเดตล่าสุด | Forecast data is up to date. |
| `aging` | ข้อมูลพยากรณ์เริ่มเก่า ควรตรวจสอบอัปเดตถัดไป | Forecast data is aging. Check the next update. |
| `stale` | ข้อมูลพยากรณ์ล่าช้ากว่าปกติ โปรดใช้ความระมัดระวังและตรวจสอบแหล่งข้อมูลทางการ | Forecast data is older than expected. Use caution and check official sources. |

Always pair public text with `isOfficialWarning: false` until the project has production governance and agency coordination.

## Uncertainty Handling

Represent uncertainty explicitly instead of hiding it:

- Forecast models can shift rainfall location and intensity between runs.
- Global model grid resolution may miss local convective rainfall.
- Basin flooding depends on drainage, soil saturation, upstream flow, tide interaction, and infrastructure conditions that may not be represented in Phase 1.
- Mock or sparse water-level stations should be labeled clearly.
- Model disagreement should be shown as an uncertainty reason and should not reduce a high-risk signal.

Recommended uncertainty levels:

| Level | Criteria |
| --- | --- |
| `low` | Fresh forecast, one or more models agree, and supporting observations are available. |
| `medium` | Fresh forecast exists, but observations are missing or models differ by one risk level. |
| `high` | Forecast is stale, models differ by two or more levels, or key input data is unavailable. |

## Historical Calibration Plan

Thresholds should be revised once historical Hat Yai flood events and non-flood heavy-rain events are assembled.

Minimum calibration dataset:

- Event date and location
- Flood impact label, such as no flood, nuisance flooding, road flooding, property flooding, or severe flooding
- Observed rainfall windows: 1h, 3h, 6h, 24h, 48h, and 72h
- Available water levels and station thresholds
- Forecast model runs available before the event, separated by run time, valid time, and lead time
- Notes on tide, drainage, river conditions, and source reliability when available

Calibration method:

1. Build an event table with both flood and non-flood periods.
2. Calculate rainfall windows and water-level exceedances for each event.
3. Test candidate thresholds against observed impact labels.
4. Report misses, false alarms, lead time, and model disagreement.
5. Adjust thresholds conservatively, prioritizing public explainability over narrow statistical optimization.
6. Keep threshold versions in configuration with notes on calibration data and effective date.

Useful validation metrics:

- Probability of detection for known flood events
- False alarm ratio for high-risk forecasts
- Critical success index for `orange` and `red`
- Median lead time before reported impact
- Number of events with missing observations

## Implementation Notes

- Store thresholds in backend configuration, not hard-coded UI logic.
- Keep rainfall units in millimeters and timestamps in ISO 8601 UTC.
- Include source, run time, valid time, generated time, and retrieval time in risk outputs.
- Do not expose raw provider payloads directly to the frontend.
- Use the same `green`, `yellow`, `orange`, and `red` labels across API, map layer, and UI copy.
- Keep mock data shaped like the real output schema so frontend and backend work can proceed independently.
