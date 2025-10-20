# Blackmagic Camera パッチガイド

このリポジトリは、**Blackmagic Camera** 用のカスタムパッチを含む ReVanced ビルドシステムです。

## 🎯 対象デバイス

### OnePlus 9 Pro
- **問題**: モノクロカメラ (ID 4) がクラッシュを引き起こす
- **パッチ**: カメラ ID 4 をフィルタリング
- **パッケージ名**: `com.google.android.GoogleCameraEng.blackmagic.op9pro`

### OnePlus 9
- **問題**: モノクロカメラ (ID 3) がクラッシュを引き起こす
- **パッチ**: カメラ ID 3 をフィルタリング
- **パッケージ名**: `com.google.android.GoogleCameraEng.blackmagic.op9`

## 🚀 ビルド方法

### 前提条件

以下のツールが必要です:

```bash
# Ubuntu/Debian
sudo apt install openjdk-17-jre zip jq unzip aapt zipalign

# Arch Linux
sudo pacman -S jdk17-openjdk zip jq unzip android-tools

# macOS
brew install openjdk@17 zip jq android-sdk
```

### ビルド実行

```bash
# リポジトリをクローン
git clone https://github.com/tqmane/Revanced
cd Revanced

# ビルド実行
./build.sh

# 完了後、build/ ディレクトリにAPKとMagiskモジュールが生成されます
ls -lh build/
```

## 📝 config.toml の設定

デフォルトでは、OnePlus 9 と 9 Pro の両方の設定が含まれています。

### OnePlus 9 Pro のみビルドする場合

```toml
[blackmagic-oneplus9pro]
enabled = true
# ... (その他の設定)

[blackmagic-oneplus9]
enabled = false  # ← 無効化
# ...
```

### カスタムパッケージ名を使用する場合

```toml
[blackmagic-oneplus9pro.options]
packageName = "your.custom.package.name"
cameraIdsToFilter = "4"
```

### 別のバージョンの Blackmagic Camera を使用する場合

APKMirror でバージョンを選択し、URL を更新:

```toml
[blackmagic-oneplus9pro]
apkmirror-dlurl = "https://www.apkmirror.com/apk/blackmagic-design-inc/blackmagic-camera/blackmagic-camera-X-Y-Z-release/"
```

## 🔧 .apkm ファイルの自動変換

このリポジトリには `antisplit-apkm.sh` スクリプトが含まれており、APKMirror からダウンロードした `.apkm` ファイルを自動的に `.apk` に変換します。

### 仕組み

1. **APKMirror からダウンロード**: config.toml の `apkmirror-dlurl` に基づいて `.apkm` をダウンロード
2. **自動変換**: `build.sh` が `.apkm` を検出すると自動的に `antisplit-apkm.sh` を実行
3. **split APK をマージ**: base.apk + すべての split APK (ネイティブライブラリ、リソース等) をマージ
4. **パッチ適用**: 変換された `.apk` にパッチを適用

### 手動で .apkm を変換する場合

```bash
# .apkmファイルを配置
cp ~/Downloads/blackmagic_camera.apkm ./

# 変換実行
./antisplit-apkm.sh blackmagic_camera.apkm Blackmagic_Camera.apk

# 生成された.apkを確認
ls -lh Blackmagic_Camera.apk
```

## 📦 ビルド成果物

ビルドが成功すると、`build/` ディレクトリに以下のファイルが生成されます:

```
build/
├── blackmagic-camera-op9pro-v1.0.0.apk        # OnePlus 9 Pro用APK
├── blackmagic-camera-op9pro-magisk-v1.0.0.zip # OnePlus 9 Pro用Magiskモジュール
├── blackmagic-camera-op9-v1.0.0.apk           # OnePlus 9用APK
└── blackmagic-camera-op9-magisk-v1.0.0.zip    # OnePlus 9用Magiskモジュール
```

## 🔨 インストール方法

### 方法1: Magisk モジュール (推奨)

```bash
# .zipファイルを端末に転送
adb push build/blackmagic-camera-op9pro-magisk-v1.0.0.zip /sdcard/Download/

# Magisk アプリで:
# 1. Modules タブを開く
# 2. "Install from storage" をタップ
# 3. .zipファイルを選択
# 4. 再起動
```

### 方法2: 直接インストール (非root)

```bash
# APKを端末に転送
adb push build/blackmagic-camera-op9pro-v1.0.0.apk /sdcard/Download/

# インストール
adb install build/blackmagic-camera-op9pro-v1.0.0.apk

# または端末上でファイルマネージャーからインストール
```

## 🐛 トラブルシューティング

### エラー: `aapt: command not found`

**原因**: Android SDK Build Tools がインストールされていない

**解決策**:
```bash
# Ubuntu/Debian
sudo apt install aapt zipalign

# macOS
brew install android-sdk
```

### エラー: パッチが見つからない

**原因**: Blackmagic Patches のリリースが存在しない

**解決策**:
1. https://github.com/tqmane/blackmagic-revanced-patches/releases を確認
2. リリースが存在しない場合、パッチをビルド:
   ```bash
   cd ../revanced-patches
   ./gradlew build
   ```

### .apkm ファイルの変換に失敗

**原因**: 依存関係が不足している

**解決策**:
```bash
# すべての依存関係をインストール
sudo apt install unzip aapt zipalign

# スクリプトを実行
./antisplit-apkm.sh input.apkm output.apk
```

### APK のインストールに失敗

**原因1**: 署名の問題

**解決策**: ビルドスクリプトが自動的に署名するため、通常は問題ありません

**原因2**: 既存のアプリとの競合

**解決策**: 古いバージョンをアンインストールしてから再インストール

## 🔄 更新方法

### パッチの更新

```bash
cd Revanced
git pull

# config.toml で patches-version を更新
# patches-version = "1.1.0"  # 新しいバージョン

./build.sh
```

### Blackmagic Camera アプリの更新

```bash
# config.toml で apkmirror-dlurl を新しいバージョンに更新
# または version = "auto" で自動的に最新版を取得

./build.sh
```

## 📚 関連ドキュメント

- [CONFIG.md](./CONFIG.md) - config.toml の詳細設定
- [README.md](./README.md) - メインドキュメント
- [antisplit-apkm.sh](./antisplit-apkm.sh) - APKMirror 変換スクリプト
- [Blackmagic Patches](https://github.com/tqmane/blackmagic-revanced-patches) - パッチのソースコード

## 💡 カスタマイズ

### 他のデバイス用に調整

他の OnePlus デバイスや、異なるモノクロカメラ ID を持つデバイスの場合:

```toml
[blackmagic-custom]
enabled = true
app-name = "Blackmagic Camera (Custom)"
apkmirror-dlurl = "..."
patches-source = "tqmane/blackmagic-revanced-patches"
patches-version = "1.0.0"
cli-version = "4.6.0"
included-patches = "'Change package name' 'Filter camera IDs'"

[blackmagic-custom.options]
packageName = "com.custom.package.name"
cameraIdsToFilter = "2,3"  # 複数のカメラIDをフィルタ
```

### パッケージ名のみ変更 (カメラフィルタなし)

```toml
[blackmagic-rename]
enabled = true
app-name = "Blackmagic Camera (Renamed)"
apkmirror-dlurl = "..."
patches-source = "tqmane/blackmagic-revanced-patches"
patches-version = "1.0.0"
cli-version = "4.6.0"
included-patches = "'Change package name'"  # ← Filter camera IDs を除外

[blackmagic-rename.options]
packageName = "com.your.custom.name"
# cameraIdsToFilter は不要
```

## 🤝 貢献

Issue や Pull Request を歓迎します！

## 📄 ライセンス

このプロジェクトは [GPL-3.0 License](./LICENSE) の下でライセンスされています。

## 🙏 クレジット

- [j-hc/revanced-magisk-module](https://github.com/j-hc/revanced-magisk-module) - ベースビルドシステム
- [ReVanced/revanced-patches](https://github.com/ReVanced/revanced-patches) - ReVanced Patches
- [ReVanced/revanced-cli](https://github.com/ReVanced/revanced-cli) - ReVanced CLI
- [Blackmagic Design](https://www.blackmagicdesign.com/) - Blackmagic Camera アプリ
