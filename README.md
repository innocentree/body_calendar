# Body Calendar

운동 기록, 세트 관리, 휴식 타이머, 신체 변화 추적을 한 앱에서 다루는 Flutter 프로젝트입니다.

## 이 앱이 하는 일

- 캘린더 기반 운동 기록 관리
- 하루 운동을 1/2/3회차로 나눠 기록
- 운동 종목 선택, 최근 운동/부위별 탐색, 커스텀 운동 추가
- 세트별 무게/횟수/휴식 시간 기록
- 세트 완료 시 휴식 타이머 및 오버레이 표시
- 종목별 통계(최대 중량, 1RM, 볼륨)
- 체중/체성분/신체 치수 변화 기록
- 데이터 백업/복원

## 현재 구조 요약

- `lib/main.dart`: 앱 시작점, DI/Bloc 초기화
- `lib/features/calendar`: 캘린더와 날짜별 운동 진입
- `lib/features/workout`: 운동 선택, 운동 기록, 세트 상세, 루틴, 통계
- `lib/features/profile`: 체중/체성분/치수 기록
- `lib/features/settings`: 테마, 단위, 백업/복원

## 데이터 저장 방식

현재 앱은 주로 `SharedPreferences`를 사용합니다.

주요 키 예시:
- `workouts_yyyy-MM-dd`: 날짜별 운동 목록
- `exercise_sets_{exerciseName}_{yyyy-MM-dd}`: 운동별 세트 기록
- `recorded_dates_{exerciseName}`: 해당 운동 기록 날짜 목록
- `body_change_record_{item}`: 체성분/치수 변화 기록

주의:
- 일부 repository 계층과 실제 화면 저장 구조가 완전히 통일되어 있지 않습니다.
- 후속 리팩터링 시 저장 경로 통합이 필요합니다.

## 개발 상태

로컬에서 저장소 클론과 git 연결은 완료되었습니다.

확인 완료:
- origin 연결
- master 브랜치 체크아웃
- 코드 구조 검토

미완료:
- Flutter SDK / Dart SDK가 현재 머신 PATH에 없어 `flutter pub get`, `flutter analyze`, 실행 검증은 아직 수행하지 못함

## 우선 개선 포인트

1. 저장 구조 통일 (`SharedPreferences` 직접 접근 vs Repository 혼재)
2. 대형 화면 파일 분리 (`exercise_detail_screen.dart`, `workout_screen.dart` 등)
3. 루트 임시 파일 정리 (`fix*.py`, `temp_orig*.dart`, `analyze.txt` 등)
4. format/analyze/test 자동화

## 최근 반영 사항

- 휴식 타이머 설정 변경 시 현재 돌아가는 타이머의 전체 기준 시간(`initialDuration`)이 즉시 갱신되도록 수정
- 운동 선택 화면에서 최근 사용 운동 정렬이 실제 날짜별 운동 기록(`workouts_yyyy-MM-dd`)을 우선 반영하도록 개선
