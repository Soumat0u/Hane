import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';

/// PIN kurulum ve giriş ekranlarının paylaştığı, 4 haneli gösterge + 0-9
/// tuş takımı ve geri silme tuşundan oluşan basit bileşen.
class PinKeypad extends StatelessWidget {
  final int enteredLength;
  final int pinLength;
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final Color? dotColor;

  const PinKeypad({
    super.key,
    required this.enteredLength,
    required this.onDigit,
    required this.onBackspace,
    this.pinLength = 4,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = dotColor ?? context.colors.brand;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pinLength, (i) {
            final filled = i < enteredLength;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
              ),
            );
          }),
        ),
        const SizedBox(height: 36),
        _buildRow(context, [1, 2, 3]),
        const SizedBox(height: 16),
        _buildRow(context, [4, 5, 6]),
        const SizedBox(height: 16),
        _buildRow(context, [7, 8, 9]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72),
            _buildKey(context, '0', () => onDigit(0)),
            _buildBackspaceKey(context),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<int> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) => _buildKey(context, '$d', () => onDigit(d))).toList(),
    );
  }

  Widget _buildKey(BuildContext context, String label, VoidCallback onTap) {
    return SizedBox(
      width: 72,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: onBackspace,
          child: Center(
            child: Icon(Icons.backspace_outlined, color: context.colors.textSecondary, size: 22),
          ),
        ),
      ),
    );
  }
}
