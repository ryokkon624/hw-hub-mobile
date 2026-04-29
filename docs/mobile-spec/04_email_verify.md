# #4 メール認証 モバイル仕様

## 1. 概要

サインアップ後に送付される認証メール内のリンクをタップすると、ディープリンク経由でアプリが起動し、トークンを自動検証する処理画面。

ユーザーの操作は不要で、画面表示中に検証を実行し、結果に応じて認証結果画面 (#9) へ自動遷移する。

---

## 2. 画面構成

ユーザーが操作する画面ではなく、処理中の一時的な表示のみ行う。

```
┌─────────────────────────────────────┐
│                                      │
│                                      │
│         メール認証中...              │
│         [スピナー]                   │
│                                      │
│                                      │
└─────────────────────────────────────┘
```

---

## 3. 機能仕様

### 3.1 ディープリンクによるトークン受け取り

| 項目 | 内容 |
|---|---|
| URLスキーム | `hwhub://email-verify?token=<TOKEN>` |
| go_router パス | `/email-verify` |
| パラメータ | `token`（クエリパラメータ） |

メール内リンク例（バックエンドが送信するリンクのモバイル版）:
```
hwhub://email-verify?token=abc123xyz
```

### 3.2 処理フロー

```
1. go_router が hwhub://email-verify?token=xxx を受け取る
2. token を取得してAPIを呼び出す
3. 成功 → 認証結果画面へ (type=emailVerify, status=success)
4. 失敗（期限切れ）→ 認証結果画面へ (type=emailVerify, status=expired)
5. 失敗（無効・その他）→ 認証結果画面へ (type=emailVerify, status=invalid)
6. token が空 → 認証結果画面へ (type=emailVerify, status=invalid)
```

すべての結果は認証結果画面 (#9) に集約し、この画面は処理後即座に遷移する。

### 3.3 go_router 設定

```dart
GoRoute(
  path: '/email-verify',
  builder: (context, state) {
    final token = state.uri.queryParameters['token'] ?? '';
    return EmailVerifyPage(token: token);
  },
),
```

---

## 4. APIエンドポイント

| メソッド | エンドポイント | 用途 |
|---|---|---|
| POST | `/api/auth/email-verification/verify` | メールアドレス認証 |

### POST /api/auth/email-verification/verify

```json
// Request
{ "token": "abc123xyz" }

// Response 204 No Content

// エラー: 400 { "errorCode": "EMAIL_VERIFY_EXPIRED" }  → expired 扱い
// エラー: 400 { "errorCode": "EMAIL_VERIFY_INVALID" }  → invalid 扱い
```

---

## 5. 画面遷移

```
[メール認証画面] ※ディープリンクで自動起動
  │
  ├─ 検証成功 ──────────→ 認証結果 (#9) type=emailVerify, status=success
  ├─ 期限切れ ──────────→ 認証結果 (#9) type=emailVerify, status=expired
  └─ 無効トークン/空 ──→ 認証結果 (#9) type=emailVerify, status=invalid
```

---

*v0.1 / 2026-04-27 時点*
