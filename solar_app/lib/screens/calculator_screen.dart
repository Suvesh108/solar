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

  String _propertyType = 'House / Ghar';
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

  double _computeSubsidyFor(double kw, String propType) {
    final isResidential = propType.toLowerCase().contains('house') ||
        propType.toLowerCase().contains('ghar') ||
        propType.toLowerCase().contains('residential');
    
    // Commercial, Corporate & Industrial get NO subsidy (₹0)
    if (!isResidential || kw <= 0) {
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

                        // Property Type Dropdown
                        Text(
                          lang.t('Property Type (Subsidy applies to Residential)', 'जगह का प्रकार (सब्सिडी सिर्फ घर के लिए है)'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _propertyType,
                          decoration: const InputDecoration(),
                          items: [
                            DropdownMenuItem(
                              value: 'House / Ghar',
                              child: Text(lang.t('House / Ghar (Residential — Up to ₹98k Subsidy)', 'घर (Residential — ₹98,000 तक सब्सिडी)')),
                            ),
                            DropdownMenuItem(
                              value: 'Shop / Dukaan',
                              child: Text(lang.t('Shop / Commercial Dukaan (No Subsidy)', 'दुकान (Commercial — कोई सब्सिडी नहीं)')),
                            ),
                            DropdownMenuItem(
                              value: 'Office',
                              child: Text(lang.t('Office / Corporate (No Subsidy)', 'ऑफिस (Corporate — कोई सब्सिडी नहीं)')),
                            ),
                            DropdownMenuItem(
                              value: 'Factory',
                              child: Text(lang.t('Factory / Industrial (No Subsidy)', 'फैक्ट्री (Industrial — कोई सब्सिडी नहीं)')),
                            ),
                          ],
                          onChanged: _onPropertyTypeChanged,
                        ),
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
                            helperText: _propertyType.toLowerCase().contains('house') || _propertyType.toLowerCase().contains('ghar')
                                ? lang.t('PM Surya Ghar: 1kW=₹40k, 2kW=₹80k, 3kW+=₹98k', 'पीएम सूर्य घर: 1kW=₹40k, 2kW=₹80k, 3kW+=₹98k')
                                : lang.t('Commercial/Industrial has no subsidy (₹0)', 'कमर्शियल/फैक्ट्री पर कोई सब्सिडी नहीं (₹0)'),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // STEP 3: Enhanced Solar Estimate Box (Animated with common words)
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
                                    lang.t('TOTAL CALCULATION ESTIMATE', 'आपका पूरा हिसाब-किताब'),
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
}
