class HangulUtils {
  static const int _hangulBase = 0xAC00;
  static const int _hangulEnd = 0xD7A3;

  // 초성 리스트
  static const List<String> _initialConsonants = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
  ];

  /// 문자열을 초성으로 변환합니다.
  /// 한글이 아닌 문자는 그대로 유지됩니다.
  static String getChoseong(String text) {
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      int code = text.codeUnitAt(i);

      if (code >= _hangulBase && code <= _hangulEnd) {
        // 유니코드 공식: (초성 * 21 + 중성) * 28 + 종성 + 0xAC00
        // 초성 인덱스 = ((code - 0xAC00) / 28) / 21
        int initialIndex = ((code - _hangulBase) ~/ 28) ~/ 21;
        buffer.write(_initialConsonants[initialIndex]);
      } else {
        buffer.write(text[i]);
      }
    }

    return buffer.toString();
  }

  /// 검색어가 타겟 문자열에 포함되는지 확인합니다 (초성 검색 지원).
  /// [query] : 검색어 (예: "가슴", "ㄱㅅ")
  /// [target] : 대상 문자열 (예: "가슴 운동")
  static bool containsChoseong(String target, String query) {
    if (query.isEmpty) return true;
    
    // 1. 일반적인 포함 여부 확인
    if (target.contains(query)) return true;

    // 2. 초성으로 변환하여 확인
    String targetChoseong = getChoseong(target);
    // 검색어는 사용자가 이미 초성으로 입력했을 수 있으므로, 
    // 검색어도 초성 분리를 시도하되, 이미 초성이라면 그대로 유지됨.
    // 하지만 "ㄱㅅ"를 입력했을 때 getChoseong("ㄱㅅ")는 "ㄱㅅ"를 반환하므로 안전함.
    // 만약 "가슴"을 입력했다면 "ㄱㅅ"가 되어 비교됨.
    String queryChoseong = getChoseong(query);

    if (targetChoseong.contains(queryChoseong)) return true;

    // 3. 공백 무시 초성 검색
    String targetChoseongNoSpace = targetChoseong.replaceAll(' ', '');
    String queryChoseongNoSpace = queryChoseong.replaceAll(' ', '');

    return targetChoseongNoSpace.contains(queryChoseongNoSpace);
  }
}
