import 'package:flutter/material.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool compact;
  final List<Widget> actions;
  final Widget? child;
  final double bottomPadding;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.compact = false,
    this.actions = const [],
    this.child,
    this.bottomPadding = 72,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();

    final backButton = canPop
        ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Kembali',
            onPressed: () => Navigator.maybePop(context),
          )
        : const SizedBox(width: 12, height: 48);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withAlpha(190)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: compact
            ? _buildCompact(backButton)
            : _buildCentered(colorScheme, backButton),
      ),
    );
  }

  Widget _buildCompact(Widget backButton) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            backButton,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
        if (child != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
            child: child,
          ),
      ],
    );
  }

  Widget _buildCentered(ColorScheme colorScheme, Widget backButton) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(children: [backButton, const Spacer(), ...actions]),
        if (icon != null) ...[
          const SizedBox(height: 4),
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 42, color: colorScheme.primary),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
        if (child != null) ...[const SizedBox(height: 14), child!],
      ],
    );
  }
}
