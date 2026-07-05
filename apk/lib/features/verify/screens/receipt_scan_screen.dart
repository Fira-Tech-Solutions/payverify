import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../models/transaction.dart';
import '../../../providers/providers.dart';
import '../../../services/sms/sms_parser.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_messages.dart';
import '../widgets/result_sheet.dart';

class ReceiptScanScreen extends ConsumerStatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  ConsumerState<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends ConsumerState<ReceiptScanScreen> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  File? _image;
  bool _isProcessing = false;
  ParsedSms? _parsed;
  String? _error;

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1200,
      );
      if (picked == null) return;
      setState(() {
        _image = File(picked.path);
        _isProcessing = true;
        _parsed = null;
        _error = null;
      });
      await _runOcr(_image!);
    } catch (e) {
      setState(() => _error = 'Could not open image: $e');
    }
  }

  Future<void> _runOcr(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await _recognizer.processImage(inputImage);
      final text = recognized.text;

      ParsedSms? parsed;
      for (final method in PaymentMethod.all) {
        parsed = SmsParser.parse(text, method);
        if (parsed != null) break;
      }
      parsed ??= _fallbackParse(text);

      setState(() {
        _parsed = parsed;
        _isProcessing = false;
        if (parsed == null) {
          _error = 'Could not read payment details.\nTry a clearer photo.';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = 'OCR failed: $e';
      });
    }
  }

  ParsedSms? _fallbackParse(String text) {
    final amountMatch = RegExp(r'ETB\s*([\d,]+\.?\d*)').firstMatch(text);
    final refMatch = RegExp(
      r'(?:Ref|TxID|TxnID|Transaction\s*ID)[:\s]+([A-Z0-9]{8,20})',
      caseSensitive: false,
    ).firstMatch(text);
    if (amountMatch == null || refMatch == null) return null;
    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
    return ParsedSms(
      transactionId: refMatch.group(1)!.trim(),
      amount: amount,
      senderPhone: '',
      senderName: 'Unknown',
      paymentMethod: _detectMethodFromText(text),
      rawSms: text,
    );
  }

  String _detectMethodFromText(String text) {
    final t = text.toLowerCase();
    if (t.contains('telebirr'))  return PaymentMethod.teleBirr;
    if (t.contains('cbe') || t.contains('commercial bank')) return PaymentMethod.cbe;
    if (t.contains('awash'))     return PaymentMethod.awash;
    if (t.contains('dashen'))    return PaymentMethod.dashen;
    if (t.contains('amole'))     return PaymentMethod.amole;
    if (t.contains('abyssinia')) return PaymentMethod.abyssinia;
    if (t.contains('hellocash')) return PaymentMethod.helloCash;
    return 'Unknown';
  }

  Future<void> _verifyParsed() async {
    if (_parsed == null) return;
    await ref.read(verifyProvider.notifier).verify(_parsed!.transactionId);
    final result = ref.read(verifyProvider);
    if (!mounted) return;
    if (result.state == VerifyState.success && result.transaction != null) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ResultSheet(transaction: result.transaction!),
      );
    } else if (result.state == VerifyState.error) {
      AppMessages.error(context, result.errorMessage ?? 'Verification failed');
    }
    ref.read(verifyProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final isVerifying = ref.watch(verifyProvider).state == VerifyState.processing;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _SourceBtn(Icons.camera_alt, 'Take photo',
                  () => _pickImage(ImageSource.camera))),
              const SizedBox(width: 12),
              Expanded(child: _SourceBtn(Icons.photo_library, 'From gallery',
                  () => _pickImage(ImageSource.gallery))),
            ]),
            const SizedBox(height: 20),

            if (_image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!,
                    width: double.infinity, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],

            if (_isProcessing)
              const _ProcessingCard(),

            if (_error != null && !_isProcessing)
              _ErrorCard(_error!),

            if (_parsed != null && !_isProcessing) ...[
              const Text('Extracted from receipt',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(children: [
                  _Row('Method',    _parsed!.paymentMethod),
                  _Row('Reference', _parsed!.transactionId),
                  _Row('Amount',    'ETB ${_parsed!.amount.toStringAsFixed(2)}'),
                  if (_parsed!.senderName != 'Unknown')
                    _Row('Sender', _parsed!.senderName),
                  if (_parsed!.senderPhone.isNotEmpty)
                    _Row('Phone', _parsed!.senderPhone),
                ]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.verified_outlined),
                label: isVerifying
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Verify this payment'),
                onPressed: isVerifying ? null : _verifyParsed,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => setState(() {
                  _image = null; _parsed = null; _error = null;
                }),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: const Text('Scan another'),
              ),
            ],

            if (_image == null && !_isProcessing)
              const _PlaceholderCard(),
          ],
        ),
      ),
    );
  }
}

class _SourceBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _SourceBtn(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border)),
      child: Column(children: [
        Icon(icon, size: 28, color: AppTheme.primary),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ]),
    ),
  );
}

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border)),
    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2)),
      SizedBox(width: 14),
      Text('Reading receipt…',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
    ]),
  );
}

class _ErrorCard extends StatelessWidget {
  final String msg;
  const _ErrorCard(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.dangerLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.danger.withOpacity(0.3))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(
          fontSize: 13, color: AppTheme.danger, height: 1.4))),
    ]),
  );
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border)),
    child: const Column(children: [
      Icon(Icons.document_scanner_outlined, size: 56, color: AppTheme.border),
      SizedBox(height: 16),
      Text('Take a photo of the payment receipt',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
      SizedBox(height: 8),
      Text('Works with SMS screenshots, printed receipts,\nand in-app confirmations',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.5)),
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label; final String value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
    ]),
  );
}
