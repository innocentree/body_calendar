import re
import sys

file_path = r"c:\Workspace\body_calendar\lib\features\workout\presentation\screens\exercise_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    text = f.read()

# Fix ?? 
text = text.replace("final setsJson = _prefs.getStringList(key)   [];", "final setsJson = _prefs.getStringList(key) ?? [];")
text = text.replace("_recordedDates = _prefs.getStringList(key)   [];", "_recordedDates = _prefs.getStringList(key) ?? [];")
text = text.replace("weight: lastSet?.weight   _currentWeight,", "weight: lastSet?.weight ?? _currentWeight,")
text = text.replace("reps: lastSet?.reps   _currentReps,", "reps: lastSet?.reps ?? _currentReps,")
text = text.replace("restTime: lastSet?.restTime   _currentRestTime,", "restTime: lastSet?.restTime ?? _currentRestTime,")

text = text.replace("assistedWeight: lastSet?.assistedWeight   0.0,", "assistedWeight: lastSet?.assistedWeight ?? 0.0,")
text = text.replace("bodyWeight: lastSet?.bodyWeight   70.0,", "bodyWeight: lastSet?.bodyWeight ?? 70.0,")
text = text.replace("final value = _prefs.getString(key)   '';", "final value = _prefs.getString(key) ?? '';")

# Missing comma / parenthesis errors
text = text.replace("String _formatDuration(Duration d) {\n    final minutes = d.inMinutes.remainder(60)\n    final seconds = d.inSeconds.remainder(60)", 
                    "String _formatDuration(Duration d) {\n    final minutes = d.inMinutes.remainder(60);\n    final seconds = d.inSeconds.remainder(60);")
text = text.replace("final minutes = d.inMinutes.remainder(60)\n    final seconds = d.inSeconds.remainder(60)", "final minutes = d.inMinutes.remainder(60);\n    final seconds = d.inSeconds.remainder(60);")


with open(file_path, "w", encoding="utf-8") as f:
    f.write(text)

print("Done fixing syntax errors in Python script 5.")
