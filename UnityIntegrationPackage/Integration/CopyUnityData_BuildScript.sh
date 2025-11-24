#!/bin/bash
# Xcode Build Phases에 추가할 스크립트
#
# 사용 방법:
# 1. Xcode에서 프로젝트 선택 → TARGETS → 앱 타겟
# 2. Build Phases 탭 → + 버튼 → New Run Script Phase
# 3. 아래 스크립트 복사/붙여넣기
# 4. Build Phases에서 "Copy Bundle Resources" 다음 위치로 드래그

echo "===== Copying Unity Data folder ====="

# 프로젝트 최상단의 Data 폴더
SOURCE="${PROJECT_DIR}/Data"

# 앱 번들 내 Data 경로
DEST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Data"

echo "Source: $SOURCE"
echo "Destination: $DEST"

# Data 폴더가 있는지 확인
if [ -d "$SOURCE" ]; then
    echo "Found Data folder at project root"

    # 기존 Data 폴더 제거
    if [ -d "$DEST" ]; then
        echo "Removing old Data folder..."
        rm -rf "$DEST"
    fi

    # Data 폴더 복사
    echo "Copying Data folder..."
    cp -R "$SOURCE" "$DEST"

    # 성공 확인
    if [ -f "$DEST/Managed/Metadata/global-metadata.dat" ]; then
        echo "✅ SUCCESS: Data folder copied!"
    else
        echo "⚠️ WARNING: Data structure might be different"
    fi
else
    echo "❌ ERROR: Data folder not found at project root"
    exit 1
fi

echo "===== Done ====="