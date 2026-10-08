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
  final _tariffController = TextEditingController(text: '7');
  final _costPerKwController = TextEditingController(text: '55000');
  final _subsidyController = TextEditingController(text: '78000');

  String _propertyType = 'House / Ghar';
  bool _showAdvancedRates = false;

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _numFormat = NumberFormat('#,##,###', 'en_IN');

  static const int generationPerKwMonth = 120; // 4 units/kW/day * 30 days

  @override
  void dispose() {
    _billController.dispose;
    _kwController.dispose();
    _tariffController.dispose();
    _costPerKwController.dispose();
    _subsidyController.dispose();
    super.dispose();
  }

  double get _bill => double.tryParse(_billController.text) ?? 0;
  double get _kw => double.tryParse(_kwController.text) ?? 0;
  double get _tariff {
    final t = double.tryParse(_tariffController.text) ?? 7;
    return t > 0 ? t : 7;
  }
  double get _costPerKw => double.tryParse(_costPerKwController.text) ?? 55000;
  double get _subsidy => double.tryParse(_subsidyController.text) ?? 0;

  void _onBillChanged(String val) {
    setState(() {
      final nBill = double.tryParse(val) ?? 0;
      if (nBill > 0) {
        final recKw = ((nBill / _tariff) / generationPerKwMonth).ceil().toDouble();
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
        final estBill = (nKw * generationPerKwMonth * _tariff).round();
        _billController.text = estBill.toString();
        _updateAutoSubsidy(nKw);
      } else {
        _billController.text = '0';
      }
    });
  }

  void _updateAutoSubsidy(double kw) {
    // Standard PM Surya Ghar benchmark subsidy in India:
    // 1 kW: ~₹30,000 | 2 kW: ~₹60,000 | 3 kW and above: ~₹78,000
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
                    'Book Free Site Visit',
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
                'Quote: ${_kw.toInt()} kW System (Bill: ₹${_bill.toInt()}/mo)',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  hintText: 'e.g. Ramesh Kulkarni',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'e.g. 9822012345',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location / City *',
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
                          content: Text('Lead saved successfully! Check Admin Inbox.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save & Forward to Admin Box', style: TextStyle(fontWeight: FontWeight.bold)),
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

    final dailyGeneration = kw * 4;
    final monthlyGeneration = kw * generationPerKwMonth;
    final annualGeneration = monthlyGeneration * 12;
    final monthlySavings = monthlyGeneration * safeTariff;
    final annualSavings = annualGeneration * safeTariff;
    final grossCost = kw * _costPerKw;
    final effectiveSubsidy = hasKw ? _subsidy : 0.0;
    final netCost = (grossCost - effectiveSubsidy) > 0 ? (grossCost - effectiveSubsidy) : 0.0;
    final payback = (hasKw && annualSavings > 0) ? (netCost / annualSavings).toStringAsFixed(1) : '0';
    final lifetimeSavings = hasKw ? ((annualSavings * 25) - netCost) : 0.0;
    final roiPercent = (hasKw && netCost > 0) ? ((lifetimeSavings / netCost) * 100).round() : 0;

    final roofAreaSqFt = (kw * 100).round();
    final panelCount = (kw > 0) ? ((kw * 1000) / 540).ceil() : 0;
    final co2Kg = (annualGeneration * 0.82).round();
    final treesCount = (co2Kg / 20).round();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.sun,
                shape: BoxShape.circle,
              ),
              child: const Text('☼', style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            const Text('Sunward Solar Calculator'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Card
            Card(
              color: AppColors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTIMATE YOUR SYSTEM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
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
                              const Text('Monthly Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                              const Text('System Size (kW)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                    // Presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Quick: ', style: TextStyle(fontSize: 11, color: AppColors.muted)),
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
                    // Property Type
                    const Text('Property Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _propertyType,
                      decoration: const InputDecoration(),
                      items: const [
                        DropdownMenuItem(value: 'House / Ghar', child: Text('House / Ghar (Residential)')),
                        DropdownMenuItem(value: 'Shop / Dukaan', child: Text('Shop / Commercial Dukaan')),
                        DropdownMenuItem(value: 'Office', child: Text('Office / Corporate')),
                        DropdownMenuItem(value: 'Factory', child: Text('Factory / Industrial')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _propertyType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Expandable Custom Rates Toggle
                    InkWell(
                      onTap: () => setState(() => _showAdvancedRates = !_showAdvancedRates),
                      child: Row(
                        children: [
                          Icon(
                            _showAdvancedRates ? Icons.expand_less : Icons.tune,
                            size: 16,
                            color: AppColors.coral,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showAdvancedRates ? 'Hide Custom Rates' : 'Customize Rates & Subsidy',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.coral,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showAdvancedRates) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tariffController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Tariff (₹/unit)',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _costPerKwController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price (₹/kW)',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _subsidyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Govt Subsidy Amount (₹)',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Financial & Return Card (Hero Accent)
            Container(
              decoration: BoxDecoration(
                color: AppColors.sun,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
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
                            'SOLAR ESTIMATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '${kw.toStringAsFixed(kw % 1 == 0 ? 0 : 1)} kW System Hisaab',
                            style: const TextStyle(
                              fontSize: 18,
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
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$payback yrs Payback',
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

                  // Three Big Numbers Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeroStat('Net Cost', _currencyFormat.format(netCost), 'after subsidy'),
                        Container(width: 1, height: 36, color: AppColors.ink.withOpacity(0.15)),
                        _buildHeroStat('Yearly Savings', _currencyFormat.format(annualSavings), '₹${_numFormat.format(monthlySavings)}/mo'),
                        Container(width: 1, height: 36, color: AppColors.ink.withOpacity(0.15)),
                        _buildHeroStat('25-Yr Profit', _currencyFormat.format(lifetimeSavings > 0 ? lifetimeSavings : 0), '$roiPercent% ROI'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4-tile grid breakdown
                  Row(
                    children: [
                      Expanded(
                        child: _buildBreakdownBox(
                          'Gross Cost',
                          _currencyFormat.format(grossCost),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildBreakdownBox(
                          'Govt Subsidy',
                          effectiveSubsidy > 0 ? '-${_currencyFormat.format(effectiveSubsidy)}' : '₹0',
                          valueColor: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBreakdownBox(
                          'Daily Power',
                          '~${_numFormat.format(dailyGeneration)} Units',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildBreakdownBox(
                          'Annual Power',
                          '~${_numFormat.format(annualGeneration)} Units',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Technical & Environmental Specs
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TECHNICAL & ENVIRONMENTAL SPECS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSpecItem('Panels (540W)', '~$panelCount Nos'),
                            _buildSpecItem('Rooftop Area', '~$roofAreaSqFt sq.ft.'),
                            _buildSpecItem('CO₂ Saved', '${_numFormat.format(co2Kg)} kg ($treesCount 🌲)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text(
                        'Capture Lead & Site Visit',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _buildHeroStat(String label, String value, String sub) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 1),
        Text(sub, style: TextStyle(fontSize: 9, color: AppColors.ink.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildBreakdownBox(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: AppColors.ink.withOpacity(0.7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: AppColors.ink.withOpacity(0.6))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink)),
      ],
    );
  }
}
