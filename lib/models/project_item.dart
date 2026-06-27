import 'dart:typed_data';

enum ProjectKind { flutter }

class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.appName,
    required this.workspaceName,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.kind,
    this.sourcePath = '',
    this.iconBytes,
  });

  final String id;
  final String appName;
  final String workspaceName;
  final String packageName;
  final String versionName;
  final String versionCode;
  final ProjectKind kind;
  final String sourcePath;
  final Uint8List? iconBytes;

  factory ProjectItem.fromPlatformMap(Map<Object?, Object?> map) {
    String readString(String key, [String fallback = '']) {
      final value = map[key]?.toString() ?? '';
      return value.isEmpty ? fallback : value;
    }

    return ProjectItem(
      id: readString('id'),
      appName: readString('appName', readString('id')),
      workspaceName: readString('workspaceName', readString('appName')),
      packageName: readString('packageName'),
      versionName: readString('versionName', '1.0'),
      versionCode: readString('versionCode', '1'),
      kind: ProjectKind.flutter,
      sourcePath: readString('sourcePath'),
      iconBytes: map['iconBytes'] as Uint8List?,
    );
  }
}

const sampleProjects = <ProjectItem>[
  ProjectItem(
    id: '1',
    appName: 'Dev Studio',
    workspaceName: 'Dev Studio',
    packageName: 'com.devstudio.app',
    versionName: '1.0',
    versionCode: '1',
    kind: ProjectKind.flutter,
  ),
  ProjectItem(
    id: '2',
    appName: 'Calculator',
    workspaceName: 'Calculator Demo',
    packageName: 'com.devstudio.calculator',
    versionName: '1.2',
    versionCode: '3',
    kind: ProjectKind.flutter,
  ),
  ProjectItem(
    id: '3',
    appName: 'Weather',
    workspaceName: 'Weather Demo',
    packageName: 'com.devstudio.weather',
    versionName: '1.0',
    versionCode: '1',
    kind: ProjectKind.flutter,
  ),
];
