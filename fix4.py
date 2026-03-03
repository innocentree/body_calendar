import re
import sys

file_path = r"c:\Workspace\body_calendar\lib\features\workout\presentation\screens\exercise_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    text = f.read()

# Fix ?? for _isLbs
text = text.replace("_isLbs = _prefs.getBool('use_lbs')   false;", "_isLbs = _prefs.getBool('use_lbs') ?? false;")

# Fix ?? for setsJson
text = text.replace("final setsJson = _prefs.getStringList(key)   [];", "final setsJson = _prefs.getStringList(key) ?? [];")

# Fix the displaced _runningBest1RM assignment
old_block = """    _runningBestMaxWeight = bestMaxWeight;
  }

  double _toDisplayWeight(double kg) => _isLbs ? kg * 2.20462 : kg;
  double _toStorageWeight(double displayed) => _isLbs ? displayed / 2.20462 : displayed;
  String _unitStr() => _isLbs ? 'lb' : 'kg';

  void _toggleUnit() {
    setState(() {
      _isLbs = !_isLbs;
      _prefs.setBool('use_lbs', _isLbs);
    });
  }
  _runningBest1RM = bestMax1RM;
    _runningBestVolume = bestTotalVolume;
    
    // Also calculate historical best volume (excluding today) to see when we cross it?
    // Actually _runningBestVolume already includes today's current total.
    // If we add a set, volume increases.
  }"""

new_block = """    _runningBestMaxWeight = bestMaxWeight;
    _runningBest1RM = bestMax1RM;
    _runningBestVolume = bestTotalVolume;
    
    // Also calculate historical best volume (excluding today) to see when we cross it?
    // Actually _runningBestVolume already includes today's current total.
    // If we add a set, volume increases.
  }

  double _toDisplayWeight(double kg) => _isLbs ? kg * 2.20462 : kg;
  double _toStorageWeight(double displayed) => _isLbs ? displayed / 2.20462 : displayed;
  String _unitStr() => _isLbs ? 'lb' : 'kg';

  void _toggleUnit() {
    setState(() {
      _isLbs = !_isLbs;
      _prefs.setBool('use_lbs', _isLbs);
    });
  }"""

text = text.replace(old_block, new_block)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(text)

print("Done fixing syntax errors in Python script 4.")
