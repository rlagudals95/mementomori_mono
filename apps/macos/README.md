# 메멘토모리 for Mac

SwiftUI로 렌더링하고 AppKit의 비활성 floating panel로 다른 일반 창 위에 표시합니다. 서버, 브라우저, 웹뷰가 필요하지 않습니다. 메뉴바 모래시계에서 설정 및 표시/숨기기를 제어합니다.

저장소 루트에서:

```sh
npm ci
npm run build:mac
open artifacts/mac/MementoMori.app
npm run test:mac
```

- `../../packages/memento-core`: iOS와 공유하는 계산, 유효성 검사, 설정 파일 계약. Foundation만 사용.
- `Sources/MementoMori`: 네이티브 UI, 창 관리, 로컬 저장.
- `../../packages/memento-core/Tests`: 날짜/계산, 위젯 일정 및 웹과의 공통 계약 검증.
- `../../shared`: JavaScript/Swift 공통 fixture와 설정 예시.

사용 중인 앱을 종료한 후 다시 빌드하세요. 빌드 스크립트는 npm의 Pretendard 폰트를 앱에 포함하고 로컬 개발용 ad-hoc 서명을 합니다. 공개 배포용 Developer ID 서명과 공증은 별도 단계입니다. macOS 13 이상 타깃이며 기본 빌드는 빌드하는 Mac의 아키텍처를 사용합니다.

### 시간 테마

모래시계 / 레코드 / 인생의 책 / 나이테 / 한 번의 생명, 다섯 네이티브 테마를 지원합니다. 설정 또는 위젯 우클릭 메뉴에서 고릅니다. 그림을 클릭하면 작은 상호작용이 동작하며 초 카운트는 계속 흐릅니다. 테마 선택과 모션 설정은 이 Mac에 저장되고, 설정 JSON 내보내기에는 포함되지 않습니다. 시스템 동작 줄이기를 따릅니다.
