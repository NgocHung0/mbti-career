import 'dart:io';

void main() {
  final lib = Directory('lib');

  if (!lib.existsSync()) {
    print('Không tìm thấy thư mục lib. Hãy chạy ở thư mục mobile_flutter.');
    return;
  }

  int changed = 0;

  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final path = entity.path.replaceAll('\\', '/');

    if (path.endsWith('app_colors.dart')) continue;

    var text = entity.readAsStringSync();
    final old = text;

    if (text.contains('AppColors') &&
        !text.contains("core/constants/app_colors.dart")) {
      final importPath = _relativeImport(path);
      text = _insertImport(text, "import '$importPath';");
    }

    if (text.contains('AppColors.') && text.contains('(context)')) {
      text = text.replaceAll(RegExp(r'\bconst\s+(?=[A-Z\[\{])'), '');
    }

    text = text.replaceAll('.withOpacity(', '.withValues(alpha: ');

    if (text != old) {
      entity.writeAsStringSync(text);
      changed++;
      print('Đã sửa: $path');
    }
  }

  print('Xong. Đã sửa $changed file.');
}

String _relativeImport(String filePath) {
  final parts = filePath.split('/');
  final libIndex = parts.indexOf('lib');
  final dirParts = parts.sublist(libIndex + 1, parts.length - 1);

  if (dirParts.isEmpty) {
    return 'core/constants/app_colors.dart';
  }

  final up = List.filled(dirParts.length, '..').join('/');
  return '$up/core/constants/app_colors.dart';
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