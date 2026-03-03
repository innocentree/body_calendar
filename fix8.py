import re
import sys

file_path = r"c:\Workspace\body_calendar\lib\features\workout\presentation\screens\exercise_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace(r'\(', '(')
text = text.replace(r'\)', ')')
text = text.replace(r'\+', '+')
text = text.replace(r'\[', '[')
text = text.replace(r'\]', ']')
text = text.replace(r'\.', '.')

with open(file_path, "w", encoding="utf-8") as f:
    f.write(text)

print("Done fixing backslashes")
