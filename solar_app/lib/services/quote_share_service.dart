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
  static const MethodChannel _platformChannel = MethodChannel('com.sunward.solar/whatsapp');

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

  /// Sends the full quotation card image DIRECTLY to the customer's WhatsApp chat
  /// without ANY text caption (Zero text, 100% detail in the image card).
  static Future<bool> sendQuotationCardToWhatsApp({
    required File imageFile,
    required String phone,
    required String customerName,
  }) async {
    try {
      if (Platform.isAndroid) {
        final res = await _platformChannel.invokeMethod<bool>('sendImageToWhatsApp', {
          'filePath': imageFile.path,
          'phone': phone,
        });
        if (res == true) return true;
      }
    } catch (e) {
      debugPrint('Native WhatsApp intent channel error: $e');
    }

    // Fallback if direct intent not available: system share sheet with ZERO text
    try {
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: null, // ZERO text into it as requested
        subject: 'Sunward Solar Quotation for $customerName',
      );
      return true;
    } catch (e) {
      debugPrint('Fallback share error: $e');
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
