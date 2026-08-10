import 'dart:io';

void main() {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    print('Không tìm thấy lib/');
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

    if (text.contains('AppColors.')) {
      text = text.replaceAll(
        RegExp("import\\s+['\\\"][^'\\\"]*app_colors\\\\.dart['\\\"];\\s*"),
        '',
      );

      text = _insertImport(
        text,
        "import 'package:mobile_flutter/core/constants/app_colors.dart';",
      );
    }

    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('AppColors.') ||
          lines[i].contains('Theme.of(context)')) {
        for (int j = i - 3; j <= i; j++) {
          if (j >= 0 && j < lines.length) {
            lines[j] = lines[j].replaceAll(RegExp(r'\bconst\s+'), '');
          }
        }
      }
    }

    text = lines.join('\n');

    text = text.replaceAll(
      'background = AppColors.card(context)',
      'background = Colors.white',
    );

    text = text.replaceAll(
      'borderColor = AppColors.border(context)',
      'borderColor = const Color(0xFFE4EEF8)',
    );

    text = text.replaceAll(
      'AppColors.card(context),',
      'Colors.white,',
    );

    text = text.replaceAll(
      'AppColors.border(context),',
      'const Color(0xFFE4EEF8),',
    );

    if (text != old) {
      entity.writeAsStringSync(text);
      changed++;
      print('Đã sửa: $path');
    }
  }

  print('Xong. Đã sửa $changed file.');
}

String _insertImport(String text, String importLine) {
  if (text.contains(importLine)) return text;

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