# 모노레포 구조

## 앱 경계

`apps/web`는 웹 HTML/CSS/JavaScript, Vite 구성, 정적 파일, 웹 테스트를 소유합니다. `apps/macos`는 Swift package와 네이티브 UI, 로컬 저장, 창 동작, Swift 테스트를 소유합니다. 폰트 준비 및 .app 패키징은 루트 `scripts/build-mac.sh`에서 수행합니다.

iOS와 Android는 실제 구현을 시작할 때 각각 `apps/ios`, `apps/android`를 추가합니다. 앱별 빌드·배포를 독립적으로 진행합니다. iOS와 macOS가 계산 코드를 공유할 필요가 생기면 현재 MementoCore를 공용 Swift 패키지로 추출합니다.

## 공유 범위

`shared/contracts`는 데이터 교환 형식과 버전 규칙, `shared/fixtures`는 언어별 계산의 정답 데이터, `shared/design`은 브랜드·문구·디자인 원칙입니다. 각 플랫폼의 UI 코드는 앱 안에 둡니다. 계산이나 설정 계약을 변경할 때에는 모든 관련 앱과 공통 데이터를 함께 검토합니다.

현재 JavaScript는 웹 내부, Swift 계산은 macOS의 MementoCore에 있습니다. 런타임 코드의 무리한 통합 대신 동일한 fixture로 계산 결과를 맞춥니다. 구조 정리를 위한 이동에서 제품 기능과 저장 키, 앱 bundle identifier는 유지했습니다. 기존 사용자 설정은 같은 로컬 저장 위치를 사용합니다.

## 의존성과 명령

루트 `package-lock.json` 하나를 커밋합니다. 웹 런타임 및 개발 의존성은 `apps/web/package.json`, 공통 빌드의 sharp와 네이티브 폰트 준비에 필요한 pretendard는 루트에서 관리합니다. npm이 같은 Pretendard 버전을 함께 설치합니다. Swift에는 외부 package 의존성이 없습니다.

루트의 `npm run dev`, `build`, `preview`, `test`, `test:browser`가 웹 workspace로 전달되고, `build:mac`, `dev:mac`, `test:mac`은 macOS 앱을 대상으로 합니다. 웹 결과는 `apps/web/dist`, Mac 앱은 기존 `artifacts/mac/MementoMori.app` 경로에 생성됩니다. 로컬 웹 URL과 JSON 설정 파일 형식은 유지합니다.

## Git과 배포

소스, 테스트, 라이선스, 설정 파일, lockfile을 추적합니다. node_modules, dist, Swift 빌드 캐시, artifacts, 비밀 키와 인증서는 제외합니다. 개인정보가 포함된 사용자 설정 파일을 fixture로 커밋하지 마세요.

GitHub의 checks workflow는 웹·Mac을 별도 job으로 빌드·테스트합니다. 공통 계약 변경도 검사하도록 모든 PR과 main/master push에서 두 앱을 검사합니다. 아직 원격 레포에 연결하거나 workflow를 원격에서 실행한 것은 아닙니다.

출시는 `web-v0.1.0`, `macos-v0.1.0`처럼 앱별 태그로 구분할 수 있습니다. Swift 앱 외부 배포용 Developer ID 서명/공증은 로컬 개발 빌드와 별도 단계입니다.
