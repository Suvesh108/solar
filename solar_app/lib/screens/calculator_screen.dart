import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/lead_service.dart';
import '../theme/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _billController = TextEditingController(text: '5000');
  final _kwController = TextEditingController(text: '3');
  
  // Custom Rates (always visible, fully editable)
  final _tariffController = TextEditingController(text: '7');
  final _panelRateController = TextEditingController(text: '45000');
  final _installRateController = TextEditingController(text: '10000');
  final _extraCostController = TextEditingController(text: '15000');
  final _subsidyController = TextEditingController(text: '78000');

  String _propertyType = 'House / Ghar';

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _numFormat = NumberFormat('#,##,###', 'en_IN');

  static const int unitsPerKwMonth = 120; // 4 units per kW per day * 30 days

  @override
  void dispose() {
    _billController.dispose();
    _kwController.dispose();
    _tariffController.dispose();
    _panelRateController.dispose();
    _installRateController.dispose();
    _extraCostController.dispose();
    _subsidyController.dispose();
    super.dispose();
  }

  double get _bill => double.tryParse(_billController.text) ?? 0;
  double get _kw => double.tryParse(_kwController.text) ?? 0;
  double get _tariff {
    final t = double.tryParse(_tariffController.text) ?? 7;
    return t > 0 ? t : 7;
  }
  double get _panelRate => double.tryParse(_panelRateController.text) ?? 45000;
  double get _installRate => double.tryParse(_installRateController.text) ?? 10000;
  double get _extraCost => double.tryParse(_extraCostController.text) ?? 15000;
  double get _subsidy => double.tryParse(_subsidyController.text) ?? 0;

  void _onBillChanged(String val) {
    setState(() {
      final nBill = double.tryParse(val) ?? 0;
      if (nBill > 0) {
        final recKw = ((nBill / _tariff) / unitsPerKwMonth).ceil().toDouble();
        final finalKw = recKw < 1 ? 1.0 : recKw;
        _kwController.text = finalKw.toInt().toString();
        _updateAutoSubsidy(finalKw);
      } else {
        _kwController.text = '0';
      }
    });
  }

  void _onKwChanged(String val) {
    setState(() {
      final nKw = double.tryParse(val) ?? 0;
      if (nKw > 0) {
        final estBill = (nKw * unitsPerKwMonth * _tariff).round();
        _billController.text = estBill.toString();
        _updateAutoSubsidy(nKw);
      } else {
        _billController.text = '0';
      }
    });
  }

  void _updateAutoSubsidy(double kw) {
    // PM Surya Ghar Benchmark: 1kW=₹30,000, 2kW=₹60,000, 3kW+=₹78,000
    if (kw <= 0) {
      _subsidyController.text = '0';
    } else if (kw == 1) {
      _subsidyController.text = '30000';
    } else if (kw == 2) {
      _subsidyController.text = '60000';
    } else {
      _subsidyController.text = '78000';
    }
  }

  void _selectKwPreset(int kw) {
    _kwController.text = kw.toString();
    _onKwChanged(kw.toString());
  }

  void _showSaveLeadDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Free Site Checkup & Quote',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                'System: ${_kw.toInt()} kW Solar System (Bijli Bill: ₹${_bill.toInt()}/month)',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Customer Name / Aapka Naam *',
                  hintText: 'e.g. Ramesh Kulkarni',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number / Mobile *',
                  hintText: 'e.g. 9822012345',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location / City / Shahar *',
                  hintText: 'e.g. Pune, Maharashtra',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter name and phone number')),
                      );
                      return;
                    }

                    await LeadService.instance.addLead(
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      location: locationCtrl.text.trim().isEmpty ? 'Direct' : locationCtrl.text.trim(),
                      monthlyBill: _bill.toInt().toString(),
                      propertyType: _propertyType,
                    );

                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.teal,
                          content: Text('Lead saved successfully! Check the Leads tab.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save & Send to Leads Tab', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kw = _kw;
    final hasKw = kw > 0;
    final safeTariff = _tariff;

    // Detailed Math
    final panelsCost = kw * _panelRate;
    final installCost = kw * _installRate;
    final otherCost = _extraCost;
    final totalSystemCost = panelsCost + installCost + otherCost;
    final effectiveSubsidy = hasKw ? _subsidy : 0.0;
    final finalPriceYouPay = (totalSystemCost - effectiveSubsidy) > 0 ? (totalSystemCost - effectiveSubsidy) : 0.0;

    final dailyUnits = kw * 4;
    final monthlyUnits = kw * unitsPerKwMonth;
    final annualUnits = monthlyUnits * 12;
    final monthlySavings = monthlyUnits * safeTariff;
    final annualSavings = annualUnits * safeTariff;

    final paybackYears = (hasKw && annualSavings > 0)
        ? (finalPriceYouPay / annualSavings).toStringAsFixed(1)
        : '0';
    final lifetimeProfit = hasKw ? ((annualSavings * 25) - finalPriceYouPay) : 0.0;

    final roofAreaSqFt = (kw * 100).round();
    final panelCount = (kw > 0) ? ((kw * 1000) / 540).ceil() : 0;
    final co2Kg = (annualUnits * 0.82).round();
    final treesCount = (co2Kg / 20).round();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/logo.png',
                height: 34,
                width: 34,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Sunward Solar'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // STEP 1: Basic Usage Inputs Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. APNA BIJLI KHARCHA ENTER KAREIN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monthly Bijli Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _billController,
                                keyboardType: TextInputType.number,
                                onChanged: _onBillChanged,
                                decoration: const InputDecoration(
                                  prefixText: '₹ ',
                                  prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Solar Size (kW)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _kwController,
                                keyboardType: TextInputType.number,
                                onChanged: _onKwChanged,
                                decoration: const InputDecoration(
                                  suffixText: 'kW',
                                  suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Quick presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Quick Size: ', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                          for (final p in [1, 2, 3, 5, 10, 15]) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text('${p}kW'),
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: kw.toInt() == p ? AppColors.ink : AppColors.muted,
                                ),
                                selected: kw.toInt() == p,
                                selectedColor: AppColors.sun,
                                backgroundColor: AppColors.cream,
                                showCheckmark: false,
                                onSelected: (_) => _selectKwPreset(p),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Property Type / Kahan Lagana Hai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _propertyType,
                      decoration: const InputDecoration(),
                      items: const [
                        DropdownMenuItem(value: 'House / Ghar', child: Text('House / Ghar (Residential)')),
                        DropdownMenuItem(value: 'Shop / Dukaan', child: Text('Shop / Commercial Dukaan')),
                        DropdownMenuItem(value: 'Office', child: Text('Office / Corporate')),
                        DropdownMenuItem(value: 'Factory', child: Text('Factory / Industrial Karkhana')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _propertyType = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // STEP 2: Custom Rates & Price Breakdown (Always Visible)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 18, color: AppColors.teal),
                        const SizedBox(width: 8),
                        const Text(
                          '2. RATES & COST SETTINGS (CUSTOM RATE)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'All rates are fully customizable for your local market:',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),

                    // Grid of Rates
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tariffController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Bijli Rate (₹/unit)',
                              helperText: 'Current power cost',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _panelRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Solar Plates (₹/kW)',
                              helperText: 'Hardware price',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _installRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Fitting / Labour (₹/kW)',
                              helperText: 'Structure & fitting',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _extraCostController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Wiring & Inverter (₹)',
                              helperText: 'Lumpsum other cost',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _subsidyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sarkari Subsidy / Govt Discount (₹)',
                        helperText: 'PM Surya Ghar scheme discount',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // STEP 3: Enhanced Solar Estimate Box (Simple everyday words)
            Container(
              decoration: BoxDecoration(
                color: AppColors.sun,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AAPKA COMPLETE HISAAB',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '${kw.toStringAsFixed(kw % 1 == 0 ? 0 : 1)} kW Solar System Estimate',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$paybackYears Saal Vasool',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Three Main Hero Numbers
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeroStat(
                          'Aapka Kharcha',
                          _currencyFormat.format(finalPriceYouPay),
                          'Subsidy ke baad',
                        ),
                        Container(width: 1, height: 42, color: AppColors.ink.withOpacity(0.18)),
                        _buildHeroStat(
                          'Saal Ki Bachat',
                          _currencyFormat.format(annualSavings),
                          '₹${_numFormat.format(monthlySavings)}/month',
                        ),
                        Container(width: 1, height: 42, color: AppColors.ink.withOpacity(0.18)),
                        _buildHeroStat(
                          '25 Saal Munafa',
                          _currencyFormat.format(lifetimeProfit > 0 ? lifetimeProfit : 0),
                          'Total savings',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Cost Breakdown Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PAISA KAHAN LAGEGA (COST BREAKDOWN)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        _buildPriceRow('Solar Plates (${kw.toInt()} kW)', _currencyFormat.format(panelsCost)),
                        _buildPriceRow('Fitting & Structure', _currencyFormat.format(installCost)),
                        _buildPriceRow('Inverter & Wiring', _currencyFormat.format(otherCost)),
                        const Divider(height: 14, thickness: 1, color: AppColors.ink),
                        _buildPriceRow('Kul Kharcha (Total Price)', _currencyFormat.format(totalSystemCost), isBold: true),
                        _buildPriceRow('Sarkari Subsidy Discount', effectiveSubsidy > 0 ? '-${_currencyFormat.format(effectiveSubsidy)}' : '₹0', isGreen: true),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Aapko Dena Hoga:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink),
                            ),
                            Text(
                              _currencyFormat.format(finalPriceYouPay),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Technical & Rooftop Space Specs
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CHHAT AUR BIJLI KI DETAILS (SPECS)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSpecBox('Rozana Bijli', '~$dailyUnits Units'),
                            _buildSpecBox('Solar Plates', '~$panelCount Plates (540W)'),
                            _buildSpecBox('Chhat Ki Jagah', '~$roofAreaSqFt sq.ft.'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.home_work_rounded, size: 20),
                      label: const Text(
                        'Ghar Pe Free Checkup & Quote Mangwayein',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () => _showSaveLeadDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(String title, String mainValue, String sub) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 3),
        Text(mainValue, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 9, color: AppColors.ink.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isGreen ? AppColors.teal : AppColors.ink,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isGreen ? AppColors.teal : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecBox(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 9, color: AppColors.ink.withOpacity(0.7))),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink)),
      ],
    );
  }
}
