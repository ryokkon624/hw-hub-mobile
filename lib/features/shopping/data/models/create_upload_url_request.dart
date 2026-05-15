import 'package:json_annotation/json_annotation.dart';

part 'create_upload_url_request.g.dart';

@JsonSerializable()
class CreateUploadUrlRequest {
  const CreateUploadUrlRequest({
    required this.fileName,
    required this.mimeType,
  });

  final String fileName;
  final String mimeType;

  Map<String, dynamic> toJson() => _$CreateUploadUrlRequestToJson(this);

  factory CreateUploadUrlRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUploadUrlRequestFromJson(json);
}
