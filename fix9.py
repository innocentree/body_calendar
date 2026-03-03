import re
import sys

file_path = r"c:\Workspace\body_calendar\lib\features\workout\presentation\screens\exercise_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    text = f.read()

# Fix string literal at line 920
text = text.replace("child: const Text('?€ ),", "child: const Text('확인'),")

# Fix missing ?? at 516
text = text.replace(": double.tryParse(controller.text)?.toInt().toDouble()  \n                        initialValue;", ": double.tryParse(controller.text)?.toInt().toDouble() ?? \n                        initialValue;")
text = text.replace("toDouble()  \n", "toDouble() ?? \n")

# Remove null bytes at the very end
text = text.replace('\x00', '')

with open(file_path, "w", encoding="utf-8") as f:
    f.write(text)

print("Done fixing syntax errors in Python script 9.")
