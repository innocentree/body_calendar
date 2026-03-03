import re
import sys

file_path = r"c:\Workspace\body_calendar\lib\features\workout\presentation\screens\exercise_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    text = f.read()

# Fix ?? operators that turned into 3 spaces
text = text.replace("weight   this.weight", "weight ?? this.weight")
text = text.replace("reps   this.reps", "reps ?? this.reps")
text = text.replace("restTime   this.restTime", "restTime ?? this.restTime")
text = text.replace("startTime   this.startTime", "startTime ?? this.startTime")
text = text.replace("endTime   this.endTime", "endTime ?? this.endTime")
text = text.replace("isCompleted   this.isCompleted", "isCompleted ?? this.isCompleted")
text = text.replace("bodyWeight   this.bodyWeight", "bodyWeight ?? this.bodyWeight")
text = text.replace("assistedWeight   this.assistedWeight", "assistedWeight ?? this.assistedWeight")

text = text.replace("(_exercise?.needsWeight   true)", "(_exercise?.needsWeight ?? true)")
text = text.replace("!(_exercise?.isAssisted   false)", "!(_exercise?.isAssisted ?? false)")

text = text.replace(".assistedWeight   0.0", ".assistedWeight ?? 0.0")
text = text.replace(".bodyWeight   70.0", ".bodyWeight ?? 70.0")

# Fix duplicate "이후적용" block for rest time (lines 1784 to 1800 roughly)
duplicate_rest_time = """                                          const SizedBox(width: 4),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                final targetRest = _sets[index].restTime;
                                                for (int i = index; i < _sets.length; i++) {
                                                  if (!_sets[i].isCompleted) {
                                                    _sets[i] = _sets[i].copyWith(restTime: targetRest);
                                                  }
                                                }
                                                _saveSets();
                                                if (_currentSetIndex > 0 && index <= _currentSetIndex - 1) {
                                                   context.read<TimerBloc>().add(TimerDurationUpdated(duration: targetRest.inSeconds));
                                                }
                                              });
                                              _showTopNotification('이후 미완료 세트에 휴식 시간이 적용되었습니다.');
                                            },
                                            child: const Text('이후적용', style: TextStyle(color: AppColors.neonCyan, fontSize: 12)),
                                          ),"""
# I will just write a regex to clean up duplicate consecutive blocks for "이후적용" if needed.
# Since it's easier to use multi_replace, I will just let flutter test run after this py fix.

with open(file_path, "w", encoding="utf-8") as f:
    f.write(text)

print("Done fixing Dart file syntaxes in Python script.")
