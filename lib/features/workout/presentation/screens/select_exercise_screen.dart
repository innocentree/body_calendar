import 'dart:convert';

import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_repository.dart';
import 'package:body_calendar/features/workout/presentation/screens/add_custom_exercise_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/exercise.dart';
import '../../../../core/utils/hangul_utils.dart';
import '../../../../core/theme/app_colors.dart';

class SelectExerciseScreen extends StatefulWidget {
  final String title;
  final String? helperText;
  final String? preferredBodyPart;

  const SelectExerciseScreen({
    super.key,
    this.title = '운동 선택',
    this.helperText,
    this.preferredBodyPart,
  });

  @override
  State<SelectExerciseScreen> createState() => _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends State<SelectExerciseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = '분류';
  Map<String, List<Exercise>> _exercises = {};
  bool _isLoading = true;

  late final ExerciseRepository _exerciseRepository;
  late final WorkoutRepository _workoutRepository;

  List<String> _bodyParts = [
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
    '종아리',
    '유산소',
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
      final prefs = await SharedPreferences.getInstance();

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
      exercisesMap['나만의 운동'] = customExercises;
      for (var exercise in customExercises) {
        if (exercise.bodyPart != null &&
            exercisesMap.containsKey(exercise.bodyPart)) {
          if (exercisesMap[exercise.bodyPart!]!
                  .any((e) => e.id == exercise.id) ==
              false) {
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
            bodyPartFrequency[bodyPart] =
                (bodyPartFrequency[bodyPart] ?? 0) + 1;
          }
        }
      }

      // Sort body parts
      final fixedParts = ['분류', '최근 운동', '전체', '나만의 운동'];
      final sortableParts =
          _bodyParts.where((part) => !fixedParts.contains(part)).toList();

      sortableParts.sort((a, b) {
        final freqA = bodyPartFrequency[a] ?? 0;
        final freqB = bodyPartFrequency[b] ?? 0;
        return freqB.compareTo(freqA); // Descending order
      });

      // Count exercise frequency and recency for sorting
      final Map<String, int> exerciseFrequencyMap = {};
      final Map<String, int> exerciseRecencyMap = {};
      int recencyCounter = 0;

      final workoutKeys = prefs
          .getKeys()
          .where((k) => k.startsWith('workouts_'))
          .toList()
        ..sort((a, b) => b.compareTo(a));

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

      // 기존 repository 기반 기록도 참고하되,
      // 실제 앱에서는 SharedPreferences의 workouts_yyyy-MM-dd 키가 주 데이터라 이것을 우선 사용한다.
      List<Exercise> recentExercises = [];

      for (final key in workoutKeys) {
        final workoutsJson = prefs.getStringList(key) ?? [];
        for (final jsonStr in workoutsJson.reversed) {
          try {
            final workout = jsonDecode(jsonStr) as Map<String, dynamic>;
            final name = workout['name']?.toString();
            if (name == null || name.isEmpty) continue;

            exerciseFrequencyMap[name] = (exerciseFrequencyMap[name] ?? 0) + 1;
            exerciseRecencyMap.putIfAbsent(name, () => recencyCounter++);

            final ex = allAvailableExercises[name];
            if (ex != null && !recentExercises.any((e) => e.name == ex.name)) {
              recentExercises.add(ex);
            }
          } catch (_) {}
        }
      }

      // repository 데이터가 살아 있는 경우 보조적으로 합친다.
      for (var workout in workouts.reversed) {
        for (var workoutExercise in workout.exercises.reversed) {
          exerciseFrequencyMap[workoutExercise.name] =
              (exerciseFrequencyMap[workoutExercise.name] ?? 0) + 1;
          exerciseRecencyMap.putIfAbsent(
              workoutExercise.name, () => recencyCounter++);

          if (allAvailableExercises.containsKey(workoutExercise.name)) {
            final ex = allAvailableExercises[workoutExercise.name]!;
            if (!recentExercises.any((e) => e.name == ex.name)) {
              recentExercises.add(ex);
            }
          }
        }
      }
      exercisesMap['최근 운동'] = recentExercises;

      // Sort all exercise lists by recency (primary) and frequency (secondary)
      for (var entry in exercisesMap.entries) {
        if (entry.key == '최근 운동')
          continue; // Keep recent exercises in chronological order

        entry.value.sort((a, b) {
          final recencyA = exerciseRecencyMap[a.name] ?? 999999;
          final recencyB = exerciseRecencyMap[b.name] ?? 999999;

          if (recencyA != recencyB) {
            return recencyA.compareTo(recencyB);
          }

          final freqA = exerciseFrequencyMap[a.name] ?? 0;
          final freqB = exerciseFrequencyMap[b.name] ?? 0;

          if (freqA != freqB) {
            return freqB.compareTo(freqA);
          }
          return a.name.compareTo(b.name);
        });
      }

      setState(() {
        _exercises = exercisesMap;
        _bodyParts = [...fixedParts, ...sortableParts];
        if (widget.preferredBodyPart != null &&
            sortableParts.contains(widget.preferredBodyPart)) {
          _selectedTab = widget.preferredBodyPart!;
        }
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
            content: Text('운동 목록을 불러오지 못했어요.'),
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
      useSafeArea: true,
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).bottomSheetTheme.backgroundColor ??
                          Theme.of(context).colorScheme.surface,
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.045),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16),
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor:
                          Theme.of(context).textTheme.bodySmall?.color,
                      indicator: BoxDecoration(
                        gradient: context.appPrimaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
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
                          _buildVariationList(
                              exercise.variations, scrollController),
                          _buildVariationList(
                            exercise.variations
                                .where((v) => v.equipment == '덤벨')
                                .toList(),
                            scrollController,
                          ),
                          _buildVariationList(
                            exercise.variations
                                .where((v) => v.equipment == '케이블')
                                .toList(),
                            scrollController,
                          ),
                          _buildVariationList(
                            exercise.variations
                                .where((v) => v.equipment == '머신')
                                .toList(),
                            scrollController,
                          ),
                          _buildVariationList(
                            exercise.variations
                                .where((v) => v.equipment == '밴드')
                                .toList(),
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

  Widget _buildVariationList(
      List<Exercise> variations, ScrollController scrollController) {
    if (variations.isEmpty) {
      return const Center(
        child: Text('표시할 운동이 없어요.'),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: variations.length,
      itemBuilder: (context, index) {
        final variation = variations[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
            ),
          ),
          child: ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: context.appPrimaryGradient,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
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
    return PopScope(
      canPop: _selectedTab == '분류',
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            _selectedTab = '분류';
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_selectedTab == '분류') {
                Navigator.pop(context);
              } else {
                setState(() {
                  _selectedTab = '분류';
                });
              }
            },
          ),
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            if (widget.helperText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.16),
                        AppColors.secondary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    widget.helperText!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, widget.helperText == null ? 8 : 0, 16, 10),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).cardTheme.color ??
                          Theme.of(context).colorScheme.surface,
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.055),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.24
                            : 0.07,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '운동 검색',
                    hintStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    prefixIcon: Icon(Icons.search,
                        color: Theme.of(context).textTheme.bodySmall?.color),
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '검색어 지우기',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.cancel_rounded, size: 18),
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),
            SizedBox(
              height: 54,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('분류'),
                      Container(
                        height: 22,
                        width: 1,
                        color: Theme.of(context).dividerColor,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
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
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchController.text.isNotEmpty
                      ? _buildSearchResults()
                      : _buildSelectedTabContent(),
            ),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: context.appPrimaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.34),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: 'select-exercise-add-custom',
            elevation: 0,
            highlightElevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            onPressed: _navigateToAddExercise,
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    if (_selectedTab == '분류') {
      return _buildCategoryButtons();
    }

    if (_selectedTab == '전체') {
      final allExercises =
          _exercises.values.expand((exercises) => exercises).toSet().toList();
      return _buildExerciseList(allExercises);
    }

    final exercises = _exercises[_selectedTab] ?? [];
    return _buildExerciseList(exercises);
  }

  Widget _buildSearchResults() {
    final allExercises =
        _exercises.values.expand((exercises) => exercises).toSet().toList();
    // final searchText = _searchController.text.toLowerCase(); // Unused

    final filteredExercises = allExercises.where((exercise) {
      return HangulUtils.containsChoseong(
          exercise.name, _searchController.text);
    }).toList();

    return _buildExerciseList(filteredExercises);
  }

  Widget _buildExerciseList(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              const Text('표시할 운동이 없어요.'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardTheme.color ??
                    Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.055),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.22
                      : 0.065,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              minTileHeight: 76,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: context.appPrimaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              title: Text(
                exercise.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exercise.description.isNotEmpty)
                    Text(
                      exercise.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.needsWeight
                        ? '${exercise.sets}세트 · ${exercise.weight}kg'
                        : '${exercise.sets}세트',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              trailing: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              onTap: () => _showVariations(exercise),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String text) {
    final isSelected = _selectedTab == text;
    final selectedColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        setState(() {
          _selectedTab = text;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? null : Colors.transparent,
          gradient: isSelected ? context.appPrimaryGradient : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButtons() {
    final categories =
        _bodyParts.where((part) => part != '분류' && part != '전체').toList();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Semantics(
          button: true,
          label: category,
          excludeSemantics: true,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).cardTheme.color ??
                      Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.065),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    _selectedTab = category;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: context.appPrimaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
