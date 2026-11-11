# Bundled fonts: sources

Every file in this folder comes from the font's official upstream, unchanged.
Fetched 2026-11-05 by the Developer (T-103, plan F-002 §2, DECISIONS D-028).
Re-check a file with `Get-FileHash <file> -Algorithm SHA256` (PowerShell) or
`sha256sum <file>`.

| File | Upstream | Release / commit | SHA-256 |
|---|---|---|---|
| `BricolageGrotesque-SemiBold.ttf` | https://github.com/ateliertriay/bricolage, `fonts/ttf/BricolageGrotesque-SemiBold.ttf` | commit `84745e5b96261ae5f8c6c856e262fe78d1d6efdd` | `25534ff95de6305903a3f74b237f07d9e32adefec13d0f0a0d99a4b820c6a8cf` |
| `BricolageGrotesque-Bold.ttf` | https://github.com/ateliertriay/bricolage, `fonts/ttf/BricolageGrotesque-Bold.ttf` | commit `84745e5b96261ae5f8c6c856e262fe78d1d6efdd` | `f83cb3f1ddb91bdb02868eeddb4f817b326aef993f96fe6f8a3b40b0f31c689b` |
| `OFL-BricolageGrotesque.txt` | https://github.com/ateliertriay/bricolage, `OFL.txt` | commit `84745e5b96261ae5f8c6c856e262fe78d1d6efdd` | `4b5a7d8f37f5602621c8a8d7358a6a2e71317e6c231c661e15aef0275d3e07ba` |
| `IBMPlexSans-Regular.ttf` | https://github.com/IBM/plex/releases/tag/%40ibm/plex-sans%401.1.0, asset `ibm-plex-sans.zip` → `ibm-plex-sans/fonts/complete/ttf/IBMPlexSans-Regular.ttf` | `@ibm/plex-sans@1.1.0` (2024-11-13) | `975dcda37d80f038dcd143c22e33ca2d97a0cc5a929aace1c749153b0fe1afa5` |
| `IBMPlexSans-Medium.ttf` | same zip → `ibm-plex-sans/fonts/complete/ttf/IBMPlexSans-Medium.ttf` | `@ibm/plex-sans@1.1.0` | `331c8639d7598b2cde62a911a71db195e30cb655cd6bdf2e324a7e984955f907` |
| `IBMPlexSans-SemiBold.ttf` | same zip → `ibm-plex-sans/fonts/complete/ttf/IBMPlexSans-SemiBold.ttf` | `@ibm/plex-sans@1.1.0` | `a20caf8286023a6a7a85e40b1d2a4ae9fc3e3b1f9eda8f4c542dd4986af67bb1` |
| `OFL-IBMPlexSans.txt` | same zip → `ibm-plex-sans/LICENSE.txt` | `@ibm/plex-sans@1.1.0` | `7e6b2818edbd8f6a01ae80641cc8f16a51080d08fb4e532be3a0b6f74adb07da` |

Checks done when fetching:
- The two Bricolage fonts and `OFL.txt` match the git blob hashes that GitHub's
  contents API reports for that commit (`git hash-object`): SemiBold
  `d6c29d19b85775789d5579b6a506f23845b0586d`, Bold
  `f18a1776f42b8f5009233b575db3428ae0fae735`, `OFL.txt`
  `a397658a5c4ab27c349964553b7caca61a4346f6`.
- `ibm-plex-sans.zip` (9,921,777 bytes, the size GitHub lists for the release
  asset) had SHA-256
  `fb365d910566e6d199cc2c15579a7dd9a267128e18431a394ed81f1970c69200`.
- Licence: both families are SIL Open Font License 1.1. The texts are kept
  byte-for-byte (`.gitattributes` marks `app/assets/fonts/*.txt` as `-text`).
- The Plex files contain the rupee sign (U+20B9) and tabular figures (`tnum`):
  checked on every test run by `TC-002-42` (`test/core/theme/fonts_test.dart`).
