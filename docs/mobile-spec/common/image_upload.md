# 共通仕様: 画像アップロード（S3 Presigned URL）

## 1. 概要

画像アップロードは **S3 Presigned URL による直接アップロード方式** を採用している。
バックエンドはファイルデータを中継せず、一時的な署名付きURLを発行するのみ。
Flutterは `image_picker` で画像を取得し、そのURLを使って S3 へ直接 PUT する。

```
Flutter → バックエンド (Presigned URL 発行)
Flutter → S3          (ファイルを直接 PUT)
Flutter → バックエンド (メタデータ登録)
```

**バックエンド改修不要。** 既存のAPIをそのまま利用できる。

---

## 2. 対象機能

| 機能 | S3キー形式 | 参照画面 |
|---|---|---|
| 買い物アイテム添付 | `shopping-item/{householdId}/{itemId}/{uuid}.{ext}` | #14 #15 |
| ユーザーアイコン | `user-icon/{userId}/icon.{ext}` | #18 |

---

## 3. 追加パッケージ

| パッケージ | 用途 |
|---|---|
| `image_picker` | カメラ撮影 / フォトライブラリからの画像選択 |
| `http` または `dio` | S3へのPUT（dioのインターセプタは使わず直接PUT） |

---

## 4. 処理フロー

### 4.1 買い物アイテム添付

```
1. image_picker でカメラ/ライブラリから画像選択
2. POST /api/shopping-items/{itemId}/attachments/upload-url
   Body: { fileName, mimeType }
   → { uploadUrl, fileKey } を受け取る
3. S3へ直接PUT
   PUT {uploadUrl}
   Content-Type: {mimeType}
   Body: 画像バイナリ
4. POST /api/shopping-items/{itemId}/attachments
   Body: { fileKey, fileName, mimeType }
5. GET /api/shopping-items/{itemId}/attachments で一覧再取得
```

### 4.2 ユーザーアイコン

```
1. image_picker でカメラ/ライブラリから画像選択
2. POST /api/users/me/icon/upload-url
   Body: { fileName, mimeType }
   → { uploadUrl, fileKey } を受け取る
3. S3へ直接PUT
   PUT {uploadUrl}
   Content-Type: {mimeType}
   Body: 画像バイナリ
4. POST /api/users/me/icon
   Body: { fileKey }
5. GET /api/users/me でプロフィール再取得
```

---

## 5. API

| メソッド | エンドポイント | 用途 |
|---|---|---|
| POST | `/api/shopping-items/{itemId}/attachments/upload-url` | 添付ファイル用Presigned URL発行 |
| POST | `/api/shopping-items/{itemId}/attachments` | 添付ファイルメタデータ登録 |
| GET | `/api/shopping-items/{itemId}/attachments` | 添付ファイル一覧取得（Presigned GET URL含む） |
| POST | `/api/users/me/icon/upload-url` | アイコン用Presigned URL発行 |
| POST | `/api/users/me/icon` | アイコン更新 |

---

## 6. Flutter実装方針

### 6.1 image_picker

```dart
final ImagePicker picker = ImagePicker();

// カメラ撮影
final XFile? image = await picker.pickImage(
  source: ImageSource.camera,
  maxWidth: 1920,
  maxHeight: 1920,
  imageQuality: 85,
);

// フォトライブラリ
final XFile? image = await picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 1920,
  maxHeight: 1920,
  imageQuality: 85,
);
```

### 6.2 S3へのPUT

S3へのPUTはdioのインターセプタ（認証ヘッダ付与）を**使わない**。Presigned URLに認証情報が含まれているため、素のPUTで送信する。

```dart
// dioを使う場合はbaseOptionを使わず直接送信
final dio = Dio();
final bytes = await image.readAsBytes();
await dio.put(
  uploadUrl,
  data: Stream.fromIterable([bytes]),
  options: Options(
    headers: {
      'Content-Type': mimeType,
      'Content-Length': bytes.length,
    },
  ),
);
```

### 6.3 制限値

| 項目 | 制限 |
|---|---|
| ユーザーアイコン | 5MB以内、JPEG/PNG/GIF |
| 買い物アイテム添付 | 2MB推奨（S3側の制限に準ずる） |

### 6.4 パーミッション

iOS・Androidともにカメラ・フォトライブラリのパーミッション設定が必要。

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>プロフィール写真や買い物アイテムの画像を撮影するために使用します</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>プロフィール写真や買い物アイテムの画像を選択するために使用します</string>
```

---

## 7. エラーハンドリング

| エラー | 対応 |
|---|---|
| image_pickerキャンセル | 処理中断（エラー表示なし） |
| Presigned URL取得失敗 | スナックバーでエラー通知 |
| S3 PUTステータス200以外 | スナックバーでエラー通知。S3はエラー時にレスポンスボディを返さないためステータスコードのみで判定 |
| メタデータ登録失敗 | スナックバーでエラー通知 |

---

*v0.1 / 2026-04-28 時点*
