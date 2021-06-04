import 'package:spidart/spidart.dart';

void main() {
  final crawler = Crawler(initialUrl: 'https://dexonline.ro');

  crawler.crawl(pageLimit: 10000);
}