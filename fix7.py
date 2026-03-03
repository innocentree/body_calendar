import re
import sys

file_path = r"c:\Workspace\body_calendar\lib\features\workout\presentation\screens\exercise_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace("unit: ' ,", "unit: '회',")
text = text.replace("? '${_toDisplayWeight(set.weight).toStringAsFixed(1)}${_unitStr()} 횞 ${set.reps} \n", "? '${_toDisplayWeight(set.weight).toStringAsFixed(1)}${_unitStr()} × ${set.reps}회'\n")
text = text.replace("_prefs.getStringList('recorded_dates_${widget.exerciseName}')   [];", "_prefs.getStringList('recorded_dates_${widget.exerciseName}') ?? [];")
text = text.replace("final prevSetsJson = _prefs.getStringList(prevKey)   [];", "final prevSetsJson = _prefs.getStringList(prevKey) ?? [];")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(text)

print("Done fixing syntax errors in Python script 7.")
