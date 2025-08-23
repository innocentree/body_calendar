import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// region: Models
class BodyRecord {
  final String name;
  final List<FlSpot> chartData;

  BodyRecord({required this.name, required this.chartData});
}
// endregion: Models

// region: ProfileScreen
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

    for (var key in keys) {
      if (key.startsWith('body_change_record_')) {
        final itemName = key.replaceFirst('body_change_record_', '');
        final data = prefs.getStringList(key) ?? [];
        if (data.isNotEmpty) {
          bool hasDataForSelectedDate = false;
          final chartData = data.map((e) {
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
            } catch (e) { /* Ignore */ }
            return null;
          }).whereType<FlSpot>().toList();

          if (chartData.isNotEmpty) {
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
        }
      }
    }

    setState(() {
      _bodyCompositionRecords = loadedCompositionRecords;
      _measurementRecords = loadedMeasurementRecords;
      _hasBodyCompDataForDate = compDataForDate;
      _hasMeasurementDataForDate = measureDataForDate;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 (${DateFormat('yyyy-MM-dd').format(widget.selectedDate)})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasBodyCompDataForDate && !_hasMeasurementDataForDate
              ? const Center(
                  child: Text('선택된 날짜에 저장된 데이터가 없습니다.', textAlign: TextAlign.center),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      if (_hasBodyCompDataForDate)
                        _buildCategoryCard('체중/체성분', _bodyCompositionRecords, 0),
                      if (_hasMeasurementDataForDate)
                        _buildCategoryCard('치수', _measurementRecords, 1),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SelectBodyPartScreen(selectedDate: widget.selectedDate),
            ),
          );
          _loadRecords();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryCard(String title, List<BodyRecord> records, int tabIndex) {
    final List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.brown];
    final List<LineChartBarData> lineBarsData = [];
    for (int i = 0; i < records.length; i++) {
      lineBarsData.add(
        LineChartBarData(
          spots: records[i].chartData,
          isCurved: false, // Changed to straight lines
          barWidth: 2,
          color: colors[i % colors.length],
          dotData: const FlDotData(show: false),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () async {
          final List<String> itemsToEdit = records.map((r) => r.name).toList();
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    lineBarsData: lineBarsData,
                    lineTouchData: LineTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10)),
                            );
                          },
                          interval: _getInterval(records),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
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
    double maxX = double.minPositive;
    for (var record in records) {
      for (var spot in record.chartData) {
        if (spot.x < minX) minX = spot.x;
        if (spot.x > maxX) maxX = spot.x;
      }
    }
    if (minX.isFinite && maxX.isFinite && minX != maxX) {
      final double oneDay = const Duration(days: 1).inMilliseconds.toDouble();
      double interval = (maxX - minX) / 4; // Show ~5 labels
      if (interval < oneDay) {
        interval = oneDay;
      }
      return interval;
    }
    return const Duration(days: 1).inMilliseconds.toDouble();
  }

  Widget _buildLegend(List<BodyRecord> records, List<Color> colors) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: records.asMap().entries.map((entry) {
        int idx = entry.key;
        BodyRecord record = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              color: colors[idx % colors.length],
            ),
            const SizedBox(width: 6),
            Text(record.name),
          ],
        );
      }).toList(),
    );
  }
}
// endregion: ProfileScreen

// region: SelectBodyPartScreen
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
        title: const Text('항목 선택'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '체중/체성분',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ..._bodyComposition.keys.map((key) {
              return CheckboxListTile(
                title: Text(key),
                value: _bodyComposition[key],
                onChanged: (value) {
                  setState(() {
                    _bodyComposition[key] = value!;
                  });
                },
              );
            }),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '치수',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ..._measurements.keys.map((key) {
              return CheckboxListTile(
                title: Text(key),
                value: _measurements[key],
                onChanged: (value) {
                  setState(() {
                    _measurements[key] = value!;
                  });
                },
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            final List<String> selectedItems = [];
            _bodyComposition.forEach((key, value) {
              if (value) {
                selectedItems.add(key);
              }
            });
            _measurements.forEach((key, value) {
              if (value) {
                selectedItems.add(key);
              }
            });

            if (selectedItems.isNotEmpty) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    final int initialTabIndex = selectedItems.any((item) => _bodyCompositionItems.contains(item)) ? 0 : 1;
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
          child: const Text('완료'),
        ),
      ),
    );
  }
}
// endregion: SelectBodyPartScreen

// region: RecordBodyChangeScreen
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
  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.pink,
    Colors.grey,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    int colorIndex = 0;
    for (var item in widget.selectedItems) {
      _controllers[item] = TextEditingController();
      _chartData[item] = [];
      _itemColors[item] = _availableColors[colorIndex % _availableColors.length];
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
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var item in widget.selectedItems) {
        final key = 'body_change_record_$item';
        final data = prefs.getStringList(key) ?? [];
        if (data.isNotEmpty) {
          _chartData[item] = data.map((e) {
            try {
              final parts = e.split(',');
              if (parts.length == 2) {
                final date = DateTime.parse(parts[0]);
                final value = double.parse(parts[1]);
                return FlSpot(date.millisecondsSinceEpoch.toDouble(), value);
              }
            } catch (e) { /* Ignore bad data */ }
            return null;
          }).whereType<FlSpot>().toList();
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
  }

  Future<void> _saveRecord(String item, String value, DateTime date) async {
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) {
      setState(() {
        final updatedData = List<FlSpot>.from(_chartData[item] ?? []);
        final index = updatedData.indexWhere((spot) => DateUtils.isSameDay(DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()), date));

        if (index != -1) {
          // Update existing entry for the same day
          updatedData[index] = FlSpot(updatedData[index].x, doubleValue);
        } else {
          // Add new entry
          updatedData.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), doubleValue));
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
          title: Text('$item 기록 수정'),
          content: TextField(
            controller: editController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text('삭제'),
              onPressed: () {
                setState(() {
                  _chartData[item]?.removeWhere((s) => s.x == spot.x && s.y == spot.y);
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
                    final index = _chartData[item]?.indexWhere((s) => s.x == spot.x && s.y == spot.y) ?? -1;
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
    final List<String> bodyCompositionSelected = widget.selectedItems
        .where((item) => _bodyCompositionItems.contains(item))
        .toList();
    final List<String> measurementSelected = widget.selectedItems
        .where((item) => !_bodyCompositionItems.contains(item))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('신체 변화 기록'),
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
    if (items.isEmpty) {
      return const Center(child: Text('선택된 항목이 없습니다.'));
    }

    final List<LineChartBarData> lineBarsData = items.map((item) {
      return LineChartBarData(
        spots: _chartData[item] ?? [],
        isCurved: false, // Changed to straight lines
        barWidth: 2,
        color: _itemColors[item],
        dotData: const FlDotData(show: true),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        final flSpot = barSpot;
                        final date = DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt());
                        final dateText = DateFormat('yyyy-MM-dd').format(date);
                        final valueText = flSpot.y.toString();
                        return LineTooltipItem(
                          '$dateText\n$valueText',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                  touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
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
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10)),
                        );
                      },
                      interval: _getInterval(items),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(items),
          const SizedBox(height: 24),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                controller: _controllers[item],
                focusNode: _focusNodes[item],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '$item 값 입력',
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  double _getInterval(List<String> items) {
    double minX = double.maxFinite;
    double maxX = double.minPositive;
    for (var item in items) {
      final data = _chartData[item] ?? [];
      if (data.isNotEmpty) {
        for (var spot in data) {
          if (spot.x < minX) minX = spot.x;
          if (spot.x > maxX) maxX = spot.x;
        }
      }
    }
    if (minX.isFinite && maxX.isFinite && minX != maxX) {
      final double oneDay = const Duration(days: 1).inMilliseconds.toDouble();
      double interval = (maxX - minX) / 4; // Show ~5 labels
      if (interval < oneDay) {
        interval = oneDay;
      }
      return interval;
    }
    return const Duration(days: 1).inMilliseconds.toDouble();
  }

  Widget _buildLegend(List<String> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              color: _itemColors[item],
            ),
            const SizedBox(width: 6),
            Text(item),
          ],
        );
      }).toList(),
    );
  }
}
// endregion: RecordBodyChangeScreen
