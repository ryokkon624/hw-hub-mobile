# 共通仕様: ディープリンク

## 1. 概要

メール認証・招待・パスワードリセットなど、メール内のリンクからアプリを起動するための仕組み。

---

## 2. 方式選定

### Universal Links（iOS） / App Links（Android）を採用

2つの方式があるが、**Universal Links / App Links**を採用する。

| 比較項目 | Universal Links / App Links | カスタムURLスキーム（`hwhub://`） |
|---|---|---|
| アプリ未インストール時 | ブラウザでWeb版が開く ✅ | 何も起きない ❌ |
| メール本文のURL変更 | 不要（既存のhttps://URLのまま） ✅ | 必要 ❌ |
| WebとモバイルのURL共存 | 可能 ✅ | 不可 ❌ |
| インフラ設定 | 必要（設定ファイルの配置） ⚠️ | 不要 |

**採用理由:**
- メール本文のURLを環境別（Web用/モバイル用）に分ける必要がない
- アプリ未インストールのユーザーはブラウザのWeb版で認証できる
- WebとFlutterのユーザーが混在しても同じURLで対応できる

---

## 3. 対象URL一覧

アプリで開く対象のURLパスは以下の3種類。

| 機能 | URLパス | 画面 | パラメータ |
|---|---|---|---|
| メール認証 | `/email-verify` | #4 メール認証 | `?token=<TOKEN>` |
| 招待受け取り | `/invite/:token` | #5 招待受け取り | パスパラメータ |
| パスワード再設定 | `/password/reset` | #8 パスワード再設定 | `?token=<TOKEN>` |

**URLの例:**
```
https://hwhub.familyapp-hwhub.com/email-verify?token=abc123
https://hwhub.familyapp-hwhub.com/invite/abc123
https://hwhub.familyapp-hwhub.com/password/reset?token=abc123
```

---

## 4. インフラ設定（要対応）

### 4.1 iOS: apple-app-site-association（AASA）

Webサーバーの以下のパスに設定ファイルを配置する必要がある。

```
https://hwhub.familyapp-hwhub.com/.well-known/apple-app-site-association
```

**設定ファイルの内容（例）:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "<TEAM_ID>.com.hwhub.app",
        "paths": [
          "/email-verify*",
          "/invite/*",
          "/password/reset*"
        ]
      }
    ]
  }
}
```

### 4.2 Android: assetlinks.json

Webサーバーの以下のパスに設定ファイルを配置する必要がある。

```
https://hwhub.familyapp-hwhub.com/.well-known/assetlinks.json
```

**設定ファイルの内容（例）:**
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.hwhub.app",
      "sha256_cert_fingerprints": [
        "<APK署名のSHA256フィンガープリント>"
      ]
    }
  }
]
```

### 4.3 配置方法

現在のインフラ構成（Cloudflare + ALB + ECS）に合わせて、以下のいずれかで配置する。

- **案A**: Spring BootにエンドポイントとしてAASA / assetlinks.jsonを返すコントローラを追加
- **案B**: CloudFrontまたはS3の静的ファイルとして配置

> ⚠️ **バックエンド改修一覧に追加:** AASA / assetlinks.jsonの配置対応が必要。案Aが既存インフラへの影響が最小限。

---

## 5. Flutter側の設定

### 5.1 AndroidManifest.xml

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data
    android:scheme="https"
    android:host="hwhub.familyapp-hwhub.com"
    android:pathPrefix="/email-verify" />
  <data
    android:scheme="https"
    android:host="hwhub.familyapp-hwhub.com"
    android:pathPrefix="/invite" />
  <data
    android:scheme="https"
    android:host="hwhub.familyapp-hwhub.com"
    android:pathPrefix="/password/reset" />
</intent-filter>
```

### 5.2 ios/Runner/Runner.entitlements

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:hwhub.familyapp-hwhub.com</string>
</array>
```

### 5.3 go_routerの設定

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/email-verify',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return EmailVerifyPage(token: token);
      },
    ),
    GoRoute(
      path: '/invite/:token',
      builder: (context, state) {
        final token = state.pathParameters['token'] ?? '';
        return InvitationPage(token: token);
      },
    ),
    GoRoute(
      path: '/password/reset',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return PasswordResetPage(token: token);
      },
    ),
  ],
);
```

---

## 6. バックエンドへの影響

**メール本文のURLは変更不要。**

Universal Links / App Links方式では、メール本文に記載するURLは既存のhttps://URLのまま使用できる。アプリがインストールされていればOSがアプリに誘導し、インストールされていなければブラウザでWeb版が開く。

ただし以下の対応が必要：

| 対応内容 | 担当 | タイミング |
|---|---|---|
| AASA / assetlinks.jsonの配置 | バックエンド or インフラ | Phase 2（共通基盤）|
| （参考）メール本文のURLがhttps://であることの確認 | バックエンド確認のみ | Phase 2 |

---

## 7. 動作確認方法

### iOSシミュレーター

```bash
xcrun simctl openurl booted \
  "https://hwhub.familyapp-hwhub.com/email-verify?token=testtoken"
```

### Android エミュレーター

```bash
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "https://hwhub.familyapp-hwhub.com/email-verify?token=testtoken" \
  com.hwhub.app
```

---

*v0.1 / 2026-04-27 時点*
