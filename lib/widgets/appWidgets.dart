import 'package:flutter/material.dart';

import '../helper/colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class AppSectionLabel extends StatelessWidget {
  final String text;

  const AppSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'OpenSans',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColor.textPrimary,
        ),
      ),
    );
  }
}

class AppAmountText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const AppAmountText({
    super.key,
    required this.text,
    this.color = AppColor.primary,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'OpenSans',
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
    );
  }
}

class AppBudgetBar extends StatelessWidget {
  final double actual;
  final double budget;

  const AppBudgetBar({
    super.key,
    required this.actual,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    if (budget <= 0) return const SizedBox.shrink();
    final over = actual > budget;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: (actual / budget).clamp(0.0, 1.0),
          minHeight: 8,
          backgroundColor: AppColor.chipFill,
          color: over ? AppColor.expense : AppColor.primary,
        ),
      ),
    );
  }
}

InputDecoration appInputDecoration({
  required String label,
  String? prefixText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    prefixText: prefixText,
    suffixIcon: suffixIcon,
  );
}
