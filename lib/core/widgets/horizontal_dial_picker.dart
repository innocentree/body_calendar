import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:body_calendar/core/theme/app_colors.dart';

class HorizontalDialPicker extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final double initialValue;
  final double step;
  final String unit;
  final ValueChanged<double> onChanged;
  final double width;

  const HorizontalDialPicker({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    this.step = 1.0,
    required this.unit,
    required this.onChanged,
    this.width = 300,
  });

  @override
  State<HorizontalDialPicker> createState() => _HorizontalDialPickerState();
}

class _HorizontalDialPickerState extends State<HorizontalDialPicker> {
  late ScrollController _scrollController;
  late double _currentValue;
  static const double _itemWidth = 20.0; // Increased from 10.0 to 20.0

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    final initialOffset = (_currentValue - widget.minValue) / widget.step * _itemWidth;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void didUpdateWidget(covariant HorizontalDialPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _currentValue = widget.initialValue;
      final offset = (_currentValue - widget.minValue) / widget.step * _itemWidth;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(offset);
      }
    }
  }

  void _onScroll() {
    if (!mounted) return;
    
    final offset = _scrollController.offset;
    double value = (offset / _itemWidth) * widget.step + widget.minValue;
    value = (value / widget.step).round() * widget.step;
    value = value.clamp(widget.minValue, widget.maxValue);

    if (value != _currentValue) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && value != _currentValue) {
          setState(() {
            _currentValue = value;
          });
          widget.onChanged(value);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualWidth = constraints.maxWidth;
        final centerPadding = actualWidth / 2;
        final totalScrollWidth = ((widget.maxValue - widget.minValue) / widget.step) * _itemWidth;

        return Container(
          width: actualWidth,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.customBackground.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.step < 1 ? _currentValue.toStringAsFixed(1) : _currentValue.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonCyan,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.unit,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonCyan.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Glow for center
                    Container(
                      width: 100,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.neonCyan.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification) {
                          _onScroll();
                        } else if (notification is ScrollEndNotification) {
                          // Snapping logic
                          final offset = _scrollController.offset;
                          final snappedOffset = (offset / _itemWidth).round() * _itemWidth;
                          if (snappedOffset != offset) {
                            Future.microtask(() {
                              if (_scrollController.hasClients) {
                                _scrollController.animateTo(
                                  snappedOffset,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            });
                          }
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: centerPadding),
                          child: CustomPaint(
                            size: Size(totalScrollWidth, 80),
                            painter: _DialPainter(
                              minValue: widget.minValue,
                              maxValue: widget.maxValue,
                              step: widget.step,
                              itemWidth: _itemWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Premium Pointer
                    IgnorePointer(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 4,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.neonCyan.withOpacity(0.2),
                                  AppColors.neonCyan,
                                  AppColors.neonCyan.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  final double minValue;
  final double maxValue;
  final double step;
  final double itemWidth;

  _DialPainter({
    required this.minValue,
    required this.maxValue,
    required this.step,
    required this.itemWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    int totalSteps = ((maxValue - minValue) / step).toInt();

    for (int i = 0; i <= totalSteps; i++) {
      final x = i * itemWidth;
      final isMajor = i % 5 == 0;
      final value = minValue + (i * step);

      if (isMajor) {
        paint.color = AppColors.neonCyan.withOpacity(0.8);
        paint.strokeWidth = 2.5;
        const double tickHeight = 40;
        canvas.drawLine(
          Offset(x, (size.height - tickHeight) / 2),
          Offset(x, (size.height + tickHeight) / 2),
          paint,
        );

        final label = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
        textPainter.text = TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold,
            color: AppColors.neonCyan.withOpacity(0.6),
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, (size.height + tickHeight) / 2 + 5),
        );
      } else {
        paint.color = AppColors.neonCyan.withOpacity(0.3);
        paint.strokeWidth = 1.5;
        const double tickHeight = 20;
        canvas.drawLine(
          Offset(x, (size.height - tickHeight) / 2),
          Offset(x, (size.height + tickHeight) / 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.minValue != minValue ||
           oldDelegate.maxValue != maxValue ||
           oldDelegate.step != step ||
           oldDelegate.itemWidth != itemWidth;
  }
}
