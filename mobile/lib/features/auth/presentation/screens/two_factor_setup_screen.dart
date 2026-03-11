import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';

final mockTotpSecretProvider = Provider<String>((ref) {
  // Mock base32 secret; gerçekte backend'den gelir.
  return 'JBSWY3DPEHPK3PXP';
});

class TwoFactorSetupScreen extends ConsumerWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secret = ref.watch(mockTotpSecretProvider);
    final otpauthUrl =
        'otpauth://totp/Datenow:example@mail.com?secret=$secret&issuer=Datenow';

    return Scaffold(
      appBar: AppBar(
        title: const Text('İki Adımlı Doğrulama'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Hesabını Google Authenticator veya benzeri bir uygulamaya ekle.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.softGrey,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.deepCharcoal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: otpauthUrl,
                version: QrVersions.auto,
                size: 180,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Secret: $secret',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.softGrey,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Uygulamadaki 6 haneli kodu gir.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Pinput(
              length: 6,
              defaultPinTheme: PinTheme(
                width: 48,
                height: 56,
                textStyle: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
                decoration: BoxDecoration(
                  color: AppColors.deepCharcoal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
              ),
              onCompleted: (code) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kod doğrulandı (mock): $code'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

