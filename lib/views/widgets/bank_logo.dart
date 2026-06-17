import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';

class BankLogoWidget extends StatelessWidget {
  final String bankName;
  final double width;
  final double height;

  const BankLogoWidget({
    super.key,
    required this.bankName,
    this.width = 70.0,
    this.height = 30.0,
  });

  String get _logoPath {
    final lower = bankName.toLowerCase();
    if (lower.contains('ziraat')) {
      return 'assets/images/logos/ziraat.png';
    } else if (lower.contains('garanti')) {
      return 'assets/images/logos/garanti.png';
    } else if (lower.contains('halk')) {
      return 'assets/images/logos/halk.png';
    } else if (lower.contains('akbank')) {
      return 'assets/images/logos/akbank.png';
    } else if (lower.contains('yapı kredi') || lower.contains('yapi kredi')) {
      return 'assets/images/logos/yapi_kredi.png';
    } else if (lower.contains('iş bankası') || lower.contains('is bankasi')) {
      return 'assets/images/logos/is_bankasi.png';
    } else if (lower.contains('vakıf') || lower.contains('vakif')) {
      return 'assets/images/logos/vakif.png';
    } else if (lower.contains('visa')) {
      return 'assets/images/logos/visa.png';
    } else if (lower.contains('mastercard') || lower.contains('master card')) {
      return 'assets/images/logos/mastercard.png';
    } else if (lower.contains('troy')) {
      return 'assets/images/logos/troy.png';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final path = _logoPath;
    if (path.isEmpty) {
      return Icon(Icons.account_balance, size: height, color: context.colors.textSecondary);
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.account_balance, size: height, color: context.colors.textSecondary);
      },
    );
  }
}
