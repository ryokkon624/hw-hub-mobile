class InquiryMessageDto {
  const InquiryMessageDto({
    required this.messageId,
    required this.seq,
    required this.senderType,
    required this.body,
    required this.createdAt,
  });

  final int messageId;
  final int seq;
  final String senderType;
  final String body;
  final String createdAt;

  factory InquiryMessageDto.fromJson(Map<String, dynamic> json) {
    return InquiryMessageDto(
      messageId: json['messageId'] as int,
      seq: json['seq'] as int,
      senderType: json['senderType'] as String,
      body: json['body'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}
