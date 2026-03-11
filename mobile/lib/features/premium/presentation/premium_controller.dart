import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PremiumPlanId { monthly, sixMonths }

class PremiumState {
  final PremiumPlanId selectedPlan;
  final bool isLoading;
  final bool purchaseCompleted;

  const PremiumState({
    required this.selectedPlan,
    required this.isLoading,
    required this.purchaseCompleted,
  });

  PremiumState copyWith({
    PremiumPlanId? selectedPlan,
    bool? isLoading,
    bool? purchaseCompleted,
  }) {
    return PremiumState(
      selectedPlan: selectedPlan ?? this.selectedPlan,
      isLoading: isLoading ?? this.isLoading,
      purchaseCompleted: purchaseCompleted ?? this.purchaseCompleted,
    );
  }
}

class PremiumController extends StateNotifier<PremiumState> {
  PremiumController()
      : super(const PremiumState(
          selectedPlan: PremiumPlanId.monthly,
          isLoading: false,
          purchaseCompleted: false,
        ));

  void selectPlan(PremiumPlanId id) {
    if (state.isLoading) return;
    state = state.copyWith(selectedPlan: id);
  }

  Future<void> startPurchase() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    // Mock IAP işlemi – burada gerçek satın alma entegrasyonu devreye girecek.
    await Future<void>.delayed(const Duration(seconds: 2));

    state = state.copyWith(
      isLoading: false,
      purchaseCompleted: true,
    );
  }
}

final premiumControllerProvider =
    StateNotifierProvider<PremiumController, PremiumState>(
  (ref) => PremiumController(),
);

