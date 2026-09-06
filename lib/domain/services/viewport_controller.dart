abstract interface class ViewportController {
  Future<void> initialize();
  Future<void> show();
  Future<void> hide();
  Future<void> toggle();
  Future<void> minimize();
  bool get isVisible;
  bool get hideWindowAfterItemActivation;
  bool get minimizeAfterItemActivation;
}
