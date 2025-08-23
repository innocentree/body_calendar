import '../constants/app_constants.dart';

class ValidationUtils {
  // 이메일 검증
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegex.hasMatch(email);
  }

  // 비밀번호 검증
  static bool isValidPassword(String password) {
    // 최소 8자, 최소 하나의 문자, 하나의 숫자, 하나의 특수문자
    final passwordRegex = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  // 이름 검증
  static bool isValidName(String name) {
    return name.isNotEmpty && name.length <= AppConstants.maxNameLength;
  }

  // 설명 검증
  static bool isValidDescription(String description) {
    return description.length <= AppConstants.maxDescriptionLength;
  }

  // 숫자 검증
  static bool isValidNumber(String number) {
    if (number.isEmpty) return false;
    return double.tryParse(number) != null;
  }

  // 정수 검증
  static bool isValidInteger(String number) {
    if (number.isEmpty) return false;
    return int.tryParse(number) != null;
  }

  // 양수 검증
  static bool isValidPositiveNumber(String number) {
    if (!isValidNumber(number)) return false;
    return double.parse(number) > 0;
  }

  // 운동 시간 검증
  static bool isValidWorkoutDuration(int duration) {
    return duration > 0 && duration <= AppConstants.maxWorkoutDuration;
  }

  // 세트 수 검증
  static bool isValidSetCount(int count) {
    return count > 0 && count <= AppConstants.maxSetCount;
  }

  // 반복 횟수 검증
  static bool isValidRepCount(int count) {
    return count > 0 && count <= AppConstants.maxRepCount;
  }

  // 무게 검증
  static bool isValidWeight(double weight) {
    return weight > 0 && weight <= AppConstants.maxWeight;
  }

  // 날짜 검증
  static bool isValidDate(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now) || date.isAtSameMomentAs(now);
  }

  // 시작 시간과 종료 시간 검증
  static bool isValidTimeRange(DateTime start, DateTime end) {
    return start.isBefore(end);
  }

  // URL 검증
  static bool isValidUrl(String url) {
    final urlRegex = RegExp(
      r'^(http|https)://[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*([/?].*)?$',
    );
    return urlRegex.hasMatch(url);
  }

  // 전화번호 검증
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(
      r'^\+?[0-9]{10,15}$',
    );
    return phoneRegex.hasMatch(phone);
  }

  // 이미지 크기 검증
  static bool isValidImageSize(int size) {
    return size > 0 && size <= AppConstants.maxImageSize;
  }

  // 이미지 크기 검증
  static bool isValidImageDimensions(double width, double height) {
    return width > 0 &&
        width <= AppConstants.maxImageWidth &&
        height > 0 &&
        height <= AppConstants.maxImageHeight;
  }

  // 입력값 길이 검증
  static bool isValidLength(String value, int minLength, int maxLength) {
    return value.length >= minLength && value.length <= maxLength;
  }

  // 필수 입력값 검증
  static bool isRequired(String value) {
    return value.trim().isNotEmpty;
  }

  // 숫자 범위 검증
  static bool isInRange(num value, num min, num max) {
    return value >= min && value <= max;
  }

  // 이메일 도메인 검증
  static bool isValidEmailDomain(String email) {
    final domain = email.split('@').last;
    return domain.contains('.');
  }

  // 특수문자 포함 여부 검증
  static bool containsSpecialCharacters(String value) {
    final specialCharsRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    return specialCharsRegex.hasMatch(value);
  }

  // 대문자 포함 여부 검증
  static bool containsUpperCase(String value) {
    return value.contains(RegExp(r'[A-Z]'));
  }

  // 소문자 포함 여부 검증
  static bool containsLowerCase(String value) {
    return value.contains(RegExp(r'[a-z]'));
  }

  // 숫자 포함 여부 검증
  static bool containsNumber(String value) {
    return value.contains(RegExp(r'[0-9]'));
  }
} 