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

## 클라우드 백업 / Google 로그인

이번에 추가한 구조는 **로컬 우선 + 필요할 때만 로그인**입니다.

- 평소에는 로그인 없이 로컬에 저장
- 사용자가 설정 화면에서 **클라우드 업로드 / 복원**을 눌렀을 때만 Google 로그인 요청
- 로그인 후에는 `Supabase`의 `user_sync_snapshots` 테이블에 전체 앱 스냅샷 저장
- 새 폰/재설치 후에도 같은 Google 계정으로 복원 가능

### 설정 방법

1. Supabase 프로젝트 생성
2. `supabase/cloud_sync_schema.sql` 실행
3. Supabase Auth에서 Google provider 활성화
4. Redirect URL에 아래 값 추가
   - `bodycalendar://login-callback/`
5. 앱 실행 시 dart-define 전달

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=SUPABASE_REDIRECT_URL=bodycalendar://login-callback/
```

### 참고

- 현재 클라우드에는 운동기록/세트/체형기록/루틴 등 앱의 `SharedPreferences` 스냅샷 전체를 올립니다.
- 즉시 제품화는 가능하지만, 장기적으로는 workout/day/set 단위 정규화 테이블로 분리하면 통계/분석이 더 편합니다.

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
