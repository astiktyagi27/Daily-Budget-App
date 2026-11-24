/// The category of a spend (README section 3.4, F-013 T-380). The order here
/// is the README order: it breaks ties in the Dashboard and is the order of
/// the category picker (F-015).
///
/// Every spend without a category, or with a key this version does not know,
/// counts as [other] (never an error: data from a later version must open).
enum SpendCategory {
  food('food'),
  groceries('groceries'),
  shopping('shopping'),
  travel('travel'),
  billsRecharge('bills_recharge'),
  entertainment('entertainment'),
  health('health'),
  friendsPeople('friends_people'),
  other('other');

  new(this.key);

  /// The stored key: lower case with underscores. Phase 4's categoriser
  /// writes the same strings.
  final String key;

  /// The category stored as [key]. `null` and a key this version does not
  /// know both read as [other].
  static SpendCategory fromKey(String? key) {
    for (final category in values) {
      if (category.key == key) return category;
    }
    return other;
  }

  bool get isOther => this == other;
}
