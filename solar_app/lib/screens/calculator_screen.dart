import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/language_service.dart';
import '../services/lead_service.dart';
import '../services/quote_share_service.dart';
import '../theme/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with SingleTickerProviderStateMixin {
  final _billController = TextEditingController(text: '5000');
  final _kwController = TextEditingController(text: '3.0');
  
  // Custom Rates & Hardware Plate Settings
  final _plateCountController = TextEditingController(text: '6');
  final _plateCostController = TextEditingController(text: '7500'); // ₹7,500 per 540W plate
  final _tariffController = TextEditingController(text: '7');       // ₹7/unit
  final _installRateController = TextEditingController(text: '10000'); // ₹10,000/kW fitting
  final _extraCostController = TextEditingController(text: '15000');  // Inverter & Wiring
  final _subsidyController = TextEditingController(text: '98000');   // Govt Subsidy

  // Bank Loan & EMI Settings
  final _loanAmountController = TextEditingController(text: '0');
  final _interestRateController = TextEditingController(text: '8.5'); // 8.5% p.a.
  final _loanTenureController = TextEditingController(text: '5');      // 5 years

  String _propertyType = 'Residential';
  final GlobalKey _quotationBoundaryKey = GlobalKey();

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _numFormat = NumberFormat('#,##,###', 'en_IN');

  static const int unitsPerKwMonth = 120; // 4 units/kW/day * 30 days
  static const int plateWattage = 540;   // 540W Mono PERC TopCon plates

  @override
  void initState() {
    super.initState();
    _recalculateSubsidy(3.0, _propertyType);
  }

  @override
  void dispose() {
    _billController.dispose();
    _kwController.dispose();
    _plateCountController.dispose();
    _plateCostController.dispose();
    _tariffController.dispose();
    _installRateController.dispose();
    _extraCostController.dispose();
    _subsidyController.dispose();
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _loanTenureController.dispose();
    super.dispose();
  }

  double get _bill => double.tryParse(_billController.text) ?? 0;
  double get _kw => double.tryParse(_kwController.text) ?? 0;
  int get _plateCount => int.tryParse(_plateCountController.text) ?? 0;
  double get _plateCost => double.tryParse(_plateCostController.text) ?? 7500;
  double get _tariff {
    final t = double.tryParse(_tariffController.text) ?? 7;
    return t > 0 ? t : 7;
  }
  double get _installRate => double.tryParse(_installRateController.text) ?? 10000;
  double get _extraCost => double.tryParse(_extraCostController.text) ?? 15000;
  double get _subsidy => double.tryParse(_subsidyController.text) ?? 0;

  double get _loanAmount => double.tryParse(_loanAmountController.text) ?? 0;
  double get _interestRate => double.tryParse(_interestRateController.text) ?? 8.5;
  int get _loanTenureYears {
    final y = int.tryParse(_loanTenureController.text) ?? 5;
    return y > 0 ? y : 1;
  }

  double _calculateMonthlyEmi(double principal, double annualRate, int years) {
    if (principal <= 0 || years <= 0) return 0.0;
    if (annualRate <= 0) return principal / (years * 12);
    final monthlyRate = annualRate / (12 * 100);
    final months = years * 12;
    final factor = math.pow(1 + monthlyRate, months);
    return (principal * monthlyRate * factor) / (factor - 1);
  }

  double _computeSubsidyFor(double kw, String propType) {
    // Only Residential qualifies for PM Surya Ghar subsidy
    if (propType != 'Residential' || kw <= 0) {
      return 0.0;
    }

    // Official PM Surya Ghar Subsidy:
    // 1 kW = ₹40,000 | 2 kW = ₹80,000 | 3 kW and above = ₹98,000
    if (kw < 2.0) {
      return 40000.0;
    } else if (kw < 3.0) {
      return 80000.0;
    } else {
      return 98000.0;
    }
  }

  void _recalculateSubsidy(double kw, String propType) {
    final sub = _computeSubsidyFor(kw, propType);
    _subsidyController.text = sub.round().toString();
  }

  void _onBillChanged(String val) {
    setState(() {
      final nBill = double.tryParse(val) ?? 0;
      if (nBill > 0) {
        final recKw = ((nBill / _tariff) / unitsPerKwMonth).ceil().toDouble();
        final finalKw = recKw < 1.0 ? 1.0 : recKw;
        _kwController.text = finalKw.toStringAsFixed(1);
        final plates = ((finalKw * 1000) / plateWattage).ceil();
        _plateCountController.text = plates.toString();
        _recalculateSubsidy(finalKw, _propertyType);
      } else {
        _kwController.text = '0';
        _plateCountController.text = '0';
        _subsidyController.text = '0';
      }
    });
  }

  void _onKwChanged(String val) {
    setState(() {
      final nKw = double.tryParse(val) ?? 0;
      if (nKw > 0) {
        final estBill = (nKw * unitsPerKwMonth * _tariff).round();
        _billController.text = estBill.toString();
        final plates = ((nKw * 1000) / plateWattage).ceil();
        _plateCountController.text = plates.toString();
        _recalculateSubsidy(nKw, _propertyType);
      } else {
        _billController.text = '0';
        _plateCountController.text = '0';
        _subsidyController.text = '0';
      }
    });
  }

  void _onPlateCountChanged(String val) {
    setState(() {
      final pCount = int.tryParse(val) ?? 0;
      if (pCount > 0) {
        final calcKw = (pCount * plateWattage) / 1000.0;
        _kwController.text = calcKw.toStringAsFixed(1);
        final estBill = (calcKw * unitsPerKwMonth * _tariff).round();
        _billController.text = estBill.toString();
        _recalculateSubsidy(calcKw, _propertyType);
      } else {
        _kwController.text = '0';
        _billController.text = '0';
        _subsidyController.text = '0';
      }
    });
  }

  void _onPropertyTypeChanged(String? val) {
    if (val == null) return;
    setState(() {
      _propertyType = val;
      _recalculateSubsidy(_kw, val);
    });
  }

  void _selectKwPreset(double kw) {
    _kwController.text = kw.toStringAsFixed(1);
    _onKwChanged(kw.toString());
  }

  void _showQuoteDialog(BuildContext context) {
    final lang = LanguageService.instance;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    final kw = _kw;
    final pCount = _plateCount;
    final pCost = _plateCost;
    final totalPlatesCost = pCount * pCost;
    final installCost = kw * _installRate;
    final extraCost = _extraCost;
    final totalSystemCost = totalPlatesCost + installCost + extraCost;
    final sub = _subsidy;
    final netPayable = (totalSystemCost - sub) > 0 ? (totalSystemCost - sub) : 0.0;
    final monthlySavings = kw * unitsPerKwMonth * _tariff;
    final annualSavings = monthlySavings * 12;
    final payback = annualSavings > 0 ? (netPayable / annualSavings).toStringAsFixed(1) : '0';
    final profit25 = (annualSavings * 25) - netPayable;

    final loanAmt = _loanAmount;
    final rate = _interestRate;
    final years = _loanTenureYears;
    final emi = _calculateMonthlyEmi(loanAmt, rate, years);
    final downPayment = (netPayable - loanAmt) > 0 ? (netPayable - loanAmt) : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lang.t('Customer Quotation & Booking', 'ग्राहक कोटेशन व बुकिंग'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Visual Quotation Receipt Card for capture
              RepaintBoundary(
                key: _quotationBoundaryKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset('assets/logo.png', height: 28, width: 28),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'SUNWARD SOLAR',
                                style: TextStyle(
                                  color: AppColors.sun,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.sun,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${kw.toStringAsFixed(1)} kW System',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildReceiptMiniStat('Solar Plates', '$pCount Nos (540W)'),
                          _buildReceiptMiniStat('Net Price', _currencyFormat.format(netPayable)),
                          _buildReceiptMiniStat('Payback', '$payback Yrs'),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Price: ${_currencyFormat.format(totalSystemCost)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          Text(
                            'Subsidy: -${_currencyFormat.format(sub)}',
                            style: const TextStyle(color: AppColors.sun, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (loanAmt > 0) ...[
                        const Divider(color: Colors.white24, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildReceiptMiniStat('Bank Loan', _currencyFormat.format(loanAmt)),
                            _buildReceiptMiniStat('Monthly EMI', '${_currencyFormat.format(emi)}/mo'),
                            _buildReceiptMiniStat('Down Payment', _currencyFormat.format(downPayment)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: lang.t('Customer Name *', 'ग्राहक का नाम *'),
                  hintText: 'e.g. Ramesh Kulkarni',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: lang.t('Mobile / WhatsApp Number *', 'मोबाइल / व्हाट्सऐप नंबर *'),
                  hintText: 'e.g. 9822012345',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                  labelText: lang.t('Location / City *', 'शहर / इलाका *'),
                  hintText: 'e.g. Pune, Maharashtra',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 18),

              // Action 1: Save Lead & Send Directly via WhatsApp
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp brand green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.chat, size: 20),
                label: Text(
                  lang.t('Send Quote to WhatsApp', 'व्हाट्सऐप पर कोटेशन भेजें'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final phone = phoneCtrl.text.trim();
                  final loc = locationCtrl.text.trim();

                  if (name.isEmpty || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(lang.t('Please enter name and phone number', 'कृपया नाम और फोन नंबर दर्ज करें'))),
                    );
                    return;
                  }

                  // 1. Save Lead
                  await LeadService.instance.addLead(
                    name: name,
                    phone: phone,
                    location: loc.isEmpty ? 'Direct' : loc,
                    monthlyBill: _bill.toInt().toString(),
                    propertyType: _propertyType,
                  );

                  // 2. Format Quote
                  final quoteMsg = QuoteShareService.formatWhatsAppQuote(
                    customerName: name,
                    phone: phone,
                    location: loc.isEmpty ? 'Direct' : loc,
                    propertyType: _propertyType,
                    kw: kw,
                    plateCount: pCount,
                    platePrice: pCost,
                    totalPlatesCost: totalPlatesCost,
                    installCost: installCost,
                    inverterWiringCost: extraCost,
                    totalSystemCost: totalSystemCost,
                    subsidy: sub,
                    netPayable: netPayable,
                    monthlySavings: monthlySavings,
                    annualSavings: annualSavings,
                    paybackYears: payback,
                    profit25Years: profit25,
                    loanAmount: loanAmt > 0 ? loanAmt : null,
                    emiAmount: loanAmt > 0 ? emi : null,
                    loanYears: loanAmt > 0 ? years : null,
                  );

                  if (mounted) Navigator.pop(ctx);

                  // 3. Open WhatsApp
                  await QuoteShareService.openWhatsApp(
                    phone: phone,
                    message: quoteMsg,
                  );
                },
              ),
              const SizedBox(height: 10),

              // Action 2: Share Quote Card Image
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.ink, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.image_outlined, size: 19),
                label: Text(
                  lang.t('Share Quotation Image Card', 'कोटेशन कार्ड इमेज शेयर करें'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim().isEmpty ? 'Customer' : nameCtrl.text.trim();
                  final quoteMsg = QuoteShareService.formatWhatsAppQuote(
                    customerName: name,
                    phone: phoneCtrl.text.trim().isEmpty ? '-' : phoneCtrl.text.trim(),
                    location: locationCtrl.text.trim().isEmpty ? 'Direct' : locationCtrl.text.trim(),
                    propertyType: _propertyType,
                    kw: kw,
                    plateCount: pCount,
                    platePrice: pCost,
                    totalPlatesCost: totalPlatesCost,
                    installCost: installCost,
                    inverterWiringCost: extraCost,
                    totalSystemCost: totalSystemCost,
                    subsidy: sub,
                    netPayable: netPayable,
                    monthlySavings: monthlySavings,
                    annualSavings: annualSavings,
                    paybackYears: payback,
                    profit25Years: profit25,
                    loanAmount: loanAmt > 0 ? loanAmt : null,
                    emiAmount: loanAmt > 0 ? emi : null,
                    loanYears: loanAmt > 0 ? years : null,
                  );

                  await QuoteShareService.shareQuotationImage(
                    key: _quotationBoundaryKey,
                    text: quoteMsg,
                    customerName: name,
                  );
                },
              ),
              const SizedBox(height: 8),

              // Action 3: Save Only to Leads
              TextButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final phone = phoneCtrl.text.trim();
                  final loc = locationCtrl.text.trim();

                  if (name.isEmpty || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(lang.t('Please enter name and phone number', 'कृपया नाम और फोन नंबर दर्ज करें'))),
                    );
                    return;
                  }

                  await LeadService.instance.addLead(
                    name: name,
                    phone: phone,
                    location: loc.isEmpty ? 'Direct' : loc,
                    monthlyBill: _bill.toInt().toString(),
                    propertyType: _propertyType,
                  );

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.teal,
                        content: Text(lang.t('Lead saved successfully to Leads tab!', 'लीड सफलतापूर्वक सेव हो गई!')),
                      ),
                    );
                  }
                },
                child: Text(
                  lang.t('Save Only to Leads Tab', 'सिर्फ लीड्स टैब में सेव करें'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;
    final kw = _kw;
    final hasKw = kw > 0;
    final safeTariff = _tariff;

    // Financial Calculation with Solar Plate Counts
    final pCount = _plateCount;
    final pCost = _plateCost;
    final totalPlatesCost = pCount * pCost;
    final installCost = kw * _installRate;
    final otherCost = _extraCost;
    final totalSystemCost = totalPlatesCost + installCost + otherCost;
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

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: lang.languageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 36,
                    width: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Sunward Solar'),
              ],
            ),
            actions: const [
              LanguageToggleButton(),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // STEP 1: Basic Electricity Usage Inputs Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.t('1. BASIC USAGE / BIJLI CONSUMPTION', '1. बिजली का बिल और साइज चुनें'),
                          style: const TextStyle(
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
                                  Text(
                                    lang.t('Monthly Bill', 'महीने का बिजली बिल'),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                                  Text(
                                    lang.t('Solar Size (kW)', 'सोलर साइज (kW)'),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _kwController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

                        // Quick presets row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              Text(
                                '${lang.t("Quick Size", "पसंदीदा साइज")}: ',
                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                              for (final p in [1.0, 2.0, 3.0, 5.0, 10.0, 15.0]) ...[
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text('${p.toInt()}kW'),
                                    labelStyle: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: kw.toInt() == p.toInt() ? AppColors.ink : AppColors.muted,
                                    ),
                                    selected: (kw - p).abs() < 0.1,
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

                        // Property Type Dropdown (Custom UI showing only Residential, Commercial, Corporate, Industrial)
                        _buildPropertyTypeSelector(lang),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // STEP 2: Custom Rates & Solar Plates (Always Visible)
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
                            Expanded(
                              child: Text(
                                lang.t('2. SOLAR PLATES & CUSTOM RATES', '2. सोलर प्लेट्स व रेट्स सेटिंग'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: AppColors.teal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.t(
                            'Enter plate count & price per plate; kW and total cost compute automatically:',
                            'प्लेट संख्या और प्रति प्लेट कीमत डालें; kW और कुल खर्च अपने आप निकलेगा:',
                          ),
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),

                        // Solar Plates Row: Number of Plates & Cost per Plate
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _plateCountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: lang.t('No. of Solar Plates', 'सोलर प्लेट्स संख्या'),
                                  helperText: lang.t('540W Mono PERC', '540W प्लेट्स'),
                                ),
                                onChanged: _onPlateCountChanged,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _plateCostController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: lang.t('Price / Plate (₹)', '1 प्लेट की कीमत (₹)'),
                                  helperText: lang.t('Hardware price', 'प्रति प्लेट रेट'),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Electricity Tariff & Fitting / Labour Rate
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _tariffController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: lang.t('Bijli Rate (₹/unit)', 'बिजली रेट (₹/यूनिट)'),
                                  helperText: lang.t('Power tariff', 'यूनिट दर'),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _installRateController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: lang.t('Fitting / Labour (₹/kW)', 'फिटिंग व स्ट्रक्चर (₹/kW)'),
                                  helperText: lang.t('Installation cost', 'लेबर व स्ट्रक्चर'),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Inverter & Wiring Extra Charges
                        TextField(
                          controller: _extraCostController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.t('Inverter & Wiring Charges (₹)', 'इन्वर्टर और वायरिंग खर्च (₹)'),
                            helperText: lang.t('Lumpsum balance of plant', 'अन्य सामान खर्च'),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),

                        // Government Subsidy (Auto computed by residential rule)
                        TextField(
                          controller: _subsidyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.t('Govt Subsidy Discount (₹)', 'सरकारी सब्सिडी छूट (₹)'),
                            helperText: _propertyType == 'Residential'
                                ? lang.t('PM Surya Ghar: 1kW=₹40k, 2kW=₹80k, 3kW+=₹98k', 'पीएम सूर्य घर: 1kW=₹40k, 2kW=₹80k, 3kW+=₹98k')
                                : lang.t('Commercial/Corporate/Industrial has no subsidy (₹0)', 'कमर्शियल/कॉर्पोरेट/फैक्ट्री पर कोई सब्सिडी नहीं (₹0)'),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // STEP 3: Solar Bank Loan & Easy EMI Card
                _buildBankLoanCard(lang, finalPriceYouPay, monthlySavings),
                const SizedBox(height: 14),

                // STEP 4: Enhanced Solar Estimate Box (Animated with common words)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.95, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.sun,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withOpacity(0.14),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.t('4. TOTAL CALCULATION ESTIMATE', '4. आपका पूरा हिसाब-किताब'),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    '${kw.toStringAsFixed(1)} kW Solar System',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lang.t('$paybackYears Yrs Payback', '$paybackYears साल में वसूल'),
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

                        // Three Main Hero Numbers (Fitted to prevent overflow)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildHeroStat(
                                  lang.t('Price You Pay', 'आपका खर्च'),
                                  _currencyFormat.format(finalPriceYouPay),
                                  lang.t('After subsidy', 'सब्सिडी के बाद'),
                                ),
                              ),
                              Container(width: 1, height: 42, color: AppColors.ink.withOpacity(0.18)),
                              Expanded(
                                child: _buildHeroStat(
                                  lang.t('Yearly Savings', 'साल की बचत'),
                                  _currencyFormat.format(annualSavings),
                                  '₹${_numFormat.format(monthlySavings)}/${lang.t("mo", "महीना")}',
                                ),
                              ),
                              Container(width: 1, height: 42, color: AppColors.ink.withOpacity(0.18)),
                              Expanded(
                                child: _buildHeroStat(
                                  lang.t('25-Yr Profit', '25 साल मुनाफा'),
                                  _currencyFormat.format(lifetimeProfit > 0 ? lifetimeProfit : 0),
                                  lang.t('Total profit', 'कुल फायदा'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Detailed Cost Breakdown
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.t('PAISA KAHAN LAGEGA (COST BREAKDOWN)', 'पैसा कहाँ लगेगा (खर्च का विवरण)'),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                              ),
                              const SizedBox(height: 8),
                              _buildPriceRow(
                                '${lang.t("Solar Plates", "सोलर प्लेट्स")} ($pCount × ₹${pCost.round()})',
                                _currencyFormat.format(totalPlatesCost),
                              ),
                              _buildPriceRow(
                                lang.t('Structure & Fitting', 'स्ट्रक्चर और फिटिंग'),
                                _currencyFormat.format(installCost),
                              ),
                              _buildPriceRow(
                                lang.t('Inverter & Wiring', 'इन्वर्टर और वायरिंग'),
                                _currencyFormat.format(otherCost),
                              ),
                              const Divider(height: 14, thickness: 1, color: AppColors.ink),
                              _buildPriceRow(
                                lang.t('Total System Cost', 'कुल खर्च (Total Price)'),
                                _currencyFormat.format(totalSystemCost),
                                isBold: true,
                              ),
                              _buildPriceRow(
                                lang.t('Govt Subsidy Discount', 'सरकारी सब्सिडी छूट'),
                                effectiveSubsidy > 0 ? '-${_currencyFormat.format(effectiveSubsidy)}' : '₹0',
                                isGreen: true,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      lang.t('Final Amount To Pay:', 'आपको देना होगा:'),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _currencyFormat.format(finalPriceYouPay),
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_loanAmount > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      lang.t('BANK LOAN & EMI (KIST HISAAB)', 'बैंक लोन व किश्त का हिसाब'),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                                    ),
                                    Text(
                                      '$_loanTenureYears ${lang.t("Yrs @", "साल @")} $_interestRate%',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.teal),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildPriceRow(lang.t('Sanctioned Loan', 'स्वीकृत लोन रकम'), _currencyFormat.format(_loanAmount)),
                                _buildPriceRow(
                                  lang.t('Down Payment (Cash)', 'डाउन पेमेंट (नकद भुगतान)'),
                                  _currencyFormat.format((finalPriceYouPay - _loanAmount) > 0 ? (finalPriceYouPay - _loanAmount) : 0),
                                ),
                                _buildPriceRow(
                                  lang.t('Monthly EMI', 'हर महीने की किश्त (EMI)'),
                                  '${_currencyFormat.format(_calculateMonthlyEmi(_loanAmount, _interestRate, _loanTenureYears))} / ${lang.t("mo", "महीना")}',
                                ),
                                _buildPriceRow(
                                  lang.t('Total Bank Interest', 'कुल बैंक ब्याज'),
                                  _currencyFormat.format(
                                    ((_calculateMonthlyEmi(_loanAmount, _interestRate, _loanTenureYears) * (_loanTenureYears * 12)) - _loanAmount) > 0
                                        ? ((_calculateMonthlyEmi(_loanAmount, _interestRate, _loanTenureYears) * (_loanTenureYears * 12)) - _loanAmount)
                                        : 0,
                                  ),
                                ),
                                const Divider(height: 12, thickness: 1, color: AppColors.ink),
                                _buildPriceRow(
                                  lang.t('Total Cost with Loan Interest', 'ब्याज सहित कुल खर्च'),
                                  _currencyFormat.format(
                                    finalPriceYouPay +
                                        (((_calculateMonthlyEmi(_loanAmount, _interestRate, _loanTenureYears) * (_loanTenureYears * 12)) - _loanAmount) > 0
                                            ? ((_calculateMonthlyEmi(_loanAmount, _interestRate, _loanTenureYears) * (_loanTenureYears * 12)) - _loanAmount)
                                            : 0),
                                  ),
                                  isBold: true,
                                ),
                                _buildPriceRow(
                                  lang.t('Net 25-Year Profit (after Loan)', '25 साल का शुद्ध मुनाफा'),
                                  _currencyFormat.format(
                                    (annualSavings * 25) -
                                        (finalPriceYouPay +
                                            (((_calculateMonthlyEmi(_loanAmount, _interestRate, _loanTenureYears) * (_loanTenureYears * 12)) - _loanAmount) > 0
                                                ? ((_calculateMonthlyEmi(_loanAmount, _interestRate, _loanTenureYears) * (_loanTenureYears * 12)) - _loanAmount)
                                                : 0)),
                                  ),
                                  isBold: true,
                                  isGreen: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Electricity & Rooftop Specs
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.t('CHHAT AUR BIJLI SPECS', 'छत और बिजली विवरण'),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: _buildSpecBox(lang.t('Daily Power', 'रोजाना बिजली'), '~$dailyUnits ${lang.t("Units", "यूनिट")}')),
                                  Expanded(child: _buildSpecBox(lang.t('Plates', 'प्लेट्स'), '$pCount ${lang.t("Nos (540W)", "प्लेट्स")}')),
                                  Expanded(child: _buildSpecBox(lang.t('Roof Area', 'छत की जगह'), '~$roofAreaSqFt ${lang.t("sq.ft.", "वर्ग फुट")}')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // CTA Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 20),
                          label: Text(
                            lang.t('Free Site Checkup & WhatsApp Quote', 'घर पर फ्री चेकअप और व्हाट्सऐप कोटेशन'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () => _showQuoteDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroStat(String title, String mainValue, String sub) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(mainValue, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: TextStyle(fontSize: 9, color: AppColors.ink.withOpacity(0.7)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isGreen ? AppColors.teal : AppColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        Text(
          title,
          style: TextStyle(fontSize: 9, color: AppColors.ink.withOpacity(0.7)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPropertyTypeSelector(LanguageService lang) {
    final types = [
      {'key': 'Residential', 'en': 'Residential', 'hi': 'Residential (आवासीय)', 'icon': Icons.home_outlined},
      {'key': 'Commercial', 'en': 'Commercial', 'hi': 'Commercial (व्यावसायिक)', 'icon': Icons.storefront_outlined},
      {'key': 'Corporate', 'en': 'Corporate', 'hi': 'Corporate (कॉर्पोरेट)', 'icon': Icons.business_outlined},
      {'key': 'Industrial', 'en': 'Industrial', 'hi': 'Industrial (औद्योगिक)', 'icon': Icons.factory_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lang.t('Property Type', 'जगह का प्रकार'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _propertyType == 'Residential' ? AppColors.teal.withOpacity(0.12) : AppColors.muted.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _propertyType == 'Residential'
                    ? lang.t('Subsidy Eligible', 'सब्सिडी लागू')
                    : lang.t('No Subsidy', 'सब्सिडी नहीं'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _propertyType == 'Residential' ? AppColors.teal : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.creamDark, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _propertyType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.ink),
              items: types.map((item) {
                final key = item['key'] as String;
                final label = lang.isHindi ? (item['hi'] as String) : (item['en'] as String);
                final icon = item['icon'] as IconData;
                return DropdownMenuItem<String>(
                  value: key,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: AppColors.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _onPropertyTypeChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankLoanCard(
    LanguageService lang,
    double netPayable,
    double monthlySavings,
  ) {
    final loanAmt = _loanAmount;
    final rate = _interestRate;
    final years = _loanTenureYears;
    final emi = _calculateMonthlyEmi(loanAmt, rate, years);
    final totalMonths = years * 12;
    final totalRepayment = emi * totalMonths;
    final totalInterest = totalRepayment > loanAmt ? totalRepayment - loanAmt : 0.0;
    final downPayment = (netPayable - loanAmt) > 0 ? (netPayable - loanAmt) : 0.0;
    final netMonthlyCashflow = monthlySavings - emi;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_outlined, size: 18, color: AppColors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lang.t('3. BANK LOAN & EASY EMI (FINANCE)', '3. सोलर बैंक लोन व आसान किश्त (EMI)'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppColors.teal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              lang.t(
                'Calculate solar loan EMI and monthly savings (SBI/Govt loan ~7% to 8.5% p.a.):',
                'सोलर बैंक लोन व मासिक किश्त का हिसाब निकालें (पीएम सूर्य घर लोन ~7% से 8.5%):',
              ),
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 12),

            // Loan Amount Input + Quick Presets
            Text(
              lang.t('Loan Amount (₹)', 'लोन राशि (₹)'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _loanAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                helperText: loanAmt > 0
                    ? lang.t(
                        'Down payment: ${_currencyFormat.format(downPayment)}',
                        'डाउन पेमेंट (शुरुआती रकम): ${_currencyFormat.format(downPayment)}',
                      )
                    : lang.t('Enter 0 for cash payment', 'नकद भुगतान के लिए 0 रखें'),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Quick Loan Amount Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Text(
                    '${lang.t("Quick Amount", "शॉर्टकट")}: ',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  ChoiceChip(
                    label: Text(lang.t('100% Loan', 'पूरा लोन')),
                    labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    selected: (loanAmt - netPayable).abs() < 10 && loanAmt > 0,
                    selectedColor: AppColors.sun,
                    backgroundColor: AppColors.cream,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        _loanAmountController.text = netPayable.round().toString();
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(lang.t('80% Loan', '80% लोन')),
                    labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    selected: (loanAmt - (netPayable * 0.8)).abs() < 50 && loanAmt > 0,
                    selectedColor: AppColors.sun,
                    backgroundColor: AppColors.cream,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        _loanAmountController.text = (netPayable * 0.8).round().toString();
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(lang.t('50% Loan', '50% लोन')),
                    labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    selected: (loanAmt - (netPayable * 0.5)).abs() < 50 && loanAmt > 0,
                    selectedColor: AppColors.sun,
                    backgroundColor: AppColors.cream,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        _loanAmountController.text = (netPayable * 0.5).round().toString();
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(lang.t('No Loan (Cash)', 'कोई लोन नहीं')),
                    labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    selected: loanAmt <= 0,
                    selectedColor: AppColors.coral,
                    backgroundColor: AppColors.cream,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        _loanAmountController.text = '0';
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Interest Rate & Tenure Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('Interest Rate (% p.a.)', 'ब्याज दर (% सालाना)'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _interestRateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          suffixText: '%',
                          suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.muted),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('Tenure (Years)', 'अवधि (साल)'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _loanTenureController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          suffixText: lang.t('Yrs', 'साल'),
                          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.muted),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Chips for Interest Rate & Tenure
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Text(
                    '${lang.t("Tenure", "साल")}: ',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  for (final yr in [3, 5, 7, 10]) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('$yr ${lang.t("Yrs", "साल")}'),
                        labelStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: years == yr ? AppColors.ink : AppColors.muted,
                        ),
                        selected: years == yr,
                        selectedColor: AppColors.sun,
                        backgroundColor: AppColors.cream,
                        showCheckmark: false,
                        onSelected: (_) {
                          setState(() {
                            _loanTenureController.text = yr.toString();
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (loanAmt > 0) ...[
              const SizedBox(height: 14),
              // Live EMI Calculation Result Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.teal.withOpacity(0.3), width: 1.2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.t('MONTHLY EMI (किश्त)', 'महीने की किश्त (EMI)'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${_currencyFormat.format(emi)} / ${lang.t("mo", "महीना")}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: AppColors.ink.withOpacity(0.15)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.t('TOTAL INTEREST', 'कुल ब्याज'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _currencyFormat.format(totalInterest),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    // Monthly cashflow comparison callout
                    Row(
                      children: [
                        Icon(
                          netMonthlyCashflow >= 0 ? Icons.check_circle_outline : Icons.info_outline,
                          size: 16,
                          color: netMonthlyCashflow >= 0 ? AppColors.teal : AppColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            netMonthlyCashflow >= 0
                                ? lang.t(
                                    'Free Solar! Bijli savings (₹${monthlySavings.round()}) cover EMI with +₹${netMonthlyCashflow.round()} extra cash in hand!',
                                    'सोलर फ्री में! बिजली बचत (₹${monthlySavings.round()}) किश्त चुका देगी और महीने में +₹${netMonthlyCashflow.round()} बचेंगे!',
                                  )
                                : lang.t(
                                    'Effective cost is only ₹${(-netMonthlyCashflow).round()}/mo (EMI ₹${emi.round()} - Saved ₹${monthlySavings.round()}) for $years yrs.',
                                    'असल खर्च सिर्फ ₹${(-netMonthlyCashflow).round()}/माह (किश्त ₹${emi.round()} - बचत ₹${monthlySavings.round()}) $years साल तक।',
                                  ),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: netMonthlyCashflow >= 0 ? AppColors.teal : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
