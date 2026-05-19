class AppInfoState {
  const AppInfoState({
    this.isLoadingApi = true,
    this.apiVersion,
    this.appVersion,
  });

  /// API バージョンの取得中かどうか
  final bool isLoadingApi;

  /// /actuator/info から取得した API バージョン。取得失敗時は null
  final String? apiVersion;

  /// package_info_plus で取得したアプリバージョン
  final String? appVersion;

  AppInfoState copyWith({
    bool? isLoadingApi,
    Object? apiVersion = _sentinel,
    Object? appVersion = _sentinel,
  }) {
    return AppInfoState(
      isLoadingApi: isLoadingApi ?? this.isLoadingApi,
      apiVersion: apiVersion == _sentinel
          ? this.apiVersion
          : apiVersion as String?,
      appVersion: appVersion == _sentinel
          ? this.appVersion
          : appVersion as String?,
    );
  }
}

const _sentinel = Object();
