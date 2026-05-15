// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_attachment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAttachmentRequest _$CreateAttachmentRequestFromJson(
  Map<String, dynamic> json,
) => CreateAttachmentRequest(
  fileKey: json['fileKey'] as String,
  fileName: json['fileName'] as String,
  mimeType: json['mimeType'] as String,
);

Map<String, dynamic> _$CreateAttachmentRequestToJson(
  CreateAttachmentRequest instance,
) => <String, dynamic>{
  'fileKey': instance.fileKey,
  'fileName': instance.fileName,
  'mimeType': instance.mimeType,
};
