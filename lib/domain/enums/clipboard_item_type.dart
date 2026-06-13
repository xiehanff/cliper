enum ClipboardItemType {
  text,
  image,
  file;

  String get value => name;

  static ClipboardItemType fromString(String value) {
    return ClipboardItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClipboardItemType.text,
    );
  }
}
