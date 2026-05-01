---
description: Frontend conventions for the Hat Yai flood warning app
globs:
  - frontend/**/*.ts
  - frontend/**/*.tsx
  - frontend/**/*.css
  - frontend/**/package.json
alwaysApply: false
---

# Frontend Conventions

## TypeScript And React

- Keep TypeScript strict. Do not use `any`; prefer `unknown` plus narrowing when input shape is not trusted.
- Use React function components and hooks. Avoid class components.
- Type API responses explicitly and keep shared contracts near the API client or generated contract layer.
- Use `useMemo` and `useCallback` only when they remove real recomputation or stabilize props for a measured reason.

## Product UI

- Design mobile-first for public flood awareness in Hat Yai.
- Keep Thai and English UI copy easy to translate. Avoid scattering repeated text across components.
- Use the four project risk levels consistently: green, yellow, orange, red.
- Show data freshness, source, loading, empty, stale, and error states for forecasts and observations.
- Prefer clear public guidance over dense technical displays, while allowing research-oriented detail on secondary screens.

## Maps And Data Display

- Prefer MapLibre GL JS for maps.
- Keep station, basin, and forecast overlay data typed.
- Use accessible controls and readable legends for color-coded risk.
- Keep map-heavy screens usable on low-powered mobile devices.

## Project Boundaries

- Keep frontend HTTP calls centralized under `frontend/src/lib/` or the established local API layer.
- Use `VITE_API_URL` for backend base URLs.
- Follow the repo's existing package manager and scripts once they exist; do not introduce new tooling without need.
