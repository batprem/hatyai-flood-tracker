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
- Inside `Args:`, use `name: description.` — **no type in the docstring**. The signature is the canonical source for types; repeating them is noise, especially for FastAPI `Annotated[T, Depends(...)]` parameters. Pydoclint is configured with `arg-type-hints-in-docstring = false` to enforce this.
- For optional parameters, mention the default in the description (for example `provider: Optional provider name to scope freshness. Defaults to ``None``.`).
- **`Returns:` is mandatory** on every public callable whose return annotation is not `None`. Write `Returns:\n    description.` — description only, never the type.
- **`Raises:` is mandatory** when the function body contains a `raise <Exception>(...)`. List each exception class with a short description: `ExceptionClass: when it is raised.`
- `Yields:` follows the same rules as `Returns:` for generators.
- Skip private helpers (`_foo`) and obvious dunder methods (`__init__`, `__repr__`, `__eq__`) unless their behavior is genuinely non-obvious. When a private helper is documented, the same `Args:`/`Returns:`/`Raises:` rules apply.
- Public Pydantic model classes need a class-level docstring describing what the model represents; field documentation belongs in `Field(description=...)`, not in the class docstring.
- The hook `uv run pydoclint --style=google` runs after every backend Python edit and **blocks** on any violation. Treat its output as the canonical pass/fail.

## Tooling

- Prefer `backend/pyproject.toml` over `requirements.txt`.
- Use Ruff when configured. A good baseline is `E`, `F`, `I`, `B`, and `UP`, with FastAPI-specific exceptions only when justified.
- Do not add `# noqa` comments without a concrete reason.
