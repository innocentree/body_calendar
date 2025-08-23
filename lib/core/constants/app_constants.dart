class AppConstants {
  // 앱 정보
  static const String appName = 'Body Calendar';
  static const String appVersion = '1.0.0';
  
  // 데이터베이스
  static const String dbName = 'body_calendar.db';
  static const int dbVersion = 1;
  
  // 공유 프리퍼런스 키
  static const String keyThemeMode = 'theme_mode';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyUserProfile = 'user_profile';
  
  // 애니메이션 지속 시간
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);
  
  // 페이지네이션
  static const int defaultPageSize = 20;
  
  // 날짜 포맷
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  
  // 유효성 검사
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  
  // 이미지
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1080;
  
  // 운동 관련
  static const int maxWorkoutDuration = 24 * 60; // 24시간 (분 단위)
  static const int maxSetCount = 100;
  static const int maxRepCount = 1000;
  static const double maxWeight = 1000.0; // kg
  
  // 차트
  static const int maxChartDataPoints = 30; // 최대 30일 데이터 표시
  
  // 알림
  static const int maxNotificationCount = 10;
  static const Duration notificationDuration = Duration(seconds: 3);
  
  // 캐시
  static const Duration cacheDuration = Duration(days: 7);
  
  // 에러 메시지
  static const String errorGeneric = '오류가 발생했습니다. 다시 시도해주세요.';
  static const String errorNetwork = '네트워크 연결을 확인해주세요.';
  static const String errorServer = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  static const String errorAuth = '로그인이 필요합니다.';
  static const String errorPermission = '권한이 없습니다.';
  static const String errorValidation = '입력값을 확인해주세요.';
  
  // 성공 메시지
  static const String successSave = '저장되었습니다.';
  static const String successDelete = '삭제되었습니다.';
  static const String successUpdate = '수정되었습니다.';
  
  // 확인 메시지
  static const String confirmDelete = '정말 삭제하시겠습니까?';
  static const String confirmLogout = '로그아웃 하시겠습니까?';
  static const String confirmDiscard = '작성 중인 내용이 있습니다. 정말 나가시겠습니까?';
} 