abstract interface class ViewportController {
  Future<void> initialize();
  Future<void> show();
  Future<void> hide();
  Future<void> toggle();
  bool get isVisible;
  bool get hideWindowAfterItemActivation;
}
