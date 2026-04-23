import 'package:flutter/material.dart';
import '../../services/theme.dart';

// ─── FCard ────────────────────────────────────────────────────────────────────
class FCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderTop;
  final VoidCallback? onTap;

  const FCard({
    super.key,
    required this.child,
    this.padding,
    this.borderTop,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: kCardDecoration(borderTop: borderTop),
      padding: padding ?? const EdgeInsets.all(18),
      child: child,
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ─── MetricCard ───────────────────────────────────────────────────────────────
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color accent;
  final IconData? icon;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FCard(
      borderTop: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(), style: kCaption),
              if (icon != null) Icon(icon, size: 15, color: accent),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: accent, letterSpacing: -0.5,
          )),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!, style: kCaption),
          ],
        ],
      ),
    );
  }
}

// ─── FProgressBar ─────────────────────────────────────────────────────────────
class FProgressBar extends StatelessWidget {
  final double percent;
  final Color? color;
  final double height;

  const FProgressBar({
    super.key,
    required this.percent,
    this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 100.0);
    final barColor = color ??
      (clamped >= 100 ? kRed : clamped >= 80 ? kAmber : kBrand);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: clamped / 100,
        backgroundColor: kBorder,
        valueColor: AlwaysStoppedAnimation<Color>(barColor),
        minHeight: height,
      ),
    );
  }
}

// ─── TypeBadge ────────────────────────────────────────────────────────────────
class TypeBadge extends StatelessWidget {
  final String type;
  const TypeBadge(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    final isIncome = type == 'income';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: (isIncome ? kBrand : kRed).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isIncome ? 'Ingreso' : 'Egreso',
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: isIncome ? kBrand : kRed,
        ),
      ),
    );
  }
}

// ─── SectionHeader ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: kTitle),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: const TextStyle(color: kBrand, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

// ─── AlertBanner ─────────────────────────────────────────────────────────────
class AlertBannerWidget extends StatelessWidget {
  final String title;
  final String message;
  final Color color;

  const AlertBannerWidget({
    super.key,
    required this.title,
    required this.message,
    this.color = kAmber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                Text(message, style: kCaption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LoadingShimmer ──────────────────────────────────────────────────────────
class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kBrand, strokeWidth: 2),
          SizedBox(height: 16),
          Text('Cargando tus finanzas...', style: TextStyle(color: kMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
