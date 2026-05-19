import 'package:dio/dio.dart';
import '../../../core/network/app_exception.dart';
import 'models/inquiry_summary_dto.dart';
import 'models/inquiry_detail_dto.dart';

export 'models/inquiry_summary_dto.dart';
export 'models/inquiry_detail_dto.dart';

abstract class InquiryRepository {
  Future<List<InquirySummaryDto>> fetchInquiries();

  Future<int> createInquiry({
    required String category,
    required String title,
    required String body,
  });

  Future<InquiryDetailDto> fetchInquiry(int inquiryId);

  Future<void> addMessage(int inquiryId, String body);

  Future<void> closeInquiry(int inquiryId);

  Future<void> escalateToStaff(int inquiryId);
}

class InquiryRepositoryImpl implements InquiryRepository {
  InquiryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<InquirySummaryDto>> fetchInquiries() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/inquiries');
      final data = response.data!;
      return (data['items'] as List<dynamic>)
          .map((e) => InquirySummaryDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<int> createInquiry({
    required String category,
    required String title,
    required String body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/inquiries',
        data: {'category': category, 'title': title, 'body': body},
      );
      return response.data!['inquiryId'] as int;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<InquiryDetailDto> fetchInquiry(int inquiryId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/inquiries/$inquiryId',
      );
      return InquiryDetailDto.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> addMessage(int inquiryId, String body) async {
    try {
      await _dio.post<void>(
        '/api/inquiries/$inquiryId/messages',
        data: {'body': body},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> closeInquiry(int inquiryId) async {
    try {
      await _dio.post<void>('/api/inquiries/$inquiryId/close');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> escalateToStaff(int inquiryId) async {
    try {
      await _dio.post<void>('/api/inquiries/$inquiryId/escalate');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
