class InvitationInfo {
  const InvitationInfo({
    required this.householdName,
    required this.inviterName,
    required this.invitedEmail,
  });

  final String householdName;
  final String inviterName;
  final String invitedEmail;

  factory InvitationInfo.fromJson(Map<String, dynamic> json) => InvitationInfo(
    householdName: json['householdName'] as String,
    inviterName: json['inviterName'] as String,
    invitedEmail: json['invitedEmail'] as String,
  );
}
