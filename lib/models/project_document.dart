class ProjectDocument {
  final int? id;
  final int projectId;
  final String name;
  final String? fileUrl;
  final String uploadedAt;

  ProjectDocument({
    this.id,
    required this.projectId,
    this.name = '',
    this.fileUrl,
    this.uploadedAt = '',
  });

  factory ProjectDocument.fromMap(Map<String, dynamic> m) => ProjectDocument(
        id: m['id'],
        projectId: m['project'],
        name: m['name'] ?? '',
        fileUrl: m['file'],
        uploadedAt: m['uploaded_at'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'project': projectId,
        'name': name,
      };

  ProjectDocument copyWith({String? name}) => ProjectDocument(
        id: id,
        projectId: projectId,
        name: name ?? this.name,
        fileUrl: fileUrl,
        uploadedAt: uploadedAt,
      );
}
