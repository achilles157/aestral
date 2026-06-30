import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tarot_card.dart';

final tarotDeckProvider = FutureProvider<List<TarotCard>>((ref) async {
  final String jsonString = await rootBundle.loadString('assets/tarot/tarot-merged.json');
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((json) => TarotCard.fromJson(json)).toList();
});

class DrawnCardInfo {
  final TarotCard card;
  final bool isReversed;

  DrawnCardInfo({required this.card, required this.isReversed});
}

class DrawnCardNotifier extends Notifier<DrawnCardInfo?> {
  @override
  DrawnCardInfo? build() {
    return null;
  }

  void drawCard(List<TarotCard> deck) {
    if (deck.isEmpty) return;
    final random = Random();
    final card = deck[random.nextInt(deck.length)];
    final isReversed = random.nextBool(); // 50% chance of being reversed
    state = DrawnCardInfo(card: card, isReversed: isReversed);
  }

  void setCard(TarotCard card, bool isReversed) {
    state = DrawnCardInfo(card: card, isReversed: isReversed);
  }

  void reset() {
    state = null;
  }
}

final drawnCardProvider = NotifierProvider<DrawnCardNotifier, DrawnCardInfo?>(() {
  return DrawnCardNotifier();
});
