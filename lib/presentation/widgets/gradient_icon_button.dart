import 'package:flutter/material.dart';
import 'package:notefolder/core/themes/app_spacing.dart';

class GradientIconButton extends StatelessWidget {
  const GradientIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.width = 60,
    this.height = 50,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.lg);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: radius,
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox(
            width: width,
            height: height,
            child: Icon(icon, color: Colors.white, semanticLabel: tooltip),
          ),
        ),
      ),
    );
  }
}
