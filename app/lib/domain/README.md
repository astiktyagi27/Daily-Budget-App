# domain/

The app's rules, in pure Dart.

- **May contain:** models, the budget engine, SMS parsers, the categorizer — all money and date logic.
- **Pure Dart only:** no `package:flutter` and no `dart:ui` imports. The automated guard test `TC-001-06` (`test/architecture/domain_purity_test.dart`) fails the build if one appears.
- **Money is integer paise** (`int`), never `double` (STANDARDS §4).
- Everything here is unit-tested, aiming at 100% of branches.
