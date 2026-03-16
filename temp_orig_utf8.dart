import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_repository.dart';
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
  String _selectedTab = '遺꾨쪟';
  Map<String, List<Exercise>> _exercises = {};
  bool _isLoading = true;

  late final ExerciseRepository _exerciseRepository;
  late final WorkoutRepository _workoutRepository;

  List<String> _bodyParts = [
    '遺꾨쪟',
    '?꾩껜',
    '?섎쭔???대룞',
    '?닿묠',
    '?밸え洹?,
    '媛??,
    '??,
    '?쇰몢',
    '?대몢',
    '?꾩셿',
    '蹂듬?',
    '?덈━',
    '?됰뜦??,
    '?섏껜',
    '醫낆븘由?
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _exerciseRepository = GetIt.I<ExerciseRepository>();
    _workoutRepository = GetIt.I<WorkoutRepository>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final categories = await _exerciseRepository.getExerciseCategories();
      final customExercises = await _exerciseRepository.getCustomExercises();
      final workouts = await _workoutRepository.getWorkouts();

      final Map<String, List<Exercise>> exercisesMap = {};
      
      // Create a map for quick body part lookup by exercise name
      final Map<String, String> exerciseBodyPartMap = {};

      for (var category in categories) {
        exercisesMap[category.name] = category.exercises;
        for (var ex in category.exercises) {
          exerciseBodyPartMap[ex.name] = category.name;
        }
      }

      // Add custom exercises
      exercisesMap['?섎쭔???대룞'] = customExercises;
      for (var exercise in customExercises) {
        if (exercise.bodyPart != null && exercisesMap.containsKey(exercise.bodyPart)) {
          if (exercisesMap[exercise.bodyPart!]!.any((e) => e.id == exercise.id) == false) {
            exercisesMap[exercise.bodyPart!]!.add(exercise);
          }
        }
        // Assuming custom exercises also have names and bodyParts we can track
        if (exercise.bodyPart != null) {
          exerciseBodyPartMap[exercise.name] = exercise.bodyPart!;
        }
      }

      // Calculate frequency
      final Map<String, int> bodyPartFrequency = {};
      for (var part in _bodyParts) {
        bodyPartFrequency[part] = 0;
      }

      for (var workout in workouts) {
        for (var exercise in workout.exercises) {
          final bodyPart = exerciseBodyPartMap[exercise.name];
          if (bodyPart != null) {
            bodyPartFrequency[bodyPart] = (bodyPartFrequency[bodyPart] ?? 0) + 1;
          }
        }
      }

      // Sort body parts
      final fixedParts = ['遺꾨쪟', '理쒓렐 ?대룞', '?꾩껜', '?섎쭔???대룞'];
      final sortableParts = _bodyParts.where((part) => !fixedParts.contains(part)).toList();
      
      sortableParts.sort((a, b) {
        final freqA = bodyPartFrequency[a] ?? 0;
        final freqB = bodyPartFrequency[b] ?? 0;
        return freqB.compareTo(freqA); // Descending order
      });

      // Extract recent exercises and recency map for sorting
      final Map<String, int> exerciseRecencyMap = {}; // Lower is more recent
      int recencyCounter = 0;
      
      // Collect all available exercises from categories and custom ones for lookup
      final Map<String, Exercise> allAvailableExercises = {};
      for (var list in exercisesMap.values) {
        for (var ex in list) {
          allAvailableExercises[ex.name] = ex;
          for (var v in ex.variations) {
            allAvailableExercises[v.name] = v;
          }
        }
      }

      // Get all exercises from workouts, newest first
      for (var workout in workouts.reversed) {
        for (var workoutExercise in workout.exercises.reversed) {
          if (!exerciseRecencyMap.containsKey(workoutExercise.name)) {
            exerciseRecencyMap[workoutExercise.name] = recencyCounter++;
          }
        }
      }

      // Sort all exercise lists by recency
      for (var entry in exercisesMap.entries) {
        entry.value.sort((a, b) {
          final recencyA = exerciseRecencyMap[a.name] ?? 999999;
          final recencyB = exerciseRecencyMap[b.name] ?? 999999;
          
          if (recencyA != recencyB) {
            return recencyA.compareTo(recencyB);
          }
          return a.name.compareTo(b.name);
        });
      }

      setState(() {
        _exercises = exercisesMap;
        _bodyParts = [...fixedParts, ...sortableParts];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('?곗씠?곕? 遺덈윭?ㅻ뒗???ㅽ뙣?덉뒿?덈떎.'),
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
      _loadData(); // Refresh the list if an exercise was added
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
                        Tab(text: '?꾩껜'),
                        Tab(text: '?ㅻ꺼'),
                        Tab(text: '耳?대툝'),
                        Tab(text: '癒몄떊'),
                        Tab(text: '諛대뱶'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildVariationList(exercise.variations, scrollController),
                          _buildVariationList(
                            exercise.variations.where((v) => v.equipment == '?ㅻ꺼').toList(),
                            scrollController,
                          ),
                          _buildVariationList(
                            exercise.variations.where((v) => v.equipment == '耳?대툝').toList(),
                            scrollController,
                          ),
                          _buildVariationList(
                            exercise.variations.where((v) => v.equipment == '癒몄떊').toList(),
                            scrollController,
                          ),
                          _buildVariationList(
                            exercise.variations.where((v) => v.equipment == '諛대뱶').toList(),
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
        child: Text('?대룞???놁뒿?덈떎.'),
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
                Text('?λ퉬: ${variation.equipment}'),
                Text(variation.description),
              ],
            ),
            trailing: Text(
              variation.needsWeight
                  ? '${variation.sets}?명듃 ${variation.weight}kg'
                  : '${variation.sets}?명듃',
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
              hintText: '?대룞 寃??,
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
                  _buildTabButton('遺꾨쪟'),
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
                            .where((part) => part != '遺꾨쪟')
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
    if (_selectedTab == '遺꾨쪟') {
      return _buildCategoryButtons();
    }

    if (_selectedTab == '?꾩껜') {
      final allExercises = _exercises.values.expand((exercises) => exercises).toSet().toList();
      return _buildExerciseList(allExercises);
    }

    final exercises = _exercises[_selectedTab] ?? [];
    return _buildExerciseList(exercises);
  }

  Widget _buildSearchResults() {
    final allExercises = _exercises.values.expand((exercises) => exercises).toSet().toList();
    // final searchText = _searchController.text.toLowerCase(); // Unused

    final filteredExercises = allExercises.where((exercise) {
      return HangulUtils.containsChoseong(exercise.name, _searchController.text);
    }).toList();

    return _buildExerciseList(filteredExercises);
  }

  Widget _buildExerciseList(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return const Center(
        child: Text('?대룞???놁뒿?덈떎.'),
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
                  ? '${exercise.sets}?명듃 ${exercise.weight}kg'
                  : '${exercise.sets}?명듃',
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
    final categories = _bodyParts.where((part) => part != '遺꾨쪟' && part != '?꾩껜').toList();
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
