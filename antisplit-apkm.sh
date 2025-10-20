#!/bin/bash
#
# AntiSplit-M Script for APKMirror .apkm files
# APKMirrorからダウンロードした.apkmファイルを自動的に単一の.apkに変換
#
# 使用方法:
#   ./antisplit-apkm.sh input.apkm output.apk
#
# 依存関係:
#   - unzip
#   - aapt (Android SDK Build Tools)
#   - zipalign (Android SDK Build Tools)
#   - apksigner (Android SDK Build Tools) ※オプション
#

set -e  # エラーで即座に終了

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 使用方法
usage() {
    cat << EOF
使用方法: $0 <input.apkm> <output.apk>

APKMirrorからダウンロードした.apkmファイルを単一の.apkファイルに変換します。

引数:
  input.apkm   入力ファイル (.apkm形式)
  output.apk   出力ファイル (.apk形式)

例:
  $0 blackmagic_camera.apkm Blackmagic_Camera.apk

依存関係:
  - unzip
  - aapt (Android SDK Build Tools)
  - zipalign (Android SDK Build Tools)
  - apksigner (Android SDK Build Tools) ※オプション

EOF
    exit 1
}

# 引数チェック
if [ $# -ne 2 ]; then
    log_error "引数が不足しています"
    usage
fi

INPUT_APKM="$1"
OUTPUT_APK="$2"

# 入力ファイル存在チェック
if [ ! -f "$INPUT_APKM" ]; then
    log_error "入力ファイルが見つかりません: $INPUT_APKM"
    exit 1
fi

# 依存関係チェック
check_dependencies() {
    local missing=0
    
    if ! command -v unzip &> /dev/null; then
        log_error "unzipがインストールされていません"
        missing=1
    fi
    
    if ! command -v aapt &> /dev/null; then
        log_warning "aaptが見つかりません (Android SDK Build Toolsが必要)"
        log_warning "インストール: sudo apt install aapt (Ubuntu/Debian)"
        log_warning "または Android SDK をセットアップしてください"
        missing=1
    fi
    
    if ! command -v zipalign &> /dev/null; then
        log_warning "zipalignが見つかりません (Android SDK Build Toolsが必要)"
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        log_error "必要な依存関係が不足しています"
        exit 1
    fi
}

log_info "依存関係チェック..."
check_dependencies

# 作業ディレクトリ作成
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

log_info "作業ディレクトリ: $WORK_DIR"

# Step 1: .apkmを解凍
log_info "Step 1: .apkmファイルを解凍中..."
unzip -q "$INPUT_APKM" -d "$WORK_DIR/apkm_extracted"

if [ ! -d "$WORK_DIR/apkm_extracted" ]; then
    log_error "解凍に失敗しました"
    exit 1
fi

# Step 2: APKファイルをリスト表示
log_info "Step 2: 含まれるAPKファイルを確認中..."
APK_FILES=($(find "$WORK_DIR/apkm_extracted" -name "*.apk" | sort))

if [ ${#APK_FILES[@]} -eq 0 ]; then
    log_error "APKファイルが見つかりません"
    exit 1
fi

log_success "${#APK_FILES[@]}個のAPKファイルを検出:"
for apk in "${APK_FILES[@]}"; do
    echo "  - $(basename "$apk")"
done

# Step 3: base.apkを特定
BASE_APK=""
for apk in "${APK_FILES[@]}"; do
    if [[ "$(basename "$apk")" == "base.apk" ]]; then
        BASE_APK="$apk"
        break
    fi
done

if [ -z "$BASE_APK" ]; then
    log_error "base.apkが見つかりません"
    exit 1
fi

log_info "Step 3: base.apkを展開中..."
MERGED_DIR="$WORK_DIR/merged_apk"
mkdir -p "$MERGED_DIR"
unzip -q "$BASE_APK" -d "$MERGED_DIR"

# Step 4: 各split APKをマージ
log_info "Step 4: split APKをマージ中..."
SPLIT_COUNT=0

for apk in "${APK_FILES[@]}"; do
    apk_name=$(basename "$apk")
    
    # base.apkはスキップ（既に展開済み）
    if [[ "$apk_name" == "base.apk" ]]; then
        continue
    fi
    
    log_info "  マージ中: $apk_name"
    
    # split APKを一時ディレクトリに展開
    SPLIT_DIR="$WORK_DIR/split_$SPLIT_COUNT"
    mkdir -p "$SPLIT_DIR"
    unzip -q "$apk" -d "$SPLIT_DIR"
    
    # リソースとライブラリをマージ
    # - lib/ (ネイティブライブラリ)
    # - res/ (リソースファイル)
    # - assets/ (アセット)
    # - その他のファイル
    
    if [ -d "$SPLIT_DIR/lib" ]; then
        log_info "    - libディレクトリをマージ"
        cp -r "$SPLIT_DIR/lib"/* "$MERGED_DIR/lib/" 2>/dev/null || mkdir -p "$MERGED_DIR/lib" && cp -r "$SPLIT_DIR/lib"/* "$MERGED_DIR/lib/"
    fi
    
    if [ -d "$SPLIT_DIR/assets" ]; then
        log_info "    - assetsディレクトリをマージ"
        cp -r "$SPLIT_DIR/assets"/* "$MERGED_DIR/assets/" 2>/dev/null || mkdir -p "$MERGED_DIR/assets" && cp -r "$SPLIT_DIR/assets"/* "$MERGED_DIR/assets/"
    fi
    
    if [ -d "$SPLIT_DIR/res" ]; then
        log_info "    - resディレクトリをマージ"
        # resディレクトリは慎重にマージ（上書きを避ける）
        find "$SPLIT_DIR/res" -type f | while read file; do
            rel_path="${file#$SPLIT_DIR/res/}"
            target="$MERGED_DIR/res/$rel_path"
            if [ ! -f "$target" ]; then
                mkdir -p "$(dirname "$target")"
                cp "$file" "$target"
            fi
        done
    fi
    
    # dexファイルをマージ（classes2.dex, classes3.dex など）
    find "$SPLIT_DIR" -maxdepth 1 -name "classes*.dex" | while read dex_file; do
        dex_name=$(basename "$dex_file")
        if [ ! -f "$MERGED_DIR/$dex_name" ]; then
            log_info "    - $dex_name をコピー"
            cp "$dex_file" "$MERGED_DIR/"
        fi
    done
    
    SPLIT_COUNT=$((SPLIT_COUNT + 1))
done

log_success "全splitAPKをマージ完了 ($SPLIT_COUNT個)"

# Step 5: AndroidManifest.xmlを更新（split属性を削除）
log_info "Step 5: AndroidManifest.xmlを更新中..."
MANIFEST="$MERGED_DIR/AndroidManifest.xml"

if [ -f "$MANIFEST" ]; then
    # バイナリXMLなのでaaptで処理
    # split属性やisSplitRequiredを削除する必要がある場合はapktoolを使用
    log_warning "AndroidManifest.xmlの手動編集が必要な場合があります"
    log_warning "必要に応じて apktool を使用してください"
fi

# Step 6: 新しいAPKを作成
log_info "Step 6: 最終APKを作成中..."
TEMP_APK="$WORK_DIR/temp_unsigned.apk"

cd "$MERGED_DIR"
zip -r -q "$TEMP_APK" .
cd - > /dev/null

# Step 7: zipalignで最適化
log_info "Step 7: zipalignで最適化中..."
ALIGNED_APK="$WORK_DIR/aligned.apk"

if command -v zipalign &> /dev/null; then
    zipalign -f 4 "$TEMP_APK" "$ALIGNED_APK"
    mv "$ALIGNED_APK" "$OUTPUT_APK"
else
    log_warning "zipalignが見つかりません。最適化をスキップします"
    mv "$TEMP_APK" "$OUTPUT_APK"
fi

# 完了
log_success "APK作成完了: $OUTPUT_APK"

# ファイル情報表示
if [ -f "$OUTPUT_APK" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_APK" | cut -f1)
    log_info "ファイルサイズ: $FILE_SIZE"
    
    if command -v aapt &> /dev/null; then
        PACKAGE_NAME=$(aapt dump badging "$OUTPUT_APK" 2>/dev/null | grep "package:" | sed "s/.*name='\([^']*\)'.*/\1/")
        VERSION_NAME=$(aapt dump badging "$OUTPUT_APK" 2>/dev/null | grep "package:" | sed "s/.*versionName='\([^']*\)'.*/\1/")
        
        if [ -n "$PACKAGE_NAME" ]; then
            log_info "パッケージ名: $PACKAGE_NAME"
        fi
        if [ -n "$VERSION_NAME" ]; then
            log_info "バージョン: $VERSION_NAME"
        fi
    fi
fi

# 署名に関する注意
log_warning ""
log_warning "⚠️  重要な注意事項:"
log_warning "  このAPKは署名されていません"
log_warning "  ReVanced CLIがパッチ適用時に自動的に署名します"
log_warning ""
log_warning "  手動でインストールする場合は以下のコマンドで署名してください:"
log_warning "  apksigner sign --ks keystore.jks --ks-key-alias alias $OUTPUT_APK"
log_warning ""

# 次のステップを表示
cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ AntiSplit処理が完了しました！

次のステップ:

1. config.tomlでこのAPKを指定:
   
   [blackmagic-camera]
   apk-source = "./$OUTPUT_APK"
   cli-version = "4.6.0"
   patches-source = "tqmane/blackmagic-revanced-patches"

2. ReVanced CLIでパッチを適用:
   
   java -jar revanced-cli-4.6.0.jar patch \\
     --patch-bundle revanced-patches-blackmagic-1.0.0.jar \\
     --apk $OUTPUT_APK \\
     --out patched.apk

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

exit 0
