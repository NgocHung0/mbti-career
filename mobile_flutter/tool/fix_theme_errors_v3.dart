import 'dart:io';

void main() {
  final lib = Directory('lib');

  if (!lib.existsSync()) {
    print('Không tìm thấy lib/. Hãy chạy trong thư mục mobile_flutter.');
    return;
  }

  int changedFiles = 0;

  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final path = entity.path.replaceAll('\\', '/');
    if (path.endsWith('app_colors.dart')) continue;

    var text = entity.readAsStringSync();
    final old = text;

    if (text.contains('AppColors.')) {
      final importPath = _relativeImport(path);

      if (!text.contains("core/constants/app_colors.dart")) {
        text = _insertImport(text, "import '$importPath';");
      }

      final lines = text.split('\n');

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('AppColors.')) {
          lines[i] = lines[i].replaceAll(RegExp(r'\bconst\s+'), '');
        }
      }

      text = lines.join('\n');
    }

    if (text != old) {
      entity.writeAsStringSync(text);
      changedFiles++;
      print('Đã sửa: $path');
    }
  }

  print('Xong. Đã sửa $changedFiles file.');
}

String _relativeImport(String filePath) {
  final parts = filePath.split('/');
  final libIndex = parts.indexOf('lib');
  final depth = parts.length - libIndex - 2;

  if (depth <= 0) {
    return 'core/constants/app_colors.dart';
  }

  return '${List.filled(depth, '..').join('/')}/core/constants/app_colors.dart';
}

String _insertImport(String text, String importLine) {
  final lines = text.split('\n');

  int insertAt = 0;

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('import ')) {
      insertAt = i + 1;
    }
  }

  lines.insert(insertAt, importLine);
  return lines.join('\n');
}