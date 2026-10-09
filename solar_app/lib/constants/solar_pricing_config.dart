class SolarPricingConfig {
  /// Turnkey base solar price per kilowatt: Residential = ₹70,000, Commercial = ₹50,000
  static const double basePricePerKwResidential = 70000.0;
  static const double basePricePerKwCommercial = 50000.0;
  static const double basePricePerKw = 70000.0;

  /// Default electricity tariff rate in ₹/unit
  static const double defaultTariff = 7.0;

  /// Concessional PM Surya Ghar bank loan annual interest rate (SBI/Canara Bank ~5.76% p.a.)
  static const double defaultLoanInterestRate = 5.76;

  /// Default loan tenure in years
  static const int defaultLoanTenureYears = 5;

  /// Rated wattage of single TopCon Mono PERC solar plate
  static const int plateWattage = 540;

  /// Generation metrics: 4 units/kW/day * 30 days = 120 units/kW/month
  static const int unitsPerKwMonth = 120;
  static const double dailyUnitsPerKw = 4.0;

  /// Approximate shadow-free roof area per kilowatt (sq. ft.)
  static const int sqFtPerKw = 100;

  /// Base rate per kW depending on property type
  static double getRatePerKw(String propertyType) {
    if (propertyType.trim().toLowerCase() == 'commercial') {
      return basePricePerKwCommercial;
    }
    return basePricePerKwResidential;
  }

  /// Calculates turnkey base price from capacity and property type
  static double calculateBasePrice(double kw, [String propertyType = 'Residential']) {
    return kw > 0 ? (kw * getRatePerKw(propertyType)) : 0.0;
  }

  /// Calculates auto-estimated plate count from capacity
  static int calculatePlateCount(double kw) {
    if (kw <= 0) return 0;
    return ((kw * 1000) / plateWattage).ceil();
  }
}
