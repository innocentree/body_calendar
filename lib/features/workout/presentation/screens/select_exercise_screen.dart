import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/presentation/screens/add_custom_exercise_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/models/exercise.dart';
import '../../../../core/utils/hangul_utils.dart';

class SelectExerciseScreen extends StatefulWidget {
  const SelectExerciseScreen({super.key});

  @override
  State<SelectExerciseScreen> createState() => _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends State<SelectExerciseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = '분류';
  Map<String, List<Exercise>> _exercises = {};
  bool _isLoading = true;

  late final ExerciseRepository _exerciseRepository;

  final List<String> _bodyParts = [
    '분류',
    '전체',
    '나만의 운동',
    '어깨',
    '승모근',
    '가슴',
    '등',
    '삼두',
    '이두',
    '전완',
    '복부',
    '허리',
    '엉덩이',
    '하체',
    '종아리'
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _exerciseRepository = GetIt.I<ExerciseRepository>();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final categories = await _exerciseRepository.getExerciseCategories();
      final customExercises = await _exerciseRepository.getCustomExercises();

      final Map<String, List<Exercise>> exercisesMap = {};
      for (var category in categories) {
        exercisesMap[category.name] = category.exercises;
      }

      // Add custom exercises to their respective categories or a general custom list
      exercisesMap['나만의 운동'] = customExercises;
      for (var exercise in customExercises) {
        if (exercise.bodyPart != null && exercisesMap.containsKey(exercise.bodyPart)) {
          if (exercisesMap[exercise.bodyPart!]!.any((e) => e.id == exercise.id) == false) {
            exercisesMap[exercise.bodyPart!]!.add(exercise);
          }
        }
      }

      setState(() {
        _exercises = exercisesMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('운동 데이터를 불러오는데 실패했습니다.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddExercise() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddCustomExerciseScreen()),
    );

    if (result == true) {
      _loadExercises(); // Refresh the list if an exercise was added
    }
  }

  void _showVariations(Exercise exercise) {
    if (exercise.isCustom || exercise.variations.isEmpty) {
      Navigator.pop(context, exercise);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DefaultTabController(
          length: 5,
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.description,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const TabBar(
                      isScrollable: true,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: '전체'),
                        Tab(text: '덤벨'),
                        Tab(text: '케이블'),
                        Tab(text: '머신'),
                        Tab(text: '밴드'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildVariationList(exercise.variations, scrollController),
                          _buildVariationList(
                            exercise.variations.where((v) => v.equipment == '덤벨').toList(),
                            scrollController,
                          ),
                          _buildVariationList(
                            exercise.variations.where((v) => v.equipment == '케이블').toList(),
                            scrollController,
                          ),
                          _buildVariationList(
                            exercise.variations.where((v) => v.equipment == '머신').toList(),
                            scrollController,
                          ),
                          _buildVariationList(
                            exercise.variations.where((v) => v.equipment == '밴드').toList(),
                            scrollController,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVariationList(List<Exercise> variations, ScrollController scrollController) {
    if (variations.isEmpty) {
      return const Center(
        child: Text('운동이 없습니다.'),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: variations.length,
      itemBuilder: (context, index) {
        final variation = variations[index];
        return Card(
          child: ListTile(
            title: Text(variation.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('장비: ${variation.equipment}'),
                Text(variation.description),
              ],
            ),
            trailing: Text(
              variation.needsWeight
                  ? '${variation.sets}세트 ${variation.weight}kg'
                  : '${variation.sets}세트',
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context, variation);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '운동 검색',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              Row(
                children: [
                  _buildTabButton('분류'),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _bodyParts
                            .where((part) => part != '분류')
                            .map((part) => _buildTabButton(part))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                height: 1,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchController.text.isNotEmpty
              ? _buildSearchResults()
              : _buildSelectedTabContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExercise,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    if (_selectedTab == '분류') {
      return _buildCategoryButtons();
    }

    if (_selectedTab == '전체') {
      final allExercises = _exercises.values.expand((exercises) => exercises).toSet().toList();
      return _buildExerciseList(allExercises);
    }

    final exercises = _exercises[_selectedTab] ?? [];
    return _buildExerciseList(exercises);
  }

  Widget _buildSearchResults() {
    final allExercises = _exercises.values.expand((exercises) => exercises).toSet().toList();
    final searchText = _searchController.text.toLowerCase();

    final filteredExercises = allExercises.where((exercise) {
      return HangulUtils.containsChoseong(exercise.name, _searchController.text);
    }).toList();

    return _buildExerciseList(filteredExercises);
  }

  Widget _buildExerciseList(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return const Center(
        child: Text('운동이 없습니다.'),
      );
    }

    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(exercise.name),
            subtitle: Text(exercise.description),
            trailing: Text(
              exercise.needsWeight
                  ? '${exercise.sets}세트 ${exercise.weight}kg'
                  : '${exercise.sets}세트',
            ),
            onTap: () => _showVariations(exercise),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String text) {
    final isSelected = _selectedTab == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButtons() {
    final categories = _bodyParts.where((part) => part != '분류' && part != '전체').toList();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.0,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedTab = category;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
