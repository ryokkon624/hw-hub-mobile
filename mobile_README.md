# Housework Hub（HwHub）Mobile

> ここは **モバイル（hw-hub-mobile）リポジトリ** の README です。

---

## 1. Mobile の役割

- iOS / Android 向けのネイティブアプリ（Flutter）
- メール認証・招待・パスワードリセットなどの認証フロー
- 世帯の家事・買い物リストの確認と操作
- バックエンド（hw-hub-backend）の REST API を Retrofit/Dio で呼び出す
- ディープリンク（メール認証・招待・パスワードリセット）に対応

---

## 2. 技術スタック

| 分類 | 内容 |
|---|---|
| 言語 | Dart 3.x |
| フレームワーク | Flutter 3.x (stable) |
| 状態管理 | flutter_riverpod 2.x（Notifier / AsyncNotifier） |
| ルーティング | go_router 14.x |
| ネットワーク | Dio 5.x + Retrofit 4.x（コード生成） |
| ストレージ | flutter_secure_storage（JWT）/ shared_preferences（設定） |
| i18n | flutter_localizations + gen-l10n（ja / en / es） |
| テスト | flutter_test + mockito（@GenerateMocks） |

---

## 3. ディレクトリ構成

```
lib/
├── main.dart                     # エントリポイント
├── app_router.dart               # GoRouter 定義（全ルート）
├── core/                         # 全機能共通の基盤
│   ├── auth/                     # 認証状態管理（AuthNotifier・TokenStorage）
│   ├── config/                   # 環境設定（AppConfig・ベースURL）
│   ├── di/                       # Provider 定義（DI配線）
│   ├── household/                # 世帯状態管理
│   ├── models/                   # 共有ドメインモデル
│   ├── network/                  # Dio クライアント・例外定義・インターセプター
│   ├── storage/                  # ストレージキー定数
│   ├── theme/                    # テーマ・カラー・スペーシング定数
│   └── ui/                       # 共通UIコンポーネント（SnackBar・Dialog）
├── features/                     # 機能モジュール（feature-first）
│   ├── auth/                     # 認証機能
│   │   ├── auth_providers.dart   # 認証関連 Provider
│   │   ├── data/                 # API クライアント・Repository・モデル
│   │   │   ├── auth_api.dart     # Retrofit @RestApi 定義
│   │   │   ├── auth_repository.dart  # interface + impl
│   │   │   └── models/           # レスポンスモデル（fromJson）
│   │   └── presentation/         # 各画面（Page・Notifier・State）
│   │       ├── login/
│   │       ├── signup/
│   │       ├── email_verify/
│   │       ├── email_verify_wait/
│   │       ├── invitation/
│   │       ├── password_forgot/
│   │       ├── password_reset/
│   │       ├── password_reset_sent/
│   │       └── auth_result/
│   └── shell/                    # ナビゲーションシェル（BottomNav・世帯切替）
└── l10n/                         # gen-l10n 生成ファイル（編集禁止）
```

```
test/
├── core/                         # core 層のユニットテスト
│   ├── auth/
│   ├── household/
│   └── network/
├── features/
│   └── auth/
│       ├── data/                 # Repository テスト
│       └── presentation/        # Notifier テスト
└── helpers/                      # テスト共通モック定義
```

---

## 4. アーキテクチャ方針

### 4.1 レイヤー構成

feature-first + 簡略 Clean Architecture を採用しています。
バックエンドと異なり **domain 層は省略**しており、Repository interface は `data/` に同居させています。
UseCase が薄いラッパーにしかならない規模であるため、Notifier が直接 Repository を呼びます。

```
presentation/ (Page・Notifier・State)
      ↓
data/         (Repository interface + impl・API・モデル)
      ↓
core/network/ (Dio・例外・インターセプター)
```

将来的に複数機能をまたぐビジネスロジックが必要になった場合は、`domain/usecase/` を切り出します。

### 4.2 状態管理（Riverpod）

| 種別 | 用途 |
|---|---|
| `NotifierProvider` | 同期的な画面状態（フォーム入力・ローディング） |
| `AsyncNotifierProvider` | 非同期の画面状態（API呼び出しを含む操作） |
| `FutureProvider.family` | 一度だけ実行する非同期処理（メール認証トークン検証など） |
| `AutoDispose` | 画面を離れたら破棄するプロバイダに付与 |

### 4.3 ナビゲーション（go_router）

- `app_router.dart` に全ルートを定義
- 認証状態（`authNotifierProvider`）を `redirect` で監視し、未認証→`/login` へリダイレクト
- ディープリンクパス（`/email-verify`・`/invite/:token`・`/password/reset`）は `_publicPrefixes` に含め、認証不要として扱う

### 4.4 画面ごとのファイル構成

各画面は以下の3ファイルで構成します。

```
login/
├── login_page.dart      # UI（ConsumerWidget / ConsumerStatefulWidget）
├── login_notifier.dart  # ビジネスロジック（Notifier）+ Provider 定義
└── login_state.dart     # 不変状態クラス（copyWith・getter）
```

---

## 5. ローカル開発

### 5.1 前提

- Flutter SDK 3.x stable
- Android Studio または VS Code（Flutter / Dart 拡張）
- Android Emulator または実機
- バックエンド（hw-hub-backend）が起動していること
- Mailhog（メール確認用）

### 5.2 起動

```bash
# 依存パッケージ取得
flutter pub get

# コード生成（Retrofit・Mockito）
dart run build_runner build --delete-conflicting-outputs

# アプリ起動（エミュレータ or 接続済み実機）
flutter run
```

> バックエンドの URL はデフォルト `http://10.0.2.2:8080`（Android エミュレータから見たホスト）。
> 変更する場合は `--dart-define=BASE_URL=http://...` を指定するか `core/config/app_config.dart` を参照。

---

## 6. 開発コマンド

### 6.1 テスト

```bash
flutter test
```

### 6.2 静的解析

```bash
flutter analyze
```

### 6.3 区分値（enum）の更新

区分値ファイル `lib/core/models/*.dart` は **hw-hub-database** の `generateEnums` タスクで自動生成されます。  
m_code を変更したときは以下の手順で更新してください。

```bash
# hw-hub-database で実行
./gradlew generateEnums

# 生成ファイルをコピー（PowerShell 例）
Copy-Item build\generated\mobile\*.dart ..\hw-hub-mobile\lib\core\models\ -Force
```

> コピー後、参照箇所を `flutter analyze` で確認してください。

---

### 6.4 その他コード生成

```bash
# Retrofit (.g.dart) および Mockito (.mocks.dart) の再生成
dart run build_runner build --delete-conflicting-outputs

# i18n ファイルの再生成（.arb を編集したあと）
flutter gen-l10n
```

> `.g.dart` / `.mocks.dart` / `l10n/app_localizations*.dart` は自動生成ファイルです。**直接編集しないこと。**

### 6.5 フォーマット

```bash
dart format .
```

---

## 7. カバレッジ

### 7.1 ローカルでのレポート生成（Windows）

```powershell
.\coverage.ps1
```

- 除外パターンは `lcov_exclude.txt` で管理（`coverage.ps1` と CI の両方が参照）
- 実行後 `coverage/html/index.html` がブラウザで開く

前提ツール:
```powershell
choco install lcov strawberryperl
```

### 7.2 GitHub Pages（CI）

- `main` へ push / 手動実行でレポートを GitHub Pages に公開（workflow: `coverage-mobile`）
- 公開URL: https://ryokkon624.github.io/hw-hub-mobile/

> **注意**: 新規リポジトリは GitHub Pages がデフォルト無効。初回は GitHub API で手動有効化が必要（Settings → Pages、または `POST /repos/{owner}/{repo}/pages` API）。

---

## 8. CI ワークフロー

| workflow | トリガー | 内容 |
|---|---|---|
| `coverage-mobile` | push main / 手動 | テスト実行・カバレッジ計測・GitHub Pages へ公開 |
| `format-check-mobile` | push main / PR | `dart format --set-exit-if-changed .` でフォーマット違反を検出 |

> `dart format .` をコミット前に実行しないと `format-check-mobile` で CI がブロックされる。

---

## 9. ディープリンク

### 9.1 スキーム

| 環境 | スキーム | 備考 |
|---|---|---|
| 本番 / STG | `https://hwhub.familyapp-hwhub.com/...` | App Links（Android）|
| 開発・テスト | `hwhub:///...` | カスタムスキーム |

### 9.2 対応パス

| パス | 用途 |
|---|---|
| `/email-verify?token=TOKEN` | メールアドレス認証 |
| `/invite/TOKEN` | 世帯招待 |
| `/password/reset?token=TOKEN` | パスワードリセット |

### 9.3 adb を使ったローカルテスト

メールリンクのトークンを Mailhog（`http://localhost:8025`）から取得し、以下を実行します。

```bash
# メール認証
adb shell am start -a android.intent.action.VIEW \
  -d "hwhub:///email-verify?token=TOKEN" com.hwhub.app

# 世帯招待
adb shell am start -a android.intent.action.VIEW \
  -d "hwhub:///invite/TOKEN" com.hwhub.app

# パスワードリセット
adb shell am start -a android.intent.action.VIEW \
  -d "hwhub:///password/reset?token=TOKEN" com.hwhub.app
```

> `hwhub:///`（スラッシュ3つ）が必要です。`hwhub://`（2つ）ではパスが go_router に届きません。

---

## 10. i18n（多言語対応）

### 10.1 対応言語

`ja`（日本語）/ `en`（英語）/ `es`（スペイン語）

### 10.2 翻訳文字列の追加手順

1. `lib/l10n/app_ja.arb` / `app_en.arb` にキーと文字列を追加
2. `flutter gen-l10n` を実行して Dart ファイルを再生成
3. 各 Page で `AppLocalizations.of(context).キー名` を使う

> ハードコードの日本語・英語文字列は追加しないこと。

---

## 11. よくあるトラブルシュート

| 症状 | 確認ポイント |
|---|---|
| ビルドエラー `*.g.dart not found` | `dart run build_runner build` を実行 |
| i18n キーが見つからない | `flutter gen-l10n` を実行 |
| API が `Connection refused` | バックエンドが起動しているか、ベースURLが `10.0.2.2:8080` か確認 |
| ディープリンクが開かない | `hwhub:///`（3スラッシュ）になっているか確認。アプリを再インストールして manifest を反映させる |
| `perl` が認識されない | `choco install strawberryperl` 後に PowerShell を再起動 |
| `genhtml` が認識されない | `C:\ProgramData\chocolatey\lib\lcov\tools\bin` を PATH に追加 |
