import re
import sys

file_path = r"c:\Workspace\body_calendar\lib\features\workout\presentation\screens\exercise_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    text = f.read()

# Fix ?? at line 59
text = text.replace("double.tryParse(json['weight'].toString())   0.0", "double.tryParse(json['weight'].toString()) ?? 0.0")

# Fix missing quote at line 1292
text = text.replace("': '${set.reps} ,", "': '${set.reps}회',")
text = text.replace("? '${_toDisplayWeight(set.weight).toStringAsFixed(1)}${_unitStr()} × ${set.reps} '", "? '${_toDisplayWeight(set.weight).toStringAsFixed(1)}${_unitStr()} × ${set.reps}회'")
text = text.replace("? '${set.weight}kg × ${set.reps} '", "? '${set.weight}kg × ${set.reps}회'")
text = text.replace(": '${set.reps} ,", ": '${set.reps}회',")

# Fix EOF `}. `
text = re.sub(r'\}\.\s*\x00*', '}\n', text)
text = text.replace("}. ", "}\n")
text = text.replace("}\n \n \n", "}\n")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(text)

print("Done fixing syntax errors in Python script 3.")
