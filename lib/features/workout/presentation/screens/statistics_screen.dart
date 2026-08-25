import 'dart:convert';

import 'package:body_calendar/core/theme/app_colors.dart';
import 'package:body_calendar/features/calendar/presentation/widgets/rest_fab_overlay.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_statistics_screen.dart';
import 'group_statistics_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<String> _exerciseNames = [];
  List<_GroupStatEntry> _groupEntries = [];
  int _groupExerciseCount = 0;
  int _singleExerciseCount = 0;
  Map<DateTime, int> _heatmapCounts = {};
  List<_BodyPartStatEntry> _bodyPartEntries = [];
  List<_RoutineUsageEntry> _routineEntries = [];

  @override
  void initState() {
    super.initState();
    _loadExerciseNames();
  }

  Future<void> _loadExerciseNames() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('workouts_'));
    final names = <String>{};
    final groups = <String, _GroupStatEntry>{};
    final heatmapCountByDate = <String, int>{};
    final bodyPartCount = <String, int>{};
    final performedNamesByDate = <String, Set<String>>{};
    var groupedEntries = 0;
    var singleEntries = 0;

    for (final key in keys) {
      final dateStr = key.replaceFirst('workouts_', '');
      final workoutsJson = prefs.getStringList(key) ?? [];
      final groupedWorkouts = <String, List<Map<String, dynamic>>>{};
      final performedNames =
          performedNamesByDate.putIfAbsent(dateStr, () => {});

      for (final jsonStr in workoutsJson) {
        try {
          final workout = jsonDecode(jsonStr);
          final name = workout['name']?.toString();
          if (name != null && name.isNotEmpty) {
            names.add(name);
            performedNames.add(name);
          }
          final bodyPart = workout['bodyPart']?.toString();
          if (bodyPart != null && bodyPart.isNotEmpty) {
            bodyPartCount[bodyPart] = (bodyPartCount[bodyPart] ?? 0) + 1;
          }
          heatmapCountByDate[dateStr] = (heatmapCountByDate[dateStr] ?? 0) + 1;
          final groupId = workout['groupId']?.toString();
          if (groupId != null && groupId.isNotEmpty) {
            groupedEntries++;
            groupedWorkouts.putIfAbsent(groupId, () => []).add(
                  Map<String, dynamic>.from(workout as Map),
                );
          } else {
            singleEntries++;
          }
        } catch (_) {}
      }

      for (final workouts in groupedWorkouts.values) {
        workouts.sort((a, b) => ((a['groupOrder'] ?? 0) as int)
            .compareTo((b['groupOrder'] ?? 0) as int));
        final signature = _buildGroupSignature(workouts);
        groups.putIfAbsent(
          signature,
          () => _GroupStatEntry(
            signature: signature,
            title: _buildGroupTitle(workouts),
            exerciseNames: workouts
                .map((workout) => workout['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList(),
          ),
        );
      }
    }

    final routinesJson = prefs.getStringList('workout_routines') ?? [];
    final routineEntries = <_RoutineUsageEntry>[];
    for (final raw in routinesJson) {
      try {
        final routine = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final routineName = routine['name']?.toString() ?? '이름 없는 루틴';
        final exercises = (routine['exercises'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .map((e) => e['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toSet();
        if (exercises.isEmpty) continue;

        var matchedDays = 0;
        var bestMatchCount = 0;
        for (final performed in performedNamesByDate.values) {
          final overlap = performed.intersection(exercises).length;
          if (overlap > 0) {
            matchedDays++;
            if (overlap > bestMatchCount) {
              bestMatchCount = overlap;
            }
          }
        }

        routineEntries.add(
          _RoutineUsageEntry(
            name: routineName,
            exerciseCount: exercises.length,
            matchedDays: matchedDays,
            bestMatchRate: bestMatchCount / exercises.length,
          ),
        );
      } catch (_) {}
    }

    setState(() {
      _exerciseNames = names.toList()..sort();
      _groupEntries = groups.values.toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      _groupExerciseCount = groupedEntries;
      _singleExerciseCount = singleEntries;
      _heatmapCounts = {
        for (final entry in heatmapCountByDate.entries)
          if (DateTime.tryParse(entry.key) case final date?)
            DateTime(date.year, date.month, date.day): entry.value,
      };
      _bodyPartEntries = bodyPartCount.entries
          .map((entry) =>
              _BodyPartStatEntry(name: entry.key, count: entry.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));
      _routineEntries = routineEntries
        ..sort((a, b) {
          final dayCompare = b.matchedDays.compareTo(a.matchedDays);
          if (dayCompare != 0) return dayCompare;
          return b.bestMatchRate.compareTo(a.bestMatchRate);
        });
    });
  }

  String _buildGroupSignature(List<Map<String, dynamic>> workouts) {
    final type = workouts.first['groupType']?.toString() ?? 'group';
    final names =
        workouts.map((workout) => workout['name']?.toString() ?? '').join('::');
    return '$type::$names';
  }

  String _buildGroupTitle(List<Map<String, dynamic>> workouts) {
    final type = workouts.first['groupType']?.toString();
    final label = switch (type) {
      'superset' => '슈퍼세트',
      'compound' => '컴파운드 세트',
      _ => '그룹',
    };
    final names = workouts
        .map((workout) => workout['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .join(' · ');
    return '$label · $names';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = _exerciseNames.isNotEmpty;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('운동 통계'),
          ),
          body: hasData
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    _HeroStatisticsCard(
                      exerciseCount: _exerciseNames.length,
                      groupCount: _groupEntries.length,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DashboardCard(
                            title: '개별 운동 종목',
                            value: '${_exerciseNames.length}',
                            subtitle: '통계 진입 가능 종목 수',
                            tint: AppColors.chartColors[0],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DashboardCard(
                            title: '그룹 조합',
                            value: '${_groupEntries.length}',
                            subtitle: '슈퍼세트/컴파운드 조합 수',
                            tint: AppColors.chartColors[1],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ComparisonBanner(
                      groupCount: _groupExerciseCount,
                      singleCount: _singleExerciseCount,
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      title: '월간 활동 히트맵',
                      subtitle: '최근 12주 운동 밀도를 빠르게 볼 수 있어요.',
                    ),
                    const SizedBox(height: 10),
                    _HeatmapCard(counts: _heatmapCounts),
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      title: '부위별 통계',
                      subtitle: '어느 부위를 자주 기록했는지 보여줘요.',
                    ),
                    const SizedBox(height: 10),
                    _BodyPartStatsCard(entries: _bodyPartEntries),
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      title: '루틴별 통계',
                      subtitle: '저장된 루틴이 실제 기록과 얼마나 겹쳤는지 봐요.',
                    ),
                    const SizedBox(height: 10),
                    _RoutineStatsCard(entries: _routineEntries),
                    const SizedBox(height: 18),
                    if (_groupEntries.isNotEmpty) ...[
                      _SectionTitle(
                        title: '그룹 운동 통계',
                        subtitle:
                            '${_groupEntries.length}개 조합의 흐름을 바로 열 수 있어요.',
                      ),
                      const SizedBox(height: 10),
                      ..._groupEntries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NavigationCardButton(
                            title: entry.title,
                            subtitle: '그룹 수행 기록 보기',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupStatisticsScreen(
                                    groupSignature: entry.signature,
                                    title: entry.title,
                                    exerciseNames: entry.exerciseNames,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _SectionTitle(
                      title: '개별 운동 통계',
                      subtitle: '${_exerciseNames.length}개 운동의 상세 통계로 이동해요.',
                    ),
                    const SizedBox(height: 10),
                    ..._exerciseNames.map(
                      (name) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NavigationCardButton(
                          title: name,
                          subtitle: '운동별 기록 흐름 보기',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseStatisticsScreen(
                                    exerciseName: name),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.insights_rounded,
                            size: 34,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '기록된 운동 종목이 아직 없어요.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '운동 기록이 쌓이면 이 화면에서 흐름을 한눈에 볼 수 있어요.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        const RestFabOverlay(),
      ],
    );
  }
}

class _BodyPartStatEntry {
  final String name;
  final int count;

  const _BodyPartStatEntry({required this.name, required this.count});
}

class _RoutineUsageEntry {
  final String name;
  final int exerciseCount;
  final int matchedDays;
  final double bestMatchRate;

  const _RoutineUsageEntry({
    required this.name,
    required this.exerciseCount,
    required this.matchedDays,
    required this.bestMatchRate,
  });
}

class _GroupStatEntry {
  final String signature;
  final String title;
  final List<String> exerciseNames;

  const _GroupStatEntry({
    required this.signature,
    required this.title,
    required this.exerciseNames,
  });
}

class _HeroStatisticsCard extends StatelessWidget {
  final int exerciseCount;
  final int groupCount;

  const _HeroStatisticsCard({
    required this.exerciseCount,
    required this.groupCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.cardTheme.color ?? theme.cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '운동 기록 흐름',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '운동별, 그룹별, 루틴별 기록 패턴을 SwiftUI 톤으로 한눈에 볼 수 있어요.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetricPill(
                  label: '운동',
                  value: '$exerciseCount개',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetricPill(
                  label: '그룹',
                  value: '$groupCount개',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationCardButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationCardButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color tint;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  final Map<DateTime, int> counts;

  const _HeatmapCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 83));
    final values = counts.values.where((v) => v > 0).toList();
    final maxCount =
        values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    final totalLogs = values.fold<int>(0, (sum, value) => sum + value);
    final activeDays = values.length;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _HeroMetricPill(label: '활동일', value: '$activeDays일'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetricPill(label: '기록 수', value: '$totalLogs개'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(84, (index) {
              final date = start.add(Duration(days: index));
              final day = DateTime(date.year, date.month, date.day);
              final count = counts[day] ?? 0;
              return Tooltip(
                message: '${date.month}/${date.day} · ${count}개 기록',
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _heatColor(context, count, maxCount),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('적음', style: theme.textTheme.bodySmall),
              const SizedBox(width: 6),
              ...List.generate(4, (index) {
                final sample = ((maxCount * (index + 1)) / 4).round();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _heatColor(context, sample, maxCount),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 2),
              Text('많음', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Color _heatColor(BuildContext context, int count, int maxCount) {
    if (count <= 0) {
      return Theme.of(context).dividerColor.withValues(alpha: 0.35);
    }
    final ratio = (count / maxCount).clamp(0.0, 1.0);
    return Color.lerp(
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
          Theme.of(context).colorScheme.primary,
          ratio,
        ) ??
        Theme.of(context).colorScheme.primary;
  }
}

class _BodyPartStatsCard extends StatelessWidget {
  final List<_BodyPartStatEntry> entries;

  const _BodyPartStatsCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyCard(message: '아직 부위 정보가 쌓인 기록이 없어요.');
    }

    final topEntries = entries.take(5).toList();
    final maxCount = topEntries.first.count;
    final palette = AppColors.chartColors;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: topEntries.asMap().entries.map((entrySet) {
          final index = entrySet.key;
          final entry = entrySet.value;
          final ratio = maxCount == 0 ? 0.0 : entry.count / maxCount;
          final color = palette[index % palette.length];
          return Padding(
            padding: EdgeInsets.only(
                bottom: index == topEntries.length - 1 ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.name)),
                    Text('${entry.count}회'),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    color: color,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.22),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RoutineStatsCard extends StatelessWidget {
  final List<_RoutineUsageEntry> entries;

  const _RoutineStatsCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyCard(message: '저장된 루틴이 아직 없어요.');
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: entries.take(5).map((entry) {
          final percent = (entry.bestMatchRate * 100).round();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${entry.exerciseCount}개 운동 · 기록과 겹친 날 ${entry.matchedDays}일',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: entry.bestMatchRate.clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor:
                                theme.dividerColor.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('최대 일치 $percent%'),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _ComparisonBanner extends StatelessWidget {
  final int groupCount;
  final int singleCount;

  const _ComparisonBanner({
    required this.groupCount,
    required this.singleCount,
  });

  @override
  Widget build(BuildContext context) {
    final hint = groupCount > singleCount
        ? '최근 누적 기록 기준으로 그룹 운동 비중이 더 높아요.'
        : singleCount > groupCount
            ? '최근 누적 기록 기준으로 단일 운동 비중이 더 높아요.'
            : '그룹/단일 운동 비중이 비슷해요.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '그룹 vs 단일 운동 비중',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CompareMiniCard(label: '그룹', value: '$groupCount개'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompareMiniCard(label: '단일', value: '$singleCount개'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}

class _CompareMiniCard extends StatelessWidget {
  final String label;
  final String value;

  const _CompareMiniCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
