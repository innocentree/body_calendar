import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/timer/presentation/timer_navigation.dart';
import 'package:body_calendar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestFabOverlay extends StatefulWidget {
  const RestFabOverlay({Key? key}) : super(key: key);

  @override
  State<RestFabOverlay> createState() => _RestFabOverlayState();
}

class _RestFabOverlayState extends State<RestFabOverlay> {
  Offset _fabOffset = const Offset(16, 16);
  Offset? _dragStartOffset;
  Offset? _dragStartPosition;

  @override
  void initState() {
    super.initState();
    _loadFabOffset();
  }

  Future<void> _loadFabOffset() async {
    final prefs = await SharedPreferences.getInstance();
    final dx = prefs.getDouble('rest_fab_offset_dx') ?? 16.0;
    final dy = prefs.getDouble('rest_fab_offset_dy') ?? 16.0;
    if (mounted) {
      setState(() {
        _fabOffset = Offset(dx, dy);
      });
    }
  }

  Future<void> _saveFabOffset(Offset offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('rest_fab_offset_dx', offset.dx);
    await prefs.setDouble('rest_fab_offset_dy', offset.dy);
  }

  Future<void> _goToRestingExercise(TimerBloc bloc) async {
    await navigateToRunningTimer(context, bloc);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        final isExerciseDetail = const {
          '/exercise_detail',
          '/grouped_exercise_detail'
        }.contains(ModalRoute.of(context)?.settings.name);
        if (state is! TimerRunInProgress || isExerciseDetail) {
          return const SizedBox.shrink();
        }

        final mq = MediaQuery.of(context);
        return Positioned(
          right: _fabOffset.dx,
          bottom: _fabOffset.dy + mq.padding.bottom,
          child: GestureDetector(
            onPanStart: (details) {
              _dragStartOffset = _fabOffset;
              _dragStartPosition = details.globalPosition;
            },
            onPanUpdate: (details) {
              if (_dragStartOffset != null && _dragStartPosition != null) {
                final dx = details.globalPosition.dx - _dragStartPosition!.dx;
                final dy = details.globalPosition.dy - _dragStartPosition!.dy;
                double newRight = (_dragStartOffset!.dx - dx);
                double newBottom = (_dragStartOffset!.dy - dy);
                final maxRight = mq.size.width - 144;
                final maxBottom = mq.size.height - 76;
                newRight =
                    newRight.clamp(0.0, maxRight.isFinite ? maxRight : 0.0);
                newBottom =
                    newBottom.clamp(0.0, maxBottom.isFinite ? maxBottom : 0.0);
                if (newRight.isNaN ||
                    newBottom.isNaN ||
                    newRight < 0 ||
                    newBottom < 0) return;
                setState(() {
                  _fabOffset = Offset(newRight, newBottom);
                });
              }
            },
            onPanEnd: (_) {
              _saveFabOffset(_fabOffset);
              _dragStartOffset = null;
              _dragStartPosition = null;
            },
            child: _buildFab(
              context,
              state.duration,
              state.initialDuration,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFab(
    BuildContext context,
    int duration,
    int initialDuration,
  ) {
    final bloc = context.read<TimerBloc>();
    final progress = initialDuration <= 0
        ? 0.0
        : (duration / initialDuration).clamp(0.0, 1.0);
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return GestureDetector(
      onTap: () => _goToRestingExercise(bloc),
      child: Container(
        key: const ValueKey('rest-fab-overlay'),
        width: 128,
        height: 60,
        decoration: BoxDecoration(
          gradient: context.appPrimaryGradient,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.34),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.36),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: Stack(
            children: [
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 13, 8),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.timer_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REST',
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.none,
                                fontSize: 9,
                                height: 1,
                                letterSpacing: 1.25,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$minutes:${seconds.toString().padLeft(2, '0')}',
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.none,
                                fontSize: 20,
                                height: 1,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
