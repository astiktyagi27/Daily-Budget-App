# data/

Everything that stores or fetches data.

- **May contain:** the local database (Drift, Phase 2), the SMS source behind the `TransactionSource` interface (Phase 4), and repositories.
- **May import:** `domain/` (models and interfaces), database and platform packages.
- **Must not import:** `features/`.
- The UI never talks to the database directly: features go through repositories and Riverpod providers (STANDARDS §3).
- Never log SMS bodies, amounts or personal data.
