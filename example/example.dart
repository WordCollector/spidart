import 'package:spidart/src/crawler.dart';

void main() {
  final crawler = Crawler(initialUrl: 'https://enro.dict.cc/', userAgent: 'spidart');

  crawler.crawl(pageLimit: 500);
}
