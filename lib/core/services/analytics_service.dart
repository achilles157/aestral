import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized Firebase Analytics service.
/// Semua event di-log melalui static methods — fire-and-forget, non-fatal.
class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;

  /// NavigatorObserver untuk auto-track screen_view di MaterialApp.
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Feature events ────────────────────────────────────────────────────────

  static Future<void> logWetonCalculated(String wetonName, int neptu) =>
      _log('weton_calculated', {
        'weton_name': wetonName,
        'neptu': neptu.toString(),
      });

  static Future<void> logBaziCalculated(String dayMaster) =>
      _log('bazi_calculated', {'day_master': dayMaster});

  static Future<void> logTarotDrawn(String drawType) =>
      _log('tarot_drawn', {'draw_type': drawType});

  static Future<void> logOracleSessionStarted(String oracleType) =>
      _log('oracle_session_started', {'oracle_type': oracleType});

  static Future<void> logOracleMessageSent(String oracleType) =>
      _log('oracle_message_sent', {'oracle_type': oracleType});

  static Future<void> logCompatibilityChecked(String system) =>
      _log('compatibility_checked', {'system': system}); // 'weton' | 'bazi'

  static Future<void> logHistoryViewed() => _log('history_viewed');

  // ── Conversion events ─────────────────────────────────────────────────────

  static Future<void> logGuestUpsellShown(String source) =>
      _log('guest_upsell_shown', {'source': source});

  static Future<void> logSesepuhKosmisOpened() =>
      _log('sesepuh_kosmis_opened');

  // ── User properties ───────────────────────────────────────────────────────

  /// Set setelah user input tanggal lahir — untuk segmentasi.
  static Future<void> setHasProfile(bool value) async {
    try {
      await _analytics.setUserProperty(
        name: 'has_profile',
        value: value ? 'true' : 'false',
      );
    } catch (e) {
      debugPrint('Analytics setUserProperty error (non-fatal): $e');
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static Future<void> _log(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics logEvent "$name" error (non-fatal): $e');
    }
  }
}
