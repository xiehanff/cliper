abstract interface class HotkeyService {
  Future<void> register(String shortcut);
  Future<void> unregister();
}
