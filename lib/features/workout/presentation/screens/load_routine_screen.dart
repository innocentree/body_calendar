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
            content: Text('루틴을 불러오지 못했어요.'),
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
          const SnackBar(content: Text('루틴을 삭제했어요.')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting routine: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('루틴 삭제 중 문제가 생겼어요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴 불러오기'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routines.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.folder_open_rounded,
                              color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 18),
                        Text('저장된 루틴이 아직 없어요.',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('운동 화면에서 현재 목록을 루틴으로 저장할 수 있어요.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: _routines.length,
                  itemBuilder: (context, index) {
                    final routine = _routines[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        minTileHeight: 72,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(Icons.list_alt_rounded,
                              color: theme.colorScheme.primary),
                        ),
                        title: Text(routine.name),
                        subtitle: Text('${routine.exercises.length}가지 운동'),
                        onTap: () {
                          Navigator.pop(
                              context, routine); // Return selected routine
                        },
                        trailing: IconButton(
                          tooltip: '루틴 삭제',
                          icon: Icon(Icons.delete_outline_rounded,
                              color: theme.colorScheme.error),
                          onPressed: () => _deleteRoutine(routine.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
