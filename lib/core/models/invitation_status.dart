enum InvitationStatus {
  pending('0'),
  accepted('1'),
  declined('7'),
  revoked('8'),
  expired('9');

  const InvitationStatus(this.code);
  final String code;

  static InvitationStatus? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
