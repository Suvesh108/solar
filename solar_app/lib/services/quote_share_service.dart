import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class QuoteShareService {
  static String formatWhatsAppQuote({
    required String customerName,
    required String phone,
    required String location,
    required String propertyType,
    required double kw,
    String installationType = 'On-Grid',
    String? batteryVoltage,
    double batteryPrice = 0.0,
    required double baseSolarCost,
    required double installCost,
    required double inverterWiringCost,
    required double totalSystemCost,
    required double subsidy,
    required double netPayable,
    required double monthlySavings,
    required double annualSavings,
    required String paybackYears,
    required double profit25Years,
    double? loanAmount,
    double? emiAmount,
    int? loanYears,
    double? interestRate,
  }) {
    final hasLoan = (loanAmount != null && loanAmount > 0 && emiAmount != null && emiAmount > 0);
    final isHybrid = installationType == 'Hybrid';
    final autoPlates = ((kw * 1000) / 540).ceil();

    final loanSection = hasLoan
        ? '''
🏦 *BANK LOAN & EASY EMI:*
• Sanctioned Loan: ₹${loanAmount.round()} ($loanYears Yrs @ ${interestRate?.toStringAsFixed(2) ?? "5.76"}%)
• Monthly EMI: ₹${emiAmount.round()} / month
• Monthly Savings: ₹${monthlySavings.round()} / month
${monthlySavings >= emiAmount ? '★ Savings fully covers your EMI!' : '★ Net EMI difference: ₹${(emiAmount - monthlySavings).round()} / mo'}
'''
        : '';

    final batteryLine = (isHybrid && batteryPrice > 0)
        ? '• Hybrid Battery Bank (${batteryVoltage ?? "24V"}): ₹${batteryPrice.round()}\n'
        : '';

    final extraFittingLine = installCost > 0
        ? '• Extra Structure & Fitting: ₹${installCost.round()}\n'
        : '';

    final extraWiringLine = inverterWiringCost > 0
        ? '• Converter / Battery: ₹${inverterWiringCost.round()}\n'
        : '';

    return '''
☀️ *SUNWARD SOLAR — OFFICIAL ROOFTOP ESTIMATE* ☀️
━━━━━━━━━━━━━━━━━━━━━━━━━
👤 *Customer:* $customerName
📞 *Contact:* $phone
📍 *Location:* $location
🏠 *Property:* $propertyType
⚙️ *System Type:* $installationType Solar System

⚡ *SYSTEM SPECIFICATIONS:*
• Solar Capacity: ${kw.toStringAsFixed(1)} kW System
• Solar Panels: ~$autoPlates Panels (540W TopCon)
• Daily Generation: ~${(kw * 4).round()} Units / day
• Monthly Generation: ~${(kw * 120).round()} Units / month
• Rooftop Area: ~${(kw * 100).round()} sq. ft.
${isHybrid ? '• Battery Setup: ${batteryVoltage ?? "24V"} Solar Battery Bank\n' : ''}
💰 *COST BREAKDOWN:*
• Turnkey Solar Package (${kw.toStringAsFixed(1)} kW): ₹${baseSolarCost.round()}
$batteryLine$extraFittingLine$extraWiringLine─────────────────────────
• *Total System Cost:* ₹${totalSystemCost.round()}
• *Govt Subsidy Discount:* -₹${subsidy.round()}
★ *FINAL AMOUNT TO PAY:* ₹${netPayable.round()}
$loanSection
📈 *SAVINGS & RETURN:*
• Monthly Bill Saved: ~₹${monthlySavings.round()} / month
• Annual Bill Saved: ~₹${annualSavings.round()} / year
• Payback Period: $paybackYears Years
• 25-Year Estimated Profit: ₹${profit25Years.round()}

📞 *Sunward Solar Helpline:* +91 9731001477
━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  static Future<bool> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    var clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    if (clean.length == 10) {
      clean = '91$clean';
    }

    final encoded = Uri.encodeComponent(message);

    // 1. Try native WhatsApp URI scheme (Launches WhatsApp chat directly)
    final nativeUri = Uri.parse('whatsapp://send?phone=$clean&text=$encoded');
    try {
      if (await canLaunchUrl(nativeUri)) {
        final ok = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        if (ok) return true;
      }
    } catch (e) {
      debugPrint('WhatsApp native scheme error: $e');
    }

    // 2. Try api.whatsapp.com deep link
    final apiUri = Uri.parse('https://api.whatsapp.com/send?phone=$clean&text=$encoded');
    try {
      if (await canLaunchUrl(apiUri)) {
        final ok = await launchUrl(apiUri, mode: LaunchMode.externalApplication);
        if (ok) return true;
      }
    } catch (e) {
      debugPrint('WhatsApp api deep link error: $e');
    }

    // 3. Fallback to wa.me universal link
    final waMeUri = Uri.parse('https://wa.me/$clean?text=$encoded');
    try {
      if (await canLaunchUrl(waMeUri)) {
        final ok = await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
        if (ok) return true;
      }
      return await launchUrl(waMeUri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('WhatsApp wa.me error: $e');
    }

    return false;
  }

  static const MethodChannel _nativeChannel = MethodChannel('com.sunward.solar/whatsapp');

  /// Sends the full quotation card image directly to WhatsApp chat for the customer number
  /// with ZERO text caption and NO system share sheet picker.
  static Future<bool> sendQuotationCardToWhatsApp({
    required File imageFile,
    required String phone,
    required String customerName,
  }) async {
    // 1. Primary: Direct native WhatsApp Intent with recipient JID (No system chooser)
    try {
      final bool? nativeSuccess = await _nativeChannel.invokeMethod<bool>(
        'sendWhatsAppImage',
        {
          'filePath': imageFile.path,
          'phone': phone,
        },
      );
      if (nativeSuccess == true) {
        return true;
      }
    } catch (e) {
      debugPrint('Native direct WhatsApp dispatch error: $e');
    }

    // 2. Fallback: Share.shareXFiles
    try {
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: null, // ZERO text into it as requested
        subject: 'Sunward Solar Quotation for $customerName',
      );
      return true;
    } catch (e) {
      debugPrint('Fallback Share error: $e');
      return false;
    }
  }

  /// High-resolution unclipped offscreen widget screenshot capture
  static Future<File?> captureWidgetWithController({
    required ScreenshotController controller,
    required Widget widget,
    BuildContext? context,
  }) async {
    try {
      final imageBytes = await controller.captureFromWidget(
        widget,
        context: context,
        delay: const Duration(milliseconds: 150),
        pixelRatio: 3.0,
      );
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Sunward_Quote_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);
      return file;
    } catch (e) {
      debugPrint('ScreenshotController capture error: $e');
      return null;
    }
  }

  /// Fallback RepaintBoundary capture
  static Future<File?> captureWidgetToImage(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/solar_quotation_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      debugPrint('Error capturing quotation image: $e');
      return null;
    }
  }
}
