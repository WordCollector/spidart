extension TextExtraction on String {
  /// Extract the parts of text that correspond with the pattern
  Iterable<String> extract(Pattern pattern) {
    return pattern.allMatches(this).map((m) => m.group(0)!.replaceAll('"', ''));
  }
}

class Utils {
  /// Remove path to leave just the hostname
  static String getHostFromUrl(String url) => url.split('/').sublist(0, 3).join('/');

  /// Remove hostname to leave just the path
  static String getPathFromUrl(String url) => '/' + url.split('/').sublist(3).join('/');

  /// Remove the final part of the path to leave just the parent directory
  static String getParentPath(String url) {
    final parts = url.split('/');
    parts.removeLast();
    return parts.join('/') + '/';
  }
}