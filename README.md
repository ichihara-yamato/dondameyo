# ドンドンッダメよ (dondondameyo)

このリポジトリは Flutter ベースのモバイルアプリケーションのプロジェクトです。

## 概要

- 表示名: ドンドンッダメよ
- パッケージ名 / bundle identifier: com.example.dondondameyo（変更していません）

本リポジトリは Flutter の標準テンプレートを元に作成されています。

## 最近の変更

- アプリ表示名を `ドンドンッダメよ` に変更しました。
  - Android: `android/app/src/main/AndroidManifest.xml` の `android:label` を更新
  - iOS: `ios/Runner/Info.plist` の `CFBundleDisplayName` / `CFBundleName` を更新
- ルートに配置した `icon.png` を使い、ImageMagick によりアプリ用アイコンを生成して配置しました。
  - Android: `android/app/src/main/res/mipmap-*/ic_launcher.png` を生成
  - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/` に Contents.json に合わせた画像を生成
  - 既存のアイコンは自動的に `.bak` バックアップが作成されています。

## 要件

- Flutter SDK（プロジェクトルートの `pubspec.yaml` に依存）
- macOS (iOS のビルドを行う場合)
- ImageMagick（アイコン生成に使用。Homebrew で `brew install imagemagick`）

## ビルド / 実行方法

### 共通
1. Flutter のセットアップを行う（SDK インストール、Xcode/Android SDK 設定など）
2. 依存取得

```bash
flutter pub get
```

### Android

```bash
flutter build apk
# または
flutter run -d <android_device_id>
```

Android のアプリアイコンは `android/app/src/main/res/mipmap-*` に配置済みです。

### iOS

Xcode でワークスペースを開くか、flutter コマンドでビルドします。

```bash
open ios/Runner.xcworkspace
# もしくは
flutter build ios
flutter run -d <ios_device_id>
```

iOS の App Icon は `ios/Runner/Assets.xcassets/AppIcon.appiconset/` に配置済みです。

## アイコンのロールバック方法

生成前のアイコンは各ファイルに対して `.bak` 拡張子で保存されています。元に戻すには:

```bash
# 例: mdpi を戻す
mv android/app/src/main/res/mipmap-mdpi/ic_launcher.png.bak android/app/src/main/res/mipmap-mdpi/ic_launcher.png

# iOS の例
mv ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png.bak ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
```

表示名を元に戻す場合は、以下のファイルで元の値に書き戻してください（バックアップがある場合はそれを利用）。

- `android/app/src/main/AndroidManifest.xml` (android:label)
- `ios/Runner/Info.plist` (CFBundleDisplayName / CFBundleName)

## よくある問題と対処

- アイコンが Xcode で反映されない場合: Xcode の Clean（Shift+Cmd+K）を行い、DerivedData を削除して再ビルドしてください。
- Android で古いアイコンが表示される場合: アンインストールして再インストール、またはキャッシュクリアを行ってください。
- ImageMagick が無い場合: macOS の場合 `brew install imagemagick` で導入してください。

## 今後の改善案

- `flutter_launcher_icons` パッケージを導入してアイコン生成を一元化する。
- Android Adaptive Icon（foreground/background）対応に切り替える。

---

必要であれば、README にスクリーンショットやストア向けの説明文（日本語/英語）を追加します。
