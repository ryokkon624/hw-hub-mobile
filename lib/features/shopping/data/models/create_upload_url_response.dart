import 'package:json_annotation/json_annotation.dart';

part 'create_upload_url_response.g.dart';

@JsonSerializable()
class CreateUploadUrlResponse {
  const CreateUploadUrlResponse({
    required this.uploadUrl,
    required this.fileKey,
  });

  final String uploadUrl;
  final String fileKey;

  factory CreateUploadUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateUploadUrlResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateUploadUrlResponseToJson(this);
}
