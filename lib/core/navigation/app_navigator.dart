import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final AppNavigatorObserver appNavigatorObserver = AppNavigatorObserver();

const exerciseDetailRouteName = '/exercise_detail';
const groupedExerciseDetailRouteName = '/grouped_exercise_detail';

enum WorkoutDetailKind { exercise, group }

@immutable
class WorkoutDetailTarget {
  final WorkoutDetailKind kind;
  final String dateKey;
  final String? exerciseName;
  final String? groupId;
  final int? sessionIndex;

  const WorkoutDetailTarget._({
    required this.kind,
    required this.dateKey,
    this.exerciseName,
    this.groupId,
    this.sessionIndex,
  });

  factory WorkoutDetailTarget.exercise({
    required String exerciseName,
    required DateTime selectedDate,
  }) =>
      WorkoutDetailTarget._(
        kind: WorkoutDetailKind.exercise,
        dateKey: _dateKey(selectedDate),
        exerciseName: exerciseName,
      );

  factory WorkoutDetailTarget.group({
    required String groupId,
    required int sessionIndex,
    required DateTime selectedDate,
  }) =>
      WorkoutDetailTarget._(
        kind: WorkoutDetailKind.group,
        dateKey: _dateKey(selectedDate),
        groupId: groupId,
        sessionIndex: sessionIndex,
      );

  String get routeName => kind == WorkoutDetailKind.exercise
      ? exerciseDetailRouteName
      : groupedExerciseDetailRouteName;

  RouteSettings get routeSettings =>
      RouteSettings(name: routeName, arguments: this);

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutDetailTarget &&
          kind == other.kind &&
          dateKey == other.dateKey &&
          exerciseName == other.exerciseName &&
          groupId == other.groupId &&
          sessionIndex == other.sessionIndex;

  @override
  int get hashCode =>
      Object.hash(kind, dateKey, exerciseName, groupId, sessionIndex);
}

class AppNavigatorObserver extends RouteObserver<PageRoute<dynamic>> {
  String? currentRouteName;
  final List<Route<dynamic>> _routes = [];

  bool tracks(NavigatorState navigatorState) => navigator == navigatorState;

  Route<dynamic>? routeForTarget(WorkoutDetailTarget target) {
    for (final route in _routes) {
      if (route is PageRoute && route.settings.arguments == target) {
        return route;
      }
    }
    return null;
  }

  Route<dynamic>? get firstDetailRoute {
    for (final route in _routes) {
      if (isWorkoutDetailRoute(route)) return route;
    }
    return null;
  }

  Route<dynamic>? routeBefore(Route<dynamic> route) {
    final index = _routes.indexOf(route);
    return index > 0 ? _routes[index - 1] : null;
  }

  bool isWorkoutDetailRoute(Route<dynamic> route) =>
      route is PageRoute && route.settings.arguments is WorkoutDetailTarget;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    currentRouteName = route.settings.name;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    currentRouteName = previousRoute?.settings.name;
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    currentRouteName = _routes.isEmpty ? null : _routes.last.settings.name;
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    } else if (newRoute != null) {
      _routes.add(newRoute);
    }
    currentRouteName = newRoute?.settings.name;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
