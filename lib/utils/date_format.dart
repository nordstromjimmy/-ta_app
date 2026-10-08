String _two(int n) => n.toString().padLeft(2, '0');

/// 2026-10-05
String formatDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// 2026-10-05 14:32
String formatDateTime(DateTime d) =>
    '${formatDate(d)} ${_two(d.hour)}:${_two(d.minute)}';
