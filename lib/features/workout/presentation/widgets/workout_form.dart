import 'package:flutter/material.dart';

import 'package:body_calendar/features/workout/domain/models/workout.dart';

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
  late final List<Exercise> _exercises;
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.workout?.name ?? '';
    _exercises = [...?widget.workout?.exercises];
    _duration = widget.workout?.duration ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveWorkout() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final workout = Workout(
      id: widget.workout?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      exercises: _exercises,
      duration: _duration,
      date: widget.workout?.date ?? DateTime.now(),
    );

    Navigator.pop(context, workout);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.workout == null ? '운동 저장' : '운동 수정',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '운동 이름',
                  prefixIcon: Icon(Icons.edit_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '운동 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('운동 시간',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: '운동 시간 줄이기',
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (_duration > 0) {
                              setState(() {
                                _duration--;
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: Text(
                            '$_duration분',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: '운동 시간 늘리기',
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _duration++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_exercises.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  '포함된 운동',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      tileColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      title: Text(exercise.name),
                      subtitle:
                          Text('${exercise.sets}세트 • ${exercise.weight}kg'),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saveWorkout,
                child: Text(widget.workout == null ? '저장' : '수정'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
