class InquirySummaryDto {
  const InquirySummaryDto({
    required this.inquiryId,
    required this.category,
    required this.status,
    required this.title,
    required this.createdAt,
  });

  final int inquiryId;
  final String category;
  final String status;
  final String title;
  final String createdAt;

  factory InquirySummaryDto.fromJson(Map<String, dynamic> json) {
    return InquirySummaryDto(
      inquiryId: json['inquiryId'] as int,
      category: json['category'] as String,
      status: json['status'] as String,
      title: json['title'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}
