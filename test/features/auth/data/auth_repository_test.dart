import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/auth/data/auth_repository.dart';
import 'package:hw_hub_mobile/features/auth/data/models/auth_user.dart';
import 'package:hw_hub_mobile/features/auth/data/models/invitation_info.dart';
import 'package:hw_hub_mobile/features/auth/data/models/login_response.dart';
import 'package:hw_hub_mobile/features/auth/data/models/register_response.dart';
import 'package:mockito/mockito.dart';

import '../auth_mocks.mocks.dart';

DioException _dioErr({Object? error}) => DioException(
  requestOptions: RequestOptions(path: '/test'),
  error: error,
);

void main() {
  late MockAuthApi mockApi;
  late AuthRepositoryImpl sut;

  setUp(() {
    mockApi = MockAuthApi();
    sut = AuthRepositoryImpl(api: mockApi);
  });

  group('AuthRepositoryImpl', () {
    group('login', () {
      test('成功時にLoginResponseを返す', () async {
        const resp = LoginResponse(
          accessToken: 'access',
          refreshToken: 'refresh',
          user: AuthUser(userId: 1, email: 'a@b.com', displayName: 'A'),
        );
        when(mockApi.login(any)).thenAnswer((_) async => resp);

        expect(await sut.login(email: 'a@b.com', password: 'pass'), resp);
      });

      test('DioExceptionにAppExceptionが含まれる場合はそのまま再throw', () {
        const appEx = ServerException(statusCode: 401, message: 'Unauthorized');
        when(mockApi.login(any)).thenThrow(_dioErr(error: appEx));

        expect(
          () => sut.login(email: 'a@b.com', password: 'pass'),
          throwsA(isA<ServerException>()),
        );
      });

      test('DioExceptionにAppException以外が含まれる場合はNetworkExceptionをthrow', () {
        when(
          mockApi.login(any),
        ).thenThrow(_dioErr(error: Exception('timeout')));

        expect(
          () => sut.login(email: 'a@b.com', password: 'pass'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('register', () {
      test('成功時にRegisterResponseを返す', () async {
        final resp = RegisterResponse(
          emailVerificationRequired: true,
          user: const AuthUser(userId: 1, email: 'a@b.com', displayName: 'A'),
        );
        when(mockApi.register(any)).thenAnswer((_) async => resp);

        expect(
          await sut.register(
            email: 'a@b.com',
            password: 'pass',
            displayName: 'A',
            locale: 'ja',
          ),
          resp,
        );
      });

      test('DioException → NetworkException', () {
        when(mockApi.register(any)).thenThrow(_dioErr());

        expect(
          () => sut.register(
            email: 'a@b.com',
            password: 'pass',
            displayName: 'A',
            locale: 'ja',
          ),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('verifyEmail', () {
      test('成功時に例外なし', () async {
        when(mockApi.verifyEmail(any)).thenAnswer((_) async {});

        await expectLater(sut.verifyEmail(token: 'tok'), completes);
      });

      test('DioException → NetworkException', () {
        when(mockApi.verifyEmail(any)).thenThrow(_dioErr());

        expect(
          () => sut.verifyEmail(token: 'tok'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('getInvitation', () {
      test('成功時にInvitationInfoを返す', () async {
        const info = InvitationInfo(
          householdName: '田中家',
          inviterName: '田中 太郎',
          invitedEmail: 'user@example.com',
        );
        when(mockApi.getInvitation(any)).thenAnswer((_) async => info);

        expect(await sut.getInvitation(token: 'tok'), info);
      });

      test('DioException → NetworkException', () {
        when(mockApi.getInvitation(any)).thenThrow(_dioErr());

        expect(
          () => sut.getInvitation(token: 'tok'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('acceptInvitation', () {
      test('成功時に例外なし', () async {
        when(mockApi.acceptInvitation(any)).thenAnswer((_) async {});

        await expectLater(sut.acceptInvitation(token: 'tok'), completes);
      });

      test('DioExceptionにApiExceptionが含まれる場合はそのまま再throw', () {
        const appEx = ApiException('forbidden', code: 'FORBIDDEN');
        when(mockApi.acceptInvitation(any)).thenThrow(_dioErr(error: appEx));

        expect(
          () => sut.acceptInvitation(token: 'tok'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('googleLoginMobile', () {
      test('成功時にLoginResponseを返す', () async {
        const resp = LoginResponse(
          accessToken: 'access',
          refreshToken: 'refresh',
          user: AuthUser(userId: 1, email: 'a@b.com', displayName: 'A'),
        );
        when(mockApi.googleLoginMobile(any)).thenAnswer((_) async => resp);

        expect(await sut.googleLoginMobile(idToken: 'id-token'), resp);
      });

      test('DioException → NetworkException', () {
        when(mockApi.googleLoginMobile(any)).thenThrow(_dioErr());

        expect(
          () => sut.googleLoginMobile(idToken: 'id-token'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('resendVerification', () {
      test('成功時に例外なし', () async {
        when(mockApi.resendVerification(any)).thenAnswer((_) async {});

        await expectLater(sut.resendVerification(email: 'a@b.com'), completes);
      });

      test('DioException → NetworkException', () {
        when(mockApi.resendVerification(any)).thenThrow(_dioErr());

        expect(
          () => sut.resendVerification(email: 'a@b.com'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('requestPasswordReset', () {
      test('成功時に例外なし', () async {
        when(mockApi.requestPasswordReset(any)).thenAnswer((_) async {});

        await expectLater(
          sut.requestPasswordReset(email: 'a@b.com'),
          completes,
        );
      });

      test('DioException → NetworkException', () {
        when(mockApi.requestPasswordReset(any)).thenThrow(_dioErr());

        expect(
          () => sut.requestPasswordReset(email: 'a@b.com'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('confirmPasswordReset', () {
      test('成功時に例外なし', () async {
        when(mockApi.confirmPasswordReset(any)).thenAnswer((_) async {});

        await expectLater(
          sut.confirmPasswordReset(token: 'tok', newPassword: 'newpass'),
          completes,
        );
      });

      test('DioException → NetworkException', () {
        when(mockApi.confirmPasswordReset(any)).thenThrow(_dioErr());

        expect(
          () => sut.confirmPasswordReset(token: 'tok', newPassword: 'newpass'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('declineInvitation', () {
      test('成功時に例外なし', () async {
        when(mockApi.declineInvitation(any)).thenAnswer((_) async {});

        await expectLater(sut.declineInvitation(token: 'tok'), completes);
      });

      test('DioException → NetworkException', () {
        when(mockApi.declineInvitation(any)).thenThrow(_dioErr());

        expect(
          () => sut.declineInvitation(token: 'tok'),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
