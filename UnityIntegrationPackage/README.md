# Unity iOS Integration Package

Unity를 iOS Swift 앱에 통합하기 위한 완전한 패키지입니다.

## 📦 패키지 구성

```
UnityIntegrationPackage/
├── UnityBridge/                   # Unity-iOS 통신 브릿지
│   ├── UnityBridge.swift          # 메인 브릿지 클래스
│   ├── UnityManager.swift         # Unity 생명주기 관리
│   └── UnityViewRepresentable.swift # SwiftUI Unity View
├── Integration/                   # 통합 가이드 및 설정 파일
│   ├── AppDelegate_Addition.swift # AppDelegate 추가 코드
│   ├── CopyUnityData_BuildScript.sh # Data 폴더 복사 스크립트
│   ├── Info.plist_Addition.xml   # 권한 설정
│   ├── Xcode_Settings.txt        # Xcode 프로젝트 설정
│   └── ContentView_Example.swift  # 구현 예시
├── ios-swift-Bridging-Header.h   # Objective-C 브릿징 헤더
└── README.md                      # 이 파일
```

## 🚀 빠른 시작 가이드

### 필수 준비물
1. **UnityFramework.framework** (Unity에서 빌드)
2. **Data 폴더** (Unity 빌드 폴더에서)
3. 이 패키지

## 📝 설치 단계

### 1단계: Unity에서 iOS 빌드
1. Unity 프로젝트 열기
2. File → Build Settings → iOS 선택
3. Build (Xcode 프로젝트 생성)
4. 빌드 폴더에서 다음 복사:
   - `UnityFramework.framework`
   - `Data` 폴더 전체

### 2단계: iOS 프로젝트 준비

#### 2-1. 파일 추가
1. Xcode 프로젝트 루트에 추가:
   ```
   프로젝트 폴더/
   ├── UnityFramework.framework (드래그 & 드롭)
   └── Data/ (Finder에서 복사)
   ```

2. UnityBridge 폴더 전체를 프로젝트에 추가
   - Xcode에서 프로젝트 우클릭 → Add Files
   - UnityBridge 폴더 선택
   - "Copy items if needed" 체크
   - "Create groups" 선택

#### 2-2. Bridging Header 설정
1. `ios-swift-Bridging-Header.h` 파일을 프로젝트에 추가
2. Build Settings → "Objective-C Bridging Header" 검색
3. 경로 설정: `$(PROJECT_DIR)/ios-swift-Bridging-Header.h`

### 3단계: Xcode 프로젝트 설정

#### 3-1. Build Settings
```
Framework Search Paths: $(PROJECT_DIR)
Other Linker Flags: -Wl,-U,_UnityReplayKitDelegate
Enable Bitcode: No
User Script Sandboxing: No
```

#### 3-2. General 탭
- UnityFramework.framework → **"Embed & Sign"** 설정
- Deployment Target: iOS 14.0+

#### 3-3. Build Phases - Data 폴더 자동 복사 설정 ⭐
1. Build Phases → + → New Run Script Phase
2. `CopyUnityData_BuildScript.sh` 내용 복사/붙여넣기
3. "Copy Bundle Resources" 다음 위치로 드래그

### 4단계: 코드 통합

#### 4-1. AppDelegate 설정
SwiftUI App 파일 (@main):
```swift
import SwiftUI

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

`AppDelegate.swift` 생성 또는 수정:
- `Integration/AppDelegate_Addition.swift` 내용 참고

#### 4-2. ContentView 구현
- `Integration/ContentView_Example.swift` 참고하여 구현
- Unity 시작, 종료, 통신 예시 포함

#### 4-3. Info.plist 권한 추가
```xml
<key>NSCameraUsageDescription</key>
<string>AR 기능을 사용하기 위해 카메라 접근이 필요합니다</string>
```

## 🔄 Unity 업데이트 시

Unity 프로젝트를 수정한 후:
1. Unity에서 다시 빌드
2. 새 UnityFramework.framework를 Xcode 프로젝트에 교체
3. Data 폴더를 프로젝트 루트에 교체
4. Clean Build (Cmd+Shift+K) → Build (Cmd+B)

## 🐛 문제 해결

### "IL2CPP initialization failed" 에러
- Data 폴더가 앱 번들에 포함되었는지 확인
- Build Script가 제대로 실행되는지 확인

### "Code signature invalid" 에러
- 수동으로 .app 파일을 수정하지 말 것
- Clean Build 후 재빌드

### Build Script 에러
- User Script Sandboxing → No 설정 확인
- Build Script 위치가 Copy Bundle Resources 다음인지 확인

## 📚 API 문서

### UnityBridge 사용법
```swift
// Unity로 메시지 전송
UnityBridge.shared.sendMessage(
    to: "GameObject",
    method: "MethodName",
    message: "data"
)

// JSON 데이터 전송
UnityBridge.shared.sendJSONData(["key": "value"])
```

### UnityBridgeDelegate
```swift
class MyHandler: UnityBridgeDelegate {
    func unityDidReceiveMessage(_ message: String) { }
    func unityARPlaneDetected(planeId: String, position: (x: Float, y: Float, z: Float)) { }
    func unityARSessionStateChanged(_ state: String) { }
    func unityReady() { }
    func unityRequestCloseView() { }
}
```
