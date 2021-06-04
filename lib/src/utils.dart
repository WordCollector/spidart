extension TextExtraction on String {
  Iterable<String> extract(Pattern pattern) {
    return pattern.allMatches(this).map((m) => m.group(0)!.replaceAll('"', ''));
  }
}