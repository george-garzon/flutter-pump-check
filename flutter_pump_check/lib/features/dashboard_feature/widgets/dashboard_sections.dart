import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

class DashboardTopHeader extends StatelessWidget {
  final String title;
  final Widget leading;
  final Widget trailing;
  final Widget? bottom;
  final Color foreground;

  const DashboardTopHeader({
    super.key,
    required this.title,
    required this.leading,
    required this.trailing,
    required this.foreground,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: context.dimensions.values.s86,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.dimensions.values.s16,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: context.dimensions.values.s56,
                  child: Center(child: leading),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: foreground,
                        size: context.dimensions.values.s24,
                      ),
                      SizedBox(width: context.dimensions.values.s8),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: context.textSizes.s22,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: context.dimensions.values.s56,
                  child: Center(child: trailing),
                ),
              ],
            ),
          ),
        ),
        if (bottom != null) bottom!,
      ],
    );
  }
}

class DashboardSegmentTab<T> {
  final T value;
  final Widget child;

  const DashboardSegmentTab({required this.value, required this.child});

  factory DashboardSegmentTab.text({required T value, required String label}) {
    return DashboardSegmentTab<T>(
      value: value,
      child: Builder(
        builder: (context) =>
            Text(label, style: TextStyle(fontSize: context.textSizes.s16)),
      ),
    );
  }
}

class DashboardSegmentedTabs<T> extends StatelessWidget {
  final List<DashboardSegmentTab<T>> tabs;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final double height;
  final Color foreground;
  final Color selectedBackground;
  final EdgeInsetsGeometry? tabMargin;
  final EdgeInsetsGeometry tabPadding;

  const DashboardSegmentedTabs({
    super.key,
    required this.tabs,
    required this.selectedValue,
    required this.onSelected,
    required this.foreground,
    required this.selectedBackground,
    this.height = 46,
    this.tabMargin,
    this.tabPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: tabs.map((tab) {
          final selected = selectedValue == tab.value;
          return Expanded(
            child: Padding(
              padding: tabPadding,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  context.dimensions.values.s12,
                ),
                onTap: () => onSelected(tab.value),
                child: Container(
                  margin:
                      tabMargin ??
                      EdgeInsets.symmetric(
                        horizontal: context.dimensions.values.s5,
                      ),
                  decoration: BoxDecoration(
                    color: selected ? selectedBackground : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      context.dimensions.values.s12,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(color: foreground),
                      child: tab.child,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DashboardProfileAvatar extends StatelessWidget {
  final String photoUrl;
  final IconData icon;
  final double radius;
  final Color background;
  final Color foreground;

  const DashboardProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.icon,
    required this.background,
    required this.foreground,
    this.radius = 23,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      backgroundImage: hasPhoto ? NetworkImage(photoUrl.trim()) : null,
      onBackgroundImageError: hasPhoto ? (_, _) {} : null,
      child: hasPhoto ? null : Icon(icon, color: foreground, size: radius + 3),
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color muted;

  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: context.dimensions.values.s38),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Icon(icon, color: muted, size: context.dimensions.values.s74),
        SizedBox(height: context.dimensions.values.s26),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: muted,
            fontSize: context.textSizes.s21,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class DashboardCardShell extends StatelessWidget {
  final Widget child;
  final Color surface;
  final Color border;
  final EdgeInsetsGeometry? padding;

  const DashboardCardShell({
    super.key,
    required this.child,
    required this.surface,
    required this.border,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(context.dimensions.values.s16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(context.dimensions.values.s18),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class BurnCampColors {
  const BurnCampColors._();

  static const accent = ClaudePalette.accent;
}
