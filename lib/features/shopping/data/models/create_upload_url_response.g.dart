// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_upload_url_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateUploadUrlResponse _$CreateUploadUrlResponseFromJson(
  Map<String, dynamic> json,
) => CreateUploadUrlResponse(
  uploadUrl: json['uploadUrl'] as String,
  fileKey: json['fileKey'] as String,
);

Map<String, dynamic> _$CreateUploadUrlResponseToJson(
  CreateUploadUrlResponse instance,
) => <String, dynamic>{
  'uploadUrl': instance.uploadUrl,
  'fileKey': instance.fileKey,
};
