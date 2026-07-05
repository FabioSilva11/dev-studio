class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.name,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.screenCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String packageName;
  final String versionName;
  final int versionCode;
  final int screenCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectSummary copyWith({
    String? id,
    String? name,
    String? packageName,
    String? versionName,
    int? versionCode,
    int? screenCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      screenCount: screenCount ?? this.screenCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
