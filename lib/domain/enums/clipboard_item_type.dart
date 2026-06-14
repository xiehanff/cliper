enum ClipboardItemType {
  text,
  image,
  file,
  json,
  url;

  String get value => name;

  static ClipboardItemType fromString(String value) {
    return ClipboardItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClipboardItemType.text,
    );
  }
}
