import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tarot_card.dart';

final tarotDeckProvider = FutureProvider<List<TarotCard>>((ref) async {
  final String jsonString = await rootBundle.loadString(
    'assets/tarot/tarot-merged.json',
  );
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((json) => TarotCard.fromJson(json)).toList();
});

class DrawnCardInfo {
  final TarotCard card;
  final bool isReversed;
  final String label; // "past" | "present" | "future"

  DrawnCardInfo({
    required this.card,
    required this.isReversed,
    required this.label,
  });
}

class DrawnCardNotifier extends Notifier<List<DrawnCardInfo>?> {
  @override
  List<DrawnCardInfo>? build() {
    return null;
  }

  void drawCard(List<TarotCard> deck) {
    if (deck.length < 3) return;

    // Draw 3 unique random cards from local deck
    final random = Random();
    final List<TarotCard> chosenCards = [];
    final List<bool> chosenReversals = [];

    while (chosenCards.length < 3) {
      final card = deck[random.nextInt(deck.length)];
      if (!chosenCards.contains(card)) {
        chosenCards.add(card);
        chosenReversals.add(random.nextBool());
      }
    }

    state = [
      DrawnCardInfo(
        card: chosenCards[0],
        isReversed: chosenReversals[0],
        label: 'past',
      ),
      DrawnCardInfo(
        card: chosenCards[1],
        isReversed: chosenReversals[1],
        label: 'present',
      ),
      DrawnCardInfo(
        card: chosenCards[2],
        isReversed: chosenReversals[2],
        label: 'future',
      ),
    ];
  }

  void setCards(List<DrawnCardInfo> cards) {
    state = cards;
  }

  void reset() {
    state = null;
  }
}

final drawnCardProvider =
    NotifierProvider<DrawnCardNotifier, List<DrawnCardInfo>?>(() {
      return DrawnCardNotifier();
    });
