import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'premium_controller.dart';
import 'widgets/feature_list_item.dart';
import 'widgets/pricing_card.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumControllerProvider);
    final controller = ref.read(premiumControllerProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.purchaseCompleted) {
        // Mock: burada anasayfaya yönlendirme + konfeti animasyonu tetiklenebilir.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium aktifleştirildi!'),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Hafif hareket eden soyut mor dalga efekti (mock - static gradient)
          Positioned.fill(
            child: CustomPaint(
              painter: _WaveBackgroundPainter(),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha:0.5),
                    AppColors.darkBackground,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _Header(),
                        const SizedBox(height: 24),
                        Text(
                          'Neden Datenow Premium?',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        const FeatureListItem(
                          text: 'Limitsiz kaydırma ve keşfetme.',
                        ),
                        const FeatureListItem(
                          text:
                              'Sınırları kaldır: 10 dakikalık görüntülü aramalar.',
                        ),
                        const FeatureListItem(
                          text: 'Sınırsız Datenow Live katılımı.',
                        ),
                        const FeatureListItem(
                          text:
                              'Buluşma ayarlamak için özel, kısıtlı mesajlaşma.',
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Planını seç',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        PricingCard(
                          id: PremiumPlanId.monthly,
                          title: '1 Aylık',
                          priceText: '99 ₺ / 4.99 \$',
                          subtitle: 'Aylık ödeme, istediğin zaman iptal.',
                          isPopular: false,
                          selected:
                              state.selectedPlan == PremiumPlanId.monthly,
                          onTap: () =>
                              controller.selectPlan(PremiumPlanId.monthly),
                        ),
                        const SizedBox(height: 12),
                        PricingCard(
                          id: PremiumPlanId.sixMonths,
                          title: '6 Aylık',
                          priceText: '499 ₺ / 24.99 \$',
                          subtitle: 'En iyi fiyat-performans seçeneği.',
                          isPopular: true,
                          selected:
                              state.selectedPlan == PremiumPlanId.sixMonths,
                          onTap: () =>
                              controller.selectPlan(PremiumPlanId.sixMonths),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
                // Sticky CTA
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.deepCharcoal.withValues(alpha:0.98),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.6),
                        offset: const Offset(0, -4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: state.isLoading
                            ? null
                            : () => controller.startPurchase(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                '7 Günlük Ücretsiz Denemeni Başlat',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'İstediğin zaman iptal edebilirsin.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.softGrey,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.accentPurpleSoft,
                Colors.transparent,
              ],
              radius: 0.8,
            ),
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.deepCharcoal,
              ),
              child: const Center(
                child: Text(
                  'D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Datenow Premium',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gerçek buluşmalara odaklanan, reklamsız ve sınırsız bir deneyim.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.softGrey,
          ),
        ),
      ],
    );
  }
}

class _WaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.accentPurple.withValues(alpha:0.25),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.3,
      size.width,
      size.height * 0.2,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.save();
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final dx = 8 * sin(t);
    canvas.translate(dx, 0);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaveBackgroundPainter oldDelegate) => true;
}

