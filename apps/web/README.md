# 메멘토모리 웹

Vite + JavaScript/CSS. 웹 상세 화면, 위젯 미리보기, 지원 브라우저의 작은 창, 오프라인 캐시를 제공합니다.

저장소 루트에서 `npm ci` 후:

```sh
npm run dev
npm run build
npm run preview -- --port 4173
npm test
npm run test:browser
```

배포 파일은 `apps/web/dist/`입니다. HTTPS 정적 호스팅에 올리며 서버·DB·API 키가 필요 없습니다. `public/`은 Vite 정적 파일, `src/`는 화면 및 계산, `tests/`는 단위·브라우저 테스트입니다. 공통 데이터 계약과 계산 fixture는 루트 `shared/`에 있습니다.

실제 휴대폰 위젯은 아직 구현하지 않았습니다. 지원되는 데스크톱 Chrome의 작은 창은 원래 탭을 열어두어야 합니다. 자세한 사용 범위는 루트 README를 확인하세요.
