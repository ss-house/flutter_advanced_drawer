part of '../flutter_advanced_drawer.dart';

/// Advanced Drawer Controller that manage drawer state.
class AdvancedDrawerController extends ValueNotifier<AdvancedDrawerValue> {
  /// Creates controller with initial drawer state. (Hidden by default)
  AdvancedDrawerController([AdvancedDrawerValue? value])
      : super(value ?? AdvancedDrawerValue.hidden());

  bool expanded = false;

  /// Shows drawer.
  void showDrawer() {
    value = AdvancedDrawerValue.visible();
    notifyListeners();
  }

  void maximize() {
    expanded = true;
    notifyListeners();
  }

  void minimize() {
    expanded = false;
    notifyListeners();
  }

  /// Hides drawer.
  void hideDrawer() {
    value = AdvancedDrawerValue.hidden();
    notifyListeners();
  }

  /// Toggles drawer.
  void toggleDrawer() {
    if (value.visible) {
      return hideDrawer();
    }

    return showDrawer();
  }
}
