/// The first-time hints, one per main tab (F-004 AC-7).
///
/// Each carries a versioned storage suffix: a later phase that changes a
/// tip gives it a new version (`home.v2`), so it shows once more while the
/// old "seen" flag is simply ignored (F-004 edge cases).
enum HintId {
  home('home.v1'),
  dashboard('dashboard.v1'),
  transactions('transactions.v1'),
  settings('settings.v1'),

  /// The tip above the Home calendar (F-011), shown once `home` is gone.
  calendar('calendar.v1');

  new(this.storageSuffix);

  final String storageSuffix;
}
