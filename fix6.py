import re
import sys

file_path = r"c:\Workspace\body_calendar\lib\features\workout\presentation\screens\exercise_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace("double.tryParse(controller.text)   initialValue", "double.tryParse(controller.text) ?? initialValue")
text = text.replace("toDouble()   initialValue;", "toDouble() ?? initialValue;")
text = text.replace("initialValue.toInt().toString() :", "initialValue.toInt().toString();")

# I will also quickly fix the null problem if it appears
text = text.replace("?? initialValue", "?? initialValue")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(text)

print("Done fixing syntax errors in Python script 6.")
