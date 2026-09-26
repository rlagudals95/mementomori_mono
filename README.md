# 메멘토모리

언젠가 끝나기에, 지금이 소중합니다.

평균 기대수명을 시간의 가늠자로 삼아 삶의 유한함을 느끼게 하는 웹·Mac·iPhone 앱입니다. 생년월일 기반 초 단위 카운트다운, 삶의 주간 달력, 오늘의 한 문장과 노트북의 작은 창을 제공합니다.

## 레포 구조

```text
apps/
  web/          # Vite 웹앱과 웹 테스트
  macos/        # SwiftUI/AppKit 작은 창 앱
  ios/          # SwiftUI iPhone 앱과 홈·잠금화면 위젯
packages/
  memento-core/ # Mac/iOS 공용 Swift 계산·계약·테스트
shared/
  contracts/    # 설정 JSON 형식과 버전 규칙
  fixtures/     # 플랫폼별 계산 결과 검증 데이터
  design/       # 공통 디자인 원칙과 문구
docs/           # 제품 계획, 검증 기록
scripts/        # Mac/iOS 빌드·실행, 폰트·아이콘 준비
.github/workflows/ # GitHub 빌드·테스트
```

npm workspaces로 웹을 관리하고 Mac은 Swift Package Manager를 사용합니다. 아래 명령은 모두 레포 루트에서 실행합니다. iPhone은 Xcode 프로젝트, Mac은 Swift package를 사용하며 계산은 공용 Swift package를 공유합니다. 제품 개발 대상은 iOS·macOS이고 Android는 후순위입니다. 데스크톱은 Mac만 지원합니다. 폴더별 책임은 [구조 안내](docs/ARCHITECTURE.md), 현재 기능과 플랫폼별 차이는 [플랫폼 기준](docs/PLATFORMS.md)에 있습니다.

## 실행

Node.js 22.12 이상(또는 20.19 이상)이 필요합니다.

```sh
npm ci
npm run dev
```

화면에 표시되는 로컬 주소로 접속합니다. 같은 네트워크의 휴대폰은 개발 서버의 Network 주소로 확인할 수 있습니다. 일반 LAN HTTP에서는 설치·오프라인·작은 창 등 보안 컨텍스트가 필요한 기능이 제한됩니다. 실제 배포에는 HTTPS를 사용하세요.

```sh
npm test
npm run build
npm run preview
npm run test:browser
```

`npm test`와 `npm run test:web`는 웹 단위 테스트만 실행합니다. macOS에서 전체 검증은 다음 명령을 사용하세요. 웹 단위 테스트·공용 Swift 테스트·웹 빌드와 브라우저 테스트·Mac 빌드·iOS 빌드와 UI 테스트를 순서대로 실행하며 실패 시 중단합니다. Xcode, iPhone 시뮬레이터 런타임, Chrome이 필요합니다. Mac 빌드는 `artifacts/mac/MementoMori.app`을 갱신하므로 실행 중인 해당 앱은 먼저 종료하세요.

```sh
npm run test:all
```

브라우저 테스트는 설치된 Google Chrome을 사용합니다. 없으면 `npx --workspace @mementomori/web playwright install chrome`으로 테스트용 Chrome을 준비하세요. `npm run build` 뒤 실행해야 최신 배포본을 검사합니다.

## 배포

`npm run build`로 생성되는 `apps/web/dist/` 폴더를 HTTPS 정적 호스팅에 올립니다. 서버·환경변수·API 키·데이터베이스가 필요 없습니다. 현재 `/` 경로에 배포하도록 구성되어 있습니다. `sw.js`와 `index.html`은 `Cache-Control: no-cache`, 해시가 포함된 `/assets/*`는 장기 immutable 캐시를 권장합니다.

Service Worker는 배포 파일과 폰트를 미리 저장합니다. 최초 온라인 캐시 준비를 마쳐야 오프라인으로 사용할 수 있습니다. 새 버전은 기존 앱 탭을 모두 닫았다가 열 때 활성화됩니다. 브라우저의 저장 공간 정리로 데이터와 오프라인 캐시가 지워질 수 있습니다.

## 사용 범위

- 개인의 사망 시점을 예측하지 않습니다. 기본 83.7년은 대한민국 2024년 **출생 시 기대수명**입니다. 현재 연령의 기대여명은 아닙니다.
- 웹의 생년월일과 문장은 localStorage에 보관합니다. 서버로 보내거나 기기 사이에 동기화하지 않습니다.
- 작은 창은 지원되는 데스크톱 Chrome에서 사용하며 원래 탭을 열어 두어야 합니다. 브라우저/기기 절전 정책에 따라 표시 갱신이 늦어질 수 있으며 복귀 시 현재 시각으로 보정합니다.
- 홈 화면에 추가되는 것은 PWA 아이콘입니다. iPhone 네이티브 위젯은 `apps/ios`에서 제공합니다. Android·스마트워치 위젯은 아직 없습니다.
- ‘집중 화면’은 웹페이지 내부의 단순 보기 모드입니다. 화면 꺼짐을 방지하지 않습니다.
- 날짜 기준은 기기의 현재 시간대입니다. 시계·시간대 변경은 표시 결과에 영향을 줍니다.
- 웹폰트는 로컬 번들에 포함되어 있습니다. 서비스 자체는 외부 API나 추적 SDK를 호출하지 않습니다.

## 파일

- `apps/web/src/life.js`: 날짜 검증, 수명 계산, 저장 데이터 복원.
- `apps/web/src/main.js`: UI, 로컬 저장, 작은 창, 설치·집중 모드.
- `apps/web/src/style.css`: 반응형 디자인, 로컬 폰트, 접근성·모션 설정.
- `apps/web/vite.config.js`: 오프라인 배포 파일 생성.
- `apps/web/tests/`: 계산 단위 테스트와 실제 브라우저 사용 흐름 테스트.
- [제품 평가와 실행 계획](docs/PRODUCT.md).
- [후속 기능 상세 기획: 미루고 있는 삶](docs/PRD-mementomori-life-goals.md) / [구현 계획](docs/IMPLEMENTATION-life-goals.md). 기획 단계이며 아직 구현하지 않았습니다.
- [검증 결과와 남은 확인 항목](docs/VERIFICATION.md).

폰트: Pretendard Variable 1.3.9. 로컬 번들로 제공하며 SIL Open Font License를 따릅니다. 라이선스는 `apps/web/public/licenses/pretendard.txt`에 포함되어 있습니다.

## 위젯 디자인

시간을 표현하는 다섯 장면은 `/motion.html`에서 비교합니다. 모래시계·시지프스·필름·촛불·편도 열차를 모노톤으로 표현하고, 뒤집기·밀기·한 컷 남기기·가리기·창문 닦기를 직접 해볼 수 있습니다. [시안 설명](docs/SCENE-STUDIES.md)에 의미와 검증할 가설을 정리했습니다. 최초의 숫자 움직임 세 가지는 `/motion-minimal.html`과 [움직임 설명](docs/MOTION-STUDIES.md)에 보관했습니다. 두 화면 모두 실제 설정을 변경하지 않는 웹 시안입니다.

`/widgets.html`에서 가로형(360×190), 정사각형(190×190), 한 줄형(360×84)을 다크·라이트로 비교할 수 있습니다. 기준 크기이며 작은 화면이나 브라우저 창 제한에 맞춰 조정됩니다. 선택한 형태와 테마는 이 브라우저에 저장되고, 메인 화면의 ‘작은 창 띄우기’에도 적용됩니다. 정사각형은 일 단위, 나머지는 초 단위입니다. 메인 미리보기와 작은 창에는 오늘의 문장이 표시되고, 하단 비교 샘플에는 기본 문장이 표시됩니다.

`apps/web/src/widget.js`와 `apps/web/src/widget.css`가 미리보기와 실제 작은 창의 공통 컴포넌트입니다. 이 디자인은 웹의 작은 창과 Mac 앱에 적용합니다. iPhone OS 위젯은 같은 모티프를 WidgetKit으로 구현하며 iOS가 제공하는 크기를 사용합니다.

## Mac 앱 (첫 로컬 버전)

웹과 별도로 실행되는 SwiftUI/AppKit 앱입니다. 브라우저나 개발 서버를 닫아도 동작합니다. macOS 13 이상을 대상으로 하며 현재 빌드는 이 Mac의 Apple Silicon 아키텍처입니다. Xcode와 Swift 도구가 필요합니다.

```sh
npm ci
npm run build:mac
open artifacts/mac/MementoMori.app
npm run test:mac
```

`apps/macos/Package.swift`를 Xcode로 열어 개발할 수도 있습니다. 폰트 준비를 위해 최초 한 번 `npm run build:mac`을 실행하세요. 빌드 결과는 `artifacts/mac/MementoMori.app`입니다. 다른 폴더로 앱을 옮겨도 폰트를 포함해 독립 실행됩니다. 빌드할 때 실행 중인 앱은 먼저 종료하고 새 빌드를 다시 실행하세요.

- 가로형·정사각형·한 줄형, 다크·라이트. 정사각형은 일, 나머지는 초를 표시합니다.
- 메뉴바 모래시계 → 표시/숨기기, 설정, 창 위치 초기화, 종료.
- 위젯 위쪽을 드래그하면 위치를 옮길 수 있습니다. 크기·테마·위치·프로필은 저장됩니다.
- 일반 앱 창보다 위에 표시하며 입력 포커스를 빼앗지 않는 패널을 사용합니다. 전체화면, Stage Manager, 다중 모니터 환경은 별도 실기기 확인이 필요합니다.
- 로그인 시 자동 실행과 자동 업데이트는 이 버전에 포함하지 않았습니다. 앱을 원하는 폴더에 둔 뒤 필요하면 macOS 로그인 항목에 직접 추가할 수 있습니다.
- 프로필을 설정하기 전에는 예시임을 표시합니다. 설정에서 이 Mac의 기록만 지울 수 있습니다.
- local ad-hoc 서명을 사용한 개발용 빌드입니다. Developer ID 서명·공증·App Store 등록은 하지 않았습니다. 외부 사용자에게 배포할 릴리스는 별도로 준비해야 합니다.

### 웹 ↔ Mac 설정 이동

웹의 ‘나의 시간 설정’과 Mac의 ‘설정’에서 JSON 파일을 내보내고 가져옵니다. 가져오기는 유효성을 검사한 다음 현재 설정을 바꿀지 확인합니다. 자동 동기화는 없습니다. 파일에는 생년월일이 들어 있으므로 본인이 지정한 위치에 보관하세요.

공통 계약은 `shared/contracts/settings-example.json`이며, 계산 규칙은 `shared/fixtures/life-cases.json`으로 JavaScript와 Swift에서 함께 검사합니다. 웹은 localStorage, Mac은 앱의 UserDefaults에 각각 저장합니다. 같은 시간대와 같은 프로필이라면 같은 카운트다운 기준을 사용합니다.

### 비용

현재 웹 로컬 실행·Mac 개발·이 Mac에서 사용하는 데 별도 라이선스 결제는 필요 없습니다. 서버·DB·유료 API는 사용하지 않습니다. 공개 웹 호스팅과 도메인은 선택하는 업체와 사용량에 따라 별도 비용이 생길 수 있습니다. Mac 외부 배포용 Developer ID 서명과 공증에는 Apple Developer Program 가입이 필요하며, 2026-09-26 확인 기준 연 US$99 또는 현지 통화 금액입니다: https://developer.apple.com/support/compare-memberships/

### 위젯 크기 조절

Mac 위젯 가장자리 또는 오른쪽 아래 손잡이를 드래그하면 가로·세로 크기를 자유롭게 바꿀 수 있습니다. 윗부분은 이동 영역입니다. 크기와 위치는 다음 실행에도 유지됩니다. 메뉴바의 ‘기본 크기로 되돌리기’로 선택한 디자인의 기준 크기를 복원합니다. 가로형/정사각형/한 줄형은 시작 크기이며, 드래그한 비율에 따라 내용이 자동 배치됩니다. 정사각형 디자인의 일 단위와 나머지 디자인의 초 단위는 크기 변경 중에도 유지됩니다.

웹 `/widgets.html`의 미리보기도 오른쪽 아래 모서리로 크기를 조절합니다. 브라우저에서 연 작은 창은 창 테두리를 드래그하세요. 브라우저 자체의 최소 창 크기 제한이 적용될 수 있습니다. Mac과 달리 웹 미리보기의 수동 크기는 페이지를 다시 열면 초기화됩니다.

## iPhone 개인용 앱

SwiftUI 앱과 홈·잠금화면 WidgetKit 위젯을 제공합니다. iOS 17 이상을 대상으로 합니다.

```sh
npm ci
npm run dev:ios
npm run test:core
npm run test:ios
```

`dev:ios`는 이 Mac의 iPhone 시뮬레이터에서 실행합니다. 자신의 iPhone에는 `npm run prepare:ios` 후 로컬 서명 파일에 Team ID를 설정하고 `apps/ios/MementoMori.xcodeproj`에서 Run하세요. 절차는 [iPhone 안내](apps/ios/README.md)에 있습니다. 무료 설치는 **7일마다 재빌드·재설치**가 필요합니다. 상용 배포는 하지 않았습니다.

앱은 초/일 카운트다운, 주간 달력, 오늘의 문장, 웹·Mac JSON 설정 이동을 지원합니다. 홈 화면은 작은/중간 크기, 잠금화면은 직사각형/인라인/원형을 제공합니다. 앱의 생년월일·기준 나이와 초·일 선택은 App Groups로 위젯에 자동 적용됩니다. 별도 생년월일을 입력한 위젯만 개별 설정을 사용합니다. 위젯도 콤마가 들어간 남은 총 초로 표시합니다. iOS 18 이상은 시스템이 자동 갱신하고 iOS 17은 timeline 갱신 시점의 총 초를 표시합니다.

실기기 무료 설치 절차, 비용, 위젯 제한, 추후 공개 배포 구조는 [iPhone 안내](apps/ios/README.md)에 정리했습니다.
