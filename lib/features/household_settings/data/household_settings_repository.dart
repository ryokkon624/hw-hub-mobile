import 'package:dio/dio.dart';
import '../../../core/network/app_exception.dart';
import 'models/household_dto.dart';
import 'models/household_invitation_dto.dart';
import 'models/household_member_dto.dart';

export 'models/household_dto.dart';
export 'models/household_invitation_dto.dart';
export 'models/household_member_dto.dart';

abstract class HouseholdSettingsRepository {
  /// メンバー一覧を取得する。
  Future<List<HouseholdSettingsMemberDto>> fetchMembers({
    required int householdId,
  });

  /// 招待一覧を取得する。
  Future<List<HouseholdInvitationDto>> fetchInvitations({
    required int householdId,
  });

  /// 招待を作成する。
  Future<HouseholdInvitationDto> createInvitation({
    required int householdId,
    required String invitedEmail,
  });

  /// 招待を取り消す。
  Future<void> revokeInvitation({required String token});

  /// 世帯名を更新する。
  Future<void> updateHouseholdName({
    required int householdId,
    required String name,
  });

  /// ニックネームを更新する。
  Future<void> updateNickname({
    required int householdId,
    required String nickname,
  });

  /// メンバーを除外する（OWNERのみ）。
  Future<void> removeMember({required int householdId, required int userId});

  /// OWNERを譲渡する。
  Future<void> transferOwner({
    required int householdId,
    required int newOwnerUserId,
  });

  /// 自分がこの世帯から離脱する。
  Future<void> leaveHousehold({required int householdId});

  /// 世帯を新規作成する。
  Future<HouseholdSettingsDto> createHousehold({required String name});

  /// 世帯を削除する。
  Future<void> deleteHousehold({required int householdId});

  /// 家事マスタの件数を取得する。
  Future<int> fetchHouseworkCount({required int householdId});

  /// 未購入の買い物件数を取得する。
  Future<int> fetchShoppingCount({required int householdId});
}

class HouseholdSettingsRepositoryImpl implements HouseholdSettingsRepository {
  HouseholdSettingsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<HouseholdSettingsMemberDto>> fetchMembers({
    required int householdId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/households/$householdId/members',
      );
      return (response.data as List<dynamic>)
          .map(
            (e) =>
                HouseholdSettingsMemberDto.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<List<HouseholdInvitationDto>> fetchInvitations({
    required int householdId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/households/$householdId/invitations',
      );
      return (response.data as List<dynamic>)
          .map(
            (e) => HouseholdInvitationDto.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<HouseholdInvitationDto> createInvitation({
    required int householdId,
    required String invitedEmail,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/households/$householdId/invitations',
        data: {'invitedEmail': invitedEmail},
      );
      return HouseholdInvitationDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> revokeInvitation({required String token}) async {
    try {
      await _dio.post<dynamic>('/api/household-invitations/$token/revoke');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> updateHouseholdName({
    required int householdId,
    required String name,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/api/households/$householdId',
        data: {'name': name},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> updateNickname({
    required int householdId,
    required String nickname,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/api/households/$householdId/members/me/nickname',
        data: {'nickname': nickname},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> removeMember({
    required int householdId,
    required int userId,
  }) async {
    try {
      await _dio.delete<dynamic>(
        '/api/households/$householdId/members/$userId',
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> transferOwner({
    required int householdId,
    required int newOwnerUserId,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/api/households/$householdId/transfer-owner',
        data: {'newOwnerUserId': newOwnerUserId},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> leaveHousehold({required int householdId}) async {
    try {
      await _dio.delete<dynamic>('/api/households/$householdId/members/me');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<HouseholdSettingsDto> createHousehold({required String name}) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/households',
        data: {'name': name},
      );
      return HouseholdSettingsDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> deleteHousehold({required int householdId}) async {
    try {
      await _dio.delete<dynamic>('/api/households/$householdId');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<int> fetchHouseworkCount({required int householdId}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/houseworks',
        queryParameters: {'householdId': householdId},
      );
      // リストを受け取ったら即カウントして破棄（メモリに保持しない）
      final count = (response.data as List<dynamic>).length;
      return count;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<int> fetchShoppingCount({required int householdId}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/households/$householdId/shopping-items',
        queryParameters: <String, dynamic>{},
      );
      final data = response.data as Map<String, dynamic>;
      // リストを受け取ったら即カウントして破棄（メモリに保持しない）
      final count = (data['items'] as List<dynamic>).length;
      return count;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
