import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../sms/sms_parser.dart';

/// Scans a receipt image (from camera or gallery) using on-device OCR
/// and extracts payment details using the same regex parsers as SMS.
class ReceiptOcrService {
  static final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  static final _picker = ImagePicker();

  /// Pick image from camera or gallery, run OCR, parse result
  static Future<OcrResult> scanFromCamera() =>
      _scan(ImageSource.camera);

  static Future<OcrResult> scanFromGallery() =>
      _scan(ImageSource.gallery);

  static Future<OcrResult> _scan(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null) return OcrResult.cancelled();

      return await extractFromFile(File(picked.path));
    } catch (e) {
      debugPrint('[OCR] Error: $e');
      return OcrResult.error(e.toString());
    }
  }

  /// Run OCR on a file already on disk
  static Future<OcrResult> extractFromFile(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await _recognizer.processImage(inputImage);
      final text = recognized.text;

      debugPrint('[OCR] Extracted text:\n$text');

      // Try to detect which bank/wallet this receipt is from
      final parsed = _parseReceiptText(text);

      return OcrResult(
        rawText: text,
        parsed: parsed,
        success: parsed != null,
      );
    } catch (e) {
      debugPrint('[OCR] Recognition error: $e');
      return OcrResult.error(e.toString());
    }
  }

  static ParsedSms? _parseReceiptText(String text) {
    // Detect sender from receipt text (same logic as SMS parser)
    final lower = text.toLowerCase();

    String detectedMethod = '';
    if (lower.contains('telebirr'))                       detectedMethod = 'TeleBirr';
    else if (lower.contains('commercial bank') ||
             lower.contains('cbe'))                        detectedMethod = 'CBE';
    else if (lower.contains('awash'))                     detectedMethod = 'Awash';
    else if (lower.contains('dashen'))                    detectedMethod = 'Dashen';
    else if (lower.contains('abyssinia') ||
             lower.contains('boa'))                        detectedMethod = 'Abyssinia';
    else if (lower.contains('amole'))                     detectedMethod = 'Amole';
    else if (lower.contains('hellocash'))                 detectedMethod = 'HelloCash';

    if (detectedMethod.isEmpty) {
      // Try generic ETB amount + any reference number
      detectedMethod = 'Unknown';
    }

    // Reuse SMS parser - receipt text has same patterns
    return SmsParser.parse(text, detectedMethod);
  }

  static void dispose() {
    _recognizer.close();
  }
}

class OcrResult {
  final String rawText;
  final ParsedSms? parsed;
  final bool success;
  final bool cancelled;
  final String? errorMessage;

  OcrResult({
    required this.rawText,
    this.parsed,
    required this.success,
    this.cancelled = false,
    this.errorMessage,
  });

  factory OcrResult.cancelled() => OcrResult(
        rawText: '',
        success: false,
        cancelled: true,
      );

  factory OcrResult.error(String msg) => OcrResult(
        rawText: '',
        success: false,
        errorMessage: msg,
      );

  /// The most likely transaction reference extracted from receipt
  String? get transactionId => parsed?.transactionId;

  /// Formatted amount or null
  String? get amountFormatted => parsed != null
      ? 'ETB ${parsed!.amount.toStringAsFixed(2)}'
      : null;
}
