import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/clipboard_group.dart';
import '../../domain/entities/clipboard_item.dart';
import '../../domain/entities/clipboard_store.dart';
import '../../domain/repositories/store_repository.dart';
import '../../domain/services/clipboard_history_service.dart';
import '../../domain/services/clipboard_writer.dart';
import '../../domain/services/group_service.dart';
import '../../domain/services/hotkey_service.dart';
import '../../domain/services/launch_at_startup_service.dart';
import '../../domain/services/viewport_controller.dart';

class AppController extends ChangeNotifier {
  final StoreRepository _storeRepository;
  final ClipboardHistoryService _historyService;
  final GroupService _groupService;
  final ClipboardWriter? _clipboardWriter;
  final ViewportController? _windowController;
  final HotkeyService? _hotkeyService;
  final LaunchAtStartupService? _launchService;
  final AppLogger? _logger;

  ClipboardStore _store = const ClipboardStore();
  String? _currentGroupId;
  bool _persistPending = false;

  AppController({
    required StoreRepository storeRepository,
    required ClipboardHistoryService historyService,
    required GroupService groupService,
    ClipboardWriter? clipboardWriter,
    ViewportController? windowController,
    HotkeyService? hotkeyService,
    LaunchAtStartupService? launchService,
    AppLogger? logger,
  })  : _storeRepository = storeRepository,
        _historyService = historyService,
        _groupService = groupService,
        _clipboardWriter = clipboardWriter,
        _windowController = windowController,
        _hotkeyService = hotkeyService,
        _launchService = launchService,
        _logger = logger;

  ClipboardStore get store => _store;

  String? get currentGroupId => _currentGroupId;

  bool get isRealtimeSelected => _currentGroupId == null;

  String get currentTheme => _store.settings.theme;

  String get currentLanguage => _store.settings.language;

  String get currentShortcut => _store.settings.shortcut;

  bool get autoLaunch => _store.settings.autoLaunch;

  List<ClipboardGroup> get groups => _store.groups;

  List<ClipboardItem> get currentItems {
    if (_currentGroupId == null) return _store.realtime;

    final group = _store.groups.firstWhere(
      (g) => g.id == _currentGroupId,
      orElse: () => const ClipboardGroup(id: '', name: ''),
    );
    if (group.id.isEmpty) {
      _logger?.warning('Selected group not found, falling back to realtime');
      return _store.realtime;
    }
    return group.items;
  }

  Future<void> loadStore() async {
    try {
      _store = await _storeRepository.load();
    } catch (e, stack) {
      _logger?.error('Failed to load store', error: e, stackTrace: stack);
      _store = const ClipboardStore();
    }
    notifyListeners();
  }

  void selectGroup(String? groupId) {
    if (groupId != null) {
      final exists = _store.groups.any((g) => g.id == groupId);
      if (!exists) {
        _logger?.warning('Group $groupId does not exist, selecting realtime');
        _currentGroupId = null;
        notifyListeners();
        return;
      }
    }
    _currentGroupId = groupId;
    notifyListeners();
  }

  void switchTheme(String theme) {
    if (!AppConstants.supportedThemes.contains(theme)) return;
    _store = _store.copyWith(settings: _store.settings.copyWith(theme: theme));
    notifyListeners();
    _persist();
  }

  void switchLanguage(String language) {
    if (!AppConstants.supportedLanguages.contains(language)) return;
    _store = _store.copyWith(
      settings: _store.settings.copyWith(language: language),
    );
    notifyListeners();
    _persist();
  }

  Future<void> setShortcut(String shortcut) async {
    _store = _store.copyWith(
      settings: _store.settings.copyWith(shortcut: shortcut),
    );
    notifyListeners();
    _persist();

    try {
      await _hotkeyService?.unregister();
      await _hotkeyService?.register(shortcut);
    } catch (e, stack) {
      _logger?.error('Failed to update hotkey', error: e, stackTrace: stack);
    }
  }

  void createGroup(String name, String color) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return;
    if (isGroupNameTaken(normalizedName)) {
      _logger?.warning('Group name already exists: $normalizedName');
      return;
    }
    _store = _groupService.createGroup(_store, normalizedName, color);
    notifyListeners();
    _persist();
  }

  bool isGroupNameTaken(String name, {String? excludingGroupId}) {
    final normalized = _normalizeGroupName(name);
    if (normalized.isEmpty) return false;

    return _store.groups.any((group) {
      if (group.id == excludingGroupId) return false;
      return _normalizeGroupName(group.name) == normalized;
    });
  }

  void deleteGroup(String groupId) {
    _store = _groupService.deleteGroup(_store, groupId);
    if (_currentGroupId == groupId) {
      _currentGroupId = null;
    }
    notifyListeners();
    _persist();
  }

  void renameGroup(String groupId, String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return;
    if (isGroupNameTaken(normalizedName, excludingGroupId: groupId)) {
      _logger?.warning('Group name already exists: $normalizedName');
      return;
    }
    _store = _groupService.renameGroup(_store, groupId, normalizedName);
    notifyListeners();
    _persist();
  }

  void updateGroupColor(String groupId, String color) {
    _store = _groupService.updateGroupColor(_store, groupId, color);
    notifyListeners();
    _persist();
  }

  void addClipboardItem(ClipboardItem item) {
    _store = _historyService.addItem(_store, item);
    notifyListeners();
    _persist();
  }

  Future<void> activateItem(String itemId, {String? groupId}) async {
    final item = _findItem(itemId, groupId: groupId);
    if (item == null) {
      _logger?.warning('Activated item not found: $itemId');
      return;
    }

    try {
      await _clipboardWriter?.write(item);
    } catch (e, stack) {
      _logger?.error(
        'Failed to write item back to clipboard',
        error: e,
        stackTrace: stack,
      );
    }

    if (groupId == null) {
      _store = _historyService.activateItem(_store, itemId);
    }

    notifyListeners();
    _persist();

    try {
      await _windowController?.hide();
    } catch (e, stack) {
      _logger?.error('Failed to hide window', error: e, stackTrace: stack);
    }
  }

  void deleteItem(String itemId, {String? groupId}) {
    if (groupId == null) {
      _store = _historyService.deleteItem(_store, itemId);
    } else {
      _store = _groupService.deleteItemFromGroup(_store, groupId, itemId);
    }
    notifyListeners();
    _persist();
  }

  void moveItem({
    required String? sourceGroupId,
    required String? targetGroupId,
    required String itemId,
  }) {
    _store = _groupService.moveItem(
      _store,
      sourceGroupId: sourceGroupId,
      targetGroupId: targetGroupId,
      itemId: itemId,
    );
    notifyListeners();
    _persist();
  }

  Future<void> setAutoLaunch(bool enabled) async {
    _store = _store.copyWith(
      settings: _store.settings.copyWith(autoLaunch: enabled),
    );
    notifyListeners();
    _persist();

    try {
      await _launchService?.setEnabled(enabled);
    } catch (e, stack) {
      _logger?.error('Failed to set auto launch', error: e, stackTrace: stack);
    }
  }

  void _persist() {
    if (_persistPending) return;
    _persistPending = true;
    _saveStore().then((_) => _persistPending = false);
  }

  @override
  void dispose() {
    _persistPending = false;
    super.dispose();
  }

  Future<void> _saveStore() async {
    try {
      await _storeRepository.save(_store);
    } catch (e, stack) {
      _logger?.error('Failed to save store', error: e, stackTrace: stack);
    }
  }

  ClipboardItem? _findItem(String itemId, {String? groupId}) {
    if (groupId == null) {
      final index = _store.realtime.indexWhere((it) => it.id == itemId);
      return index < 0 ? null : _store.realtime[index];
    }

    for (final group in _store.groups) {
      if (group.id != groupId) continue;
      final index = group.items.indexWhere((it) => it.id == itemId);
      return index < 0 ? null : group.items[index];
    }
    return null;
  }

  String _normalizeGroupName(String name) => name.trim().toLowerCase();
}
