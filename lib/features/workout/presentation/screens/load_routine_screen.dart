import 'package:body_calendar/features/workout/domain/models/workout_routine.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_routine_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class LoadRoutineScreen extends StatefulWidget {
  const LoadRoutineScreen({super.key});

  @override
  State<LoadRoutineScreen> createState() => _LoadRoutineScreenState();
}

class _LoadRoutineScreenState extends State<LoadRoutineScreen> {
  late final WorkoutRoutineRepository _workoutRoutineRepository;
  List<WorkoutRoutine> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _workoutRoutineRepository = GetIt.I<WorkoutRoutineRepository>();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final routines = await _workoutRoutineRepository.getWorkoutRoutines();
      setState(() {
        _routines = routines;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading routines: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('루틴을 불러오는데 실패했습니다.'),
          ),
        );
      }
    }
  }

  Future<void> _deleteRoutine(String id) async {
    try {
      await _workoutRoutineRepository.deleteWorkoutRoutine(id);
      _loadRoutines(); // Refresh list after deletion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('루틴이 삭제되었습니다.')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting routine: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('루틴 삭제 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴 불러오기'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routines.isEmpty
              ? const Center(child: Text('저장된 루틴이 없습니다.'))
              : ListView.builder(
                  itemCount: _routines.length,
                  itemBuilder: (context, index) {
                    final routine = _routines[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(routine.name),
                        subtitle: Text('${routine.exercises.length}가지 운동'),
                        onTap: () {
                          Navigator.pop(context, routine); // Return selected routine
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteRoutine(routine.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
