import 'package:flutter/widgets.dart';

class ThemeModeScope extends InheritedWidget {
  const ThemeModeScope({
    super.key,
    required this.isDarkMode,
    required this.toggle,
    required super.child,
  });

  final bool isDarkMode;
  final VoidCallback toggle;

  static ThemeModeScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeModeScope>()!;
  }

  @override
  bool updateShouldNotify(ThemeModeScope oldWidget) {
    return isDarkMode != oldWidget.isDarkMode;
  }
}
