class Text {
  final TextType type;
  final String content;

  const Text(this.type, this.content);
}

enum TextType {
  quote,
  paragraph,
  // ...
  none,
}