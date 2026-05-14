// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_upload_url_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateUploadUrlRequest _$CreateUploadUrlRequestFromJson(
  Map<String, dynamic> json,
) => CreateUploadUrlRequest(
  fileName: json['fileName'] as String,
  mimeType: json['mimeType'] as String,
);

Map<String, dynamic> _$CreateUploadUrlRequestToJson(
  CreateUploadUrlRequest instance,
) => <String, dynamic>{
  'fileName': instance.fileName,
  'mimeType': instance.mimeType,
};
