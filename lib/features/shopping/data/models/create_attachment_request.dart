import 'package:json_annotation/json_annotation.dart';

part 'create_attachment_request.g.dart';

@JsonSerializable()
class CreateAttachmentRequest {
  const CreateAttachmentRequest({
    required this.fileKey,
    required this.fileName,
    required this.mimeType,
  });

  final String fileKey;
  final String fileName;
  final String mimeType;

  Map<String, dynamic> toJson() => _$CreateAttachmentRequestToJson(this);

  factory CreateAttachmentRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAttachmentRequestFromJson(json);
}
