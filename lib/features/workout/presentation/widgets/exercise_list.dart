import 'package:flutter/material.dart';
import 'package:body_calendar/features/workout/domain/models/workout.dart';

class ExerciseList extends StatelessWidget {
  final List<Workout> workouts;

  const ExerciseList({
    super.key,
    required this.workouts,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              workout.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${workout.exercises.length}개의 운동 • ${workout.duration}분',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.fitness_center,
                color: Theme.of(context).primaryColor,
              ),
            ),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workout.exercises.length,
                itemBuilder: (context, exerciseIndex) {
                  final exercise = workout.exercises[exerciseIndex];
                  return ListTile(
                    title: Text(exercise.name),
                    subtitle: Text(
                      '${exercise.sets}세트 × ${exercise.reps}회',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Text(
                      '${exercise.weight}kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: 운동 수정 기능 구현
                      },
                      child: const Text('수정'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        // TODO: 운동 삭제 기능 구현
                      },
                      child: const Text(
                        '삭제',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 