import 'package:flutter/material.dart';

import '../../../workout/domain/models/exercise.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _muscleGroups = [
    '목',
    '승모근',
    '어깨',
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

  final Map<String, int> _muscleCount = {
    '목': 2,
    '승모근': 18,
    '어깨': 87,
    '가슴': 82,
    '등': 124,
    '삼두': 49,
    '이두': 53,
    '전완': 9,
    '복부': 56,
    '허리': 7,
    '엉덩이': 23,
    '하체': 98,
    '종아리': 14
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '운동 검색',
              isDense: true,
              hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color),
              prefixIcon: Icon(Icons.search,
                  color: Theme.of(context).textTheme.bodySmall?.color),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 40),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 최상단 탭 표시
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(width: 10),
                    Text('분류',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 20),
                    Text('전체',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    SizedBox(width: 20),
                    Text('최근 30일',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    SizedBox(width: 20),
                    Text('즐겨찾기',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    SizedBox(width: 20),
                    Text('커스텀',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    SizedBox(width: 20),
                    Text('유산소',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    SizedBox(width: 10),
                  ],
                ),
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
            ),

            // 메인 콘텐츠
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _muscleGroups.length,
                itemBuilder: (context, index) {
                  final muscle = _muscleGroups[index];
                  final count = _muscleCount[muscle] ?? 0;

                  return InkWell(
                    onTap: () {
                      try {
                        // 운동 선택 시 이전 화면으로 결과 전달
                        Navigator.pop(
                          context,
                          Exercise(
                            name: muscle,
                            imagePath: 'assets/images/default_exercise.png',
                            sets: 4,
                            weight: 10.0,
                            description: '$muscle 운동',
                            bodyPart: muscle,
                          ),
                        );
                      } catch (e) {
                        // 오류 방지
                        debugPrint('Error selecting exercise: $e');
                        Navigator.pop(context);
                      }
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                muscle.substring(0, 1),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            muscle,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Text(
                          count.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 하단 이력
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildHistoryItem(context, '04 완료'),
                    const SizedBox(width: 12),
                    _buildHistoryItem(context, '05 완료'),
                    const SizedBox(width: 12),
                    _buildHistoryItem(context, '06 완료'),
                    const SizedBox(width: 12),
                    _buildHistoryItem(context, '07 완료'),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '슈퍼세트',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(72, 48),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const FittedBox(child: Text('완료')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String title) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.close,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12),
        ),
      ],
    );
  }
}
