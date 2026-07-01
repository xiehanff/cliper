import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/clipboard_group.dart';
import '../../domain/entities/clipboard_item.dart';
import '../../domain/entities/clipboard_store.dart';
import '../../domain/repositories/store_repository.dart';
import '../../domain/services/clipboard_history_service.dart';
import '../../domain/services/clipboard_writer.dart';
import '../../domain/services/group_service.dart';
import '../../domain/services/image_loader_service.dart';
import '../../domain/services/viewport_controller.dart';
import 'settings_handler.dart';

class AppController extends ChangeNotifier {
  // -- Dependencies --
  final StoreRepository _storeRepository;
  final ClipboardHistoryService _historyService;
  final GroupService _groupService;
  final ClipboardWriter? _clipboardWriter;
  final ViewportController? _windowController;
  final SettingsHandler _settings;
  final ImageLoaderService? _imageLoader;
  final AppLogger? _logger;

  // -- State --
  ClipboardStore _store = const ClipboardStore();
  String? _currentGroupId;
  bool _persistInProgress = false;
  bool _persistDirty = false;

  AppController({
    required StoreRepository storeRepository,
    required ClipboardHistoryService historyService,
    required GroupService groupService,
    required SettingsHandler settingsHandler,
    ClipboardWriter? clipboardWriter,
    ViewportController? windowController,
    ImageLoaderService? imageLoader,
    AppLogger? logger,
  })  : _storeRepository = storeRepository,
        _historyService = historyService,
        _groupService = groupService,
        _settings = settingsHandler,
        _clipboardWriter = clipboardWriter,
        _windowController = windowController,
        _imageLoader = imageLoader,
        _logger = logger;

  // -- Public accessors --
  ClipboardStore get store => _store;
  String? get currentGroupId => _currentGroupId;
  bool get isRealtimeSelected => _currentGroupId == null;

  // Settings proxies (delegated to SettingsHandler)
  String get currentTheme => _store.settings.theme;
  String get currentLanguage => _store.settings.language;
  String get currentShortcut => _store.settings.shortcut;
  bool get autoLaunch => _store.settings.autoLaunch;
  bool get isMacOS => _settings.isMacOS;
  bool get supportsGlobalShortcut => _settings.supportsGlobalShortcut;
  ImageLoaderService? get imageLoader => _imageLoader;

  // Shortcut recording proxies
  bool get isShortcutRecording => _settings.shortcutRecording;

  void startShortcutRecording() {
    if (!supportsGlobalShortcut) return;
    _settings.shortcutRecording = true;
    notifyListeners();
  }

  void cancelShortcutRecording() {
    _settings.shortcutRecording = false;
    notifyListeners();
  }

  void handleShortcutRecordingKeyEvent(KeyEvent event) {
    final wasRecording = _settings.shortcutRecording;
    _settings.handleShortcutRecordingKeyEvent(event, (shortcut) {
      setShortcut(shortcut);
    });
    final recordingChanged = wasRecording != _settings.shortcutRecording;
    if (recordingChanged) notifyListeners();
  }

  // Group proxies (delegated to GroupService)
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

  // -- Store I/O --
  Future<void> loadStore() async {
    try {
      _store = await _storeRepository.load();
    } catch (e, stack) {
      _logger?.error('Failed to load store', error: e, stackTrace: stack);
      _store = const ClipboardStore();
    }
    notifyListeners();
  }

  // -- Group selection --
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

  // -- Settings operations --
  void switchTheme(String theme) {
    if (!AppConstants.supportedThemes.contains(theme)) return;
    _store = _settings.switchTheme(_store, theme);
    notifyListeners();
    _persist();
  }

  void switchLanguage(String language) {
    if (!AppConstants.supportedLanguages.contains(language)) return;
    _store = _settings.switchLanguage(_store, language);
    notifyListeners();
    _persist();
  }

  Future<void> setShortcut(String shortcut) async {
    _store = _settings.setShortcutStore(_store, shortcut);
    notifyListeners();
    _persist();
    await _settings.applyShortcutHotkey(shortcut);
  }

  Future<void> setAutoLaunch(bool enabled) async {
    _store = _settings.setAutoLaunchStore(_store, enabled);
    notifyListeners();
    _persist();
    await _settings.applyAutoLaunch(enabled);
  }

  // -- Group operations --
  bool isGroupNameTaken(String name, {String? excludingGroupId}) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    return _store.groups.any((group) {
      if (group.id == excludingGroupId) return false;
      return group.name.trim().toLowerCase() == normalized;
    });
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

  // -- Item operations --
  void addClipboardItem(ClipboardItem item) {
    _store = _historyService.addItem(_store, item);
    notifyListeners();
    _persist();
  }

  Future<void> activateItem(String itemId, {String? groupId}) async {
    final item = _store.findItem(itemId, groupId: groupId);
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

    if (_windowController?.hideWindowAfterItemActivation ?? true) {
      try {
        await _windowController?.hide();
      } catch (e, stack) {
        _logger?.error('Failed to hide window', error: e, stackTrace: stack);
      }
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

  // -- Persistence --
  void _persist() {
    _persistDirty = true;
    if (_persistInProgress) return;

    _persistInProgress = true;
    unawaited(_drainPersistQueue());
  }

  Future<void> _drainPersistQueue() async {
    try {
      while (_persistDirty) {
        _persistDirty = false;
        await _saveStore();
      }
    } finally {
      _persistInProgress = false;
      if (_persistDirty) _persist();
    }
  }

  @override
  void dispose() {
    _persistDirty = false;
    super.dispose();
  }

  Future<void> _saveStore() async {
    try {
      await _storeRepository.save(_store);
    } catch (e, stack) {
      _logger?.error('Failed to save store', error: e, stackTrace: stack);
    }
  }
}
