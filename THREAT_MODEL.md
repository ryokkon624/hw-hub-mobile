# THREAT_MODEL — hw-hub-mobile

Housework Hub モバイルアプリ（Flutter 3 / Dart 3 / Riverpod / go_router / Dio）の脅威モデル。
LLM ベースのセキュリティスキャンおよび人手レビューが、**何を守り・何を信頼し・何を対象外とするか**を共有するための土台ドキュメント。

> 本書は Anthropic「Using LLMs to secure source code」の Find-and-Fix ループ Step 1（Threat Modeling）に対応する。

- 対象リポジトリ: `hw-hub-mobile`
- 種別: エンドユーザー端末上で動作する iOS/Android アプリ（信頼できないクライアント）
- 最終更新: 2026-06-23
- ステータス: ドラフト（Phase 0）

---

## 1. システムコンテキスト

| 項目         | 内容                                                            |
| ------------ | --------------------------------------------------------------- |
| 実行環境     | エンドユーザーの iOS / Android 端末（信頼できないクライアント） |
| 主要技術     | Flutter 3 / Dart 3 / Riverpod / go_router / Dio + Retrofit      |
| バックエンド | `AppConfig.baseUrl`（dart-define で切替）への REST              |
| 認証         | JWT（アクセス＋リフレッシュ）/ Google Sign-In                   |
| トークン保管 | `flutter_secure_storage`（iOS Keychain / Android EncryptedSharedPreferences） |
| ディープリンク | go_router（email-verify / invite / password-reset）            |

---

## 2. 守るべき資産（Assets）

| 資産                            | 説明                                                       | 影響度 |
| ------------------------------- | ---------------------------------------------------------- | ------ |
| アクセス/リフレッシュトークン   | secure storage 保管。漏洩＝なりすまし                      | 高     |
| ユーザー個人情報                | プロフィール・世帯・問い合わせ等（API 経由で表示）         | 高     |
| ディープリンク内トークン        | email-verify / invite / password-reset の URL トークン     | 中     |
| 端末上のローカルデータ          | 選択世帯 ID・設定（SharedPreferences）                     | 低     |

---

## 3. エントリポイント / 攻撃面（Entry points）

| #   | エントリポイント                              | 信頼できない入力                       |
| --- | --------------------------------------------- | -------------------------------------- |
| E1  | ログイン/登録フォーム                         | email・password・displayName           |
| E2  | Google Sign-In                                | idToken                                |
| E3  | API レスポンス（Dio/Retrofit）                | バックエンドから受け取る JSON          |
| E4  | ディープリンク（go_router）                   | URL 内 token（verify/invite/reset）    |
| E5  | 通知ペイロード                                | i18n キー・リンク情報                  |
| E6  | 画像アップロード（image_picker）              | ファイル（5MB 制限あり）               |
| E7  | secure storage / SharedPreferences            | 端末上の保管データ                     |
| E8  | pub 依存パッケージ                            | サプライチェーン（`pubspec.lock`）     |

---

## 4. 信頼境界（Trust boundaries）

```
[端末/アプリ:信頼できない] ──TLS+JWT──> [Backend API:認可の砦] ──> [DB / S3]
        │
        ├─ secure storage（トークン: Keychain / EncryptedSharedPreferences）
        ├─ SharedPreferences（設定・選択世帯ID＝平文・非PII）
        └─ ディープリンク ──> token はサーバーで検証
```

**最重要原則: 端末は信頼できない。認可・入力検証の最終強制はバックエンドで行われる前提で評価する。**
アプリ側のガードや画面出し分けは UX 上の利便性にすぎない。

---

## 5. 想定する脅威（What can go wrong?）

| ID  | 脅威                                                                                           | 関連                          | 重大度 |
| --- | ---------------------------------------------------------------------------------------------- | ----------------------------- | ------ |
| T1  | **証明書ピンニング未実装による MITM**: root 化端末/プロキシ下での通信傍受                       | `dio_client.dart`             | 中     |
| T2  | **デバッグビルドの全文ログ**: `LogInterceptor(requestBody/responseBody)` で password/email 露出 | `dio_client.dart`（kDebugMode 限定）| 中     |
| T3  | **Google OAuth 設定のデフォルト空**: `GOOGLE_SERVER_CLIENT_ID` 未設定で OAuth 不成立（可用性）  | `app_config.dart`             | 低〜中 |
| T4  | **ディープリンクトークンの取り扱い**: token を UI に直渡し、URL 履歴/Referer 残留               | `app_router.dart`             | 低〜中 |
| T5  | **平文ローカル保存**: SharedPreferences に選択世帯 ID 等（非 PII だが）                         | `storage_keys.dart`           | 低     |
| T6  | **iOS Keychain 残留**: アンインストール後もトークンが残る（フラグで対処済み）                   | `auth_notifier.dart`          | 低     |
| T7  | **依存パッケージの既知脆弱性**: pub サプライチェーン                                            | `pubspec.lock`                | 中     |

---

## 6. 現状の対策（既存コントロール）

- **トークン保管**: `flutter_secure_storage`（暗号化）。メモリキャッシュせず毎回読み出し。
- **トークン付与/更新**: `AuthInterceptor` で `Authorization: Bearer` 自動付与、401 で自動リフレッシュ（並行制御・ログアウト再入防止あり）。
- **ログ**: `LogInterceptor` は `kDebugMode` 時のみ有効（本番ビルドでは無効）。
- **アップロード**: 画像 5MB 上限。
- **OAuth/秘密**: API キーのハードコード無し。`GOOGLE_SERVER_CLIENT_ID` / `baseUrl` は dart-define 供給（秘密値はコードに埋め込まない）。
- **iOS 初回起動**: `_clearOnFreshInstall()` で再インストール後の Keychain 残留に対処。

---

## 7. 信頼する入力（Trusted inputs）— スキャン時の過大評価を防ぐ

- **API レスポンス**: バックエンドが JWT 署名検証・認可（世帯所属）を強制する前提。
- **ディープリンク内トークン**: バックエンドが用途（verify/invite/reset）と有効期限を検証する前提。
- **通知ペイロードの i18n キー**: バックエンドがホワイトリストのキーのみ送る前提。
- **TLS / OS のサンドボックス・Keychain 実装**。

---

## 8. スコープ外（Out of scope）

- サーバー側の認証・認可・セッション管理・レート制限・SQLi → `hw-hub-backend`
- バッチ/AI 処理 → `hw-hub-batch`
- インフラ・証明書・App Links のドメイン検証基盤 → `hw-hub-infra`
- OS/端末自体のマルウェア感染・脱獄/root 化端末の完全防御（軽減はするが前提にしない）

> サーバー側で強制される認可等は「信頼する入力」として扱い、それを根拠にした指摘は重大度を上げない。

---

## 9. レビュー観点チェック（Did we do a good job?）

1. トークンが secure storage に保管され、平文（SharedPreferences/ログ）に出ていないか
2. デバッグログに password/email/token が出る経路が本番ビルドで確実に無効か
3. ディープリンクの token 処理が安全か（外部 URL への誘導・履歴残留）
4. ハードコードされた秘密（API キー等）がコード/アセットに無いか
5. 証明書ピンニングの要否（MITM 耐性）
6. 依存パッケージに既知の高/重大脆弱性がないか（Trivy/Phase 2）

---

## 10. 更新運用

- 認証・トークン保管・通信・ディープリンク・外部連携など**信頼境界に関わる変更時**に本書を更新する。
- スキャン結果のトリアージで前提が誤っていた場合、本書を正とせず修正する。
- Retro でセキュリティ指摘を棚卸しする際、本書の見直し要否を確認する。
