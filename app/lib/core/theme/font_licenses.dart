import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Package names the bundled fonts are listed under in the licence registry.
const kBricolageLicenseName = 'Bricolage Grotesque';
const kPlexLicenseName = 'IBM Plex Sans';

/// Registers the SIL OFL 1.1 texts of the bundled fonts, so they appear in
/// Flutter's licence list (F-002 AC-17). The texts are loaded from the bundled
/// assets only when the licence list is read.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      kBricolageLicenseName,
    ], await rootBundle.loadString('assets/fonts/OFL-BricolageGrotesque.txt'));
    yield LicenseEntryWithLineBreaks(const [
      kPlexLicenseName,
    ], await rootBundle.loadString('assets/fonts/OFL-IBMPlexSans.txt'));
  });
}
