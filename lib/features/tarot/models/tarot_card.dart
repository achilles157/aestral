class TarotCard {
  final int id;
  final String nameId;
  final String nameEn;
  final String suit;
  final String img;
  final List<String> keywordsId;
  final List<String> keywordsEn;
  final String uprightMeaningId;
  final String reversedMeaningId;
  final String uprightMeaningEn;
  final String reversedMeaningEn;
  final List<String> fortuneTellingId;
  final List<String> fortuneTellingEn;
  final List<String> questionsToAskId;
  final List<String> questionsToAskEn;
  final String elementalId;
  final String elementalEn;
  final String archetypeId;
  final String archetypeEn;
  final String numerologyId;
  final String numerologyEn;
  final String mythicalId;
  final String mythicalEn;
  final String imagePromptKeywordsId;
  final String imagePromptKeywordsEn;

  TarotCard({
    required this.id,
    required this.nameId,
    required this.nameEn,
    required this.suit,
    required this.img,
    required this.keywordsId,
    required this.keywordsEn,
    required this.uprightMeaningId,
    required this.reversedMeaningId,
    required this.uprightMeaningEn,
    required this.reversedMeaningEn,
    required this.fortuneTellingId,
    required this.fortuneTellingEn,
    required this.questionsToAskId,
    required this.questionsToAskEn,
    required this.elementalId,
    required this.elementalEn,
    required this.archetypeId,
    required this.archetypeEn,
    required this.numerologyId,
    required this.numerologyEn,
    required this.mythicalId,
    required this.mythicalEn,
    required this.imagePromptKeywordsId,
    required this.imagePromptKeywordsEn,
  });

  // Default getters to maintain backward compatibility with Indonesian UI
  String get name => nameId;
  List<String> get keywords => keywordsId;
  String get uprightMeaning => uprightMeaningId;
  String get reversedMeaning => reversedMeaningId;
  String get imagePromptKeywords => imagePromptKeywordsId;

  // Bilingual Helper Methods
  String getName(String lang) => lang == 'id' ? nameId : nameEn;
  List<String> getKeywords(String lang) => lang == 'id' ? keywordsId : keywordsEn;
  String getUprightMeaning(String lang) => lang == 'id' ? uprightMeaningId : uprightMeaningEn;
  String getReversedMeaning(String lang) => lang == 'id' ? reversedMeaningId : reversedMeaningEn;
  List<String> getFortuneTelling(String lang) => lang == 'id' ? fortuneTellingId : fortuneTellingEn;
  List<String> getQuestionsToAsk(String lang) => lang == 'id' ? questionsToAskId : questionsToAskEn;
  String getElemental(String lang) => lang == 'id' ? elementalId : elementalEn;
  String getArchetype(String lang) => lang == 'id' ? archetypeId : archetypeEn;
  String getNumerology(String lang) => lang == 'id' ? numerologyId : numerologyEn;
  String getMythical(String lang) => lang == 'id' ? mythicalId : mythicalEn;

  factory TarotCard.fromJson(Map<String, dynamic> json) {
    return TarotCard(
      id: json['id'] as int,
      nameId: json['name_id'] as String? ?? json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      suit: json['suit'] as String? ?? '',
      img: json['img'] as String? ?? '',
      keywordsId: List<String>.from(json['keywords_id'] ?? []),
      keywordsEn: List<String>.from(json['keywords_en'] ?? []),
      uprightMeaningId: json['upright_meaning_id'] as String? ?? json['upright_meaning'] as String? ?? '',
      reversedMeaningId: json['reversed_meaning_id'] as String? ?? json['reversed_meaning'] as String? ?? '',
      uprightMeaningEn: json['upright_meaning_en'] as String? ?? '',
      reversedMeaningEn: json['reversed_meaning_en'] as String? ?? '',
      fortuneTellingId: List<String>.from(json['fortune_telling_id'] ?? []),
      fortuneTellingEn: List<String>.from(json['fortune_telling_en'] ?? []),
      questionsToAskId: List<String>.from(json['questions_to_ask_id'] ?? []),
      questionsToAskEn: List<String>.from(json['questions_to_ask_en'] ?? []),
      elementalId: json['elemental_id'] as String? ?? '',
      elementalEn: json['elemental_en'] as String? ?? '',
      archetypeId: json['archetype_id'] as String? ?? '',
      archetypeEn: json['archetype_en'] as String? ?? '',
      numerologyId: json['numerology_id'] as String? ?? '',
      numerologyEn: json['numerology_en'] as String? ?? '',
      mythicalId: json['mythical_id'] as String? ?? '',
      mythicalEn: json['mythical_en'] as String? ?? '',
      imagePromptKeywordsId: json['image_prompt_keywords_id'] as String? ?? json['image_prompt_keywords'] as String? ?? '',
      imagePromptKeywordsEn: json['image_prompt_keywords_en'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_id': nameId,
      'name_en': nameEn,
      'suit': suit,
      'img': img,
      'keywords_id': keywordsId,
      'keywords_en': keywordsEn,
      'upright_meaning_id': uprightMeaningId,
      'reversed_meaning_id': reversedMeaningId,
      'upright_meaning_en': uprightMeaningEn,
      'reversed_meaning_en': reversedMeaningEn,
      'fortune_telling_id': fortuneTellingId,
      'fortune_telling_en': fortuneTellingEn,
      'questions_to_ask_id': questionsToAskId,
      'questions_to_ask_en': questionsToAskEn,
      'elemental_id': elementalId,
      'elemental_en': elementalEn,
      'archetype_id': archetypeId,
      'archetype_en': archetypeEn,
      'numerology_id': numerologyId,
      'numerology_en': numerologyEn,
      'mythical_id': mythicalId,
      'mythical_en': mythicalEn,
      'image_prompt_keywords_id': imagePromptKeywordsId,
      'image_prompt_keywords_en': imagePromptKeywordsEn,
    };
  }
}
