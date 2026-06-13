abstract interface class WindowController {
  Future<void> show();
  Future<void> hide();
  Future<void> toggle();
  bool get isVisible;
}
