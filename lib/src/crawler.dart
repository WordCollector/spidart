import 'dart:collection';

import 'package:web_scraper/web_scraper.dart';

import 'utils.dart';

class Crawler {
  /// The starting point of the crawl
  final String initialUrl;

  /// Stores all content extracted from visited pages
  final List<String> extractedText = [];

  /// Keeps track of all visited urls
  int totalVisited = 0;

  /// Indicates if the crawler should ignore urls starting with 'http'
  final bool allowInsecureHttp;

  /// Specifies a valid url match, based on whether insecure http is allowed or not
  final _validUrl;
  
  /// [initialUrl] - The root of the tree of pages / The first visited page
  Crawler({required this.initialUrl, this.allowInsecureHttp = false}) : _validUrl = RegExp('"http${!allowInsecureHttp ? 's' : ''}:\/\/.+?"');

  /// Specifies a valid path match, disallowing links to files, scripts and images
  final _validPath = RegExp('"\/[^\.]+?"');

  Future crawl({int pageLimit = -1, bool quiet = false}) async {
    final registeredUrls = <String>{};
    final urlsToVisit = Queue<String>()..add(initialUrl);

    // While there are hosts to visit
    while (urlsToVisit.isNotEmpty && totalVisited != pageLimit) {
      // Keeps track of paths that have already been remembered, and therefore cannot be added to [pathsToVisit]
      final registeredPaths = <String>{};
      // The empty path is the root path which must be accessed first
      final pathsToVisit = Queue<String>()..add('');

      final scraper = WebScraper(urlsToVisit.removeFirst());

      while (pathsToVisit.isNotEmpty) {
        var currentPath = pathsToVisit.removeFirst();

        // If loading the page failed
        if (!await scraper.loadWebPage(currentPath)) {
          continue;
        }

        var content = scraper.getPageContent();
        
        var extractedPaths = content.extract(_validPath);
        // Remember to visit a path only if it hasn't already been visited
        pathsToVisit.addAll(extractedPaths.where((path) => !registeredPaths.contains(path)));
        // Remember unique paths
        registeredPaths.addAll(extractedPaths);
        
        var extractedUrls = content.extract(_validUrl);
        // Remember to visit a url only if it hasn't already been visited
        urlsToVisit.addAll(extractedUrls.where((url) => !registeredUrls.contains(url)));
        // Remember unique urls
        registeredUrls.addAll(extractedUrls);

        totalVisited++;
        print('Found ${registeredUrls.length} urls, visited $totalVisited pages');
      }
    }

    print(registeredUrls);

    print('Crawl complete. Visited $totalVisited pages, extracted ${extractedText.length} pieces of text.');

    return;
  }
}