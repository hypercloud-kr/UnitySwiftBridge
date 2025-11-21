# Unity Framework iOS 통합 가이드

> Unity Framework를 iOS 네이티브 앱에 통합하는 방법입니다.

---

## 📦 제공받는 파일

1. **UnityFramework.framework** - Unity 빌드 결과물
2. **Data/** 폴더 - Unity 리소스
3. **UnitySwiftBridge/** - iOS 통합 코드

---

## ⚙️ 1단계: Xcode 프로젝트 설정

### 1-1. UnityFramework 추가

1. Xcode 프로젝트 열기
2. **프로젝트 내 Frameworks 폴더 생성** (선택사항, 정리용)
3. **UnityFramework.framework를 프로젝트로 드래그**
   - ✅ **Copy items if needed** 체크
   - ✅ 타겟에 추가
4. **General → Frameworks, Libraries, and Embedded Content**
   - **Embed & Sign** 선택 ⚠️ 중요!

### 1-2. Data 폴더 추가

1. **Data 폴더를 프로젝트로 드래그**
2. ⚠️ **Create folder references** 선택 (파란 폴더)
3. **Create groups 아님!** (노란 폴더 X)
4. 타겟에 추가 체크

### 1-3. Build Settings 구성

**프로젝트 선택 → Build Settings → 검색해서 설정:**

#### Framework Search Paths
```
$(PROJECT_DIR)
$(PROJECT_DIR)/Frameworks
```

#### Other Linker Flags
```
-Wl,-U,_UnityReplayKitDelegate
```

#### Enable Bitcode
```
No
```

### 1-4. Bridging Header 생성

**파일 생성:** `YourProject-Bridging-Header.h`

```objective-c
#ifndef YourProject_Bridging_Header_h
#define YourProject_Bridging_Header_h

#import <UnityFramework/UnityFramework.h>

#endif
```

**Build Settings → Swift Compiler - General:**
- **Objective-C Bridging Header**: `$(PROJECT_DIR)/YourProject/YourProject-Bridging-Header.h`

### 1-5. Info.plist 설정

카메라 권한 추가 (AR 사용 시):

```xml
<key>NSCameraUsageDescription</key>
<string>AR 기능을 사용하기 위해 카메라 접근이 필요합니다</string>
```

---

## 📝 2단계: UnitySwiftBridge 통합

### 2-1. Swift 파일 추가

제공받은 Swift 파일들을 프로젝트에 추가:

```
프로젝트/
├── Managers/
│   └── UnityManager.swift          ← 추가
├── Bridge/
│   └── UnityBridge.swift           ← 추가
└── Views/
    └── UnityViewRepresentable.swift ← 추가
```

**또는** Swift Package로 제공받은 경우:
1. **File → Add Packages...**
2. GitHub URL 또는 로컬 경로 입력
3. **Add Package**

### 2-2. AppDelegate 수정

**AppDelegate.swift** (또는 App 구조체에 추가):

```swift
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Unity 로드 (0.5초 후)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UnityManager.shared.loadUnity()
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        UnityManager.shared.pauseUnity()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UnityManager.shared.resumeUnity()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        UnityManager.shared.unloadUnity()
    }
}
```

**SwiftUI App에서 AppDelegate 사용:**

```swift
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

---

## 🎮 3단계: Unity 사용하기

### 3-1. Unity 시작하기

```swift
import SwiftUI

struct ContentView: View {
    @State private var showUnity = false

    var body: some View {
        Button("Unity 시작") {
            if let window = UIApplication.shared.windows.first {
                UnityManager.shared.showUnity(inWindow: window)
            }
            UnityManager.shared.showUnityWindow()
            showUnity = true
        }
        .sheet(isPresented: $showUnity) {
            UnityViewRepresentable()
                .edgesIgnoringSafeArea(.all)
        }
    }
}
```

### 3-2. Unity에 메시지 보내기

```swift
// 간단한 메시지
UnityBridge.shared.sendMessage(
    to: "iOSBridge",
    method: "ReceiveJSONData",
    message: "{\"command\":\"test\",\"data\":\"Hello\"}"
)

// JSON 데이터
let data: [String: Any] = [
    "command": "spawn_object",
    "x": 0, "y": 0, "z": -1
]
UnityBridge.shared.sendJSONData(data)
```

### 3-3. Unity로부터 메시지 받기

```swift
class MyBridgeHandler: ObservableObject, UnityBridgeDelegate {

    init() {
        UnityBridge.shared.delegate = self
    }

    func unityDidReceiveMessage(_ message: String) {
        print("Unity 메시지: \(message)")
    }

    func unityARPlaneDetected(planeId: String, position: (x: Float, y: Float, z: Float)) {
        print("평면 감지: \(planeId)")
    }

    func unityARSessionStateChanged(_ state: String) {
        print("AR 세션: \(state)")
    }

    func unityReady() {
        print("Unity 준비 완료")
    }

    func unityRequestCloseView() {
        print("Unity 닫기 요청")
        // Unity 뷰 닫기 처리
    }
}
```

---

## 📡 4단계: Unity 통신 프로토콜

### Unity GameObject 이름

모든 메시지는 Unity의 **"iOSBridge"** GameObject로 전송됩니다.

### 사용 가능한 메서드

| 메서드 | 설명 | 파라미터 |
|--------|------|----------|
| `ReceiveJSONData` | JSON 데이터 수신 | JSON 문자열 |
| `StartARSession` | AR 세션 시작 | 설정 문자열 (선택) |
| `StopARSession` | AR 세션 정지 | "" |
| `ResetARSession` | AR 세션 리셋 | "" |
| `TogglePlaneDetection` | 평면 감지 토글 | "true" or "false" |

### JSON 메시지 형식

```json
{
  "command": "명령어",
  "data": "데이터",
  "추가_필드": "값"
}
```

---

## ⚠️ 문제 해결

### Unity가 시작되지 않음

**확인사항:**
- [ ] UnityFramework가 **Embed & Sign**으로 설정되어 있는지
- [ ] Data 폴더가 **folder reference**(파란색)로 추가되었는지
- [ ] Bridging Header 경로가 정확한지
- [ ] Framework Search Paths가 설정되어 있는지

### 통신이 작동하지 않음

**확인사항:**
- [ ] UnityBridge.shared.delegate가 설정되어 있는지
- [ ] Unity 측에 "iOSBridge" GameObject가 있는지
- [ ] 메시지 전송 시 GameObject 이름이 "iOSBridge"인지

### 빌드 에러

**일반적인 원인:**
- Bitcode가 활성화되어 있음 → **No**로 설정
- Framework Search Paths 누락
- Bridging Header 경로 오류

---

## 📱 테스트

### 1. 시뮬레이터 vs 실제 기기

- ⚠️ **시뮬레이터**: Unity가 기기용으로 빌드되었다면 작동 안 함
- ✅ **실제 기기**: AR 기능 포함 모든 기능 작동

### 2. 로그 확인

**Xcode Console에서 확인:**

```
[AppDelegate] Loading Unity framework...
[UnityManager] Unity loaded successfully
[Swift->Unity] Sending to iOSBridge.ReceiveJSONData: ...
[Unity->Swift] Unity is ready
```

---

## 📋 체크리스트

프로젝트 통합 완료 확인:

- [ ] UnityFramework.framework 추가 (Embed & Sign)
- [ ] Data 폴더 추가 (folder reference)
- [ ] Build Settings 구성 완료
- [ ] Bridging Header 생성 및 설정
- [ ] Info.plist 권한 추가
- [ ] UnitySwiftBridge 코드 추가
- [ ] AppDelegate 수정
- [ ] Unity 시작 코드 구현
- [ ] 실제 기기에서 테스트

---

## 🚀 다음 단계

1. Unity와 통신하는 커스텀 기능 구현
2. AR 기능 활용
3. UI/UX 개선

---

## 📞 지원

문제가 발생하면:
1. 체크리스트 확인
2. 로그 확인 (Xcode Console)
3. 문제 해결 섹션 참고

---

**통합 완료! 🎉**
