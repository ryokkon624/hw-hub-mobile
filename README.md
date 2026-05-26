# Housework Hub (HwHub)

![Java](https://img.shields.io/badge/Java-21-orange)
![SpringBoot](https://img.shields.io/badge/SpringBoot-4.x-brightgreen)
![Vue](https://img.shields.io/badge/Vue-3-42b883)
![Flutter](https://img.shields.io/badge/Flutter-3.x-54c5f8)
![Terraform](https://img.shields.io/badge/Terraform-managed-blue)
---

## Overview

Housework Hub（HwHub）は、家庭内の家事・買い物・メンバー管理を協調的に行うためのアプリケーションです。  
複数のおうち（Household）をサポートし、家事タスクのテンプレート化、定期実行、担当者割当、履歴管理などを提供します。  
ユーザーからの問い合わせには Claude API を活用した AI 自動返信機能を備えており、解決できない場合はサポートスタッフへのエスカレーションも可能です。

本リポジトリ群は以下の構成で成り立っています。

- **hw-hub-backend** : メインAPI（Spring Boot / MyBatis / MySQL）
- **hw-hub-batch** : 定期バッチ処理（Spring Batch / ECS Fargate）
- **hw-hub-frontend** : フロントエンド（Vue 3 + Vite + TypeScript）
- **hw-hub-mobile** : モバイルアプリ（Flutter / Dart / Riverpod）
- **hw-hub-database** : DBスキーマ・Flywayマイグレーション管理
- **hw-hub-infra** : AWSインフラ（Terraform）
- **hw-hub-knowledge** : AIサポートナレッジ（S3同期）

---

## Architecture

- Backend / Batch は AWS ECS Fargate 上で稼働
- DB は Amazon RDS (MySQL)
- ファイル保存は S3
- 認証は JWT
- フロントエンドは S3 + CloudFront によりホスティング
- モバイルは iOS / Android ネイティブアプリ（Flutter）
- バッチは EventBridge Scheduler により起動
- インフラは Terraform により管理
- STG 環境は Ephemeral 構成（使用時のみ `terraform apply`、不使用時は `terraform destroy`）

---

## Tech stack

### Backend
- Java 21
- Spring Boot 4.0.x
- MyBatis + MyBatis Generator
- Flyway
- MySQL

### Frontend
- Vue 3 + Composition API
- TypeScript
- Pinia
- Tailwind CSS
- vue-i18n

### Mobile
- Flutter 3.x (stable) / Dart 3.x
- flutter_riverpod 2.x（Notifier / AsyncNotifier）
- go_router 14.x
- Dio 5.x + Retrofit 4.x（コード生成）
- flutter_secure_storage / shared_preferences
- flutter_localizations + gen-l10n（ja / en / es）
- mockito（テスト）

### Infrastructure
- AWS ECS Fargate
- Application Load Balancer（Ephemeral）
- Amazon RDS (MySQL)
- Amazon S3
- CloudFront
- EventBridge Scheduler
- CloudWatch / SNS
- Route 53
- **Terraform**

---

## Repository Structure

| Repository | Role |
|------------------------------------------------------------------|-----------------------------|
| [hw-hub-backend](https://github.com/ryokkon624/hw-hub-backend)   | REST API / authentication / business logic |
| [hw-hub-batch](https://github.com/ryokkon624/hw-hub-batch)       | scheduled batch processing |
| [hw-hub-frontend](https://github.com/ryokkon624/hw-hub-frontend) | Web UI |
| [hw-hub-mobile](https://github.com/ryokkon624/hw-hub-mobile)     | iOS / Android mobile app |
| [hw-hub-database](https://github.com/ryokkon624/hw-hub-database) | Flyway database schema |
| [hw-hub-infra](https://github.com/ryokkon624/hw-hub-infra) | Terraform infrastructure |
| [hw-hub-knowledge](https://github.com/ryokkon624/hw-hub-knowledge) | AI support knowledge base (S3 sync) |

---

## hw-hub-mobile

このリポジトリは iOS / Android 向けのモバイルアプリです。

### 役割

- iOS / Android 向けのネイティブアプリ（Flutter）
- メール認証・招待・パスワードリセットなどの認証フロー
- 世帯の家事・買い物リストの確認と操作
- バックエンド（hw-hub-backend）の REST API を Retrofit/Dio で呼び出す
- ディープリンク（メール認証・招待・パスワードリセット）に対応

### セットアップ

**前提**

- Flutter SDK 3.x stable
- Android Studio または VS Code（Flutter / Dart 拡張）
- Android Emulator または実機
- バックエンド（hw-hub-backend）が起動していること

**手順**

```bash
# 依存パッケージ取得
flutter pub get

# コード生成（Retrofit .g.dart・Mockito .mocks.dart）
dart run build_runner build --delete-conflicting-outputs

# i18n Dart ファイル生成（.arb を編集したあと）
flutter gen-l10n

# アプリ起動（接続済みエミュレータ or 実機）
flutter run
```

> バックエンドの URL はデフォルト `http://10.0.2.2:8080`（Android エミュレータから見たホスト）。  
> 変更する場合は `--dart-define=BASE_URL=http://...` を指定するか `lib/core/config/app_config.dart` を参照。

**コード生成ファイル（編集禁止）**

- `lib/**/*.g.dart` — Retrofit / json_serializable 生成
- `test/**/*.mocks.dart` — Mockito 生成
- `lib/l10n/app_localizations*.dart` — gen-l10n 生成

---

## Development

各リポジトリにそれぞれの詳細を記載した README ファイルがあります。

- [backend_README.md](https://github.com/ryokkon624/hw-hub-backend/blob/main/backend_README.md)
- [batch_README.md](https://github.com/ryokkon624/hw-hub-batch/blob/main/batch_README.md)
- [frontend_README.md](https://github.com/ryokkon624/hw-hub-frontend/blob/main/frontend_README.md)
- [mobile_README.md](https://github.com/ryokkon624/hw-hub-mobile/blob/main/mobile_README.md)
- [database_README.md](https://github.com/ryokkon624/hw-hub-database/blob/main/database_README.md)
- [infra_README.md](https://github.com/ryokkon624/hw-hub-infra/blob/main/infra_README.md)

---

## Coverage Report

- Backend: [GitHub Pages](https://ryokkon624.github.io/hw-hub-backend/)
- Batch: [GitHub Pages](https://ryokkon624.github.io/hw-hub-batch/)
- Frontend: [GitHub Pages](https://ryokkon624.github.io/hw-hub-frontend/)
- Mobile: [GitHub Pages](https://ryokkon624.github.io/hw-hub-mobile/)

---

## CI / CD 概要

GitHub Actions により CI/CD を構築しています。

| workflow | トリガー | 内容 |
|---|---|---|
| `coverage-mobile` | push main / 手動 | テスト実行・カバレッジ計測・GitHub Pages へ公開 |
| `format-check-mobile` | push main / PR | `dart format --set-exit-if-changed .` でフォーマット違反を検出 |

---

## Project Status

- architecture established
- CI/CD pipeline implemented
- AI-powered inquiry support implemented (Claude API)
- role-based admin panel implemented
- high test coverage achieved
- infrastructure managed via Terraform
- STG environment fully ephemeral (ALB / ECS / Route53 on demand)
- mobile app implemented (Flutter / iOS / Android)
