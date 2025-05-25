# RushCutter Frontend (Flutter)

## Overview
RushCutter 프론트엔드는 Flutter 기반으로 개발된 지하철 혼잡도 예측 및 길찾기 앱입니다.
Android Emulator (Pixel 6 Pro, Android 12) 기준으로 개발되었습니다.

---

## 1. 프로젝트 디렉터리 구조

```
lib/
├── main.dart                         # 앱 진입점, MultiProvider 설정 및 MainLayout 실행
│
├── data/                             # 정적 데이터 및 노선 매핑
│   ├── line_mapping.dart             # 노선 코드 → 이름/색상 매핑 정보
│   └── station_data.dart             # 역 정보 상수
│
├── layout/
│   └── main_layout.dart              # 하단 탭바 포함한 전체 레이아웃 관리
│
├── models/                           # 데이터 모델 클래스 정의
│   ├── congestion_data.dart          # 혼잡도 예측 결과 모델
│   ├── inquiry_data.dart             # 문의글/오류 신고 모델
│   ├── realtime_train.dart           # 실시간 열차 위치 정보 모델
│   ├── saved_route.dart              # 저장된 경로 정보 모델
│   ├── station.dart                  # SVG 기반 지하철 역 좌표 모델
│   ├── station_api.dart              # API 기반 역 정보 모델
│   └── train_arrival.dart            # 도착 정보 모델
│
├── providers/                        # 상태 관리 Provider 클래스
│   ├── saved_route_provider.dart     # 즐겨찾는 경로 상태 관리
│   └── station_provider.dart         # 출발/도착역 상태 관리
│
├── screen/                           # 주요 화면 (탭바 포함)
│   ├── home_screen.dart              # SVG 지도 + 지도 터치 기능
│   ├── congestion_prediction_screen.dart  # 혼잡도 예측 화면
│   ├── route_result_screen.dart      # 경로 탐색 결과
│   ├── saved_routes_screen.dart      # 저장된 경로 목록
│   ├── my_page_screen.dart           # 마이페이지
│   ├── news_screen.dart              # 공지사항 / 이벤트
│   ├── real_time_screen.dart         # 실시간 지하철 도착 정보
│   ├── real_time_bottom_sheet.dart   # 혼잡도 상세 모달
│   ├── search_screen.dart            # 역 검색 화면
│   └── bottom_category_bar.dart      # 하단 탭바 구성 요소
│
├── screen2/                          # 서브 화면
│   ├── subway_line_select_screen.dart   # 호선 선택
│   ├── station_select_screen.dart       # 역 목록
│   ├── subway_timetable_screen.dart    # 시간표 조회
│   ├── inquiry_list_screen.dart        # 문의글 리스트
│   ├── inquiry_post_screen.dart        # 문의글 작성/수정
│   ├── my_info_screen.dart             # 내 정보 수정
│   ├── notification_screen.dart        # 알림함
│   ├── news_hidden_inquiry_screen.dart # 공지/문의 작성
│   └── saved_routes_screen.dart        # 재사용 저장 경로 목록
│
├── services/                         # API 통신 및 처리 로직
│   ├── api_service.dart              # 공통 API 설정
│   ├── api_station_service.dart      # 역 이름 → fr_code 변환
│   ├── path_service.dart             # 경로 탐색 API
│   ├── realtime_service.dart         # 실시간 위치 API
│   └── station_service.dart          # 좌표 기반 역 탐색
│
├── widgets/                          # 재사용 가능한 위젯 모음
│   ├── station_component.dart        # 전체 역 감지기
│   ├── station_map_painter.dart      # 역 위치 그리는 Painter
│   ├── station_button.dart           # 지도 위 역 원형 버튼
│   ├── category_button.dart          # 필터 버튼 (공지/이벤트)
│   └── AlertDialog.dart              # 커스텀 다이얼로그
│
assets/
├── images/                           # 지도 이미지, 좌표 JSON
├── completed.py                      # (선택) 전처리 스크립트
└── station_info.json                 # 역 정보 JSON

pubspec.yaml        # Flutter 프로젝트 메타 정보 및 의존성 관리
pubspec.lock        # 실제 설치된 패키지 버전 고정 파일
.gitignore          # Git 추적 제외 파일 설정
```

---

## 2. 실행 방법

### 2.1 초기 세팅
Flutter 프로젝트를 처음 실행할 경우 아래 명령어를 차례대로 실행합니다:
```sh
   flutter pub get
   flutter emulators --launch pixel_6_pro
   flutter run
```

---

### 2.2 pubspec.yaml 변경 시 경고 해결
pubspec.yaml has been edited 경고가 발생했을 경우:
VSCode 또는 Android Studio에서 "Reload all from disk" 클릭

아래 명령어 순서대로 실행:

```sh
flutter clean
flutter pub cache repair
flutter pub get
flutter run
```

---

## 3. Troubleshooting

❌ Target of URI doesn't exist: 'package:flutter/material.dart'
원인: 의존성 패키지가 설치되지 않음
해결 방법: 아래 명령어 실행

```sh
flutter pub get
```

---

## 4. 주요 기능 요약


| 기능             | 설명 |
|------------------|------|
| 지하철 노선도        | 제작 지하철 노선도 및 터치 감지 기능 |
| 혼잡도 예측        | 요일/시각/노선 기반으로 칸별 예측 혼잡도 시각화 |
| 경로 탐색         | 출발지/도착지 입력 시 최단 거리 또는 최소 환승 경로 탐색 |
| 시간표 조회        | 요일/급행 조건 기반 지하철 도착 시각 조회 |
| 즐겨찾기 경로 저장 | 자주 쓰는 경로를 저장하고 순서를 변경할 수 있음 (드래그 앤 드롭) |
| 문의/오류 작성     | 문의글 작성 기능 (비공개/비밀번호 기능 포함) |
| 실시간 위치      | 도착 예정 열차 정보 + 현재 위치 및 혼잡도 예측 표시 |


---
