import re
import sys

file_path = r"c:\Workspace\body_calendar\lib\features\workout\presentation\screens\exercise_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    text = f.read()

# Fix string literal at 1304
text = text.replace(
    "subtitle: Text('휴식: ${set.restTime.inSeconds}초, style: const TextStyle(color: Colors.grey)),",
    "subtitle: Text('휴식: ${set.restTime.inSeconds}초', style: const TextStyle(color: Colors.grey)),"
)

# Fix extra parenthesis at lines 1558, 1654, 1783 etc.
# These lines look exactly like:
#                                           ),
#                                           ),
#                                       ],
# Let's just fix the specific blocks. Since it's safer to use regex to find:
# "child: const Text('이후적용', style: TextStyle(color: AppColors.neonCyan, fontSize: 12)),\n                                          ),\n                                          ),"
# And replace with single "),"
pattern = r"(child: const Text\('이후적용', style: TextStyle\(color: AppColors\.neonCyan, fontSize: 12\)\),\n\s*\),\n)\s*\),"
text = re.sub(pattern, r"\1", text)

# There is also a duplicate block for rest time afterwards
# In step 816, lines 1784 to 1800 had a duplicate "이후적용" block.
# Let's remove the duplicate block completely.
duplicate_block = r"""                                          const SizedBox\(width: 4\),
                                          TextButton\(
                                            onPressed: \(\) {
                                              setState\(\(\) {
                                                final targetRest = _sets\[index\]\.restTime;
                                                for \(int i = index; i < _sets\.length; i\+\+\) {
                                                  if \(!_sets\[i\]\.isCompleted\) {
                                                    _sets\[i\] = _sets\[i\]\.copyWith\(restTime: targetRest\);
                                                  }
                                                }
                                                _saveSets\(\);
                                                if \(_currentSetIndex > 0 && index <= _currentSetIndex - 1\) {
                                                   context\.read<TimerBloc>\(\)\.add\(TimerDurationUpdated\(duration: targetRest\.inSeconds\)\);
                                                }
                                              }\);
                                              _showTopNotification\('이후 미완료 세트에 휴식 시간이 적용되었습니다\.'\);
                                            },
                                            child: const Text\('이후적용', style: TextStyle\(color: AppColors\.neonCyan, fontSize: 12\)\),
                                          \),"""
# Simply doing replacement 2->1 for the block if it exists twice
import logging
res = re.findall(duplicate_block, text)
print(f"Found duplicate block {len(res)} times")
if len(res) >= 2:
    # replace the exact second occurrence or replace 2 matches with 1 match
    text = re.sub(duplicate_block + r"\n*" + duplicate_block, duplicate_block, text)


with open(file_path, "w", encoding="utf-8") as f:
    f.write(text)

print("Done fixing syntax errors in Python script 2.")
