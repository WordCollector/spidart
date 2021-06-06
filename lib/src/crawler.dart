import 'dart:collection';

import 'package:spidart/src/robots.dart';
import 'package:web_scraper/web_scraper.dart';

import 'package:spidart/src/text.dart';
import 'package:spidart/src/utils.dart';

const List<String> metadataTags = ['head', 'link', 'meta'];
const List<String> formattingTags = ['b', 'i', 's', 'u', 'span', 'strong', 'small', 'mark', 'em', 'del', 'ins', 'sub', 'sup'];
const List<String> quotationTags = ['blockquote', 'q', 'abbr', 'address', 'cite', 'bdo'];
const List<String> sectioningTags = ['html', 'main', 'header', 'body', 'footer', 'nav', 'article', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'div', 'hr', 'li', 'ol', 'ul'];
const List<String> paragraphTags = ['p', 'pre'];
const List<String> formTags = ['button', 'datalist', 'form', 'fieldset', 'label', 'legend', 'optgroup', 'option', 'select'];
const List<String> irrelevantTags = ['area', 'audio', 'img', 'map', 'track', 'video', 'embed', 'iframe', 'object', 'param', 'source', 'canvas', 'noscript', 'script', 'code', 'a', 'address', 'textarea'];

final RegExp metadataTagsRegex = RegExp('<(${metadataTags.join('|')}).+?<\/(${metadataTags.join('|')})>');
final RegExp formattingTagsRegex = RegExp('<\/?(${formattingTags.join('|')})[^<>]*?>');
final RegExp sectioningTagsRegex = RegExp('<\/?(${sectioningTags.join('|')})[^<>]*?>');
final RegExp formTagsRegex = RegExp('<\/?(${formTags.join('|')})[^<>]*?>');
final RegExp irrelevantTagsRegex = RegExp('<(${irrelevantTags.join('|')}).+?<\/(${irrelevantTags.join('|')})>', dotAll: true);

class Crawler {
  /// The starting point of the crawl
  final String initialUrl;

  /// What identifies this particular crawler instance
  final String userAgent;

  /// Stores all content extracted from visited pages
  final List<Text> extractedText = [];

  /// Keeps track of all visited urls
  int totalVisited = 0;

  /// Indicates if the crawler should ignore urls starting with 'http'
  final bool allowInsecureHttp;

  /// Specifies a valid url match, based on whether insecure http is allowed or not
  final RegExp _validUrl;
  
  /// [initialUrl] - The root of the tree of pages / The first visited page
  Crawler({required this.initialUrl, this.userAgent = 'spidart', this.allowInsecureHttp = false})
    : _validUrl = RegExp('("|\')http${!allowInsecureHttp ? 's' : ''}:\/\/(www.)?(\\w+?\.)+?\\w+?(\/[^"\']+?)*?("|\')');

  /// Specifies a valid path match, disallowing links to files, scripts and images
  final _validPath = RegExp('"\/[^\.]+?"');

  Future crawl({int pageLimit = -1, bool quiet = false}) async {
    if (pageLimit == 0) {
      throw 'By setting the limit of pages to 0, you have made the crawler unable to crawl. 🤡';
    }

    if (pageLimit < -1) {
      throw 'The limit of pages the crawler can traverse cannot be negative.';
    }
    
    final registeredUrls = <String>{};
    final urlsToVisit = Queue<String>()..add(initialUrl);
    final robots = Robots(userAgent: userAgent);

    print(
      pageLimit == -1 ? 
      'Crawling with no limit of pages...' : 
      'Crawling through a maximum of $pageLimit pages...'
    );

    // While there are hosts to visit
    while (urlsToVisit.isNotEmpty) {
      // Keeps track of paths that have already been remembered, and therefore cannot be added to [pathsToVisit]
      final registeredPaths = <String>{};
      // The empty path is the root path which must be accessed first
      final pathsToVisit = Queue<String>()..add('/');

      final url = urlsToVisit.removeFirst();
      final host = Utils.getHostFromUrl(url);
      final scraper = WebScraper(host);

      await robots.readRobots(host);

      // The robots.txt file prohibits the crawler from visiting any of its paths
      if (robots.disallowedAllPaths) {
        continue;
      }

      print('# $host');

      while (pathsToVisit.isNotEmpty && totalVisited != pageLimit) {
        final path = pathsToVisit.removeFirst();

        // If loading the page failed
        try {
          if (!await scraper.loadWebPage(path)) {
            continue;
          }
        } on WebScraperException catch (e) {
          print(e.errorMessage());
          continue;
        }

        var content = scraper.getPageContent();
        
        final extractedPaths = <String>[];

        final extractedUrls = content.extract(_validUrl).toList();
        // Catch any paths that were written as a complete url
        extractedPaths.addAll(
          extractedUrls
            .where((url) => url.startsWith(host))
            .map((url) => Utils.getPathFromUrl(url))
            .where((path) => robots.isAllowedPath(path)
          )
        );
        // Remove the caught paths from `extractedUrls`
        extractedUrls.removeWhere((url) => url.startsWith(host));
        // Remember to visit a url only if it hasn't already been visited
        urlsToVisit.addAll(extractedUrls.where((url) => !registeredUrls.contains(url)));
        // Remember unique hosts
        registeredUrls.addAll(extractedUrls.map((url) => url));

        extractedPaths.addAll(content.extract(_validPath));
        // Remember to visit a path only if it hasn't already been visited
        pathsToVisit.addAll(extractedPaths.where((path) => 
          !registeredPaths.contains(path) && 
          robots.isAllowedPath(path))
        );
        // Remember unique paths
        registeredPaths.addAll(extractedPaths);

        content = content.replaceAll(metadataTagsRegex, '');
        content = content.replaceAll(formattingTagsRegex, '');
        content = content.replaceAll(sectioningTagsRegex, '');
        content = content.replaceAll(formTagsRegex, '');
        content = content.replaceAll(irrelevantTagsRegex, '');

        extractedText.addAll(content.split('  ').map((textPiece) => Text(TextType.none, textPiece)));

        totalVisited++;

        print('$totalVisited » $path');
      }

      if (totalVisited == pageLimit) {
        break;
      }
    }

    print('Crawl complete. Visited $totalVisited pages, extracted ${extractedText.length} pieces of text.');

    return;
  }
}