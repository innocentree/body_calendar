import 'package:body_calendar/core/theme/app_colors.dart';
import 'package:body_calendar/core/widgets/ios_widgets.dart';
import 'package:body_calendar/features/cloud_sync/data/services/cloud_sync_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BodyRecord {
  final String name;
  final List<FlSpot> chartData;

  BodyRecord({required this.name, required this.chartData});
}

class ProfileScreen extends StatefulWidget {
  final DateTime selectedDate;

  const ProfileScreen({super.key, required this.selectedDate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<BodyRecord> _bodyCompositionRecords = [];
  List<BodyRecord> _measurementRecords = [];
  bool _hasBodyCompDataForDate = false;
  bool _hasMeasurementDataForDate = false;
  bool _isLoading = true;
  bool _enableWorkoutRecommendation = true;

  final List<String> _bodyCompositionItems = ['체중', '골격근량', '체지방'];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final List<BodyRecord> loadedCompositionRecords = [];
    final List<BodyRecord> loadedMeasurementRecords = [];
    bool compDataForDate = false;
    bool measureDataForDate = false;

    for (final key in keys) {
      if (!key.startsWith('body_change_record_')) continue;
      final itemName = key.replaceFirst('body_change_record_', '');
      final data = prefs.getStringList(key) ?? [];
      if (data.isEmpty) continue;

      var hasDataForSelectedDate = false;
      final chartData = data
          .map((e) {
            try {
              final parts = e.split(',');
              if (parts.length == 2) {
                final date = DateTime.parse(parts[0]);
                final value = double.parse(parts[1]);
                if (DateUtils.isSameDay(date, widget.selectedDate)) {
                  hasDataForSelectedDate = true;
                }
                return FlSpot(date.millisecondsSinceEpoch.toDouble(), value);
              }
            } catch (_) {}
            return null;
          })
          .whereType<FlSpot>()
          .toList();

      if (chartData.isEmpty) continue;
      chartData.sort((a, b) => a.x.compareTo(b.x));
      final record = BodyRecord(name: itemName, chartData: chartData);
      if (_bodyCompositionItems.contains(itemName)) {
        loadedCompositionRecords.add(record);
        if (hasDataForSelectedDate) compDataForDate = true;
      } else {
        loadedMeasurementRecords.add(record);
        if (hasDataForSelectedDate) measureDataForDate = true;
      }
    }

    setState(() {
      _bodyCompositionRecords = loadedCompositionRecords;
      _measurementRecords = loadedMeasurementRecords;
      _hasBodyCompDataForDate = compDataForDate;
      _hasMeasurementDataForDate = measureDataForDate;
      _enableWorkoutRecommendation =
          prefs.getBool('enable_workout_recommendation') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _toggleRecommendation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_workout_recommendation', value);
    await GetIt.I<CloudSyncService>().notifyLocalChange();
    setState(() {
      _enableWorkoutRecommendation = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final totalItems =
        _bodyCompositionRecords.length + _measurementRecords.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '새로고침',
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IosLargeHeader(
                    title: '바디 로그',
                    subtitle: formattedDate,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroProfileCard(
                          dateText: formattedDate,
                          summary: !_hasBodyCompDataForDate &&
                                  !_hasMeasurementDataForDate
                              ? '아직 이 날짜에 기록된 바디 로그가 없어요.'
                              : '체성분과 치수 변화를 한눈에 확인해보세요.',
                          totalItems: totalItems,
                          hasBodyComp: _hasBodyCompDataForDate,
                          hasMeasurements: _hasMeasurementDataForDate,
                        ),
                        const SizedBox(height: 20),
                        if (!_hasBodyCompDataForDate &&
                            !_hasMeasurementDataForDate)
                          const _EmptyStateCard(
                            title: '기록이 아직 없어요',
                            message: '아래 + 버튼으로 오늘의 바디 로그를 추가해보세요.',
                            icon: Icons.monitor_weight_outlined,
                          )
                        else ...[
                          if (_hasBodyCompDataForDate) ...[
                            const _SectionHeader(
                              title: '체중/체성분',
                              subtitle: '선택한 날짜와 누적 변화 흐름',
                            ),
                            const SizedBox(height: 8),
                            _buildCategoryCard(
                                '체중/체성분', _bodyCompositionRecords, 0),
                            const SizedBox(height: 20),
                          ],
                          if (_hasMeasurementDataForDate) ...[
                            const _SectionHeader(
                              title: '치수',
                              subtitle: '부위별 기록 추이',
                            ),
                            const SizedBox(height: 8),
                            _buildCategoryCard('치수', _measurementRecords, 1),
                            const SizedBox(height: 20),
                          ],
                        ],
                        const _SectionHeader(
                          title: '설정',
                          subtitle: '운동 기록 추천 옵션',
                        ),
                        const SizedBox(height: 8),
                        _buildSettingsSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SelectBodyPartScreen(selectedDate: widget.selectedDate),
            ),
          );
          _loadRecords();
        },
        tooltip: '바디 로그 추가',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildCategoryCard(
      String title, List<BodyRecord> records, int tabIndex) {
    final theme = Theme.of(context);
    final colors = AppColors.chartColors;
    final lineBarsData = <LineChartBarData>[];
    for (int i = 0; i < records.length; i++) {
      final color = colors[i % colors.length];
      lineBarsData.add(
        LineChartBarData(
          spots: records[i].chartData,
          isCurved: true,
          barWidth: 3,
          color: color,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3.2,
              color: color,
              strokeWidth: 2,
              strokeColor: theme.cardTheme.color ?? theme.cardColor,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.08),
          ),
        ),
      );
    }

    return IosGroupedSurface(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final itemsToEdit = records.map((r) => r.name).toList();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordBodyChangeScreen(
                selectedItems: itemsToEdit,
                initialTabIndex: tabIndex,
                selectedDate: widget.selectedDate,
              ),
            ),
          );
          _loadRecords();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.appSecondaryText,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${records.length}개 항목',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    lineBarsData: lineBarsData,
                    lineTouchData: LineTouchData(enabled: false),
                    minY: 0,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final date = DateTime.fromMillisecondsSinceEpoch(
                                value.toInt());
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                DateFormat('MM/dd').format(date),
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          },
                          interval: _getInterval(records),
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: context.appSeparator.withValues(alpha: 0.35),
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLegend(records, colors),
            ],
          ),
        ),
      ),
    );
  }

  double _getInterval(List<BodyRecord> records) {
    double minX = double.maxFinite;
    double maxX = double.negativeInfinity;
    for (final record in records) {
      for (final spot in record.chartData) {
        if (spot.x < minX) minX = spot.x;
        if (spot.x > maxX) maxX = spot.x;
      }
    }
    if (minX.isFinite && maxX.isFinite && minX != maxX) {
      final oneDay = const Duration(days: 1).inMilliseconds.toDouble();
      double interval = (maxX - minX) / 4;
      if (interval < oneDay) {
        interval = oneDay;
      }
      return interval;
    }
    return const Duration(days: 1).inMilliseconds.toDouble();
  }

  Widget _buildLegend(List<BodyRecord> records, List<Color> colors) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: records.asMap().entries.map((entry) {
        final idx = entry.key;
        final record = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors[idx % colors.length],
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 6),
              Text(record.name, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsSection() {
    final theme = Theme.of(context);
    return IosGroupedSurface(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        secondary: const IosIconBadge(icon: Icons.auto_awesome_rounded),
        title: Text(
          '지난 주 운동 추천',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '새로운 날에 이전 주 동일 세션의 운동을 추천합니다.',
          style: theme.textTheme.bodySmall,
        ),
        value: _enableWorkoutRecommendation,
        onChanged: _toggleRecommendation,
      ),
    );
  }
}

class SelectBodyPartScreen extends StatefulWidget {
  final DateTime selectedDate;
  const SelectBodyPartScreen({super.key, required this.selectedDate});

  @override
  State<SelectBodyPartScreen> createState() => _SelectBodyPartScreenState();
}

class _SelectBodyPartScreenState extends State<SelectBodyPartScreen> {
  final Map<String, bool> _bodyComposition = {
    '체중': false,
    '골격근량': false,
    '체지방': false,
  };

  final Map<String, bool> _measurements = {
    '목 둘레': false,
    '어깨 너비': false,
    '가슴 둘레': false,
    '허리 둘레': false,
    '엉덩이': false,
    '허벅지': false,
    '팔': false,
    '전완': false,
    '종아리': false,
  };

  final List<String> _bodyCompositionItems = ['체중', '골격근량', '체지방'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록할 항목 선택'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: '체중/체성분',
              subtitle: '오늘 기록할 체성분 항목을 골라주세요.',
            ),
            const SizedBox(height: 10),
            _SelectionCard(
              children: _bodyComposition.keys.map((key) {
                return _AdaptiveCheckboxTile(
                  title: key,
                  value: _bodyComposition[key] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _bodyComposition[key] = value;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              title: '치수',
              subtitle: '부위별 치수도 함께 기록할 수 있어요.',
            ),
            const SizedBox(height: 10),
            _SelectionCard(
              children: _measurements.keys.map((key) {
                return _AdaptiveCheckboxTile(
                  title: key,
                  value: _measurements[key] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _measurements[key] = value;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: IosBottomSafeAction(
        child: SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: () async {
              final selectedItems = <String>[];
              _bodyComposition.forEach((key, value) {
                if (value) selectedItems.add(key);
              });
              _measurements.forEach((key, value) {
                if (value) selectedItems.add(key);
              });

              if (selectedItems.isNotEmpty) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      final initialTabIndex = selectedItems.any(
                              (item) => _bodyCompositionItems.contains(item))
                          ? 0
                          : 1;
                      return RecordBodyChangeScreen(
                        selectedItems: selectedItems,
                        initialTabIndex: initialTabIndex,
                        selectedDate: widget.selectedDate,
                      );
                    },
                  ),
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('이 항목으로 시작'),
          ),
        ),
      ),
    );
  }
}

class RecordBodyChangeScreen extends StatefulWidget {
  final List<String> selectedItems;
  final int initialTabIndex;
  final DateTime selectedDate;

  const RecordBodyChangeScreen({
    super.key,
    required this.selectedItems,
    required this.selectedDate,
    this.initialTabIndex = 0,
  });

  @override
  State<RecordBodyChangeScreen> createState() => _RecordBodyChangeScreenState();
}

class _RecordBodyChangeScreenState extends State<RecordBodyChangeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<FlSpot>> _chartData = {};
  final Map<String, Color> _itemColors = {};
  final Map<String, FocusNode> _focusNodes = {};

  final List<String> _bodyCompositionItems = ['체중', '골격근량', '체지방'];
  final List<Color> _availableColors = AppColors.chartColors;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    var colorIndex = 0;
    for (final item in widget.selectedItems) {
      _controllers[item] = TextEditingController();
      _chartData[item] = [];
      _itemColors[item] =
          _availableColors[colorIndex % _availableColors.length];
      _focusNodes[item] = FocusNode();
      _focusNodes[item]?.addListener(() {
        if (!(_focusNodes[item]?.hasFocus ?? false)) {
          final value = _controllers[item]!.text;
          if (value.isNotEmpty) {
            _saveRecord(item, value, widget.selectedDate);
          }
        }
      });
      colorIndex++;
    }
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final item in widget.selectedItems) {
        final key = 'body_change_record_$item';
        final data = prefs.getStringList(key) ?? [];
        if (data.isNotEmpty) {
          _chartData[item] = data
              .map((e) {
                try {
                  final parts = e.split(',');
                  if (parts.length == 2) {
                    final date = DateTime.parse(parts[0]);
                    final value = double.parse(parts[1]);
                    return FlSpot(
                        date.millisecondsSinceEpoch.toDouble(), value);
                  }
                } catch (_) {}
                return null;
              })
              .whereType<FlSpot>()
              .toList();
          _chartData[item]?.sort((a, b) => a.x.compareTo(b.x));
        }
      }
    });
  }

  Future<void> _saveRecords(String item) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'body_change_record_$item';
    final dataToSave = _chartData[item]?.map((spot) {
      final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
      return '${date.toIso8601String()},${spot.y}';
    }).toList();
    await prefs.setStringList(key, dataToSave ?? []);
    await GetIt.I<CloudSyncService>().notifyLocalChange();
  }

  Future<void> _saveRecord(String item, String value, DateTime date) async {
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) {
      setState(() {
        final updatedData = List<FlSpot>.from(_chartData[item] ?? []);
        final index = updatedData.indexWhere((spot) => DateUtils.isSameDay(
            DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()), date));

        if (index != -1) {
          updatedData[index] = FlSpot(updatedData[index].x, doubleValue);
        } else {
          updatedData
              .add(FlSpot(date.millisecondsSinceEpoch.toDouble(), doubleValue));
        }
        updatedData.sort((a, b) => a.x.compareTo(b.x));
        _chartData[item] = updatedData;
      });
      await _saveRecords(item);
    }
  }

  void _showEditDialog(String item, FlSpot spot) {
    final editController = TextEditingController(text: spot.y.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Text('$item 기록 수정'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: TextField(
              controller: editController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '값',
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('삭제'),
              onPressed: () {
                setState(() {
                  _chartData[item]
                      ?.removeWhere((s) => s.x == spot.x && s.y == spot.y);
                });
                _saveRecords(item);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('저장'),
              onPressed: () {
                final doubleValue = double.tryParse(editController.text);
                if (doubleValue != null) {
                  setState(() {
                    final index = _chartData[item]?.indexWhere(
                            (s) => s.x == spot.x && s.y == spot.y) ??
                        -1;
                    if (index != -1) {
                      _chartData[item]![index] = FlSpot(spot.x, doubleValue);
                    }
                  });
                  _saveRecords(item);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyCompositionSelected = widget.selectedItems
        .where((item) => _bodyCompositionItems.contains(item))
        .toList();
    final measurementSelected = widget.selectedItems
        .where((item) => !_bodyCompositionItems.contains(item))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('바디 로그'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: IosSegmentedTabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '체중/체성분'),
                Tab(text: '치수'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab(bodyCompositionSelected),
          _buildTab(measurementSelected),
        ],
      ),
    );
  }

  Widget _buildTab(List<String> items) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return const IosEmptyState(
        icon: Icons.checklist_rounded,
        title: '선택한 항목이 없어요',
        message: '이 종류에 추가한 기록 항목이 없습니다.',
      );
    }

    final lineBarsData = items.map((item) {
      final color = _itemColors[item] ?? theme.colorScheme.primary;
      return LineChartBarData(
        spots: _chartData[item] ?? [],
        isCurved: true,
        barWidth: 3,
        color: color,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
            radius: 3.4,
            color: color,
            strokeWidth: 2,
            strokeColor: theme.cardTheme.color ?? theme.cardColor,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.1),
        ),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IosGroupedSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '변화 추이',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '그래프를 탭하면 기존 기록을 수정할 수 있어요.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 280,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((barSpot) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  barSpot.x.toInt());
                              final dateText =
                                  DateFormat('yyyy-MM-dd').format(date);
                              final valueText = barSpot.y.toString();
                              return LineTooltipItem(
                                '$dateText\n$valueText',
                                theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ) ??
                                    const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                        touchCallback:
                            (FlTouchEvent event, LineTouchResponse? response) {
                          if (event is FlTapUpEvent &&
                              response != null &&
                              response.lineBarSpots != null &&
                              response.lineBarSpots!.isNotEmpty) {
                            final spot = response.lineBarSpots!.first;
                            final item = items[spot.barIndex];
                            _showEditDialog(item, spot);
                          }
                        },
                        handleBuiltInTouches: true,
                      ),
                      lineBarsData: lineBarsData,
                      minY: 0,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                value.toStringAsFixed(0),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt());
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  DateFormat('MM/dd').format(date),
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            },
                            interval: _getInterval(items),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: context.appSeparator.withValues(alpha: 0.35),
                          strokeWidth: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLegend(items),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: '오늘 기록',
            subtitle: '입력 후 포커스가 빠지면 자동 저장돼요.',
          ),
          const SizedBox(height: 10),
          IosGroupedSurface(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: items.asMap().entries.expand((entry) sync* {
                final item = entry.value;
                if (entry.key > 0) {
                  yield Divider(
                    height: 1,
                    indent: 50,
                    color: context.appSeparator.withValues(alpha: 0.55),
                  );
                }
                yield Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _itemColors[item],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controllers[item],
                          focusNode: _focusNodes[item],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: item,
                            hintText: '값 입력',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  double _getInterval(List<String> items) {
    double minX = double.maxFinite;
    double maxX = double.negativeInfinity;
    for (final item in items) {
      final data = _chartData[item] ?? [];
      for (final spot in data) {
        if (spot.x < minX) minX = spot.x;
        if (spot.x > maxX) maxX = spot.x;
      }
    }
    if (minX.isFinite && maxX.isFinite && minX != maxX) {
      final oneDay = const Duration(days: 1).inMilliseconds.toDouble();
      double interval = (maxX - minX) / 4;
      if (interval < oneDay) {
        interval = oneDay;
      }
      return interval;
    }
    return const Duration(days: 1).inMilliseconds.toDouble();
  }

  Widget _buildLegend(List<String> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _itemColors[item],
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 6),
              Text(item, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HeroProfileCard extends StatelessWidget {
  final String dateText;
  final String summary;
  final int totalItems;
  final bool hasBodyComp;
  final bool hasMeasurements;

  const _HeroProfileCard({
    required this.dateText,
    required this.summary,
    required this.totalItems,
    required this.hasBodyComp,
    required this.hasMeasurements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IosHeroSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IosIconBadge(
                icon: Icons.monitor_weight_outlined,
                size: 42,
                iconSize: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘의 바디 로그',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.appSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.appSecondaryText,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 390;
              final itemWidth = isCompact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _MiniInfoPill(
                      label: '항목 수',
                      value: '$totalItems개',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _MiniInfoPill(
                      label: '체성분',
                      value: hasBodyComp ? '기록됨' : '없음',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _MiniInfoPill(
                      label: '치수',
                      value: hasMeasurements ? '기록됨' : '없음',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.appSecondaryText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.appSecondaryText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.appSecondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _EmptyStateCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IosGroupedSurface(
      child: IosEmptyState(
        icon: icon,
        title: title,
        message: message,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SelectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return IosGroupedSurface(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children.asMap().entries.expand((entry) sync* {
          if (entry.key > 0) {
            yield Divider(
              height: 1,
              indent: 16,
              color: context.appSeparator.withValues(alpha: 0.55),
            );
          }
          yield entry.value;
        }).toList(),
      ),
    );
  }
}

class _AdaptiveCheckboxTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AdaptiveCheckboxTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: CheckboxListTile(
        title: Text(title),
        value: value,
        onChanged: (next) => onChanged(next ?? false),
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        activeColor: context.appPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        side: BorderSide(color: context.appSeparator),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}
