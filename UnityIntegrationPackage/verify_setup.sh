#!/bin/bash
# Unity iOS Integration 설치 확인 스크립트

echo "===== Unity iOS Integration 설치 확인 ====="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 체크 결과 카운터
SUCCESS=0
WARNING=0
ERROR=0

# 함수: 성공 메시지
check_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((SUCCESS++))
}

# 함수: 경고 메시지
check_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNING++))
}

# 함수: 에러 메시지
check_error() {
    echo -e "${RED}❌ $1${NC}"
    ((ERROR++))
}

echo "1. 필수 폴더 확인..."
echo "------------------------"

# UnityFramework 확인
if [ -d "UnityFramework.framework" ]; then
    check_success "UnityFramework.framework 존재"
else
    check_error "UnityFramework.framework 없음 - Unity에서 빌드 필요"
fi

# Data 폴더 확인
if [ -d "Data" ]; then
    check_success "Data 폴더 존재"

    # global-metadata.dat 확인
    if [ -f "Data/Managed/Metadata/global-metadata.dat" ]; then
        check_success "global-metadata.dat 파일 존재"
    else
        check_error "global-metadata.dat 파일 없음 - Data 폴더 구조 확인 필요"
    fi
else
    check_error "Data 폴더 없음 - Unity 빌드에서 복사 필요"
fi

# UnityBridge 폴더 확인
if [ -d "UnityBridge" ]; then
    check_success "UnityBridge 폴더 추가됨"
else
    check_warning "UnityBridge 폴더가 프로젝트에 없음"
fi

# Bridging Header 확인
if [ -f "ios-swift-Bridging-Header.h" ]; then
    check_success "Bridging Header 파일 존재"
else
    check_warning "Bridging Header 파일이 프로젝트에 없음"
fi

echo ""
echo "2. Xcode 프로젝트 확인..."
echo "------------------------"

# .xcodeproj 파일 확인
if ls *.xcodeproj 1> /dev/null 2>&1; then
    check_success "Xcode 프로젝트 파일 발견"
    echo "   프로젝트: $(ls *.xcodeproj)"
else
    check_warning "Xcode 프로젝트 파일이 현재 폴더에 없음"
fi

echo ""
echo "3. 권장 사항..."
echo "------------------------"

# Build Script 확인
if [ -f "Integration/CopyUnityData_BuildScript.sh" ]; then
    echo "📝 Build Script를 Build Phases에 추가하세요"
fi

# Info.plist 확인
echo "📝 Info.plist에 카메라 권한을 추가하세요"
echo "📝 Build Settings에서 User Script Sandboxing을 No로 설정하세요"

echo ""
echo "===== 검사 결과 ====="
echo -e "${GREEN}성공: $SUCCESS${NC}"
echo -e "${YELLOW}경고: $WARNING${NC}"
echo -e "${RED}에러: $ERROR${NC}"

if [ $ERROR -eq 0 ]; then
    if [ $WARNING -eq 0 ]; then
        echo -e "\n${GREEN}🎉 모든 준비가 완료되었습니다!${NC}"
    else
        echo -e "\n${YELLOW}⚠️ 일부 확인이 필요합니다. 위의 경고를 확인하세요.${NC}"
    fi
else
    echo -e "\n${RED}❌ 설치를 완료하려면 위의 에러를 해결하세요.${NC}"
fi

echo ""
echo "자세한 설치 가이드는 README.md를 참고하세요."