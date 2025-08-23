import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_category.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('나만의 운동 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '운동 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '운동 이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBodyPart,
                decoration: const InputDecoration(
                  labelText: '운동 부위',
                  border: OutlineInputBorder(),
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
                    return '운동 부위를 선택해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '운동 설명 (선택 사항)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveExercise,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
