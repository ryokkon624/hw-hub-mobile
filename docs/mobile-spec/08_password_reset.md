# #8 パスワード再設定 モバイル仕様

## 1. 概要

パスワードリセットメール内のリンクをタップすると、ディープリンク経由でアプリが起動し、新しいパスワードを入力して確定する画面。

URLに含まれるトークンを自動取得し、トークンがない場合や無効な場合は認証結果画面 (#9) へリダイレクトする。

---

## 2. 画面構成

### 2.1 通常（トークンあり）

```
┌─────────────────────────────────────┐
│  ← （戻る）                         │
├─────────────────────────────────────┤
│                                      │
│  新しいパスワードを設定              │
│                                      │
│  新しいパスワードを入力してください。│
│                                      │
│  新しいパスワード                    │
│  [                              ]    │
│                                      │
│  パスワード（確認）                  │
│  [                              ]    │
│  ※パスワードが一致しません（任意）  │
│                                      │
│  [エラーメッセージ（任意）]           │
│                                      │
│  [  パスワードを変更する  ]          │
│                                      │
│  ─────────────────────────────────  │
│  再申請 · ログイン画面へ戻る         │
│                                      │
└─────────────────────────────────────┘
```

### 2.2 トークンなし

- 画面表示と同時に認証結果画面 (#9) へ自動リダイレクト（`status=invalid`）

---

## 3. 機能仕様

### 3.1 ディープリンクによるトークン受け取り

| 項目 | 内容 |
|---|---|
| URLスキーム | `hwhub://password/reset?token=<TOKEN>` |
| go_router パス | `/password/reset` |
| パラメータ | `token`（クエリパラメータ） |

メール内リンク例:
```
hwhub://password/reset?token=abc123xyz
```

### 3.2 go_router 設定

```dart
GoRoute(
  path: '/password/reset',
  builder: (context, state) {
    final token = state.uri.queryParameters['token'] ?? '';
    return PasswordResetPage(token: token);
  },
),
```

### 3.3 フォームバリデーション

| フィールド | ルール | ボタン非活性条件 |
|---|---|---|
| 新しいパスワード | 必須・8文字以上 | 空またはtoken空 |
| パスワード確認 | 新しいパスワードと一致 | 不一致またはtoken空 |

- パスワード不一致時は確認フィールド下部にインラインエラーを即時表示
- トークンが空の場合はフォーム全体を非活性にして認証結果画面へ自動遷移

### 3.4 送信処理

- 送信中はボタンをスピナー表示に切り替え、再タップ不可
- 成功（204）→ 認証結果画面へ (`type=passwordReset, status=success`)
- 期限切れ → 認証結果画面へ (`type=passwordReset, status=expired`)
- その他エラー → 認証結果画面へ (`type=passwordReset, status=invalid`)

---

## 4. APIエンドポイント

| メソッド | エンドポイント | 用途 |
|---|---|---|
| POST | `/api/auth/password-reset/confirm` | パスワード再設定の確定 |

### POST /api/auth/password-reset/confirm

```json
// Request
{ "token": "abc123xyz", "newPassword": "newpassword123" }

// Response 204 No Content

// エラー: 400 { "errorCode": "PASSWORD_RESET_EXPIRED" }  → expired 扱い
// エラー: 400 { "errorCode": "PASSWORD_RESET_INVALID" }  → invalid 扱い
```

---

## 5. 画面遷移

```
[パスワード再設定画面] ※ディープリンクで自動起動
  │
  ├─ 変更成功 ──────────→ 認証結果 (#9) type=passwordReset, status=success
  ├─ 期限切れ ──────────→ 認証結果 (#9) type=passwordReset, status=expired
  ├─ 無効トークン/空 ──→ 認証結果 (#9) type=passwordReset, status=invalid
  ├─ 再申請 ────────────→ パスワード忘れ (#6)
  └─ ← 戻る / ログインへ→ ログイン (#1)
```

---

*v0.1 / 2026-04-27 時点*
