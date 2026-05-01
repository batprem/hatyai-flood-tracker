---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces for the Hat Yai flood warning app. Use when building public alert pages, map views, station dashboards, forecast displays, or other user-facing React UI.
---

This skill guides frontend UI work for a public flood monitoring product. The goal is a distinctive interface that feels trustworthy, local, mobile-first, and clear under stress.

## Design Direction

Before coding, choose a concrete visual direction that fits flood awareness:

- Prioritize public comprehension: current risk, location, trend, confidence, and next useful action.
- Design for Thai and English content from the start.
- Make risk state legible without relying on color alone.
- Use map, water, rainfall, and civic information patterns as inspiration without turning the app into a generic weather dashboard.
- Keep dense research detail available, but do not let it overwhelm the public alert view.

## Interface Quality

- Use strong typography, spacing, and hierarchy so urgent information scans quickly on mobile.
- Use consistent visual treatment for the four risk levels: green, yellow, orange, red.
- Treat data freshness and source attribution as first-class UI elements.
- Include loading, stale, empty, offline, and error states for live data.
- Prefer purposeful motion: subtle state transitions, forecast timeline changes, and map interactions. Avoid motion that obscures urgent information.
- Keep map legends, station markers, and chart colors accessible and understandable.

## Implementation

- Build real React + TypeScript components, not static mockups unless explicitly requested.
- Keep product logic out of primitive UI components.
- Centralize repeated labels, status metadata, and formatting helpers.
- Verify the result on a narrow mobile viewport before calling it done.
