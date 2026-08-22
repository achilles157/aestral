import 'package:flutter/material.dart';

import '../errors/oracle_rest_exception.dart';
import '../theme/app_theme.dart';

/// Dialog on-brand saat kuota Gemini harian habis (503 ORACLE_REST).
///
/// Tone mystical: Sesepuh Kosmis "sedang beristirahat", dengan hitung mundur
/// perkiraan kembali (dari `retryAfterSeconds` backend).
class OracleRestDialog extends StatelessWidget {
  final OracleRestException exception;

  const OracleRestDialog({super.key, required this.exception});

  /// Tampilkan dialog; aman dipanggil dari mana saja (pakai root navigator).
  static Future<void> show(
    BuildContext context,
    OracleRestException exception,
  ) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => OracleRestDialog(exception: exception),
    );
  }

  /// Tampilkan dialog hanya jika [error] adalah [OracleRestException].
  /// Dipanggil dari catch block screen AI — error lain dibiarkan ke flow
  /// existing (pesan generik) tanpa mengubah perilaku lama.
  static void showIfOracleRest(BuildContext context, Object error) {
    if (error is OracleRestException && context.mounted) {
      show(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.accentPurple.withValues(alpha: 0.45),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.purpleFadeGradient,
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.6),
                ),
              ),
              child: const Icon(
                Icons.nightlight_round,
                color: AppTheme.accentGold,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sesepuh Sedang Beristirahat',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              exception.friendlyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                'Kapasitas kosmis pulih ${exception.countdownLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  foregroundColor: AppTheme.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Baiklah, sampai nanti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
