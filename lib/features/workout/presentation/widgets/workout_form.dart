import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:body_calendar/features/workout/domain/models/workout.dart';
import 'package:body_calendar/features/workout/presentation/bloc/workout_bloc.dart';

class WorkoutForm extends StatefulWidget {
  final Workout? workout;

  const WorkoutForm({
    super.key,
    this.workout,
  });

  @override
  State<WorkoutForm> createState() => _WorkoutFormState();
}

class _WorkoutFormState extends State<WorkoutForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _exercises = <Exercise>[];
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _nameController.text = widget.workout!.name;
      _exercises.addAll(widget.workout!.exercises);
      _duration = widget.workout!.duration;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) => ExerciseDialog(
        onSave: (exercise) {
          setState(() {
            _exercises.add(exercise);
          });
        },
      ),
    );
  }

  void _saveWorkout() {
    if (_formKey.currentState!.validate()) {
      final workout = Workout(
        id: widget.workout?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        exercises: _exercises,
        duration: _duration,
        date: widget.workout?.date ?? DateTime.now(),
      );

      if (widget.workout == null) {
        context.read<WorkoutBloc>().add(AddWorkout(workout));
      } else {
        context.read<WorkoutBloc>().add(UpdateWorkout(workout));
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.workout == null ? '새 운동 추가' : '운동 수정',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '운동 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '운동 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('운동 시간: '),
                  Text('$_duration분'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (_duration > 0) {
                        setState(() {
                          _duration--;
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _duration++;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('운동 추가'),
              ),
              const SizedBox(height: 8),
              if (_exercises.isNotEmpty) ...[
                const Text(
                  '추가된 운동',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(
                        '${exercise.sets}세트 × ${exercise.reps}회 • ${exercise.weight}kg',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _exercises.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveWorkout,
                child: Text(
                  widget.workout == null ? '추가' : '수정',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExerciseDialog extends StatefulWidget {
  final Function(Exercise) onSave;

  const ExerciseDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<ExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _sets = 3;
  int _reps = 12;
  double _weight = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('운동 추가'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '운동 이름',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '운동 이름을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('세트: '),
                Text('$_sets'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (_sets > 1) {
                      setState(() {
                        _sets--;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _sets++;
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('횟수: '),
                Text('$_reps'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (_reps > 1) {
                      setState(() {
                        _reps--;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _reps++;
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('무게(kg): '),
                Expanded(
                  child: TextFormField(
                    initialValue: _weight.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _weight = double.tryParse(value) ?? 0;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final exercise = Exercise(
                name: _nameController.text,
                sets: _sets,
                reps: _reps,
                weight: _weight,
                intensity: 75,
              );
              widget.onSave(exercise);
              Navigator.pop(context);
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
} 