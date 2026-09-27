# 메멘토모리 for iPhone

SwiftUI 앱과 WidgetKit 확장입니다. iOS 17 이상, iPhone을 대상으로 합니다. 서버·웹뷰·로그인·유료 API를 사용하지 않습니다. Pretendard와 앱 아이콘은 번들에 포함합니다.

## 구현 범위

- 생년월일과 기준 나이 설정, 실시간 초/일 카운트다운, 삶의 주간 달력, 오늘의 한 문장.
- 홈 화면 작은/중간 위젯, 잠금화면 직사각형/인라인/원형 위젯.
- 위젯의 남은 날 또는 남은 총 초 표시, 다크/라이트, 사용자 문장.
- 앱의 로컬 저장과 웹·Mac 공통 JSON 설정 가져오기/내보내기. 가져오기는 확인 후 적용.
- 설정 전에는 자신의 카운트다운을 표시하지 않습니다. 위젯 갤러리의 샘플만 예시 프로필을 사용합니다.

앱과 위젯은 App Groups의 공유 저장소를 사용합니다. 앱에서 한 번 설정하면 홈·잠금화면 위젯에 자동 적용됩니다. 기존 앱 설정은 새 버전 앱을 열 때 공유 저장소로 옮기며, 설정 변경·초/일 전환·초기화 시 위젯 timeline을 다시 요청합니다. 갱신 시점은 iOS가 결정합니다.

위젯 생년월일을 비워 두면 앱의 프로필과 초·일 표시를 따릅니다. 위젯 편집에 다른 생년월일을 입력한 경우만 해당 위젯의 기준 나이·표시 방식을 사용합니다. 기존에 개별 설정한 위젯을 자동 공유로 바꾸려면 생년월일을 비우세요.

## 이 Mac에서 실행

저장소 루트에서:

```sh
npm ci
npm run dev:ios
```

설치된 iPhone 시뮬레이터를 선택해 빌드·설치·실행합니다. Apple 계정이 필요 없습니다. Xcode와 iOS 시뮬레이터 런타임이 필요하며 Xcode → Settings → Components에서 런타임을 설치할 수 있습니다.

```sh
npm run build:ios  # 시뮬레이터 빌드만
npm run test:core  # Mac/iOS 공용 계산과 계약
npm run test:ios   # 앱 UI와 실제 홈 화면 위젯 추가
```

특정 시뮬레이터 선택은 `MEMENTO_IOS_SIMULATOR_UDID` 환경변수로 가능합니다. 결과물은 `artifacts/ios/DerivedData`입니다. 시뮬레이터용 .app은 실제 iPhone에 설치할 수 없습니다.

## 내 iPhone에 무료 설치

1. `npm ci && npm run prepare:ios`를 실행합니다.
2. `apps/ios/MementoMori.xcodeproj`를 Xcode로 엽니다. scheme은 **MementoMori**입니다.
3. Xcode → Settings → Accounts에서 자신의 Apple 계정으로 로그인합니다. 유료 가입을 하지 않은 계정은 **Personal Team**으로 표시됩니다.
4. `apps/ios/Config/LocalSigning.xcconfig.example`을 같은 폴더의 `LocalSigning.xcconfig`로 복사하고 `YOUR_TEAM_ID`를 자신의 Team ID로 바꿉니다. Team ID는 Xcode 계정의 Team 상세에서 확인합니다. 앱·위젯은 이 값을 상속하며 자동 서명을 사용합니다. Team 변경은 이 로컬 파일에서 하세요. Xcode target에서 직접 Team을 선택하면 공용 프로젝트에 개인 설정이 기록될 수 있습니다. 자동 서명에 필요한 App ID 두 개를 사용합니다.
5. Bundle Identifier 충돌이 있다면 app은 `com.본인의고유이름.mementomori`, widget은 같은 app ID 뒤에 `.widgets`를 붙여 변경합니다. 실제 사용을 시작한 뒤에는 ID를 유지하세요.
6. iPhone을 USB로 연결하고 Mac을 신뢰합니다. iPhone → 설정 → 개인정보 보호 및 보안 → **개발자 모드**를 켭니다. 재시작/확인이 요구될 수 있습니다.
7. Xcode의 실행 대상을 자신의 iPhone으로 선택한 뒤 ▶ Run 또는 ⌘R을 누릅니다. iPhone에서 개발자 신뢰 요청이 표시되면 설정 → 일반 → VPN 및 기기 관리에서 자신의 계정을 확인합니다.
8. 앱에서 자신의 시간을 설정합니다. 홈·잠금화면 위젯을 추가하면 자동으로 같은 시간이 표시됩니다.

개인 계정 선택과 iPhone 연결이 필요하므로 실기기 서명·설치는 사용자가 이 Mac에서 진행해야 합니다. 팀 ID·인증서·기기 정보를 저장소에 커밋하지 않습니다. 정상적으로 다시 Run하면 동일한 bundle ID의 설정은 보통 유지되므로, 매주 갱신할 때 앱을 먼저 삭제하지 마세요. 설정 JSON 백업도 제공합니다.

### 비용과 기간

개발 도구와 무료 Apple 계정의 개인 기기 설치에는 결제가 필요 없습니다. 무료 Personal Team의 프로비저닝은 **7일** 후 만료됩니다. 그때 이 Mac에서 iPhone에 다시 Run해 설치해야 합니다. Apple은 무료 계정에 동시에 10개 App ID, 3개 등록 기기, 기기당 3개 앱 제한을 안내합니다. 이 앱은 본체와 위젯 확장용 App ID를 사용합니다.

App Store/TestFlight 배포는 이번 범위에 포함하지 않았습니다. 나중에 공개 배포하려면 Apple Developer Program이 필요하며 2026-09-26 확인 기준 연 US$99 또는 현지 통화 금액입니다. 서버·DB 비용은 현재 없습니다.

- [Apple 개인 계정과 무료 설치 제한](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Developer Program 가격과 배포 기능](https://developer.apple.com/programs/whats-included/)
- [iPhone 개발자 모드](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)

## 위젯 동작

WidgetKit은 앱처럼 코드를 매초 실행하지 않습니다. iOS 18 이상에서는 SwiftUI의 `Text(.currentDate, format: .offset(to:allowedFields:maxFieldCount:sign:))`에 `.second`만 지정하여 **1,797,555,555초** 형식으로 남은 총 초를 자동 갱신합니다. 음수 부호는 표시하지 않습니다. iOS 17은 timeline 시점의 총 초 숫자를 표시하며 매초 움직이는 기능은 제공하지 않습니다. 화면 꺼짐, Always-On, 저전력 모드, iOS의 표시 정책에 따라 갱신이 멈추거나 느려질 수 있습니다. 매초 갱신을 보장하지 않습니다.

가로형은 상하 18pt, 좌우 20pt 여백을 사용합니다. 숫자는 최대 44pt이고 짧은 높이에서는 여백이 유지되도록 크기를 조절합니다. 정사각형은 16pt 여백을 사용하고, 총 초를 마지막 두 천 단위 그룹 앞에서 두 줄로 나누어 오른쪽 정렬합니다. 예: `1,797,` / `552,425초`. 뒤쪽 여섯 자리는 0을 유지하며 두 줄은 동일한 종료시각에 맞춰 갱신합니다. 가로형은 한 줄을 유지합니다. 위젯에는 시·분·초 설명 줄이 없습니다.

남은 날은 카운트다운의 하루 경계에 맞춘 최대 일주일 분량의 timeline을 제공합니다. 기준 나이를 넘으면 0 아래로 내려가거나 다시 증가하는 타이머를 표시하지 않고 ‘오늘도 삶은 계속됩니다.’를 표시합니다. OS가 timeline 전환을 지연할 수 있습니다. 원형 위젯은 지나온 삶의 비율, 인라인 위젯은 남은 날을 표시합니다.

생년월일 날짜는 기기 시간대의 자정, 1년은 365.2425일로 계산하여 웹·Mac과 같은 규칙을 사용합니다. 시간대를 바꾸면 앱을 다시 열고 위젯 표시도 확인하세요. 기준 83.7년은 대한민국 2024년 출생 시 기대수명이고 개인의 수명 예측은 아닙니다.

## 코드와 향후 배포

```text
App/       # 화면, 로컬 저장, JSON 이동
Widgets/   # AppIntent 설정, timeline, 위젯 엔트리
Shared/    # 앱 미리보기/위젯 디자인, 폰트
Resources/ # 라이선스, 개인정보 manifest, 아이콘
UITests/   # 실제 시뮬레이터 사용 흐름
../../packages/memento-core/ # Mac/iOS 공용 계산, 검증, 설정 계약
```

앱과 확장에 동일한 App Groups entitlement(`group.com.rlagudals95.mementomori`)가 필요합니다. 두 target은 `Config/LocalSigning.xcconfig`의 같은 Team을 상속합니다. 다른 계정으로 개발할 때는 자신이 등록할 수 있는 App Group ID로 `Shared/MementoMori.entitlements`와 `Shared/Design.swift`의 group 값을 함께 변경합니다. 실제 Team의 지원·서명이 확인되어야 설치할 수 있습니다. 공유 데이터는 기기에만 저장합니다.

앱과 위젯은 별도 target, Debug/Release 설정, 고정 bundle ID, 앱 아이콘, 폰트 라이선스, UserDefaults 사용 이유가 포함된 PrivacyInfo.xcprivacy를 갖춥니다. 공개 배포 시에는 배포 서명, App Store 정보/스크린샷/개인정보 안내, 실기기 및 지원 OS 검증을 추가하세요. 결제·계정·서버를 먼저 추가할 필요는 없습니다.

`MementoMori.xcodeproj`는 저장소에 포함되어 있어 별도 프로젝트 생성 도구 설치가 필요 없습니다. 소스 파일을 추가한 뒤 프로젝트를 재생성하려면 `python3 scripts/generate-ios-project.py`를 실행합니다. 재생성은 `Config/LocalSigning.xcconfig`를 변경하지 않아 개인 Team 설정을 유지합니다. 로컬 파일이 없어도 시뮬레이터와 CI 빌드는 가능합니다. 일반 빌드는 프로젝트를 재생성하지 않습니다.

서명 설정의 파일 분리는 [Apple의 build configuration 파일 방식](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)을 사용합니다. 인증서나 프로비저닝 파일은 이 설정 파일에 넣지 않습니다.

## Native time themes

Choose hourglass, record, book, tree rings, or one life from the dashboard or Settings. Tap the artwork for its interaction; the countdown keeps running. Selection persists and also applies to home-screen widgets. Widget artwork is static, while the existing live seconds text (including small-widget split rows) continues to update. Lock-screen layouts remain unchanged. Motion can be disabled and respects Reduce Motion.

Artwork lives in `packages/memento-core/Sources/MementoScenes`, shared with Mac. Regenerate the Xcode project with `python3 scripts/generate-ios-project.py` when needed.
