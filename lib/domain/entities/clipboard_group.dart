import 'package:flutter/foundation.dart';

import 'clipboard_item.dart';

@immutable
class ClipboardGroup {
  final String id;
  final String name;
  final String color;
  final List<ClipboardItem> items;

  const ClipboardGroup({
    required this.id,
    required this.name,
    this.color = '#4ECDC4',
    this.items = const [],
  });

  ClipboardGroup copyWith({
    String? id,
    String? name,
    String? color,
    List<ClipboardItem>? items,
  }) {
    return ClipboardGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory ClipboardGroup.fromJson(Map<String, dynamic> json) {
    return ClipboardGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: json['color'] as String? ?? '#4ECDC4',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ClipboardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipboardGroup &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          color == other.color &&
          items.length == other.items.length;

  @override
  int get hashCode => Object.hash(id, name, color, items.length);

  @override
  String toString() {
    return 'ClipboardGroup(id: $id, name: $name, items: ${items.length})';
  }
}
