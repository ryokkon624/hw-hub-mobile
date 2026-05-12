enum HouseholdMemberStatus {
  invited('0'),
  active('1'),
  left('9');

  const HouseholdMemberStatus(this.code);
  final String code;

  static HouseholdMemberStatus? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
