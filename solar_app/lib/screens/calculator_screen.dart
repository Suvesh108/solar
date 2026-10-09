import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import '../constants/solar_pricing_config.dart';
import '../services/language_service.dart';
import '../services/lead_service.dart';
import '../services/quote_share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/quotation_card.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with SingleTickerProviderStateMixin {
  final _screenshotController = ScreenshotController();
  final _billController = TextEditingController(text: '0');
  final _kwController = TextEditingController(text: '0');

  // Installation Type & Battery Settings
  String _installationType = 'On-Grid'; // 'On-Grid' or 'Hybrid'
  String _batteryVoltage = '24V';       // '24V' or '48V'
  final _batteryCostController = TextEditingController(text: '0');

  // Custom Rates & Balance of Plant
  final _tariffController = TextEditingController(text: '7');       // ₹7/unit
  final _installRateController = TextEditingController(text: '0');  // Optional extra fitting ₹/kW
  final _extraCostController = TextEditingController(text: '0');    // Optional extra wiring ₹
  final _subsidyController = TextEditingController(text: '0');

  // Bank Loan & EMI Settings (Default 5.76% p.a. PM Surya Ghar concessional rate)
  final _loanAmountController = TextEditingController(text: '0');
  final _interestRateController = TextEditingController(text: '5.76');
  final _loanTenureController = TextEditingController(text: '5');      // 5 years

  // Auto-zero focus nodes (clears '0' on click, restores '0' when left empty)
  final _billFocus = FocusNode();
  final _kwFocus = FocusNode();
  final _batteryCostFocus = FocusNode();
  final _tariffFocus = FocusNode();
  final _installRateFocus = FocusNode();
  final _extraCostFocus = FocusNode();
  final _subsidyFocus = FocusNode();
  final _loanAmountFocus = FocusNode();
  final _interestRateFocus = FocusNode();
  final _loanTenureFocus = FocusNode();

  String _propertyType = 'Residential';

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _numFormat = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _recalculateSubsidy(0.0, _propertyType);

    _setupAutoZero(_billController, _billFocus, () => setState(() {}));
    _setupAutoZero(_kwController, _kwFocus, () {
      _recalculateSubsidy(_kw, _propertyType);
      setState(() {});
    });
    _setupAutoZero(_batteryCostController, _batteryCostFocus, () => setState(() {}));
    _setupAutoZero(_tariffController, _tariffFocus, () => setState(() {}));
    _setupAutoZero(_installRateController, _installRateFocus, () => setState(() {}));
    _setupAutoZero(_extraCostController, _extraCostFocus, () => setState(() {}));
    _setupAutoZero(_subsidyController, _subsidyFocus, () => setState(() {}));
    _setupAutoZero(_loanAmountController, _loanAmountFocus, () => setState(() {}));
    _setupAutoZero(_interestRateController, _interestRateFocus, () => setState(() {}));
    _setupAutoZero(_loanTenureController, _loanTenureFocus, () => setState(() {}));
  }

  void _setupAutoZero(
    TextEditingController controller,
    FocusNode focusNode,
    VoidCallback onEmptyRestore,
  ) {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        if (controller.text.trim() == '0' || controller.text.trim() == '0.0') {
          controller.clear();
        }
      } else {
        if (controller.text.trim().isEmpty) {
          controller.text = '0';
          onEmptyRestore();
        }
      }
    });
  }

  @override
  void dispose() {
    _billController.dispose();
    _kwController.dispose();
    _batteryCostController.dispose();
    _tariffController.dispose();
    _installRateController.dispose();
    _extraCostController.dispose();
    _subsidyController.dispose();
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _loanTenureController.dispose();

    _billFocus.dispose();
    _kwFocus.dispose();
    _batteryCostFocus.dispose();
    _tariffFocus.dispose();
    _installRateFocus.dispose();
    _extraCostFocus.dispose();
    _subsidyFocus.dispose();
    _loanAmountFocus.dispose();
    _interestRateFocus.dispose();
    _loanTenureFocus.dispose();

    super.dispose();
  }

  void _resetCalculator() {
    setState(() {
      _billController.text = '0';
      _kwController.text = '0';
      _installationType = 'On-Grid';
      _batteryVoltage = '24V';
      _batteryCostController.text = '0';
      _tariffController.text = '7';
      _installRateController.text = '0';
      _extraCostController.text = '0';
      _subsidyController.text = '0';
      _loanAmountController.text = '0';
      _interestRateController.text = '5.76';
      _loanTenureController.text = '5';
      _propertyType = 'Residential';
    });
  }

  double get _bill => double.tryParse(_billController.text) ?? 0;
  double get _kw => double.tryParse(_kwController.text) ?? 0;
  bool get _isHybrid => _installationType == 'Hybrid';
  double get _batteryPrice => _isHybrid ? (double.tryParse(_batteryCostController.text) ?? 0.0) : 0.0;
  double get _baseSolarPrice => SolarPricingConfig.calculateBasePrice(_kw);
  double get _tariff {
    final t = double.tryParse(_tariffController.text) ?? 7;
    return t > 0 ? t : 7;
  }
  double get _installRate => double.tryParse(_installRateController.text) ?? 0;
  double get _extraCost => double.tryParse(_extraCostController.text) ?? 0;
  double get _subsidy => double.tryParse(_subsidyController.text) ?? 0;

  double get _loanAmount => double.tryParse(_loanAmountController.text) ?? 0;
  double get _interestRate => double.tryParse(_interestRateController.text) ?? 5.76;
  int get _loanTenureYears {
    final y = int.tryParse(_loanTenureController.text) ?? 5;
    return y > 0 ? y : 1;
  }
  int get _autoPlateCount => SolarPricingConfig.calculatePlateCount(_kw);

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
    setState(() {});
  }

  void _onKwChanged(String val) {
    setState(() {
      final nKw = double.tryParse(val) ?? 0;
      _recalculateSubsidy(nKw, _propertyType);
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
    _recalculateSubsidy(kw, _propertyType);
    setState(() {});
  }

  void _showQuoteDialog(BuildContext context) {
    final lang = LanguageService.instance;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    final kw = _kw;
    final basePrice = _baseSolarPrice;
    final bPrice = _batteryPrice;
    final installCost = kw * _installRate;
    final extraCost = _extraCost;
    final totalSystemCost = basePrice + bPrice + installCost + extraCost;
    final sub = _subsidy;
    final netPayable = (totalSystemCost - sub) > 0 ? (totalSystemCost - sub) : 0.0;
    final monthlySavings = kw * SolarPricingConfig.unitsPerKwMonth * _tariff;
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.t('Customer Quotation', 'ग्राहक कोटेशन व विवरण'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                lang.t(
                  'Enter customer details to generate self-contained quotation card and send to WhatsApp:',
                  'ग्राहक का नाम व नंबर दर्ज करें और व्हाट्सऐप पर पूरा कार्ड भेजें:',
                ),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: lang.t('Customer Full Name *', 'ग्राहक का नाम *'),
                  hintText: 'e.g. Ramesh Patel',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: lang.t('Mobile / WhatsApp Number *', 'मोबाइल / व्हाट्सऐप नंबर *'),
                  hintText: 'e.g. 9822012345',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                  labelText: lang.t('Location / City *', 'शहर / इलाका *'),
                  hintText: 'e.g. Pune, Maharashtra',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 16),

              // Primary Action: Save Lead & Send Full WhatsApp Card (100% details, ZERO text)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp brand green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                icon: const Icon(Icons.share, size: 20),
                label: Text(
                  lang.t('Save & Send Card to WhatsApp', 'कार्ड सेव करें व व्हाट्सऐप पर भेजें'),
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

                  // 1. Save Lead locally
                  await LeadService.instance.addLead(
                    name: name,
                    phone: phone,
                    location: loc.isEmpty ? 'Direct' : loc,
                    monthlyBill: _bill.toInt().toString(),
                    propertyType: _propertyType,
                  );

                  // 2. Close input modal
                  if (!mounted) return;
                  Navigator.pop(ctx);

                  // 3. Build Full Unclipped Quotation Card
                  final cardWidget = Material(
                    color: Colors.transparent,
                    child: QuotationCard(
                      customerName: name,
                      customerPhone: phone,
                      customerLocation: loc.isEmpty ? 'Direct Consultation' : loc,
                      propertyType: _propertyType,
                      kw: kw,
                      installationType: _installationType,
                      batteryVoltage: _isHybrid ? _batteryVoltage : null,
                      batteryPrice: bPrice,
                      baseSolarCost: basePrice,
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
                      interestRate: loanAmt > 0 ? rate : null,
                      downPayment: loanAmt > 0 ? downPayment : null,
                      generatedAt: DateTime.now(),
                    ),
                  );

                  // 4. Capture high-res unclipped image
                  final file = await QuoteShareService.captureWidgetWithController(
                    controller: _screenshotController,
                    widget: cardWidget,
                    context: context,
                  );

                  // 5. Send directly to customer's WhatsApp chat with ZERO text caption
                  if (file != null) {
                    await QuoteShareService.sendQuotationCardToWhatsApp(
                      imageFile: file,
                      phone: phone,
                      customerName: name,
                    );
                  }

                  // 6. Reset calculator to 0
                  if (mounted) {
                    _resetCalculator();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.teal,
                        content: Text(lang.t('Quotation card sent to WhatsApp & Lead saved!', 'कोटेशन कार्ड व्हाट्सऐप पर भेजा गया व लीड सेव हो गई!')),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),

              // Secondary Action: Send WhatsApp Text Direct Chat
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.ink, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(
                  lang.t('Send Text Only via WhatsApp', 'सिर्फ टेक्स्ट व्हाट्सऐप पर भेजें'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

                  await LeadService.instance.addLead(
                    name: name,
                    phone: phone,
                    location: loc.isEmpty ? 'Direct' : loc,
                    monthlyBill: _bill.toInt().toString(),
                    propertyType: _propertyType,
                  );

                  final quoteMsg = QuoteShareService.formatWhatsAppQuote(
                    customerName: name,
                    phone: phone,
                    location: loc.isEmpty ? 'Direct' : loc,
                    propertyType: _propertyType,
                    kw: kw,
                    installationType: _installationType,
                    batteryVoltage: _isHybrid ? _batteryVoltage : null,
                    batteryPrice: bPrice,
                    baseSolarCost: basePrice,
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
                    interestRate: loanAmt > 0 ? rate : null,
                  );

                  if (mounted) {
                    Navigator.pop(ctx);
                    _resetCalculator();
                  }

                  await QuoteShareService.openWhatsApp(phone: phone, message: quoteMsg);
                },
              ),
              const SizedBox(height: 6),

              // Tertiary Action: Save Only to Leads Tab
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
                    _resetCalculator();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.teal,
                        content: Text(lang.t('Lead saved to Leads tab! Calculator reset to 0.', 'लीड सेव हो गई! कैलकुलेटर 0 पर रीसेट हो गया।')),
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

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;
    final kw = _kw;
    final hasKw = kw > 0;
    final safeTariff = _tariff;

    // Financial Calculation with Capacity-based Pricing
    final basePrice = _baseSolarPrice;
    final bPrice = _batteryPrice;
    final installCost = kw * _installRate;
    final otherCost = _extraCost;
    final totalSystemCost = basePrice + bPrice + installCost + otherCost;
    final effectiveSubsidy = hasKw ? _subsidy : 0.0;
    final finalPriceYouPay = (totalSystemCost - effectiveSubsidy) > 0 ? (totalSystemCost - effectiveSubsidy) : 0.0;

    final dailyUnits = kw * SolarPricingConfig.dailyUnitsPerKw;
    final monthlyUnits = kw * SolarPricingConfig.unitsPerKwMonth;
    final annualUnits = monthlyUnits * 12;
    final monthlySavings = monthlyUnits * safeTariff;
    final annualSavings = annualUnits * safeTariff;

    final paybackYears = (hasKw && annualSavings > 0)
        ? (finalPriceYouPay / annualSavings).toStringAsFixed(1)
        : '0';
    final lifetimeProfit = hasKw ? ((annualSavings * 25) - finalPriceYouPay) : 0.0;

    final roofAreaSqFt = (kw * SolarPricingConfig.sqFtPerKw).round();
    final autoPlates = _autoPlateCount;

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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: lang.t('Reset Calculator to 0', 'कैलकुलेटर 0 पर रीसेट करें'),
                onPressed: _resetCalculator,
              ),
              const LanguageToggleButton(),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // UNIFIED STEP 1: Solar Setup & Pricing (Merged Section A + Section B)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.solar_power_outlined, size: 20, color: AppColors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lang.t('1. SOLAR SETUP & PRICING', '1. सोलर सेटअप व कीमत'),
                                style: const TextStyle(
                                  fontSize: 12,
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
                            'Choose plant type, property, and solar capacity (Turnkey @ ₹70,000/kW):',
                            'सोलर प्रकार, जगह व प्लांट साइज चुनें (टर्नकी रेट ₹70,000/kW):',
                          ),
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                        const SizedBox(height: 14),

                        // Installation Type Selector: On-Grid vs Hybrid
                        Text(
                          lang.t('Installation Type', 'सोलर प्लांट प्रकार'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                                label: Text(lang.t('On-Grid (Net Meter)', 'ऑन-ग्रिड (नेट मीटर)')),
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _installationType == 'On-Grid' ? AppColors.ink : AppColors.muted,
                                ),
                                selected: _installationType == 'On-Grid',
                                selectedColor: AppColors.sun,
                                backgroundColor: AppColors.cream,
                                showCheckmark: false,
                                onSelected: (_) {
                                  setState(() {
                                    _installationType = 'On-Grid';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                avatar: const Icon(Icons.battery_charging_full, size: 16),
                                label: Text(lang.t('Hybrid (With Battery)', 'हाइब्रिड (बैटरी सहित)')),
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _installationType == 'Hybrid' ? AppColors.ink : AppColors.muted,
                                ),
                                selected: _installationType == 'Hybrid',
                                selectedColor: AppColors.sun,
                                backgroundColor: AppColors.cream,
                                showCheckmark: false,
                                onSelected: (_) {
                                  setState(() {
                                    _installationType = 'Hybrid';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Property Type Dropdown
                        _buildPropertyTypeSelector(lang),
                        const SizedBox(height: 12),

                        // Electricity Bill & Solar Capacity Row
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
                                    focusNode: _billFocus,
                                    onTap: () {
                                      if (_billController.text.trim() == '0') _billController.clear();
                                    },
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
                                    focusNode: _kwFocus,
                                    onTap: () {
                                      if (_kwController.text.trim() == '0' || _kwController.text.trim() == '0.0') _kwController.clear();
                                    },
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

                        // Quick Size Presets Row
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

                        // Turnkey Base Solar Package Banner (Live auto-calculated)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.teal.withOpacity(0.35), width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.t('Base Solar Package (₹70k/kW)', 'टर्नकी सोलर पैकेज (₹70,000/kW)'),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.teal),
                                  ),
                                  Text(
                                    '${kw.toStringAsFixed(1)} kW × ₹70,000 (TopCon + Inverter + Fitting)',
                                    style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                                  ),
                                ],
                              ),
                              Text(
                                _currencyFormat.format(basePrice),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),

                        // HYBRID ONLY: Dedicated Battery Configuration Card
                        if (_isHybrid) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.sun.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.sun, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.battery_charging_full, size: 16, color: AppColors.ink),
                                    const SizedBox(width: 6),
                                    Text(
                                      lang.t('Battery Configuration (Hybrid)', 'हाइब्रिड बैटरी सेटअप'),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Voltage Selection Chips (24V vs 48V)
                                Row(
                                  children: [
                                    Text(
                                      '${lang.t("Voltage", "वोल्टेज")}: ',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('24V'),
                                      labelStyle: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _batteryVoltage == '24V' ? AppColors.white : AppColors.ink,
                                      ),
                                      selected: _batteryVoltage == '24V',
                                      selectedColor: AppColors.ink,
                                      backgroundColor: AppColors.cream,
                                      showCheckmark: false,
                                      onSelected: (_) {
                                        setState(() {
                                          _batteryVoltage = '24V';
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('48V'),
                                      labelStyle: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _batteryVoltage == '48V' ? AppColors.white : AppColors.ink,
                                      ),
                                      selected: _batteryVoltage == '48V',
                                      selectedColor: AppColors.ink,
                                      backgroundColor: AppColors.cream,
                                      showCheckmark: false,
                                      onSelected: (_) {
                                        setState(() {
                                          _batteryVoltage = '48V';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Battery Price Input Field (Manual Entry)
                                TextField(
                                  controller: _batteryCostController,
                                  focusNode: _batteryCostFocus,
                                  onTap: () {
                                    if (_batteryCostController.text.trim() == '0') {
                                      _batteryCostController.clear();
                                    }
                                  },
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: lang.t('Battery Bank Price (₹)', 'बैटरी बैंक की कीमत (₹)'),
                                    helperText: lang.t(
                                      'Enter total battery price (Tubular or Lithium pack)',
                                      'बैटरी बैंक की कुल कीमत दर्ज करें (ट्यूबलर या लिथियम)',
                                    ),
                                    prefixText: '₹ ',
                                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Additional Charges & Rates
                        Text(
                          lang.t('Custom Rates & Balance of Plant (Optional)', 'अतिरिक्त रेट्स व खर्च (वैकल्पिक)'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _tariffController,
                                focusNode: _tariffFocus,
                                onTap: () {
                                  if (_tariffController.text.trim() == '0' || _tariffController.text.trim() == '0.0') _tariffController.clear();
                                },
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
                                focusNode: _installRateFocus,
                                onTap: () {
                                  if (_installRateController.text.trim() == '0') _installRateController.clear();
                                },
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: lang.t('Extra Structure (₹/kW)', 'अतिरिक्त स्ट्रक्चर (₹/kW)'),
                                  helperText: lang.t('Special civil/high-rise', 'हाई-राइज स्ट्रक्चर'),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: _extraCostController,
                          focusNode: _extraCostFocus,
                          onTap: () {
                            if (_extraCostController.text.trim() == '0') _extraCostController.clear();
                          },
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.t('Extra Wiring / Protection (₹)', 'अतिरिक्त वायरिंग खर्च (₹)'),
                            helperText: lang.t('Long distance cable run', 'लंबी दूरी की केबल आदि'),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),

                        // Government Subsidy (Auto computed by residential rule)
                        TextField(
                          controller: _subsidyController,
                          focusNode: _subsidyFocus,
                          onTap: () {
                            if (_subsidyController.text.trim() == '0') _subsidyController.clear();
                          },
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

                // STEP 2: Solar Bank Loan & Easy EMI Card
                _buildBankLoanCard(lang, finalPriceYouPay, monthlySavings),
                const SizedBox(height: 14),

                // STEP 3: Enhanced Solar Estimate Box (Summary Hisaab)
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
                                    _isHybrid
                                        ? '${kw.toStringAsFixed(1)} kW Hybrid ($_batteryVoltage)'
                                        : '${kw.toStringAsFixed(1)} kW On-Grid Solar',
                                    style: const TextStyle(
                                      fontSize: 17,
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

                        // Three Main Hero Numbers
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
                                '${lang.t("Turnkey Solar Package", "सोलर पैकेज")} (${kw.toStringAsFixed(1)} kW @ ₹70k/kW)',
                                _currencyFormat.format(basePrice),
                              ),
                              if (_isHybrid && bPrice > 0)
                                _buildPriceRow(
                                  '${lang.t("Hybrid Battery Bank", "हाइब्रिड बैटरी")} ($_batteryVoltage)',
                                  _currencyFormat.format(bPrice),
                                  isGreen: true,
                                ),
                              if (installCost > 0)
                                _buildPriceRow(
                                  lang.t('Extra Structure & Fitting', 'अतिरिक्त स्ट्रक्चर खर्च'),
                                  _currencyFormat.format(installCost),
                                ),
                              if (otherCost > 0)
                                _buildPriceRow(
                                  lang.t('Extra Wiring Charges', 'अतिरिक्त वायरिंग खर्च'),
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
                                  Expanded(child: _buildSpecBox(lang.t('Daily Power', 'रोजाना बिजली'), '~${dailyUnits.round()} ${lang.t("Units", "यूनिट")}')),
                                  Expanded(child: _buildSpecBox(lang.t('Panels', 'पैनल संख्या'), '~$autoPlates ${lang.t("TopCon (540W)", "प्लेट्स")}')),
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
                            lang.t('Save & Send', 'सेव और भेजें (Save & Send)'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    lang.t('2. BANK LOAN & EASY EMI (FINANCE)', '2. सोलर बैंक लोन व आसान किश्त (EMI)'),
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
                'Calculate solar loan EMI and monthly savings (PM Surya Ghar Loan ~5.76% p.a.):',
                'सोलर बैंक लोन व मासिक किश्त का हिसाब निकालें (पीएम सूर्य घर लोन ~5.76% सालाना):',
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
              focusNode: _loanAmountFocus,
              keyboardType: TextInputType.number,
              onTap: () {
                if (_loanAmountController.text.trim() == '0') {
                  _loanAmountController.clear();
                }
              },
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
                        focusNode: _interestRateFocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onTap: () {
                          if (_interestRateController.text.trim() == '0') {
                            _interestRateController.clear();
                          }
                        },
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
                        focusNode: _loanTenureFocus,
                        keyboardType: TextInputType.number,
                        onTap: () {
                          if (_loanTenureController.text.trim() == '0') {
                            _loanTenureController.clear();
                          }
                        },
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

            // Quick Chips for Interest Rate Presets & Tenure
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Text(
                    '${lang.t("Rate", "दर")}: ',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  for (final r in [5.76, 7.0, 8.5]) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('$r%'),
                        labelStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: (rate - r).abs() < 0.05 ? AppColors.ink : AppColors.muted,
                        ),
                        selected: (rate - r).abs() < 0.05,
                        selectedColor: AppColors.sun,
                        backgroundColor: AppColors.cream,
                        showCheckmark: false,
                        onSelected: (_) {
                          setState(() {
                            _interestRateController.text = r.toString();
                          });
                        },
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
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
                                lang.t('Monthly Bank EMI', 'हर महीने की किश्त (EMI)'),
                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_currencyFormat.format(emi)} / ${lang.t("mo", "महीना")}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.teal),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: AppColors.creamDark),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.t('Total Bank Interest', 'कुल बैंक ब्याज'),
                                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currencyFormat.format(totalInterest),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: AppColors.creamDark),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.t('Net Monthly Savings after EMI:', 'किश्त देने के बाद शुद्ध मासिक बचत:'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        Text(
                          netMonthlyCashflow >= 0
                              ? '+${_currencyFormat.format(netMonthlyCashflow)}'
                              : _currencyFormat.format(netMonthlyCashflow),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: netMonthlyCashflow >= 0 ? AppColors.teal : AppColors.coral,
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
