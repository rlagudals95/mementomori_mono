# 메멘토모리 for Mac

SwiftUI로 렌더링하고 AppKit의 비활성 floating panel로 다른 일반 창 위에 표시합니다. 서버, 브라우저, 웹뷰가 필요하지 않습니다. 메뉴바 모래시계에서 설정 및 표시/숨기기를 제어합니다.

저장소 루트에서:

```sh
npm ci
npm run build:mac
open artifacts/mac/MementoMori.app
npm run test:mac
```

- `Sources/MementoCore`: 계산, 유효성 검사, 설정 파일 계약. Foundation만 사용.
- `Sources/MementoMori`: 네이티브 UI, 창 관리, 로컬 저장.
- `Tests/MementoCoreTests`: 날짜/계산 및 웹과의 공통 계약 검증.
- `../../shared`: JavaScript/Swift 공통 fixture와 설정 예시.

사용 중인 앱을 종료한 후 다시 빌드하세요. 빌드 스크립트는 npm의 Pretendard 폰트를 앱에 포함하고 로컬 개발용 ad-hoc 서명을 합니다. 공개 배포용 Developer ID 서명과 공증은 별도 단계입니다. macOS 13 이상 타깃이며 기본 빌드는 빌드하는 Mac의 아키텍처를 사용합니다.
