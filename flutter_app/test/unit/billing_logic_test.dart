import 'package:flutter_test/flutter_test.dart';

// Simple implementation to test logic (actual logic is in views/stats_view.dart or similar, 
// usually we should move it to a separate service/utility for better testability).
double calculateCost(double energy, List<double> tiers) {
  double total = 0;
  double remaining = energy;
  
  // Example tiers: [50, 50, 100, 100, 100] kWh
  // For simplicity, let's say energy is in kWh
  List<double> limits = [50, 100, 200, 300, 400];
  
  for (int i = 0; i < tiers.length; i++) {
    double tierLimit = (i == 0) ? limits[0] : (limits[i] - limits[i-1]);
    if (remaining > tierLimit) {
      total += tierLimit * tiers[i];
      remaining -= tierLimit;
    } else {
      total += remaining * tiers[i];
      remaining = 0;
      break;
    }
  }
  if (remaining > 0) {
    total += remaining * tiers.last;
  }
  
  return total * 1.1; // 10% VAT
}

void main() {
  group('Billing Logic tests', () {
    final tiers = [1984.0, 2380.0, 2998.0, 3571.0, 3967.0];

    test('Calculate cost for 40kWh (Tier 1)', () {
      final cost = calculateCost(40, tiers);
      // 40 * 1984 * 1.1 = 87296
      expect(cost, closeTo(87296.0, 0.1));
    });

    test('Calculate cost for 75kWh (Tier 1 + 2)', () {
      final cost = calculateCost(75, tiers);
      // Tier 1: 50 * 1984 = 99200
      // Tier 2: 25 * 2380 = 59500
      // Total: (99200 + 59500) * 1.1 = 174570
      expect(cost, closeTo(174570.0, 0.1));
    });

    test('Calculate cost for 500kWh (All Tiers + Surplus)', () {
      final cost = calculateCost(500, tiers);
      // Tier 1 (50): 50 * 1984 = 99200
      // Tier 2 (50): 50 * 2380 = 119000
      // Tier 3 (100): 100 * 2998 = 299800
      // Tier 4 (100): 100 * 3571 = 357100
      // Tier 5 (100): 100 * 3967 = 396700
      // Surplus (100): 100 * 3967 = 396700
      // Total: (99200 + 119000 + 299800 + 357100 + 396700 + 396700) * 1.1 = 1668500 * 1.1 = 1835350
      expect(cost, closeTo(1835350.0, 0.1));
    });
  });
}
