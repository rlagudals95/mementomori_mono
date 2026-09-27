# 모노레포 구조

## 앱 경계

현재 개발 대상은 iOS·macOS이며 데스크톱은 Mac만 지원합니다. Android는 후순위입니다. 플랫폼별 기능의 현재 차이는 [플랫폼 기준](PLATFORMS.md)에서 관리합니다.

`apps/web`는 웹 HTML/CSS/JavaScript, Vite 구성, 정적 파일, 웹 테스트를 소유합니다. `apps/macos`는 Swift package와 네이티브 UI, 로컬 저장, 창 동작을 소유합니다. 폰트 준비 및 .app 패키징은 루트 `scripts/build-mac.sh`에서 수행합니다.

`apps/ios`는 SwiftUI iPhone 앱, WidgetKit 확장, AppIntent 설정, iOS UI 테스트를 소유합니다. Android는 구현할 때 `apps/android`를 추가합니다. 앱별 빌드·배포는 독립적입니다. `packages/memento-core`는 macOS와 iOS가 공유하는 Foundation 기반 Swift package입니다.

## 공유 범위

`shared/contracts`는 데이터 교환 형식과 버전 규칙, `shared/fixtures`는 언어별 계산의 정답 데이터, `shared/design`은 브랜드·문구·디자인 원칙입니다. 각 플랫폼의 UI 코드는 앱 안에 둡니다. 계산이나 설정 계약을 변경할 때에는 모든 관련 앱과 공통 데이터를 함께 검토합니다.

현재 JavaScript는 웹 내부, Swift 계산·검증·설정 계약과 위젯 날짜 경계 계산은 packages/memento-core에 있습니다. 런타임 코드의 무리한 통합 대신 동일한 fixture로 계산 결과를 맞춥니다. 구조 정리를 위한 이동에서 제품 기능과 저장 키, 앱 bundle identifier는 유지했습니다. 기존 사용자 설정은 같은 로컬 저장 위치를 사용합니다.

## 의존성과 명령

루트 `package-lock.json` 하나를 커밋합니다. 웹 런타임 및 개발 의존성은 `apps/web/package.json`, 공통 빌드의 sharp와 네이티브 폰트 준비에 필요한 pretendard는 루트에서 관리합니다. npm이 같은 Pretendard 버전을 함께 설치합니다. Swift 앱은 저장소 내부의 memento-core package만 사용하며 외부 Swift 의존성이 없습니다.

루트의 `npm run dev`, `build`, `preview`, `test`, `test:browser`가 웹 workspace로 전달되고, `build:mac`, `dev:mac`은 macOS 앱을, `test:mac`과 `test:core`는 공용 Swift 계산을 검사합니다. `prepare:ios`, `build:ios`, `dev:ios`, `test:ios`는 iPhone 폰트 준비·시뮬레이터 빌드·실행·UI 검증입니다. 웹 결과는 `apps/web/dist`, Mac 앱은 기존 `artifacts/mac/MementoMori.app`, iOS 결과물은 `artifacts/ios/DerivedData`에 생성됩니다. 로컬 웹 URL과 JSON 설정 파일 형식은 유지합니다.

## Git과 배포

로컬 전체 검증은 macOS에서 `npm run test:all`을 실행합니다. `npm test`는 웹 단위 테스트만 실행합니다. 통합 검증은 공용 Swift 테스트를 한 번 실행하고 웹·Mac·iOS 빌드와 웹/iOS 사용 흐름을 검사합니다. CI는 플랫폼별 job을 유지하여 실패한 플랫폼을 구분합니다.

소스, 테스트, 라이선스, 설정 파일, lockfile을 추적합니다. node_modules, dist, Swift 빌드 캐시, artifacts, 비밀 키와 인증서는 제외합니다. 개인정보가 포함된 사용자 설정 파일을 fixture로 커밋하지 마세요.

GitHub의 checks workflow는 웹·Mac·iOS를 별도 job으로 빌드·테스트합니다. 공통 계약 변경도 검사하도록 모든 PR과 main/master push에서 관련 앱을 검사합니다. 원격 저장소는 rlagudals95/mementomori_mono입니다. 로컬 검증과 원격 CI 결과는 별도로 확인합니다.

출시는 `web-v0.1.0`, `macos-v0.1.0`처럼 앱별 태그로 구분할 수 있습니다. Swift 앱 외부 배포용 Developer ID 서명/공증은 로컬 개발 빌드와 별도 단계입니다.

## iOS 개인 설치와 공개 배포 경계

iOS 앱은 UserDefaults의 settings.v1에 공통 설정을 저장합니다. 앱은 저장·초기화·첫 실행 시 App Groups UserDefaults에도 settings.v1을 기록하고 WidgetCenter에 timeline 갱신을 요청합니다. 위젯의 생년월일 입력이 비어 있으면 공유 프로필·앱의 초/일 모드를 사용합니다. 생년월일을 직접 입력한 위젯은 기존 intent 설정을 유지합니다. 앱과 확장은 같은 App Groups entitlement와 서명 프로파일이 필요합니다. 웹↔Mac↔iOS 이동은 동일한 v1 JSON으로 가능합니다.

WidgetKit의 실행 예산 때문에 임의의 숫자를 매초 다시 그리지 않습니다. 앱은 현재 시각 기반 TimelineView, 위젯 타이머는 시스템의 동적 날짜 Text, 날 표시에는 공용 WidgetClock의 날짜 경계 timeline을 사용합니다. iOS UI와 디자인은 공용 Foundation package에 넣지 않습니다.

프로젝트 생성은 표준 라이브러리 Python 스크립트로 수행하며 생성된 Xcode 프로젝트를 추적합니다. 프로젝트의 Debug/Release는 `apps/ios/Config/Signing.xcconfig`를 읽고, 이 파일은 Git에서 제외한 `LocalSigning.xcconfig`를 선택적으로 포함합니다. 개인 Team ID는 로컬 파일에만 기록합니다. 재생성해도 이 파일을 유지하며, 파일이 없는 CI는 계정 없는 시뮬레이터로 빌드합니다. Xcode target에 Team을 직접 지정하면 로컬 파일을 덮어쓰는 설정이 프로젝트에 생길 수 있으므로 Team 변경은 로컬 파일에서 수행합니다. 공개 배포용 서명·TestFlight·App Store 제출은 이번 개발에 포함하지 않습니다.

## Native scene rendering

The local memento-core Swift package now exports two products: Foundation-based `MementoCore` for calculation and validation, and SwiftUI-based `MementoScenes` for native artwork. Mac, iPhone, and home-screen widgets share the five scene drawings and interactions through MementoScenes. Platform screen layout, window handling, WidgetKit, and persistence stay in each app.

On iOS, `scene.theme` is stored in app defaults and mirrored to the App Group. Selection requests a WidgetKit timeline reload; iOS controls when that refresh appears. `scene.motion` is app-only. Existing settings-v1 JSON and profile keys stay unchanged; scene preferences are not included in JSON transfer or automatic cross-device sync. App motion pauses when inactive or presenting settings/help, and respects Reduce Motion. Widget art is static; existing date text owns live seconds. Lock-screen layouts remain compact.
