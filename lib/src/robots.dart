import 'package:web_scraper/web_scraper.dart';

import 'package:spidart/src/utils.dart';

/// Corresponds with the robots.txt file of a host
class Robots {
  /// This crawler's user agent
  final String userAgent;
  
  /// The complete routes the crawler *can* visit
  List<String> allowedCompletePaths = [];
  /// The incomplete routes the crawler *can* visit
  List<String> allowedIncompletePaths = [];
  /// The complete routes the crawler *cannot* visit
  List<String> disallowedCompletePaths = [];
  /// The incomplete routes the crawler *cannot* visit
  List<String> disallowedIncompletePaths = [];

  bool disallowedAllPaths = false;

  Robots({required this.userAgent});

  /// Reads and parses the robots.txt file of a host
  Future readRobots(String url) async {
    allowedCompletePaths.clear();
    allowedIncompletePaths.clear();
    disallowedCompletePaths.clear();
    disallowedIncompletePaths.clear();
    disallowedAllPaths = false;

    final scraper = WebScraper(url);

    await scraper.loadWebPage('/robots.txt');

    // Read the text content of the robots.txt file
    final content = scraper.getPageContent().replaceAll(RegExp('<\/?(html|head|body)>'), '');
    final lines = content.split('\n');

    // If there is any html code still left over, do not parse robots.txt
    if (content.contains('<')) {
      return;
    }

    // Only the key-value pairs relevant to this user-agent and * should be counted
    var parsingRelevantAllowances = false;

    for (final line in lines) {
      // Empty lines and comments should not be parsed
      if (line.trim().isEmpty || line.startsWith('#')) {
        continue;
      }

      final pair = line.split(':');

      final key = pair[0].toLowerCase(); 
      final value = pair[1].trim();

      switch (key) {
        case 'user-agent':
          if (value == '*' || value == userAgent) {
            parsingRelevantAllowances = true;
            break;
          }
          parsingRelevantAllowances = false;
          break;
        case 'allow':
          if (!parsingRelevantAllowances) {
            break;
          }
          if (value == '*') {
            disallowedCompletePaths.clear();
            disallowedIncompletePaths.clear();
            break;
          }
          if (value.endsWith('*') || value.endsWith('[')) {
            allowedIncompletePaths.add(Utils.getParentPath(value));
            break;
          }
          allowedCompletePaths.add(value);
          break;
        case 'disallow':
          if (!parsingRelevantAllowances) {
            break;
          }
          if (value == '*') {
            allowedCompletePaths.clear();
            allowedIncompletePaths.clear();
            disallowedAllPaths = true;
            break;
          }
          if (value.endsWith('*') || value.endsWith('[')) {
            disallowedIncompletePaths.add(Utils.getParentPath(value));
            break;
          }
          disallowedCompletePaths.add(value);
          break;
        default:
          break;
      }
    }
  }

  /// Determines whether a path may be visited or not, taking into account allowed paths as well
  bool isAllowedPath(String path) {
    return 
      // Entries that *are* a disallowed path should be disregarded
      (
        !disallowedCompletePaths.contains(path) || allowedCompletePaths.contains(path)
      ) &&
      // All entries listed under a disallowed path should be disregarded
      (
        !disallowedIncompletePaths.any(
          (incompletePath) => path.startsWith(incompletePath)
        ) || 
        allowedIncompletePaths.any(
          (incompletePath) => path.startsWith(incompletePath)
        )
      );
  }
}