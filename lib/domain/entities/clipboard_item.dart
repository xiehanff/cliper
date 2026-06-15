import 'package:flutter/foundation.dart';

import '../../core/utils/clipboard_path_normalizer.dart';
import '../enums/clipboard_item_type.dart';

@immutable
class ClipboardItem {
  final String id;
  final ClipboardItemType type;
  final String text;
  final String image;
  final List<String> files;
  final int timestamp;

  const ClipboardItem({
    required this.id,
    required this.type,
    this.text = '',
    this.image = '',
    this.files = const [],
    required this.timestamp,
  });

  String get contentKey {
    return switch (type) {
      ClipboardItemType.text => text,
      ClipboardItemType.image => image,
      ClipboardItemType.file =>
          files.map(normalizeClipboardFilePath).join('\n'),
      ClipboardItemType.json => text,
      ClipboardItemType.url => text,
    };
  }

  ClipboardItem copyWith({
    String? id,
    ClipboardItemType? type,
    String? text,
    String? image,
    List<String>? files,
    int? timestamp,
  }) {
    return ClipboardItem(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      image: image ?? this.image,
      files: files ?? this.files,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'text': text,
      'image': image,
      'files': files,
      'timestamp': timestamp,
    };
  }

  factory ClipboardItem.fromJson(Map<String, dynamic> json) {
    return ClipboardItem(
      id: json['id'] as String? ?? '',
      type: ClipboardItemType.fromString(json['type'] as String? ?? 'text'),
      text: json['text'] as String? ?? '',
      image: json['image'] as String? ?? '',
      files:
          (json['files'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipboardItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          text == other.text &&
          image == other.image &&
          files.join('\n') == other.files.join('\n') &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      Object.hash(id, type, text, image, files.join('\n'), timestamp);

  @override
  String toString() {
    return 'ClipboardItem(id: $id, type: $type, timestamp: $timestamp)';
  }
}
