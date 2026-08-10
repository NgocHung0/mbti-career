import 'dart:io';

void main() {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    print('Hãy chạy trong thư mục mobile_flutter');
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

    // 1. Thêm import AppColors nếu file có dùng AppColors
    if (text.contains('AppColors.') &&
        !text.contains("core/constants/app_colors.dart")) {
      text = _insertImport(
        text,
        "import '${_relativeAppColorsImport(path)}';",
      );
    }

    // 2. Xóa const trước các widget có AppColors.xxx(context)
    text = text.replaceAllMapped(
      RegExp(r'const\s+([A-Z][A-Za-z0-9_]*\s*\([^;{}]*AppColors\.[^;{}]*context[^;{}]*\))'),
      (m) => m.group(1)!,
    );

    // 3. Xóa const trước TextStyle / BoxDecoration / Border / Icon nếu có context
    text = text.replaceAll('const TextStyle(', 'TextStyle(');
    text = text.replaceAll('const BoxDecoration(', 'BoxDecoration(');
    text = text.replaceAll('const BorderSide(', 'BorderSide(');
    text = text.replaceAll('const Icon(', 'Icon(');

    // 4. Sửa lỗi script cũ thêm thiếu dấu ngoặc do withOpacity
    text = text.replaceAllMapped(
      RegExp(r'\.withValues\(alpha:\s*([0-9.]+)\)'),
      (m) => '.withValues(alpha: ${m.group(1)})',
    );

    // 5. Fix lỗi phổ biến: AppColors.card(context) trong nơi không có context ở top-level
    text = text.replaceAll(
      'static const lightBlue = AppColors.bg(context);',
      'static const lightBlue = Color(0xFFF1FAFF);',
    );
    text = text.replaceAll(
      'static const textDark = AppColors.title(context);',
      'static const textDark = Color(0xFF29425E);',
    );
    text = text.replaceAll(
      'static const textGrey = AppColors.subText(context);',
      'static const textGrey = Color(0xFF617587);',
    );
    text = text.replaceAll(
      'static const borderColor = AppColors.border(context);',
      'static const borderColor = Color(0xFFE4EEF8);',
    );

    if (text != old) {
      entity.writeAsStringSync(text);
      changed++;
      print('Đã sửa: $path');
    }
  }

  print('Xong. Đã sửa $changed file.');
}

String _relativeAppColorsImport(String filePath) {
  final parts = filePath.split('/');
  final libIndex = parts.indexOf('lib');
  final folderDepth = parts.length - libIndex - 2;

  if (folderDepth <= 0) {
    return 'core/constants/app_colors.dart';
  }

  final prefix = List.filled(folderDepth, '..').join('/');
  return '$prefix/core/constants/app_colors.dart';
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