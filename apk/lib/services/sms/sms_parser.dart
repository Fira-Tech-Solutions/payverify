import '../../models/transaction.dart';

/// Parses raw SMS text from Ethiopian banks and wallets
/// into structured Transaction data.
class SmsParser {
  /// Master parse entry point — tries each bank's pattern
  static ParsedSms? parse(String smsBody, String senderAddress) {
    final method = _detectMethod(senderAddress, smsBody);
    if (method == null) return null;

    switch (method) {
      case PaymentMethod.teleBirr:
        return _parseTeleBirr(smsBody);
      case PaymentMethod.cbe:
        return _parseCbe(smsBody);
      case PaymentMethod.awash:
        return _parseAwash(smsBody);
      case PaymentMethod.dashen:
        return _parseDashen(smsBody);
      case PaymentMethod.amole:
        return _parseAmole(smsBody);
      case PaymentMethod.helloCash:
        return _parseHelloCash(smsBody);
      default:
        return _parseGeneric(smsBody, method);
    }
  }

  static String? _detectMethod(String address, String body) {
    final addr = address.toLowerCase();
    final b = body.toLowerCase();
    if (addr.contains('telebirr') || b.contains('telebirr')) return PaymentMethod.teleBirr;
    if (addr == '841' || b.contains('commercial bank of ethiopia') || b.contains('cbe')) return PaymentMethod.cbe;
    if (addr.contains('awash') || b.contains('awash bank')) return PaymentMethod.awash;
    if (addr.contains('dashen') || b.contains('dashen bank')) return PaymentMethod.dashen;
    if (addr.contains('amole') || b.contains('amole')) return PaymentMethod.amole;
    if (addr.contains('hellocash') || b.contains('hellocash')) return PaymentMethod.helloCash;
    if (addr.contains('abyssinia') || b.contains('bank of abyssinia') || b.contains('boa')) return PaymentMethod.abyssinia;
    return null;
  }

  // ─── TeleBirr ───────────────────────────────────────────────────
  // Sample: "You have received ETB 1,250.00 from 0912345678 (Abebe Bekele).
  //          Ref: TLB20260628884201. Your balance is ETB 5,450.00"
  static ParsedSms? _parseTeleBirr(String body) {
    final amountMatch = RegExp(
      r'received\s+ETB\s+([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(body);

    final refMatch = RegExp(
      r'[Rr]ef[:\s]+([A-Z0-9]{8,20})',
      caseSensitive: false,
    ).firstMatch(body);

    final phoneMatch = RegExp(r'from\s+(09\d{8}|\+2519\d{8})').firstMatch(body);

    final nameMatch = RegExp(r'\(([^)]+)\)').firstMatch(body);

    if (amountMatch == null || refMatch == null) return null;

    return ParsedSms(
      transactionId: refMatch.group(1)!.trim(),
      amount: _parseAmount(amountMatch.group(1)!),
      senderPhone: phoneMatch?.group(1) ?? '',
      senderName: nameMatch?.group(1) ?? 'Unknown',
      paymentMethod: PaymentMethod.teleBirr,
      rawSms: body,
    );
  }

  // ─── CBE ─────────────────────────────────────────────────────────
  // Sample: "Cr ETB1,500.00 A/C No XXXX1234 Date 28/06/26 Desc:
  //          Transfer from DAWIT KEBEDE Ref No:CBE2026062812345"
  static ParsedSms? _parseCbe(String body) {
    final amountMatch = RegExp(
      r'Cr\s*ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(body);

    final refMatch = RegExp(
      r'[Rr]ef\s*[Nn]o[:\s]*([A-Z0-9]{6,20})',
    ).firstMatch(body);

    final nameMatch = RegExp(
      r'(?:Transfer from|from)\s+([A-Z][A-Z\s]+?)(?:\s+Ref|\s+A\/C|$)',
    ).firstMatch(body);

    if (amountMatch == null || refMatch == null) return null;

    return ParsedSms(
      transactionId: refMatch.group(1)!.trim(),
      amount: _parseAmount(amountMatch.group(1)!),
      senderPhone: '',
      senderName: nameMatch?.group(1)?.trim() ?? 'CBE Customer',
      paymentMethod: PaymentMethod.cbe,
      rawSms: body,
    );
  }

  // ─── Awash Bank ──────────────────────────────────────────────────
  // Sample: "Dear Customer, ETB 2,000.00 has been credited to your account.
  //          Sender: Sara Tesfaye (0923456789). TxnID: AWB20260628556677"
  static ParsedSms? _parseAwash(String body) {
    final amountMatch = RegExp(
      r'ETB\s*([\d,]+\.?\d*)\s+has been credited',
      caseSensitive: false,
    ).firstMatch(body);

    final txnMatch = RegExp(
      r'TxnID[:\s]+([A-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(body);

    final senderMatch = RegExp(
      r'Sender[:\s]+([^(]+)\s*\(?(\d{10,13})?\)?',
      caseSensitive: false,
    ).firstMatch(body);

    if (amountMatch == null || txnMatch == null) return null;

    return ParsedSms(
      transactionId: txnMatch.group(1)!.trim(),
      amount: _parseAmount(amountMatch.group(1)!),
      senderPhone: senderMatch?.group(2) ?? '',
      senderName: senderMatch?.group(1)?.trim() ?? 'Awash Customer',
      paymentMethod: PaymentMethod.awash,
      rawSms: body,
    );
  }

  // ─── Dashen / Amole ──────────────────────────────────────────────
  static ParsedSms? _parseDashen(String body) {
    final amountMatch = RegExp(
      r'(?:credited|received)\s*(?:with)?\s*ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(body);

    final refMatch = RegExp(
      r'[Tt]x(?:n)?[Ii][Dd]?[:\s]+([A-Z0-9]+)',
    ).firstMatch(body);

    if (amountMatch == null || refMatch == null) return null;

    return ParsedSms(
      transactionId: refMatch.group(1)!.trim(),
      amount: _parseAmount(amountMatch.group(1)!),
      senderPhone: '',
      senderName: 'Dashen Customer',
      paymentMethod: PaymentMethod.dashen,
      rawSms: body,
    );
  }

  static ParsedSms? _parseAmole(String body) => _parseDashen(body)
      ?.copyWith(paymentMethod: PaymentMethod.amole);

  static ParsedSms? _parseHelloCash(String body) {
    final amountMatch = RegExp(
      r'ETB\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(body);
    final refMatch = RegExp(r'[Tt]x[:\s]+([A-Z0-9]{6,20})').firstMatch(body);
    if (amountMatch == null || refMatch == null) return null;
    return ParsedSms(
      transactionId: refMatch.group(1)!.trim(),
      amount: _parseAmount(amountMatch.group(1)!),
      senderPhone: '',
      senderName: 'HelloCash User',
      paymentMethod: PaymentMethod.helloCash,
      rawSms: body,
    );
  }

  /// Fallback for unrecognised format — try to grab any amount + ref
  static ParsedSms? _parseGeneric(String body, String method) {
    final amountMatch = RegExp(r'ETB\s*([\d,]+\.?\d*)').firstMatch(body);
    final refMatch = RegExp(r'[Rr]ef[:\s]+([A-Z0-9]{6,20})').firstMatch(body);
    if (amountMatch == null || refMatch == null) return null;
    return ParsedSms(
      transactionId: refMatch.group(1)!.trim(),
      amount: _parseAmount(amountMatch.group(1)!),
      senderPhone: '',
      senderName: 'Unknown',
      paymentMethod: method,
      rawSms: body,
    );
  }

  static double _parseAmount(String raw) =>
      double.tryParse(raw.replaceAll(',', '')) ?? 0.0;
}

class ParsedSms {
  final String transactionId;
  final double amount;
  final String senderPhone;
  final String senderName;
  final String paymentMethod;
  final String rawSms;

  ParsedSms({
    required this.transactionId,
    required this.amount,
    required this.senderPhone,
    required this.senderName,
    required this.paymentMethod,
    required this.rawSms,
  });

  ParsedSms copyWith({String? paymentMethod}) => ParsedSms(
        transactionId: transactionId,
        amount: amount,
        senderPhone: senderPhone,
        senderName: senderName,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        rawSms: rawSms,
      );
}
