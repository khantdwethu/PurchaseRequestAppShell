import 'package:flutter/material.dart';

class LoadingProgressBar extends StatelessWidget {
  const LoadingProgressBar({
    required this.progress,
    required this.visible,
    super.key,
  });

  final int progress;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 3,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: visible ? 1 : 0,
        child: LinearProgressIndicator(
          value: progress > 0 && progress < 100 ? progress / 100 : null,
          minHeight: 3,
          backgroundColor: color.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}
