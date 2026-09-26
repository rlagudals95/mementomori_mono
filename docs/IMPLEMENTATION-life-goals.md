# 미루고 있는 삶: 구현 계획

작성: 2026-09-26. 기획 기준은 [PRD](PRD-mementomori-life-goals.md). 이번 변경은 문서이며 기능 구현·앱 재설치는 수행하지 않습니다.

## 실행 기본안

- iOS에서 먼저 흐름을 만들고 같은 도메인 로직을 Mac에 연결합니다.
- 현재 `packages/memento-core`를 확장합니다. UIKit·AppKit·SwiftUI·WidgetKit은 공용 package에 넣지 않습니다.
- 기존 설정·프로필·계산 fixture와 bundle ID, 개인 서명 파일을 유지합니다.
- 목표 기록은 별도 계약/파일입니다. 웹의 기존 설정 가져오기는 그대로 유지합니다.
- 기본 UI에 한 번에 활성 목표 하나와 그 다음 행동 하나만 노출합니다.
- 기기 간 동기화·웹 목표 UI·Android·상용 배포는 이번 범위에서 수행하지 않습니다.

## 코드 경계와 파일 책임

| 파일 | 책임 |
| --- | --- |
| `packages/memento-core/Sources/MementoCore/Goals/GoalModels.swift` | Codable 모델, 상태·이유 enum, 텍스트 한도 |
| `packages/memento-core/Sources/MementoCore/Goals/GoalValidation.swift` | ID·참조·상태·날짜·한도 검증 |
| `packages/memento-core/Sources/MementoCore/Goals/GoalCommands.swift` | 목표와 행동의 상태 전환, 이력 생성 |
| `packages/memento-core/Sources/MementoCore/Goals/GoalsFile.swift` | 별도 JSON 계약의 읽기·쓰기 |
| `packages/memento-core/Sources/MementoCore/Goals/GoalsRepository.swift` | 주 저장·백업·복구, 임시 디렉터리로 테스트 가능한 IO |
| `packages/memento-core/Sources/MementoCore/Goals/GoalPresentation.swift` | 현재 행동 요약·주간 돌아보기 계산 |
| `apps/ios/App/Goals/GoalStore.swift` | MainActor 화면 상태, 저장 후 publish, 위젯 요약 재시도 |
| `apps/ios/App/Goals/GoalsListView.swift` | 목록과 상태별 구분 |
| `apps/ios/App/Goals/GoalEditorView.swift` | 목표 제목·이유, 활성화와 다음 행동 작성 |
| `apps/ios/App/Goals/GoalDetailView.swift` | 다음 행동·이력·완료·일시 중단 |
| `apps/ios/App/Goals/GoalReviewView.swift` | 실행 기록·막힌 이유·재조정·주간 돌아보기 |
| `apps/ios/App/Goals/GoalHistoryView.swift` | 날짜별 경험 기록 |
| `apps/ios/App/Goals/GoalsDocument.swift` | 전용 JSON 내보내기·교체 확인 |
| `apps/ios/Shared/GoalWidgetBridge.swift` | App Group 요약 캐시, deep link 생성·파싱 |
| `apps/macos/Sources/MementoMori/Goals/GoalStore.swift` | Mac 상태와 공용 repository 연결 |
| `apps/macos/Sources/MementoMori/Goals/GoalsWindowView.swift` | 입력 가능한 관리 창과 목록·상세·기록 탐색 |
| `apps/macos/Sources/MementoMori/Goals/GoalEditorView.swift` | Mac 목표·행동 작성 폼 |
| `apps/macos/Sources/MementoMori/Goals/GoalReviewView.swift` | Mac 실행·재조정·경험 작성 폼 |
| `shared/contracts/life-goals-v1.schema.json` | Android 등에도 사용할 목표 계약 |
| `shared/contracts/life-goals-example.json` | 합성 목표·행동·돌아보기 예시 |
| `shared/fixtures/goal-cases.json` | 동일 명령에 대한 상태 전환 기대 결과 |

공통 파일은 기능 디렉터리 안에서 나눕니다. 기존 `Life.swift`에 목표 저장소나 화면 로직을 합치지 않습니다. iOS 새 하위 폴더는 현재 프로젝트 생성기의 `glob('App/*.swift')`에 포함되지 않으므로 생성기를 `rglob('*.swift')` 방식으로 수정해야 합니다. Swift Package Manager의 Mac/core 소스 탐색은 기존 target 경계를 유지합니다.

## 1단계: 계약과 상태 전환

수정/추가: 공용 Goals 모델·검증·명령·계약·fixture와 `Tests/MementoCoreTests/Goals/GoalCommandsTests.swift`, `GoalValidationTests.swift`.

- [ ] PRD의 모델과 enum을 정의하고 기존 SettingsFile은 변경하지 않는다.
- [ ] 시간과 UUID를 명령 입력으로 전달하여 테스트에서 고정할 수 있게 한다.
- [ ] 새 목표 저장, 활성화, 다음 행동 생성, 실행 완료, 재조정, 일시 중단, 재개, 목표 완료, 내려놓기, 재시작, 영구 삭제 명령을 구현한다.
- [ ] 외부 호출은 불변 workspace를 받아 새 workspace를 반환한다. 오류면 원본이 바뀌지 않는다.
- [ ] 다른 목표 활성화는 사용자 확인을 받은 단일 명령으로 이전 active를 paused로 바꾸고 새 목표와 행동을 활성화한다.
- [ ] 재조정은 이전 행동 종료·새 행동 생성·돌아보기 추가를 한 명령으로 수행한다.
- [ ] 목표 완료와 내려놓기는 미완료 행동을 cancelled로 닫는다. 자동 completed 전환은 금지한다.
- [ ] 완료된 행동에 완료 명령을 다시 보내면 같은 상태를 반환하여 중복 기록을 방지한다.
- [ ] 과거 review의 제목·이유·행동 문장은 이후 목표 수정에 영향을 받지 않도록 snapshot을 저장한다.

검증 사례: active 목표 두 개 거부; 목표별 pending 두 개 거부; 중복 ID/없는 참조 거부; 잘못된 계획일 거부; 공백 제목 거부; pause/resume이 pending을 잃지 않음; 재조정이 이전 행동을 보존; action 완료가 goal 완료로 번지지 않음; 재시작이 과거 종료 기록을 보존; 삭제가 연결 기록만 지움; 지원하지 않는 버전과 한도 초과 거부.

명령: `npm run test:core`. 완료 기준: 기존 계산/계약 테스트와 새 상태 전환 테스트 모두 통과. 계약 예시를 Swift로 읽고 쓰고 다시 읽었을 때 동일한 의미를 유지한다.

## 2단계: 파일 저장과 복구

추가: GoalsFile·GoalsRepository, `Tests/MementoCoreTests/Goals/GoalsRepositoryTests.swift`. 수정: 공통 계약 README.

- [ ] repository 생성 시 디렉터리 URL을 받는다. 테스트는 고유 임시 디렉터리를 사용한다.
- [ ] `life-goals.v1.json`을 읽고 버전·크기·workspace를 검증한다.
- [ ] 파일이 처음부터 없을 때만 빈 workspace를 반환한다. 읽기 실패를 빈 목표로 취급하지 않는다.
- [ ] 저장 전에 새 workspace를 검증한다. 직전 유효본을 `.backup`에 원자적으로 저장한 뒤 새 주 파일을 원자적으로 쓴다. 최초 저장은 새 데이터로 백업을 만든다.
- [ ] 저장 실패는 throw하고 화면이 이전 상태를 유지하도록 한다. 호출자는 `try?`로 무시하지 않는다.
- [ ] 손상/지원하지 않는 버전에서는 원본 파일을 유지하고 복구 상태를 반환한다. 백업 복원·새 파일 가져오기·사용자 확인 후 초기화 중 선택한다. 교체 전 원본 바이트를 `recovery-<UUID>.json`에 보존하고 보존 실패 시 교체를 중단한다.
- [ ] 새 데이터를 인코딩한 뒤에도 5MiB 한도를 검사한다. 한도를 넘으면 원본·백업·화면 상태를 유지하고 기록 내보내기/정리 안내를 표시한다.
- [ ] 가져오기는 파싱·검증·사용자 확인·기존 유효 데이터 백업·전체 교체 순서로 수행한다. 자동 병합하지 않는다.
- [ ] 내보내기 파일은 `mementomori-life-goals.json`. 기존 `mementomori-settings.json`과 구분한다.

검증 사례: 재실행 복원; 손상 원본 보존; 유효 백업 복원; 손상 백업 안내; 알 수 없는 버전 보존; 파일 크기 제한; IO 실패 때 화면 상태 미변경; 취소한 import 미변경; 교체 후 이전본 복구 가능. 읽기와 쓰기 오류는 테스트용 IO 주입으로 재현하고 실제 기기 파일을 훼손하지 않는다.

완료 기준: 임시 저장소 테스트 통과, 기존 `settings.v1`과 설정 import/export가 바뀌지 않음.

## 3단계: iOS 목표·행동·기록 흐름

수정: `apps/ios/App/MementoMoriApp.swift`, `HomeView.swift`, `SettingsView.swift`, `scripts/generate-ios-project.py`. 추가: iOS Goals 화면·GoalStore·GoalsDocument, `apps/ios/UITests/GoalFlowUITests.swift`.

- [ ] App에 독립 GoalStore를 StateObject로 추가한다. 기존 프로필 Store는 유지한다.
- [ ] 프로젝트 생성기가 App 하위 Swift 파일을 포함하게 수정하고 재생성한다. ignored LocalSigning.xcconfig가 그대로인지 확인한다.
- [ ] 지금/삶의 목록/기록 탐색을 구성한다. 기존 카운트다운·주간 달력·설정·위젯 안내를 보존한다.
- [ ] 생년월일이 없는 상태에서도 목록 작성과 다음 행동을 사용할 수 있게 한다.
- [ ] 목표 보관에는 제목만, 활성화에는 이유와 다음 행동을 받는다. 기존 active 교체 확인을 표시한다.
- [ ] 현재 행동에 실행/재조정 흐름을 연결한다. 완료 기록 후 목표 완료 또는 다음 행동을 사용자에게 선택하게 한다.
- [ ] 막힌 이유에 맞는 도움말, 그대로 유지/새 행동/잠시 멈춤/내려놓기를 제공한다.
- [ ] goal 완료·재시작·영구 삭제의 확인과 기록 화면을 만든다.
- [ ] 기존 `오늘의 문장`은 유지하며 활성 행동이 있는 지금 카드에서는 행동을 우선 표시한다.
- [ ] 저장 오류·손상 파일 복구 안내를 공통 상태에서 표시한다.
- [ ] 시간 설정 초기화와 목표 기록 초기화를 분리하고 확인 문구를 변경한다.

UI 테스트는 앱에 주입한 합성 GoalStore/고유 테스트 디렉터리로 수행한다. 실제 사용자 파일과 App Group 목표 요약을 초기화하는 테스트 경로를 만들지 않는다. 합성 DOB는 기존과 동일하게 사용한다.

필수 흐름: 목표 생성→활성화→행동 완료→다음 행동→앱 재실행 복원; 이유 선택→행동 재조정→이전 이력 확인; pause/resume; 다른 목표로 전환; goal 완료/release/restart; 설정 초기화 이후 목표 유지. 파일 읽기 오류 화면은 테스트용 저장소에서 재현한다.

명령: `npm run test:core`, `npm run build:ios`, `npm run test:ios`. 완료 기준: 새 흐름과 기존 카운트다운 UI 테스트 통과. 긴 한글/영문/emoji, 큰 글자 설정, 키보드 열린 폼에서 저장 버튼을 확인한다.

## 4단계: 위젯 요약과 목표 이동

수정: `apps/ios/Widgets/MementoWidgets.swift`, `apps/ios/Shared/Design.swift`, `HomeView.swift`, GoalStore. 추가: GoalWidgetBridge와 공용 GoalPresentation, `GoalPresentationTests.swift`.

- [ ] App Group의 별도 `goal-widget.v1` 요약 캐시를 추가한다. profile의 `settings.v1`과 섞지 않는다.
- [ ] canonical 저장 성공 후 캐시를 쓰고 timeline 갱신을 요청한다. 캐시 실패는 원본 저장 실패로 처리하지 않는다.
- [ ] 앱 활성화·가져오기·삭제·재조정·완료 때 요약을 다시 계산한다. 실패한 캐시 쓰기는 앱 활성화 때 재시도한다.
- [ ] 앱 프로필을 따르는 위젯에만 개인 행동을 표시한다. 개별 생년월일 override 위젯의 문장은 유지한다.
- [ ] 중간 위젯은 기존 하단 문장 자리에 행동을 넣는다. 작은 위젯의 두 줄 초와 폰트·여백을 유지한다.
- [ ] URL은 `mementomori://goals/<UUID>`로 생성/파싱한다. cold launch와 warm launch 모두 해당 목표를 연다.
- [ ] 잘못된 UUID, 없는/삭제된 목표, 현재 활성 목표가 바뀐 오래된 링크는 목록으로 이동한다. 완료된 목표는 남아 있으면 상세 이력을 연다.
- [ ] 기존 `mementomori://widget-help` 동작을 보존한다.
- [ ] OS widget 갱신을 기다려 실제 small/medium 화면을 캡처하고 숫자의 초 갱신을 검사한다. widget을 앱에서 편집 가능한 쓰기 인터페이스로 만들지 않는다.

검증: 기존 위젯 UI 테스트 유지; 중간 위젯 행동 문장 노출; 탭 후 목표 상세; pending 종료 후 올바른 fallback; old link 복구; 개별 프로필 위젯이 개인 목표를 노출하지 않음. deep link URL 입력은 부작용 없이 검증한다.

완료 기준: 숫자 전체 자릿수·초 갱신·상하 여백 회귀가 없고 iPhone 설치로 확인. 사용자 설정은 기존과 같은 bundle ID에 유지한다.

## 5단계: 주간 돌아보기

수정: GoalPresentation·iOS GoalReviewView·지금 화면. 테스트: `GoalPresentationTests.swift`.

- [ ] firstActivatedAt과 가장 최근 review/action 완료 시각 중 최신 값을 현지 달력 날짜로 변환한다.
- [ ] 활성 목표가 있고 해당 날짜부터 현지 달력 7일 이상 지났을 때 지금 화면에 돌아보기 카드를 표시한다.
- [ ] 질문은 실행 여부/막힌 이유/다음 행동 중 현재 상태에 필요한 것만 보여준다.
- [ ] 사용자가 돌아보기를 완료하면 checkin review를 기록한다. 단순 화면 닫기는 review로 기록하지 않는다.
- [ ] 다음 실행 때도 필요하면 카드를 보이되 알림·badge·자동 화면 전환은 추가하지 않는다.

검증: 6일에는 안 보임, 7일에 보임, 최근 실행/돌아보기 후 안 보임, pause/완료 목표에서는 안 보임, DST와 시간대 이동, 시계가 과거로 이동해도 반복 기록하지 않음. 7×86400초 대신 달력 일수로 계산한다.

완료 기준: 날짜 테스트 통과, 실행 직후 질문을 반복하지 않음.

## 6단계: Mac 관리 창과 작은 창 연결

수정: `apps/macos/Sources/MementoMori/Main.swift`, `Views.swift`, `Store.swift`. 추가: Mac Goals 파일. 기존 FloatingPanel을 입력 가능한 창으로 바꾸지 않는다.

- [ ] AppDelegate에 독립 GoalStore와 일반 NSWindow 기반 관리 창을 추가한다.
- [ ] 메뉴바에 `지금의 한 걸음…`, `삶의 목록…`, `살아낸 기록…` 진입을 추가한다.
- [ ] 관리 창에서 iOS와 같은 명령·저장·import/export를 사용한다. 테마·위치·크기 저장 키는 유지한다.
- [ ] 충분한 높이의 작은 창 하단 문장을 현재 행동으로 대체하고 명시적인 목표 열기 버튼을 제공한다.
- [ ] 한 줄형·최소 창 크기에는 숫자를 유지한다. 관리 창은 메뉴로 열 수 있게 한다.
- [ ] drag handle·resize handle과 목표 열기 버튼의 hit area를 분리한다.
- [ ] 목표 작성·실행·재조정·일시 중단·재개·완료·기록 조회·파일 이동을 구현한다.
- [ ] Mac의 시간 설정 초기화도 목표 기록을 유지하게 설명한다.

명령: `npm run test:core`, `npm run build:mac`. 수동 검증: 키보드 입력·복사/붙여넣기, 입력 포커스, 창 닫고 다시 열기, 앱 재실행, 190×84·190×190·360×190 및 가로/세로 드래그, 다크/라이트, 목표 클릭과 창 이동 충돌, 설정 JSON/목표 JSON 교차 오입력 거부.

완료 기준: Mac에서 전체 흐름을 독립 실행할 수 있고 작은 창의 크기/위치/초 갱신이 유지된다. `test:mac`는 현재 core 테스트의 별칭이므로 Mac UI 검증으로 보고하지 않는다.

## 7단계: 통합 검증·개인 실험 준비

수정: README, iOS/Mac README, PLATFORMS, ARCHITECTURE, VERIFICATION, 공통 디자인 문구. PRODUCT의 기존 MVP 내용은 이 PRD와 현재 플랫폼 현황을 명시적으로 구분한다.

- [ ] 합성 목표 JSON을 iOS에서 내보내고 Mac에서 가져온 뒤 반대 방향도 검증한다.
- [ ] import 전체 교체 안내, 취소, 교체 전 백업 복원, 기존 설정 파일의 독립성을 확인한다.
- [ ] 실제 사용자 생년월일/목표/기록/Team ID가 커밋 대상에 없는지 확인한다.
- [ ] Mac 앱을 종료한 뒤 `npm run test:all`을 실행한다. 통과 후 다시 실행한다.
- [ ] 로컬 signing 설정으로 실기기 build, 같은 앱에 update 설치, 실제 위젯과 deep link를 확인한다.
- [ ] docs에 자동 테스트/수동 Mac 검사/실기기 검사 결과를 구분하여 기록한다.
- [ ] 사용자의 주 사용 기기와 14일 관찰 방법, 무료 iPhone 재설치 시점을 정한다.
- [ ] 개인 사용에서 실제 실행·다음 행동·막힘·재조정 사례를 기록한다. 고객 리텐션 증명으로 확대 해석하지 않는다.

완료 기준: 핵심 행동 흐름, 데이터 보존, 위젯 회귀, 파일 이동·복구가 검증되어 개인 사용을 시작할 수 있음. 상용 배포는 하지 않음.

## 병목과 순서 판단

가장 큰 불확실성은 상태 전환/복구와 위젯 공간입니다. 첫 2단계에서 데이터 보존을 해결한 뒤 화면을 추가합니다. iOS에서 먼저 끝까지 사용할 수 있게 만들고 Mac UI를 연결하므로, 플랫폼 전체를 동시에 고치는 일을 피합니다.

각 단계는 검증 가능한 단위로 나누어 커밋합니다. 작업 중 사용자 수정·개인 signing 설정을 보존합니다. 개발 시간은 실제 작업 속도를 확인한 뒤 추정하며 아직 날짜나 소요 일수를 약속하지 않습니다.

## 시작 가능한 다음 작업

1단계의 공통 모델·계약·상태 전환 테스트부터 시작합니다. 이 단계는 화면을 바꾸지 않으며, 성공하면 저장소와 iOS 흐름을 이어서 구현할 수 있습니다.
