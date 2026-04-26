import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// BRAND COLOURS
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color success = Color(0xFF34A853);
  static const Color successDark = Color(0xFF1E8E3E);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningDark = Color(0xFFF57C00);
  static const Color error = Color(0xFFE53935);
  static const Color orange = Color(0xFFE65100);
  static const Color amber = Color(0xFFF9A825);
  static const Color purple = Color(0xFF7B1FA2);
  static const Color background = Color(0xFFF2F5FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
}

// ─────────────────────────────────────────────
// COVER TYPES
// ─────────────────────────────────────────────
class CoverTypes {
  CoverTypes._();

  static const String thirdParty = 'Third Party';
  static const String tpft = 'TP Fire & Theft';
  static const String comprehensive = 'Comprehensive';

  static const List<String> all = [thirdParty, tpft, comprehensive];

  static const Map<String, double> basePrices = {
    thirdParty: 500.0,
    tpft: 600.0,
    comprehensive: 720.0,
  };

  static const Map<String, IconData> icons = {
    thirdParty: Icons.gavel_outlined,
    tpft: Icons.local_fire_department_outlined,
    comprehensive: Icons.verified_user_outlined,
  };

  static const Map<String, Color> colors = {
    thirdParty: AppColors.orange,
    tpft: AppColors.amber,
    comprehensive: AppColors.primary,
  };

  static const Map<String, String> shortLabels = {
    thirdParty: 'TP Only',
    tpft: 'TPFT',
    comprehensive: 'Comprehensive',
  };

  static const Map<String, String> descriptions = {
    thirdParty: 'Legal minimum. Covers damage you cause to others.',
    tpft: 'Third party cover plus fire & theft protection.',
    comprehensive: 'Most complete cover including own-vehicle damage.',
  };

  static const Map<String, List<String>> inclusions = {
    thirdParty: [
      'Third party vehicle damage',
      'Third party personal injury',
      'Legal liability cover',
    ],
    tpft: [
      'All Third Party benefits',
      'Fire damage protection',
      'Theft & attempted theft',
    ],
    comprehensive: [
      'Accidental damage (fault & non-fault)',
      'Windscreen & glass cover',
      'Personal accident benefit',
      'Medical expenses',
      'Fire, theft & third party',
    ],
  };
}

// ─────────────────────────────────────────────
// CAR CATEGORIES
// ─────────────────────────────────────────────
class CarCategories {
  CarCategories._();

  static const String cityCar = 'City Car';
  static const String smallHatchback = 'Small Hatchback';
  static const String familyHatchback = 'Family Hatchback';
  static const String estateSaloon = 'Estate / Saloon';
  static const String suvCrossover = 'SUV / Crossover';
  static const String largeSuv = 'Large SUV';
  static const String sportsPerformance = 'Sports / Performance';
  static const String luxurySaloon = 'Luxury Saloon';
  static const String vanMpv = 'Van / MPV';

  static const List<String> all = [
    cityCar,
    smallHatchback,
    familyHatchback,
    estateSaloon,
    suvCrossover,
    largeSuv,
    sportsPerformance,
    luxurySaloon,
    vanMpv,
  ];

  /// Multipliers applied to the base cover-type price
  static const Map<String, double> multipliers = {
    cityCar: 0.70,
    smallHatchback: 0.85,
    familyHatchback: 1.00,
    estateSaloon: 1.10,
    suvCrossover: 1.25,
    largeSuv: 1.45,
    sportsPerformance: 2.20,
    luxurySaloon: 1.60,
    vanMpv: 1.35,
  };

  /// Indicative annual price ranges shown on the home screen
  static const Map<String, String> priceRanges = {
    cityCar: '£280–£600',
    smallHatchback: '£350–£750',
    familyHatchback: '£400–£900',
    estateSaloon: '£450–£950',
    suvCrossover: '£550–£1,200',
    largeSuv: '£700–£1,600',
    sportsPerformance: '£900–£3,000',
    luxurySaloon: '£600–£1,800',
    vanMpv: '£550–£1,300',
  };

  static const Map<String, String> examples = {
    cityCar: 'e.g. Fiat 500, Ford Ka',
    smallHatchback: 'e.g. Ford Fiesta, VW Polo',
    familyHatchback: 'e.g. Ford Focus, VW Golf',
    estateSaloon: 'e.g. VW Passat, Ford Mondeo',
    suvCrossover: 'e.g. Nissan Qashqai, Ford Kuga',
    largeSuv: 'e.g. BMW X5, Land Rover Discovery',
    sportsPerformance: 'e.g. Ford Mustang, BMW M3',
    luxurySaloon: 'e.g. BMW 5-Series, Mercedes E-Class',
    vanMpv: 'e.g. Ford Transit, Vauxhall Vivaro',
  };
}

// ─────────────────────────────────────────────
// VOLUNTARY EXCESS
// ─────────────────────────────────────────────
class ExcessOptions {
  ExcessOptions._();

  static const String standard = '£250 (Standard)';
  static const String moderate = '£500 (Moderate)';
  static const String higher = '£750 (Higher)';
  static const String maximum = '£1,000 (Maximum)';

  static const List<String> all = [standard, moderate, higher, maximum];

  /// Percentage discount applied to the total premium
  static const Map<String, double> discounts = {
    standard: 0.00,
    moderate: 0.05,
    higher: 0.10,
    maximum: 0.15,
  };
}

// ─────────────────────────────────────────────
// LICENCE TYPES
// ─────────────────────────────────────────────
class LicenceTypes {
  LicenceTypes._();

  static const String fullUk = 'Full UK';
  static const String provisional = 'Provisional';
  static const String international = 'International';
  static const String european = 'European';

  static const List<String> all = [fullUk, provisional, international, european];

  /// Flat surcharge added to running total
  static const Map<String, double> surcharges = {
    fullUk: 0.0,
    provisional: 380.0,
    international: 140.0,
    european: 80.0,
  };
}

// ─────────────────────────────────────────────
// FUEL TYPES
// ─────────────────────────────────────────────
class FuelTypes {
  FuelTypes._();

  static const String petrol = 'Petrol';
  static const String diesel = 'Diesel';
  static const String electric = 'Electric';
  static const String hybrid = 'Hybrid';

  static const List<String> all = [petrol, diesel, electric, hybrid];

  /// Flat adjustment (+/-) to the base premium
  static const Map<String, double> adjustments = {
    petrol: 0.0,
    diesel: 45.0,
    electric: -60.0,
    hybrid: -30.0,
  };
}

// ─────────────────────────────────────────────
// USAGE TYPES
// ─────────────────────────────────────────────
class UsageTypes {
  UsageTypes._();

  static const String socialOnly = 'Social only';
  static const String socialCommuting = 'Social & commuting';
  static const String businessUse = 'Business use';

  static const List<String> all = [socialOnly, socialCommuting, businessUse];

  static const Map<String, double> surcharges = {
    socialOnly: 0.0,
    socialCommuting: 120.0,
    businessUse: 280.0,
  };
}

// ─────────────────────────────────────────────
// NO CLAIMS DISCOUNT (NCD)
// ─────────────────────────────────────────────
class NcdOptions {
  NcdOptions._();

  static const List<String> all = [
    '0 years',
    '1 year',
    '2 years',
    '3 years',
    '4 years',
    '5+ years',
  ];

  /// Discount rate applied to the running total
  static const List<double> discountRates = [
    0.00, // 0 years
    0.15, // 1 year
    0.25, // 2 years
    0.35, // 3 years
    0.45, // 4 years
    0.55, // 5+ years
  ];

  static double rateForYears(int years) {
    final idx = years.clamp(0, discountRates.length - 1);
    return discountRates[idx];
  }
}

// ─────────────────────────────────────────────
// CLAIM TYPES
// ─────────────────────────────────────────────
class ClaimTypes {
  ClaimTypes._();

  static const String accident = 'Accident / Collision';
  static const String theft = 'Theft';
  static const String fire = 'Fire Damage';
  static const String windscreen = 'Windscreen';
  static const String vandalism = 'Vandalism';
  static const String flood = 'Flood / Weather Damage';
  static const String other = 'Other';

  static const List<String> all = [
    accident,
    theft,
    fire,
    windscreen,
    vandalism,
    flood,
    other,
  ];

  static const Map<String, IconData> icons = {
    accident: Icons.car_crash_outlined,
    theft: Icons.no_encryption_gmailerrorred_outlined,
    fire: Icons.local_fire_department_outlined,
    windscreen: Icons.window,
    vandalism: Icons.warning_amber_outlined,
    flood: Icons.water_damage_outlined,
    other: Icons.help_outline,
  };
}

// ─────────────────────────────────────────────
// POLICY STATUS
// ─────────────────────────────────────────────
class PolicyStatus {
  PolicyStatus._();

  static const String active = 'active';
  static const String expired = 'expired';
  static const String cancelled = 'cancelled';
  static const String pending = 'pending';

  static Color colorFor(String status) {
    switch (status) {
      case active:
        return AppColors.success;
      case pending:
        return AppColors.warning;
      case expired:
        return AppColors.textSecondary;
      case cancelled:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData iconFor(String status) {
    switch (status) {
      case active:
        return Icons.verified_rounded;
      case pending:
        return Icons.hourglass_empty_rounded;
      case expired:
        return Icons.event_busy_outlined;
      case cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}

// ─────────────────────────────────────────────
// CLAIM STATUS
// ─────────────────────────────────────────────
class ClaimStatus {
  ClaimStatus._();

  static const String submitted = 'submitted';
  static const String underReview = 'under_review';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String settled = 'settled';

  static const List<String> all = [
    submitted,
    underReview,
    approved,
    rejected,
    settled,
  ];

  static String label(String status) {
    switch (status) {
      case submitted:
        return 'Submitted';
      case underReview:
        return 'Under Review';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      case settled:
        return 'Settled';
      default:
        return status;
    }
  }

  static Color colorFor(String status) {
    switch (status) {
      case submitted:
        return AppColors.primary;
      case underReview:
        return AppColors.warning;
      case approved:
        return AppColors.success;
      case rejected:
        return AppColors.error;
      case settled:
        return AppColors.purple;
      default:
        return AppColors.textSecondary;
    }
  }
}

// ─────────────────────────────────────────────
// PRICING LIMITS
// ─────────────────────────────────────────────
class PricingLimits {
  PricingLimits._();

  static const double minAnnualPremium = 150.0;
  static const double maxAnnualPremium = 8000.0;

  /// Monthly finance charge divisor (slightly less than 12 to reflect interest)
  static const double monthlyDivisor = 11.5;
}

// ─────────────────────────────────────────────
// SUPABASE TABLE NAMES
// ─────────────────────────────────────────────
class SupabaseTables {
  SupabaseTables._();

  static const String quotes = 'quotes';
  static const String policies = 'policies';
  static const String claims = 'claims';
  static const String userProfiles = 'user_profiles';
  static const String vehicles = 'vehicles';
}
