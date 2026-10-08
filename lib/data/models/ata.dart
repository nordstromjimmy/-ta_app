/// A single change (Ändring, Tillägg, Avgående arbete) within a project.
class Ata {
  const Ata({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.createdAt,
    this.imageFileNames = const [],
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final DateTime createdAt;

  /// File names only (not full paths), in display order.
  final List<String> imageFileNames;

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'title': title,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'imageFileNames': imageFileNames,
  };

  factory Ata.fromJson(Map<String, dynamic> json) => Ata(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    imageFileNames: _readImageFileNames(json),
  );

  static List<String> _readImageFileNames(Map<String, dynamic> json) {
    final list = json['imageFileNames'];
    if (list is List) return list.cast<String>();

    // Older versions stored a single image under 'imageFileName'.
    final legacy = json['imageFileName'];
    return legacy is String ? [legacy] : const [];
  }
}
