import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'models/invitation_info.dart';
import 'models/login_response.dart';
import 'models/register_response.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  @POST('/api/auth/login')
  Future<LoginResponse> login(@Body() Map<String, dynamic> body);

  @POST('/api/auth/google/mobile')
  Future<LoginResponse> googleLoginMobile(@Body() Map<String, dynamic> body);

  @POST('/api/auth/register')
  Future<RegisterResponse> register(@Body() Map<String, dynamic> body);

  @POST('/api/auth/email-verification/resend')
  Future<void> resendVerification(@Body() Map<String, dynamic> body);

  @POST('/api/auth/email-verification/verify')
  Future<void> verifyEmail(@Body() Map<String, dynamic> body);

  @POST('/api/auth/password-reset/request')
  Future<void> requestPasswordReset(@Body() Map<String, dynamic> body);

  @POST('/api/auth/password-reset/confirm')
  Future<void> confirmPasswordReset(@Body() Map<String, dynamic> body);

  @GET('/api/household-invitations/{token}')
  Future<InvitationInfo> getInvitation(@Path('token') String token);

  @POST('/api/household-invitations/{token}/accept')
  Future<void> acceptInvitation(@Path('token') String token);

  @POST('/api/household-invitations/{token}/decline')
  Future<void> declineInvitation(@Path('token') String token);
}
