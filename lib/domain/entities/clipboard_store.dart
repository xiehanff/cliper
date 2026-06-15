import 'package:flutter/foundation.dart';

import 'app_settings.dart';
import 'clipboard_group.dart';
import 'clipboard_item.dart';

@immutable
class ClipboardStore {
  final List<ClipboardItem> realtime;
  final List<ClipboardGroup> groups;
  final AppSettings settings;

  const ClipboardStore({
    this.realtime = const [],
    this.groups = const [],
    this.settings = const AppSettings(),
  });

  ClipboardStore copyWith({
    List<ClipboardItem>? realtime,
    List<ClipboardGroup>? groups,
    AppSettings? settings,
  }) {
    return ClipboardStore(
      realtime: realtime ?? this.realtime,
      groups: groups ?? this.groups,
      settings: settings ?? this.settings,
    );
  }

  ClipboardItem? findItem(String itemId, {String? groupId}) {
    if (groupId == null) {
      final index = realtime.indexWhere((it) => it.id == itemId);
      return index < 0 ? null : realtime[index];
    }

    for (final group in groups) {
      if (group.id != groupId) continue;
      final index = group.items.indexWhere((it) => it.id == itemId);
      return index < 0 ? null : group.items[index];
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'realtime': realtime.map((e) => e.toJson()).toList(),
      'groups': groups.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
    };
  }

  factory ClipboardStore.fromJson(Map<String, dynamic> json) {
    return ClipboardStore(
      realtime: (json['realtime'] as List<dynamic>?)
              ?.map((e) => ClipboardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => ClipboardGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      settings: json['settings'] is Map<String, dynamic>
          ? AppSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const AppSettings(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipboardStore &&
          runtimeType == other.runtimeType &&
          realtime.length == other.realtime.length &&
          groups.length == other.groups.length &&
          settings == other.settings;

  @override
  int get hashCode => Object.hash(realtime.length, groups.length, settings);

  @override
  String toString() {
    return 'ClipboardStore(realtime: ${realtime.length}, '
        'groups: ${groups.length}, settings: $settings)';
  }
}
