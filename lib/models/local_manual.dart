import 'dart:io';

class LocalManual {
  const LocalManual({
    required this.id,
    required this.title,
    required this.size,
    required this.path,
    this.guideId,
    this.guideTitle,
    this.missing = false,
  });
  final String id, title, path;
  final int size;
  final String? guideId, guideTitle;
  final bool missing;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'size': size,
    'guideId': guideId,
    'guideTitle': guideTitle,
  };
  static LocalManual fromJson(Map<String, dynamic> json, Directory directory) {
    final id = json['id'] as String;
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(id))
      throw const FormatException('Invalid manual id');
    return LocalManual(
      id: id,
      title: json['title'] as String,
      size: json['size'] as int,
      path: '${directory.path}/$id.pdf',
      guideId: json['guideId'] as String?,
      guideTitle: json['guideTitle'] as String?,
      missing: !File('${directory.path}/$id.pdf').existsSync(),
    );
  }
}
