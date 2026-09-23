import 'package:body_calendar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A rounded panel for content placed on an iOS grouped background.
class IosGroupedSurface extends StatelessWidget {
  const IosGroupedSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 14,
    this.color,
    this.showBorder = false,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? color;
  final bool showBorder;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: color ?? context.appGroupedSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder ? Border.all(color: context.appSeparator) : null,
      ),
      child: child,
    );
  }
}

class IosLargeHeader extends StatelessWidget {
  const IosLargeHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 12),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appSecondaryText,
                ),
          ),
        ],
      ],
    );
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: text),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class IosSectionHeader extends StatelessWidget {
  const IosSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 8),
  });

  final String title;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.appSecondaryText,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class IosIconBadge extends StatelessWidget {
  const IosIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? context.appPrimary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: foreground, size: iconSize),
    );
  }
}

/// A compact segmented tab strip. The matching [TabBarView] remains owned by
/// the calling screen, so its existing controller and navigation stay intact.
class IosSegmentedTabBar extends StatelessWidget {
  const IosSegmentedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.height = 36,
    this.padding = EdgeInsets.zero,
  });

  final TabController controller;
  final List<Widget> tabs;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: context.appSeparator.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(9),
        ),
        child: TabBar(
          controller: controller,
          tabs: tabs,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          labelColor: context.appPrimaryText,
          unselectedLabelColor: context.appSecondaryText,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class IosEmptyState extends StatelessWidget {
  const IosEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.action,
    this.padding = const EdgeInsets.all(32),
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IosIconBadge(icon: icon, size: 52, iconSize: 25),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appSecondaryText,
                    ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class IosBottomSafeAction extends StatelessWidget {
  const IosBottomSafeAction({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 10),
    this.backgroundColor,
    this.showTopBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? context.appGroupedSurface,
        border: showTopBorder
            ? Border(top: BorderSide(color: context.appSeparator, width: 0.5))
            : null,
      ),
      child: SafeArea(
        top: false,
        minimum: padding.resolve(Directionality.of(context)),
        child: child,
      ),
    );
  }
}

class IosModalHandle extends StatelessWidget {
  const IosModalHandle({super.key, this.width = 36, this.height = 5});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.appSeparator,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

class IosSheetShell extends StatelessWidget {
  const IosSheetShell({
    super.key,
    required this.child,
    this.title,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    this.showHandle = true,
  });

  final Widget child;
  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appGroupedSurface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle) ...[
                const IosModalHandle(),
                const SizedBox(height: 10),
              ],
              if (title != null || leading != null || trailing != null) ...[
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      SizedBox(width: 44, child: leading),
                      Expanded(
                        child: Text(
                          title ?? '',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 17,
                                  ),
                        ),
                      ),
                      SizedBox(width: 44, child: trailing),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
