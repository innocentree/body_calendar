import 'dart:convert';
import 'dart:io';

import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_category.dart';
import 'package:body_calendar/features/workout/domain/models/workout.dart'
    as workout_model;
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_repository.dart';
import 'package:body_calendar/features/workout/presentation/screens/select_exercise_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _expectedCategories = {
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
};

const _newExercisesByCategory = <String, List<String>>{
  '어깨': [
    '숄더 프레스: 머신',
    '레터럴 레이즈: 머신',
    '리어 델트 플라이: 덤벨',
    '리어 델트 플라이: 케이블',
  ],
  '가슴': ['인클라인 프레스: 머신'],
  '등': [
    '스트레이트 암 풀다운',
    '체스트 서포티드 로우: 덤벨',
    '체스트 서포티드 로우: 머신',
    '친업: 맨몸',
  ],
  '삼두': ['트라이셉스 킥백: 덤벨', '트라이셉스 킥백: 케이블'],
  '이두': ['바이셉스 컬: 케이블', '컨센트레이션 컬', '바이셉스 컬: 머신'],
  '전완': ['리버스 컬: 이지바'],
  '복부': ['리버스 크런치', '크런치: 머신', '데드 버그', '팔로프 프레스: 케이블'],
  '허리': ['루마니안 데드리프트: 덤벨', '버드독'],
  '엉덩이': ['힙 스러스트: 머신', '힙 킥백: 머신'],
  '하체': ['힙 어덕션: 머신', '프론트 스쿼트: 바벨', '스텝업: 덤벨', '리버스 런지: 덤벨'],
  '종아리': ['카프 레이즈: 머신 스탠딩', '카프 레이즈: 레그 프레스'],
};

const _newEquipmentByName = <String, String>{
  '숄더 프레스: 머신': '머신',
  '레터럴 레이즈: 머신': '머신',
  '리어 델트 플라이: 덤벨': '덤벨',
  '리어 델트 플라이: 케이블': '케이블',
  '인클라인 프레스: 머신': '머신',
  '스트레이트 암 풀다운': '케이블',
  '체스트 서포티드 로우: 덤벨': '덤벨',
  '체스트 서포티드 로우: 머신': '머신',
  '친업: 맨몸': '맨몸',
  '트라이셉스 킥백: 덤벨': '덤벨',
  '트라이셉스 킥백: 케이블': '케이블',
  '바이셉스 컬: 케이블': '케이블',
  '컨센트레이션 컬': '덤벨',
  '바이셉스 컬: 머신': '머신',
  '리버스 컬: 이지바': '이지바',
  '리버스 크런치': '맨몸',
  '크런치: 머신': '머신',
  '데드 버그': '맨몸',
  '팔로프 프레스: 케이블': '케이블',
  '루마니안 데드리프트: 덤벨': '덤벨',
  '버드독': '맨몸',
  '힙 스러스트: 머신': '머신',
  '힙 킥백: 머신': '머신',
  '힙 어덕션: 머신': '머신',
  '프론트 스쿼트: 바벨': '바벨',
  '스텝업: 덤벨': '덤벨',
  '리버스 런지: 덤벨': '덤벨',
  '카프 레이즈: 머신 스탠딩': '머신',
  '카프 레이즈: 레그 프레스': '머신',
};

const _newBodyweightExercises = {
  '친업: 맨몸',
  '리버스 크런치',
  '데드 버그',
  '버드독',
};

Map<String, dynamic> _readCatalog() {
  return jsonDecode(File('assets/data/exercises.json').readAsStringSync())
      as Map<String, dynamic>;
}

Iterable<Map<String, dynamic>> _allExerciseJson(
  Map<String, dynamic> catalog,
) sync* {
  for (final category in catalog.values.cast<Map<String, dynamic>>()) {
    yield* (category['exercises'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled exercise catalog', () {
    test('keeps all baseline exercises in their original categories', () {
      final catalog = _readCatalog();
      final baseline = jsonDecode(
        File('test/fixtures/exercise_names_baseline.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      expect(baseline.length, 13);
      expect(
        baseline.values
            .cast<List<dynamic>>()
            .fold<int>(0, (count, names) => count + names.length),
        153,
      );

      for (final entry in baseline.entries) {
        final currentNames = ((catalog[entry.key]
                as Map<String, dynamic>)['exercises'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((exercise) => exercise['name'])
            .toSet();
        expect(
          currentNames.containsAll(entry.value as List<dynamic>),
          isTrue,
          reason: '${entry.key} 분류의 기존 운동 이름이 모두 보존되어야 합니다.',
        );
      }
    });

    test('contains 13 categories and 182 unique, well-formed exercises', () {
      final catalog = _readCatalog();
      final exercises = _allExerciseJson(catalog).toList();
      final names = exercises.map((exercise) => exercise['name']).toList();

      expect(catalog.keys.toSet(), _expectedCategories);
      for (final entry in catalog.entries) {
        expect(entry.value, isA<Map<String, dynamic>>());
        final category = entry.value as Map<String, dynamic>;
        expect(category['name'], entry.key);
        expect(category['exercises'], isA<List<dynamic>>());
      }
      expect(exercises, hasLength(182));
      expect(names.toSet(), hasLength(182));

      for (final exercise in exercises) {
        expect(exercise['name'], isA<String>());
        expect((exercise['name'] as String).trim(), isNotEmpty);
        expect(exercise['equipment'], isA<String>());
        expect((exercise['equipment'] as String).trim(), isNotEmpty);
        expect(exercise['imagePath'], isA<String>());
        expect((exercise['imagePath'] as String).trim(), isNotEmpty);
        expect(exercise['sets'], isA<int>());
        expect(exercise['weight'], isA<num>());
        expect(exercise['description'], isA<String>());
        expect((exercise['description'] as String).trim(), isNotEmpty);
        expect(exercise['variations'], isA<List<dynamic>>());
        if (exercise.containsKey('needsWeight')) {
          expect(exercise['needsWeight'], isA<bool>());
        }
      }
    });

    test('parses all 29 additions with explicit weight behavior', () {
      final catalog = _readCatalog();
      final expectedNewNames =
          _newExercisesByCategory.values.expand((names) => names).toSet();
      expect(expectedNewNames, hasLength(29));
      expect(_newEquipmentByName.keys.toSet(), expectedNewNames);

      for (final categoryEntry in _newExercisesByCategory.entries) {
        final categoryExercises = ((catalog[categoryEntry.key]
                as Map<String, dynamic>)['exercises'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .toList();
        final exerciseJson = categoryExercises
            .where(
              (exercise) => categoryEntry.value.contains(exercise['name']),
            )
            .toList();
        expect(exerciseJson, hasLength(categoryEntry.value.length));
        expect(
          categoryExercises
              .skip(categoryExercises.length - categoryEntry.value.length)
              .map((exercise) => exercise['name'])
              .toList(),
          categoryEntry.value,
        );

        for (final json in exerciseJson) {
          final exercise = Exercise.fromJson(json);
          expect(exercise.imagePath, 'assets/images/exercise.png');
          expect(exercise.sets, 4);
          expect(exercise.weight, 0.0);
          expect(exercise.equipment, _newEquipmentByName[exercise.name]);
          expect(exercise.description, isNotEmpty);
          expect(exercise.variations, isEmpty);
          expect(json.containsKey('needsWeight'), isTrue);
          expect(
            exercise.needsWeight,
            !_newBodyweightExercises.contains(exercise.name),
          );
        }
      }
    });

    test('fills only the requested missing equipment values', () {
      final byName = {
        for (final exercise in _allExerciseJson(_readCatalog()))
          exercise['name'] as String: exercise,
      };

      expect(byName['업라이트 로우']?['equipment'], '바벨');
      expect(byName['점프 로프']?['equipment'], '줄넘기');
    });
  });

  testWidgets('exercise selector displays and opens the cardio tab',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    addTearDown(GetIt.I.reset);
    GetIt.I.registerSingleton<ExerciseRepository>(_FakeExerciseRepository());
    GetIt.I.registerSingleton<WorkoutRepository>(_FakeWorkoutRepository());

    await tester.pumpWidget(
      const MaterialApp(home: SelectExerciseScreen()),
    );
    await tester.pumpAndSettle();

    final cardioTab = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.text('유산소'),
    );
    expect(cardioTab, findsOneWidget);

    await tester.ensureVisible(cardioTab);
    await tester.pumpAndSettle();
    await tester.tap(cardioTab);
    await tester.pumpAndSettle();

    expect(find.text('테스트 유산소 운동'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeExerciseRepository implements ExerciseRepository {
  final Exercise cardioExercise = Exercise(
    name: '테스트 유산소 운동',
    imagePath: 'assets/images/exercise.png',
    sets: 4,
    weight: 0,
    description: '유산소 탭 표시를 검증하는 운동입니다.',
    equipment: '머신',
    needsWeight: false,
  );

  @override
  Future<List<ExerciseCategory>> getExerciseCategories() async => [
        ExerciseCategory(name: '유산소', exercises: [cardioExercise]),
      ];

  @override
  Future<List<Exercise>> getCustomExercises() async => [];

  @override
  Future<Exercise?> getExerciseByName(String name) async =>
      name == cardioExercise.name ? cardioExercise : null;

  @override
  Future<void> addCustomExercise(Exercise exercise) async {}

  @override
  Future<void> deleteCustomExercise(String id) async {}
}

class _FakeWorkoutRepository implements WorkoutRepository {
  @override
  Future<List<workout_model.Workout>> getWorkouts() async => [];

  @override
  Future<void> addWorkout(workout_model.Workout workout) async {}

  @override
  Future<void> updateWorkout(workout_model.Workout workout) async {}

  @override
  Future<void> deleteWorkout(String id) async {}

  @override
  Future<String> getWorkoutsJson() async => '[]';

  @override
  Future<void> restoreWorkoutsFromJson(String jsonString) async {}
}
