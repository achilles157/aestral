class TarotCard {
  final int id;
  final String name;
  final String suit;
  final List<String> keywords;
  final String uprightMeaning;
  final String reversedMeaning;
  final String imagePromptKeywords;

  TarotCard({
    required this.id,
    required this.name,
    required this.suit,
    required this.keywords,
    required this.uprightMeaning,
    required this.reversedMeaning,
    required this.imagePromptKeywords,
  });

  factory TarotCard.fromJson(Map<String, dynamic> json) {
    return TarotCard(
      id: json['id'] as int,
      name: json['name'] as String,
      suit: json['suit'] as String,
      keywords: List<String>.from(json['keywords'] ?? []),
      uprightMeaning: json['upright_meaning'] as String,
      reversedMeaning: json['reversed_meaning'] as String,
      imagePromptKeywords: json['image_prompt_keywords'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'suit': suit,
      'keywords': keywords,
      'upright_meaning': uprightMeaning,
      'reversed_meaning': reversedMeaning,
      'image_prompt_keywords': imagePromptKeywords,
    };
  }
}
