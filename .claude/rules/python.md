---
description: Backend Python conventions for FastAPI and MongoDB
globs:
  - backend/**/*.py
  - backend/**/pyproject.toml
alwaysApply: false
---

# Python Backend Conventions

## Typing

- Target Python 3.13+.
- Avoid `Any`. Use precise types, `object` for opaque values, or `JsonValue` from Pydantic for arbitrary JSON payloads.
- Use modern typing syntax: `X | None`, `list[T]`, `dict[str, T]`, and imports from `collections.abc`.
- Prefer `StrEnum` for string enums.

## FastAPI And Async IO

- Use async IO for MongoDB, weather API clients, file-heavy ingestion, and network calls.
- Manage long-lived clients through FastAPI lifespan.
- Keep dependencies small and explicit. Avoid hidden global state outside application setup.
- Use timezone-aware UTC datetimes internally: `datetime.now(UTC)`.

## MongoDB Data Model

- Use Pydantic v2 models at API boundaries and for normalized internal records.
- Prefer MongoDB time-series collections for station observations, rainfall forecasts, and forecast model runs when they grow over time.
- Use `2dsphere` indexes for station locations, basin geometry, and geographic queries.
- Store provider provenance, model run time, forecast valid time, units, and freshness metadata with forecast records.
- Keep public response shapes stable even while provider integrations evolve.

## Risk Logic

- Keep Phase 1 flood risk rule-based and auditable.
- Use the project risk levels consistently: green, yellow, orange, red.
- Separate provider normalization, station aggregation, and risk classification so rules can be tested independently.

## Docstrings

Add Google-style docstrings to public functions, classes, and route handlers.

- Start with a one-line imperative summary.
- Add `Args:`, `Returns:`, `Yields:`, or `Raises:` only when useful.
- Do not repeat type information already present in signatures.
- Skip private helpers and obvious dunder methods unless behavior is non-obvious.

## Tooling

- Prefer `backend/pyproject.toml` over `requirements.txt`.
- Use Ruff when configured. A good baseline is `E`, `F`, `I`, `B`, and `UP`, with FastAPI-specific exceptions only when justified.
- Do not add `# noqa` comments without a concrete reason.
