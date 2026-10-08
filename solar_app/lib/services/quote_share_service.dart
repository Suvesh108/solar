import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class QuoteShareService {
  static String formatWhatsAppQuote({
    required String customerName,
    required String phone,
    required String location,
    required String propertyType,
    required double kw,
    required int plateCount,
    required double platePrice,
    required double totalPlatesCost,
    required double installCost,
    required double inverterWiringCost,
    required double totalSystemCost,
    required double subsidy,
    required double netPayable,
    required double monthlySavings,
    required double annualSavings,
    required String paybackYears,
    required double profit25Years,
  }) {
    return '''
☀️ *SUNWARD SOLAR — OFFICIAL ROOFTOP QUOTE* ☀️
━━━━━━━━━━━━━━━━━━━━━━━━━
👤 *Customer:* $customerName
📞 *Contact:* $phone
📍 *Location:* $location
🏠 *Property:* $propertyType

⚡ *SYSTEM SPECIFICATIONS:*
• Solar Capacity: ${kw.toStringAsFixed(1)} kW System
• Solar Plates: $plateCount Plates (540W Mono PERC)
• Daily Generation: ~${(kw * 4).round()} Units / day
• Monthly Generation: ~${(kw * 120).round()} Units / month
• Rooftop Area: ~${(kw * 100).round()} sq. ft.

💰 *DETAILED COST BREAKDOWN (HISAAB):*
• Solar Plates Cost ($plateCount × ₹${platePrice.round()}): ₹${totalPlatesCost.round()}
• Fitting & Structure: ₹${installCost.round()}
• Inverter & Wiring: ₹${inverterWiringCost.round()}
─────────────────────────
• *Kul Kharcha (Total Price):* ₹${totalSystemCost.round()}
• *Govt Subsidy Discount:* -₹${subsidy.round()}
★ *FINAL AMOUNT TO PAY:* ₹${netPayable.round()}*

📈 *SAVINGS & PROFIT:*
• Monthly Bill Saved: ~₹${monthlySavings.round()} / month
• Annual Bill Saved: ~₹${annualSavings.round()} / year
• Kharcha Vasool (Payback): $paybackYears Years
• 25-Year Estimated Profit: ₹${profit25Years.round()}

📞 *Contact Sunward Solar for Free Site Visit!*
WhatsApp & Call Helpline: +91 99999 99999
━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  static Future<bool> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    var clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      clean = '91$clean';
    }
    final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

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

  static Future<void> shareQuotationImage({
    required GlobalKey key,
    required String text,
    required String customerName,
  }) async {
    try {
      final file = await captureWidgetToImage(key);
      if (file != null && await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: text,
          subject: 'Sunward Solar Quotation for $customerName',
        );
      } else {
        await Share.share(text, subject: 'Sunward Solar Quotation for $customerName');
      }
    } catch (e) {
      debugPrint('Error sharing quotation: $e');
    }
  }
}
