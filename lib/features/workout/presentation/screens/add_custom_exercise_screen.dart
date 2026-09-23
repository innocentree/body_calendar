import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class AddCustomExerciseScreen extends StatefulWidget {
  const AddCustomExerciseScreen({super.key});

  @override
  State<AddCustomExerciseScreen> createState() =>
      _AddCustomExerciseScreenState();
}

class _AddCustomExerciseScreenState extends State<AddCustomExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedBodyPart;

  late final ExerciseRepository _exerciseRepository;
  List<String> _bodyPartOptions = [];

  @override
  void initState() {
    super.initState();
    _exerciseRepository = GetIt.I<ExerciseRepository>();
    _loadBodyParts();
  }

  Future<void> _loadBodyParts() async {
    final categories = await _exerciseRepository.getExerciseCategories();
    setState(() {
      _bodyPartOptions = categories.map((c) => c.name).toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveExercise() {
    if (_formKey.currentState!.validate()) {
      final newExercise = Exercise(
        name: _nameController.text,
        description: _descriptionController.text,
        bodyPart: _selectedBodyPart!,
        isCustom: true,
        // Default values for non-user-configurable fields
        imagePath: 'assets/images/exercise.png', // Placeholder image
        sets: 4,
        weight: 10.0,
        equipment: '사용자 추가',
      );

      _exerciseRepository.addCustomExercise(newExercise).then((_) {
        Navigator.pop(context, true); // Return true to indicate success
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 운동'),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text(
                '내 운동 만들기',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '이름과 운동 부위를 입력하면 목록에 바로 추가돼요.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text('운동 정보', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '운동 이름',
                  hintText: '예: 랜드마인 프레스',
                  prefixIcon: Icon(Icons.fitness_center_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '운동 이름을 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedBodyPart,
                decoration: const InputDecoration(
                  labelText: '운동 부위',
                  prefixIcon: Icon(Icons.accessibility_new_rounded),
                ),
                items: _bodyPartOptions
                    .map((bodyPart) => DropdownMenuItem(
                          value: bodyPart,
                          child: Text(bodyPart),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBodyPart = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '운동 부위를 선택해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '운동 메모 (선택)',
                  hintText: '자세나 기구 설정을 메모해 두세요.',
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saveExercise,
                child: const Text('운동 저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
