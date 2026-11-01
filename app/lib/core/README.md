# core/

Shared building blocks used by every feature.

- **May contain:** shared utilities, the app theme (Light, Dark, Dim, Auto — Phase 1), shared widgets such as the help/tooltip widget, and formatting helpers for the UI (e.g. Indian money formatting).
- **May import:** Flutter, `domain/`.
- **Must not import:** `features/` (core is below the features), or the database directly.
