import 'dart:io';

String toRealPath(Uri uri) {
  if (Platform.isWindows) {
    return _toWindowsPath(uri);
  }
  return uri.toFilePath();
}

String _toWindowsPath(Uri uri) {
  final buffer = StringBuffer();
  if (uri.authority.isNotEmpty) {
    buffer.write('\\\\${uri.authority}');
  }

  if (uri.pathSegments.isEmpty && uri.authority.isEmpty) {
    return '\\';
  }

  for (var i = 0; i < uri.pathSegments.length; i++) {
    var segment = uri.pathSegments[i];

    bool isDriveLetter = i == 0 &&
        segment.length == 2 &&
        segment[1] == ':' &&
        uri.authority.isEmpty;

    if (!isDriveLetter) {
      buffer.write('\\');
    }
    buffer.write(segment);
  }

  final pathStr = buffer.toString();

  // Ensure absolute path on Windows if missing drive letter
  if (pathStr.startsWith('\\') && !pathStr.contains(':')) {
    try {
      return File(pathStr).absolute.path;
    } catch (_) {
      return pathStr;
    }
  }

  return pathStr;
}
