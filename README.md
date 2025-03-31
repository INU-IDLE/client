emulator: Pixel 6 Pro / android 12

pubspec has been edited 경고
1. reload all from disk 실행
2. build 에러 - 캐시 정리 // terminal에 실행
   - flutter clean (build 파일 정리)
   - flutter pub cache repair
3. 의존성 가져오기 // terminal
   - flutter pub get
4. flutter run // terminal

error: Target of URI doesn't exist: 'package:flutter/material.dart'
- 'pubspec.yaml'에서 'flutter packages get' 입력


lib/
├── models/
│   └── station_model.dart          # 역 정보를 저장하는 데이터 모델
├── screen/
│   ├── home_screen.dart            # 메인 화면
│   ├── search_screen.dart          # 검색 화면
│   ├── subway_map_screen.dart      # 지하철 노선도 화면
│   ├── route_result_screen.dart    # 경로 결과 화면
├── services/
│   └── station_service.dart        # JSON 데이터 처리 서비스
├── widgets/
