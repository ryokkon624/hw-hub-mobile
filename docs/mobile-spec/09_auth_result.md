# #9 認証結果 モバイル仕様

## 1. 概要

メール認証・パスワードリセットなど、非同期の認証アクションの結果を表示する共通結果画面。

成功・期限切れ・無効の3パターンをカバーし、結果に応じた案内メッセージとアクションボタンを表示する。

Web版との差異はなし。

---

## 2. 画面構成

### 2.1 成功パターン

```
┌─────────────────────────────────────┐
│                                      │
│                                      │
│  ✓ メール認証が完了しました          │
│  （またはパスワードを変更しました）  │
│                                      │
│  ログインしてアプリをご利用ください。│
│                                      │
│  [  ログイン画面へ  ]                │
│                                      │
└─────────────────────────────────────┘
```

### 2.2 期限切れパターン

```
┌─────────────────────────────────────┐
│                                      │
│                                      │
│  ✕ リンクの有効期限が切れています    │
│                                      │
│  リンクの有効期限が切れています。    │
│  再度お手続きください。              │
│                                      │
│  [  再申請する  ]                    │
│  （パスワードリセットの場合）        │
│  または                              │
│  [  サインアップへ  ]                │
│  （メール認証の場合）                │
│                                      │
└─────────────────────────────────────┘
```

### 2.3 無効パターン

```
┌─────────────────────────────────────┐
│                                      │
│                                      │
│  ✕ 無効なリンクです                  │
│                                      │
│  リンクが無効です。                  │
│  お手続きをやり直してください。      │
│                                      │
│  [  再申請する  ]                    │
│  （またはサインアップへ）            │
│                                      │
└─────────────────────────────────────┘
```

---

## 3. 機能仕様

### 3.1 パラメータ

go_router のクエリパラメータで動作を制御する:

| パラメータ | 値 | 意味 |
|---|---|---|
| `type` | `emailVerify` | メール認証の結果 |
| `type` | `passwordReset` | パスワードリセットの結果 |
| `status` | `success` | 成功 |
| `status` | `expired` | 有効期限切れ |
| `status` | `invalid` | 無効なトークン |

go_router パス: `/auth/result?type=emailVerify&status=success`

### 3.2 メッセージのi18nキー対応

| type / status | タイトルキー | メッセージキー |
|---|---|---|
| emailVerify / success | `authResult.emailVerify.success.title` | `authResult.emailVerify.success.message` |
| emailVerify / expired | `authResult.emailVerify.expired.title` | `authResult.emailVerify.expired.message` |
| emailVerify / invalid | `authResult.emailVerify.invalid.title` | `authResult.emailVerify.invalid.message` |
| passwordReset / success | `authResult.passwordReset.success.title` | `authResult.passwordReset.success.message` |
| passwordReset / expired | `authResult.passwordReset.expired.title` | `authResult.passwordReset.expired.message` |
| passwordReset / invalid | `authResult.passwordReset.invalid.title` | `authResult.passwordReset.invalid.message` |
| （該当なし） | `authResult.common.title` | `authResult.common.message` |

### 3.3 アクションボタンの制御

| type | status | ボタン | 遷移先 | 通知 |
|---|---|---|---|---|
| emailVerify | success | ログイン画面へ | ログイン (#1) | `notice=emailVerified` をクエリに付与 |
| emailVerify | expired | サインアップへ | サインアップ (#2) | なし |
| emailVerify | invalid | サインアップへ | サインアップ (#2) | なし |
| passwordReset | success | ログイン画面へ | ログイン (#1) | `notice=passwordResetSuccess` をクエリに付与 |
| passwordReset | expired | 再申請する | パスワード忘れ (#6) | なし |
| passwordReset | invalid | 再申請する | パスワード忘れ (#6) | なし |

### 3.4 ログイン画面への `notice` クエリパラメータ

ログイン画面 (#1) では受け取った `notice` の値に応じてスナックバーを表示する:

| `notice` | スナックバー内容 |
|---|---|
| `emailVerified` | 「メール認証が完了しました。ログインしてください」 |
| `passwordResetSuccess` | 「パスワードを変更しました。ログインしてください」 |

---

## 4. APIエンドポイント

なし（この画面はAPI呼び出しを行わない。メール認証・パスワードリセットの各処理は呼び出し元の画面が担う）。

---

## 5. 画面遷移

```
[認証結果画面]
  │
  ├─ emailVerify / success ──────────→ ログイン (#1) notice=emailVerified
  ├─ emailVerify / expired|invalid ──→ サインアップ (#2)
  ├─ passwordReset / success ────────→ ログイン (#1) notice=passwordResetSuccess
  └─ passwordReset / expired|invalid→ パスワード忘れ (#6)
```

---

*v0.1 / 2026-04-27 時点*
