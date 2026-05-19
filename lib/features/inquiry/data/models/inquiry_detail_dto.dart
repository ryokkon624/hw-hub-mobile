import 'inquiry_message_dto.dart';

export 'inquiry_message_dto.dart';

class InquiryDetailDto {
  const InquiryDetailDto({
    required this.inquiryId,
    required this.category,
    required this.status,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  final int inquiryId;
  final String category;
  final String status;
  final String title;
  final String createdAt;
  final List<InquiryMessageDto> messages;

  factory InquiryDetailDto.fromJson(Map<String, dynamic> json) {
    return InquiryDetailDto(
      inquiryId: json['inquiryId'] as int,
      category: json['category'] as String,
      status: json['status'] as String,
      title: json['title'] as String,
      createdAt: json['createdAt'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => InquiryMessageDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
