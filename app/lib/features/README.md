# features/

One folder per feature (e.g. `home/`, `calendar/`, `dashboard/`, `setup/`, `settings/`).

- **May contain:** screens and the small widgets that belong to one feature.
- **May import:** `core/`, `domain/`, and repositories from `data/` through Riverpod providers (from Phase 1).
- **Must not:** open the database directly, or hold money/date logic (that belongs in `domain/`).
- Every button, setting and number has a label plus a description or (i) tooltip, and every screen works in all four themes (STANDARDS §7).
