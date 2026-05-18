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

- Start with a one-line imperative summary that begins with an imperative verb (`Return`, `Compute`, `Persist`, `Model`, `Describe`, …) and ends with a period.
- **`Args:` is mandatory** on every public callable (function, method, classmethod, staticmethod, route handler) that has at least one parameter beyond `self`/`cls`. Document **every** parameter, including FastAPI dependency-injected parameters (`Annotated[..., Depends(...)]`). The only excluded names are `self` and `cls`.
- Use the full Google form inside `Args:`: `name (type): description.` The type **is** allowed to repeat the signature here, because the rendered docstring is the canonical reference for callers.
- For optional parameters, mention the default in the description (for example `provider (str | None): Optional provider name to scope freshness. Defaults to ``None``.`).
- Add `Returns:`, `Yields:`, or `Raises:` only when they add information beyond the signature. Do **not** repeat the return type in `Returns:` — write the description only.
- Skip private helpers (`_foo`) and obvious dunder methods (`__init__`, `__repr__`, `__eq__`) unless their behavior is genuinely non-obvious. When a private helper is documented, the same `Args:` rule applies.
- Public Pydantic model classes need a class-level docstring describing what the model represents; field documentation belongs in `Field(description=...)`, not in the class docstring.

## Tooling

- Prefer `backend/pyproject.toml` over `requirements.txt`.
- Use Ruff when configured. A good baseline is `E`, `F`, `I`, `B`, and `UP`, with FastAPI-specific exceptions only when justified.
- Do not add `# noqa` comments without a concrete reason.
